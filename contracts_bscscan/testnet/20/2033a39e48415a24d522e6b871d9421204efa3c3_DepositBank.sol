/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

pragma solidity ^0.8.0;


contract DepositBank {
    //mapping(address => uint) public balances;
    uint256 constant FUNDING_GOAL = 0.01 ether;
    address constant TEAM_ADDRESS = address(0xF3e35B1293937003B092BB15f7B2cED87faf1405);

    function withdraw() external {
        require(address(this).balance >= FUNDING_GOAL, 'Haven\'t reached the funding goal');
        payable(TEAM_ADDRESS).transfer(address(this).balance);
    }
    
    function getBalance() public view returns (uint) {
      return address(this).balance;
    }
    
    
    
    receive() external payable {}
}