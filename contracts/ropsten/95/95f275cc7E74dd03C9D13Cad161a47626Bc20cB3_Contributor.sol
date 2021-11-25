/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// File: contracts/contribtor.sol



pragma solidity ^0.8.3;



contract Contributor{
    
  
     event Response(bool success, bytes data);
    
    function contribute(address _addr, uint _id) public payable{
         (bool success, bytes memory data) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("contribute(uint256)", _id)
        );
        emit Response(success, data);
    }
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns(bytes4){
         return 0xf0b9e5ba;
     }
   
}