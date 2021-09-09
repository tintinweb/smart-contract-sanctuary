/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

interface IERC1155 {
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
}

contract NftDistributor {
  function distribute(IERC1155 nft, address[] memory to, uint[] memory ids, uint[] memory amounts) public {
    for(uint i = 0; i < to.length; i++) {
      nft.safeTransferFrom(msg.sender, to[i], ids[i], amounts[i], "0x");
    }
  }
}