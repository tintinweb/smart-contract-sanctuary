/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/**
 * @title WriteOnBlockchain
 * @dev Write a text on the blockchain
 */
contract WriteOnBlockchain {
    string text;
    //string head_log = "El ultimo artista retratista dijo: ";

    /**
     * @dev write message in local variable
     * @param _text message to write
     */
    function write(string calldata _text) public {
        //text = abi.encodePacked(head_log, _text);
        text = string(abi.encodePacked("El ultimo artista retratista dijo: ", _text));
    }

    /**
     * @dev Return text 
     * @return value of 'text'
     */
    function read() public view returns (string memory){
        return text;
    }
}