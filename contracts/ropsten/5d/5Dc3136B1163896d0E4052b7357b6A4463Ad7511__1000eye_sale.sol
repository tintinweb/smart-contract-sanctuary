/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.5.16;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract Ownable {
  address public owner;

    constructor() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract _1000eye_sale is Ownable {

    event Sale1000(uint256 indexed tokenId,address indexed owner);
    

    
    address[] public sales;

    uint256 public totalsale;
    IERC721 public erc721_1000;

  
    
    uint256 constant ALEN=1000;





    constructor(address _1000eye)
        public
    {
         erc721_1000=IERC721(_1000eye);
    }
    
    function  buy() external 
     payable {
        require(msg.value==1 ether, "MUST_1_ETHER_ONLY");
        require(totalsale<ALEN, "1000_SOLD_OUT");

        totalsale=sales.push(msg.sender);
        erc721_1000.safeTransferFrom(erc721_1000.ownerOf(totalsale), msg.sender,totalsale);
        emit Sale1000(totalsale,msg.sender);

    }

    
    function collect(address bene) external onlyOwner {
        uint256 balance=address(this).balance;
        (bool success, ) =address(uint160(bene)).call.value(balance)("");
        require(success,"ERR contract transfer eth to pool fail,maybe gas fail");
    }

}