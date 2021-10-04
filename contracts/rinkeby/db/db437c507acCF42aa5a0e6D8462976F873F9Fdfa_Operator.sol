// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

interface IERC721{

    function createCollectible(address from, string memory tokenURI, uint256 fee) external returns (uint256);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC1155{

    function mint(address from, string memory uri, uint256 supply, uint256 fee) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;


}
contract Operator {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    address public owner;
    mapping(address => bool) private celebrityAdmin;
    mapping(address => bool) private mintors;
    constructor () {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMinters() {
        require(mintors[msg.sender],"Minter: caller doesn't have minter Role");
        _;
    }
    function ownerTransfership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function addCelebrityAdmin(address _celebrityAdmin) public onlyOwner returns(bool) {
        require(!celebrityAdmin[_celebrityAdmin], "Celebrity Admin already exist");
        celebrityAdmin[_celebrityAdmin] = true;
        return true;
    }

    function removeCelebrityAdmin(address _celebrityAdmin) public onlyOwner returns(bool) {
        require(celebrityAdmin[_celebrityAdmin], "Celebrity Admin does not exist");
        celebrityAdmin[_celebrityAdmin] = false;
        return true;
    }
    
    function isCelebrityAdmin(address _celebrityAdmin) view public returns(bool) {
        return celebrityAdmin[_celebrityAdmin];
    }
    
    function addMintor(address _mintor) public returns(bool) {
        require(celebrityAdmin[msg.sender], "Only celebrity admin can add mintor");
        require(!mintors[_mintor], "Mintor already exist");
        mintors[_mintor] = true;
        return true;
    }
    
    function removeMintor(address _mintor) public returns(bool) {
        require(celebrityAdmin[msg.sender], "Only celebrity admin can remove mintor");
        require(mintors[_mintor], "Mintor does not exist");
        mintors[_mintor] = false;
        return true;
    }

    function mintSingle(address nftAddress, address from, string memory tokenURI, uint256 fee) public onlyMinters returns(bool) {
        IERC721(nftAddress).createCollectible(from, tokenURI, fee);
        return true;
    }

    function mintMultiply(address nftAddress, address from, string memory tokenURI, uint256 fee, uint256 supply) public onlyMinters returns(bool) {
        IERC1155(nftAddress).mint(from, tokenURI, supply, fee);
        return true;
    }

    function safeTransferMultiply(address nftAddress, uint256 tokenId, address[] memory receivers, uint256[] memory supplys) public onlyMinters returns(bool) {
        require(receivers.length == supplys.length, "ERC1155: ids and amounts length mismatch");
        for(uint i = 0; i < receivers.length; i++) {
            IERC1155(nftAddress).safeTransferFrom(address(this), receivers[i], tokenId, supplys[i], " ");
        }

        return true;
    }

    function safeTransfersingle(address nftAddress, uint256 tokenId, address to) public onlyMinters returns(bool) {
        require(to != address(0), "receiver address should not be zero address");
        IERC721(nftAddress).safeTransferFrom(address(this), to, tokenId, " ");
        return true;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}