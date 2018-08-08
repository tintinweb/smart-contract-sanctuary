pragma solidity ^0.4.17;

/**
 * @title ERC20
 * @dev ERC20 interface
 */
contract ERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/// @dev Crowdsale interface for Etheal Normal Sale, functions needed from outside.
contract iEthealSale {
    bool public paused;
    uint256 public minContribution;
    uint256 public whitelistThreshold;
    mapping (address => uint256) public stakes;
    function setPromoBonus(address _investor, uint256 _value) public;
    function buyTokens(address _beneficiary) public payable;
    function depositEth(address _beneficiary, uint256 _time, bytes _whitelistSign) public payable;
    function depositOffchain(address _beneficiary, uint256 _amount, uint256 _time) public;
    function hasEnded() public constant returns (bool);
}






/**
 * @title claim accidentally sent tokens
 */
contract HasNoTokens is Ownable {
    event ExtractedTokens(address indexed _token, address indexed _claimer, uint _amount);

    /// @notice This method can be used to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    /// @param _claimer Address that tokens will be send to
    function extractTokens(address _token, address _claimer) onlyOwner public {
        if (_token == 0x0) {
            _claimer.transfer(this.balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(_claimer, balance);
        ExtractedTokens(_token, _claimer, balance);
    }
}





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

/*
 * ERC-20 Standard Token Smart Contract Interface.
 * Copyright &#169; 2016–2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2a474341424b4346045c464b4e43474358455c6a4d474b434604494547">[email&#160;protected]</a>>
 */

/**
 * ERC-20 standard token interface, as defined
 * <a href="http://github.com/ethereum/EIPs/issues/20">here</a>.
 */
contract Token {
    /**
     * Get total number of tokens in circulation.
     *
     * @return total number of tokens in circulation
     */
    function totalSupply () view returns (uint256 supply);

    /**
     * Get number of tokens currently belonging to given owner.
     *
     * @param _owner address to get number of tokens currently belonging to the
     *        owner of
     * @return number of tokens currently belonging to the owner of given address
     */
    function balanceOf (address _owner) view returns (uint256 balance);

    /**
     * Transfer given number of tokens from message sender to given recipient.
     *
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer to the owner of given address
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transfer (address _to, uint256 _value) returns (bool success);

    /**
     * Transfer given number of tokens from given owner to given recipient.
     *
     * @param _from address to transfer tokens from the owner of
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer from given owner to given
     *        recipient
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transferFrom (address _from, address _to, uint256 _value) returns (bool success);

    /**
     * Allow given spender to transfer given number of tokens from message sender.
     *
     * @param _spender address to allow the owner of to transfer tokens from
     *        message sender
     * @param _value number of tokens to allow to transfer
     * @return true if token transfer was successfully approved, false otherwise
     */
    function approve (address _spender, uint256 _value) returns (bool success);

    /**
     * Tell how many tokens given spender is currently allowed to transfer from
     * given owner.
     *
     * @param _owner address to get number of tokens allowed to be transferred
     *        from the owner of
     * @param _spender address to get number of tokens allowed to be transferred
     *        by the owner of
     * @return number of tokens given spender is currently allowed to transfer
     *         from given owner
     */
    function allowance (address _owner, address _spender) view returns (uint256 remaining);

    /**
     * Logged when tokens were transferred from one owner to another.
     *
     * @param _from address of the owner, tokens were transferred from
     * @param _to address of the owner, tokens were transferred to
     * @param _value number of tokens transferred
     */
    event Transfer (address indexed _from, address indexed _to, uint256 _value);

    /**
     * Logged when owner approved his tokens to be transferred by some spender.
     *
     * @param _owner owner who approved his tokens to be transferred
     * @param _spender spender who were allowed to transfer the tokens belonging
     *        to the owner
     * @param _value number of tokens belonging to the owner, approved to be
     *        transferred by the spender
     */
    event Approval (address indexed _owner, address indexed _spender, uint256 _value);
}

/*
 * Abstract Token Smart Contract.  Copyright &#169; 2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fa979391929b9396d48c969b9e93979388958cba9d979b9396d4999597">[email&#160;protected]</a>>
 * Modified to use SafeMath library by thesved
 */
/**
 * Abstract Token Smart Contract that could be used as a base contract for
 * ERC-20 token contracts.
 */
contract AbstractToken is Token {
    using SafeMath for uint;

    /**
     * Create new Abstract Token contract.
     */
    function AbstractToken () {
        // Do nothing
    }

    /**
     * Get number of tokens currently belonging to given owner.
     *
     * @param _owner address to get number of tokens currently belonging to the owner
     * @return number of tokens currently belonging to the owner of given address
     */
    function balanceOf (address _owner) view returns (uint256 balance) {
        return accounts[_owner];
    }

    /**
     * Transfer given number of tokens from message sender to given recipient.
     *
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer to the owner of given address
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transfer (address _to, uint256 _value) returns (bool success) {
        uint256 fromBalance = accounts[msg.sender];
        if (fromBalance < _value) return false;
        if (_value > 0 && msg.sender != _to) {
            accounts[msg.sender] = fromBalance.sub(_value);
            accounts[_to] = accounts[_to].add(_value);
            Transfer(msg.sender, _to, _value);
        }
        return true;
    }

    /**
     * Transfer given number of tokens from given owner to given recipient.
     *
     * @param _from address to transfer tokens from the owner of
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer from given owner to given recipient
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transferFrom (address _from, address _to, uint256 _value) returns (bool success) {
        uint256 spenderAllowance = allowances[_from][msg.sender];
        if (spenderAllowance < _value) return false;
        uint256 fromBalance = accounts[_from];
        if (fromBalance < _value) return false;

        allowances[_from][msg.sender] = spenderAllowance.sub(_value);

        if (_value > 0 && _from != _to) {
            accounts[_from] = fromBalance.sub(_value);
            accounts[_to] = accounts[_to].add(_value);
            Transfer(_from, _to, _value);
        }
        return true;
    }

    /**
     * Allow given spender to transfer given number of tokens from message sender.
     *
     * @param _spender address to allow the owner of to transfer tokens from
     *        message sender
     * @param _value number of tokens to allow to transfer
     * @return true if token transfer was successfully approved, false otherwise
     */
    function approve (address _spender, uint256 _value) returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * Tell how many tokens given spender is currently allowed to transfer from
     * given owner.
     *
     * @param _owner address to get number of tokens allowed to be transferred from the owner
     * @param _spender address to get number of tokens allowed to be transferred by the owner
     * @return number of tokens given spender is currently allowed to transfer from given owner
     */
    function allowance (address _owner, address _spender) view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    /**
     * Mapping from addresses of token holders to the numbers of tokens belonging
     * to these token holders.
     */
    mapping (address => uint256) accounts;

    /**
     * Mapping from addresses of token holders to the mapping of addresses of
     * spenders to the allowances set by these token holders to these spenders.
     */
    mapping (address => mapping (address => uint256)) private allowances;
}


/*
 * Abstract Virtual Token Smart Contract.  Copyright &#169; 2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cda0a4a6a5aca4a1e3bba1aca9a4a0a4bfa2bb8daaa0aca4a1e3aea2a0">[email&#160;protected]</a>>
 * Modified to use SafeMath library by thesved
 */

/**
 * Abstract Token Smart Contract that could be used as a base contract for
 * ERC-20 token contracts supporting virtual balance.
 */
contract AbstractVirtualToken is AbstractToken {
    using SafeMath for uint;

    /**
     * Maximum number of real (i.e. non-virtual) tokens in circulation (2^255-1).
     */
    uint256 constant MAXIMUM_TOKENS_COUNT = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Mask used to extract real balance of an account (2^255-1).
     */
    uint256 constant BALANCE_MASK = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Mask used to extract "materialized" flag of an account (2^255).
     */
    uint256 constant MATERIALIZED_FLAG_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;

    /**
     * Create new Abstract Virtual Token contract.
     */
    function AbstractVirtualToken () {
        // Do nothing
    }

    /**
     * Get total number of tokens in circulation.
     *
     * @return total number of tokens in circulation
     */
    function totalSupply () view returns (uint256 supply) {
        return tokensCount;
    }

    /**
     * Get number of tokens currently belonging to given owner.
     *
     * @param _owner address to get number of tokens currently belonging to the owner
     * @return number of tokens currently belonging to the owner of given address
    */
    function balanceOf (address _owner) constant returns (uint256 balance) { 
        return (accounts[_owner] & BALANCE_MASK).add(getVirtualBalance(_owner));
    }

    /**
     * Transfer given number of tokens from message sender to given recipient.
     *
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer to the owner of given address
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transfer (address _to, uint256 _value) returns (bool success) {
        if (_value > balanceOf(msg.sender)) return false;
        else {
            materializeBalanceIfNeeded(msg.sender, _value);
            return AbstractToken.transfer(_to, _value);
        }
    }

    /**
     * Transfer given number of tokens from given owner to given recipient.
     *
     * @param _from address to transfer tokens from the owner of
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer from given owner to given
     *        recipient
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transferFrom (address _from, address _to, uint256 _value) returns (bool success) {
        if (_value > allowance(_from, msg.sender)) return false;
        if (_value > balanceOf(_from)) return false;
        else {
            materializeBalanceIfNeeded(_from, _value);
            return AbstractToken.transferFrom(_from, _to, _value);
        }
    }

    /**
     * Get virtual balance of the owner of given address.
     *
     * @param _owner address to get virtual balance for the owner of
     * @return virtual balance of the owner of given address
     */
    function virtualBalanceOf (address _owner) internal view returns (uint256 _virtualBalance);

    /**
     * Calculate virtual balance of the owner of given address taking into account
     * materialized flag and total number of real tokens already in circulation.
     */
    function getVirtualBalance (address _owner) private view returns (uint256 _virtualBalance) {
        if (accounts [_owner] & MATERIALIZED_FLAG_MASK != 0) return 0;
        else {
            _virtualBalance = virtualBalanceOf(_owner);
            uint256 maxVirtualBalance = MAXIMUM_TOKENS_COUNT.sub(tokensCount);
            if (_virtualBalance > maxVirtualBalance)
                _virtualBalance = maxVirtualBalance;
        }
    }

    /**
     * Materialize virtual balance of the owner of given address if this will help
     * to transfer given number of tokens from it.
     *
     * @param _owner address to materialize virtual balance of
     * @param _value number of tokens to be transferred
     */
    function materializeBalanceIfNeeded (address _owner, uint256 _value) private {
        uint256 storedBalance = accounts[_owner];
        if (storedBalance & MATERIALIZED_FLAG_MASK == 0) {
            // Virtual balance is not materialized yet
            if (_value > storedBalance) {
                // Real balance is not enough
                uint256 virtualBalance = getVirtualBalance(_owner);
                require (_value.sub(storedBalance) <= virtualBalance);
                accounts[_owner] = MATERIALIZED_FLAG_MASK | storedBalance.add(virtualBalance);
                tokensCount = tokensCount.add(virtualBalance);
            }
        }
    }

    /**
    * Number of real (i.e. non-virtual) tokens in circulation.
    */
    uint256 tokensCount;
}


/**
 * Etheal Promo ERC-20 contract
 * Author: thesved
 */
contract EthealPromoToken is HasNoTokens, AbstractVirtualToken {
    // Balance threshold to assign virtual tokens to the owner of higher balances then this threshold.
    uint256 private constant VIRTUAL_THRESHOLD = 0.1 ether;

    // Number of virtual tokens to assign to the owners of balances higher than virtual threshold.
    uint256 private constant VIRTUAL_COUNT = 911;

    // crowdsale to set bonus when sending token
    iEthealSale public crowdsale;

    // logging promo token activation
    event LogBonusSet(address indexed _address, uint256 _amount);

    ////////////////
    // Basic functions
    ////////////////

    /// @dev Constructor, crowdsale address can be 0x0
    function EthealPromoToken(address _crowdsale) {
        crowdsale = iEthealSale(_crowdsale);
    }

    /// @dev Setting crowdsale, crowdsale address can be 0x0
    function setCrowdsale(address _crowdsale) public onlyOwner {
        crowdsale = iEthealSale(_crowdsale);
    }

    /// @notice Get virtual balance of the owner of given address.
    /// @param _owner address to get virtual balance for the owner
    /// @return virtual balance of the owner of given address
    function virtualBalanceOf(address _owner) internal view returns (uint256) {
        return _owner.balance >= VIRTUAL_THRESHOLD ? VIRTUAL_COUNT : 0;
    }

    /// @notice Get name of this token.
    function name() public pure returns (string result) {
        return "An Etheal Promo";
    }

    /// @notice Get symbol of this token.
    function symbol() public pure returns (string result) {
        return "HEALP";
    }

    /// @notice Get number of decimals for this token.
    function decimals() public pure returns (uint8 result) {
        return 0;
    }


    ////////////////
    // Set sale bonus
    ////////////////

    /// @dev Internal function for setting sale bonus
    function setSaleBonus(address _from, address _to, uint256 _value) internal {
        if (address(crowdsale) == address(0)) return;
        if (_value == 0) return;

        if (_to == address(1) || _to == address(this) || _to == address(crowdsale)) {
            crowdsale.setPromoBonus(_from, _value);
            LogBonusSet(_from, _value);
        }
    }

    /// @dev Override transfer function to set sale bonus
    function transfer(address _to, uint256 _value) public returns (bool) {
        bool success = super.transfer(_to, _value); 

        if (success) {
            setSaleBonus(msg.sender, _to, _value);
        }

        return success;
    }

    /// @dev Override transfer function to set sale bonus
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        bool success = super.transferFrom(_from, _to, _value);

        if (success) {
            setSaleBonus(_from, _to, _value);
        }

        return success;
    }


    ////////////////
    // Extra
    ////////////////

    /// @notice Notify owners about their virtual balances.
    function massNotify(address[] _owners) public onlyOwner {
        for (uint256 i = 0; i < _owners.length; i++) {
            Transfer(address(0), _owners[i], VIRTUAL_COUNT);
        }
    }

    /// @notice Kill this smart contract.
    function kill() public onlyOwner {
        selfdestruct(owner);
    }

    
}