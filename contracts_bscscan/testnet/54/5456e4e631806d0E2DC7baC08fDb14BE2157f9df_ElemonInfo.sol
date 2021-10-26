//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './utils/Ownable.sol';

contract ElemonInfo is Ownable {
    struct Info{
        uint256 rarity;
        uint256 baseCardId;
        uint256 bodyPart01;
        uint256 bodyPart02;
        uint256 bodyPart03;
        uint256 bodyPart04;
        uint256 bodyPart05;
        uint256 bodyPart06;
        uint256 quality;
    }

    mapping(uint256 => Info) public _tokenInfos;

    function setInfo(uint256 tokenId, uint256 rarity, uint256 baseCardId,
        uint256 bodyPart01, uint256 bodyPart02, uint256 bodyPart03, uint256 bodyPart04,
        uint256 bodyPart05, uint256 bodyPart06, uint256 quality) external onlyOwner{
            Info memory info = Info({
                rarity: rarity,
                baseCardId: baseCardId,
                bodyPart01: bodyPart01,
                bodyPart02: bodyPart02,
                bodyPart03: bodyPart03,
                bodyPart04: bodyPart04,
                bodyPart05: bodyPart05,
                bodyPart06: bodyPart06,
                quality: quality
            });
            _tokenInfos[tokenId] = info;
            emit ElemonInfoUpdated(tokenId, info);
    }

    event ElemonInfoUpdated(uint256 tokenId, Info info);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './Context.sol';

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    _owner = _msgSender();
    emit OwnershipTransferred(address(0), _msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
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