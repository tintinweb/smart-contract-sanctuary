/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

pragma solidity >=0.4.21 <0.7.0;

contract Document {
    string public documentTitle;
    string public documentURL;
    address public documentOwner;

    constructor(string memory title, string memory url) public {
        documentTitle = title;
        documentURL = url;
        documentOwner = msg.sender;
    }
}