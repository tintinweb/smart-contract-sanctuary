pragma solidity 0.5.12;

import "./MPool.sol";

contract MFactory is MBronze {
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
    );

    address private _lpMining;
    address private _swapMining;

    mapping(address => bool) private _isMPool;
    mapping(address => bool) private _isWhiteList;

    function isMPool(address b)
    external view returns (bool)
    {
        return _isMPool[b];
    }

    function isWhiteList(address w)
    external view returns (bool)
    {
        return _isWhiteList[w];
    }

    function newMPool()
    external
    returns (MPool)
    {
        MPool mpool = new MPool();
        _isMPool[address(mpool)] = true;
        emit LOG_NEW_POOL(msg.sender, address(mpool));
        mpool.setController(msg.sender);
        return mpool;
    }

    address private _mlabs;
    address public feeTo;

    constructor() public {
        _mlabs = msg.sender;
    }

    function getMLabs()
    external view
    returns (address)
    {
        return _mlabs;
    }

    function getFeeTo()
    external view
    returns (address)
    {
        return feeTo;
    }

    function setMLabs(address b)
    external
    {
        require(msg.sender == _mlabs, "ERR_NOT_BLABS");
        _mlabs = b;
    }

    function setFeeTo(address b)
    external
    {
        require(msg.sender == _mlabs, "ERR_NOT_BLABS");
        feeTo = b;
    }

    function updateWhiteList(address w, bool status)
    external
    {
        require(msg.sender == _mlabs, "ERR_NOT_MLABS");
        _isWhiteList[w] = status;
    }

    function getMining()
    external view
    returns (address lpMiningAdr, address swapMiningAdr)
    {
        return (_lpMining, _swapMining);
    }

    function setMining(address lpMining, address swapMining)
    external
    {
        require(msg.sender == _mlabs, "ERR_NOT_MLABS");
        _lpMining = lpMining;
        _swapMining = swapMining;
    }

}