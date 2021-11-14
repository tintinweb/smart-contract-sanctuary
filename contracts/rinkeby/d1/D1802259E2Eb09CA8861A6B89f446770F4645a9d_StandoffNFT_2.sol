// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.4.25;

interface IERC1155 {
  function safeTransferFrom(
      address from,
      address to,
      uint256 id,
      uint256 amount,
      bytes data
  ) external;
}

contract Ownable {
    address owner;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function setOwner(address _owner) external {
      require(owner == msg.sender || owner == 0x0);
      owner = _owner;
    }
}

contract StandoffNFT_2 is Ownable {
    address owner;
    IERC1155 public collection;
    uint256 public TOKEN_ID = 1;

    constructor(IERC1155 _collection){
        owner = msg.sender; // set owner
        collection = _collection;
    }

    function withdraw() onlyOwner external {
        collection.safeTransferFrom(address(this), msg.sender, TOKEN_ID, 1, "");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
      return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}