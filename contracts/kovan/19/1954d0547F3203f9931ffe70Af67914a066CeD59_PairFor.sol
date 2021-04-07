pragma solidity 0.5.0;

/**
 * @title PairFor
 * @dev Retreive a uniswap pair address created with create2
 */
contract PairFor {
    address factory = 0xD3E51Ef092B2845f10401a0159B2B96e8B6c3D30;

    function getPairFor(address token0, address token1)
        internal
        view
        returns (address pair)
    {
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
        return pair;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}