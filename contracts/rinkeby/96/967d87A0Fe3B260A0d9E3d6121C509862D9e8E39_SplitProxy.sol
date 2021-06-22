// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {SplitStorage} from "./SplitStorage.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";

interface ISplitFactory {
    function splitter() external returns (address);

    function wethAddress() external returns (address);

    function merkleRoot() external returns (bytes32);
}

/**
 * @title SplitProxy
 * @author MirrorXYZ
 */
contract SplitProxy is SplitStorage, IERC721Receiver {
    constructor() {
        _splitter = ISplitFactory(msg.sender).splitter();
        wethAddress = ISplitFactory(msg.sender).wethAddress();
        merkleRoot = ISplitFactory(msg.sender).merkleRoot();
    }

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

    address zoraMediaRinkeby = 0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4;
    
    event NFTminted(address sender, bool success);

    struct MediaData {
        // A valid URI of the content represented by this token
        string tokenURI;
        // A valid URI of the metadata associated with this token
        string metadataURI;
        // A SHA256 hash of the content pointed to by tokenURI
        bytes32 contentHash;
        // A SHA256 hash of the content pointed to by metadataURI
        bytes32 metadataHash;
    }
    
    struct BidShares {
        uint256 prevOwner;
        uint256 creator;
        uint256 owner;
    }

    function splitter() public view returns (address) {
        return _splitter;
    }

    // Plain ETH transfers.
    receive() external payable {
        depositedInWindow += msg.value;
    }

    function mintNFT(
        MediaData calldata data, 
        BidShares calldata bidShares
    ) external {
        zoraMediaRinkeby.call(abi.encode(
            "mint(MediaData memory data, IMarket.BidShares memory bidShares)", data, bidShares)
        );
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        emit NFTminted(msg.sender, true);
        return this.onERC721Received.selector;
    }
    
    function transferNFTtoCreator(
        address to,
        uint256 tokenId
    ) external {
        zoraMediaRinkeby.call(abi.encode(
            "_transfer(address from, address to, uint256 tokenId)", this, to, tokenId));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title SplitStorage
 * @author MirrorXYZ
 */
contract SplitStorage {
    bytes32 public merkleRoot;
    uint256 public currentWindow;
    address internal wethAddress;
    address internal _splitter;
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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