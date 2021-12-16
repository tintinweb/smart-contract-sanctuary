/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract GameResult {
   
    struct Record {
        string id;
        address submitter;
        uint submit_nonce;
        uint winner_score;
        uint loser_score;
        uint winner_mask;
    }

    Record[] records;

    uint nonce;

    constructor () {
        nonce = 0;
    }

    function getnonce() public view returns (uint _nonce) {
        _nonce = nonce;
    }

    function getrecords() public view returns (string memory ss) {
        ss = "begin";
        for (uint i = 0; i < records.length; i ++) {
            ss = append(ss, "^", "[", records[i].id);
            ss = append(ss, ",", string(abi.encodePacked(records[i].submitter)), ",");
            ss = append(ss, "", uint2str(records[i].submit_nonce), "]");
            ss = append(ss, uint2str(records[i].winner_mask), "(", uint2str(records[i].winner_score));
            ss = append(ss, ",", uint2str(records[i].loser_score), ")");
        }
    }

    /** 
     * @dev appendRecord is used to add records to this contract.
     * @return next_nonce the next nonce.
     */
    function appendRecord(uint _nonce, string memory _id, address _submitter, uint _submit_nonce, uint _winner_score, uint _loser_score, uint _winner_mask) public returns (uint next_nonce) {
        require(nonce == _nonce);
        Record memory r = Record(_id, _submitter, _submit_nonce, _winner_score, _loser_score, _winner_mask);
        records.push(r);
        nonce += 1;
        next_nonce =  nonce;
    }

    /** 
     * @dev Calls getRecord() function to get the record of a specific game
     * @return ss is the record in string format
     */
    function getRecord(uint _nonce, string memory _id) public view returns (string memory ss) {
        require(nonce == _nonce);
        for (uint i = 0; i < records.length; i ++) {
            if (compareStrings(records[i].id, _id)) {
                ss = append(ss, "^", "[", records[i].id);
                ss = append(ss, ",", string(abi.encodePacked(records[i].submitter)), ",");
                ss = append(ss, "", uint2str(records[i].submit_nonce), "]");
                ss = append(ss, uint2str(records[i].winner_mask), "(", uint2str(records[i].winner_score));
                ss = append(ss, ",", uint2str(records[i].loser_score), ")");
            }
        }
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function append(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));

    }

}