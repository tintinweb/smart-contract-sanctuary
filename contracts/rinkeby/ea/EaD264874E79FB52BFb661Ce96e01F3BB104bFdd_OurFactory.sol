// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import { OurProxy } from "./OurProxy.sol";

/**
 * @title OurFactory (originally SplitFactory)
 * @author MirrorXYZ https://github.com/mirror-xyz/splits - modified by Nick Adamson for Ourz
 *
 * @notice Modified: store OurMinter.sol address, add events, remove WETHaddress in favor of constant
 */
contract OurFactory {
  //======== Events =========
  event ProxyCreation(address ourProxy);

  //======== Immutable storage =========
  address public immutable splitter;
  address public immutable minter;

  //======== Mutable storage =========
  /// @dev Gets set within the block, and then deleted.
  bytes32 public merkleRoot;

  //======== Constructor =========
  constructor(address splitter_, address minter_) {
    splitter = splitter_;
    minter = minter_;
  }

  //======== Deploy function =========
  function createSplit(bytes32 merkleRoot_) external returns (address ourProxy) {
    merkleRoot = merkleRoot_;
    ourProxy = address(new OurProxy{ salt: keccak256(abi.encode(merkleRoot_)) }());
    delete merkleRoot;
    emit ProxyCreation(ourProxy);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import { OurStorage } from "./OurStorage.sol";

interface IOurFactory {
  function splitter() external returns (address);

  function minter() external returns (address);

  function merkleRoot() external returns (bytes32);
}

/**
 * @title OurProxy (originally SplitProxy)
 * @author MirrorXYZ https://github.com/mirror-xyz/splits - modified by Nick Adamson for Ourz
 *
 * @notice Modified: added OpenZeppelin's Ownable (modified) & IERC721Receiver (inherited)
 */
contract OurProxy is OurStorage {
  /// OZ Ownable.sol
  address private _owner;

  constructor() {
    _splitter = IOurFactory(msg.sender).splitter();
    _minter = IOurFactory(msg.sender).minter();
    merkleRoot = IOurFactory(msg.sender).merkleRoot();

    /**
     * @dev Using tx.origin instead of OurFactory to set owner saves gas and is safe in this context
     * NOTE: Modification of OpenZeppelin Ownable.sol
     */
    _setOwner(tx.origin);

    address(_minter).delegatecall(
      abi.encodeWithSignature("setApprovalsForSplit(address)", owner())
    );
  }

  //======== OZ Ownable =========
  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  /// @notice Transfers ownership of the contract to a new account (`newOwner`).
  function transferOwnership(address newOwner) public {
    require(msg.sender == owner());
    require(newOwner != address(0), "Ownable: new owner is the zero address");

    _setOwner(newOwner);
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public {
    require(msg.sender == owner());
    _setOwner(address(0));
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /// @dev Returns the address of the current owner.
  function owner() public view returns (address) {
    return _owner;
  }

  //======== /Ownable.sol =========

  function minter() public view returns (address) {
    return _minter;
  }

  function splitter() public view returns (address) {
    return _splitter;
  }

  fallback() external payable {
    if (msg.sender == owner()) {
      address _impl = minter();
      assembly {
        let ptr := mload(0x40)
        calldatacopy(ptr, 0, calldatasize())
        let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
        let size := returndatasize()
        returndatacopy(ptr, 0, size)

        switch result
        case 0 {
          revert(ptr, size)
        }
        default {
          return(ptr, size)
        }
      }
    } else {
      address _impl = splitter();
      assembly {
        let ptr := mload(0x40)
        calldatacopy(ptr, 0, calldatasize())
        let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
        let size := returndatasize()
        returndatacopy(ptr, 0, size)

        switch result
        case 0 {
          revert(ptr, size)
        }
        default {
          return(ptr, size)
        }
      }
    }
  }

  // Plain ETH transfers.
  receive() external payable {
    depositedInWindow += msg.value;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title OurStorage (originally SplitStorage)
 * @author MirrorXYZ https://github.com/mirror-xyz/splits - modified by Nick Adamson for Ourz
 *
 * @notice Modified: store addresses as constants, _add minter
 */
contract OurStorage {
  bytes32 public merkleRoot;
  uint256 public currentWindow;

  // RINKEBY!
  address public constant wethAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  // address public constant _zoraMedia =
  //     0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4;
  // address public constant _zoraMarket =
  //     0x85e946e1Bd35EC91044Dc83A5DdAB2B6A262ffA6;
  // address public constant _zoraAuctionHouse =
  //     0xE7dd1252f50B3d845590Da0c5eADd985049a03ce;
  // address public constant _mirrorAH =
  //     0x2D5c022fd4F81323bbD1Cc0Ec6959EC8CC1C5A11;
  // address public constant _mirrorCrowdfundFactory =
  //     0xeac226B370D77f436b5780b4DD4A49E59e8bEA37;
  // address public constant _mirrorEditions =
  //     0xa8b8F7cC0C64c178ddCD904122844CBad0021647;
  // address public constant _partyBidFactory =
  //     0xB725682D5AdadF8dfD657f8e7728744C0835ECd9;

  address internal _splitter;
  address internal _minter;

  uint256[] public balanceForWindow;
  mapping(bytes32 => bool) internal claimed;
  uint256 internal depositedInWindow;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
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