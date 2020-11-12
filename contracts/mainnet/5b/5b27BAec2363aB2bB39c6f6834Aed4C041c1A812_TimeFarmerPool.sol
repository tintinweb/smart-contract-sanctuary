pragma solidity 0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Token {
  function totalSupply() pure public returns (uint256 supply);
  function balanceOf(address _owner) pure public returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) pure public returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract TimeFarmerPool is Ownable {
    
  uint256 constant public TOKEN_PRECISION = 1e6;
  uint256 constant private PRECISION = 1e12;  
  uint256 constant private REBASE_TIME = 1 hours; 
	
  Token public liqudityToken;
  Token public farmToken;
  
  struct User {
        uint256 liqudityBalance;
        uint256 appliedFarmTokenCirculation;
  }
    
  struct Info {
        uint256 totalFarmSupply;
        
        mapping(address => User) users;
        address admin;
        
        uint256 coinWorkingTime;
        uint256 coinCreationTime;
  }
    
  Info private info;

  address public liqudityTokenAddress;
  address public farmTokenAddress;
  uint256 public VaultCreation = now;
  
  mapping(uint256 => uint256) public historyOfLiqudity;
      
    uint256 public testPosition;
  
  constructor() public{
      
    info.coinWorkingTime = now;
	info.coinCreationTime = now;
	
	liqudityTokenAddress = 0x608903534527B0623fe0b0bd81a2F29BC5b50D32;
	farmTokenAddress = 0x63A6da104C6a08dfeB50D13a7488F67bC98Cc41f;
	    
    liqudityToken = Token(liqudityTokenAddress); 
    farmToken = Token(farmTokenAddress);
    
    info.totalFarmSupply = 1 * TOKEN_PRECISION;
  } 
  
  function joinFarmPool(uint256 liqudityTokenToFarm) public payable {
      
    uint256 userBalance = liqudityToken.balanceOf(msg.sender);
   
    require(userBalance >= liqudityTokenToFarm, "Insufficient tokens");
    
    bool isNewUser = info.users[msg.sender].liqudityBalance == 0;

	if(isNewUser)
	{
	    liqudityToken.transferFrom(msg.sender, address(this), liqudityTokenToFarm);
	    adjustTime();
	    info.users[msg.sender].appliedFarmTokenCirculation = info.totalFarmSupply;
	}
	else
	{
	    claimTokens();
	    liqudityToken.transferFrom(msg.sender, address(this), liqudityTokenToFarm);
	}
    
    info.users[msg.sender].liqudityBalance += liqudityTokenToFarm;
  }
  
  function leaveFarmPool(uint256 liqudityTokenFromFarm) public payable {
      
    uint256 userBalanceInPool = info.users[msg.sender].liqudityBalance;
   
    require(userBalanceInPool >= liqudityTokenFromFarm, "Insufficient tokens");
    
    claimTokens();
    
    liqudityToken.transfer(msg.sender, liqudityTokenFromFarm); 
    
    info.users[msg.sender].liqudityBalance -= liqudityTokenFromFarm;
    
  }

  function adjustTime() private {
    if(info.coinWorkingTime + REBASE_TIME < now)
    {
        uint256 countOfCoinsToAdd = ((now - info.coinCreationTime) / REBASE_TIME);
        info.coinWorkingTime = now;
        info.totalFarmSupply = (countOfCoinsToAdd * TOKEN_PRECISION); 
    }
    
    uint256 position = info.totalFarmSupply / TOKEN_PRECISION;
    testPosition = position;
    historyOfLiqudity[position] = liqudityToken.balanceOf(address(this));
  }
  
  function claimTokens() public payable {
    adjustTime();
    
    uint256 valueFromLiqudityHistory = info.users[msg.sender].appliedFarmTokenCirculation / TOKEN_PRECISION;
    uint256 valueToLiqudityHistory = info.totalFarmSupply / TOKEN_PRECISION;
    
    uint256 farmTokenToClaim = 0;
    for (uint i=valueFromLiqudityHistory; i<valueToLiqudityHistory; i++) {
        
        if(historyOfLiqudity[i] == 0){
            historyOfLiqudity[i] = historyOfLiqudity[i - 1];
        }
        
        farmTokenToClaim += ((TOKEN_PRECISION * info.users[msg.sender].liqudityBalance) / historyOfLiqudity[i]); 
    }
    
    farmToken.transfer(msg.sender, farmTokenToClaim); 
    
    info.users[msg.sender].appliedFarmTokenCirculation = info.totalFarmSupply;
  }
  
 
  // Views
  function tokensToClaim(address _user)  public view returns (uint256 tokensToTake) {
    uint256 countOfCoinsToAdd = ((now - info.coinCreationTime) / REBASE_TIME);
      
    uint256 realTotalSupply = (countOfCoinsToAdd * TOKEN_PRECISION); 
        
    uint256 valueFromLiqudityHistory = info.users[_user].appliedFarmTokenCirculation / TOKEN_PRECISION;
    uint256 valueToLiqudityHistory = realTotalSupply / TOKEN_PRECISION;
    
    uint256[] memory myArray = new uint256[](valueToLiqudityHistory - valueFromLiqudityHistory);
    uint counter = 0;
    for (uint i=valueFromLiqudityHistory; i<valueToLiqudityHistory; i++) {
        myArray[counter] = historyOfLiqudity[i];
        if(historyOfLiqudity[i] == 0){
            myArray[counter] = myArray[counter-1];
        }
        counter++;
    }
    
    uint256 adjustedAddressBalance = 0;
    for (uint j=0; j<counter; j++) {
        adjustedAddressBalance += ((TOKEN_PRECISION * info.users[_user].liqudityBalance) / myArray[j]); 
    }
    
     return adjustedAddressBalance;
  }
  
   function allMintedTokens()  public view returns (uint256 mintedTokens) {
      uint256 countOfCoinsToAdd = ((now - info.coinCreationTime) / REBASE_TIME);
      uint256 allMintedTokensFromFarm = (countOfCoinsToAdd * TOKEN_PRECISION); 
      return allMintedTokensFromFarm;
  }
  
  function allInfoFor(address _user) public view returns (
      uint256 totalFarmSupply,
      uint256 allFarmTokens, 
      uint256 allLiquidityTokens,
      uint256 myLiqudityInContract,
      uint256 allFarmTokensContract, 
      uint256 allLiquidityTokensontract,
      uint256 lockedLiqudityInContract
      ) {
	return (
	info.totalFarmSupply, 
	farmToken.balanceOf(_user), //metamask
	liqudityToken.balanceOf(_user), //metamask
	info.users[_user].liqudityBalance, //locked in contract
	farmToken.balanceOf(address(this)), //contract farm tokens
	liqudityToken.balanceOf(address(this)), //liqudity tokens
	info.users[address(this)].liqudityBalance
	);
  }
	
	
  // Liqudity tokens dropped to contract not using functions so it lock itself
  // Farm tokens dropped to contract not using functions so it lock itself
  
  function refundAll() onlyOwner public{
    require(now > VaultCreation + 365 days); 
    farmToken.transfer(owner(), farmToken.balanceOf(this));  
    liqudityToken.transfer(owner(), liqudityToken.balanceOf(this)); 
  }
}