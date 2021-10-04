// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Transfer {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

/*
  __  __  ____  _   _  _____ _______ ______ _____
 |  \/  |/ __ \| \ | |/ ____|__   __|  ____|  __ \
 | \  / | |  | |  \| | (___    | |  | |__  | |__) |
 | |\/| | |  | | . ` |\___ \   | |  |  __| |  _  /
 | |  | | |__| | |\  |____) |  | |  | |____| | \ \
 |_|  |_|\____/|_| \_|_____/   |_|  |______|_|  \_\

     __  __          _____  _  ________ _______
    |  \/  |   /\   |  __ \| |/ /  ____|__   __|
    | \  / |  /  \  | |__) | ' /| |__     | |
    | |\/| | / /\ \ |  _  /|  < |  __|    | |
    | |  | |/ ____ \| | \ \| . \| |____   | |
    |_|  |_/_/    \_\_|  \_\_|\_\______|  |_|


               Contract written by:
     ____       _          _     _           _
    / __ \  ___| |__  _ __(_)___| |__   ___ | |
   / / _` |/ __| '_ \| '__| / __| '_ \ / _ \| |
  | | (_| | (__| | | | |  | \__ \ | | | (_) | |
   \ \__,_|\___|_| |_|_|  |_|___/_| |_|\___/|_|
    \____/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC721Transfer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MonsterMarket is ReentrancyGuard {
  IERC721Transfer public monsterBlocks = IERC721Transfer(0xa56a4f2b9807311AC401c6afBa695D3B0C31079d);

  /* Balance Functions */

  mapping (address => uint256) private _balances;

  function balanceOf(address _owner) public view virtual returns (uint256) {
    require(_owner != address(0), "Balance query for the zero address");
    return _balances[_owner];
  }

  function transferBalance(address _to) public nonReentrant {
    require(msg.sender != _to, "No transfer required");

    uint256 balanceToTransfer = _balances[msg.sender];
    require(balanceToTransfer > 0, "No balance to transfer");

    _balances[msg.sender] = 0;
    _balances[_to] = balanceToTransfer;
  }

  /* Deposit and Redemption Functions */

  uint256 public maxTransactionSize = 10;

  function depositOne(uint256 _tokenId) public {
    monsterBlocks.transferFrom(msg.sender, address(this), _tokenId);
    _balances[msg.sender] += 1;
  }

  function depositMany(uint256[] memory _tokenIds) public {
    require(_tokenIds.length <= maxTransactionSize);
    _deposit(_tokenIds);
  }

  function redeemOne(uint256 _tokenId) public nonReentrant {
    require(_balances[msg.sender] > 0);
    _balances[msg.sender] -= 1;
    monsterBlocks.transferFrom(address(this), msg.sender, _tokenId);
  }

  function redeemMany(uint256[] memory _tokenIds) public nonReentrant {
    require(_tokenIds.length <= maxTransactionSize);
    _redeem(_tokenIds);
  }

  function depositAndRedeemOne(uint256 _depositTokenId, uint256 _redeemTokenId) public nonReentrant {
    monsterBlocks.transferFrom(msg.sender, address(this), _depositTokenId);
    monsterBlocks.transferFrom(address(this), msg.sender, _redeemTokenId);
  }

  function depositAndRedeemMany(uint256[] memory _depositTokenIds, uint256[] memory _redeemTokenIds) public nonReentrant {
    require(_depositTokenIds.length <= maxTransactionSize);
    require(_depositTokenIds.length == _redeemTokenIds.length);

    __deposit(_depositTokenIds);
    __redeem(_redeemTokenIds);
  }

  /* Internal Helper Functions */

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
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