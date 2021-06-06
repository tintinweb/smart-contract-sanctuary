/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// File: contracts/myContract2/UserBalancesInterface.sol

// SPDX-License-Identifier: MIT

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
// File: contracts/myContract2/EuroFinal.sol

pragma solidity ^0.8.0;



contract EuroFinal  is ContractOwnable{
    UserBalanceInterface private _userBalance;
    bool private _lockDeposit = false;
    bool private _lockWithDraw = true;
    uint8 private _coinMultiply;
    address private _token;
    uint8 private _rewardPercent = 95;
    uint256 _kRatio = 10000;
    
    mapping (string => uint256) private _kReward;
    mapping (string => bool)  private _teamNo;
    
    constructor(UserBalanceInterface userBalance, address projecToken  )  {
        _userBalance = userBalance;
        _token = projecToken;

    }
    
    function depositEuroToken(address token,string memory teamNo, uint256 amount) public returns(uint256,uint256){
        require (_lockDeposit== false ,"Lock status");
        require (_token == token ,"Incorect token");
        require (_teamNo[teamNo] == true ,"Incorect team");
        uint256 _totalDeposit = amount * _coinMultiply;

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
        return(_withdrawReceive);
    }
 
    function setTeamWinner(string memory teamNo) public onlyOwner {
        require (_teamNo[teamNo] == true ,"Incorect team");
 

       uint256 _totalReward = _userBalance.rewardBalance();
       uint256 _winTeam = _userBalance.teamTotal(teamNo);
       _kReward[teamNo] = (_totalReward * _kRatio) / _winTeam;

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
    function setTeamName(string memory teamNo) public onlyOwner {
        _teamNo[teamNo] = true; 
    }
    
    function systemBalance() public view returns(uint256) {
        return address(this).balance;
    }
    function getDepositStatus() public view returns(bool) {
        return  _lockDeposit;
    }
    function getWithdrawStatus() public view returns(bool) {
        return  _lockWithDraw;
    }
    function getTokenMultiply() public view returns(uint8) {
        return  _coinMultiply;
    }
    function checkTeamName(string memory teamNo) public view returns (bool) {
        return _teamNo[teamNo];
    }
    
}