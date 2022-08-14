# ytt-test

(prototype) End-to-end test runner for ytt.

## Quick Start

0. Put `./ytt-test.sh` in the $PATH.
1. _outside_ of your ytt source directory, create a directory named `.ytt-tests`
2. for each test you want to run, create a test file (i.e. with a `.test.yaml` suffix)

    ```yaml
    #! .ytt-tests/sample.test.yaml
    ---

    actual: ytt --file ${YTT_SUBJECT}/config/ --data-values-file values.yaml
    expected: ytt --file expected/
    ```
    - ytt-test sets `YTT_SUBJECT` to the absolute path to parent directory of `.ytt-tests`

3. create the fixture(s) for the test

    ```yaml
    #! .ytt-tests/values.yaml
    ---
    instances: 7
    ```

4. in the parent directory of `.ytt-tests` run the test runner

    ```console
    $ ls -a1F
    .ytt-tests/
    config/

    $ ytt-test.sh
    fail  .ytt-tests/sample.test.yaml
            ==> .ytt-test-out/sample/result.diff

    FAILURE
    ```
5. examine the "actual" result; if acceptable, make it the "expected"

    ```console
    $ mv .ytt-test-out/sample/actual .ytt-tests/expected
    ```
6. re-run the test

    ```console 
    $ ytt-test.sh
    pass  .ytt-tests/sample.test.yaml
    SUCCESS
    ```
   
_(See also [`./examples`](examples))_
