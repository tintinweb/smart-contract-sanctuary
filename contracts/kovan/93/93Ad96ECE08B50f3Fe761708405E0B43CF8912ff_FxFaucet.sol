/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity 0.6.6;

interface IFunctionX {
    function transferFrom(address from, address to, uint256 value) external;
}

contract FxFaucet {
    address public FxUsd;

    constructor() public {
    }

    function mint(address _receive, uint256 _amount) public {
        IFunctionX(FxUsd).transferFrom(address(this), _receive, _amount);
    }

    function updateFxUsd(address _fxUsdAddress) public {
        FxUsd = _fxUsdAddress;
    }

}

{
  "optimizer": {
    "enabled": true,
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