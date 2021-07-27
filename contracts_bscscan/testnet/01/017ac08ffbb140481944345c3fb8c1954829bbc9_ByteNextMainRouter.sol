/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "../interfaces/IERC20.sol";
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


//import "../core/Ownable.sol";
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
    function _now() internal view virtual returns(uint256){
        return block.timestamp;
    }
}

abstract contract Ownable is Context {
    
    modifier onlyOwner{
        require(_msgSender() == _owner, "Forbidden");
        _;
    }
    
    address internal _owner;
    
    constructor(){
        _owner = _msgSender();
    }
    
    function getOwner() external virtual view returns(address){
        return _owner;
    }
    
    function setOwner(address newOwner) external  onlyOwner{
        require(_owner != newOwner, "New owner is current owner");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnerChanged(oldOwner, _owner);
    }
    
    event OwnerChanged(address oldOwner, address newOwner);
}

/**
 * @dev Contract for transfer BNU between BSC and other child chains
 * This contract is in BSC:
 *  1. Deposit
 *      1.1: User deposits BNU to this contract
 *      1.2: BNU will be locked
 *      1.3: ByteNext tracks deposit transaction and request to other child chains
 *  2. Withdraw: 
 *      After receiving information for successful deposit from child chains,
 *      users can Withdraw their tokens         
 *  NOTE: TOKENS THAT ARE DEPOSITED DIRECTLY, WILL NOT BE PROCESSED
 *  THEREFORE: DO NOT TRANSFER ANY TOKEN TO CONTRACT ADDRESS, PLEASE USE `deposit` METHOD INSTEAD OF
 */ 
 
contract ByteNextMainRouter is Ownable{
    mapping(address => mapping(uint256 => uint256)) public depositBalances;
    mapping(address => uint256) public withdrawalBalances;
    mapping(uint256 => bool) public allowedChains;
    
    uint256 public fee;
    
    IERC20 public bnuToken;
    
    constructor(){
        allowedChains[137] = true;      //Polygon
    }
    
    /**
     * @dev User call deposit and deposit token to transfer
     */ 
    function deposit(uint256 amount, uint256 chainId) public returns(bool){
        require(amount > 0, "Nothing to deposit");
        require(amount > fee, "Not enough fee");
        require(depositBalances[_msgSender()][chainId] == 0, "Only one transaction per time");
        require(allowedChains[chainId], "Chain is not allowed");
        
        bnuToken.transferFrom(_msgSender(), address(this), amount);
        
        uint256 transferringAmount = amount - fee;
        depositBalances[_msgSender()][chainId] = transferringAmount;
        
        if(fee > 0)
            bnuToken.transfer(_owner, fee);
        
        emit Deposited(_msgSender(), chainId, transferringAmount);
        return true;
    }
    
    /**
     * @dev Owner call to mark `account` has been transfered `amount`
     */ 
    function processDeposit(address account, uint256 amount, uint256 chainId) public onlyOwner returns(bool){
        require(allowedChains[chainId], "Chain is not allowed");
        depositBalances[account][chainId] -= amount;
        return true;
    }
    
    /**
     * @dev Owner call to mark `account` can withdraw `amount` when chil chains confirmed deposit transaction
     */ 
    function transfer(address account, uint256 amount) public onlyOwner returns(bool){
        require(account != address(0), "Zero address");
        require(amount > 0, "Nothing to deposit");
        bnuToken.transfer(account, amount);
        
        emit Transferred(account, amount);
        
        return true;
    }
    
    function setAllowedChains(uint256 chainId, bool allowed) public onlyOwner{
        allowedChains[chainId] = allowed;
    }
    
    function setBnuToken(address newAddress) public onlyOwner{
        require(newAddress != address(0), "Zero address");
        bnuToken = IERC20(newAddress);
    }
    
    function setFee(uint256 fee_) public onlyOwner{
        fee = fee_;
    }
    
    event Deposited(address account, uint256 indexed chainId, uint256 amount);
    event Transferred(address account, uint256 amount);
}