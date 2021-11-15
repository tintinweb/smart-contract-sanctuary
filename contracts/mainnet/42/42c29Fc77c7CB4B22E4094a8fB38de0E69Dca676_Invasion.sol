// SPDX-License-Identifier: MIT

/// @title: Metavaders - Invasion
/// @author: PxGnome
/// @notice: Used to interact with metavaders NFT contract
/// @dev: This is Version 1.0
//
// ███╗   ███╗███████╗████████╗ █████╗ ██╗   ██╗ █████╗ ██████╗ ███████╗██████╗ ███████╗
// ████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║   ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝
// ██╔████╔██║█████╗     ██║   ███████║██║   ██║███████║██║  ██║█████╗  ██████╔╝███████╗
// ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║╚██╗ ██╔╝██╔══██║██║  ██║██╔══╝  ██╔══██╗╚════██║
// ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║ ╚████╔╝ ██║  ██║██████╔╝███████╗██║  ██║███████║
// ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝
//
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Abstract Contract Used for Inheriting
abstract contract IMetavader {
    function changeMode(uint256 tokenId, string memory mode) public virtual;
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function getBaseURI() public view virtual returns (string memory);
    function tokenURI(uint256 tokenId) public view virtual returns (string memory);
}

// Abstract Contract Used for Inheriting
abstract contract mvCustomIERC721 {
    function balanceOf(address owner) public view virtual returns (uint256);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function approve(address to, uint256 tokenId) public virtual;
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
}

contract Invasion is 
    Ownable
{   
    using Strings for uint256;

    address public vaultAddress;
    address public invadeAddress;
    address public metavadersAddress;
    bool public paused = true;

    IMetavader MetavaderContract;
    mvCustomIERC721 InvasionContract;

    // -- CONSTRUCTOR FUNCTIONS -- //
    // 10101 Metavaders in total
    constructor(address _metavadersAddress, address _invadeAddress) {
        metavadersAddress = _metavadersAddress;
        invadeAddress = _invadeAddress;
        vaultAddress = owner();
        MetavaderContract = IMetavader(_metavadersAddress);
        InvasionContract = mvCustomIERC721(_invadeAddress);
    }

    // // -- UTILITY FUNCTIONS -- //
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // -- SMART CONTRACT OWNER ONLY FUNCTIONS -- //
    // Change Vault Address For Future Use
    function updateVaultAddress(address _address) public onlyOwner {
        vaultAddress = _address;
    }
    // Update Invade Address Incase There Is an Issue
    function updateInvadeAddress(address _address) public onlyOwner {
        invadeAddress = _address;
    }
    // Update Invade Address Incase There Is an Issue
    function updateMetavadersAddress(address _address) public onlyOwner {
        metavadersAddress = _address;
    }

    // Withdraw to owner addresss
    function withdrawAll() public payable onlyOwner returns (uint256) {
        uint256 balance = address(this).balance;
        require(payable(owner()).send(balance)); 
        return balance;
    }

    // Pause sale/mint in case of special reason
    function pause(bool val) public onlyOwner {
        paused = val;
    }

    // -- INVADER RELATED FUNCTIONS -- //
    // In this case relates to Animetas
    function getInvadeAddress() public view returns (address) {
        return invadeAddress;
    }
    function getInvaderBalance() public view returns (uint256) {
        return InvasionContract.balanceOf(_msgSender());
    }
    function getInvaderOwnerOf(uint256 tokenId) public view returns (address) {
        return InvasionContract.ownerOf(tokenId);
    }

    // -- CUSTOM ADD ONS  --//
    // // // Change back the Metavaders' mode to normal
    function changeModeMetavaders_Normal(uint256 tokenId) public virtual {
        require(!paused, "Invasion is on hold");
        require(MetavaderContract.ownerOf(tokenId) == _msgSender(), "Must be the owner of the Metavader to execute");
        require(!compareStrings(MetavaderContract.tokenURI(tokenId), string(abi.encodePacked(MetavaderContract.getBaseURI(), tokenId.toString(), "C"))), "Metavader has transformed and cannot revert");
        MetavaderContract.changeMode(tokenId, ""); 
    }

    // // // Changes the Metavaders' mode when also own an Invaded NFT
    function changeModeMetavaders_Animetas(uint256 tokenId) public virtual {
        require(!paused, "Invasion is on hold");
        require(MetavaderContract.ownerOf(tokenId) == _msgSender(), "Must be the owner of the Metavader to execute");
        require(InvasionContract.balanceOf(_msgSender()) > 0,  "You needs to own Animetas NFT to activate");
        require(!compareStrings(MetavaderContract.tokenURI(tokenId), string(abi.encodePacked(MetavaderContract.getBaseURI(), tokenId.toString(), "C"))), "Metavader has transformed and cannot revert");
        MetavaderContract.changeMode(tokenId, "A"); 
    }

    // // // Permenanetly changes the Metavaders' mode if willing to give up the Invaded NFT -- NOTE: NEED APPROVAL PRIOR
    function transformMetavaders(uint256 tokenId, uint256 animetas_tokenId) public virtual {
        require(MetavaderContract.ownerOf(tokenId) == _msgSender(), "Must be the owner of the Metavader to execute");
        require(InvasionContract.ownerOf(animetas_tokenId) == _msgSender(), "Sender is not owner nor approved for Animetas Token");
        require(!compareStrings(MetavaderContract.tokenURI(tokenId), string(abi.encodePacked(MetavaderContract.getBaseURI(), tokenId.toString(), "C"))), "Metavader has transformed and cannot revert");
        InvasionContract.safeTransferFrom(_msgSender(),  vaultAddress, animetas_tokenId);
        MetavaderContract.changeMode(tokenId, "B"); 
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

