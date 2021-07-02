/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity 0.6.10;
contract Hello{
    
    
    receive() payable external {}
    string public name = "hello,world"; 
    function setName(string memory _name) external{
        name = _name;
    }
    function getName() external view returns(string memory){
        return name;
    }
    
    function reviceETH() payable external{
        (bool success,) = msg.sender.call{value:address(this).balance/2}(new bytes(0));
    }
    
    function getBalance() view external returns(uint256){
        return address(this).balance;
        
    }
    
    
}