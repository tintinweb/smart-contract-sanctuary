pragma solidity ^0.4.24;

// File: contracts/math/SafeMath.sol

/**
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Released under the MIT license.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
*/

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
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: contracts/ownership/Ownable.sol

/**
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Released under the MIT license.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
*/

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

// File: contracts/token/ERC20/ERC20Interface.sol

/**
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Released under the MIT license.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
*/

/**
 * @title 
 * @dev 
 */
contract ERC20Interface {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/token/ERC20/ERC20Standard.sol

/**
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Released under the MIT license.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
*/



/**
 * @title 
 * @dev 
 */
contract ERC20Standard is ERC20Interface {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) external returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
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
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * 
   * To avoid this issue, allowances are only allowed to be changed between zero and non-zero.
   *
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) external returns (bool) {
    require(allowed[msg.sender][_spender] == 0 || _value == 0);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() external view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) external view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) external view returns (uint256) {
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
  function increaseApproval(address _spender, uint _addedValue) external returns (bool) {
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
  function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool) {
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

// File: contracts/token/ERC223/ERC223Interface.sol

/**
 * Released under the MIT license.
 * https://github.com/Dexaran/ERC223-token-standard/blob/master/LICENSE
*/

contract ERC223Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value, bytes data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/token/ERC223/ERC223ReceivingContract.sol

/**
 * Released under the MIT license.
 * https://github.com/Dexaran/ERC223-token-standard/blob/master/LICENSE
*/


/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

// File: contracts/token/ERC223/ERC223Standard.sol

/**
 * Released under the MIT license.
 * https://github.com/Dexaran/ERC223-token-standard/blob/master/LICENSE
*/





/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract ERC223Standard is ERC223Interface, ERC20Standard {
    using SafeMath for uint256;

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint256 _value, bytes _data) external returns(bool){
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint256 codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value);
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn&#39;t contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint256 _value) external returns(bool){
        uint256 codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
 
}

// File: contracts/token/extentions/MintableToken.sol

/**
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Released under the MIT license.
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
*/





/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is ERC223Standard, Ownable {
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
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: contracts/DAICOVO/TokenController.sol

/// @title A controller that manages permissions to mint specific ERC20/ERC223 token.
/// @author ICOVO AG
/// @dev The target must be a mintable ERC20/ERC223 and also be set its ownership
///      to this controller. It changes permissions in each 3 phases - before the
///      token-sale, during the token-sale and after the token-sale.
///     
///      Before the token-sale (State = Init):
///       Only the owner of this contract has a permission to mint tokens.
///      During the token-sale (State = Tokensale):
///       Only the token-sale contract has a permission to mint tokens.
///      After the token-sale (State = Public):
///       Nobody has any permissions. Will be expand in the future:
contract TokenController is Ownable {
    using SafeMath for uint256;

    MintableToken public targetToken;
    address public votingAddr;
    address public tokensaleManagerAddr;

    State public state;

    enum State {
        Init,
        Tokensale,
        Public
    }

    /// @dev The deployer must change the ownership of the target token to this contract.
    /// @param _targetToken : The target token this contract manage the rights to mint.
    /// @return 
    constructor (
        MintableToken _targetToken
    ) public {
        targetToken = MintableToken(_targetToken);
        state = State.Init;
    }

    /// @dev Mint and distribute specified amount of tokens to an address.
    /// @param to An address that receive the minted tokens.
    /// @param amount Amount to mint.
    /// @return True if the distribution is successful, revert otherwise.
    function mint (address to, uint256 amount) external returns (bool) {
        /*
          being called from voting contract will be available in the future
          ex. if (state == State.Public && msg.sender == votingAddr) 
        */

        if ((state == State.Init && msg.sender == owner) ||
            (state == State.Tokensale && msg.sender == tokensaleManagerAddr)) {
            return targetToken.mint(to, amount);
        }

        revert();
    }

    /// @dev Change the phase from "Init" to "Tokensale".
    /// @param _tokensaleManagerAddr A contract address of token-sale.
    /// @return True if the change of the phase is successful, revert otherwise.
    function openTokensale (address _tokensaleManagerAddr)
        external
        onlyOwner
        returns (bool)
    {
        /* check if the owner of the target token is set to this contract */
        require(MintableToken(targetToken).owner() == address(this));
        require(state == State.Init);
        require(_tokensaleManagerAddr != address(0x0));

        tokensaleManagerAddr = _tokensaleManagerAddr;
        state = State.Tokensale;
        return true;
    }

    /// @dev Change the phase from "Tokensale" to "Public". This function will be
    ///      cahnged in the future to receive an address of voting contract as an
    ///      argument in order to handle the result of minting proposal.
    /// @return True if the change of the phase is successful, revert otherwise.
    function closeTokensale () external returns (bool) {
        require(state == State.Tokensale && msg.sender == tokensaleManagerAddr);

        state = State.Public;
        return true;
    }

    /// @dev Check if the state is "Init" or not.
    /// @return True if the state is "Init", false otherwise.
    function isStateInit () external view returns (bool) {
        return (state == State.Init);
    }

    /// @dev Check if the state is "Tokensale" or not.
    /// @return True if the state is "Tokensale", false otherwise.
    function isStateTokensale () external view returns (bool) {
        return (state == State.Tokensale);
    }

    /// @dev Check if the state is "Public" or not.
    /// @return True if the state is "Public", false otherwise.
    function isStatePublic () external view returns (bool) {
        return (state == State.Public);
    }
}