/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

pragma solidity ^0.8.0;

contract SplitPayment{
    
    address owner;
    
    constructor(address _owner){
        owner = _owner;
    }
    
    function Send(address payable[] memory to, uint[] memory amount) public onlyOwner payable{
        require(to.length == amount.length, 'length is not equal');
        for(uint i = 0; i < to.length; i++){
            to[i].transfer(amount[i]);
        }
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner,"only owner can send");
        _;
    }
}