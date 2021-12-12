// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ThePixelsBaseExtender.sol";
import "./../IThePixelsDNAUpdater.sol";

contract ThePixelsChristmasExtension is Ownable, ThePixelsBaseExtender, IThePixelsDNAUpdater {
  bool public isLive;
  mapping (uint256 => bool) public extendedTokens;

  constructor() ThePixelsBaseExtender(1)  {}

  function setIsLive(bool _isLive) external onlyOwner {
    isLive = _isLive;
  }

  function canUpdateDNAExtension(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  ) external view override returns (bool) {
    return isLive;
  }

  function getUpdatedDNAExtension(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  ) external override returns (uint256) {
    require(isLive, "Extension is not live yet.");
    require(!extendedTokens[_tokenId], "Already extended.");

    uint256 rnd = _rnd(_owner, _tokenId, _dna, _dnaExtension) % 100;
    uint256 variant;

    if (rnd >= 85) {
      variant = 3;
    }else if (rnd < 85 && rnd >= 50) {
      variant = 2;
    }else{
      variant = 1;
    }

    uint256 newExtension = _getAddedExtension(0, variant);
    emit Extended(_owner, _tokenId, _dna, newExtension);
    extendedTokens[_tokenId] = true;
    return newExtension;
  }

  function getExtendStatusOf(uint256[] memory tokens) public view returns (bool[] memory) {
    bool[] memory result = new bool[](tokens.length);
    for(uint256 i=0; i<tokens.length; i++) {
      if (!extendedTokens[tokens[i]]) {
        result[i] = true;
      }
    }
    return result;
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

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

interface IThePixel {
  function tokensOfOwner(address _owner) external view returns (uint256[] memory);
}

contract ThePixelsBaseExtender {
  uint256 public decimal;

  event Extended(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  );

  constructor(uint256 _decimal) {
    decimal = _decimal;
  }

  function _getAddedExtension(uint256 extension, uint256 index) internal returns (uint256) {
    return extension + index * decimal;
  }

  function _rnd(address _owner, uint256 _tokenId, uint256 _dna, uint256 _dnaExtension) internal returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      _owner,
      _tokenId,
      _dna,
      _dnaExtension,
      block.timestamp
    )));
  }
}

// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

interface IThePixelsDNAUpdater {
  function canUpdateDNAExtension(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  ) external view returns (bool);

  function getUpdatedDNAExtension(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  ) external returns (uint256);
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