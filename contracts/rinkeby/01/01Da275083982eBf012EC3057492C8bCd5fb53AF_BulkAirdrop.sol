// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// an interface decleares the methods
interface IERC20 {
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   function balanceOf(address account) external view returns (uint256);
   function allowance(address owner, address spender) external view returns (uint256);
// copy functions from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
}

interface IERC721 {
   function safeTransferFrom( address from, address to, uint256 tokenId ) external;
}

interface IERC1155 {
   function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data ) external;
}

contract BulkAirdrop {
   constructor() {}

   // bulkAirdropERC20 inputs:
	// _token = token address
	// _to = address we're sending to
	// _value = how many tokens we are sending
   function bulkAirdropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value) public {
      require (_to.length == _value.length, "Receiver and amounts are different lenght.");
      for (uint256 i = 0; i< _to.length; i++) {
	 require(_token.transferFrom(msg.sender, _to[i], _value[i]));
      }
   }

   function bulkAirdropERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _id) public {
   require (_to.length == _id.length, "Receiver and IDs are different lenght.");
      for (uint256 i = 0; i< _to.length; i++) {
	 _token.safeTransferFrom(msg.sender, _to[i], _id[i]);
      }
   }

   function bulkAirdropERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _id, uint256[] calldata _amount) public {
   require (_to.length == _id.length, "Receiver and IDs are different lenght.");
      for (uint256 i = 0; i< _to.length; i++) {
	 _token.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");
      }
   }
}