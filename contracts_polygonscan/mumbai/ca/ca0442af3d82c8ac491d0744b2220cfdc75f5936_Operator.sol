/**
 *Submitted for verification at polygonscan.com on 2021-10-19
*/

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

interface IERC721 {

    function createCollectible(uint256 tokenId, string memory tokenURI, uint256 fee) external returns (uint256);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {

    function mint(uint256 tokenId, string memory uri, uint256 supply, uint256 fee) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;


}
contract Operator {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event MintorAdded(address indexed mintor);

    event MintorRemoved(address indexed mintor);

    event CelebrityAdminAdded(address indexed admin);

    event CelebrityAdminRemoved(address indexed admin);


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
        emit CelebrityAdminAdded(_celebrityAdmin);
        return true;
    }

    function removeCelebrityAdmin(address _celebrityAdmin) public onlyOwner returns(bool) {
        require(celebrityAdmin[_celebrityAdmin], "Celebrity Admin does not exist");
        celebrityAdmin[_celebrityAdmin] = false;
        emit CelebrityAdminRemoved(_celebrityAdmin);
        return true;
    }
    
    function isCelebrityAdmin(address _celebrityAdmin) view public returns(bool) {
        return celebrityAdmin[_celebrityAdmin];
    }
    
    function addMintor(address _mintor) public returns(bool) {
        require(celebrityAdmin[msg.sender], "Only celebrity admin can add mintor");
        require(!mintors[_mintor], "Mintor already exist");
        mintors[_mintor] = true;
        emit MintorAdded(_mintor);
        return true;
    }
    
    function removeMintor(address _mintor) public returns(bool) {
        require(celebrityAdmin[msg.sender], "Only celebrity admin can remove mintor");
        require(mintors[_mintor], "Mintor does not exist");
        mintors[_mintor] = false;
        emit MintorRemoved(_mintor);
        return true;
    }

    function mintSingle(address nftAddress, uint256 tokenId, string memory tokenURI, uint256 fee) public onlyMinters returns(bool) {
        IERC721(nftAddress).createCollectible(tokenId, tokenURI, fee);
        return true;
    }

    function mintMultiple(address nftAddress, uint256 tokenId, string memory tokenURI, uint256 fee, uint256 supply) public onlyMinters returns(bool) {
        IERC1155(nftAddress).mint(tokenId, tokenURI, supply, fee);
        return true;
    }

    function safeTransferMultiple(address nftAddress, address from, uint256 tokenId, address[] memory receivers, uint256[] memory amounts) public onlyMinters returns(bool) {
        require(receivers.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        for(uint i = 0; i < receivers.length; i++) {
            IERC1155(nftAddress).safeTransferFrom(from, receivers[i], tokenId, amounts[i], "");
        }

        return true;
    }

    function safeTransferSingle(address nftAddress, address from, uint256 tokenId, address to) public onlyMinters returns(bool) {
        require(to != address(0), "receiver address should not be zero address");
        IERC721(nftAddress).safeTransferFrom(from, to, tokenId);
        return true;
    }

    function isMintor(address _Mintor) public view returns(bool) {
        return mintors[_Mintor];
    }
}