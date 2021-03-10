/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

// hevm: flattened sources of src/OpynV2WhitelistMock.sol
pragma solidity =0.6.7;

////// src/OpynV2WhitelistMock.sol
/* pragma solidity 0.6.7; */

abstract contract OpynV2WhitelistLike {
    function isWhitelistedOtoken(address _otoken) external virtual view returns (bool);
}

contract OpynV2WhitelistMock is OpynV2WhitelistLike {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "not owner");
        _;
    }

    mapping (address => uint256) public whitelist;

    function toggleWhitelist(address _otoken) external ownerOnly {
        whitelist[_otoken] = (whitelist[_otoken] + 1) % 2;
    }

    function isWhitelistedOtoken(address _otoken) external view override returns (bool) {
        return whitelist[_otoken] == 1;
    }
}