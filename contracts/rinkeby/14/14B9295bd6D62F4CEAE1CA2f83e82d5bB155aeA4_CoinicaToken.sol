pragma solidity ^0.4.18;


import './cca/LimitedTransferCoinicaSmartToken.sol';


/**
  A Token which is 'CCA' compatible and can mint new tokens and pause token-transfer functionality
*/
contract CoinicaToken is LimitedTransferCoinicaSmartToken {

    // =================================================================================================================
    //                                         Members
    // =================================================================================================================

    string public name = "COINICA";

    string public symbol = "CCASNRA";

    uint8 public decimals = 5;

    // =================================================================================================================
    //                                         Constructor
    // =================================================================================================================

    function CoinicaToken() public {
        //Apart of 'CCA' computability - triggered when a smart token is deployed
        NewSmartToken(address(this));
    }
}

pragma solidity ^0.4.18;

import '../token/MintableToken.sol';
import '../token/LimitedTransferToken.sol';
import './ISmartToken.sol';

/**
    BancorSmartToken
*/
contract LimitedTransferCoinicaSmartToken is MintableToken, ISmartToken, LimitedTransferToken {

    // =================================================================================================================
    //                                      Modifiers
    // =================================================================================================================

    /**
     * @dev Throws if destroy flag is not enabled.
     */
    modifier canDestroy() {
        require(destroyEnabled);
        _;
    }

    // =================================================================================================================
    //                                      Members
    // =================================================================================================================

    // We add this flag to avoid users and owner from destroy tokens during crowdsale,
    // This flag is set to false by default and blocks destroy function,
    // We enable destroy option on finalize, so destroy will be possible after the crowdsale.
    bool public destroyEnabled = false;

    // =================================================================================================================
    //                                      Public Functions
    // =================================================================================================================

    function setDestroyEnabled(bool _enable) onlyOwner public {
        destroyEnabled = _enable;
    }

    // =================================================================================================================
    //                                      Impl ISmartToken
    // =================================================================================================================

    //@Override
    function disableTransfers(bool _disable) onlyOwner public {
        transfersEnabled = !_disable;
    }

    //@Override
    function issue(address _to, uint256 _amount) onlyOwner public {
        require(super.mint(_to, _amount));
        Issuance(_amount);
    }

    //@Override
    function destroy(address _from, uint256 _amount) canDestroy public {

        require(msg.sender == _from || msg.sender == owner); // validate input

        balances[_from] = balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        Destruction(_amount);
        Transfer(_from, 0x0, _amount);
    }

    // =================================================================================================================
    //                                      Impl LimitedTransferToken
    // =================================================================================================================


    // Enable/Disable token transfer
    // Tokens will be locked in their wallets until the end of the Crowdsale.
    // @holder - token`s owner
    // @time - not used (framework unneeded functionality)
    //
    // @Override
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        require(transfersEnabled);
        return super.transferableTokens(holder, time);
    }
}

pragma solidity ^0.4.18;


import './StandardToken.sol';
import '../ownership/Claimable.sol';


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Claimable {
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
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

pragma solidity ^0.4.18;

import "./ERC20.sol";

/**
 * @title LimitedTransferToken
 * @dev LimitedTransferToken defines the generic interface and the implementation to limit token
 * transferability for different events. It is intended to be used as a base class for other token
 * contracts.
 * LimitedTransferToken has been designed to allow for different limiting factors,
 * this can be achieved by recursively calling super.transferableTokens() until the base class is
 * hit. For example:
 *     function transferableTokens(address holder, uint64 time) constant public returns (uint256) {
 *       return min256(unlockedTokens, super.transferableTokens(holder, time));
 *     }
 * A working example is VestedToken.sol:
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/VestedToken.sol
 */

contract LimitedTransferToken is ERC20 {

  /**
   * @dev Checks whether it can transfer or otherwise throws.
   */
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(now)));
   _;
  }

  /**
   * @dev Checks modifier and allows transfer if tokens are not locked.
   * @param _to The address that will receive the tokens.
   * @param _value The amount of tokens to be transferred.
   */
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

  /**
  * @dev Checks modifier and allows transfer if tokens are not locked.
  * @param _from The address that will send the tokens.
  * @param _to The address that will receive the tokens.
  * @param _value The amount of tokens to be transferred.
  */
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Default transferable tokens function returns all tokens for a holder (no limit).
   * @dev Overwriting transferableTokens(address holder, uint64 time) is the way to provide the
   * specific logic for limiting token transferability for a holder over time.
   */
  function transferableTokens(address holder, uint64 time) public view returns (uint256) {
    return balanceOf(holder);
  }
}

pragma solidity ^0.4.18;

/*
    Smart Token interface
*/
contract ISmartToken {

    // =================================================================================================================
    //                                      Members
    // =================================================================================================================

    bool public transfersEnabled = false;

    // =================================================================================================================
    //                                      Event
    // =================================================================================================================

    // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewSmartToken(address _token);
    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);

    // =================================================================================================================
    //                                      Functions
    // =================================================================================================================

    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

pragma solidity ^0.4.18;


import './BasicToken.sol';
import './ERC20.sol';


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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

pragma solidity ^0.4.18;


import './Ownable.sol';


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() onlyPendingOwner public {
        OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

pragma solidity ^0.4.18;


import './ERC20Basic.sol';
import '../math/SafeMath.sol';


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

pragma solidity ^0.4.18;


import './ERC20Basic.sol';


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

pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

pragma solidity ^0.4.18;


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