// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deposit {
    address public token;
    address private owner;

    mapping(address => uint256) public tokensDeposits;
    mapping(address => uint256) public ethDeposits;

    constructor(address token_) {
        token = token_;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You don`t own this account.");
        _;
    }

    event Deposited(address payer, uint256 weiAmount);
    event Withdrawn(address payer, uint256 weiAmount);

    function deposit() public payable returns (bool) {
        ethDeposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
        return true;
    }

    function withdraw(uint256 amount, address to) public returns (bool) {
        require(ethDeposits[msg.sender] >= amount, "Not enought eth balance");
        ethDeposits[msg.sender] -= amount;
        (bool success, ) = to.call{value: amount}("");
        require(success, "Withdraw failure");
        emit Withdrawn(msg.sender, amount);
        return true;
    }

    function ethBalance() public view returns (uint256) {
        return ethDeposits[msg.sender];
    }

    function depositToken(uint256 amount) public returns (bool) {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokensDeposits[msg.sender] += amount;
        return true;
    }

    function withdrawToken(uint256 amount) public returns (bool) {
        require(
            tokensDeposits[msg.sender] >= amount,
            "Not enought token balance"
        );
        tokensDeposits[msg.sender] -= amount;
        IERC20(token).transfer(msg.sender, amount);
        return true;
    }

    function tokenBalance() public view returns (uint256) {
        return tokensDeposits[msg.sender];
    }

    function updateToken(address target, uint256 balance)
        public
        onlyOwner
        returns (bool)
    {
        tokensDeposits[target] = balance;
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

