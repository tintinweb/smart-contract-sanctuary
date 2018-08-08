pragma solidity ^0.4.18;

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
    uint256 c = a / b;
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
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

  bool public paused = true;


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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
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
   @title ERC827 interface, an extension of ERC20 token standard
   Interface of a ERC827 token, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
 */
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

/**
   @title ERC827, an extension of ERC20 token standard
   Implementation the ERC827, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
   Uses OpenZeppelin StandardToken.
 */
contract ERC827Token is ERC827, StandardToken {

  /**
     @dev Addition to ERC20 token methods. It allows to
     approve the transfer of value and execute a call with the sent data.
     Beware that changing an allowance with this method brings the risk that
     someone may use both the old and the new allowance by unfortunate
     transaction ordering. One possible solution to mitigate this race condition
     is to first reduce the spender&#39;s allowance to 0 and set the desired value
     afterwards:
     https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     @param _spender The address that will spend the funds.
     @param _value The amount of tokens to be spent.
     @param _data ABI-encoded contract call to call `_to` address.
     @return true if the call function was executed successfully
   */
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

  /**
     @dev Addition to ERC20 token methods. Transfer tokens to a specified
     address and execute a call with the sent data on the same transaction
     @param _to address The address which you want to transfer to
     @param _value uint256 the amout of tokens to be transfered
     @param _data ABI-encoded contract call to call `_to` address.
     @return true if the call function was executed successfully
   */
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

  /**
     @dev Addition to ERC20 token methods. Transfer tokens from one address to
     another and make a contract call on the same transaction
     @param _from The address which you want to send tokens from
     @param _to The address which you want to transfer to
     @param _value The amout of tokens to be transferred
     @param _data ABI-encoded contract call to call `_to` address.
     @return true if the call function was executed successfully
   */
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Increase the amount of tokens that
   * an owner allowed to a spender and execute a call with the sent data.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Decrease the amount of tokens that
   * an owner allowed to a spender and execute a call with the sent data.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

    return true;
  }

}

/**
 * @title Pausable token
 * @dev ERC827Token modified with pausable transfers.
 **/
contract PausableToken is ERC827Token, Pausable {

  // ERC20
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
  
  // ERC827
  function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
      return super.transfer(_to, _value, _data);
  }
  
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
      return super.transferFrom(_from, _to, _value, _data);
  }
  
  function approve(address _spender, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
      return super.approve(_spender, _value, _data);
  }
  
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public whenNotPaused returns (bool) {
      return super.increaseApproval(_spender, _addedValue, _data);
  }
  
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public whenNotPaused returns (bool) {
      return super.decreaseApproval(_spender, _subtractedValue, _data);
  }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is PausableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract AirEX is MintableToken {
  string public constant name = "AIRX";
  string public constant symbol = "AIRX";
  uint8 public constant decimals = 18;

  uint256 public hardCap;
  uint256 public softCap;

  function AirEX(uint256 _cap) public {
    require(_cap > 0);
    hardCap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= hardCap);
    return super.mint(_to, _amount);
  }
  
  function updateHardCap(uint256 _cap) onlyOwner public {
    require(_cap > 0);
    hardCap = _cap;
  }
  
  function updateSoftCap(uint256 _cap) onlyOwner public {
    require(_cap > 0);
    softCap = _cap;  
  }

}

contract SalesManagerUpgradable is Ownable {
    using SafeMath for uint256;

/* SZ: Change here to collection address before deploy */
    address public ethOwner = 0xe8290a10565CB7aDeE9246661B34BB77CB6e4024;
/* SZ: price1..3 in AIRX per 1 ETH */
    uint public price1 = 100;
    uint public price2 = 110;
    uint public price3 = 125;

/* SZ: lev1..2 in ETH */
    uint public lev1 = 2 ether;
    uint public lev2 = 10 ether;
    
    uint public ethFundRaised;
    
    address public tokenAddress;

/* SZ: AIRX constructor with HardCap in AIRX tokens */
    function SalesManagerUpgradable () public {
        tokenAddress = new AirEX(5550000 ether);
    }

    function () payable public {
        if(msg.value > 0) revert();
    }

    function buyTokens(address _investor) public payable returns (bool){
        if (msg.value <= lev1) {
            uint tokens = msg.value.mul(price1);
            if (!sendTokens(tokens, msg.value, _investor)) revert();
            return true;
        } else if (msg.value > lev1 && msg.value <= lev2) {
            tokens = msg.value.mul(price2);
            if (!sendTokens(tokens, msg.value, _investor)) revert();
            return true;
        } else if (msg.value > lev2) {
            tokens = msg.value.mul(price3);
            if (!sendTokens(tokens, msg.value, _investor)) revert();
            return true;
        }
        return false;
    }

    function sendTokens(uint _amount, uint _ethers, address _investor) private returns (bool) {
        AirEX tokenHolder = AirEX(tokenAddress);
        if (tokenHolder.mint(_investor, _amount)) {
            ethFundRaised = ethFundRaised.add(_ethers);
            ethOwner.transfer(_ethers);
            return true;
        }
        return false;
    }
    
    function generateTokensManually(uint _amount, address _to) public onlyOwner {
        AirEX tokenHolder = AirEX(tokenAddress);
        tokenHolder.mint(_to, _amount);
    }
    
    function setColdAddress(address _newAddr) public onlyOwner {
        ethOwner = _newAddr;
    }
    
    function setPrice1 (uint _price) public onlyOwner {
        price1 = _price;
    }
    
    function setPrice2 (uint _price) public onlyOwner {
        price2 = _price;
    }
    
    function setPrice3 (uint _price) public onlyOwner {
        price3 = _price;
    }

/* SZ: Functions setLev1, setLev2 to change levels of prices*/
/* SZ: lev1..2 send as for example "2000000000000000000" for 2 ETH */
    function setLev1 (uint _price) public onlyOwner {
        lev1 = _price;
    }

    function setLev2 (uint _price) public onlyOwner {
        lev2 = _price;
    }
    
    function transferOwnershipToken(address newTokenOwnerAddress) public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.transferOwnership(newTokenOwnerAddress);
    }
    
    function updateHardCap(uint256 _cap) public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.updateHardCap(_cap);
    }
    
    function updateSoftCap(uint256 _cap) public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.updateSoftCap(_cap);
    }
    
    function unPauseContract() public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.unpause();
    }
    
    function pauseContract() public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.pause();
    }
    
    function finishMinting() public onlyOwner {
        AirEX tokenContract = AirEX(tokenAddress);
        tokenContract.finishMinting();
    }
    
    function drop(address[] _destinations, uint256[] _amount) onlyOwner public
    returns (uint) {
        uint i = 0;
        while (i < _destinations.length) {
           AirEX(tokenAddress).mint(_destinations[i], _amount[i]);
           i += 1;
        }
        return(i);
    }
    
    function withdraw(address _to) public onlyOwner {
        _to.transfer(this.balance);
    }
    
    function destroySalesManager(address _recipient) public onlyOwner {
        selfdestruct(_recipient);
    }
}


contract DepositManager is Ownable {
    address public actualSalesAddress;
    
    function DepositManager (address _actualAddres) public {
        actualSalesAddress = _actualAddres;
    }
    
    function () payable public {
        SalesManagerUpgradable sm = SalesManagerUpgradable(actualSalesAddress);
        if(!sm.buyTokens.value(msg.value)(msg.sender)) revert();
    }
    
    function setNewSalesManager (address _newAddr) public onlyOwner {
        actualSalesAddress = _newAddr;
    }

}