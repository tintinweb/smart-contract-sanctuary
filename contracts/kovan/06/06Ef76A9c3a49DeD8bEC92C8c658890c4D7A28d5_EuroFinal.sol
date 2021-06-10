/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// File: contracts/UserBalancesInterface.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface UserBalanceInterface {
    
    
  function deposit(string memory matchNo , address account , uint8 position, uint256 amount ) external payable returns (uint256);
 
  function withdraw(string memory matchNo , address account , uint8 position, uint256 withdrawAmount ) external returns (uint256);
 
  function setKMatch (string memory matchNo , uint256 khome ,uint256  kdraw,uint256  kaway  ) external  returns (bool);
  function setMatchStart (string memory matchNo   ,uint256 lockTime  ) external  returns (bool);
  function setMatchUnlockStatus (string memory matchNo   ,bool isUnlock  ) external  returns (bool);

  function redeemBnb(uint256 amount) external returns (bool);

  function depositTax(uint256 rewardAmount , uint256 depAmount) external;
 
  function wirhdrawToDep(uint256 withdrawAmount) external ;
 
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

  
  function matchName (string memory matchNo ) external view   returns (bool) ;
  function matchLock (string memory matchNo ) external view   returns (uint256) ;
  function matchUnLock (string memory matchNo ) external view   returns (bool) ;
  function kHome (string memory matchNo ) external view   returns (uint256) ;
  function kDraw (string memory matchNo ) external view   returns (uint256) ;
  function kAway (string memory matchNo ) external view   returns (uint256) ;
    
}
// File: contracts/Context.sol

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
// File: contracts/ContractOwnable.sol

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
// File: contracts/EuroFinal.sol

pragma solidity ^0.8.0;



contract EuroFinal  is ContractOwnable {
    UserBalanceInterface private _userBalance;
    bool private _lockDeposit = false;
    bool private _lockWithDraw = true;
    uint8 private _coinMultiply = 8;
    address private _token;
    uint8 private _depFee = 5;
    uint256 private _kRatio = 10000;
    
    mapping (string => uint256) private _kReward;
    mapping (string => bool)  private _teamNo;
    
    event depositEuroTokenActived(address indexed accountAddress,string  teamNo , uint256 amount);
    event redeemRewardActived(address indexed accountAddress,string  teamNo , uint256 amount);
    
    constructor(UserBalanceInterface userBalance, address projecToken, string[] memory teamName  )  {
        _userBalance = userBalance;
        _token = projecToken;
       for(uint8 i=0 ; i<teamName.length ; i++)
       {
           _teamNo[teamName[i]] = true;
       }

    }
    
    function depositEuroToken(address token,string memory teamNo, uint256 amount) public returns(uint256,uint256){
        require (_lockDeposit== false ,"Lock status");
        require (_token == token ,"Incorect token");
        require (_teamNo[teamNo] == true ,"Incorect team");
        uint256 _totalDeposit = amount * _coinMultiply;
        emit depositEuroTokenActived(msg.sender , teamNo , _totalDeposit);
        return _userBalance.depositToken(teamNo,msg.sender,_totalDeposit);
    }
    
    function redeemBNB(string memory teamNo, uint256 withdrawAmount) public returns(uint256){
        require (_lockWithDraw== false ,"Lock status");
        require (_kReward[teamNo] != 0 ,"Your team is not winner");
        require(_userBalance.teamBalance(teamNo,msg.sender) >= withdrawAmount, "Balance is not enough");
        
        uint256 _withdrawReceive = (withdrawAmount * _kReward[teamNo]) / _kRatio;
        _userBalance.redeemFinalReward(teamNo,msg.sender,_withdrawReceive);
        _userBalance.redeemBnb(_withdrawReceive);
        payable(msg.sender).transfer(_withdrawReceive);
        emit redeemRewardActived(msg.sender,teamNo,withdrawAmount);
        return(_withdrawReceive);
    }
 
    function setTeamWinner(string memory teamNo) public onlyOwner {
        require (_lockDeposit== true ,"Lock status");
        require (_lockWithDraw== false ,"Lock status");
        //require (_teamNo[teamNo] == true ,"Incorect team");
       uint256 _totalReward = _userBalance.rewardBalance();
       uint256 _winTeam = _userBalance.teamTotal(teamNo);
       uint256 _depTax =  (_winTeam * _depFee) /100;
       _winTeam = _winTeam - _depTax;
       _kReward[teamNo] = (_totalReward * _kRatio) / _winTeam;
       _userBalance.depositTax(0,_depTax);

    }

    
    function setLockDeposit(bool lockDeposit) public onlyOwner{
        _lockDeposit = lockDeposit; 
    }
    
    function setLockWithdraw(bool lockWithDraw) public onlyOwner {
        _lockWithDraw = lockWithDraw; 
    }
    function setTokenMultiply(uint8 coinMultiply) public onlyOwner {
        _coinMultiply = coinMultiply; 
    }

   function teamInfo(string memory teamNo , address account) public view returns(uint256 total , uint256 accountToken) {
       total  = _userBalance.teamTotal(teamNo);
       accountToken = _userBalance.teamBalance(teamNo,account );
    }
    
    function FinalTotalReward() public view returns(uint256 ) {
       return _userBalance.rewardBalance();
    }
    
    receive() external payable { }
}