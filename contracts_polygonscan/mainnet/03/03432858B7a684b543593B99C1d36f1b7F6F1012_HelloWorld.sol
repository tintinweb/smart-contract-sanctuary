// SPDX-License-Identifier: MIT
//import "./XtfContract.sol";
pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    //XtfContract extInstance = XtfContract(0xB8C430B0E8644C2EbF6c8502fb2f6159Bb976a00);

    function sayHello() public pure returns(string memory){
        return "OK"; 
    }
    /*function say(uint256 tokenId) public view  returns(string memory){
        return extInstance.tokenURI(tokenId); 
    }*/
}