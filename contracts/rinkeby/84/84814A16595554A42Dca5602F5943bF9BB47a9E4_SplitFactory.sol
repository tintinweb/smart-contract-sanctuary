// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {SplitProxy} from "./SplitProxy.sol";

/**
 * @title SplitFactory
 * @author MirrorXYZ
 * @notice Modified by NA. Use at your own risk
 */
contract SplitFactory {
    //======== Immutable storage =========

    address public immutable splitter;
    address public immutable minter;
    address public immutable auctionHouse;
    address public immutable wethAddress;

    //======== Mutable storage =========

    // Gets set within the block, and then deleted.
    bytes32 public merkleRoot;

    //======== Constructor =========

    constructor(
        address splitter_,
        address minter_,
        address auctionHouse_,
        address wethAddress_
    ) {
        splitter = splitter_;
        minter = minter_;
        auctionHouse = auctionHouse_;
        wethAddress = wethAddress_;
    }

    //======== Deploy function =========

    function createSplit(bytes32 merkleRoot_)
        external
        returns (address splitProxy)
    {
        merkleRoot = merkleRoot_;
        splitProxy = address(
            new SplitProxy{salt: keccak256(abi.encode(merkleRoot_))}()
        );
        delete merkleRoot;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {SplitStorage} from "./SplitStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface ISplitFactory {
    function splitter() external returns (address);

    function minter() external returns (address);

    function auctionHouse() external returns (address);

    function wethAddress() external returns (address);

    function merkleRoot() external returns (bytes32);
}

interface IMinter {
    function setApprovalForSplit(address operator, bool approved) external;
}

/**
 * @title SplitProxy
 * @author MirrorXYZ
 * @notice Modified by NA. Use at your own risk.
 * added OpenZeppelin's Ownable (modified) & IERC721Receiver (inherited)
 */
contract SplitProxy is SplitStorage, IERC721Receiver {
    // Emits event for Graph Protocol
    // event TokenReceived(uint256 tokenId);

    // Allows minting ERC721 and creating auction in same tx
    uint256 internal _tokenId;

    // OpenZeppelin Ownable.sol
    address private _owner;

    constructor() {
        _splitter = ISplitFactory(msg.sender).splitter();
        _minter = ISplitFactory(msg.sender).minter();
        _auctionHouse = ISplitFactory(msg.sender).auctionHouse();
        wethAddress = ISplitFactory(msg.sender).wethAddress();
        merkleRoot = ISplitFactory(msg.sender).merkleRoot();

        /** @notice Modification of OpenZeppelin Ownable.sol */
        // using tx.origin instead of splitFactory to set owner saves ~25,000 gas
        // & should be safe in this context.
        _setOwner(tx.origin);

        // IMinter(_minter).setApprovalForSplit(_owner, true);
        // IMinter(_minter).setApprovalForSplit(_auctionHouse, true);
        (bool success, bytes memory returndata) = address(_minter).call(
            abi.encodeWithSignature(
                "setApprovalForSplit(address,bool)",
                _owner,
                true
            )
        );
        (bool success2, bytes memory returndata2) = address(_minter).call(
            abi.encodeWithSignature(
                "setApprovalForSplit(address,bool)",
                _auctionHouse,
                true
            )
        );
        require(success);
        require(success2);
    }

    /// @notice Begin OpenZeppelin Ownable.sol

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner());
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        // IMedia(zora).setApprovalForAll(_owner, false);
        _owner = newOwner;
        // IMedia(zora).setApprovalForAll(newOwner, true);
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
        // IMedia(zora).setApprovalForAll(_owner, true);
    }

    // End OpenZeppelin Ownable.sol

    /** @author OpenZeppelin IERC721Receiver.sol */
    /// @notice Allows contract to receive ERC-721. Saves to state and emits event
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) public override returns (bytes4) {
        // _tokenId = tokenId;
        // emit TokenReceived(tokenId);
        return this.onERC721Received.selector;
    }

    function callMinter(bytes calldata data_) external {
        require(msg.sender == owner());

        address _impl = minter();

        // (bool success, bytes memory returndata) = _minter.call(msg.data);

        // require(success);
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := call(gas(), _impl, 0, ptr, calldatasize(), 0, 0)
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

    /** @dev any eth sent to this address gets deposited to splitter */
    fallback() external payable {
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

    function splitter() public view returns (address) {
        return _splitter;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    // Plain ETH transfers.
    receive() external payable {
        depositedInWindow += msg.value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title SplitStorage
 * @author MirrorXYZ
 * @notice Modified by NA. Use at your own risk
 */
contract SplitStorage {
    bytes32 public merkleRoot;
    uint256 public currentWindow;

    address internal wethAddress;
    address internal _splitter;
    address internal _minter;
    address internal _auctionHouse;

    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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