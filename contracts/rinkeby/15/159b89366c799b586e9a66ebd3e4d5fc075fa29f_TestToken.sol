/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.7.0;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  constructor() {
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

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view virtual returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
abstract contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

 
}

// File: zeppelin-solidity/contracts/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view virtual returns (uint256);
  function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
  function approve(address spender, uint256 value) public virtual returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
abstract contract StandardToken is ERC20, BasicToken {
    using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public override returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view override returns (uint256) {
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract TestToken is StandardToken, Ownable {
    event AssignmentStopped();
    event Frosted(address indexed to, uint256 amount, uint256 defrostClass);
    event Defrosted(address indexed to, uint256 amount, uint256 defrostClass);

	using SafeMath for uint256;

    /* Overriding some ERC20 variables */
    string public constant name      = "TestToken";
    string public constant symbol    = "TST";
    uint8 public constant decimals   = 18;

    uint256 public constant MAX_NUM_TESTTOKENS    = 220000000 * 10 ** uint256(decimals);
    uint256 public constant START_ICO_TIMESTAMP   = 1619711668;  // TODO: line to uncomment for the PROD before the main net deployment
    //uint256 public START_ICO_TIMESTAMP; // TODO: !!! line to remove before the main net deployment (not constant for testing and overwritten in the constructor)

    uint256 public constant MONTH_IN_MINUTES = 43200; // month in minutes  (1month = 43200 min)
    uint256 public totalStrategicSupply;
    uint256 public totalPvt1Supply;
    uint256 public totalPvt2Supply;
    uint256 public totalAirdropSupply;
    uint256 public totalPublicSaleSupply;
    uint256 public totalalloc;

    struct stakeAccount{
    address AccountHolder;
    uint256 stakeamount;
    uint256 startTime;
    uint256 remainingTime;
}    

    uint256 public monthIndex;
    bool public InitUnTrigger = true;
    uint256 public count;
    
    uint256 time_of_investment = block.timestamp;


    enum DefrostClass {StrategicSale, PvtSale1, PvtSale2, PublicSale, Airdrop}
mapping(address=>stakeAccount) public StakeInfo;
uint256 totalLockingTime= 30 minutes ;
    // Fields that can be changed by functions
    address[] public icedBalancesStrategicSale;
    address[] public icedBalancesPvtSale1;
    address[] public icedBalancesPvtSale2;

    mapping (address => uint256) public mapicedBalancesStrategicSale;
    mapping (address => uint256) public mapicedBalancesPvtSale1;
    mapping (address => uint256) public mapicedBalancesPvtSale2;
    
    mapping (address => uint256) public totalicedBalancesStrategicSale;
    mapping (address => uint256) public totalicedBalancesPvtSale1;
    mapping (address => uint256) public totalicedBalancesPvtSale2;

        //Boolean to allow or not the initial assignement of token (batch)
    bool public batchAssignStopped = false;

    modifier canAssign() {
        require(!batchAssignStopped);
        //require(elapsedMonthsFromICOStart() < 2);
        _;
    }

    constructor() {
        // for test only: set START_ICO to contract creation timestamp
        //START_ICO_TIMESTAMP = now; // TODO: line to remove before the main net deployment
    }
    function alloc(address addre, uint256 aamount) public onlyOwner canAssign{
        uint256 avmount = aamount*1e18;
        totalSupply = totalSupply.add(aamount);
            require(totalSupply <= MAX_NUM_TESTTOKENS);
            require (totalalloc <= 151000000 * 10 ** uint256(decimals));
            balances[addre] = balances[addre].add(aamount);
            totalalloc = totalalloc.add(aamount);
            
    }

    function batchAssignTokens(address[] memory _addr, uint256[] memory _amounts, DefrostClass[] memory _defrostClass) public onlyOwner canAssign {
        require(_addr.length == _amounts.length && _addr.length == _defrostClass.length);
        //Looping into input arrays to assign target amount to each given address
        
        for (uint256 index = 0; index < _addr.length; index++) {
            address toAddress = _addr[index];
            uint256 amount = _amounts[index]*1e18;
            DefrostClass defrostClass = _defrostClass[index]; /* 0 = StrategicSale, 1 = PvtSale1, 2 = PvtSale2, 
            3 = PublicSale, 4 = Airdrop */

            totalSupply = totalSupply.add(amount);
            require(totalSupply <= MAX_NUM_TESTTOKENS);

            if (defrostClass == DefrostClass.PublicSale || defrostClass == DefrostClass.Airdrop) {
               
                require (totalPublicSaleSupply <= 6000000 * 10 ** uint256(decimals) && totalAirdropSupply <= 3000000 * 10 ** uint256(decimals));
                balances[toAddress] = balances[toAddress].add(amount);
                if (defrostClass == DefrostClass.PublicSale) {
                    totalPublicSaleSupply = totalPublicSaleSupply.add(amount);
                    emit Defrosted(toAddress, amount, uint256(DefrostClass.PublicSale));
                }
                if (defrostClass == DefrostClass.Airdrop) {
                    totalAirdropSupply = totalAirdropSupply.add(amount);
                    emit Defrosted(toAddress, amount, uint256(DefrostClass.Airdrop));
                }
                emit Transfer(address(0), toAddress, amount);  
                
            } else if (defrostClass == DefrostClass.StrategicSale) {
                
                icedBalancesStrategicSale.push(toAddress);
                mapicedBalancesStrategicSale[toAddress] = mapicedBalancesStrategicSale[toAddress].add(amount);
                totalicedBalancesStrategicSale[toAddress] = totalicedBalancesStrategicSale[toAddress].add(amount);
                emit Frosted(toAddress, amount, uint256(defrostClass));
            } else if (defrostClass == DefrostClass.PvtSale1) {
                
                icedBalancesPvtSale1.push(toAddress);
                mapicedBalancesPvtSale1[toAddress] = mapicedBalancesPvtSale1[toAddress].add(amount);
                totalicedBalancesPvtSale1[toAddress] = totalicedBalancesPvtSale1[toAddress].add(amount);
                emit Frosted(toAddress, amount, uint256(defrostClass));
            } else if (defrostClass == DefrostClass.PvtSale2) {
              
                icedBalancesPvtSale2.push(toAddress);
                mapicedBalancesPvtSale2[toAddress] = mapicedBalancesPvtSale2[toAddress].add(amount);
                totalicedBalancesPvtSale2[toAddress] = totalicedBalancesPvtSale2[toAddress].add(amount);
                emit Frosted(toAddress, amount, uint256(defrostClass));
            }
        }
        icedBalancesStrategicSale = filterAddress(icedBalancesStrategicSale);
        icedBalancesPvtSale1 = filterAddress(icedBalancesPvtSale1);
        icedBalancesPvtSale2 = filterAddress(icedBalancesPvtSale2);
    }


    
    function defrostTokens() public {
        
      
      if( InitUnTrigger && InitTknUnlockStatus()) {
        stopBatchAssign();
        monthIndex = 121;
                count = 2;

        for (uint256 index = 0; index < icedBalancesStrategicSale.length; index++) {
          address currentAddress = icedBalancesStrategicSale[index];
          uint256 amountToDefrost = mapicedBalancesStrategicSale[currentAddress];
          if (amountToDefrost > 0) {
            require(totalStrategicSupply <= 15000000 * 10 ** uint256(decimals));
            amountToDefrost = amountToDefrost.mul(20).div(100);
            balances[currentAddress] = balances[currentAddress].add(amountToDefrost);
            totalicedBalancesStrategicSale[currentAddress] = totalicedBalancesStrategicSale[currentAddress].sub(amountToDefrost);
            totalStrategicSupply = totalStrategicSupply.add(amountToDefrost);
            //Transfer(address(0), currentAddress, amountToDefrost);
            emit Defrosted(currentAddress, amountToDefrost, uint256(DefrostClass.StrategicSale));
            emit Transfer(address(0), currentAddress, amountToDefrost);
          }
        }

        for (uint256 index = 0; index < icedBalancesPvtSale1.length; index++) {
          address currentAddress = icedBalancesPvtSale1[index];
          uint256 amountToDefrost = mapicedBalancesPvtSale1[currentAddress];
          if (amountToDefrost > 0) {
            require(totalPvt1Supply <= 37500000 * 10 ** uint256(decimals));
            amountToDefrost = amountToDefrost.mul(25).div(100);
            balances[currentAddress] = balances[currentAddress].add(amountToDefrost);
            totalicedBalancesPvtSale1[currentAddress] = totalicedBalancesPvtSale1[currentAddress].sub(amountToDefrost);
            totalPvt1Supply = totalPvt1Supply.add(amountToDefrost);
            //Transfer(address(0), currentAddress, amountToDefrost);
            emit Defrosted(currentAddress, amountToDefrost, uint256(DefrostClass.PvtSale1));
            emit Transfer(address(0), currentAddress, amountToDefrost);
          }
        }

        for (uint256 index = 0; index < icedBalancesPvtSale2.length; index++) {
          address currentAddress = icedBalancesPvtSale2[index];
          uint256 amountToDefrost = mapicedBalancesPvtSale2[currentAddress];
          if (amountToDefrost > 0) {
            require(totalPvt2Supply <= 7500000 * 10 ** uint256(decimals));
            amountToDefrost = amountToDefrost.mul(25).div(100);
            balances[currentAddress] = balances[currentAddress].add(amountToDefrost);
            totalicedBalancesPvtSale2[currentAddress] = totalicedBalancesPvtSale2[currentAddress].sub(amountToDefrost);
            totalPvt2Supply = totalPvt2Supply.add(amountToDefrost);
            //Transfer(address(0), currentAddress, amountToDefrost);
            emit Defrosted(currentAddress, amountToDefrost, uint256(DefrostClass.PvtSale2));
            emit Transfer(address(0), currentAddress, amountToDefrost);
          }
        }
        InitUnTrigger = false;
      }

      if(CycleTknUnlockStatus()) {
          monthIndex++; 
        for (uint256 index = 0; index < icedBalancesStrategicSale.length; index++) {
          address currentAddress = icedBalancesStrategicSale[index];
          uint256 amountToDefrost = mapicedBalancesStrategicSale[currentAddress];
          if (amountToDefrost > 0) {
            require(totalStrategicSupply <= 15000000 * 10 ** uint256(decimals));
            amountToDefrost = amountToDefrost.mul(8).div(100);
            balances[currentAddress] = balances[currentAddress].add(amountToDefrost);
            totalicedBalancesStrategicSale[currentAddress] = totalicedBalancesStrategicSale[currentAddress].sub(amountToDefrost);
            totalStrategicSupply = totalStrategicSupply.add(amountToDefrost);
            //Transfer(address(0), currentAddress, amountToDefrost);
            emit Defrosted(currentAddress, amountToDefrost, uint256(DefrostClass.StrategicSale));
            emit Transfer(address(0), currentAddress, amountToDefrost);
            }
          }
        for (uint256 index = 0; index < icedBalancesPvtSale1.length; index++) {
          address currentAddress = icedBalancesPvtSale1[index];
          uint256 amountToDefrost = mapicedBalancesPvtSale1[currentAddress];
          if (amountToDefrost > 0) {
            require(totalPvt1Supply <= 37500000 * 10 ** uint256(decimals));
            amountToDefrost = amountToDefrost.mul(75).div(1000);
            balances[currentAddress] = balances[currentAddress].add(amountToDefrost);
            totalicedBalancesPvtSale1[currentAddress] = totalicedBalancesPvtSale1[currentAddress].sub(amountToDefrost);
            totalPvt1Supply = totalPvt1Supply.add(amountToDefrost);
            //Transfer(address(0), currentAddress, amountToDefrost);
            emit Defrosted(currentAddress, amountToDefrost, uint256(DefrostClass.PvtSale1));
            emit Transfer(address(0), currentAddress, amountToDefrost);
          }
        }

        for (uint256 index = 0; index < icedBalancesPvtSale2.length; index++) {
          address currentAddress = icedBalancesPvtSale2[index];
          uint256 amountToDefrost = mapicedBalancesPvtSale2[currentAddress];
          if (amountToDefrost > 0) {
            require(totalPvt2Supply <= 7500000 * 10 ** uint256(decimals));
            amountToDefrost = amountToDefrost.mul(75).div(1000);
            balances[currentAddress] = balances[currentAddress].add(amountToDefrost);
            totalicedBalancesPvtSale2[currentAddress] = totalicedBalancesPvtSale2[currentAddress].sub(amountToDefrost);
            totalPvt2Supply = totalPvt2Supply.add(amountToDefrost);
            //Transfer(address(0), currentAddress, amountToDefrost);
            emit Defrosted(currentAddress, amountToDefrost, uint256(DefrostClass.PvtSale2));
            emit Transfer(address(0), currentAddress, amountToDefrost);
          }
        }
        
      }
    } 
      
    function InitTknUnlockStatus() public view returns (bool) {
        if(count <= 1)
        {
            if(block.timestamp >= time_of_investment + (120 * 60)) {
                
                return true;
            }
            else{
                return false;
            }
        }
        else{
            return false;
        }
    }

    //The cycletkn unlock function will only run if InitTkn is executed
    function CycleTknUnlockStatus() public view returns (bool) {
        if((monthIndex > 120 && monthIndex <= 130)){
            if(block.timestamp >= time_of_investment + (monthIndex * 60)) { 
                
                return true;
            }
            else{
                return false;
            }
        }
        else{
            return false;
        }
    }
    
    
    function filterAddress(address[] memory array) private pure returns(address[] memory){
        for (uint256 index; index < array.length; index++) {
            if(array[index] != address(0)) {
                for(uint256 a = index+1; a < array.length; a++){
                    if(array[index] == array[a]){
                        array[a] = address(0); 
                    }
                }
            }
        }
        return array;
    }
 /*
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return totalicedBalancesStrategicSale[_owner]+totalicedBalancesPvtSale2[_owner]+totalicedBalancesPvtSale1[_owner]+StakeInfo[_owner].stakeamount;
  }
  function totalBalanceOf(address _owner) public view returns (uint256 balance) {
      
    return balances[_owner]+totalicedBalancesStrategicSale[_owner]+totalicedBalancesPvtSale2[_owner]+totalicedBalancesPvtSale1[_owner]+StakeInfo[_owner].stakeamount;
  }
  function unlockedBalanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

    function stopBatchAssign() public onlyOwner canAssign {
        batchAssignStopped = true;
        AssignmentStopped();
    }
    
   function staking(uint256 tostake)  public {
require(balances[msg.sender]>=tostake, "amount not available");
// require(balances[msg.sender]!=0&&msg.value<=balances[msg.sender],"No money for staking");
transfer(address(this),tostake);
StakeInfo[msg.sender].AccountHolder=msg.sender;
StakeInfo[msg.sender].stakeamount=tostake;
StakeInfo[msg.sender].startTime=block.timestamp;

}

//***********get remaining day ****************//
function getReaminingTime(address holder) view public returns(bool){
if (StakeInfo[holder].startTime +30 minutes <= block.timestamp)
{return true;}
else 
{return false;}
}



//***************** unstaking **********************//
function Unstaking(address holder,uint256 amount) public returns(uint256){
require(StakeInfo[holder].startTime +30 minutes <= block.timestamp,"locking time is not complete");
balances[address(this)]= balances[address(this)]-amount;
balances[holder]= balances[holder]+amount;
StakeInfo[holder].stakeamount=StakeInfo[holder].stakeamount-amount;
emit Transfer(address(this),holder,amount);
}

    fallback() external payable {
        revert();
    }
}