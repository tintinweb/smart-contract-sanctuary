/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// File: contracts/ISalt.sol

// spd-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.8;

interface ISalt {
    function startDate() external view returns (uint256);
    function rawURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/SaltTokenURI.sol

// spd-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.8;


contract SaltTokenURI {

  ISalt public salt;

  constructor(address a) public {
    salt = ISalt(a);
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    if (salt.startDate() == 0) {
      return salt.rawURI(tokenId);
    }
    else {
      uint256 daysPassed = ((block.timestamp - salt.startDate()) % 180 days) / 1 days;
      return salt.rawURI((tokenId + daysPassed) % 180);
    }
  }
}