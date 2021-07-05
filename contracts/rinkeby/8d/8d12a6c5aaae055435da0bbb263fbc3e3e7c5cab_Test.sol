/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

contract Test{
    // Intializing the state variable
    uint _randNonce = 0;
          
    function _getRandomNumber(uint256 modulus) public returns(uint){
           // increase nonce
           _randNonce++;  
           return uint(keccak256(abi.encodePacked(block.timestamp, 
                                                  msg.sender, 
                                                  _randNonce))) % modulus;
    }
}