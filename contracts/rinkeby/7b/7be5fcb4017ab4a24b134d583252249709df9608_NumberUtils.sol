/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

contract NumberUtils{
    // Intializing the state variable
    uint _randNonce = 0;
    
    uint public randomNumber;
          
    function getRandomNumber(uint256 modulus) public returns(uint){
           // increase nonce
           _randNonce++;  
           randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, 
                                                  msg.sender, 
                                                  _randNonce))) % modulus;
           return randomNumber;
    }
}