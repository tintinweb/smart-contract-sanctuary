/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Scatter {
    function scatterEther(address[] memory recipients, uint256[] memory values) external payable {
        
        for (uint256 i = 0; i < recipients.length; i++){
            payable(recipients[i]).transfer(values[i]);
        }
        
        uint256 balance = address(this).balance;
        
        if (balance > 0){
            payable(msg.sender).transfer(balance);
        }
    }

    function scatterToken(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++){
            total += values[i];
        }
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++){
            require(token.transfer(recipients[i], values[i]));
        }
    }

    function scatterTokenSimple(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        for (uint256 i = 0; i < recipients.length; i++){
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
        }
    }
}