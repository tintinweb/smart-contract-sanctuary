/**
 *Submitted for verification at Etherscan.io on 2020-12-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IAAVEDepositWithdraw {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address token, uint256 amount, address destination) external;
    function getReservesList() external view returns (address[] memory);
}

interface IERC20ApproveTransferFrom { 
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// tester contract for aave protocol deposit / withdraw 
contract AaveDepositWithdrawTest {
    address aave;
    address owner;
    
    constructor(address[] memory approvedAssets) public {
        for (uint256 i = 0; i < approvedAssets.length; i++) {
            IERC20ApproveTransferFrom(approvedAssets[i]).approve(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9, type(uint256).max); // max approve aave for deposit into aToken 
        }
        
        aave = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
        owner = msg.sender; // set deployer as owner of contract
    }
    
    function deposit(address token, uint256 amount) external {
        IERC20ApproveTransferFrom(token).transferFrom(msg.sender, address(this), amount);
        IAAVEDepositWithdraw(aave).deposit(token, amount, address(this), 0);
    }
    
    function withdraw(address token, uint256 amount) external {
        IAAVEDepositWithdraw(aave).withdraw(token, amount, msg.sender);
    }
    
    function getAaveReserves() external view returns (address[] memory) {
        address[] memory reserves = IAAVEDepositWithdraw(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9).getReservesList();
        return reserves;
    }
}