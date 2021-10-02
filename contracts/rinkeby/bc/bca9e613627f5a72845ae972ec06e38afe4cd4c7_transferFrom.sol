/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

pragma solidity >=0.7.0 <0.9.0;

contract transferTo {
    
    fallback() external payable {
        
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}

contract transferFrom {
    
    transferTo tt;
    
    constructor() {
        tt = new transferTo();
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function getBalanceTo() public view returns(uint){
        return tt.getBalance();
    }
    
    fallback() external payable{
        payable(address(tt)).transfer(msg.value);
    }
    
}