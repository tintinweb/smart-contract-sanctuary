//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IElemonInfo.sol";
import "./utils/Ownable.sol";

contract ElemonInfo is Ownable, IElemonInfo {
    modifier onlyOperator() {
        require(_operators[_msgSender()], "Forbidden");
        _;
    }

    mapping(address => bool) public _operators;

    constructor() {
        _operators[_msgSender()] = true;
    }

    mapping(uint256 => IElemonInfo.Info) public _tokenInfos;

    function setRarity(uint256 tokenId, uint256 rarity) external override onlyOperator {
        Info storage info = _tokenInfos[tokenId];
        info.rarity = rarity;
        emit ElemonInfoUpdated(tokenId, info);
    }

    function setBodyParts(uint256 tokenId, uint256[6] memory bodyParts) external override onlyOperator {
        require(bodyParts.length == 6, "Invalid bodyPart length");
        _tokenInfos[tokenId].bodyParts = bodyParts;
        emit ElemonBodyPartsUpdated(tokenId, bodyParts);
    }

    function setQuality(uint256 tokenId, uint256 quality) external override onlyOperator {
        _tokenInfos[tokenId].quality = quality;
        emit ElemonQualityUpdated(tokenId, quality);
    }

    function setClass(uint256 tokenId, uint256 class) external override  onlyOperator {
        _tokenInfos[tokenId].class = class;
        emit ElemonClassUpdated(tokenId, class);
    }

    function setStar(uint256 tokenId, uint256 star) external override onlyOperator {
        Info storage info = _tokenInfos[tokenId];
        info.star = star;
        emit ElemonStarUpdated(tokenId, star);
    }

    function setInfo(
        uint256 tokenId,
        uint256 baseCardId,
        uint256[6] memory bodyParts,
        uint256 quality,
        uint256 class,
        uint256 rarity,
        uint256 star
    ) external override onlyOperator {
        IElemonInfo.Info memory info = IElemonInfo.Info({
            rarity: rarity,
            baseCardId: baseCardId,
            bodyParts: bodyParts,
            quality: quality,
            class: class,
            star: star
        });
        _tokenInfos[tokenId] = info;
        emit ElemonInfoUpdated(tokenId, info);
    }

    function setOperator(address operatorAddress, bool value) public onlyOwner {
        _operators[operatorAddress] = value;
    }

    function getTokenInfo(uint256 tokenId) external override view returns (IElemonInfo.Info memory) {
        return _tokenInfos[tokenId];
    }

    function getRarity(uint256 tokenId) external override view returns (uint256) {
        return _tokenInfos[tokenId].rarity;
    }

    function getStar(uint256 tokenId) external override view returns (uint256) {
        return _tokenInfos[tokenId].star;
    }

    event ElemonInfoUpdated(uint256 tokenId, Info info);
    event ElemonStarUpdated(uint256 tokenId, uint256 star);
    event ElemonQualityUpdated(uint256 tokenId, uint256 quality);
    event ElemonClassUpdated(uint256 tokenId, uint256 class);
    event ElemonBodyPartsUpdated(uint256 tokenId, uint256[6] bodyParts);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './Context.sol';

contract Ownable is Context {
  address public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
     _owner = _msgSender();
     emit OwnershipTransferred(address(0), _msgSender());
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
  
  function _now() internal view returns (uint256) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return block.timestamp;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IElemonInfo {
    struct Info {
        uint256 rarity;
        uint256 baseCardId;
        uint256[6] bodyParts;
        uint256 quality;
        uint256 class;
        uint256 star;
    }

    function getTokenInfo(uint256 tokenId) external returns(Info memory);
    function getRarity(uint256 tokenId) external view returns(uint256);
    function getStar(uint256 tokenId) external view returns (uint256);

    function setRarity(uint256 tokenId, uint256 rarity) external;
    function setBodyParts(uint256 tokenId, uint256[6] memory bodyParts) external;
    function setQuality(uint256 tokenId, uint256 quality) external;
    function setClass(uint256 tokenId, uint256 class) external;
    function setStar(uint256 tokenId, uint256 star) external;
    function setInfo(
        uint256 tokenId,
        uint256 baseCardId,
        uint256[6] memory bodyParts,
        uint256 quality,
        uint256 class,
        uint256 rarity,
        uint256 star
    ) external;
}