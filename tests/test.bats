#! /usr/bin/env bats

PORT=41530
URL=http://localhost:$PORT
CONTAINER=flat-app-$PORT
export LANG=C

cd "$BATS_TEST_DIRNAME"

@test "usage errors: command missing" {
	run ../flat
	echo "$output"
	[ "$status" -eq 64 ]
	[[ "$output" =~ "missing command" ]]
}

@test "usage errors: illegal option" {
	run ../flat start -foo .
	echo "$output"
	[ "$status" -eq 64 ]
	[[ "$output" =~ "illegal option" ]]
}

@test "usage errors: port must be numeric" {
	run ../flat start -p foo "$tmpdir"
	echo "$output"
	[ "$status" -eq 64 ]
	[[ "$output" =~ "Port must be" ]]
}

@test "usage errors: dir not found" {
	run ../flat start bad/dir
	echo "$output"
	[[ $status -eq 66 ]]
	[[ $output = "Directory 'bad/dir' not found or unreadable" ]]
}

@test "flat site w/o dir" {
	cd app
	run env FLAT_NOSTART=1 ../../flat start -p $PORT

	echo "$output"
	[[ ${lines[0]} =~ ^'Using directory: '.*'/tests/app'$ ]]
}

@test "flat site w/ dir" {
	run env FLAT_NOSTART=1 ../flat start -p $PORT app

	echo "$output"
	[[ ${lines[0]} =~ ^'Using directory: '.*'/tests/app'$ ]]
}

@test "flat w/ forbidden dir" {
	dir=$(mktemp -d)

	# dir ok, but conf missing
	run env FLAT_NOSTART=1 ../flat start "$dir"
	[[ $status -eq 67 ]]

	# dir not readable
	chmod a-x "$dir"
	run env FLAT_NOSTART=1 ../flat start "$dir"
	rmdir "$dir"
	echo "$output" | grep "not found or unreadable"
	[[ $status -eq 66 ]]
}

@test "flat w/ no app dir -> error" {
	run ../flat start -p $PORT .

	echo "$output"
	[[ $status -eq 67 ]]
	[[ "${lines[0]}" =~ ^"No FLAT app found in ".*"/tests: create swagger.yaml to start"$ ]]
}

@test "start flat" {
	export FLAT_FOO="bar baz"
	export FIT_FLAT_SETTING="on"
	# used in next test
	export FLAT_DEBUG=":warn:"
	../flat start -p $PORT app &

	waitForStart

	# fallback flow
	[[ $(curl -Ss http://localhost:$PORT/fallback_does_not_exist) =~ Fallback\ flow\ should\ not\ be\ started ]]
}

@test "debug flag" {
	# uses FLAT_DEBUG from previous test
	docker logs $CONTAINER 2>&1 | grep "Debug configured: :warn:"
	docker exec -i $CONTAINER cat /opt/sevenval/fit14/conf/fit.ini.d/from_env.ini | grep "FIT_DEFAULT_ENGINE_DEBUG=errorlog-_all_-warning"
}

@test "env vars" {
	docker exec -i $CONTAINER cat /opt/sevenval/fit14/conf/fit.ini.d/from_env.ini | grep FIT_FLAT_SETTING=on
	docker exec -i $CONTAINER cat /opt/sevenval/fit14/conf/env | grep "FLAT_FOO=bar baz"
	run docker exec -i $CONTAINER /bin/sh -c "cat /opt/sevenval/fit14/conf/env | grep FIT_FLAT_SETTING=on"
	[[ $status != 0 ]]
}

@test "mocking" {
	# mocked response
	run curl -s -g \
		-H mock:true \
		"http://localhost:$PORT/api/v3/pet/findByStatus?status=available"
	echo "$output"
	[[ $(echo $output | jq -r '.[0].name' ) == Snowball ]]
}

@test "routing and validation" {
	# api fallback + successful input validation
	run curl -sg "http://localhost:$PORT/api/v3/pet/findByStatus?status=available"
	echo "$output"
	[[ $output =~ "API fallback" ]]

	# api fallback + input validation error (status param missing)
	run curl -sg "http://localhost:$PORT/api/v3/pet/findByStatus"
	echo "$output"
	[[ $output  =~ "Required constraint violated" ]]

	# api fallback + unknown route
	run curl -Ss http://localhost:$PORT/api/v3/
	echo "$output"
	[[ $output =~ "Path \/api\/v3\/ not found" ]]
}

@test "stop and cleanup tests" {
	../flat stop -p $PORT app
}

@test "template check good" {
	run ../flat check-template app/templates/good.tmpl
	[[ $status -eq 0 ]]
}

@test "template check bad" {
	run ../flat check-template app/templates/bad.tmpl
	echo "$output"
	[[ $status -eq 65 ]]
	[[ $output == $'Template contains errors:\nTemplate error in line 1: Invalid template command: bad' ]]
}


function waitForStart() {
	NAME=${1:-"$CONTAINER"}

	echo using start name $NAME

	for ((x=15; x>0; x--)); do
		if curl -f -s "http://localhost:$PORT/test.fit" > /dev/null; then
			break;
		fi
		sleep 0.5
	done
	docker logs $NAME
}

