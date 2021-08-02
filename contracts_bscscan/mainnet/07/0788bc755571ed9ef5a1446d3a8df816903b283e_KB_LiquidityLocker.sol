/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: UNLICENSED

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

contract KB_LiquidityLocker is Ownable{
    IERC20 token;

    struct KB_LockerStruct {
        address beneficiary;
        uint balance;
        uint releaseTime;
    }

    address _feeAddress = payable(0x8F0C3486D582ebe13CcfF98756B78A80d983F98B);
    KB_LockerStruct[] public KB_LockerStructs; // This could be a mapping by address, but these numbered lockBoxes support possibility of multiple tranches per address

    event KryptoBotLockerDeposit(address sender, uint amount, uint releaseTime);   
    event KryptoBotLockerWithdraw(address receiver, uint amount);
    event KryptoBotTakeFee(address feeAddress, uint amount);
    event KryptoBotOwnerPayout(address owner, uint amount);

    constructor() public {}

    function takeFee() public payable {
        uint256 amount = 0.01 * (10**18);
        payable(_feeAddress).transfer(amount);
        emit KryptoBotTakeFee(_feeAddress, amount);
    }

    function deposit(address beneficiary, address _token, uint amount, uint releaseTime) public returns(bool success) {
        token = IERC20(_token);
        require(token.transferFrom(msg.sender, address(this), amount));
        takeFee();
        KB_LockerStruct memory l;
        l.beneficiary = beneficiary;
        l.balance = amount;
        l.releaseTime = releaseTime;
        KB_LockerStructs.push(l);
        emit KryptoBotLockerDeposit(msg.sender, amount, releaseTime);
        return true;
    }

    function withdraw(uint lockBoxNumber) public returns(bool success) {
        KB_LockerStruct storage l = KB_LockerStructs[lockBoxNumber];
        require(l.beneficiary == msg.sender, "KrytoBot: You do not have any tokens to withdraw.");
        require(l.releaseTime <= block.timestamp, "KryptoBot: Tokens are still locked.");
        uint amount = l.balance;
        l.balance = 0;
        emit KryptoBotLockerWithdraw(msg.sender, amount);
        require(token.transfer(msg.sender, amount));
        return true;
    }    

    function getBalanceOfLpLockedTokens(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(msg.sender);
    }

    function withdrawBNB() public payable onlyOwner returns (bool res) {
        payable(_feeAddress).transfer(address(this).balance);
        emit KryptoBotOwnerPayout(_feeAddress, address(this).balance);
        return true;
    }

    receive() external payable {} 
}