/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Fund{
    address public masterAddress;

    struct Member{
        address _Address;
        uint _Money;
        string _Name;
    }
    Member[] public ListDeposit;

    constructor(){
        masterAddress = msg.sender;
    }

    event NewDepositCome(address _address, uint _amount, string _name);

    function Deposit(string memory user) public payable{
        require(msg.value>=100000000000000, "[0] Sorry, money must be minimum 0.02ETH");
        ListDeposit.push(Member(msg.sender,msg.value,user));
        emit NewDepositCome(msg.sender, msg.value, user);
    }
    function MembersCounter() public view returns(uint){
        return ListDeposit.length;
    }
    function getMember(uint ordering) public view returns(address, uint, string memory){
        require(ordering<ListDeposit.length,"[1] Sorry, there is no member deposited");
        return(ListDeposit[ordering]._Address, ListDeposit[ordering]._Money, ListDeposit[ordering]._Name);
    }
    modifier checkMaster(){
        require(msg.sender==masterAddress,"[2] Sorry, you are not allowed to withdraw");
        _;
    }
    function withdraw() public checkMaster{
        payable(msg.sender).transfer(address(this).balance);
    }
}