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
// File: contracts/myContract2/UserBalancesInterface.sol

pragma solidity ^0.8.0;

interface UserBalanceInterface {
    
    
  
 function deposit(string memory matchNo , address account , uint8 position, uint256 amount ) external  returns (uint256);
 
 function withdraw(string memory matchNo , address account , uint8 position, uint256 withdrawAmount ) external returns (uint256);

 function redeemBnb(uint256 amount) external returns (bool);

 function depositToReward(uint256 amount) external ;

 function depositToDep(uint256 amount) external ;
 
 function wirhdrawToDep(uint256 withdrawAmount) external ;

 function wirhdrawToReward( uint256 withdrawAmount, uint256 rewardFee) external ;
 
 function depositToken (string memory teamNo , address account , uint256 amount) external returns (uint256,uint256) ;
 
 function redeemFinalReward(string memory teamNo ,address account ,uint256 amount) external returns (uint256) ;
  
  

 
 
  function teamBalance(string memory teamNo , address account ) external view returns(uint256);
  function teamTotal(string memory teamNo ) external view returns(uint256);
 
  function systemBalance() external view returns(uint256);
  function depBalance() external view returns(uint256);
  function rewardBalance() external view returns(uint256);
  
 
  function homeBalance (string memory matchNo , address account) external view  returns (uint256);
  function drawBalance (string memory matchNo , address account) external view  returns (uint256);
  function awayBalance (string memory matchNo , address account) external view  returns (uint256);
  
  
  function homeAccountLength (string memory matchNo ) external view  returns (uint256);
  function drawAccountLength (string memory matchNo ) external view  returns (uint256);
  function awayAccountLength (string memory matchNo ) external view  returns (uint256);
  function matchAccountLength (address account ) external view  returns (uint256);
  function matchAccount (address account ) external view  returns (string [] memory );
  function homeAccount (string memory matchNo ) external view  returns (address [] memory);
  function drawAccount (string memory matchNo ) external view  returns (address [] memory);
  function awayAccount (string memory matchNo  ) external view  returns (address [] memory) ;
  
  function matchTotal (string memory matchNo ) external view  returns (uint256);
  function homeTotal (string memory matchNo ) external view   returns (uint256);
  function drawTotal (string memory matchNo ) external view   returns (uint256);
  function awayTotal (string memory matchNo ) external view   returns (uint256);
    
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
// File: contracts/myContract2/EuroMatch.sol


pragma solidity ^0.8.0;




contract EuroMatch is ContractOwnable{
    UserBalanceInterface private _userBalance;
    IERC20 private _euroToken;
    mapping (string => bool) private _matchName;
    mapping (string => uint256) private _matchLock;
    mapping (string => bool)  private _matchUnLock;
    uint8 private _depPercent = 5;
    uint8 private _rewardPercent = 5;
    uint256 private _kInitial = 900000;
    uint256 private _kRatio  = 1000000;
    mapping (string => uint256)  private _kHome;
    mapping (string => uint256)  private _kDraw;
    mapping (string => uint256)  private _kAway;
    uint256 _mintRaito = 100;
    address private _token;
    
    constructor(UserBalanceInterface userBalance ,IERC20 euroToken )  {
        _userBalance = userBalance;
        _euroToken = euroToken;
    }
    
    function selectPosition(string memory matchNo , uint8 position ) public payable returns (uint256) {
        require (_matchName[matchNo] == true ,"Incorect match name");
        require (position < 4 ,"Incorect Position");
        require (block.timestamp < _matchLock[matchNo] , "Time Over! cannot deposit" );
        uint256 _newBalance =  _userBalance.deposit(matchNo,msg.sender,position,msg.value);       
        return _newBalance;
    }

    function redeemReward(string memory matchNo,uint8 position , uint256 withdrawAmount) public returns (uint256,uint256 ) {
        require (_matchName[matchNo] == true ,"Incorect match name");
        require (position < 4 ,"Incorect Position");
        require ((block.timestamp < _matchLock[matchNo] ) ||  (_matchUnLock[matchNo] = true), "temporary close for withdraw " );

       uint256 _withdrawReceive=0;
       uint256 _reward = 0;
        if(position==1)
        {
            require(_userBalance.homeBalance(matchNo,msg.sender) >= withdrawAmount, "Balance is not enough");
            if(_kHome[matchNo] == 0)
            {
               _reward = withdrawAmount * _mintRaito;
            }
            else 
            {
               _withdrawReceive = (withdrawAmount * _kHome[matchNo] ) / _kRatio;
            }
        }
        else if (position==2)
        {
            require(_userBalance.drawBalance(matchNo,msg.sender) >= withdrawAmount, "Balance is not enough");
            if(_kDraw[matchNo] == 0)
            {
             _reward = withdrawAmount * _mintRaito;
            }
            else 
            {
                 _withdrawReceive = (withdrawAmount * _kDraw[matchNo] ) / _kRatio;
            }

        }    
        else if (position==3)
        {
            require(_userBalance.awayBalance(matchNo,msg.sender) >= withdrawAmount, "Balance is not enough");
            if(_kDraw[matchNo] == 0)
            {
               _reward = withdrawAmount * _mintRaito;
            }
            else 
            {
                 _withdrawReceive = (withdrawAmount * _kAway[matchNo] ) / _kRatio;
            }
        }
        _userBalance.withdraw(matchNo,msg.sender,position,withdrawAmount);
        if(_withdrawReceive != 0)
        {
            _userBalance.redeemBnb(_withdrawReceive);
            payable(msg.sender).transfer(_withdrawReceive);
        }
        if  (_reward != 0)
        {
            _euroToken.mint(msg.sender,_reward);
        }

        return (_withdrawReceive,_reward);
    }
    
    function createMatch(string memory matchNo ,uint256 lockTime ) public onlyOwner{
        require (_matchName[matchNo] == false ,"Duplicate match name");
        _matchName[matchNo] = true;
        _kHome[matchNo] = _kInitial;
        _kDraw[matchNo] = _kInitial;
        _kAway[matchNo] = _kInitial;
        _matchLock[matchNo] = lockTime;
    } 
    
    function updateResult(string memory matchNo , uint8 winPosition) public onlyOwner{
        require (_matchName[matchNo] == true ,"Match name Incorect");
        require (_matchUnLock[matchNo] == false ,"Match name Incorect");
        
        _matchUnLock[matchNo] = true;
        uint256 _total =  _userBalance.matchTotal(matchNo);
        uint256 _totalMul = _total * 10;
        uint256 _win;
        if(winPosition==1){
            _win = _userBalance.homeTotal(matchNo);
        }
        else if(winPosition==2){
            _win = _userBalance.drawTotal(matchNo);
        }
        else if(winPosition==3){
            _win = _userBalance.awayTotal(matchNo);
        }
        uint256 _winRatio = _totalMul / _win ; 
        
        if(_winRatio >= 11){
            uint256 _depFee =  (_total * _depPercent) / 100;
            uint256 _reward =  (_total * _rewardPercent) / 100;
            _userBalance.depositToDep(_depFee);
            _userBalance.depositToReward(_reward);
            _total = _total - _reward;
            _total = _total - _depFee;
        }

        if(winPosition==1) {
            _kHome[matchNo] = (_total * _kRatio) / _win;
            _kDraw[matchNo] = 0;
            _kAway[matchNo] = 0;
        }
        else if (winPosition==2){
            _kHome[matchNo] = 0;
            _kDraw[matchNo] = (_total * _kRatio) / _win;
            _kAway[matchNo] = 0;
        }
        else if (winPosition==3){
            _kHome[matchNo] = 0;
            _kDraw[matchNo] = 0;
            _kAway[matchNo] = (_total * _kRatio) / _win;
        }
        
    } 
   
    
    
    
    function matchConstant(string memory matchNo ) public view virtual  returns (uint256,uint256,uint256){
        return (_kHome[matchNo],_kDraw[matchNo],_kAway[matchNo]);
    }
    
    function checkMatchName(string memory matchNo ) public view virtual  returns (bool){
        return _matchName[matchNo];
    }
    
    function checkMatchUnlock(string memory matchNo ) public view virtual  returns (bool){
        return _matchUnLock[matchNo];
    }
    
    function checkMatchLockTime(string memory matchNo ) public view virtual  returns (uint256){
        return _matchLock[matchNo];
    }
    
}