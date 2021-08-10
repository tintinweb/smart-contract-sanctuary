/**
 *Submitted for verification at polygonscan.com on 2021-08-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity ^0.8.6;

interface IMachine {
  
    function runMachine(uint256 userProvidedSeed, uint256 times) external;

}
interface IERC20{
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 amount) external returns (bool);
}
interface IERC1155{
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function setApprovalForAll(address _operator, bool _approved) external;

}
contract Bulkmachine{
   function bulkRunMachine(IMachine _machine, uint256 userProvidedSeed, uint256 times) public  
   {
       
      for (uint256 i = 0; i < times; i++) {
          _machine.runMachine(userProvidedSeed,  1);
    }
  }
  function safeTransferFrom(address tokenId, address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) public{
        IERC1155(tokenId).safeTransferFrom( _from,  _to,  _id,  _value,  _data);
  }
  function safeBatchTransferFrom(address tokenId, address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) public{
        IERC1155(tokenId).safeTransferFrom( _from,  _to,  _id,  _value,  _data);
        
  }
   function setApprovalForAll(address tokenId, address _operator, bool _approved) public{
       IERC1155(tokenId).setApprovalForAll(_operator, _approved);
   }
   
   function transfer(address tokenId, address to, uint256 value) external{
       IERC20(tokenId).transfer(to,value);
   }
   function transferFrom(address tokenId, address from, address to, uint256 value) external{
       IERC20(tokenId).transferFrom(from, to,value);
   }
   function approve(address tokenId, address spender, uint256 amount) external{
       IERC20(tokenId).approve(spender, amount);
   }
}