/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface INFTAddress {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTCaller is IERC721Receiver {
    address public nftAddress;
    mapping(address => bool) public owners;

    constructor(address nftAddress_, address[] memory owners_){
        nftAddress = nftAddress_;
        for (uint256 i; i < owners_.length; i++) {
            owners[owners_[i]] = true;
        }
    }

    function mintMul(uint256 txAmount, uint256 mintAmount, uint256 price, bytes calldata data, uint256 e) public onlyOwner {
        for (uint256 i; i < txAmount; i++) {
            (bool s,) = nftAddress.call{value : price * mintAmount}(data);
            require(s);
        }
        block.coinbase.transfer(e);
    }

    function transferSelfNFTs(address to, uint256[] calldata tokenIDs) public onlyOwner {
        for (uint256 i; i < tokenIDs.length; i++) {
            INFTAddress(nftAddress).transferFrom(address(this), to, tokenIDs[i]);
        }
    }

    function setNFTAddress(address nftAddress_) public onlyOwner {
        nftAddress = nftAddress_;
    }

    function unlockETH(address owner) public {
        require(owners[owner], "not owner");
        payable(owner).transfer(address(this).balance);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4){
        IERC721Receiver i;
        return i.onERC721Received.selector;
    }

    receive() external payable {

    }

    modifier onlyOwner(){
        require(owners[msg.sender], "not owner");
        _;
    }
}