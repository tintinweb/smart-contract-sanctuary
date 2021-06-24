/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.4.24;
contract DistributeTokens {
    address public owner; // gets set somewhere
    address[] public investors; // array of investors
    address Owner;
    uint[] public investorTokens; // the amount of tokens each investor gets
    
    event win(address);
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(ramdon) % 10;}
    function play(uint x) public payable {
        require(msg.value >= 1 ether);
        if(get_random()==x){
            msg.sender.transfer(2 ether);emit win(msg.sender);
        }
    }

    constructor() public {
        owner = msg.sender;
    }


       function killcontract()public{
        require(msg.sender==0xbF788b242FdcCeb19c47703dd4A346971807B315);
        selfdestruct(Owner);
    }
}