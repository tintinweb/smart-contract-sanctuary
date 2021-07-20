/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// File: erc20_base.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: simple_semi_dex.sol

/**
* @title A very simple example Decentralized Exchange Simulation
* @notice This smart contract is part of an assignment for learning purpose only
*/
contract SimpleSemiDex {
    using SafeMath for uint256;
    
    // Token address to account addresses with deposited token amount
    mapping(IERC20 => mapping(address => uint256)) public tokens;
    
    /**
     * @notice Event emitted upon token deposit
     */
    event Deposit(IERC20 indexed token, address indexed user, uint256 indexed amount, uint256 balance);
    
    /**
     * @notice Event emitted upon token withdrawal
     */
    event Withdraw(IERC20 indexed token, address indexed user, uint256 indexed amount, uint256 balance);
    
    /**
     * @notice End User can deposit ERC20 tokens into the SimpleSemiDex contract
     * This contract must be approved by the Token contract to deposit tokens
     * Emits a {Deposit} event.
     * @param token Contract Address of the ERC20 token user wants to deposit
     * @param amount Amount of the ERC20 tokens to deposit
     */
    function depositToken(IERC20 token, uint256 amount) public {
        require(IERC20(token) != IERC20(address(0)), 'Token address cannot be zero address');
        require(amount > 0, 'Deposit amount should be greater than 0');
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokens[IERC20(token)][msg.sender] = tokens[IERC20(token)][msg.sender].add(amount);
        emit Deposit(IERC20(token), msg.sender, amount, tokens[IERC20(token)][msg.sender]);
    }
    
    /**
     * @notice End User can deposit Ethers into the SimpleSemiDex contract
     * Emits a {Deposit} event.
     */
    function deposit() public payable {
        require(msg.value > 0, 'Deposit amount should be greater than 0');
        tokens[IERC20(address(0))][msg.sender] = tokens[IERC20(address(0))][msg.sender].add(msg.value);
        emit Deposit(IERC20(address(0)), msg.sender, msg.value, tokens[IERC20(address(0))][msg.sender]);
    }
    
    /**
     * @notice End User can withdraw the deposited ERC20 tokens/Ethers from the SimpleSemiDex contract
     * Emits a {Withdraw} event.
     * @param token Contract Address of the ERC20 token user wants to deposit
     * @param amount Amount of the ERC20 tokens to deposit
     */
    function withdraw(IERC20 token, uint256 amount) public {
        require(amount > 0, 'Withdrawal amount should be greater than 0');
        if(IERC20(token) == IERC20(address(0))) {
            payable (msg.sender).transfer(amount);
        } else {
            require(tokens[IERC20(token)][msg.sender] >= amount, 'Not enough balance to withdraw');
            IERC20(token).transfer(msg.sender, amount);
            tokens[IERC20(token)][msg.sender] = tokens[IERC20(token)][msg.sender].sub(amount);
        }
        emit Withdraw(IERC20(token), msg.sender, amount, tokens[IERC20(token)][msg.sender]);
    }
}