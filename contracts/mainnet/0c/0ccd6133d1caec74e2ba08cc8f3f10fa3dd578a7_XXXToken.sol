pragma solidity ^0.4.18;

/**

* @title ERC20Basic

* @dev Simpler version of ERC20 interface

*/

contract ERC20Basic {


 function totalSupply() public view returns (uint256); 

 function balanceOf(address who) public view returns (uint256); 

 function transfer(address to, uint256 value) public returns (bool); 

 event Transfer(address indexed from, address indexed to, uint256 value); 

}

/**

* @title SafeMath

* @dev Math operations with safety checks that throw on error

*/

library SafeMath {

 /**

 * @dev Multiplies two numbers, throws on overflow.

 */

 function mul(uint256 a, uint256 b) internal pure returns (uint256) {

  if (a == 0) {

   return 0;

  }

  uint256 c = a * b;

  assert(c / a == b);

  return c;

 }

 /**

 * @dev Integer division of two numbers, truncating the quotient.

 */

 function div(uint256 a, uint256 b) internal pure returns (uint256) {

  // assert(b > 0); // Solidity automatically throws when dividing by 0

  uint256 c = a / b;

  // assert(a == b * c + a % b); // There is no case in which this doesn't hold

  return c;

 }

 /**

 * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).

 */

 function sub(uint256 a, uint256 b) internal pure returns (uint256) {

  assert(b <= a);

  return a - b;

 }

 /**

 * @dev Adds two numbers, throws on overflow.

 */

 function add(uint256 a, uint256 b) internal pure returns (uint256) {

  uint256 c = a + b;

  assert(c >= a);

  return c;

 }

}

/**

* @title ERC20 interface

*/

contract ERC20 is ERC20Basic {

 function allowance(address owner, address spender) public view returns (uint256);

 function transferFrom(address from, address to, uint256 value) public returns (bool); 

 function approve(address spender, uint256 value) public returns (bool); 

 event Approval(address indexed owner, address indexed spender, uint256 value); 

}

/**

* @title Basic token

* @dev Basic version of StandardToken, with no allowances.

*/

contract BasicToken is ERC20Basic {

 using SafeMath for uint256;

 mapping(address => uint256) balances; 

 uint256 totalSupply_; 

 /**

 * @dev total number of tokens in existence

 */

 function totalSupply() public view returns (uint256) {

  return totalSupply_;

 }

 /**

 * @dev transfer token for a specified address

 * @param _to The address to transfer to.

 * @param _value The amount to be transferred.

 */

 function transfer(address _to, uint256 _value) public returns (bool) {

  require(_to != address(0)); 

  require(_value <= balances[msg.sender]); 

  // SafeMath.sub will throw if there is not enough balance.

  balances[msg.sender] = balances[msg.sender].sub(_value);

  balances[_to] = balances[_to].add(_value); 

  Transfer(msg.sender, _to, _value);

  return true;

 }

 /**

 * @dev Gets the balance of the specified address.

 * @param _owner The address to query the the balance of.

 * @return An uint256 representing the amount owned by the passed address.

 */

 function balanceOf(address _owner) public view returns (uint256 balance) {

  return balances[_owner]; 
 
 }

}

/**

* @title Standard ERC20 token

*

* @dev Implementation of the basic standard token.

*/

contract StandardToken is ERC20, BasicToken {

 mapping (address => mapping (address => uint256)) internal allowed;

 /**

 * @dev Transfer tokens from one address to another

 * @param _from address The address which you want to send tokens from

 * @param _to address The address which you want to transfer to

 * @param _value uint256 the amount of tokens to be transferred

 */

 function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

  require(_to != address(0)); 

  require(_value <= balances[_from]); 

  require(_value <= allowed[_from][msg.sender]);

  balances[_from] = balances[_from].sub(_value);

  balances[_to] = balances[_to].add(_value);

  allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); 

  Transfer(_from, _to, _value);

  return true;

 }

 /**

  * @param _spender address The address which you want to transfer to

  * @param _value uint256 the amount of tokens to be transferred

  */

 function approve(address _spender, uint256 _value) public returns (bool) {

  allowed[msg.sender][_spender] = _value;

  Approval(msg.sender, _spender, _value);

  return true;

 }

 /**

 * @dev Function to check the amount of tokens that an owner allowed to a spender.

 * @param _owner address The address which owns the funds.

 * @param _spender address The address which will spend the funds.

 * @return A uint256 specifying the amount of tokens still available for the spender.

 */

 function allowance(address _owner, address _spender) public view returns (uint256) {

  return allowed[_owner][_spender];

 }

 /**

 * @dev Increase the amount of tokens that an owner allowed to a spender.

 *

 * approve should be called when allowed[_spender] == 0. To increment

 * allowed value is better to use this function to avoid 2 calls (and wait until

 * the first transaction is mined)

 * From MonolithDAO Token.sol

 * @param _spender The address which will spend the funds.

 * @param _addedValue The amount of tokens to increase the allowance by.


 */

 function increaseApproval(address _spender, uint _addedValue) public returns (bool) {

  allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

  Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

  return true;

 }

 /**

 * @dev Decrease the amount of tokens that an owner allowed to a spender.

 *

 * approve should be called when allowed[_spender] == 0. To decrement

 * allowed value is better to use this function to avoid 2 calls (and wait until

 * the first transaction is mined)

 * From MonolithDAO Token.sol

 * @param _spender The address which will spend the funds.

 * @param _subtractedValue The amount of tokens to decrease the allowance by.


 */

 function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {

  uint oldValue = allowed[msg.sender][_spender];

  if (_subtractedValue > oldValue) {

   allowed[msg.sender][_spender] = 0;

  } else {

   allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

  }

  Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

  return true;

 }

}



/**

* @title Ownable

* @dev The Ownable contract has an owner address, and provides basic authorization control

* functions, this simplifies the implementation of "user permissions". 

*/

contract Ownable {

 address public owner;

 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 /**

 * @dev The Ownable constructor sets the original `owner` of the contract to the sender

 * account.

 */

 function Ownable() public {

  owner = msg.sender;

 }

 /**

 * @dev Throws if called by any account other than the owner.

 */

 modifier onlyOwner() {

  require(msg.sender == owner);

  _;

 }

 /**

 * @dev Allows the current owner to transfer control of the contract to a newOwner.

 * @param newOwner The address to transfer ownership to. 

 */

 function transferOwnership(address newOwner) public onlyOwner {

  require(newOwner != address(0));

  OwnershipTransferred(owner, newOwner);

  owner = newOwner;

 }

}

/**

* @title SimpleToken

* @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.

* Note they can later distribute these tokens as they wish using `transfer` and other


*/

contract XXXToken is StandardToken , Ownable {

  string public constant name = "XXXToken"; // solium-disable-line uppercase

  string public constant symbol = "XXX"; // solium-disable-line uppercase

  uint8 public constant decimals = 18; // solium-disable-line uppercase

  uint256 public constant INITIAL_SUPPLY = 30000000 * (10 ** uint256(decimals));
  
  uint256 public  MINTING_SUPPLY = 9000000 * (10 ** uint256(decimals));

  /**

  * @dev Constructor that gives msg.sender all of existing tokens.

  */

  function XXXToken() public {

    totalSupply_ = INITIAL_SUPPLY;
    
    balances[msg.sender] = INITIAL_SUPPLY;

    Transfer(0x0, msg.sender, INITIAL_SUPPLY);

  }

}




/**

 * @dev lock coin

 */

contract XXXTokenVault is Ownable {

  using SafeMath for uint256;
    
  address private owner;

  uint256 private teamTimeLock = 1 * 365 days;
  
//   uint256 private mintingTimeLock = 90 days;
	
 uint256 private mintingTimeLock = 90 seconds;
  

  /** Reserve allocations */

  mapping (address=>mapping(uint256 => mapping (uint8 => uint256))) public allocations;

  /** When timeLocks are over (UNIX Timestamp) */

  mapping (address=>mapping(uint256 => mapping (uint8 => uint256))) public timeLocks;


  /** When this vault was locked (UNIX Timestamp)*/

  uint256 private lockedAt = 0;

  XXXToken public token;


  /** Distributed reserved tokens */

  event Distributed(uint256 lockId,uint8 batch, uint256 value);

  /** Tokens have been locked */

  event Locked(uint256 lockId,uint256 lockTime, uint256 value);


  function XXXTokenVault(ERC20 _token) public { 

    owner = msg.sender; 

    token = XXXToken(_token);

  }

  /** lock team coin */

  function lockTeam(uint256 lockId,uint256 _amount) public onlyOwner returns (bool){

    lockedAt = block.timestamp; 
    timeLocks[msg.sender][lockId][0] = lockedAt.add(teamTimeLock);
    timeLocks[msg.sender][lockId][1] = lockedAt.add(teamTimeLock.mul(2));
    allocations[msg.sender][lockId][0] = _amount;
    allocations[msg.sender][lockId][1] = 0;

    Locked(lockId,lockedAt,_amount);

  }
  /** lock minting coin */
  function lockMinting(address _owner, uint256 lockId,uint256 _amount) public  returns (bool){

    lockedAt = block.timestamp; 
    timeLocks[_owner][lockId][0] = lockedAt.add(mintingTimeLock);
    timeLocks[_owner][lockId][1] = lockedAt.add(mintingTimeLock.mul(2));
    allocations[_owner][lockId][0] = _amount.div(2);
    allocations[_owner][lockId][1] = _amount.div(2);

    Locked(lockId,lockedAt,_amount);
    
    return true;

  }
  

  // Total number of tokens currently in the vault

  function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {

    return token.balanceOf(address(this));

  }

  // Number of tokens that are still locked

  function getLockedBalance(address parter,uint256 lockId) public view  returns (uint256 tokensLocked) {

    return allocations[parter][lockId][0].add(allocations[parter][lockId][1]);

  }

  //Claim tokens for reserve wallets

  function claimTokenReserve(address parter,uint256 lockId,uint8 batch)  public  returns (bool){
      
    require( batch==0 || batch==1);
    
    require(allocations[parter][lockId][batch] !=0 &&timeLocks[parter][lockId][batch] !=0);
    
    require(block.timestamp > timeLocks[parter][lockId][batch]);

    uint256 amount = allocations[parter][lockId][batch];
    
    require(token.transfer(msg.sender, amount));
    
    allocations[parter][lockId][batch]=0;
    
    timeLocks[parter][lockId][batch]=0;

    Distributed(lockId,batch, amount);
    
    return true;

  }

}



contract TetherToken  {
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32);
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    function balanceOf(address who) public constant returns (uint);
}



contract Minting is Ownable {
    
    using SafeMath for uint256;
    
    address public admin; 
	mapping (address => uint256) public minters;
    
    TetherToken public tokenUsdt;
    XXXToken public tokenXXX;
    XXXTokenVault public tokenVault;
    
    address public beneficiary;
    uint256 public price; 
    
      // Transfer all tokens on this contract back to the owner
      function getUsdt(address _Account,uint256 _mount) external  onlyOwner returns (bool){

        tokenUsdt.transfer(_Account, _mount);

      }
    
    function Minting(address _adminAccount, ERC20 _tokenUsdt, ERC20 _tokenXXX, ERC20 _tokenVault, uint256 _price) public {
        
		admin = _adminAccount;
		
        transferOwnership(admin);
        
        tokenXXX = XXXToken(_tokenXXX);
        
        tokenUsdt = TetherToken(_tokenUsdt);
        
        tokenVault = XXXTokenVault(_tokenVault);
        
        price = _price;
	}

	function setPrice(uint256 _price) public onlyOwner returns (bool){
		 price = _price;
	}

	function setMinter(address minter, uint256 _usdtAmount) public onlyOwner returns (bool){
		minters[minter]=_usdtAmount;
	}
    
    function mintingXXX(uint256 Appid, uint256 _usdtAmount) public returns (bool){
        beneficiary = msg.sender;

		require(minters[beneficiary]>0);
        
        _preValidatePurchaseMinting(beneficiary, _usdtAmount);    
        
        uint256 _usdtToXXXAmount = _usdtAmount.mul(price).div(10000);
        
        require(tokenXXX.balanceOf(address(this)) >= _usdtToXXXAmount);

        tokenUsdt.transferFrom(msg.sender, address(this), _usdtAmount);
        
        require(tokenXXX.transfer(tokenVault, _usdtToXXXAmount));
        
        require(tokenVault.lockMinting(msg.sender,Appid,_usdtToXXXAmount));
        
        minters[beneficiary]=0;
        
        return true;
        
    }
    
     function refundXXX(uint256 _XXXAmount) public returns (bool){
        beneficiary = msg.sender;
        
        _preValidatePurchaseRefund(beneficiary, _XXXAmount);    
        
        uint256 _XXXToUsdtAmount = _XXXAmount.div(price).mul(10000);
        
        require(tokenUsdt.balanceOf(address(this)) >= _XXXToUsdtAmount);

        require(tokenXXX.transferFrom(msg.sender, address(this), _XXXAmount));
        
        tokenUsdt.transfer(beneficiary, _XXXToUsdtAmount);
        
        return true;
        
    }
    
    
     function _preValidatePurchaseRefund(address _beneficiary, uint256 _amount) internal view {
        require(_amount > 0);
        require(tokenXXX.allowance(_beneficiary, address(this)) >= _amount);
        require(tokenXXX.balanceOf(_beneficiary) >= _amount);
        this; 
    }
    
    
    function _preValidatePurchaseMinting(address _beneficiary, uint256 _amount) internal view {
        require(_amount > 0);
        require(tokenUsdt.allowance(_beneficiary, address(this)) >= _amount);
        require(tokenUsdt.balanceOf(_beneficiary) >= _amount);
        this; 
    }
    	
    
}