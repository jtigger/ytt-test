## Use Cases

⚠️ Only _some_ of the following use cases are implemented.⚠️

### Use Case: A Full ytt Library with Evaluated Results

```yaml
---
name: Presents defaults
actual: ytt -f ${YTT_SUBJECT}/config --data-values-file default-values.yaml
expected: ytt -f default/
```
- both `actual:` and `expected:` are evaluated with the `--dangerous-emptied-output-directory` appended.


### Use Case: A Full ytt Library against inline standard out

```yaml
---
name: Presents defaults
actual: ytt -f ${YTT_SUBJECT}/config --data-values-file default-values.yaml
expected_out: |
  standard out output
  ...
```
- `acutal:` is evaluated, as-is (i.e. to `actual.stdout`)
- `expected:` is compared against `actual.stdout` both pre-processed with `ytt fmt -` (to avoid minor textual differences)

#### Idiom: Single function from library

`foo.test.yaml`
```yaml
---
actual: |
  ytt -f ${YTT_SUBJECT}/config/helpers.lib.yml -f foo.test.yaml=<(cat << EOF
  #@ load("helpers.lib.yml", "foo")
  first: #@ foo("thing", 1)
  second: #@ foo("thing", 2)
  EOF
  )
expected_out: |
  first:
    foo: thing-1
  second:
    foo: thing-2
```
- `acutal:` is evaluated

diff <( yq -r .actual foo.test.yaml | bash | ytt fmt -f - ) <( yq -r .expected_out foo.test.yaml | ytt fmt -f - )

### Use Case: A Full ytt Library erroring against inline standard error

```yaml
---
actual: ytt -f ${YTT_SUBJECT}/config --data-values-file default-values.yaml
expected_err: |
  Error: ytt: something went wrong...
  More details
...
```
- `acutal:` is evaluated, as-is (i.e. to `actual.stderr`)
- expects that `actual:` will result in a non-zero exit status.
- `expected_err:` is compared against `actual.stderr`

### Use Case: A Full ytt Library erroring against a file containing standard error

```yaml
---
actual: ytt -f ${YTT_SUBJECT}/config --data-values-file default-values.yaml
expected_err_path: expected.stderr
```
- `acutal:` is evaluated, as-is (i.e. to `actual.stderr`)
- expects that `actual:` will result in a non-zero exit status.
- contents of file at `expected_err_path:` is compared against `actual.stderr`
