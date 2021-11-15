// SPDX-License-Identifier: MIT

/// @title: Metavaders - Mint
/// @author: PxGnome
/// @notice: Used to handle mint with metavaders NFT contract
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
abstract contract IMetavader_Mint {
    function mint(address to, uint256 num) public virtual;
    function reserveMint(address to, uint256 num) public virtual;
    function balanceOf(address _owner) public virtual returns(uint256);
    function totalSupply() public view virtual returns (uint256);
}

contract Metavaders_Mint is 
    Ownable
{   
    using Strings for uint256;
    address public metavadersAddress;

    IMetavader_Mint MetavaderContract;

    // Mint Info
    uint256 public max_mint = 10101;
    uint256 private _reserved = 200; // Reserved amount for special usage
    uint256 public price = 0.07 ether;
    uint256 private _max_gas = 200000000000;
    uint256 public start_time = 1633363200; // start time:  Monday, October 4, 2021 4:00:00 PM UTC
    uint256 public max_sale = 10;
    uint256 public max_wallet = 20;
    bool public _paused = true;

    // Presale
    uint256 private _presale_supply = 1000;
    uint256 public max_presale = 5;
    bool public whiteListEnd = false;

    mapping(address => bool) whitelist;
    mapping(address => uint256) mintPerWallet;

    // -- CONSTRUCTOR FUNCTIONS -- //
    // 10101 Metavaders in total
    constructor(address _metavadersAddress) {
        metavadersAddress = _metavadersAddress;
        MetavaderContract = IMetavader_Mint(_metavadersAddress);
    }

    // // -- UTILITY FUNCTIONS -- //
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // -- SMART CONTRACT OWNER ONLY FUNCTIONS -- //
    // Update Metavader Address Incase There Is an Issue
    function updateMetavadersAddress(address _address) public onlyOwner {
        metavadersAddress = _address;
    }

    // Withdraw to owner addresss
    function withdrawAll() public payable onlyOwner returns (uint256) {
        uint256 balance = address(this).balance;
        require(payable(owner()).send(balance)); 
        return balance;
    }

    function addToWhiteList(address _address) public onlyOwner {
        whitelist[_address] = true;
        // emit AddedToWhitelist(_address);
    }

    function removeFromWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
        // emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        if (whiteListEnd == true) {
            return true;
        } else {
            return whitelist[_address];
        }
    }


    // -- MINT FUNCTIONS  --//
    function public_mint(uint256 num) public payable virtual {
        require( tx.gasprice < _max_gas,                                    "Please set lower gas price and retry"); // Set a cap on gas
        require( !_paused,                                                  "Mint is paused" );
        require( block.timestamp > start_time,                              "Mint not yet started"); // start time:  1633374000 = Monday, October 4, 2021 7:00:00 PM UTC
        require( num <= max_sale,                                           "Exceeded max mint per txn");
        require( (mintPerWallet[_msgSender()] + num) <= max_wallet,         "Exceeded mint per wallet");
        // require( MetavaderContract.balanceOf(_msgSender()) < max_wallet,    "Exceeded mint per wallet");
        uint256 supply = MetavaderContract.totalSupply();
        require( supply + num < max_mint - _reserved,                       "Exceeds maximum supply" );
        require( msg.value >= price * num,                                  "Ether sent incorrect");

        MetavaderContract.mint(_msgSender(), num);
        mintPerWallet[_msgSender()] += num;
    }

    // Presale Mint Function
    function presale_mint(uint256 num) public payable virtual {
        require(tx.gasprice < _max_gas,                                     "Please set lower gas price and retry"); // Set a cap on gas
        require( !_paused,                                                  "Mint is paused" );        
        require(isWhitelisted(_msgSender()) == true || whiteListEnd,        "You are not on whitelist");
        require( num <= max_presale,                                        "Exceeded max presale mint per txn");
        require( (mintPerWallet[_msgSender()] + num) <= max_presale,        "Exceeded mint per wallet");
        uint256 supply = MetavaderContract.totalSupply();
        require( supply + num < _presale_supply,                            "Exceeds max presale supply" );
        require( msg.value >= price * num,                                  "Ether sent incorrect");

        MetavaderContract.mint(_msgSender(), num);
        mintPerWallet[_msgSender()] += num;
    }

    // Minted the reserve
    function reserveMint(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved Metavaders supply" );
        // uint256 supply = MetavaderContract.totalSupply();
        MetavaderContract.reserveMint(_to, _amount);
        _reserved -= _amount;
    }

    // Get wallet mint numbers for troubleshooting if needed
    function getWalletMinted(address checkAdd) external view returns (uint256 minted) {
        return mintPerWallet[checkAdd];
    }

    // -- SMART CONTRACT OWNER ONLY FUNCTIONS -- //
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
    function setGasMax(uint256 _newGasMax) public onlyOwner {
        _max_gas = _newGasMax;
    }
    function setStartTime(uint256 new_start_time) public onlyOwner {
        start_time = new_start_time;
    }
    function setPresaleSupply(uint256 new_presale_supply) public onlyOwner {
        _presale_supply = new_presale_supply;
    }
    function setMaxPresale(uint256 new_max_presale) public onlyOwner {
        max_presale = new_max_presale;
    }
    function setMaxSale(uint256 new_max_sale) public onlyOwner {
        max_sale = new_max_sale;
    }
    function setMaxWallet(uint256 new_max_wallet) public onlyOwner {
        max_wallet = new_max_wallet;
    }
    function setWhiteListEnd(bool new_whiteListEnd) public onlyOwner {
        whiteListEnd = new_whiteListEnd;
    }


    // Pause sale/mint in case of special reason
    function pause(bool val) public onlyOwner {
        _paused = val;
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

