/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// YOURBASTARDYOURCALLHelper v0.9.0
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to 0x5316f4B2AAE5E15366C7130b54eFf59C81e7a9CE
// 
// SPDX-License-Identifier: MIT
//
// Enjoy. And hello, from the past.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2021. The MIT Licence.
// ----------------------------------------------------------------------------

interface IYOURBASTARDYOURCALL {
    function showLicenseForBASTARD(uint8 _version, uint _id) external view returns(string memory);
}


contract YOURBASTARDYOURCALLHelper {
    IYOURBASTARDYOURCALL public constant ybyc = IYOURBASTARDYOURCALL(0x9602874e70fA093793cadAc9D0C392F80E3A80e0);
    
    function getMetadata(uint8 version, uint from, uint to) external view returns(string[] memory _metadatas) {
        require(from < to);
        uint length = to - from;
        _metadatas = new string[](length);

        uint i = 0;
        for (uint index = from; index < to; index++) {
            (_metadatas[i]) = ybyc.showLicenseForBASTARD(version, index);
            i++;
        }
    }
}