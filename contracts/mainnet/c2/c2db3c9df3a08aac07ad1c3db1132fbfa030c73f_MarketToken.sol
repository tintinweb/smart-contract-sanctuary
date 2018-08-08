pragma solidity ^0.4.18;

/*
    Copyright 2017-2018 Phillip A. Elsasser

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


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


contract UpgradeableTarget {
    function upgradeFrom(address from, uint256 value) external; // note: implementation should require(from == oldToken)
}


contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

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



/// @title Upgradeable Token
/// @notice allows for us to update some of the needed functionality in our tokens post deployment. Inspiration taken
/// from Golems migrate functionality.
/// @author Phil Elsasser <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="19697170755974786b727c6d696b766d767a7675377076">[email&#160;protected]</a>>
contract UpgradeableToken is Ownable, BurnableToken, StandardToken {

    address public upgradeableTarget;       // contract address handling upgrade
    uint256 public totalUpgraded;           // total token amount already upgraded

    event Upgraded(address indexed from, address indexed to, uint256 value);

    /*
    // EXTERNAL METHODS - TOKEN UPGRADE SUPPORT
    */

    /// @notice Update token to the new upgraded token
    /// @param value The amount of token to be migrated to upgraded token
    function upgrade(uint256 value) external {
        require(upgradeableTarget != address(0));

        burn(value);                    // burn tokens as we migrate them.
        totalUpgraded = totalUpgraded.add(value);

        UpgradeableTarget(upgradeableTarget).upgradeFrom(msg.sender, value);
        Upgraded(msg.sender, upgradeableTarget, value);
    }

    /// @notice Set address of upgrade target process.
    /// @param upgradeAddress The address of the UpgradeableTarget contract.
    function setUpgradeableTarget(address upgradeAddress) external onlyOwner {
        upgradeableTarget = upgradeAddress;
    }

}




/// @title Market Token
/// @notice Our membership token.  Users must lock tokens to enable trading for a given Market Contract
/// as well as have a minimum balance of tokens to create new Market Contracts.
/// @author Phil Elsasser <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="66160e0f0a260b07140d0312161409120905090a480f09">[email&#160;protected]</a>>
contract MarketToken is UpgradeableToken {

    string public constant name = "MARKET Protocol Token";
    string public constant symbol = "MKT";
    uint8 public constant decimals = 18;

    uint public constant INITIAL_SUPPLY = 600000000 * 10**uint(decimals); // 600 million tokens with 18 decimals (6e+26)

    uint public lockQtyToAllowTrading;
    uint public minBalanceToAllowContractCreation;

    mapping(address => mapping(address => uint)) contractAddressToUserAddressToQtyLocked;

    event UpdatedUserLockedBalance(address indexed contractAddress, address indexed userAddress, uint balance);

    function MarketToken(uint qtyToLockForTrading, uint minBalanceForCreation) public {
        lockQtyToAllowTrading = qtyToLockForTrading;
        minBalanceToAllowContractCreation = minBalanceForCreation;
        totalSupply_ = INITIAL_SUPPLY;  //note totalSupply_ and INITIAL_SUPPLY may vary as token&#39;s are burnt.

        balances[msg.sender] = INITIAL_SUPPLY; // for now allocate all tokens to creator
    }

    /*
    // EXTERNAL METHODS
    */

    /// @notice checks if a user address has locked the needed qty to allow trading to a given contract address
    /// @param marketContractAddress address of the MarketContract
    /// @param userAddress address of the user
    /// @return true if user has locked tokens to trade the supplied marketContractAddress
    function isUserEnabledForContract(address marketContractAddress, address userAddress) external view returns (bool) {
        return contractAddressToUserAddressToQtyLocked[marketContractAddress][userAddress] >= lockQtyToAllowTrading;
    }

    /// @notice checks if a user address has enough token balance to be eligible to create a contract
    /// @param userAddress address of the user
    /// @return true if user has sufficient balance of tokens
    function isBalanceSufficientForContractCreation(address userAddress) external view returns (bool) {
        return balances[userAddress] >= minBalanceToAllowContractCreation;
    }

    /// @notice allows user to lock tokens to enable trading for a given market contract
    /// @param marketContractAddress address of the MarketContract
    /// @param qtyToLock desired qty of tokens to lock
    function lockTokensForTradingMarketContract(address marketContractAddress, uint qtyToLock) external {
        uint256 lockedBalance = contractAddressToUserAddressToQtyLocked[marketContractAddress][msg.sender].add(
            qtyToLock
        );
        transfer(this, qtyToLock);
        contractAddressToUserAddressToQtyLocked[marketContractAddress][msg.sender] = lockedBalance;
        UpdatedUserLockedBalance(marketContractAddress, msg.sender, lockedBalance);
    }

    /// @notice allows user to unlock tokens previously allocated to trading a MarketContract
    /// @param marketContractAddress address of the MarketContract
    /// @param qtyToUnlock desired qty of tokens to unlock
    function unlockTokens(address marketContractAddress, uint qtyToUnlock) external {
        uint256 balanceAfterUnLock = contractAddressToUserAddressToQtyLocked[marketContractAddress][msg.sender].sub(
            qtyToUnlock
        );  // no need to check balance, sub() will ensure sufficient balance to unlock!
        contractAddressToUserAddressToQtyLocked[marketContractAddress][msg.sender] = balanceAfterUnLock;        // update balance before external call!
        transferLockedTokensBackToUser(qtyToUnlock);
        UpdatedUserLockedBalance(marketContractAddress, msg.sender, balanceAfterUnLock);
    }

    /// @notice get the currently locked balance for a user given the specific contract address
    /// @param marketContractAddress address of the MarketContract
    /// @param userAddress address of the user
    /// @return the locked balance
    function getLockedBalanceForUser(address marketContractAddress, address userAddress) external view returns (uint) {
        return contractAddressToUserAddressToQtyLocked[marketContractAddress][userAddress];
    }

    /*
    // EXTERNAL - ONLY CREATOR  METHODS
    */

    /// @notice allows the creator to set the qty each user address needs to lock in
    /// order to trade a given MarketContract
    /// @param qtyToLock qty needed to enable trading
    function setLockQtyToAllowTrading(uint qtyToLock) external onlyOwner {
        lockQtyToAllowTrading = qtyToLock;
    }

    /// @notice allows the creator to set minimum balance a user must have in order to create MarketContracts
    /// @param minBalance balance to enable contract creation
    function setMinBalanceForContractCreation(uint minBalance) external onlyOwner {
        minBalanceToAllowContractCreation = minBalance;
    }

    /*
    // PRIVATE METHODS
    */

    /// @dev returns locked balance from this contract to the user&#39;s balance
    /// @param qtyToUnlock qty to return to user&#39;s balance
    function transferLockedTokensBackToUser(uint qtyToUnlock) private {
        balances[this] = balances[this].sub(qtyToUnlock);
        balances[msg.sender] = balances[msg.sender].add(qtyToUnlock);
        Transfer(this, msg.sender, qtyToUnlock);
    }
}