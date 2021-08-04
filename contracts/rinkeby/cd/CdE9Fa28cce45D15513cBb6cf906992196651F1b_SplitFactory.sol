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

    //======== Mutable storage =========

    // Gets set within the block, and then deleted.
    bytes32 public merkleRoot;

    //======== Constructor =========

    constructor(address splitter_) {
        splitter = splitter_;
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


    function merkleRoot() external returns (bytes32);
}

// Zora Market Contract Interface
interface IMarket {
    struct BidShares {
        uint256 prevOwner;
        uint256 creator;
        uint256 owner;
    }
}

// Zora Media Contract Interface
interface IMedia {
    struct MediaData {
        string tokenURI;
        string metadataURI;
        bytes32 contentHash;
        bytes32 metadataHash;
    }
    function mint(
        MediaData calldata data, IMarket.BidShares calldata bidShares
    ) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @title SplitProxy
 * @author MirrorXYZ
 * @notice Modified by NA. Use at your own risk
 */
contract SplitProxy is SplitStorage, IERC721Receiver {
    constructor() {
        _splitter = ISplitFactory(msg.sender).splitter();
        merkleRoot = ISplitFactory(msg.sender).merkleRoot();
        // using tx.origin instead of splitFactory to set owner saves ~25,000 gas & should be safe in this context.
        owner = tx.origin; 
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

    // Plain ETH transfers.
    receive() external payable {
        depositedInWindow += msg.value;
    }

    // Mints a Zora NFT and sends it to the creator
    function mintNFT(
        IMedia.MediaData calldata mediaData, 
        IMarket.BidShares calldata bidShares
    ) external {
        require(msg.sender == owner);
        IMedia(zoraMedia).mint(mediaData, bidShares);
    }

    /// @notice Allows contract to receive ERC-721. Immediately transfers to owner.
    function onERC721Received(address, address, uint256 tokenId, bytes calldata) public virtual override returns (bytes4) {
        IMedia(zoraMedia).safeTransferFrom(address(this), owner, tokenId);
        return this.onERC721Received.selector;
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
    address internal _splitter;
    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
    
    address public owner;

    /// @notice Do not forget to change these according to network you are deploying to
    address internal immutable wethAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab; 
    address internal immutable zoraMedia = 0x85e946e1Bd35EC91044Dc83A5DdAB2B6A262ffA6;
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