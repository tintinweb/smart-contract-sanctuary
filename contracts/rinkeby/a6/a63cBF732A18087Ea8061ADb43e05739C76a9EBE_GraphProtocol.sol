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
    IGraphProtocolInterface public graphProxy;
    IERC20Interface public grtTokenAddress;
    constructor(address _grtTokenAddress, address _graphProxy) public {
        grtTokenAddress = IERC20Interface(_grtTokenAddress);
        graphProxy = IGraphProtocolInterface(_graphProxy);
    }


    event LogDelegate(address _caller, address _current);

    function delegate(address _indexer, uint256 _tokens)
        public
        returns (uint256 shares_)
    {
        emit LogDelegate(msg.sender, address(this));
        // IERC20Interface(grtTokenAddress).transferFrom(msg.sender, address(this), _tokens);
        // IERC20Interface(grtTokenAddress).approve(address(graphProxy), _tokens);
        // shares_ = graphProxy.delegate(_indexer, _tokens);
        // emit GraphProtocolDelegated(_indexer, _tokens, shares_);
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