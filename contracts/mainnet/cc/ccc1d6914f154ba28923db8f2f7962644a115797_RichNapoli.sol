/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

pragma solidity >=0.7.0 <0.9.0;


contract RichNapoli {
    
    string message = "Rich Napoli is the best CEO ever";

    function whoIsRichN() public view returns (string memory){
        
        return message;
    }
}