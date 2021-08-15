// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Random is Ownable {
  uint256 private key;
  uint256 private nonce;

  constructor(uint256 _key) {
    key = _key;
  }

  function addNonce() private {
    nonce = ++nonce;
  }

  function getCoinbase() private view returns(address) {
    return block.coinbase;
  }

  function getDifficulty() private view returns(uint256) {
    return block.difficulty;
  }

  function getGaslimit() private view returns(uint256) {
    return block.gaslimit;
  }

  function getNumber() private view returns(uint256) {
   return block.number;
  }

  function getBlockhash1() private view returns(bytes32) {
    return blockhash(block.number - 1);
  }

  function getBlockhash2() private view returns(bytes32) {
    return blockhash(block.number - 2);
  }

  function getBlockhash3() private view returns(bytes32) {
    return blockhash(block.number - 3);
  }

  function getBlockhash4() private view returns(bytes32) {
    return blockhash(block.number - 4);
  }

  function getBlockhash5() private view returns(bytes32) {
    return blockhash(block.number - 5);
  }

  function getTimestamp() private view returns(uint256) {
    return block.timestamp;
  }

  function getData() private pure returns(bytes calldata) {
    return msg.data;
  }

  function getSender() private view returns(address) {
    return msg.sender;
  }

  function getSig() private pure returns(bytes4) {
    return msg.sig;
  }

  function getOrigin() private view returns(address) {
    return tx.origin;
  }

  function encodeMessageData() private view returns(bytes memory) {
    return abi.encodePacked(getData(), getSender(), getSig());
  }

  function A8cf9be874ceefa20f0edbc6d3672c92e058b5703579bf8cc0092763eb913f2eb94b08e0df425f02a0e182335b32c9142f9ad26c6badafcf23f7284f6d600bdde9a08faff17f7f303c1c1063ef141c7aa18c9f8c4d1089397a1005c013c4e165cb55f502c2478b56603768eff9ce17afec7ae4b4e9ef5e7214f11a05382170524d1450d12b38ca252065572b70bd4de9e06afb7ba8d4a45715adde4608ec402358b81b3c2fd2d6cac3acaadbda58b4beb0da4fe77c481197151976dafb2f37ae1652e3ad2ae13583c2839720016c3ca9e9effe305d4fbb743a9b188ab6c7ad2a08096ecfa2b9e4c8d2364998baf954b8ab311ff92c894c5bec269a7fcca1fdbc022ad34b59377cd3d8f127e87d9daca4cff6cb038144b6237c166e5f51cb7417ff698281bf223fef00105550ea55245051d5e6189b242a4cff9d87a34d0c5be4363bf9ae3bb0211ca09902ef09b54dd80098e08a90b7e80d7757efa306c3e1b1fccb519908372b345e3114f66f122c2b85b321bd3bb9a0784db519ab77591bfaadebae05528f8de2c918a33bbb59f7a8832ec77cdf95e097e76cf6597ab2ba7fe845c22d06b29f316e17a89d5f932bfd84f3896dd0b448c2ba4ba83faee5a7e03183d392c7df1df15656dccc86fc50b02026e6a6bcfa848701a634f9aaf08d6e() private {
    addNonce();

    key = uint256(keccak256(abi.encodePacked(
          key,
          getCoinbase(),
          getDifficulty(),
          getGaslimit(),
          getNumber(),
          getBlockhash1(),
          getBlockhash2(),
          getBlockhash3(),
          getBlockhash4(),
          getBlockhash5(),
          getTimestamp(),
          encodeMessageData(),
          getOrigin(),
          nonce)));
  }

  function rand(uint256 _range) onlyOwner public returns(uint256) {
    regenerateHash();
    return key % _range;
  }

  function regenerateHash() onlyOwner public {
    A8cf9be874ceefa20f0edbc6d3672c92e058b5703579bf8cc0092763eb913f2eb94b08e0df425f02a0e182335b32c9142f9ad26c6badafcf23f7284f6d600bdde9a08faff17f7f303c1c1063ef141c7aa18c9f8c4d1089397a1005c013c4e165cb55f502c2478b56603768eff9ce17afec7ae4b4e9ef5e7214f11a05382170524d1450d12b38ca252065572b70bd4de9e06afb7ba8d4a45715adde4608ec402358b81b3c2fd2d6cac3acaadbda58b4beb0da4fe77c481197151976dafb2f37ae1652e3ad2ae13583c2839720016c3ca9e9effe305d4fbb743a9b188ab6c7ad2a08096ecfa2b9e4c8d2364998baf954b8ab311ff92c894c5bec269a7fcca1fdbc022ad34b59377cd3d8f127e87d9daca4cff6cb038144b6237c166e5f51cb7417ff698281bf223fef00105550ea55245051d5e6189b242a4cff9d87a34d0c5be4363bf9ae3bb0211ca09902ef09b54dd80098e08a90b7e80d7757efa306c3e1b1fccb519908372b345e3114f66f122c2b85b321bd3bb9a0784db519ab77591bfaadebae05528f8de2c918a33bbb59f7a8832ec77cdf95e097e76cf6597ab2ba7fe845c22d06b29f316e17a89d5f932bfd84f3896dd0b448c2ba4ba83faee5a7e03183d392c7df1df15656dccc86fc50b02026e6a6bcfa848701a634f9aaf08d6e();
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

/*
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
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}