# Akce monorepo split

### Použití na projektu:

```yml
on:
  workflow_dispatch:
  push:
    branches:
      - 'main'
concurrency:
  group: split_monorepo-${{ github.ref_name }}-${{ github.ref }}
  cancel-in-progress: true

name: Monorepo split
jobs:
  split-branch:
    uses: peckadesign/.github/.github/workflows/split_monorepo.yaml@master
    name: Split branch
    strategy:
      fail-fast: false
      matrix:
        package:
          - repo-admin
          - repo-sdk
    with:
      package: ${{ matrix.package }}
    secrets:
      gh-token: ${{ secrets.ACCESS_TOKEN }}

```
