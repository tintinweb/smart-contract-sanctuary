// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IWebacy.sol";

contract WebacyProxy {
    uint8 public _version;

    constructor(uint8 version) {
        _version = version;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWebacy {

  function subscribeNewAddress(address _account) external;

  function transferERC20TokensAllowed(address contractAddress, address ownerAddress, address recipentAddress, uint256 amount) external;

  function transferERC721TokensAllowed(address contractAddress, address ownerAddress, address recipentAddress, uint256 tokenId) external;

}