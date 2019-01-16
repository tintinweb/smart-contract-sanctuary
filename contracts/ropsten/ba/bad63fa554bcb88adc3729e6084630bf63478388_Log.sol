pragma solidity ^0.4.8;

contract Log
{
    // state variables

    address private logOwnerAddr;

    // events

    event logOwnerChanged(address oldAddr, address newAddr);
    event logBlockAdded(uint indexed customerId, uint indexed logType, uint timestamp, string logBlockAddr);

    // function modifiers

    modifier onlyLogOwner()
    {
        require(msg.sender == logOwnerAddr);
        _;
    }

    modifier validateParamsA(address addr)
    {
        require(addr != address(0));
        _;
    }

    modifier validateParamsLogData(uint customerId, uint logType, uint timestamp, string logBlockAddr)
    {
        //require(customerId > 0);
        //require(logType > 0);
        //require(timestamp > 0);
        require(bytes(logBlockAddr).length > 0);
        _;
    }

    // constructor

    constructor(address ownerAddr)
        validateParamsA(ownerAddr)
        public
    {
        // set log owner        
        logOwnerAddr = ownerAddr;
    }

    // functions

    function changeLogOwner(address ownerAddr)
        onlyLogOwner
        validateParamsA(ownerAddr)
        public
    {
        // change log owner
        address oldAddr = logOwnerAddr;
        logOwnerAddr = ownerAddr;

        // emit event
        emit logOwnerChanged(oldAddr, ownerAddr);
    }

    function addLogBlock(uint customerId, uint logType, uint timestamp, string logBlockAddr)
        onlyLogOwner
        validateParamsLogData(customerId, logType, timestamp, logBlockAddr)
        public
    {
        // emit event
        emit logBlockAdded(customerId, logType, timestamp, logBlockAddr);
    }

    // views

    function getLogOwnerAddr()
        public
        view
        returns(address)
    {
        return logOwnerAddr;
    }
}