/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.8.4;

interface mintableERC20 {
    function mint(uint256 amount) external returns (bool success);
}

contract iMint {
    
    uint256 receiveAmount = 10; 
    
    function A(uint256 _amount, address _mint) public returns (bool) {
        require(_amount == receiveAmount, "Amount doesn't match received amount");
        mintt(_mint);
        
    }
    
    function mintt(address _mint) internal {
        mintableERC20(_mint).mint(receiveAmount);
    }
}