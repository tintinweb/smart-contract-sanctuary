// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;



contract Contributor{
    
  
     event Response(bool success, bytes data);
    
    function contribute(address _addr, string memory _name) public payable{
         (bool success, bytes memory data) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("contribute(string)", _name)
        );
        emit Response(success, data);
    }
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns(bytes4){
         return 0xf0b9e5ba;
     }
   
}