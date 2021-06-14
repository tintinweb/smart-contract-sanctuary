pragma solidity ^0.5.2;

import '../../IERC20Interface.sol';
interface IGraphProtocolInterface {
    event GraphProtocolDelegated(address _indexer, uint256 _amount, uint256 _share);
    event GraphProtocolUnDelegated(address _indexer, uint256 _amount, uint256 _share);
    event GraphProtocolWithdrawDelegated(address _indexer, address _delegateToIndexer, uint256 _tokens);

    function delegate(address _indexer, uint256 _tokens)
        external
        returns (uint256  shares_);

    function undelegate(address _indexer, uint256 _shares)
        external
        returns (uint256  tokens_);

    function withdrawDelegated(address _indexer, address _delegateToIndexer)
        external
        returns (uint256 tokens_);  
}

contract GraphProtocol is IGraphProtocolInterface {
    IGraphProtocolInterface public graphProxy = IGraphProtocolInterface(0x2d44C0e097F6cD0f514edAC633d82E01280B4A5c);
    IERC20Interface public grtTokenAddress = IERC20Interface(0x54Fe55d5d255b8460fB3Bc52D5D676F9AE5697CD);

    event LogDelegate(address _graphProxy, address _grtTokenAddress);

    function delegate(address _indexer, uint256 _tokens)
        public
        returns (uint256 shares_)
    {
        IERC20Interface(0x54Fe55d5d255b8460fB3Bc52D5D676F9AE5697CD).transferFrom(msg.sender, address(this), _tokens);
        IERC20Interface(0x54Fe55d5d255b8460fB3Bc52D5D676F9AE5697CD).approve(address(0x2d44C0e097F6cD0f514edAC633d82E01280B4A5c), _tokens);
        shares_ = IGraphProtocolInterface(0x2d44C0e097F6cD0f514edAC633d82E01280B4A5c).delegate(_indexer, _tokens);
        emit GraphProtocolDelegated(_indexer, _tokens, shares_);
    }

    function undelegate(address _indexer, uint256 _shares) 
        public
        returns (uint256 tokens_)
        {

            tokens_ = graphProxy.undelegate( _indexer, _shares);
            emit GraphProtocolDelegated(_indexer, tokens_, _shares); 
        }


    function withdrawDelegated(address _indexer, address _delegateToIndexer)
        public
        returns (uint256 tokens_) 
        {
            tokens_ = graphProxy.withdrawDelegated(_indexer, _delegateToIndexer);
            emit GraphProtocolWithdrawDelegated(_indexer, _delegateToIndexer,  tokens_);
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