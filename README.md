# ytt-test

(prototype) End-to-end test runner for ytt.

## Quick Start

0. Put `./ytt-test.sh` in the $PATH.
1. _outside_ of your ytt source directory, create a directory named `.ytt-tests`
2. for each test you want to run, create a test file (i.e. with a `.test.yaml` suffix)

    ```yaml
    #! sample.test.yaml
    ---

    #! First, run `ytt` with these files...
    actual:
      #! ytt library files to test
      #!   (paths in this section are relative to the parent directory of `.ytt-tests`)
      subject:
        #! corresponds to the ytt `--file` flag
        file:
          - config/
      
      #! Additional files from this testcase -- to configure this run
      #!   (paths in this section are relative to _this_ test file)
      fixtures:
        #! corresponds to the ytt `--data-values-file` flag
        data-values-file:
          - values.yaml

    #! Then, run `ytt` with these files...
    #!   (paths in this section are relative to _this_ test file)
    expected:
      file:
        - expected/
    ```
3. create the fixture(s) for the test

    ```yaml
    #! .ytt-tests/values.yaml
    ---
    instances: 7
    ```

4. in the parent directory of `.ytt-tests` run the test runner

    ```console
    $ ytt-test.sh
    fail  .ytt-tests/sample.test.yaml
            ==> .ytt-test-out/sample/result.diff

    FAILURE
    ```
5. examine the "actual" result and if acceptable, make it the "expected"

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
