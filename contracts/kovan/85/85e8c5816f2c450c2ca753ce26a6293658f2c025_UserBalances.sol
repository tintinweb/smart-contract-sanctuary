/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// File: contracts/myLib/IERC20.sol

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
    
    function mint(address account, uint256 amount) external  returns (bool);

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
// File: contracts/myLib/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: contracts/myLib/ContractOwnable.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract ContractOwnable is Context {
    address private _owner;
    address private _firstContract;
    address private _secondContract;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _firstContract = msgSender;
        _secondContract = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function firstContractOwner() public view virtual returns (address) {
        return _firstContract;
    }

    function secondContractOwner() public view virtual returns (address) {
        return _secondContract;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    modifier onlyFirstContract() {
        require(firstContractOwner() == _msgSender(), "Ownable: caller is not the contractOwner");
        _;
    }
    modifier onlySecondContract() {
        require(secondContractOwner() == _msgSender(), "Ownable: caller is not the contractOwner");
        _;
    }
    modifier onlyContractOwner() {
        require((firstContractOwner() == _msgSender()) || (secondContractOwner() == _msgSender()), "Ownable: caller is not the contractOwner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function transferFirstContractOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _firstContract = newOwner;
    }
    
    function transferSecondContractOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _secondContract = newOwner;
    }
    
 }
// File: contracts/myContract2/UserBalances.sol

pragma solidity ^0.8.0;



contract UserBalances is ContractOwnable {
  mapping (string => mapping (address => uint256))  private _homeBalance;
  mapping (string => mapping (address => uint256))  private _drawBalance;
  mapping (string => mapping (address => uint256))  private _awayBalance;
  
  mapping (string => address[])  private _homeAccount;
  mapping (string => address[])  private _drawAccount;
  mapping (string => address[])  private _awayAccount;
  
  mapping (string => mapping (address => bool))  private _matchAccountStatus;
  mapping (string => mapping (address => bool))  private _homeAccountStatus;
  mapping (string => mapping (address => bool))  private _drawAccountStatus;
  mapping (string => mapping (address => bool))  private _awayAccountStatus;

  mapping (string => uint256)  private _matchTotal;
  mapping (string => uint256)  private _homeTotal;
  mapping (string => uint256)  private _drawTotal;
  mapping (string => uint256)  private _awayTotal;
  
  mapping (address => string[])  private _matchAccount;

  mapping (string => mapping (address => uint256))  private finalTeamBalance;
  mapping (string => uint256)  private finalTeamtotal;
  
  
  uint256 _depBalance;
  uint256 _rewardBalance;
  address _rewardAddress;
  uint256 _lockTimeStamp;
 

  
 function deposit(string memory matchNo , address account , uint8 position, uint256 amount ) public onlyFirstContract payable returns (uint256){
    uint256 _newBalance;
    if(position== 1){
      _homeBalance[matchNo][account] = _homeBalance[matchNo][account] + amount;
      _homeTotal[matchNo] = _homeTotal[matchNo] + amount; 
      _newBalance = _homeBalance[matchNo][account] ;
    }
    else if(position== 2){
      _drawBalance[matchNo][account] = _homeBalance[matchNo][account] + amount;
      _drawTotal[matchNo] = _homeTotal[matchNo] + amount; 
      _newBalance = _drawBalance[matchNo][account] ;
    }
    else if(position== 3){
      _awayBalance[matchNo][account] = _homeBalance[matchNo][account] + amount;
      _awayTotal[matchNo] = _homeTotal[matchNo] + amount; 
      _newBalance = _awayBalance[matchNo][account] ;
    }
    _saveUserAccount(account,matchNo,position);
    _matchTotal[matchNo] = _matchTotal[matchNo] + amount;
    return _newBalance ;
 }
 
 function withdraw(string memory matchNo , address account , uint8 position, uint256 withdrawAmount ) public onlyFirstContract returns (uint256){
    uint256 _newBalance;
    if(position== 1){
      _homeBalance[matchNo][account] = _homeBalance[matchNo][account] - withdrawAmount;
      _homeTotal[matchNo] = _homeTotal[matchNo] - withdrawAmount; 
      _newBalance = _homeBalance[matchNo][account];
    }
    else if(position== 2){
      _drawBalance[matchNo][account] = _drawBalance[matchNo][account] - withdrawAmount;
      _drawTotal[matchNo] = _drawTotal[matchNo] - withdrawAmount; 
      _newBalance = _drawBalance[matchNo][account];
       
    }
    else if(position== 3){
      _awayBalance[matchNo][account] = _awayBalance[matchNo][account] - withdrawAmount;
      _awayTotal[matchNo] = _awayTotal[matchNo] - withdrawAmount; 
      _newBalance = _awayBalance[matchNo][account];
    }
    _matchTotal[matchNo] = _matchTotal[matchNo] - withdrawAmount;
    
  //  payable(msg.sender).transfer(amountAfterTax);
    
    return _newBalance ;
 } 

 function redeemBnb(uint256 amount) public onlyContractOwner returns (bool) {
    payable(msg.sender).transfer(amount);
    return true ;
 }

 function depositToReward(uint256 amount) public onlyFirstContract {
     _rewardBalance = _rewardBalance + amount;
 }

 function depositToDep(uint256 amount) public onlyContractOwner {
     _depBalance = _depBalance + amount;
 }
 
 function wirhdrawToDep(uint256 withdrawAmount) public onlyOwner {
     require(_depBalance >= withdrawAmount, "Balance is not enough");
     require( block.timestamp >= _lockTimeStamp, "Too early for withdraw");
     _depBalance = _depBalance - withdrawAmount;
     payable(msg.sender).transfer(withdrawAmount);
 }

 function wirhdrawToReward( uint256 withdrawAmount, uint256 rewardFee) public onlySecondContract {
     require(_rewardBalance >= withdrawAmount, "Balance is not enough");
     _rewardBalance = _rewardBalance - withdrawAmount;
     _rewardBalance = _rewardBalance - rewardFee;
     _depBalance = _depBalance + rewardFee;
 }
 
 function depositToken (string memory teamNo , address account , uint256 amount) public onlySecondContract returns (uint256,uint256) {
     finalTeamBalance[teamNo][account] = finalTeamBalance[teamNo][account] + amount;
     finalTeamtotal[teamNo] =  finalTeamtotal[teamNo] +  amount;
     return (finalTeamBalance[teamNo][account],finalTeamtotal[teamNo]);
 }
 
 function redeemFinalReward(string memory teamNo ,address account ,uint256 amount) public onlySecondContract returns (uint256) {
     finalTeamBalance[teamNo][account] = finalTeamBalance[teamNo][account] - amount;
     finalTeamtotal[teamNo] =  finalTeamtotal[teamNo] -  amount;
     return finalTeamBalance[teamNo][account];
 }
  
  
 function _saveUserAccount(address account , string memory matchNo, uint8 position) internal {
     if(_matchAccountStatus[matchNo][account] == false)
     {
         _matchAccountStatus[matchNo][account] = true;
         _matchAccount[account].push(matchNo);
     }
     bool _status;
     if(position == 1)
     {
         _status = _homeAccountStatus[matchNo][account];
     }
     else if(position == 2)
     {
         _status = _drawAccountStatus[matchNo][account];
     }
     else if(position == 3)
     {
         _status = _awayAccountStatus[matchNo][account];
     }
     if(_status == false)
     {
        if(position == 1)
        {
            _homeAccountStatus[matchNo][account] = true;
            _homeAccount[matchNo].push(account);
        }
        else if(position == 2)
        {
            _drawAccountStatus[matchNo][account] = true;
            _drawAccount[matchNo].push(account);
        }
        else if(position == 3)
        {
            _awayAccountStatus[matchNo][account] = true;
            _awayAccount[matchNo].push(account);
        }
     }
 }
 
 
 
  function teamBalance(string memory teamNo , address account ) public view returns(uint256) {
    return finalTeamBalance[teamNo][account];
  } 
  function teamTotal(string memory teamNo ) public view returns(uint256) {
    return finalTeamtotal[teamNo];
  } 
 
  function systemBalance() public view returns(uint256) {
    return address(this).balance;
  }

  function depBalance() public view returns(uint256) {
    return _depBalance;
  }
  function rewardBalance() public view returns(uint256) {
    return _rewardBalance;
  }  
  
 
  function homeBalance (string memory matchNo , address account) public view virtual  returns (uint256) {
    return  _homeBalance[matchNo][account];
  }
  function drawBalance (string memory matchNo , address account) public view virtual  returns (uint256) {
    return  _drawBalance[matchNo][account];
  }
  function awayBalance (string memory matchNo , address account) public view virtual  returns (uint256) {
    return  _awayBalance[matchNo][account];
  } 
  
  
  function homeAccountLength (string memory matchNo ) public view virtual  returns (uint256) {
    return  _homeAccount[matchNo].length ;
  } 
  function drawAccountLength (string memory matchNo ) public view virtual  returns (uint256) {
    return  _drawAccount[matchNo].length ;
  } 
  function awayAccountLength (string memory matchNo ) public view virtual  returns (uint256) {
    return  _awayAccount[matchNo].length ;
  } 
  function matchAccountLength (address account ) public view virtual  returns (uint256) {
    return  _matchAccount[account].length ;
  } 
  function matchAccount (address account ) public view virtual  returns (string [] memory ) {
    return  _matchAccount[account] ;
  } 
  function homeAccount (string memory matchNo ) public view virtual  returns (address [] memory) {
    return  _homeAccount[matchNo] ;
  } 
  function drawAccount (string memory matchNo ) public view virtual  returns (address [] memory) {
    return  _drawAccount[matchNo] ;
  } 
  function awayAccount (string memory matchNo  ) public view virtual  returns (address [] memory) {
    return  _awayAccount[matchNo] ;
  } 
  
  function matchTotal (string memory matchNo ) public view virtual  returns (uint256) {
    return  _matchTotal[matchNo];
  }
  function homeTotal (string memory matchNo ) public view virtual  returns (uint256) {
    return  _homeTotal[matchNo];
  }
  function drawTotal (string memory matchNo ) public view virtual  returns (uint256) {
    return  _drawTotal[matchNo];
  }
  function awayTotal (string memory matchNo ) public view virtual  returns (uint256) {
    return  _awayTotal[matchNo];
  }  
  
  
}