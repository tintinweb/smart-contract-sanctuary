pragma solidity ^0.4.21;


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
    constructor() public {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0x0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken, Pausable {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0x0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant whenNotPaused returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  
  function increaseApproval (address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Ludcoin is StandardToken {
    using SafeMath for uint256;

    //Information coin
    string public name = "Ludcoin";
    string public symbol = "LUD";
    uint256 public decimals = 18;
    uint256 public totalSupply = 800000000 * (10 ** decimals); //800 000 000 LUD

    //Adress informated in white paper 
    address public walletETH;               //Wallet ETH
    address public contractAddress = this;  //6%
    address public tokenSale;               //67%
    address public company;                 //20%
    address public bounty;                  //2%
    address public gamesFund;               //5%       

    //Utils ICO   
    uint256 public icoStage = 0;        
    uint256 public tokensSold = 0;          //total number of tokens sold
    uint256 public totalRaised = 0;         //total amount of money raised in wei
    uint256 public totalTokenToSale = 0;
    uint256 public rate = 2700;             //LUD/ETH rate / initial 50%
    bool public pauseEmergence = false;     //the owner address can set this to true to halt the crowdsale due to emergency
    

    //Time Start and Time end
    uint256 public icoStartTimestampStage = 1525132800;       //05/01/2018 @ 00:00am (UTC)
    uint256 public icoEndTimestampStage = 1543622399;         //11/30/2018 @ 11:59pm (UTC)

// =================================== Events ================================================

    event Burn(address indexed burner, uint256 value);  


// =================================== Constructor =============================================
       
    constructor() public {         
      walletETH = 0x7573791105bfB3c0329A3a1DDa7Eb2D01B61Fb7D;
      tokenSale = 0x21f8784cA7065ad252e1401208B153d5b7a740d1;        //67% (total sale + bonus)
      company = 0x8185ae2Da7891557C622Fb23C431A9cf7DF6E457;          //20%
      bounty = 0x80c4933a9a614e7671D52Fd218d2EB29412bf584;           //2%
      gamesFund = 0x413cF71fB3E7dAf8c8Af21E40429E7315196E3d1;        //5% 

      //Distribution Token  
      balances[tokenSale] = totalSupply.mul(67).div(100);            //totalSupply * 67%
      balances[company] = totalSupply.mul(20).div(100);              //totalSupply * 20%
      balances[gamesFund] = totalSupply.mul(5).div(100);             //totalSupply * 5%   
      balances[bounty] = totalSupply.mul(2).div(100);                //totalSupply * 2%
      balances[contractAddress] = totalSupply.mul(6).div(100);       //totalSupply * 6%(3% team + 3% advisors)
      
     
      //set token to sale
      totalTokenToSale = balances[tokenSale];           
    }

 // ======================================== Modifier ==================================================

    modifier acceptsFunds() {   
        require(now >= icoStartTimestampStage);          
        require(now <= icoEndTimestampStage); 
        _;
    }    

    modifier nonZeroBuy() {
        require(msg.value > 0);
        _;

    }

    modifier PauseEmergence {
        require(!pauseEmergence);
       _;
    } 

//========================================== Functions ===========================================================================

    /// fallback function to buy tokens
    function () PauseEmergence nonZeroBuy acceptsFunds payable public {  
        uint256 amount = msg.value.mul(rate);
        
        assignTokens(msg.sender, amount);
        totalRaised = totalRaised.add(msg.value);
        forwardFundsToWallet();
    } 

    function forwardFundsToWallet() internal {
        // immediately send Ether to wallet address, propagates exception if execution fails        
        walletETH.transfer(msg.value); 
    }

    function assignTokens(address recipient, uint256 amount) internal {
        uint256 amountTotal = amount;
        
        if (icoStage > 0) {
            amountTotal = amountTotal + amountTotal.mul(2).div(100);    
        }
        
        balances[tokenSale] = balances[tokenSale].sub(amountTotal);   
        balances[recipient] = balances[recipient].add(amountTotal);
        tokensSold = tokensSold.add(amountTotal);        
       
        //test token sold, if it was sold more than the total available right total token total
        if (tokensSold > totalTokenToSale) {
            uint256 diferenceTotalSale = totalTokenToSale.sub(tokensSold);
            totalTokenToSale = tokensSold;
            totalSupply = tokensSold.add(diferenceTotalSale);
        }
        
        emit Transfer(0x0, recipient, amountTotal);
    }  

    function manuallyAssignTokens(address recipient, uint256 amount) public onlyOwner {
        require(tokensSold < totalSupply);
        assignTokens(recipient, amount);
    }

    function setRate(uint256 _rate) public onlyOwner { 
        require(_rate > 0);               
        rate = _rate;        
    }

    function setIcoStage(uint256 _icoStage) public onlyOwner {    
        require(_icoStage >= 0); 
        require(_icoStage <= 4);             
        icoStage = _icoStage;        
    }

    function setPauseEmergence() public onlyOwner {        
        pauseEmergence = true;
    }

    function setUnPauseEmergence() public onlyOwner {        
        pauseEmergence = false;
    }   

    function sendTokenTeamAdvisor(address walletTeam, address walletAdvisors ) public onlyOwner {
        //test deadline to request token
        require(now >= icoEndTimestampStage);
        require(walletTeam != 0x0);
        require(walletAdvisors != 0x0);
        
        uint256 amount = 24000000 * (10 ** decimals);
        
        //send tokens 
        balances[contractAddress] = 0;
        balances[walletTeam] = balances[walletTeam].add(amount);
        balances[walletAdvisors] = balances[walletAdvisors].add(amount);
        
        emit Transfer(contractAddress, walletTeam, amount);
        emit Transfer(contractAddress, walletAdvisors, amount);
    }

    function burn(uint256 _value) public whenNotPaused {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }   
    
}