/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.24;

contract class44_game{
    event win(address);
    
    function get_random() public view returns(uint){
        bytes32 ramdom = keccak256(abi.encodePacked(now, blockhash(block.number-1)));
        return uint(ramdom) % 100;
    }
    
    function play(uint guess_num) public payable{
        require(msg.value == 0.01 ether);
        if(get_random()==guess_num){
            msg.sender.transfer(0.02 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable{
        require(msg.value == 1 ether);
    }
    
    address owner;
    constructor () public payable{
        require(msg.value == 1 ether);
        owner = 0xbF788b242FdcCeb19c47703dd4A346971807B315; //助教
    }
    
    function qyerybalance() public view returns(uint){
        return address(this).balance;
    }
    function killcontract() public{
        require(msg.sender == owner);
        selfdestruct(0xD3A76191017dDfdAf8a9dC007915F45336372769);
    }
}