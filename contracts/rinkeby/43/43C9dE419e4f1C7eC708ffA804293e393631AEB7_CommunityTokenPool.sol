// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Transfer.sol";

contract CommunityTokenPool {
  IERC721Transfer public monsterBlocks = IERC721Transfer(0xE2a00e6D0be0FdEB627fBAC644B67D4C5845912D);

  mapping (address => uint256) private _balances;

  function balanceOf(address owner) public view virtual returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  function depositOne(uint256 _tokenId) public {
    monsterBlocks.transferFrom(msg.sender, address(this), _tokenId);
    _balances[msg.sender] += 1;
  }

  function deposit(uint256[] memory _tokenIds) public {
    require(_tokenIds.length <= 10);
    _deposit(_tokenIds);
  }

  function redeemOne(uint256 _tokenId) public {
    require(_balances[msg.sender] > 0);
    _balances[msg.sender] -= 1;
    monsterBlocks.transferFrom(address(this), msg.sender, _tokenId);
  }

  function redeem(uint256[] memory _tokenIds) public {
    require(_tokenIds.length <= 10);
    _redeem(_tokenIds);
  }

  function depositAndRedeem(uint256[] memory _depositTokenIds, uint256[] memory _redeemTokenIds) public {
    require(_depositTokenIds.length <= 10);
    require(_depositTokenIds.length == _redeemTokenIds.length);

    __deposit(_depositTokenIds);
    __redeem(_redeemTokenIds);
  }

  /* Internal Helpers */

  function _deposit(uint256[] memory _tokenIds) internal {
    __deposit(_tokenIds);

    _balances[msg.sender] += _tokenIds.length;
  }

  function _redeem(uint256[] memory _tokenIds) internal {
    require(_balances[msg.sender] >= _tokenIds.length);

    _balances[msg.sender] -= _tokenIds.length;

    __redeem(_tokenIds);
  }

  function __deposit(uint256[] memory _tokenIds) internal {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      monsterBlocks.transferFrom(msg.sender, address(this), _tokenIds[i]);
    }
  }

  function __redeem(uint256[] memory _tokenIds) internal {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      monsterBlocks.transferFrom(address(this), msg.sender, _tokenIds[i]);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Transfer {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 5
  },
  "evmVersion": "petersburg",
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