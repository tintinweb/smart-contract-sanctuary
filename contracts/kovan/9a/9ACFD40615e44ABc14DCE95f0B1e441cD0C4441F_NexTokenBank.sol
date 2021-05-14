/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

library Fractions {
    function percent(uint num, uint percentage) internal pure returns (uint) {
        return num * percentage / 100;
    }
}

contract NexTokenBank {

    using Fractions for uint;

    IERC20 public token;
    address creator;

    mapping (address => uint) balances;

    event Deposited(address indexed _from, uint amount);
    event Withdrawed(address indexed _to, uint amount);

    constructor(address tokenAddr) {
        require(isContract(tokenAddr), "Provided address is not contract");

        creator = msg.sender;
        token = IERC20(tokenAddr);
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "This function can be called only by creator.");
        _;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function deposit(uint amount) public {
        address user = msg.sender;
        
        address contractAddress = address(this);

        uint allowed = token.allowance(user, contractAddress);

        require(allowed >= amount, "Token transfer is not allowed.");
        
        token.transferFrom(user, contractAddress, amount);

        uint fee = amount.percent(2);
        uint depAmount = amount - fee;
        balances[contractAddress] += fee;
        balances[user] += depAmount;

        emit Deposited(user, depAmount);
    }

    function withdraw(uint amount) public {
        address user = msg.sender;
        uint bal = balances[user];

        require(bal >= amount, "Insufficient Funds.");

        token.transfer(user, amount);
        balances[user] -= amount;
    
        emit Withdrawed(user, amount);
    }

    function withdraw() public {
        address user = msg.sender;
        uint bal = balances[user];

        token.transfer(user, bal);
        balances[user] -= bal;
    
        emit Withdrawed(user, bal);
    }

    function claim() public onlyCreator {
        uint bal = balances[address(this)];
        token.transfer(creator, bal);
    }

    function claimable() public view onlyCreator returns (uint) {
        return balances[address(this)];
    }

    function getTotalBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}