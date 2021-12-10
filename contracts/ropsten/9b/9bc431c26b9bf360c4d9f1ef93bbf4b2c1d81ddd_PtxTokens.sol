/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.10;

interface ERC20 {

//    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

//    function allowance(address owner, address spender) external view returns (uint256);

//    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);

//    event Transfer(address indexed from, address indexed to, uint256 value);

//    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PtxTokens{

    address public governance;
    constructor() {
        governance = msg.sender;
    }


    /*
        * @param  tokenAddress  USDT/USDC/DAI的合约地址.
        * @param  amount  已经乘过小数的值.
    */
    function deposit(
        address tokenAddress,
        uint256 amount
    ) public {
        if (isContract(tokenAddress)) {
            ERC20 token = ERC20(tokenAddress);
            uint256 exchangeBalanceBefore = token.balanceOf(address(this));
            token.transferFrom(
                msg.sender,
                address(this),
                amount
            );
         
            uint256 exchangeBalanceAfter = token.balanceOf(address(this));
            require(exchangeBalanceAfter >= exchangeBalanceBefore, "OVERFLOW");
            require(
                exchangeBalanceAfter == exchangeBalanceBefore + amount,
                "INCORRECT_AMOUNT_TRANSFERRED"
            );
        } else {
            revert("UNSUPPORTED_TOKEN_TYPE");
        }
    }

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    function setGovernance(address governanceAddress) public onlyGovernance{
        governance = governanceAddress;
    }
    
    function withdraw(
        address payable recipient,
        address tokenAddress,
        uint256 amount
    ) public onlyGovernance{
        if (isContract(tokenAddress)) {
            require(msg.sender == governance,"SENDER_FAIL");
            ERC20 token = ERC20(tokenAddress);
            uint256 exchangeBalanceBefore = token.balanceOf(address(this));
            token.transfer(
                recipient,
                amount
            );
            uint256 exchangeBalanceAfter = token.balanceOf(address(this));
            require(exchangeBalanceAfter <= exchangeBalanceBefore, "UNDERFLOW");
            // NOLINTNEXTLINE(incorrect-equality): strict equality needed.
            require(
                exchangeBalanceAfter == exchangeBalanceBefore - amount,
                "INCORRECT_AMOUNT_TRANSFERRED"
            );
        } else {
            revert("UNSUPPORTED_TOKEN_TYPE");
        }
    }

    function isContract(address tokenAddress) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(tokenAddress)
        }
        return size > 0;
    }
    
}