# bats-mock
Mocking/stubbing library for [BATS](https://github.com/sstephenson/bats)


## Motivation
A critical component to any unit testing framework is mocking. In order to test code in isolation while avoiding
external variables like network calls, one must be able to mock calls that perform actions that are not possible
or necessary to test.

In other languages there are often many strong, well-supported frameworks for doing this. For instance, in Java,
we have [mockito](http://site.mockito.org/), in python, we have [mox](https://pypi.python.org/pypi/mox) or
[mock](https://docs.python.org/3/library/unittest.mock.html), etc.

Bash, being generally a scripting language that no one bothers to write tests for, does not have any standard, or
even particularly popular mocking libarary.

This library was forked from the most popular and solid candidate, [bats-mock](https://github.com/jasonkarns/bats-mock),
though this libary had a number of shortcomings:

* Lack of support for arguments containing whitespace
* No error messaging for failures
* No unit tests

This new version of the library has a more well-defined model for how commands are mocked (see below), and tests
enforcing that advertised behaviour. This project itself is tested by [BATS](https://github.com/sstephenson/bats).


## Requirements
This library does a fair bit of heavy lifting to test that arguments match correctly. As such it requires a number
of potentially non-standard utilities be installed on whatever machine the tests using this libarary run on:

* jq
* base64 (supporting the `--wrap` and `-d` flags)


## Installation
This library can be installed in a couple of ways. Essentially, you simply need this repository somewhere on
disk, and then tests intending to use the `stub` and `unstub` functions need to load this libarary like so:
```
load path/to/bats-mock/stub
```

An option if you intend to run these tests on your host machine is to install this repository via git submodule:
tests are in `test`:
```
git submodule add https://github.com/norwoodj/bats-mock test/helpers/mocks
```

This option requires that you have the requirements listed above installed on your host machine. Generally you
ought not to rely on developers having utilities installed like this. Instead, it's recommended that any
project wishing to use this library in their bats tests should build a docker image to run the bats tests in,
and install this libarary into that docker image.

This is what's done to include the [bats-assert](https://github.com/ztombol/bats-assert) and
[bats-support](https://github.com/ztombol/bats-support) libraries in the tests for this project, you can
include this project in a docker image with the following set of commands:
```
FROM alpine:3.7
LABEL maintainer="norwood.john.m@gmail.com"

ARG BATS_ASSERT_VERSION=0.3.0
ARG BATS_MOCK_VERSION=<most-recent-version>
ARG BATS_SUPPORT_VERSION=0.3.0
ARG BATS_TESTS_HOME=/opt/testing
ARG BATS_VERSION=0.4.0

ENV BATS_VERSION=${BATS_VERSION}
ENV BATS_TESTS_HOME=${BATS_TESTS_HOME}

WORKDIR ${BATS_TESTS_HOME}

RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        bash \
        ca-certificates \
        coreutils \
        jq \
        tar \
        wget \
    && wget https://github.com/sstephenson/bats/archive/v${BATS_VERSION}.tar.gz \
    && tar xzf v${BATS_VERSION}.tar.gz \
    && cd bats-${BATS_VERSION} \
    && ./install.sh /usr/local \
    && cd .. \
    && rm -rvf bats-${BATS_VERSION} ${BATS_VERSION}.tar.gz \
    && mkdir -p libs/bats \
    && wget https://github.com/ztombol/bats-assert/archive/v${BATS_ASSERT_VERSION}.tar.gz && mv v${BATS_ASSERT_VERSION}.tar.gz bats-assert.tar.gz \
    && wget https://github.com/ztombol/bats-support/archive/v${BATS_SUPPORT_VERSION}.tar.gz && mv v${BATS_SUPPORT_VERSION}.tar.gz bats-support.tar.gz \
    && wget https://github.com/norwoodj/bats-mock/archive/${BATS_MOCK_VERSION}.tar.gz && mv ${BATS_MOCK_VERSION}.tar.gz bats-mock.tar.gz \
    && tar xzf bats-assert.tar.gz \
    && tar xzf bats-support.tar.gz \
    && tar xzf bats-mock.tar.gz \
    && mv -v bats-assert-${BATS_ASSERT_VERSION} libs/bats/bats-assert \
    && mv -v bats-support-${BATS_SUPPORT_VERSION} libs/bats/bats-support \
    && mv -v bats-mock-${BATS_MOCK_VERSION} libs/bats/bats-mock \
    && rm -rvf *.tar.gz
...
```

## Usage

After loading `bats-mock/stub` you have two new functions defined:

* `stub`: for creating new stubs, along with a plan with expected args and the results to return when called
* `unstub`: for verifying that the plan was fullfilled


### Stubbing
The `stub` function takes a program name as its first argument, and any remaining arguments goes into the stub plan,
one line per arg.

Each plan line represents an expected invocation, with a list of expected arguments followed by a command to execute
in case the arguments matched, separated with a colon:

    arg1 arg2 ... : only_run if args matched

The expected args (and the colon) is optional.

So, in order to stub `git`, we could use something like this in a test case (where `perform_git_actions` is the function
under test, relying on data from the `git` command):

```
@test "check_git_actions" {
    stub git \
        "rev-parse HEAD : echo master" \
        "checkout stable : true" \
        "rev-parse HEAD : echo stable" \
        "rebase master : true" \
        "checkout master : true" \
        "tag 17.1228 : true"

    run perform_git_actions
    unstub git
}
```

This verifies that `git` was invoked in order with the specified arguments and when matched, performs the command specified
on the right side of the colon. In this way, we can simulate being on particular git branches for the script being tested,
even when our script is say, running in a docker container that doesn't have our project's git repository included in it.
(This is how you're running your tests right? RIGHT?)

The plan is verified, one by one, as the calls come in, but the final check that there are no remaining un-met plans at the
end is left until the stub is removed with `unstub`.


## Advanced Usage
This libarary supports complicated command strings, including arguments with whitespace, as well as complicated bash
expressions for the resulting command to run when the expected invocation is matched.

### Whitespace arguments
First off, in order to specify an empty argument or an argument containing whitespace in either the expected invocation
or result command section of a plan, simply quote it. For instance, the below command expects that `cli-utility` be invoked with
one argument, a json blob, and that when matched, a different json blob is returned:
```
stub cli-utility "'{\"cat\": \"echo\"}' : echo '{\"dog\": \"oscar\"}'"
```

Similarly, to expect one empty string argument to `cli-utility`, you'd do
```
stub cli-utility "'' : echo '{\"dog\": \"oscar\"}'"
```

Finally, you can also expect a call with zero arguments by omitting the left hand side of the colon:
```
stub cli-utility " : echo '{\"dog\": \"oscar\"}'"
```

### Matching any arg or command:
In some cases, the expected argument to a command may be a complicated multiline string, that's painful to write out in a mock
call, or one of the arguments simply doesn't need to be tested. In this case, you can match any string for an argument by
passing the `__ANY__` token in a stub call.

For instance:
```
stub git "checkout __ANY__ : true"
```

Would match a call to git to checkout any branch.

Similarly, you can specify that any list of args is acceptable by omitting the left hand side of the colon AND the colon, thus
specifying only a result command to run:

```
stub git "echo master"
```

This would match any call to git at all e.g. `git checkout master` or `git branch -d stable`, and perform the result command
`echo master`.

### Complicated result commands
When a command is matched, the right hand side of the colon is run instead of the expected invocation. Sometimes it is necessary
to write relatively complicated expressions to get the output to match exactly what the stubbed command would have produced.
To that end, this library supports a fairly wide array of bash expressions for the result command:

* Pipes - You may use pipes in the result command by quoting them: `stub git "tag -l : echo 17.1223 17.1225 '|' xargs -n1 '|' sort -r"
* Herestrings - You may use herestrings in the result command by quoting them: `stub colors "random : sed 's/blue/green/g' '<<<' blue"
* For Loops - For loops can be used if all bash special characters are quoted: `stub git "tag -l : for i in 17.1223 17.1225 ';' do echo '\${i}' ';' done"
* Printing special bash characters: You can print the above special characters by double quoting them: `stub command "print_symbol : echo '\"<<<\"'"

Probably much more is supported, you should experiment.

### Caveats
You can use this library to mock either executables, or bash functions, however, since this library mocks commands by creating
a mock executable in your PATH, using this library to mock bash functions requires that the real functions be unset. This is
because bash functions with a name have priority over executables with the same name, and so the real function will be run
instead of the stub.


## Running the unit tests
In order to run the unit tests for this project, you need to have docker and docker-compose installed. You can then run:
```
./utils/run-bash-tests.sh
```

This will invoke docker-compose to build the bats-testing image for this project, and then run the tests on the current code in this
repository in a docker container.
