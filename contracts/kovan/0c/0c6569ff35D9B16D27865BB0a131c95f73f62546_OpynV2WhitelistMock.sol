// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

abstract contract OpynV2WhitelistLike {
    function isWhitelistedOtoken(address _otoken) external view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7 <=0.7.6;

import '../interfaces/OpynV2WhitelistLike.sol';

contract OpynV2WhitelistMock is OpynV2WhitelistLike {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, 'not owner');
        _;
    }

    mapping(address => uint256) public whitelist;

    function toggleWhitelist(address _otoken) external ownerOnly {
        whitelist[_otoken] = (whitelist[_otoken] + 1) % 2;
    }

    function isWhitelistedOtoken(address _otoken) external view override returns (bool) {
        return whitelist[_otoken] == 1;
    }
}