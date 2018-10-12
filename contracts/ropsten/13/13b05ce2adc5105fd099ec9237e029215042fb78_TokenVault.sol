/* file: ./node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol */
pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

/* eof (./node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol) */
/* file: ./node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol */
pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/* eof (./node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol) */
/* file: ./node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol */
pragma solidity ^0.4.24;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/* eof (./node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol) */
/* file: ./node_modules/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol */
pragma solidity ^0.4.24;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

/* eof (./node_modules/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol) */
/* file: ./contracts/vault/TokenVault.sol */
/**
 * @title Token Vault contract.
 * @version 1.0
 * @author Validity Labs AG <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="50393e363f1026313c39343924293c3132237e3f2237">[email&#160;protected]</a>>
 */

pragma solidity ^0.4.24;  // solhint-disable-line



contract TokenVault {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    ERC20 public token;
    uint256 public releaseTime;

    mapping(address => uint256) public lockedBalances;

    /**
     * @param _token Address of the MioToken to be held.
     * @param _releaseTime Epoch timestamp from which token release is enabled.
     */
    constructor(address _token, uint256 _releaseTime) public {
        require(block.timestamp < _releaseTime);
        token = ERC20(_token);
        releaseTime = _releaseTime;
    }

    /**
     * @dev Allows the transfer of unlocked tokens to a set of beneficiaries&#39; addresses.
     * @param beneficiaries Array of beneficiaries&#39; addresses that will receive the unlocked tokens.
     */
    function batchRelease(address[] beneficiaries) external {
        uint256 length = beneficiaries.length;
        for (uint256 i = 0; i < length; i++) {
            releaseFor(beneficiaries[i]);
        }
    }

    /**
     * @dev Allows the caller to transfer unlocked tokens his/her account.
     */
    function release() public {
        releaseFor(msg.sender);
    }

    /**
     * @dev Allows the caller to transfer unlocked tokens to the beneficiary&#39;s address.
     * @param beneficiary The address that will receive the unlocked tokens.
     */
    function releaseFor(address beneficiary) public {
        require(block.timestamp >= releaseTime);
        uint256 amount = lockedBalances[beneficiary];
        require(amount > 0);
        lockedBalances[beneficiary] = 0;
        token.safeTransfer(beneficiary, amount);
    }

    /**
     * @dev Allows a token holder to add to his/her balance of locked tokens.
     * @param value Amount of tokens to be locked in this vault.
     */
    function addBalance(uint256 value) public {
        addBalanceFor(msg.sender, value);
    }

    /**
     * @notice To be called by the account that holds Mio tokens. The caller needs to first approve this vault to
     * transfer tokens on its behalf.
     * The tokens to be locked will be transfered from the caller&#39;s account to this vault.
     * The &#39;value&#39; will be added to the balance of &#39;account&#39; in this contract.
     * @dev Allows a token holder to add to a another account&#39;s balance of locked tokens.
     * @param account Address that will have a balance of locked tokens.
     * @param value Amount of tokens to be locked in this vault.
     */
    function addBalanceFor(address account, uint256 value) public {
        lockedBalances[account] = lockedBalances[account].add(value);
        token.safeTransferFrom(msg.sender, address(this), value);
    }

     /**
    * @dev Gets the beneficiary&#39;s locked token balance
    * @param account Address of the beneficiary
    */
    function getLockedBalance(address account) public view returns (uint256) {
        return lockedBalances[account];
    }
}



/* eof (./contracts/vault/TokenVault.sol) */