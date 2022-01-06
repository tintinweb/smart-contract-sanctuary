/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Vesting is Ownable {
    event DistributionTracker( address indexed account, uint amount);
    event Claim( address indexed account, uint amount);

    IERC20 public token;

    uint public totalTokens;
    uint public subsequentDistribution = 30 days;
    uint public subsequentClaim = 10e18;

    mapping(address => bool) public auth;
    mapping(address => userStruct) public user;

    struct userStruct {
        uint balance;
        uint totalClaimed;
        uint lastClaimed;
    }

    modifier onlyAuth() {
        require(auth[msg.sender],"only auth");
        _;
    }

    function setAuth( address account, bool status) external onlyOwner {
        auth[account] = status;
    }

    function setToken( IERC20 token_) external onlyOwner {
        token = token_;
    }

    function setSubsequentDistribution( uint period) external onlyOwner {
        subsequentDistribution = period;
    }

    function setSubsequentClaim( uint percent) external onlyOwner {
        subsequentClaim = percent;
    }

    function distributionTracker( address account, uint amount) external onlyAuth {
        require(account != address(0), "Team : account != address(0)");
        require(amount > 0, "Team : amount > 0");

        user[account].balance += amount;
        if(user[account].lastClaimed == 0)
            user[account].lastClaimed = block.timestamp;

        totalTokens += amount;
        emit DistributionTracker( account, amount);
    }

    function claim() external {
        require(user[msg.sender].balance > 0, "Team : balance > 0");
        require(user[msg.sender].totalClaimed < user[msg.sender].balance, "Team : total claimed < balance");
        require((user[msg.sender].lastClaimed + subsequentDistribution) < block.timestamp, "Team : last claimed < subsequent distribution");

        uint totDays = block.timestamp - user[msg.sender].lastClaimed / subsequentDistribution;

        user[msg.sender].lastClaimed = block.timestamp;

        uint bal = user[msg.sender].balance - user[msg.sender].totalClaimed;
        bal = bal * subsequentClaim / 100e18;
        bal = bal * totDays;

        if((user[msg.sender].totalClaimed + bal) > user[msg.sender].balance)
            bal = user[msg.sender].balance - user[msg.sender].totalClaimed;
        
        user[msg.sender].totalClaimed += bal;
        token.transfer(msg.sender, bal);
        emit Claim( msg.sender, bal);
    }
}