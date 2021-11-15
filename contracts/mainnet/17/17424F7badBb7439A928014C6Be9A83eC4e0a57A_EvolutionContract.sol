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
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IEvolutionContract {
  function isEvolvingActive() external view returns (bool);
  function isEvolutionValid(uint256[3] memory _tokensToBurn) external returns (bool);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function getEvolutionPrice() external view returns (uint256);
}

contract EvolutionContract is IEvolutionContract, Ownable {
  using Strings for uint256;

  bytes public bases;
  mapping(bytes1 => bytes1) public evolutionMapping;
  bytes1 public constant DIGITTO_BASE = 0x1e;

  string public _baseURI = "";
  bool private _isEvolvingActive = false;

  function isEvolvingActive() external view override returns (bool) {
    return _isEvolvingActive;
  }

  function isEvolutionValid(uint256[3] memory _tokensToBurn) external override returns (bool) {
    bytes1 firstBase = getBase(_tokensToBurn[0] - 1);
    bytes1 secondBase = getBase(_tokensToBurn[1] - 1);
    bytes1 thirdBase = getBase(_tokensToBurn[2] - 1);

    bool isValid = false;
    bytes1 base;
    if (firstBase == secondBase && firstBase == thirdBase) {
      isValid = true;
      base = firstBase;
    } else if (firstBase == DIGITTO_BASE && secondBase == thirdBase) {
      isValid = true;
      base = secondBase;
    } else if (secondBase == DIGITTO_BASE && firstBase == thirdBase) {
      isValid = true;
      base = firstBase;
    } else if (thirdBase == DIGITTO_BASE && firstBase == secondBase) {
      isValid = true;
      base = firstBase;
    }

    if (isValid) {
      bytes1 evolutionBase = evolutionMapping[base];
      if (evolutionBase == 0x00) {
        isValid = false;
      } else {
        bases.push(evolutionBase);
      }
    }

    return isValid;
  }

  function tokenURI(uint256 tokenId) external view override returns (string memory) {
    return string(abi.encodePacked(_baseURI, tokenId.toString()));
  }

  function getEvolutionPrice() external pure override returns (uint256) {
    return 0 ether;
  }

  function toggleEvolvingActive() external onlyOwner {
    _isEvolvingActive = !_isEvolvingActive;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseURI = baseURI;
  }

  function getEvolutionMapping(bytes1 base) public view returns (bytes1) {
    return evolutionMapping[base];
  }

  function addEvolutionMappings(bytes memory originalBases, bytes memory evolvedBases) public onlyOwner {
    for (uint i = 0; i < originalBases.length; i++) {
      evolutionMapping[originalBases[i]] = evolvedBases[i];
    }
  }

  function getBase(uint256 index) public view returns (bytes1) {
    return bases[index];
  }

  function addBases(bytes memory basesToAdd) public onlyOwner {
    for (uint i = 0; i < basesToAdd.length; i++) {
      bases.push(basesToAdd[i]);
    }
  }

  function clearBases() public onlyOwner {
    bases = "";
  }
}

