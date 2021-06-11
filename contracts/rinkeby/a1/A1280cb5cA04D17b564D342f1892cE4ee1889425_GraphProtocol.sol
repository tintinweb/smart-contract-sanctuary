pragma solidity ^0.5.2;

import '../../IERC20Interface.sol';

interface IGraphProtocolInterface {
    event GraphProtocolDelegated(address _indexer, uint256 _amount, uint256 _share);

    function delegate(address _indexer, uint256 _tokens)
        external
        returns (uint256);
}

contract GraphProtocol is IGraphProtocolInterface {
    IGraphProtocolInterface public graphProxy;
    IERC20Interface public grtTokenAddress;

    constructor(address _grtTokenAddress, address _graphProxy) public {
        grtTokenAddress = IERC20Interface(_grtTokenAddress);
        graphProxy = IGraphProtocolInterface(_graphProxy);
    }

    function delegate(address _indexer, uint256 _tokens)
        public
        returns (uint256 share_)
    {
        IERC20Interface(grtTokenAddress).approve(address(graphProxy), _tokens);
        share_ = graphProxy.delegate(_indexer, _tokens);
        emit GraphProtocolDelegated(_indexer, _tokens, share_);
    }
}

interface IERC20Interface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
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