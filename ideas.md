# Ideas

## Map generation algorithm

Islands:
- keeps the indices on the tiles as they are
- groups the indics (i.e by 10)
- put walls only on the surrouding of the group
    - the romm should be empty
- place the next index as usual and dig the wall

This may improve the map generation by creating rooms and avoid some weird walls placed nowhere
