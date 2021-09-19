// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol';
import '@solidstate/contracts/utils/ReentrancyGuard.sol';

import './MagicWhitelistStorage.sol';

contract MagicMintReentrancyFix is ERC20BaseInternal, ReentrancyGuard {
    function mint(address account, uint256 amount) external nonReentrant {
        require(
            MagicWhitelistStorage.layout().whitelist[msg.sender],
            'Magic: sender must be whitelisted'
        );
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20Internal} from '../IERC20Internal.sol';
import {ERC20BaseStorage} from './ERC20BaseStorage.sol';

/**
 * @title Base ERC20 implementation, excluding optional extensions
 */
abstract contract ERC20BaseInternal is IERC20Internal {
  /**
   * @notice query the total minted token supply
   * @return token supply
   */
  function _totalSupply () virtual internal view returns (uint) {
    return ERC20BaseStorage.layout().totalSupply;
  }

  /**
   * @notice query the token balance of given account
   * @param account address to query
   * @return token balance
   */
  function _balanceOf (
    address account
  ) virtual internal view returns (uint) {
    return ERC20BaseStorage.layout().balances[account];
  }

  /**
   * @notice enable spender to spend tokens on behalf of holder
   * @param holder address on whose behalf tokens may be spent
   * @param spender recipient of allowance
   * @param amount quantity of tokens approved for spending
   */
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

  /**
   * @notice mint tokens for given account
   * @param account recipient of minted tokens
   * @param amount quantity of tokens minted
   */
  function _mint (
    address account,
    uint amount
  ) virtual internal {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
    l.totalSupply += amount;
    l.balances[account] += amount;

    emit Transfer(address(0), account, amount);
  }

  /**
   * @notice burn tokens held by given account
   * @param account holder of burned tokens
   * @param amount quantity of tokens burned
   */
  function _burn (
    address account,
    uint amount
  ) virtual internal {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
    uint256 balance = l.balances[account];
    require(balance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      l.balances[account] = balance - amount;
    }
    l.totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  /**
   * @notice transfer tokens from holder to recipient
   * @param holder owner of tokens to be transferred
   * @param recipient beneficiary of transfer
   * @param amount quantity of tokens transferred
   */
  function _transfer (
    address holder,
    address recipient,
    uint amount
  ) virtual internal {
    require(holder != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(holder, recipient, amount);

    ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
    uint256 holderBalance = l.balances[holder];
    require(holderBalance >= amount, 'ERC20: transfer amount exceeds balance');
    unchecked {
      l.balances[holder] = holderBalance - amount;
    }
    l.balances[recipient] += amount;

    emit Transfer(holder, recipient, amount);
  }

  /**
   * @notice ERC20 hook, called before all transfers including mint and burn
   * @dev function should be overridden and new implementation must call super
   * @param from sender of tokens
   * @param to receiver of tokens
   * @param amount quantity of tokens transferred
   */
  function _beforeTokenTransfer (
    address from,
    address to,
    uint amount
  ) virtual internal {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ReentrancyGuardStorage} from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
  modifier nonReentrant () {
    ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage.layout();
    require(l.status != 2, 'ReentrancyGuard: reentrant call');
    l.status = 2;
    _;
    l.status = 1;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library MagicWhitelistStorage {
    struct Layout {
        mapping(address => bool) whitelist;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('treasure.contracts.storage.MagicWhitelist');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20BaseStorage {
  struct Layout {
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;
    uint totalSupply;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC20Base'
  );

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
  struct Layout {
    uint status;
  }

  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ReentrancyGuard'
  );

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}