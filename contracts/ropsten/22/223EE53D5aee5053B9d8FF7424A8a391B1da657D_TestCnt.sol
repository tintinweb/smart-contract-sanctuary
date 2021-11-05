/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity >=0.7.0 <0.9.0;

contract TestCnt {
    
    event MoneyDeposited(uint256 amount);    
    
    function deposit() public payable {
        emit MoneyDeposited(msg.value);
    }
    
    function balance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function withdraw() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function callMe(uint256 id, string memory name) public {
        emit MoneyDeposited(id);
    }
}