/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

/**
 *Care Coin
*/

pragma solidity ^0.7.4;
// SPDX-License-Identifier: Unlicensed
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Ownable {
  address public owner;
 uint256 public careFundFeePercentage ;
 
  uint256 public interestRatePerYear ; 
  uint256 public interestFrequency;
    uint256 public currentLuckCounter ;
    uint256 public luckyTransactionNumber ;
    uint256 public luckRewardPercentage  ;
    string public luckyWinners;
    
    
    address  public careFund ;

    address  public luckFund ;
    
    address  public interestFund ;
    
    address[] public stakeholders;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 event CareFundTransferred(address indexed previousCareFund, address indexed newCareFund);
 event LuckFundTransferred(address indexed previousLuckFund, address indexed newLuckFund);
 event InterestFundTransferred(address indexed previousInterestFund, address indexed newInterestFund);
 


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
  
   function transferCareFund(address newCareFund) public onlyOwner {
    require(newCareFund != address(0));
    emit CareFundTransferred(careFund, newCareFund);
    careFund = newCareFund;
  }
    function transferLuckFund(address newLuckFund) public onlyOwner {
    require(newLuckFund != address(0));
    emit LuckFundTransferred(luckFund, newLuckFund);
    luckFund = newLuckFund;
  }
    function transferInterestFund(address newInterestFund) public onlyOwner {
    require(newInterestFund != address(0));
    emit InterestFundTransferred(interestFund, newInterestFund);
    interestFund = newInterestFund;
  }
  
  function changeCareFundFeePercentage(uint256 newCareFee) public onlyOwner {
    require(newCareFee >= 0);
  
    careFundFeePercentage = newCareFee;

  }
   function changeInterestRatePerYear(uint256 newInterestRatePerYear) public onlyOwner {
    require(newInterestRatePerYear >= 0);
  
    interestRatePerYear = newInterestRatePerYear;

  }
   function changeInterestFrequency(uint256 newInterestFrequency) public onlyOwner {
    require(newInterestFrequency >= 1);
  
    interestFrequency = newInterestFrequency;

  }
    function changeLuckRewardPercentage(uint256 newLuckRewardPercentage) public onlyOwner {
    require(newLuckRewardPercentage >= 0);
  
    luckRewardPercentage = newLuckRewardPercentage;

  }
    function changeLuckyTransactionNumber(uint256 newLuckyTransactionNumber) public onlyOwner {
    require(newLuckyTransactionNumber >= 0);
  
    luckyTransactionNumber = newLuckyTransactionNumber;

  }
    function changeCurrentLuckCounter(uint256 newCurrentLuckCounter) public onlyOwner {
    require(newCurrentLuckCounter >= 0);
  
    currentLuckCounter = newCurrentLuckCounter;

  }
 
  
  

}

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

abstract contract ERC20Basic {
  uint256 public totalSupply;

  event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) virtual public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
  function approve(address spender, uint256 value) virtual public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
	mapping(address => bool) tokenBlacklist;
	event Blacklist(address indexed blackListed, bool value);


  mapping(address => uint256) balances;


 function transfer(address _to, uint256 _value) virtual public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);



    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);



    return true;
  }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

/*
  function transferFrom(address _from, address _to, uint256 _value) override public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    
   

    return true;
  }
  */


  function approve(address _spender, uint256 _value) override public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) override public view returns (uint256) {
    return allowed[_owner][_spender];
  }

/*
  function increaseApproval(address _spender, uint _addedValue) override public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  */

/*
  function decreaseApproval(address _spender, uint _subtractedValue) override public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
*/

  function _blackList(address _address, bool _isBlackListed) internal returns (bool) {
	require(tokenBlacklist[_address] != _isBlackListed);
	tokenBlacklist[_address] = _isBlackListed;
	emit Blacklist(_address, _isBlackListed);
	return true;
  }



}

abstract contract PausableToken is StandardToken, Pausable {
/*
  function transfer(address _to, uint256 _value) override public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) override public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) override public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) override public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) override public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
  */
  function blackListAddress(address listAddress,  bool isBlackListed) public whenNotPaused onlyOwner  returns (bool success) {
	return super._blackList(listAddress, isBlackListed);
  }
  
}

 contract CARECOIN is PausableToken {
   
   
   	
    string public name;
    string public symbol;
    uint public decimals;
    
    uint public lastCollectionTime = (block.timestamp - 1 days) ;
    
   
    
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply, address tokenOwner)  {
        name = _name;
        symbol = _symbol;
        decimals = 9;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        
        careFundFeePercentage = 3;
        interestRatePerYear = 40;
        currentLuckCounter = 0;
        luckyTransactionNumber = 3;
        luckRewardPercentage = 1;
        interestFrequency = 1;
        
        careFund = 0x6aaA85DBa918dA5f0EEDA8F1f43F91af85EAFd8d;
        luckFund =0xd24aE131281C369f6513fD25096BA06B065Bc271;
        interestFund =0x3057d021cc347007f11D9b3B42D2b470f5c799DC;
        
        emit Transfer(address(0), tokenOwner, totalSupply);
    }
	
	function burn(uint256 _value) public {
		_burn(msg.sender, _value);
	}

	function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);
		balances[_who] = balances[_who] - (_value);
		totalSupply = totalSupply - (_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}

    function mint(address account, uint256 amount) onlyOwner public {

        totalSupply = totalSupply + (amount);
        balances[account] = balances[account] + (amount);
        emit Mint(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }
    /*
    function collect_interest() public {
    uint256 daysSinceLastCollect = now.sub(lastCollectionTime).div(1);
    uint256 newInterests = daysSinceLastCollect.mul(interestRatePerYear.div(365)).mul(balanceOf(msg.sender));

balances[owner] = balances[owner].sub(newInterests);
balances[msg.sender] = balances[msg.sender].add(newInterests);
lastCollectionTime = now;

emit Transfer(owner,msg.sender,newInterests);

  //  mint(msg.sender, newInterests);

    
}
*/


 function CollectLuckreward() public {

if(msg.sender != owner && msg.sender != careFund && msg.sender != luckFund && msg.sender != interestFund)
{
uint userBalance;

currentLuckCounter  = currentLuckCounter  + 1 ;
if(luckyTransactionNumber  == currentLuckCounter)
{
uint256 luckAmount;
userBalance = balances[msg.sender];

luckAmount = ((userBalance * luckRewardPercentage ) / 100);

balances[luckFund] = balances[luckFund] - (luckAmount);
balances[msg.sender] = balances[msg.sender] + (luckAmount);

currentLuckCounter  = 0;

string memory addr = toString(msg.sender);
//string memory val = uintToString(luckAmount / (10 ** decimals),false);
string memory val = uintToString(luckAmount,false);
string memory time = uintToString(block.timestamp,false);

luckyWinners = string(abi.encodePacked(luckyWinners  ,"Time : ", time, ", Address : " , addr , " , Luck Reward : " , val, " : ", "\n"));  

emit Transfer(luckFund,msg.sender,luckAmount);
}   
}

  //  mint(msg.sender, newInterests);

    
}

function uintToString(uint v, bool scientific) internal pure returns (string memory str) {

    if (v == 0) {
        return "0";
    }

    uint maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;
    
    while (v != 0) {
        uint remainder = v % 10;
        v = v / 10;
        reversed[i++] = byte(uint8(48 + remainder));
    }

    uint zeros = 0;
    if (scientific) {
        for (uint k = 0; k < i; k++) {
            if (reversed[k] == '0') {
                zeros++;
            } else {
                break;
            }
        }
    }

    uint len = i - (zeros > 2 ? zeros : 0);
    bytes memory s = new bytes(len);
    for (uint j = 0; j < len; j++) {
        s[j] = reversed[i - j - 1];
    }

    str = string(s);

    if (scientific && zeros > 2) {
        str = string(abi.encodePacked(s, "e", uintToString(zeros, false)));
    }
}

function toString(address account) internal pure returns(string memory) {
    return toString(abi.encodePacked(account));
}

function toString(uint256 value) internal pure returns(string memory) {
    return toString(abi.encodePacked(value));
}

function toString(bytes32 value) internal pure returns(string memory) {
    return toString(abi.encodePacked(value));
}

function toString(bytes memory data) internal pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
}

 function transferFrom(address _from, address _to, uint256 _value) override public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from] - (_value);
    balances[_to] = balances[_to] + (_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender] - (_value);
    emit Transfer(_from, _to, _value);
    
    if(_to != owner && _to != careFund && _to != luckFund && _to != interestFund && _from != owner)
    {
DonateToCareFund(_value);
    }
CollectLuckreward();

addStakeholder(_to);
removeStakeholder(_from);

if(isInterestPending())
{
     distributeInterest();
}

    return true;
  }

  function transfer(address _to, uint256 _value) override public returns (bool) {
    require(tokenBlacklist[msg.sender] == false);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);



    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender] - (_value);
    balances[_to] = balances[_to] + (_value);
    emit Transfer(msg.sender, _to, _value);

 if(_to != owner && _to != careFund && _to != luckFund && _to != interestFund && msg.sender != owner)
 {
DonateToCareFund(_value);
}
CollectLuckreward();


addStakeholder(_to);
removeStakeholder(msg.sender);

if(isInterestPending())
{
     distributeInterest();
}

    return true;
  }
  
  function DonateToCareFund(uint256 amount) public{

uint256 careFundAmount = (amount * careFundFeePercentage) / 100;
balances[owner] = balances[owner] - (careFundAmount);
balances[careFund] = balances[careFund] + (careFundAmount);
emit Transfer(owner,careFund,careFundAmount);
      
  }
  
 function isStakeholder(address _address)
       public
       view
       returns(bool, uint256)
   {

       
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }
   
   /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addStakeholder(address _stakeholder)
       public
   {    if(_stakeholder != owner && _stakeholder != careFund && _stakeholder != luckFund && _stakeholder != interestFund)
   {
              uint256 Bal = balances[_stakeholder];
            //  require(Bal > 0 , "Balance is less than Zero.");
              if(Bal >0)
              {
       (bool _isStakeholder,) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }
   }
   }
   
    /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    */
   function removeStakeholder(address _stakeholder)
       public
   {
        uint256 Bal = balances[_stakeholder];
          //require(Bal <= 0 , 'Balance is not Zero.');
          
              if(Bal <=0)
              {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
         //   delete stakeholders[stakeholders.length - 1];
          // stakeholders.pop();
       }
   }
   }
   
    /**
    * @notice A simple method that calculates the rewards for each stakeholder.
    * @param _stakeholder The stakeholder to calculate rewards for.
    */
       function calculateInterest(address _stakeholder)
       public
       view
       returns(uint256)
   {
           uint256 daysSinceLastCollect = ((block.timestamp - lastCollectionTime ) / 86400 );

    uint256  newInterests = (daysSinceLastCollect * (((balanceOf(_stakeholder) * interestRatePerYear ) / 100) / 365));

       return (newInterests);

   }
    function isInterestPending()
       public
       view
       returns(bool _val)
       {
                 uint256 daysSinceLastCollect = ((block.timestamp - lastCollectionTime ) / (interestFrequency * 86400) );
      if(daysSinceLastCollect >=1)
      {
      return(true);
      }
      else
      {
          return(false);
      }
       }

/*
function testdivuu()
 public
       view
       returns(uint256,bool _val)
       {
      uint256 daysSinceLastCollect = ((block.timestamp - lastCollectionTime ) / 86400 );
      if(daysSinceLastCollect >=1)
      {
      return(daysSinceLastCollect,true);
      }
      else
      {
          return(daysSinceLastCollect,false);
      }
      }
      
       
       
       function testdivuupow(address _stakeholder)
 public
       
       returns(uint256 t)
       {
           
            distributeInterest();
            
       return (lastCollectionTime);

       }

*/
 /**
    * @notice A method to distribute rewards to all stakeholders.
    */
   function distributeInterest()
       public
       onlyOwner
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           address stakeholder = stakeholders[s];
           uint256 interest = calculateInterest(stakeholder);
           
       balances[interestFund] = balances[interestFund] - (interest);
       balances[stakeholder] = balances[stakeholder] + (interest);
emit Transfer(interestFund,stakeholder,interest);

       }
       
       
lastCollectionTime = block.timestamp;

   }

/*Liquidity  Code*/

//pragma solidity =0.6.6;


      receive ()  external payable  {
       require(msg.value>0);
        
    }

 //   modifier nonZeroValue() { if (!(msg.value > 0)) require; _; }


    //demo only allows ANYONE to withdraw
    function withdrawAll() internal onlyOwner {
        require(msg.sender.send(address(this).balance));
    }

function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
   // require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount / getPrice();

//tokens = (tokens) / (10 ** decimals);
    // update state
  transferFrom(owner,beneficiary,tokens);

    //forwardFunds();
  }
  
  function getPrice() public    view
       returns(uint256 rate)
       {
           uint256 eth = 1 ether ;
           uint256 tokenc = 100000000 * 10**decimals; // 1:10000 ratio
           rate = eth / tokenc;
           
         //   uint256 weiAmount = 1000000000000;

    // calculate token amount to be created
    //uint256 tokens = weiAmount / (rate);

//uint caltokens = (tokens) / (10 ** decimals);

           return (rate);
       }
       
}