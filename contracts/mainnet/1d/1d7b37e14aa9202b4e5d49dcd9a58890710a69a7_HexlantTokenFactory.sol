/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface HexlantToken {
  function initialize(
    address _owner,
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 _supply
  ) external;
}

abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

abstract contract CloneFactory {
  function clone(address implementation, bytes32 salt) internal returns (address instance) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, implementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      instance := create2(0, ptr, 0x37, salt)
    }
    require(instance != address(0), "ERC1167: create2 failed");
  }

  function computeClone(
    address implementation,
    bytes32 salt,
    address deployer
  ) internal pure returns (address computed) {
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, implementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
      mstore(add(ptr, 0x38), shl(0x60, deployer))
      mstore(add(ptr, 0x4c), salt)
      mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
      computed := keccak256(add(ptr, 0x37), 0x55)
    }
  }
}

abstract contract TokenSpecStorage is Ownable {
  string private _DEFAULT = "DEFAULT";
  string private _LOCK = "LOCK";
  string private _PAUSE = "PAUSE";
  string private _FREEZE = "FREEZE";
  string private _UPGRADE = "UPGRADE";
  string private _MINT = "MINT";
  string private _BURN = "BURN";

  mapping(string => address) internal _implementationBySpecKey;

  function isLockable(bool _lock) internal view returns (string memory) {
    return _lock ? _LOCK : "";
  }

  function isPausable(bool _pause) internal view returns (string memory) {
    return _pause ? _PAUSE : "";
  }

  function isFreezable(bool _freeze) internal view returns (string memory) {
    return _freeze ? _FREEZE : "";
  }

  function isUpgradable(bool _upgrade) internal view returns (string memory) {
    return _upgrade ? _UPGRADE : "";
  }

  function isMintable(bool _mint) internal view returns (string memory) {
    return _mint ? _MINT : "";
  }

  function isBurnable(bool _burn) internal view returns (string memory) {
    return _burn ? _BURN : "";
  }

  function getTokenSpecKey(
    bool _lock,
    bool _pause,
    bool _freeze,
    bool _upgrade,
    bool _mint,
    bool _burn
  ) internal view returns (string memory) {
    string[7] memory specs;

    specs[0] = _DEFAULT;
    specs[1] = isLockable(_lock);
    specs[2] = isPausable(_pause);
    specs[3] = isFreezable(_freeze);
    specs[4] = isUpgradable(_upgrade);
    specs[5] = isMintable(_mint);
    specs[6] = isBurnable(_burn);

    return string(abi.encodePacked(specs[0], specs[1], specs[2], specs[3], specs[4], specs[5], specs[6]));
  }

  function setTokenSpecImplementation(
    address _implementation,
    bool _lock,
    bool _pause,
    bool _freeze,
    bool _upgrade,
    bool _mint,
    bool _burn
  ) external onlyOwner {
    string memory specKey = getTokenSpecKey(_lock, _pause, _freeze, _upgrade, _mint, _burn);

    _implementationBySpecKey[specKey] = _implementation;
  }

  function getTokenSpecImplementation(
    bool _lock,
    bool _pause,
    bool _freeze,
    bool _upgrade,
    bool _mint,
    bool _burn
  ) public view returns (address) {
    string memory specKey = getTokenSpecKey(_lock, _pause, _freeze, _upgrade, _mint, _burn);

    return _implementationBySpecKey[specKey];
  }
}

contract HexlantTokenFactory is CloneFactory, TokenSpecStorage {
  struct TokenParams {
    address owner;
    string name;
    string symbol;
    uint8 decimals;
    uint256 supply;
  }

  function createToken(
    TokenParams memory _tokenParams,
    bool _lock,
    bool _pause,
    bool _freeze,
    bool _upgrade,
    bool _mint,
    bool _burn
  ) external onlyOwner returns (address token) {
    address implementation = getTokenSpecImplementation(_lock, _pause, _freeze, _upgrade, _mint, _burn);

    require(implementation != address(0), "not found spec implementation");

    bytes32 finalSalt = keccak256(
      abi.encodePacked(
        _tokenParams.owner,
        _tokenParams.name,
        _tokenParams.symbol,
        _tokenParams.decimals,
        _tokenParams.supply,
        _lock,
        _pause,
        _freeze,
        _upgrade,
        _mint,
        _burn
      )
    );

    token = clone(implementation, finalSalt);

    HexlantToken(token).initialize(
      _tokenParams.owner,
      _tokenParams.name,
      _tokenParams.symbol,
      _tokenParams.decimals,
      _tokenParams.supply
    );
  }

  function getTokenAddress(
    TokenParams memory _tokenParams,
    bool _lock,
    bool _pause,
    bool _freeze,
    bool _upgrade,
    bool _mint,
    bool _burn
  ) external view returns (address wallet) {
    address implementation = getTokenSpecImplementation(_lock, _pause, _freeze, _upgrade, _mint, _burn);

    bytes32 finalSalt = keccak256(
      abi.encodePacked(
        _tokenParams.owner,
        _tokenParams.name,
        _tokenParams.symbol,
        _tokenParams.decimals,
        _tokenParams.supply,
        _lock,
        _pause,
        _freeze,
        _upgrade,
        _mint,
        _burn
      )
    );

    return computeClone(implementation, finalSalt, address(this));
  }
}