//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoBees.sol";
import "./Traits.sol";

contract Randomizer is Ownable {
    ICryptoBees beesContract;
    Traits traitsContract;
    uint256[] private unrevealedTokens;
    uint256 private unrevealedTokenIndex = 1;

    event MintRevealed(address indexed owner, uint256 tokenId, uint256 _type);

    constructor() {}

    function setContracts(address _BEES, address _TRAITS) external onlyOwner {
        beesContract = ICryptoBees(_BEES);
        traitsContract = Traits(_TRAITS);
    }

    function unrevealedTokensPush(uint256 blockNum) external {
        require(_msgSender() == address(traitsContract), "DONT CHEAT!");
        unrevealedTokens.push(blockNum);
    }

    function revealToken(uint256 blockNum) external {
        require(_msgSender() == address(traitsContract), "DONT CHEAT!");

        if (unrevealedTokens[unrevealedTokenIndex] < blockNum) {
            uint256 seed = random(unrevealedTokenIndex);
            uint256 num = ((seed & 0xFFFF) % 100);
            uint8 _type = 1;
            if (num == 0) _type = 3;
            else if (num < 10) _type = 2;
            beesContract.setTokenType(unrevealedTokenIndex, _type);
            emit MintRevealed(_msgSender(), unrevealedTokenIndex, _type);
            unrevealedTokenIndex++;
        }
    }

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, seed)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICryptoBees {
    struct Token {
        uint8 _type;
        uint32 pot;
        uint48 lastAttackTimestamp;
        uint48 cooldownTillTimestamp;
    }

    function getMinted() external view returns (uint256 m);

    function increateTokensPot(uint256 tokenId, uint32 amount) external;

    function updateTokensLastAttack(
        uint256 tokenId,
        uint48 timestamp,
        uint48 till
    ) external;

    // function mintForEth(uint256 amount, bool presale) external payable;

    // function mintForHoney(uint256 amount) external;

    // function mintForWool(uint256 amount) external;

    function withdrawERC20(
        address erc20TokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function mint(uint256 tokenId) external;

    function isWhitelisted(address who) external view returns (bool);

    function setPaused(bool _paused) external;

    function getTokenData(uint256 tokenId) external view returns (Token memory token);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function doesExist(uint256 tokenId) external view returns (bool exists);

    function setTokenType(uint256 tokenId, uint8 _type) external;

    function performTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function performSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Randomizer.sol";
import "./ICryptoBees.sol";
import "./Base64.sol";

contract Traits is Ownable {
    using Strings for uint256;
    ICryptoBees beesContract;
    Randomizer randomizerContract;
    // mint price ETH
    uint256 public constant MINT_PRICE = .02 ether;
    uint256 public constant MINT_PRICE_DISCOUNT = .055 ether;

    // mint price HONEY
    uint256 public constant MINT_PRICE_HONEY = 3000 ether;
    // mint price WOOL
    uint256 public mintPriceWool = 3000 ether;
    // how many minted already
    uint256 public minted;
    // max number of tokens that can be minted
    uint256 public constant MAX_TOKENS = 40000;
    // number of tokens that can be claimed for ETH
    uint256 public constant PAID_TOKENS = 10000;
    /// @notice controls if mintWithEthPresale is paused
    bool public mintWithEthPresalePaused = true;
    /// @notice controls if mintWithWool is paused
    bool public mintWithWoolPaused = true;

    constructor() {}

    function setBeesContract(address _BEES_CONTRACT) external onlyOwner {
        beesContract = ICryptoBees(_BEES_CONTRACT);
    }

    function setRandomizerContract(address _RANDOMIZER_CONTRACT) external onlyOwner {
        randomizerContract = Randomizer(_RANDOMIZER_CONTRACT);
    }

    /** MINTING */
    function mintForEth(
        uint256 amount,
        bool presale,
        uint256 value
    ) external {
        require(_msgSender() == address(beesContract), "DONT CHEAT!");
        mintCheck(amount, presale, value);
        for (uint256 i = 0; i < amount; i++) {
            _mint();
        }
    }

    function _mint() private {
        minted++;
        if (minted > 1) randomizerContract.revealToken(block.number);
        randomizerContract.unrevealedTokensPush(block.number);
        beesContract.mint(minted);
    }

    function mintCheck(
        uint256 amount,
        bool presale,
        uint256 value
    ) private view {
        // require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= MAX_TOKENS, "All tokens minted");
        if (presale) {
            require(beesContract.isWhitelisted(_msgSender()), "You are not on WL");
            require(!mintWithEthPresalePaused, "Presale mint paused");
            require(amount > 0 && amount <= 2, "Invalid mint amount presale");
        } else require(amount > 0 && amount <= 10, "Invalid mint amount sale");
        require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
        if (presale) require(amount * MINT_PRICE_DISCOUNT == value, "Invalid payment amount presale");
        else require(amount * MINT_PRICE == value, "Invalid payment amount sale");
    }

    /** RENDER */

    function getTokenTextType(uint256 tokenId) external view returns (string memory) {
        require(beesContract.doesExist(tokenId), "ERC721Metadata: Nonexistent token");
        return _getTokenTextType(tokenId);
    }

    function _getTokenTextType(uint256 tokenId) private view returns (string memory) {
        uint8 _type = beesContract.getTokenData(tokenId)._type;
        if (_type == 1) return "BEE";
        else if (_type == 2) return "BEAR";
        else if (_type == 3) return "BEEKEEPER";
        else return "NOT REVEALED";
    }

    function _getTokenImage(uint256 tokenId) private view returns (string memory) {
        uint8 _type = beesContract.getTokenData(tokenId)._type;
        if (_type == 1) return "QmfCnnjNDndTuRZLZFJhLVtQ8m533pEnBis4Y2NH3BvZdF";
        else if (_type == 2) return "QmVPMv3Kxg94vAJo4fQY2FGnYTYp4RM1dq7anwr9psbz9P";
        else if (_type == 3) return "QmTUuGDbndWZDYYr6pE1aeutZLpSuZi44KMZxeUw1VB2D8";
        else return "";
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(beesContract.doesExist(tokenId), "ERC721Metadata: Nonexistent token");

        string memory textType = _getTokenTextType(tokenId);
        string memory image = _getTokenImage(tokenId);
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                textType,
                " #",
                uint256(tokenId).toString(),
                '", "type": "',
                textType,
                '", "trait": "',
                uint256(beesContract.getTokenData(tokenId)._type).toString(),
                '", "description": "',
                '","image": "',
                image,
                '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }

    function setPresaleMintPaused(bool _paused) external onlyOwner {
        mintWithEthPresalePaused = _paused;
    }

    function setWoolMintPaused(bool _paused) external onlyOwner {
        mintWithWoolPaused = _paused;
    }

    function setWoolMintPrice(uint256 _price) external onlyOwner {
        mintPriceWool = _price;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

pragma solidity ^0.8.9;

library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}