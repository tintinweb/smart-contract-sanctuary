/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: unlicensed

pragma solidity 0.8.7;

contract ClashRoyale{

    uint private counter = 0;

    struct player{
        address addr;
        string tag;
        bool creator;
    }

    struct wager{
        player first;
        player second;
        uint time;
        uint bet;
        uint id;
    }

    mapping(uint => wager) private myWagers;

    modifier isZero(string memory _tag){
        require(msg.value != 0, "Value must be greater than zero.");
        string memory empty = "";
        require(keccak256(bytes(_tag)) != keccak256(bytes(empty)));
        _;
    }

    modifier scnd(uint _id){
        require(myWagers[_id].first.addr != address(0), "Wrong Match ID");
        require(myWagers[_id].bet == msg.value, "Bet must be equal");
        require(myWagers[_id].second.addr == address(0), "Second player already set");
        require(myWagers[_id].first.addr != msg.sender); 
        _;
    }

    modifier isPlayer(uint _id){
        require(msg.sender == myWagers[_id].first.addr || myWagers[_id].second.addr == msg.sender, "You are not a player of this Wager");
        _;
    }

    function newWager(string memory _tag)payable external isZero(_tag) returns(uint _id){
        myWagers[counter].first.addr = msg.sender;
        myWagers[counter].first.tag = _tag;
        myWagers[counter].bet = msg.value;
        counter++;
        return counter - 1;
    }

    function joinWager(uint _id, string memory _tag)payable external isZero(_tag) scnd(_id){
        myWagers[_id].second.addr = msg.sender;
        myWagers[_id].second.tag = _tag;
        myWagers[_id].time = block.timestamp;
    }

    function cancelWager(uint _id)public isPlayer(_id)returns(bool success){
        require(block.timestamp - myWagers[_id].time >= 1 seconds);
        payable(myWagers[_id].first.addr).transfer(myWagers[_id].bet);
        if(myWagers[_id].second.addr != address(0)) payable(myWagers[_id].second.addr).transfer(myWagers[_id].bet);
        return deleteWager(_id);
    }

    function getBet(uint _id)external isPlayer(_id)returns(bool success){
        bool sender = msg.sender == myWagers[_id].first.addr;
        int result;
        if(result <= -4 || result == 0)return cancelWager(_id);
        if(result < 0) {
            if(sender) payable(myWagers[_id].second.addr).transfer(myWagers[_id].bet * 2);
            else payable(myWagers[_id].first.addr).transfer(myWagers[_id].bet * 2);
        }
        else if(sender)payable(myWagers[_id].first.addr).transfer(myWagers[_id].bet * 2);
        else payable(myWagers[_id].second.addr).transfer(myWagers[_id].bet * 2);
        return deleteWager(_id);
    }

    function deleteWager(uint _id)private returns(bool success){
        delete(myWagers[_id]);
        return true;
    }

}