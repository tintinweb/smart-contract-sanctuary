// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import '@solidstate/contracts/contracts/token/ERC20/ERC20.sol';
import '@solidstate/contracts/contracts/token/ERC20/ERC20MetadataStorage.sol';

import './AutoRewardTokenStorage.sol';

/**
 * @title Fee-on-transfer token with frictionless distribution to holders
 * @author Nick Barry
 */
contract AutoRewardToken is ERC20 {
  using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

  uint private constant BP_DIVISOR = 10000;
  uint private constant REWARD_SCALAR = 1e36;

  address private constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;

  constructor (
    string memory name,
    string memory symbol,
    uint supply,
    uint fee
  ) {
    require(fee <= BP_DIVISOR, 'AutoRewardToken: fee must not exceed 10000 bp');

    {
      ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();
      l.setName(name);
      l.setSymbol(symbol);
      l.setDecimals(18);
    }

    AutoRewardTokenStorage.layout().fee = fee;

    _mint(msg.sender, supply);
  }

  /**
   * @notice return network fee
   * @return fee in basis points
   */
  function getFee () external view returns (uint) {
    return AutoRewardTokenStorage.layout().fee;
  }

  /**
   * @inheritdoc ERC20Base
   */
  function balanceOf (
    address account
  ) override public view returns (uint) {
    return super.balanceOf(account) + rewardsOf(account);
  }

  /**
   * @notice get pending rewards pending distribution to given account
   * @param account owner of rewards
   * @return quantity of rewards
   */
  function rewardsOf (
    address account
  ) public view returns (uint) {
    AutoRewardTokenStorage.Layout storage l = AutoRewardTokenStorage.layout();
    return (
      super.balanceOf(account) * l.cumulativeRewardPerToken
      + l.rewardsReserved[account]
      - l.rewardsExcluded[account]
    ) / REWARD_SCALAR;
  }

  /**
   * @inheritdoc ERC20Base
   * @notice override of _transfer function to include call to _afterTokenTransfer
   */
  function _transfer (
    address sender,
    address recipient,
    uint amount
  ) override internal {
    super._transfer(sender, recipient, amount);
    _afterTokenTransfer(sender, recipient, amount);
  }

  /**
   * @notice ERC20 hook: apply fees and distribute rewards on transfer
   * @inheritdoc ERC20Base
   */
  function _beforeTokenTransfer (
    address from,
    address to,
    uint amount
  ) override internal {
    super._beforeTokenTransfer(from, to, amount);

    if (from == address(0) || to == address(0)) {
      return;
    }

    AutoRewardTokenStorage.Layout storage l = AutoRewardTokenStorage.layout();

    uint fee = amount * l.fee / BP_DIVISOR;

    // update internal balances to include rewards

    uint rewardsFrom = rewardsOf(from);
    ERC20BaseStorage.layout().balances[from] += rewardsFrom;
    delete l.rewardsReserved[from];

    uint rewardsTo = rewardsOf(to);
    ERC20BaseStorage.layout().balances[to] += rewardsTo;
    delete l.rewardsReserved[to];

    // track exclusions from future rewards

    l.rewardsExcluded[from] = (super.balanceOf(from) - amount) * l.cumulativeRewardPerToken;
    l.rewardsExcluded[to] = (super.balanceOf(to) + amount - fee) * l.cumulativeRewardPerToken;

    // distribute rewards globally

    l.cumulativeRewardPerToken += (fee * REWARD_SCALAR) / (totalSupply() - fee);

    // simulate transfers
    emit Transfer(FEE_ADDRESS, from, rewardsFrom);
    emit Transfer(FEE_ADDRESS, to, rewardsTo);
  }

  /**
   * @notice ERC20 hook: remove fee from recipient
   * @param to recipient address
   * @param amount quantity transferred
   */
  function _afterTokenTransfer (
    address,
    address to,
    uint amount
  ) private {
    AutoRewardTokenStorage.Layout storage l = AutoRewardTokenStorage.layout();
    uint fee = amount * l.fee / BP_DIVISOR;
    ERC20BaseStorage.layout().balances[to] -= fee;
    emit Transfer(to, FEE_ADDRESS, fee);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './ERC20Base.sol';
import './ERC20Extended.sol';
import './ERC20Metadata.sol';

abstract contract ERC20 is ERC20Base, ERC20Extended, ERC20Metadata {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library ERC20MetadataStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC20Metadata'
  );

  struct Layout {
    string name;
    string symbol;
    uint8 decimals;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function setName (
    Layout storage l,
    string memory name
  ) internal {
    l.name = name;
  }

  function setSymbol (
    Layout storage l,
    string memory symbol
  ) internal {
    l.symbol = symbol;
  }

  function setDecimals (
    Layout storage l,
    uint8 decimals
  ) internal {
    l.decimals = decimals;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

library AutoRewardTokenStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.AutoRewardToken'
  );

  struct Layout {
    uint fee;
    uint cumulativeRewardPerToken;
    mapping (address => uint) rewardsExcluded;
    mapping (address => uint) rewardsReserved;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

import './IERC20.sol';
import './ERC20BaseStorage.sol';

abstract contract ERC20Base is IERC20 {
  using SafeMath for uint;

  function totalSupply () override virtual public view returns (uint) {
    return ERC20BaseStorage.layout().totalSupply;
  }

  function balanceOf (
    address account
  ) override virtual public view returns (uint) {
    return ERC20BaseStorage.layout().balances[account];
  }

  function allowance (
    address holder,
    address spender
  ) override virtual public view returns (uint) {
    return ERC20BaseStorage.layout().allowances[holder][spender];
  }

  function transfer (
    address recipient,
    uint amount
  ) override virtual public returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom (
    address sender,
    address recipient,
    uint amount
  ) override virtual public returns (bool) {
    _approve(sender, msg.sender, ERC20BaseStorage.layout().allowances[sender][msg.sender].sub(amount, 'ERC20: transfer amount exceeds allowance'));
    _transfer(sender, recipient, amount);
    return true;
  }

  function approve (
    address spender,
    uint amount
  ) override virtual public returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function _mint (
    address account,
    uint amount
  ) virtual internal {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
    l.totalSupply = l.totalSupply.add(amount);
    l.balances[account] = l.balances[account].add(amount);

    emit Transfer(address(0), account, amount);
  }

  function _burn (
    address account,
    uint amount
  ) virtual internal {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
    l.balances[account] = l.balances[account].sub(amount);
    l.totalSupply = l.totalSupply.sub(amount);

    emit Transfer(account, address(0), amount);
  }

  function _transfer (
    address sender,
    address recipient,
    uint amount
  ) virtual internal {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
    l.balances[sender] = l.balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
    l.balances[recipient] = l.balances[recipient].add(amount);

    emit Transfer(sender, recipient, amount);
  }

  function _approve (
    address holder,
    address spender,
    uint amount
  ) virtual internal {
    require(holder != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    ERC20BaseStorage.layout().allowances[holder][spender] = amount;

    emit Approval(holder, spender, amount);
  }

  function _beforeTokenTransfer (
    address from,
    address to,
    uint amount
  ) virtual internal {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

import './ERC20Base.sol';

abstract contract ERC20Extended is ERC20Base {
  using SafeMath for uint;

  function increaseAllowance (address spender, uint amount) virtual public returns (bool) {
    _approve(msg.sender, spender, ERC20BaseStorage.layout().allowances[msg.sender][spender].add(amount));
    return true;
  }

  function decreaseAllowance (address spender, uint amount) virtual public returns (bool) {
    _approve(msg.sender, spender, ERC20BaseStorage.layout().allowances[msg.sender][spender].sub(amount));
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import './ERC20Base.sol';
import './ERC20MetadataStorage.sol';

abstract contract ERC20Metadata is ERC20Base {
  function name () virtual public view returns (string memory) {
    return ERC20MetadataStorage.layout().name;
  }

  function symbol () virtual public view returns (string memory) {
    return ERC20MetadataStorage.layout().symbol;
  }

  function decimals () virtual public view returns (uint8) {
    return ERC20MetadataStorage.layout().decimals;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IERC20 {
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

  function totalSupply () external view returns (uint256);

  function balanceOf (
    address account
  ) external view returns (uint256);

  function transfer (
    address recipient,
    uint256 amount
  ) external returns (bool);

  function allowance (
    address owner,
    address spender
  ) external view returns (uint256);

  function approve (
    address spender,
    uint256 amount
  ) external returns (bool);

  function transferFrom (
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library ERC20BaseStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC20Base'
  );

  struct Layout {
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;
    uint totalSupply;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}