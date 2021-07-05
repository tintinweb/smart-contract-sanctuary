/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

contract Test{
    
    uint[] public values;
    
    // Intializing the state variable
    uint _randNonce = 0;
          
    function _getRandomNumber(uint256 modulus) public{
           // increase nonce
           _randNonce++;  
           values.push(uint(keccak256(abi.encodePacked(block.timestamp, 
                                                  msg.sender, 
                                                  _randNonce))) % modulus);
                                                  
    }
}