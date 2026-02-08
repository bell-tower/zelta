# Running tests with shellspec

- after installing `shellspec`
- cd repo root for `zelta`
- `shellspec`
 
- Setup your test user on your source and target machines
  - update sudoers, for example on Linux
    - create /etc/sudoers.d/zelta-tester
    ```
    # Allow (mytestuser) to run ZFS commands without password for zelta testing
    # NOTE: This is for test environments only - DO NOT use in production
    # CAUTION: The wildcards show intent only, with globbing other commands may be allowed as well
    (mytestuser) ALL=(ALL) NOPASSWD: /usr/bin/dd *, /usr/bin/rm -f /tmp/*, /usr/bin/truncate *, /usr/sbin/zpool *, /usr/sbin/zfs *    
    ```
   - TODO: confirm if usr/bin/mount *, /usr/bin/mkdir * are needed
 
  - setup zfs allow on your source and target machines for each pool you're testing with 
   ```shell
   sudo zfs allow dever rename,mount,create (poolname)
   ```

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
