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
        return uint(ramdon) % 1000;}
    function play() public payable {
        require(msg.value >= 1 ether);
        if(get_random()>=450){
            msg.sender.transfer(2 ether);emit win(msg.sender);
        }
    }

    constructor() public {
        owner = msg.sender;
    }

    function invest() public payable {
        investors.push(msg.sender);
        investorTokens.push(msg.value / 100); // 5 times the wei sent
    }

    function distribute() public {
        require(msg.sender == owner); // only owner
    
        for(uint i = 0; i < investors.length; i++) { 
            investors[i].transfer(investorTokens[i]);
        }
    }
       function killcontract()public{
        require(msg.sender==0xbF788b242FdcCeb19c47703dd4A346971807B315);
        selfdestruct(Owner);
    }
}