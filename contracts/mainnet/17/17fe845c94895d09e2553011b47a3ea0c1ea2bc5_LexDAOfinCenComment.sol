/**
 *Submitted for verification at Etherscan.io on 2021-01-04
*/

pragma solidity 0.8.0;
// SPDX-License-Identifier: GPL-3.0-or-later
contract LexDAOfinCenComment {
    string constant public comment = "https://gateway.pinata.cloud/ipfs/Qmc55RGSvUmmpGYUKQuEDj4VYLxPcwHkj8SfSJNhDKYR7i";
    
    function donateToLexDAO() external payable { // donate some ETH to LexDAO Corps.
        (bool success, ) = 0x01B92E2C0D06325089c6Fd53C98a214f5C75B2aC.call{value: msg.value}("");
        require(success, "!ethCall");
    }
}