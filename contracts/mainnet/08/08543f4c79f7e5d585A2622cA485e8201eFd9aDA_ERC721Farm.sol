// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@solidstate/contracts/token/ERC721/IERC721.sol';
import '@solidstate/contracts/token/ERC721/IERC721Receiver.sol';
import '@solidstate/contracts/utils/EnumerableSet.sol';

import '../token/IMagic.sol';

contract ERC721Farm is IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    address private immutable MAGIC;
    address private immutable ERC721_CONTRACT;
    uint256 public immutable EXPIRATION;
    uint256 private immutable RATE;

    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;

    constructor(
        address magic,
        address erc721,
        uint256 rate,
        uint256 expiration
    ) {
        MAGIC = magic;
        ERC721_CONTRACT = erc721;
        RATE = rate;
        EXPIRATION = block.number + expiration;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            rewards[i] =
                RATE *
                (_deposits[account].contains(tokenId) ? 1 : 0) *
                (Math.min(block.number, EXPIRATION) -
                    depositBlocks[account][tokenId]);
        }
    }

    function claimRewards(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256 block = Math.min(block.number, EXPIRATION);

        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            reward += rewards[i];
            depositBlocks[msg.sender][tokenIds[i]] = block;
        }

        if (reward > 0) {
            IMagic(MAGIC).mint(msg.sender, reward);
        }
    }

    function deposit(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(ERC721_CONTRACT).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );

            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    function withdraw(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                'ERC721Farm: token not deposited'
            );

            _deposits[msg.sender].remove(tokenIds[i]);

            IERC721(ERC721_CONTRACT).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC165} from '../../introspection/IERC165.sol';
import {IERC721Internal} from './IERC721Internal.sol';

/**
 * @notice ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
  /**
   * @notice query the balance of given address
   * @return balance quantity of tokens held
   */
  function balanceOf (
    address account
  ) external view returns (uint256 balance);

  /**
   * @notice query the owner of given token
   * @param tokenId token to query
   * @return owner token owner
   */
  function ownerOf (
    uint256 tokenId
  ) external view returns (address owner);

  /**
   * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
   * @param from sender of token
   * @param to receiver of token
   * @param tokenId token id
   */
  function safeTransferFrom (
    address from,
    address to,
    uint256 tokenId
  ) external payable;

  /**
   * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
   * @param from sender of token
   * @param to receiver of token
   * @param tokenId token id
   * @param data data payload
   */
  function safeTransferFrom (
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external payable;

  /**
   * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
   * @param from sender of token
   * @param to receiver of token
   * @param tokenId token id
   */
  function transferFrom (
    address from,
    address to,
    uint256 tokenId
  ) external payable;

  /**
   * @notice grant approval to given account to spend token
   * @param operator address to be approved
   * @param tokenId token to approve
   */
  function approve (
    address operator,
    uint256 tokenId
  ) external payable;

  /**
   * @notice get approval status for given token
   * @param tokenId token to query
   * @return operator address approved to spend token
   */
  function getApproved (
    uint256 tokenId
  ) external view returns (address operator);

  /**
   * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
   * @param operator address to be approved
   * @param status approval status
   */
  function setApprovalForAll (
    address operator,
    bool status
  ) external;

  /**
   * @notice query approval status of given operator with respect to given address
   * @param account address to query for approval granted
   * @param operator address to query for approval received
   * @return status whether operator is approved to spend tokens held by account
   */
  function isApprovedForAll (
    address account,
    address operator
  ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {
  function onERC721Received (
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
  struct Set {
    bytes32[] _values;
    // 1-indexed to allow 0 to signify nonexistence
    mapping (bytes32 => uint) _indexes;
  }

  struct Bytes32Set {
    Set _inner;
  }

  struct AddressSet {
    Set _inner;
  }

  struct UintSet {
    Set _inner;
  }

  function at (
    Bytes32Set storage set,
    uint index
  ) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  function at (
    AddressSet storage set,
    uint index
  ) internal view returns (address) {
    return address(uint160(uint(_at(set._inner, index))));
  }

  function at (
    UintSet storage set,
    uint index
  ) internal view returns (uint) {
    return uint(_at(set._inner, index));
  }

  function contains (
    Bytes32Set storage set,
    bytes32 value
  ) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  function contains (
    AddressSet storage set,
    address value
  ) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint(uint160(value))));
  }

  function contains (
    UintSet storage set,
    uint value
  ) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  function indexOf (
    Bytes32Set storage set,
    bytes32 value
  ) internal view returns (uint) {
    return _indexOf(set._inner, value);
  }

  function indexOf (
    AddressSet storage set,
    address value
  ) internal view returns (uint) {
    return _indexOf(set._inner, bytes32(uint(uint160(value))));
  }

  function indexOf (
    UintSet storage set,
    uint value
  ) internal view returns (uint) {
    return _indexOf(set._inner, bytes32(value));
  }

  function length (
    Bytes32Set storage set
  ) internal view returns (uint) {
    return _length(set._inner);
  }

  function length (
    AddressSet storage set
  ) internal view returns (uint) {
    return _length(set._inner);
  }

  function length (
    UintSet storage set
  ) internal view returns (uint) {
    return _length(set._inner);
  }

  function add (
    Bytes32Set storage set,
    bytes32 value
  ) internal returns (bool) {
    return _add(set._inner, value);
  }

  function add (
    AddressSet storage set,
    address value
  ) internal returns (bool) {
    return _add(set._inner, bytes32(uint(uint160(value))));
  }

  function add (
    UintSet storage set,
    uint value
  ) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  function remove (
    Bytes32Set storage set,
    bytes32 value
  ) internal returns (bool) {
    return _remove(set._inner, value);
  }

  function remove (
    AddressSet storage set,
    address value
  ) internal returns (bool) {
    return _remove(set._inner, bytes32(uint(uint160(value))));
  }

  function remove (
    UintSet storage set,
    uint value
  ) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  function _at (
    Set storage set,
    uint index
  ) private view returns (bytes32) {
    require(set._values.length > index, 'EnumerableSet: index out of bounds');
    return set._values[index];
  }

  function _contains (
    Set storage set,
    bytes32 value
  ) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  function _indexOf (
    Set storage set,
    bytes32 value
  ) private view returns (uint) {
    unchecked {
      return set._indexes[value] - 1;
    }
  }

  function _length (
    Set storage set
  ) private view returns (uint) {
    return set._values.length;
  }

  function _add (
    Set storage set,
    bytes32 value
  ) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove (
    Set storage set,
    bytes32 value
  ) private returns (bool) {
    uint valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      uint index = valueIndex - 1;
      bytes32 last = set._values[set._values.length - 1];

      // move last value to now-vacant index

      set._values[index] = last;
      set._indexes[last] = index + 1;

      // clear last index

      set._values.pop();
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@solidstate/contracts/token/ERC20/IERC20.sol';

interface IMagic is IERC20 {
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
  /**
   * @notice query whether contract has registered support for given interface
   * @param interfaceId interface id
   * @return bool whether interface is supported
   */
  function supportsInterface (
    bytes4 interfaceId
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
  event Transfer (
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  event Approval (
    address indexed owner,
    address indexed operator,
    uint256 indexed tokenId
  );

  event ApprovalForAll (
    address indexed owner,
    address indexed operator,
    bool approved
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20Internal} from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
  /**
   * @notice query the total minted token supply
   * @return token supply
   */
  function totalSupply () external view returns (uint256);

  /**
   * @notice query the token balance of given account
   * @param account address to query
   * @return token balance
   */
  function balanceOf (
    address account
  ) external view returns (uint256);

  /**
   * @notice query the allowance granted from given holder to given spender
   * @param holder approver of allowance
   * @param spender recipient of allowance
   * @return token allowance
   */
  function allowance (
    address holder,
    address spender
  ) external view returns (uint256);

  /**
   * @notice grant approval to spender to spend tokens
   * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
   * @param spender recipient of allowance
   * @param amount quantity of tokens approved for spending
   * @return success status (always true; otherwise function should revert)
   */
  function approve (
    address spender,
    uint256 amount
  ) external returns (bool);

  /**
   * @notice transfer tokens to given recipient
   * @param recipient beneficiary of token transfer
   * @param amount quantity of tokens to transfer
   * @return success status (always true; otherwise function should revert)
   */
  function transfer (
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @notice transfer tokens to given recipient on behalf of given holder
   * @param holder holder of tokens prior to transfer
   * @param recipient beneficiary of token transfer
   * @param amount quantity of tokens to transfer
   * @return success status (always true; otherwise function should revert)
   */
  function transferFrom (
    address holder,
    address recipient,
    uint256 amount
  ) external returns (bool);
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

