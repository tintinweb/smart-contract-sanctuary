/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.10;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PtxTokens{
    using SafeMath for uint256;

    address public governance;
    constructor() {
        governance = msg.sender;
    }
    
    // user deposit
    function deposit(
        address tokenAddress,
        uint256 amount
    ) public {

        ERC20 token = ERC20(tokenAddress);
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSelector(
            token.transferFrom.selector,
            msg.sender,
            address(this),
            amount
        );
        tokenAddress.call(callData);

        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter >= exchangeBalanceBefore, "OVERFLOW");
        require(
            exchangeBalanceAfter == exchangeBalanceBefore + amount,
            "INCORRECT_AMOUNT_TRANSFERRED"
        );
        
//        if (isContract(tokenAddress)) {
//            
//        } else {
//            revert("UNSUPPORTED_TOKEN_TYPE");
//        }
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
        
//        if (isContract(tokenAddress)) {
//            
//        } else {
//            revert("UNSUPPORTED_TOKEN_TYPE");
//        }
    }

    function isContract(address tokenAddress) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(tokenAddress)
        }
        return size > 0;
    }
    
}