/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

pragma solidity ^0.4.26;

contract AddressTest {
    
    event Transfered(address to, uint amount);
    event Sent(address to, uint amount, bool successed);

    //Get the ether balance of a certian address
    function getBalanceOf(address _addr) public view returns(uint) {
        return _addr.balance;
    }
    
    //Get the ether balance of this very contract
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    //Transfer to a specific address from this contract
    function transferTo(address to, uint amount) public payable {
        to.transfer(amount);
        emit Transfered(to,amount);
    }
    
    //Send to a specific address from this contract
    function sendTo(address to, uint amount) public  payable {
        bool result = to.send(amount);
        emit Sent(to,amount,result);
    }
    
    //Fallback function used to accept ether
    function () payable public {  
    }
}