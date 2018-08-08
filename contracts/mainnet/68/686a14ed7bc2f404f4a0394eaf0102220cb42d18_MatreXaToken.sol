pragma solidity ^0.4.12;

//======  OpenZeppelin libraray =====

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/** 
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="05776068666a4537">[email&#160;protected]</a>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transfering the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1a687f7779755a28">[email&#160;protected]</a>π.com>
 * @dev This blocks incoming ERC23 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC23 compatible tokens
  * param from_ address The address that is transferring the tokens
  * param value_ uint256 the amount of the specified token
  * param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address /*from_*/, uint256 /*value_*/, bytes /*data_*/) external {
    revert();
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
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

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
  function balanceOf(address _owner) constant returns (uint256 balance) {
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
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

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
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until 
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
    returns (bool success) {
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
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
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

//======  MatreXa =====

contract BurnableToken is StandardToken {
    using SafeMath for uint256;

    event Burn(address indexed from, uint256 amount);
    event BurnRewardIncreased(address indexed from, uint256 value);

    /**
    * @dev Sending ether to contract increases burning reward 
    */
    function() payable {
        if(msg.value > 0){
            BurnRewardIncreased(msg.sender, msg.value);    
        }
    }

    /**
     * @dev Calculates how much ether one will receive in reward for burning tokens
     * @param _amount of tokens to be burned
     */
    function burnReward(uint256 _amount) public constant returns(uint256){
        return this.balance.mul(_amount).div(totalSupply);
    }

    /**
    * @dev Burns tokens and send reward
    * This is internal function because it DOES NOT check 
    * if _from has allowance to burn tokens.
    * It is intended to be used in transfer() and transferFrom() which do this check.
    * @param _from The address which you want to burn tokens from
    * @param _amount of tokens to be burned
    */
    function burn(address _from, uint256 _amount) internal returns(bool){
        require(balances[_from] >= _amount);
        
        uint256 reward = burnReward(_amount);
        assert(this.balance - reward > 0);

        balances[_from] = balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        //assert(totalSupply >= 0); //Check is not needed because totalSupply.sub(value) will already throw if this condition is not met
        
        _from.transfer(reward);
        Burn(_from, _amount);
        return true;
    }

    /**
    * @dev Transfers or burns tokens
    * Burns tokens transferred to this contract itself or to zero address
    * @param _to The address to transfer to or token contract address to burn.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) returns (bool) {
        if( (_to == address(this)) || (_to == 0) ){
            return burn(msg.sender, _value);
        }else{
            return super.transfer(_to, _value);
        }
    }

    /**
    * @dev Transfer tokens from one address to another 
    * or burns them if _to is this contract or zero address
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        if( (_to == address(this)) || (_to == 0) ){
            var _allowance = allowed[_from][msg.sender];
            //require (_value <= _allowance); //Check is not needed because _allowance.sub(_value) will already throw if this condition is not met
            allowed[_from][msg.sender] = _allowance.sub(_value);
            return burn(_from, _value);
        }else{
            return super.transferFrom(_from, _to, _value);
        }
    }

}

/**
 * @title MatreXa Token
 */
contract MatreXaToken is BurnableToken, MintableToken, HasNoContracts, HasNoTokens { //MintableToken is StandardToken, Ownable
    using SafeMath for uint256;

    string public name = "MatreXa";
    string public symbol = "MTRX";
    uint256 public decimals = 18;

    uint256 public allowTransferTimestamp = 0;

    modifier canTransfer() {
        require(mintingFinished);
        require(now > allowTransferTimestamp);
        _;
    }

    function setAllowTransferTimestamp(uint256 _allowTransferTimestamp) onlyOwner {
        require(allowTransferTimestamp == 0);
        allowTransferTimestamp = _allowTransferTimestamp;
    }
    
    function transfer(address _to, uint256 _value) canTransfer returns (bool) {
        BurnableToken.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer returns (bool) {
        BurnableToken.transferFrom(_from, _to, _value);
    }

}