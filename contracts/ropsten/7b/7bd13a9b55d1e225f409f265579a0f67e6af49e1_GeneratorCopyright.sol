/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title GeneratorCopyright
 * @author BEP20 Generator (https://lgctoken.com)
 * @dev Implementation of the GeneratorCopyright
 */
contract GeneratorCopyright {

    string private constant _GENERATOR = "https://lgctoken.com";
    string private _version;

    constructor (string memory version_) {
        _version = version_;
    }

    /**
     * @dev Returns the token generator tool.
     */
    function generator() public pure returns (string memory) {
        return _GENERATOR;
    }

    /**
     * @dev Returns the token generator version.
     */
    function version() public view returns (string memory) {
        return _version;
    }
}