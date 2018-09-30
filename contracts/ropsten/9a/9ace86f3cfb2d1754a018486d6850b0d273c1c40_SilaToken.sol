pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
 
library SafeMath{
    
    
  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    
    
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

 
   /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
 
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }
  
  
 
   /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }


  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

    
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
    
    address public owner;
    address public backupOwner;
    
   /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */

    constructor () public {
        owner =msg.sender;
        backupOwner=0xE81A9B080652DF33B9Dc68974aFf3a92cbA24B53;
        
    } 
    
    /**
   * @dev Throws if called by any account other than the owner.
   */
   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     /**
   * @dev Throws if called by any account other than the backupOwner.
   */
    
    modifier onlyBackupOwner() {
        require(msg.sender == backupOwner);
        _;
    }
    
     /**
   * @dev Function assigns new owner and backupOwner
   * @param newOwner address The address which owns the funds.
   * @param newBackupOwner address The address which will spend the funds.
   */
    
    function transferOwnership(address newOwner,address newBackupOwner) public onlyBackupOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
            backupOwner = newBackupOwner;
        }
    }

}

/**
 * @title Authorizable
 * @dev The Authorizable contract can be used to add multiple addresses to control silatoken main fucntions
 * functions, this will provide more flexibility in terms on signing trasactions
 */

contract Authorizable is Ownable {

    mapping(address => bool) public authorized;
    event authorityAdded(address indexed _toAdd);
    event authorityRemoved(address indexed _toRemove);
    address[] public authorizedAddresses;

    
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || msg.sender == owner);
        _;
    }
    
    
     
     /**
   * @dev Function addAuthorized adds addresses that can issue and redeem silas
   * @param _toAdd address of the added authority
   */

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != 0);
        authorized[_toAdd] = true;
        authorizedAddresses.push(_toAdd);
        emit authorityAdded(_toAdd);
    }
    
    /**
   * @dev Function RemoveAuthorized removes addresses that can issue and redeem silas
   * @param _toRemove address of the added authority
   */

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != 0);
        authorized[_toRemove] = false;
        for (uint i = 0; i<authorizedAddresses.length-1; i++){
            authorizedAddresses[i] = authorizedAddresses[i+1];
        }
        delete authorizedAddresses[authorizedAddresses.length-1];
        authorizedAddresses.length--;
        emit authorityRemoved(_toRemove);
    }
    
    
     /**
   * @dev Function viewAuthorized lets you view all the addresses owned by sila authorized to issue and redeem silas
   */

    function viewAuthorized() external view returns(address[]){
        return authorizedAddresses;
        
    }

}


/**
 * @title EmergencyToggle
 * @dev The EmergencyToggle contract provides a way to pause the contract in emergency
 */

contract EmergencyToggle is Ownable{
     
     
    bool public emergencyFlag; 

 
 
   constructor () public{
      emergencyFlag = false;                            
      
    }
  
  
   /**
    * @dev onlyOwner can can pause the usage of issue,redeem, bathcissue, trasnfer functions
    */
    
    function emergencyToggle() external onlyOwner{
      emergencyFlag = !emergencyFlag;
    }

    
 
 }

/**
 * @title  Token is token Interface
 */

contract Token{
    
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 *@title StandardToken
 *@dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

contract StandardToken is Token,EmergencyToggle{
  using SafeMath for uint256;

  mapping (address => uint256)  balances;

  mapping (address => mapping (address => uint256)) allowed;
  
  uint256 public totalSupply;


  /**
  * @dev Total number of tokens in existence
  */
  
  function totalSupply() public view returns (uint256) {
    return totalSupply;
  }
  
  
  /**
  * @dev Gets the balance of the specified address.
  * @return An uint256 representing the amount owned by the passed address.
  */

  function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
  }

  
  
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  
  function allowance(address _owner,address _spender)public view returns (uint256){
        return allowed[_owner][_spender];
  }

 
  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(emergencyFlag==false);
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  
    /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _value The amount of tokens to be spent.
   */

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(emergencyFlag==false);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
  
    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */

  function transferFrom(address _from,address _to,uint256 _value)public returns (bool){
    require(emergencyFlag==false);
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

}



 /**
 *@title SilaToken
 *@dev Implementation for sila issue,redeem,protectedTransfer,batchissue functions
 */

contract SilaToken is StandardToken,Authorizable{
    using SafeMath for uint256;
    
    // parameters for silatoken
    string  public constant name = "SilaToken";
    string  public constant symbol = "SILA";
    uint256 public constant decimals = 18;
    string  public version = "1.0";
    
     
    //Events fired during successfull execution of main silatoken functions
    event Issued(address indexed _to,uint256 _value);
    event Redeemed(address indexed _from,uint256 _amount);
    event ProtectedTransfer(address indexed _from,address indexed _to,uint256 _amount);
    

    /**
   * @dev issue tokens from sila  to _to address
   * @dev onlyAuthorized  addresses can call this function
   * @param _to address The address which you want to transfer to
   * @param _amount uint256 the amount of tokens to be issued
   */

    function issue(address _to, uint256 _amount) public onlyAuthorized returns (bool) {
      require(emergencyFlag==false);
      require(_to !=address(0));
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);                 
      emit Issued(_to, _amount);                     
      return true;
    }
    
    
      
   /**
   * @dev redeem tokens from _from address
   * @dev onlyAuthorized  addresses can call this function
   * @param _from address is the address from which tokens are burnt
   * @param _amount uint256 the amount of tokens to be burnt
   */

    function redeem(address _from,uint256 _amount) public onlyAuthorized returns(bool){
        require(emergencyFlag==false);
        require(_from != address(0));
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);   
        totalSupply = totalSupply.sub(_amount);
        emit Redeemed(_from,_amount);
        return true;
            

    }
    
    
    /**
   * @dev Transfer tokens from one address to another
   * @dev onlyAuthorized  addresses can call this function
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _amount uint256 the amount of tokens to be transferred
   */

    function protectedTransfer(address _from,address _to,uint256 _amount) public onlyOwner returns(bool){
        require(_amount <= balances[_from]);
        require(emergencyFlag==false);
        require(_to != address(0));
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit ProtectedTransfer(_from, _to, _amount);
        return true;
        
    }
    
 
    
    

    
    

    
    
}