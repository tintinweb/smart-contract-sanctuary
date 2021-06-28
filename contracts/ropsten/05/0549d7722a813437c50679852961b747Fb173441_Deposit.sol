/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface CERC20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

contract Deposit {

    event MyLog(string, uint256);

    mapping(address => mapping (address => uint256)) public balances;

    mapping(address => mapping (address => uint256)) public c_balances;

    mapping(address => mapping (address => uint256))  allowed;


    using SafeMath for uint256;


    function lock(address token, uint256 amount) public {
        require(
            amount <= IERC20(token).balanceOf(msg.sender), 
            "Token balance is too low"
        );
        require(
            IERC20(token).allowance(msg.sender, address(this)) >= amount,
            "Token allowance too low"
        );
        balances[msg.sender][token] = balances[msg.sender][token].add(amount);
        bool sent = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(sent, "Token transfer failed");
    }
    
    function unlock(address token, uint256 amount) public {
        require(
             IERC20(token).balanceOf(msg.sender) >= amount, 
            "The balance on the deposit is too low"
        );
        balances[msg.sender][token]  = balances[msg.sender][token].sub(amount);
        bool sent = IERC20(token).transfer(msg.sender, amount);
        require(sent, "Token transfer failed");
    }

    function supplyErc20ToCompound(
        address token,
        address c_token,
        uint256 amount
    ) public returns (uint) {
        // Create a reference to the underlying asset contract, like DAI.
        IERC20 underlying = IERC20(token);

        // Create a reference to the corresponding cToken contract, like cDAI
        CERC20 cToken = CERC20(c_token);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up)", supplyRateMantissa);

        // Approve transfer on the ERC20 contract
        underlying.approve(c_token, amount);

        // Mint cTokens
        uint mintResult = cToken.mint(amount);
        
        balances[msg.sender][token] = balances[msg.sender][token].sub(amount);
        c_balances[msg.sender][token] = c_balances[msg.sender][token].add(amount);

        return mintResult;
    }
}

library SafeMath {
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