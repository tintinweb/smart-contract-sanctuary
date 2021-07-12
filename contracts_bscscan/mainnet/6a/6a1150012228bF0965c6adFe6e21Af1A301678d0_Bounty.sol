/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

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

 contract Bounty {
    address private _owner;
    address private _SOKUTokenAddr;
    mapping (address => uint256) private _hunters;
    uint256 _lockingTime = 90 days;
    uint256 _endTime;

    
     modifier onlyOwner() {
        require((msg.sender == _owner), "Bounty: Caller is not owner");
        _;
    }
    
    constructor(address sokuTokenAddr) {
        _owner = msg.sender;
        _SOKUTokenAddr = sokuTokenAddr;
        _endTime = block.timestamp + _lockingTime;
    }
    
    function changeOwner(address newOwner) onlyOwner public {
        _owner = newOwner;
    }
    
    function remainingSokuTokens() public view returns (uint256) {
        return IERC20(_SOKUTokenAddr).balanceOf(address(this));
    }
    
    function setHunter(address hunterAddress, uint256 SokuTokenQty) public onlyOwner{
        _hunters[hunterAddress] = SokuTokenQty;
    }
    
    function getBalance() public view returns (uint256) {
        return _hunters[msg.sender];
    }
    
    function getRemainSokuTokens() public onlyOwner returns (bool) {
        uint256 tokens = remainingSokuTokens();
        IERC20(_SOKUTokenAddr).transfer(msg.sender, tokens);
        return true;
    }
    
    /**
     * @dev Transfer back after the expiration time.
     */
    function withdraw() external {
        uint256 amount = getBalance();
        uint256 contractAmount = IERC20(_SOKUTokenAddr).balanceOf(address(this));
        
        require(block.timestamp >= _endTime, 'Bounty: too early');
        require(contractAmount > 0, 'Bounty: not enough funds in this contract, please contact admin');
        require(amount > 0, 'Bounty: not enough balance');
        
        _hunters[msg.sender] = 0;
        IERC20(_SOKUTokenAddr).transfer(msg.sender, amount);
      }     
}