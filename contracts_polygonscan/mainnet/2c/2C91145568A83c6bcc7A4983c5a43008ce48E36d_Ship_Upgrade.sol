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

/// @title: Metavaders Starships - Ship Upgrade
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
abstract contract IStarships {
    function mint_special(address to, uint256 race) public virtual;
    function burn(uint256 tokenId) external virtual;
    // function balanceOf(address _owner) public virtual returns(uint256);
    function totalSupply() public view virtual returns (uint256);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function getTokenRace_ID(uint256 tokenId) public view virtual returns(uint256);
}

contract Ship_Upgrade is 
    Ownable
{   
    using Strings for uint256;

    address public starshipsAddress;
    bool public paused = true;

    IStarships StarshipsContract;

    // -- CONSTRUCTOR FUNCTIONS -- //
    constructor(address _starshipsAddress) {
        starshipsAddress = _starshipsAddress;
        StarshipsContract = IStarships(_starshipsAddress);
    }

    // -- CUSTOM FUNCTIONS -- //
    // Human Basic Upgrade
    function humanAdvUpgrade(uint256[] memory tokenIds) external {
        require(paused != true,                             "Starship upgrades currently on hold");
        require(tokenIds.length == 3,                       "Must send 3 starships to burn");
        require(checkOwnership(tokenIds, _msgSender()),     "Must be owner of the starships");
        require(checkStarships(tokenIds, 1),                "Must be Basic Human Starships");
        for(uint256 i; i < 3; i++){
            StarshipsContract.burn(tokenIds[i]);
        }
        StarshipsContract.mint_special(_msgSender(), 8); // shipName[8] = 'human_advanced';
    }

    // Human Mothership Upgrade
    function humanMotherUpgrade(uint256[] memory tokenIds) external {
        require(paused != true,                             "Starship upgrades currently on hold");
        require(tokenIds.length == 3,                       "Must send 3 starships to burn");
        require(checkOwnership(tokenIds, _msgSender()),     "Must be owner of the starships");
        require(checkStarships(tokenIds, 8),                "Must be Advanced Human Starships");
        for(uint256 i; i < 3; i++){
            StarshipsContract.burn(tokenIds[i]);
        }
        StarshipsContract.mint_special(_msgSender(), 9); // shipName[9] = 'human_mother';
    }

    // Human Basic Upgrade
    function mutantAdvUpgrade(uint256[] memory tokenIds) external {
        require(paused != true,                             "Starship upgrades currently on hold");
        require(tokenIds.length == 3,                       "Must send 3 starships to burn");
        require(checkOwnership(tokenIds, _msgSender()),     "Must be owner of the starships");
        require(checkStarships(tokenIds, 4),                "Must be Basic Mutant Starships");
        for(uint256 i; i < 3; i++){
            StarshipsContract.burn(tokenIds[i]);
        }
        StarshipsContract.mint_special(_msgSender(), 10); // shipName[10] = 'mutant_advanced';
    }


    // Check ownership of starships
    function checkOwnership(uint256[] memory tokenIds, address checkAdd) public view returns (bool) {
        for(uint i; i < tokenIds.length; i++){
            if (StarshipsContract.ownerOf(tokenIds[i]) != checkAdd) return false;
        }
        return true;
    }
    // Check starships race
    function checkStarships(uint256[] memory tokenIds, uint256 raceId) public view returns (bool) {
        for(uint i; i < tokenIds.length; i++){
            if (StarshipsContract.getTokenRace_ID(tokenIds[i]) != raceId) return false;
        }
        return true;
    }

    // -- SMART CONTRACT OWNER ONLY FUNCTIONS -- //
    // Update Starships Address Incase There Is an Issue
    function updateStarshipsAddress(address _address) public onlyOwner {
        starshipsAddress = _address;
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

}