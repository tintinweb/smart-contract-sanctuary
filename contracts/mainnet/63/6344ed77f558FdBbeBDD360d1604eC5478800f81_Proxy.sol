//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import {IAuthority} from './interfaces/IAuthority.sol';

contract Auth {
    IAuthority public authority;
    address public owner;

    error Unauthorized();

    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);

    constructor() {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(address authority_) public auth {
        authority = IAuthority(authority_);
        emit LogSetAuthority(authority_);
    }

    modifier auth() {
        if (!isAuthorized(msg.sender, msg.sig)) {
            revert Unauthorized();
        }
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (address(authority) == address(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import {IProxyCache} from './interfaces/IProxyCache.sol';
import {Auth} from './Auth.sol';

contract Proxy is Auth {
    IProxyCache public cache;

    event WriteToCache(address target);

    error ZeroTarget();
    error SetCacheError();
    error Unsuccessful();

    constructor(address _cache) Auth() {
        setCache(_cache);
    }

    function setCache(address _cache) public auth {
        if (_cache == address(0)) {
            revert ZeroTarget();
        }
        cache = IProxyCache(_cache);
    }

    function execute(bytes calldata _code, bytes calldata _data) public payable {
        address target = cache.read(_code);
        if (target == address(0)) {
            target = cache.write(_code);
            emit WriteToCache(target);
        }
        execute(target, _data);
    }

    function execute(address _target, bytes memory _data) public payable auth {
        if (_target == address(0)) {
            revert ZeroTarget();
        }
        (bool success, ) = _target.delegatecall(_data);
        if (!success) {
            revert Unsuccessful();
        }
    }

    function executeCall(
        address _target,
        uint256 _amount,
        bytes memory _data
    ) public payable auth {
        (bool success, ) = _target.call{value: _amount}(_data);
        if (!success) {
            revert Unsuccessful();
        }
    }

    fallback() external payable {}

    receive() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IProxyCache {
    function read(bytes memory _code) external view returns (address);

    function write(bytes memory _code) external returns (address target);
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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