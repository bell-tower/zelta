# Running tests with shellspec

- after installing `shellspec`
- cd repo root for `zelta`
- `shellspec`



## TODOS

#### done
- backup
- match
- rotate

#### to add
- snapshot
- revert
- clone 
  - introduce NEW_CLONE=new
  - todo: clone to new place ($SRC_DS/$NEW_CLONE)
  - todo: rotate from clone

#### next release:
- prune

#### Notes:
-  snapshot (meta data capture)
   - zfs snapshot / just run zelta snapshot and check output
   - special thing for snapshot:
     - `zelta snapshot remote:pool/dataset@my-snap-name`
     - `zelta snapshot --snap-name="my-snap-name" remote:pool/dataset`
- sync (just -i, don't worry about)
- wait on: policy (consider repeating test with policy)
