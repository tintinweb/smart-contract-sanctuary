// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Bytes library
 *
 * @author Stanisław Głogowski <[email protected]>
 */
library BytesLib {
  /**
   * @notice Converts bytes to address
   * @param data data
   * @return address
   */
  function toAddress(
    bytes memory data
  )
    internal
    pure
    returns (address)
  {
    address result;

    require(
      data.length == 20,
      "BytesLib: invalid data length"
    );

    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := div(mload(add(data, 0x20)), 0x1000000000000000000000000)
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Safe math library
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/math/SafeMath.sol
 */
library SafeMathLib {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;

    require(c >= a, "SafeMathLib: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMathLib: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);

    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;

    require(c / a == b, "SafeMathLib: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMathLib: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);

    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMathLib: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);

    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Initializable
 *
 * @dev Contract module which provides access control mechanism, where
 * there is the initializer account that can be granted exclusive access to
 * specific functions.
 *
 * The initializer account will be tx.origin during contract deployment and will be removed on first use.
 * Use `onlyInitializer` modifier on contract initialize process.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Initializable {
  address private initializer;

  // events

  /**
   * @dev Emitted after `onlyInitializer`
   * @param initializer initializer address
   */
  event Initialized(
    address initializer
  );

  // modifiers

  /**
   * @dev Throws if tx.origin is not the initializer
   */
  modifier onlyInitializer() {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin == initializer,
      "Initializable: tx.origin is not the initializer"
    );

    /// @dev removes initializer
    initializer = address(0);

    _;

    emit Initialized(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin
    );
  }

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    // solhint-disable-next-line avoid-tx-origin
    initializer = tx.origin;
  }

   // external functions (views)

  /**
   * @notice Check if contract is initialized
   * @return true when contract is initialized
   */
  function isInitialized()
    external
    view
    returns (bool)
  {
    return initializer == address(0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../libs/SafeMathLib.sol";


/**
 * @title ERC20 token
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/ERC20.sol
 */
contract ERC20Token {
  using SafeMathLib for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping(address => uint256) internal balances;
  mapping(address => mapping(address => uint256)) internal allowances;

  // events

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  /**
   * @dev internal constructor
   */
  constructor() internal {}

  // external functions

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (bool)
  {
    _transfer(_getSender(), to, value);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    virtual
    external
    returns (bool)
  {
    address sender = _getSender();

    _transfer(from, to, value);
    _approve(from, sender, allowances[from][sender].sub(value));

    return true;
  }

  function approve(
    address spender,
    uint256 value
  )
    virtual
    external
    returns (bool)
  {
    _approve(_getSender(), spender, value);

    return true;
  }

  // external functions (views)

  function balanceOf(
    address owner
  )
    virtual
    external
    view
    returns (uint256)
  {
    return balances[owner];
  }

  function allowance(
    address owner,
    address spender
  )
    virtual
    external
    view
    returns (uint256)
  {
    return allowances[owner][spender];
  }

  // internal functions

  function _transfer(
    address from,
    address to,
    uint256 value
  )
    virtual
    internal
  {
    require(
      from != address(0),
      "ERC20Token: cannot transfer from 0x0 address"
    );
    require(
      to != address(0),
      "ERC20Token: cannot transfer to 0x0 address"
    );

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);

    emit Transfer(from, to, value);
  }

  function _approve(
    address owner,
    address spender,
    uint256 value
  )
    virtual
    internal
  {
    require(
      owner != address(0),
      "ERC20Token: cannot approve from 0x0 address"
    );
    require(
      spender != address(0),
      "ERC20Token: cannot approve to 0x0 address"
    );

    allowances[owner][spender] = value;

    emit Approval(owner, spender, value);
  }

  function _mint(
    address owner,
    uint256 value
  )
    virtual
    internal
  {
    require(
      owner != address(0),
      "ERC20Token: cannot mint to 0x0 address"
    );
    require(
      value > 0,
      "ERC20Token: cannot mint 0 value"
    );

    balances[owner] = balances[owner].add(value);
    totalSupply = totalSupply.add(value);

    emit Transfer(address(0), owner, value);
  }

  function _burn(
    address owner,
    uint256 value
  )
    virtual
    internal
  {
    require(
      owner != address(0),
      "ERC20Token: cannot burn from 0x0 address"
    );

    balances[owner] = balances[owner].sub(
      value,
      "ERC20Token: burn value exceeds balance"
    );

    totalSupply = totalSupply.sub(value);

    emit Transfer(owner, address(0), value);
  }

  // internal functions (views)

  function _getSender()
    virtual
    internal
    view
    returns (address)
  {
    return msg.sender;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../common/libs/BytesLib.sol";


/**
 * @title Gateway recipient
 *
 * @notice Gateway target contract
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract GatewayRecipient {
  using BytesLib for bytes;

  address public gateway;

  /**
   * @dev internal constructor
   */
  constructor() internal {}

  // internal functions

  /**
   * @notice Initializes `GatewayRecipient` contract
   * @param gateway_ `Gateway` contract address
   */
  function _initializeGatewayRecipient(
    address gateway_
  )
    internal
  {
    gateway = gateway_;
  }

  // internal functions (views)

  /**
   * @notice Gets gateway context account
   * @return context account address
   */
  function _getContextAccount()
    internal
    view
    returns (address)
  {
    return _getContextAddress(40);
  }

  /**
   * @notice Gets gateway context sender
   * @return context sender address
   */
  function _getContextSender()
    internal
    view
    returns (address)
  {
    return _getContextAddress(20);
  }

  /**
   * @notice Gets gateway context data
   * @return context data
   */
  function _getContextData()
    internal
    view
    returns (bytes calldata)
  {
    bytes calldata result;

    if (_isGatewaySender()) {
      result = msg.data[:msg.data.length - 40];
    } else {
      result = msg.data;
    }

    return result;
  }

  // private functions (views)

  function _getContextAddress(
    uint256 offset
  )
    private
    view
    returns (address)
  {
    address result = address(0);

    if (_isGatewaySender()) {
      uint from = msg.data.length - offset;
      result = bytes(msg.data[from:from + 20]).toAddress();
    } else {
      result = msg.sender;
    }

    return result;
  }

  function _isGatewaySender()
    private
    view
    returns (bool)
  {
    bool result;

    if (msg.sender == gateway) {
      require(
        msg.data.length >= 44,
        "GatewayRecipient: invalid msg.data"
      );

      result = true;
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../common/lifecycle/Initializable.sol";
import "../common/token/ERC20Token.sol";
import "../gateway/GatewayRecipient.sol";


/**
 * @title Wrapped wei token
 *
 * @notice One to one wei consumable ERC20 token
 *
 * @dev After the transfer to consumer's account is done, the token will be automatically burned and withdrawn.
 *
 * Use `startConsuming` to become a consumer.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract WrappedWeiToken is Initializable, ERC20Token, GatewayRecipient {
  mapping(address => bool) private consumers;

  // events

  /**
   * @dev Emitted when the new consumer is added
   * @param consumer consumer address
   */
  event ConsumerAdded(
    address consumer
  );

  /**
   * @dev Emitted when the existing consumer is removed
   * @param consumer consumer address
   */
  event ConsumerRemoved(
    address consumer
  );

  /**
   * @dev Public constructor
   */
  constructor()
    public
    Initializable()
  {
    name = "Wrapped Wei";
    symbol = "WWEI";
  }

  /**
   * @notice Receive fallback
   */
  receive()
    external
    payable
  {
    _mint(_getSender(), msg.value);
  }

  // external functions

  /**
   * @notice Initializes `WrappedWeiToken` contract
   * @param consumers_ array of consumers addresses
   * @param gateway_ `Gateway` contract address
   */
  function initialize(
    address[] calldata consumers_,
    address gateway_
  )
    external
    onlyInitializer
  {
    if (consumers_.length != 0) {
      uint consumersLen = consumers_.length;
      for (uint i = 0; i < consumersLen; i++) {
        _addConsumer(consumers_[i]);
      }
    }

    _initializeGatewayRecipient(gateway_);
  }

  /**
   * @notice Starts consuming
   * @dev Add caller as a consumer
   */
  function startConsuming()
    external
  {
    _addConsumer(_getSender());
  }

  /**
   * @notice Stops consuming
   * @dev Remove caller from consumers
   */
  function stopConsuming()
    external
  {
    address consumer = _getSender();

    require(
      consumers[consumer],
      "WrappedWeiToken: consumer doesn't exist"
    );

    consumers[consumer] = false;

    emit ConsumerRemoved(consumer);
  }

  /**
   * @notice Deposits `msg.value` to address
   * @param to to address
   */
  function depositTo(
    address to
  )
    external
    payable
  {
    _mint(to, msg.value);
  }

  /**
   * @notice Withdraws
   * @param value value to withdraw
   */
  function withdraw(
    uint256 value
  )
    external
  {
    _withdraw(_getSender(), _getSender(), value);
  }

  /**
   * @notice Withdraws to address
   * @param to to address
   * @param value value to withdraw
   */
  function withdrawTo(
    address to,
    uint256 value
  )
    external
  {
    _withdraw(_getSender(), to, value);
  }

  /**
   * @notice Withdraws all
   */
  function withdrawAll()
    external
  {
    address sender = _getSender();

    _withdraw(sender, sender, balances[sender]);
  }

  /**
   * @notice Withdraws all to address
   * @param to to address
   */
  function withdrawAllTo(
    address to
  )
    external
  {
    address sender = _getSender();

    _withdraw(sender, to, balances[sender]);
  }

  // external functions (views)

  /**
   * @notice Checks if consumer exists
   * @param consumer consumer address
   * @return true if consumer exists
   */
  function isConsumer(
    address consumer
  )
    external
    view
    returns (bool)
  {
    return consumers[consumer];
  }

  // internal functions

  function _transfer(
    address from,
    address to,
    uint256 value
  )
    override
    internal
  {
    if (consumers[to]) {
      _withdraw(from, to, value);
    } else {
      super._transfer(from, to, value);
    }
  }

  // internal functions (views)

  function _getSender()
    override
    internal
    view
    returns (address)
  {
    return _getContextAccount();
  }

  // private functions

  function _addConsumer(
    address consumer
  )
    private
  {
    require(
      !consumers[consumer],
      "WrappedWeiToken: consumer already exists"
    );

    consumers[consumer] = true;

    emit ConsumerAdded(consumer);
  }

  function _withdraw(
    address from,
    address to,
    uint256 value
  )
    private
  {
    _burn(from, value);

    require(
      // solhint-disable-next-line check-send-result
      payable(to).send(value),
      "WrappedWeiToken: transaction reverted"
    );
  }
}