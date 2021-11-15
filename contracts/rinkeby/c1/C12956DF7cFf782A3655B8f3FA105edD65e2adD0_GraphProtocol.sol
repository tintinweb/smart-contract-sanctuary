pragma solidity ^0.5.2;

import "../../IERC20Interface.sol";

interface IGraphProtocolInterface {
    event GraphProtocolDelegated(
        address _indexer,
        uint256 _amount,
        uint256 _share
    );
    event GraphProtocolUnDelegated(
        address _indexer,
        uint256 _amount,
        uint256 _share
    );
    event GraphProtocolWithdrawDelegated(
        address _indexer,
        address _delegateToIndexer,
        uint256 _tokens
    );

    function delegate(address _indexer, uint256 _tokens)
        external
        returns (uint256 shares_);

    function undelegate(address _indexer, uint256 _shares)
        external
        returns (uint256 tokens_);

    function withdrawDelegated(address _indexer, address _delegateToIndexer)
        external
        returns (uint256 tokens_);
}

contract GraphProtocol is IGraphProtocolInterface {
    IGraphProtocolInterface public constant graphProxy =
        IGraphProtocolInterface(0x2d44C0e097F6cD0f514edAC633d82E01280B4A5c);
    IERC20Interface public constant grtTokenAddress =
        IERC20Interface(0x54Fe55d5d255b8460fB3Bc52D5D676F9AE5697CD);

    event LogDelegate(address _graphProxy, address _grtTokenAddress);

    function delegate(address _indexer, uint256 _tokens)
        public
        returns (uint256 shares_)
    {
        grtTokenAddress.transferFrom(msg.sender, address(this), _tokens);
        shares_ = _delegate(_indexer, _tokens);
    }

    // It assumes that contract already have funds
    function chainedDelegate(address _indexer, uint256 _tokens)
        public
        returns (uint256 shares_)
    {
        shares_ = _delegate(_indexer, _tokens);
    }

    function _delegate(address _indexer, uint256 _tokens)
        private
        returns (uint256 shares_)
    {
        grtTokenAddress.approve(address(graphProxy), _tokens);
        shares_ = graphProxy.delegate(_indexer, _tokens);
        grtTokenAddress.approve(address(graphProxy), 0);
        emit GraphProtocolDelegated(_indexer, _tokens, shares_);
    }

    function undelegate(address _indexer, uint256 _shares)
        public
        returns (uint256 tokens_)
    {
        tokens_ = graphProxy.undelegate(_indexer, _shares);
        emit GraphProtocolDelegated(_indexer, tokens_, _shares);
    }

    function withdrawDelegated(address _indexer, address _delegateToIndexer)
        public
        returns (uint256 tokens_)
    {
        tokens_ = graphProxy.withdrawDelegated(_indexer, _delegateToIndexer);
        grtTokenAddress.transfer(msg.sender, tokens_);
        emit GraphProtocolWithdrawDelegated(
            _indexer,
            _delegateToIndexer,
            tokens_
        );
    }
}

interface IERC20Interface {
    function allowance(address, address) external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

