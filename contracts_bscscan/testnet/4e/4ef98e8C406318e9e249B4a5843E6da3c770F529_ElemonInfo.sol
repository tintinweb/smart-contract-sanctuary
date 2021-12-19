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
        _tokenInfos[tokenId].rarity = rarity;
        emit ElemonInfoUpdated(tokenId, _tokenInfos[tokenId]);
    }

    function setBodyParts(uint256 tokenId, uint256[6] memory bodyParts) external override onlyOperator {
        require(bodyParts.length == 6, "Invalid bodyPart length");
        _tokenInfos[tokenId].bodyParts = bodyParts;
        emit ElemonInfoUpdated(tokenId, _tokenInfos[tokenId]);
    }

    function setQuality(uint256 tokenId, uint256 quality) external override onlyOperator {
        _tokenInfos[tokenId].quality = quality;
        emit ElemonInfoUpdated(tokenId, _tokenInfos[tokenId]);
    }

    function setClass(uint256 tokenId, uint256 class) external override onlyOperator {
        _tokenInfos[tokenId].class = class;
        emit ElemonInfoUpdated(tokenId, _tokenInfos[tokenId]);
    }

    function setStar(uint256 tokenId, uint256 star) external override onlyOperator {
        _tokenInfos[tokenId].star = star;
        emit ElemonInfoUpdated(tokenId, _tokenInfos[tokenId]);
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

    function getTokenInfoValues(uint256 tokenId) external override view 
    returns (uint256 rarity, uint256 baseCardId, uint256[] memory bodyParts, uint256 quality, uint256 class, uint256 star) {
        IElemonInfo.Info memory tokenInfo = _tokenInfos[tokenId];
        rarity =  tokenInfo.rarity;
        baseCardId =  tokenInfo.baseCardId;
        bodyParts = new uint256[](tokenInfo.bodyParts.length);
        for (uint256 index = 0; index < tokenInfo.bodyParts.length; index++) {
            bodyParts[index] = tokenInfo.bodyParts[index];
        }
        quality =  tokenInfo.quality;
        class =  tokenInfo.class;
        star =  tokenInfo.star;
    }

    function getRarity(uint256 tokenId) external override view returns (uint256) {
        return _tokenInfos[tokenId].rarity;
    }

    function getBaseCardId(uint256 tokenId) external override view returns (uint256) {
        return _tokenInfos[tokenId].baseCardId;
    }

    function getBodyPart(uint256 tokenId) external override view returns (uint256[] memory) {
        IElemonInfo.Info memory tokenInfo = _tokenInfos[tokenId];
        uint256[] memory bodyParts = new uint256[](tokenInfo.bodyParts.length);
        for (uint256 index = 0; index < tokenInfo.bodyParts.length; index++) {
            bodyParts[index] = tokenInfo.bodyParts[index];
        }
        return bodyParts;
    }

    function getQuality(uint256 tokenId) external override view returns (uint256) {
        return _tokenInfos[tokenId].quality;
    }

    function getClass(uint256 tokenId) external override view returns (uint256) {
        return _tokenInfos[tokenId].class;
    }

    function getStar(uint256 tokenId) external override view returns (uint256) {
        return _tokenInfos[tokenId].star;
    }

    event ElemonInfoUpdated(uint256 tokenId, Info info);
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
    function getTokenInfoValues(uint256 tokenId) external view 
        returns (uint256 rarity, uint256 baseCardId, uint256[] memory bodyParts, uint256 quality, uint256 class, uint256 star);
    function getRarity(uint256 tokenId) external view returns(uint256);
    function getBaseCardId(uint256 tokenId) external view returns (uint256);
    function getBodyPart(uint256 tokenId) external view returns (uint256[] memory);
    function getQuality(uint256 tokenId) external view returns (uint256);
    function getClass(uint256 tokenId) external view returns (uint256);
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