/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeStream{

    string constant NAME="Decentralized Stream";
    string constant COIN_SYMBOL="DAI";
    struct _Event{
        // string uri;
        string name;
        string description;
        uint start;
        string coinSymbol;
        uint256 value;
        address operatorWallet;
    }

    _Event[] private events;
    uint private eventCount;
    constructor(){
    }
    

    function createEvent(string calldata name,string calldata desc,uint start,uint256 value) external returns(bool){
        _Event memory createdEvent = _Event(name,desc,start,COIN_SYMBOL,value,msg.sender);
        events[eventCount++]=createdEvent;
        return true;
    }

    function getEvents() external view returns(_Event[] memory){
        return events;
    }

    function purchaseEvent(uint eventId) external payable{
        require(msg.value >= events[eventId].value);
        payable(events[eventId].operatorWallet).transfer(events[eventId].value);
    }


}