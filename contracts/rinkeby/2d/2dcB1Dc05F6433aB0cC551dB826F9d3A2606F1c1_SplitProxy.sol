// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {SplitStorage} from "./SplitStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface ISplitFactory {
    function splitter() external returns (address);

    function minter() external returns (address);

    function wethAddress() external returns (address);

    function merkleRoot() external returns (bytes32);
}

/**
 * @title SplitProxy
 * @author MirrorXYZ
 *
 * @notice Modified. Use at your own risk.
 * @notice added OpenZeppelin's Ownable (modified) & IERC721Receiver (inherited)
 */
contract SplitProxy is SplitStorage, IERC721Receiver {
    // OpenZeppelin Ownable.sol
    address private _owner;

    constructor() {
        _splitter = ISplitFactory(msg.sender).splitter();
        _minter = ISplitFactory(msg.sender).minter();
        // wethAddress = ISplitFactory(msg.sender).wethAddress();
        merkleRoot = ISplitFactory(msg.sender).merkleRoot();

        /**
         * @notice Modification of OpenZeppelin Ownable.sol
         * @dev Using tx.origin instead of splitFactory to set owner saves ~25,000 gas over saving to SplitFactory
         * @dev Should be safe in this context... (only used once in the constructor)
         * @dev If that's not the case, please contact: [email protected]
         */
        _setOwner(tx.origin);

        address(_minter).call(
            abi.encodeWithSignature("setApprovalsForSplit(address)", owner())
        );
    }

    /**
     * @notice OpenZeppelin IERC721Receiver.sol
     * @dev Allows contract to receive ERC-721s
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable {
        if (msg.sender == owner()) {
            address _impl = minter();
            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize())
                let result := call(
                    gas(),
                    _impl,
                    callvalue(),
                    ptr,
                    calldatasize(),
                    0,
                    0
                )
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
                let result := delegatecall(
                    gas(),
                    _impl,
                    ptr,
                    calldatasize(),
                    0,
                    0
                )
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

    //======== OpenZeppelin Ownable.sol =========
    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev Updates approvals, see Minter.sol
     */
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner());
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        address(_minter).call(
            abi.encodeWithSignature(
                "updateApprovalsForSplit(address,address)",
                _owner,
                newOwner
            )
        );

        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    //======== /Ownable.sol =========

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
 *
 * Modified to store:
 * address of the deployed Minter Contract
 */
contract SplitStorage {
    //======== Constants =========
    address public constant _zoraMedia =
        0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4;
    address public constant _zoraMarket =
        0x85e946e1Bd35EC91044Dc83A5DdAB2B6A262ffA6;
    address public constant _zoraAuctionHouse =
        0xE7dd1252f50B3d845590Da0c5eADd985049a03ce;
    //0x835F86fF1670917A786b72D1FD8DcC385E27DD77 mainnet
    address public constant _mirrorAH =
        0x2D5c022fd4F81323bbD1Cc0Ec6959EC8CC1C5A11;
    //idk 0x517bab7661C315C63C6465EEd1b4248e6f7FE183 maybe
    address public constant _mirrorCrowdfundFactory =
        0xeac226B370D77f436b5780b4DD4A49E59e8bEA37;
    //0x3725CA6034bcDBc3c9aDa649d49Df68527661175 mainnet
    address public constant _mirrorEditions =
        0xa8b8F7cC0C64c178ddCD904122844CBad0021647;
    //0xD96Ff9e48f095f5a22Db5bDFFCA080bCC3B98c7f mainnet
    address public constant _partyBidFactory =
        0xB725682D5AdadF8dfD657f8e7728744C0835ECd9;
    address public constant wethAddress =
        0xc778417E063141139Fce010982780140Aa0cD5Ab;

    bytes32 public merkleRoot;
    uint256 public currentWindow;

    address internal _splitter;
    address internal _minter;

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

