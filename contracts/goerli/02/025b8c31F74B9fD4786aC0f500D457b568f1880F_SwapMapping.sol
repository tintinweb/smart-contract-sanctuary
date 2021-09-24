library SwapMapping {
    struct Map {
        uint256[] tradableNfts;
        mapping(uint256 => uint256) price;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function get(Map storage map, uint256 nftId)
        external
        view
        returns (uint256)
    {
        return map.price[nftId];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        external
        view
        returns (uint256)
    {
        return map.tradableNfts[index];
    }

    function size(Map storage map) external view returns (uint256) {
        return map.tradableNfts.length;
    }

    function set(
        Map storage map,
        uint256 key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.price[key] = val;
        } else {
            map.inserted[key] = true;
            map.price[key] = val;
            map.indexOf[key] = map.tradableNfts.length;
            map.tradableNfts.push(key);
        }
    }

    function remove(Map storage map, uint256 key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.price[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.tradableNfts.length - 1;
        uint256 lastKey = map.tradableNfts[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.tradableNfts[index] = lastKey;
        map.tradableNfts.pop();
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}