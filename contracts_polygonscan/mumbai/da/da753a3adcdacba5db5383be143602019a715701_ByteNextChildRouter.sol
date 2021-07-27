/**
 *Submitted for verification at polygonscan.com on 2021-07-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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

interface IERC20{
    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferOwner(address newOwner) external;
}

/**
 * @dev Contract for transfer BNU between child chains and BSC
 * This contract is in child chains(Polygon, FTM, Ethereum,...):
 *  1. Deposit
 *      1.1: User deposits BNU to this contract
 *      1.2: BNU will be burned
 *      1.3: ByteNext tracks deposit transaction and request to other child chains
 *  2. Withdraw: 
 *      After receiving information for successful deposit from child chains,
 *      users can Withdraw their tokens         
 *  NOTE: TOKENS THAT ARE DEPOSITED DIRECTLY, WILL NOT BE PROCESSED
 *  THEREFORE: DO NOT TRANSFER ANY TOKEN TO CONTRACT ADDRESS, PLEASE USE `deposit` METHOD INSTEAD OF
 */ 
 
contract ByteNextChildRouter is Ownable{
    mapping(address => mapping(uint256 => uint256)) public depositBalances;
    mapping(address => uint256) public withdrawalBalances;
    mapping(uint256 => bool) public allowedChains;
    
    IERC20 public bnuToken;
    
    /**
     * @dev User call deposit and deposit token to transfer
     */ 
    function deposit(uint256 amount, uint256 chainId) public returns(bool){
        require(amount > 0, "Nothing to deposit");
        require(depositBalances[_msgSender()][chainId] == 0, "Only one transaction per time");
        require(allowedChains[chainId], "Chain is not allowed");
        
        bnuToken.transferFrom(_msgSender(), address(this), amount);
        
        bnuToken.burn(address(this), amount);
        depositBalances[_msgSender()][chainId] = amount;
        
        emit Deposited(_msgSender(), amount);
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
    function depositForWithdrawal(address account, uint256 amount) public onlyOwner returns(bool){
        require(account != address(0), "Zero address");
        require(amount > 0, "Nothing to deposit");
        withdrawalBalances[account] += amount;

        return true;
    }
    
    function setAllowedChains(uint256 chainId, bool allowed) public onlyOwner{
        allowedChains[chainId] = allowed;
    }
    
    function setBnuToken(address newAddress) public onlyOwner{
        require(newAddress != address(0), "Zero address");
        bnuToken = IERC20(newAddress);
    }
    
    function setBnuTokenOwner(address newOwner) public onlyOwner{
        bnuToken.transferOwner(newOwner);
    }
    
     /**
     * @dev User withdraw their tokens
     */ 
    function withdraw() public returns(bool){
        uint256 withdrawalAmount = withdrawalBalances[_msgSender()];
        require(withdrawalAmount > 0, "Nothing to withdraw");
        bnuToken.mint(_msgSender(), withdrawalAmount);
        withdrawalBalances[_msgSender()] -= withdrawalAmount;
        
        emit Withdrawn(_msgSender(), withdrawalAmount);
        
        return true;
    }
    
    event Deposited(address account, uint256 amount);
    event Withdrawn(address account, uint256 amount);
}