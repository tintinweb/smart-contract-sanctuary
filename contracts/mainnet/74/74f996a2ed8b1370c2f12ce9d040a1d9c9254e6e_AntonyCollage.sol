/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.8.0;

contract AntonyCollage {
    /* 
    * sha256 of original full image Antony Collage. Created using Python hashlib.
    */
    bytes32 public fullImgHash = 0x7a292346c200c7e46714489a1fbe10fcee47476d93f4080a71d275c40644a3f7;
    
    /* 
    * sha256 of secret phrase embeded in an Antony Collage Parts and encrypted by key. 
    * The first one to reveal the passphrase gets ownership of the Antony Collage after calling the reveal() function.
    */
    bytes32 public hashOfSecret = 0x59ce1e9545744b2b56590c37a7ea621c28ea7896eb92d8c1c6dcb80ee9390e4e;
    
    /* 
    * Antony Collage one and only one owner
    */
    address public owner;
    
    bool public ownershipTransferred = false;
    
    constructor() {
        owner = msg.sender;
    }
    
    function reveal(string memory _passphrase) public {
        require(!ownershipTransferred, "No more bro :)");
        require(hashOfSecret == keccak256(abi.encodePacked(_passphrase)), "Ooops ;)");
        ownershipTransferred = true;
        owner = msg.sender;
    }
}