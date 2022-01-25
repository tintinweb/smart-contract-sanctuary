// SPDX-License-Identifier: None 

/*
* ███████ ███████ ██████  ███    ███ ██  ██████  ███    ██ 
* ██      ██      ██   ██ ████  ████ ██ ██    ██ ████   ██ 
* █████   █████   ██████  ██ ████ ██ ██ ██    ██ ██ ██  ██ 
* ██      ██      ██   ██ ██  ██  ██ ██ ██    ██ ██  ██ ██ 
* ██      ███████ ██   ██ ██      ██ ██  ██████  ██   ████ 
*
* By Trustless Labs, 2022
* Website: https://www.fermiontoken.io/
* Twitter: https://twitter.com/fermiontoken
* Discord: https://discord.gg/meqDxQXM7Q
* Reddit: https://www.reddit.com/r/fermiontoken/
* Telegram: https://t.me/fermiontoken
*/

import './interfaces/IERC20.sol';


pragma solidity >=0.6.12;
 
contract LIQUIDTYLOCK {
    uint public end;
    address payable public owner;
    address payable public pendingOwner;
    uint public duration = 365 days;
    
    constructor(address payable _owner) {
        owner = _owner;
        end = block.timestamp + duration;
    }
    
    function deposit(address token, uint amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
    
    function timeLeft() public view returns (uint) {
        if (end > block.timestamp) {
            return end - block.timestamp;
        } else {
            return 0;
        }
    }
    
    /**
     * @notice Allows owner to change ownership
     * @param _owner new owner address to set
     */
    function setOwner(address payable _owner) external {
        require(msg.sender == owner, "owner: !owner");
        pendingOwner = _owner;
    }

    /**
     * @notice Allows pendingOwner to accept their role as owner (protection pattern)
     */
    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "acceptOwnership: !pendingOwner");
        owner = pendingOwner;
    }
    
    function ExtendLockTime(uint locktime) public {
        require(msg.sender == owner, "only owner");
        end += locktime;
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }
    
    function getEthBalance() view public returns (uint) {
        return address(this).balance;
    }
    
    function getTokenBalance(address tokenaddr) view public returns (uint) {
        return IERC20(tokenaddr).balanceOf(address(this));
    }
    
    receive() external payable {}
    
    function withdraw(address token, uint amount) external {
        require(msg.sender == owner, "only owner");
        require(block.timestamp >= end, "too early");
        if(token == address(0)) {
            owner.transfer(amount);
        } else {
            IERC20(token).transfer(owner, amount);
        }
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
    * @dev Returns the decimals.
    */
    function decimals() external view returns (uint8);

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
     * @dev Emitted when `reward` tokens have been awarded to account
     *
     * Note that `value` may be zero.
     */
    event TransferReward(address indexed from, address indexed to, uint256 value, uint256 multiplier);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}