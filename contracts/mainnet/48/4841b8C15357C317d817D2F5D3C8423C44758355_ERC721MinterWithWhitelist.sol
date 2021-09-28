//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ERC721BaseLayer {
  function mintTo(address recipient, uint256 tokenId, string memory uri) external;
  function ownerOf(uint256 tokenId) external returns (address owner);
}

contract ERC721MinterWithWhitelist is Ownable {
  using Strings for *;

  address public erc721BaseContract;
  mapping(address => uint256) public whiteList;
  uint256 public maxSupply;
  uint256 public reservedSupply;
  uint256 public price;
  uint256 public minted;
  uint256 public reserveMinted;
  uint256 public startId;
  string public subCollectionURI;

  constructor(
    address erc721BaseContract_, 
    uint256 maxSupply_,
    uint256 reservedSupply_,
    uint256 price_,
    uint256 minted_, 
    uint256 startId_, 
    string memory subCollectionURI_
  ) {
    erc721BaseContract = erc721BaseContract_;
    maxSupply = maxSupply_;
    reservedSupply = reservedSupply_;
    price = price_;
    minted = minted_;
    startId = startId_;
    subCollectionURI = subCollectionURI_;
    whiteList[address(0xc55Ea01bFF091198CdA9d91100500b70c532b1A5)] = 2;
    whiteList[address(0x9eE5E3Ff06425CF972E77c195F70Ecb18aC23d7f)] = 5;
    whiteList[address(0xa68C1331bC465cfa7FB60bBdd17F4Bb57510F9f4)] = 2;
    whiteList[address(0x062F70147e58CeBa9220B6Aa0084135c21dAACee)] = 2;
    whiteList[address(0x2123EDD3Ed0f0c09A7AF4Cab58B4881B50A1F878)] = 2;
    whiteList[address(0xDd762af79fBBc73b51941Fdd1Fef8e89101EB51B)] = 2;
    whiteList[address(0xb905576A1D9Bff3b7F3A69764913037ea18F01dA)] = 2;
    whiteList[address(0x5d7d6f679083f3ebFC6A510C418b4E1B2f754FAe)] = 2;
    whiteList[address(0x7c7d093b4Fb96C89fcC29cD4c24c15DB0ed669dF)] = 2;
    whiteList[address(0x3665e13eC88D60a490eb8B34aCab4A52D46EC8c2)] = 1;
    whiteList[address(0xD1edDfcc4596CC8bD0bd7495beaB9B979fc50336)] = 2;
    whiteList[address(0x7B406Fa711451dE9E34D8Bb76c7c2D786e92047a)] = 1;
    whiteList[address(0xc86D5e4b89a0d9D4978444C9aB282C2D41918eEa)] = 2;
    whiteList[address(0x4cF93693586FE5E2F2c7097140F2EfA23e3e3FBa)] = 1;
    whiteList[address(0x148e2ED011A9EAAa200795F62889D68153EEacdE)] = 2;
  }

  function updateWhitelist(address[] memory registrants, uint256[] memory amount) public onlyOwner {
      for(uint256 i; i < registrants.length; i++) {
          whiteList[registrants[i]] = amount[i];
      }
  }

  function mintWhitelist(uint256 amount) public payable {
    require(msg.value == amount * price, "Invalid payment amount");
    require(reserveMinted + amount <= reservedSupply, "Purchase exceeds reserve supply limit");
    require(amount <= whiteList[msg.sender], "Sender not whitelisted or amount exceeds reservation");
    whiteList[msg.sender] -= amount;

    ERC721BaseLayer erc721 = ERC721BaseLayer(erc721BaseContract);

    uint256 tokenId = startId + minted; 
    minted += amount;
    reserveMinted += amount;
    for(uint256 i; i < amount; i++) {
        erc721.mintTo(msg.sender, tokenId, string(abi.encodePacked(subCollectionURI, tokenId.toString(), '.json')));
        tokenId++;
    }
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
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

{
  "optimizer": {
    "enabled": false,
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}