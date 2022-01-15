/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract fund{
    address public masterAddress;
    constructor () {
        masterAddress = msg.sender;
    }

    struct Member {
        address Wallet;
        string Name;
        uint Money;
    }

    Member[] public listDeposit;

    function Deposit(string memory user) public payable{
        require(msg.value >= 10000000000000000,"[1] Money must be minimum 0.01ETH");
        listDeposit.push(Member(msg.sender, user, msg.value));
    }

    function MemberCount() public view returns(uint){
        return listDeposit.length;
    }

    function getMember(uint ordering) public view returns (address, string memory, uint){
        require(ordering < MemberCount(),"[3] Sorry, there no number deposited");
        return (listDeposit[ordering].Wallet, listDeposit[ordering].Name, listDeposit[ordering].Money);
    }

    modifier checkMaster(){
        require(msg.sender == masterAddress,"[2] You are not owner");
        _;
    }

    function Withdraw() public checkMaster{
        payable(msg.sender).transfer(address(this).balance);
    }
}