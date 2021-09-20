/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MyContract {
    function withdrawToken(address _tokenContract, uint256 _amount) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }
    function withdrawTokenTo(address _tokenContract, uint256 _amount, address recipient) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        tokenContract.transfer(recipient, _amount);
    }
}