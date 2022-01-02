/**
 *Submitted for verification at polygonscan.com on 2021-12-31
*/

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.9;

interface IBaseNFT721 {

    function setRoyaltyFee(uint256 _royalty) external returns(bool);

    function createCollectible(address creator, string memory tokenURI) external returns (uint256);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function changeName(uint256 tokenId, string memory newName) external;

}

interface IBaseNFT1155 {

    function setRoyaltyFee(uint256 _royalty) external returns(bool);

    function mint(address creator, string memory uri, uint256 supplys) external returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

}

interface IURI {
    function updateTokenURI(uint256 tokenId, string memory metaData) external returns(bool);
}

contract Operator {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event MinterAdded(address indexed minter);

    event MinterRemoved(address indexed minter);

    event CelebrityAdminAdded(address indexed admin);

    event CelebrityAdminRemoved(address indexed admin);

    event NameChanged(address indexed nftaddress, uint256 indexed tokenId, string name);


    address public owner;

    bool public Paused;

    mapping(address => bool) private celebrityAdmin;
    mapping(address => bool) private minters;


    enum NftType{
        ERC1155,
        ERC721
    }
    constructor () {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMinters() {
        require(minters[msg.sender], "Minter: caller doesn't have minter Role");
        _;
    }
    modifier isPaused() {
        require(!Paused,"Pausable: contract was paused try again after sometime");
        _;
    }
    function ownerTransfership(address newOwner) public onlyOwner isPaused returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function addCelebrityAdmin(address _celebrityAdmin) public onlyOwner isPaused returns(bool) {
        require(!celebrityAdmin[_celebrityAdmin], "Celebrity Admin already exist");
        celebrityAdmin[_celebrityAdmin] = true;
        emit CelebrityAdminAdded(_celebrityAdmin);
        return true;
    }

    function removeCelebrityAdmin(address _celebrityAdmin) public onlyOwner isPaused returns(bool) {
        require(celebrityAdmin[_celebrityAdmin], "Celebrity Admin does not exist");
        celebrityAdmin[_celebrityAdmin] = false;
        emit CelebrityAdminRemoved(_celebrityAdmin);
        return true;
    }
    
    function isCelebrityAdmin(address _celebrityAdmin) view public returns(bool) {
        return celebrityAdmin[_celebrityAdmin];
    }

    function UpdateMetaData(address nftAddress, uint256 tokenId, string memory _metaData) public onlyMinters isPaused {
        IURI(nftAddress).updateTokenURI(tokenId, _metaData);
    }
    
    function addMinter(address _minter) public isPaused returns(bool) {
        require(celebrityAdmin[msg.sender], "Only celebrity admin can add minter");
        require(!minters[_minter], "Minter already exist");
        minters[_minter] = true;
        emit MinterAdded(_minter);
        return true;
    }
    
    function removeMinter(address _minter) public isPaused returns(bool) {
        require(celebrityAdmin[msg.sender], "Only celebrity admin can remove minter");
        require(minters[_minter], "Minter does not exist");
        minters[_minter] = false;
        emit MinterRemoved(_minter);
        return true;
    }

    function mint721(address nftAddress, address creator, string memory tokenURI) public onlyMinters isPaused returns(bool) {
        IBaseNFT721(nftAddress).createCollectible(creator, tokenURI);
        return true;
    }

    function mint1155(address nftAddress, address creator, string memory tokenURI, uint256 supply) public onlyMinters isPaused returns(bool) {
        IBaseNFT1155(nftAddress).mint(creator, tokenURI, supply);
        return true;
    }

    function safeTransfer1155(address nftAddress, address from, uint256 tokenId, address receiver, uint256 amount) public onlyMinters isPaused returns(bool) {
        IBaseNFT1155(nftAddress).safeTransferFrom(from, receiver, tokenId, amount, "");
        return true;
    }

    function safeTransfer721(address nftAddress, address from, uint256 tokenId, address to) public onlyMinters isPaused returns(bool) {
        require(to != address(0), "receiver address should not be zero address");
        IBaseNFT721(nftAddress).safeTransferFrom(from, to, tokenId,"");
        return true;
    }

    function setRoyaltyFee(address nftAddress, NftType nfttype, uint256 royaltyFee) public isPaused returns(bool) {
        require(celebrityAdmin[msg.sender], "Operator: caller doesn't have role");       
        if(nfttype == NftType.ERC721) {
            IBaseNFT721(nftAddress).setRoyaltyFee(royaltyFee);
        }
        if(nfttype == NftType.ERC1155) {
            IBaseNFT1155(nftAddress).setRoyaltyFee(royaltyFee);
        }
        return true;
    }
    
    function pause() public onlyOwner returns(bool) {
        Paused = true;
        return true;
    } 

    function unPause() public onlyOwner returns(bool) {
        Paused = false;
        return true;
    }

    function setNameForToken(address nftAddress, uint256 tokenId, string memory name) public onlyMinters isPaused returns(bool) {
        IBaseNFT721(nftAddress).changeName(tokenId, name);
        emit NameChanged(nftAddress, tokenId, name);
        return true;
    }

    function isMinter(address _minter) public view returns(bool) {
        return minters[_minter];
    }
    
}