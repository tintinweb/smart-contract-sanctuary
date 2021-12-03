/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity 0.6.0;

contract RastaNFT {
    
    struct NFT { 
        string url;
        address owner;
    }

    string public _NFTURL = "https://ipfs.infura.io/ipfs/";
    address public ownerAddr;
    uint256 public totalNFTSupply = 0;

    mapping(uint256 => NFT) public _NFTs;
    mapping(address => uint256[]) private _Users;

    constructor (address _owner) public {
        ownerAddr = _owner;
    }
    
    function mint(address to, uint256 tokenId, string calldata _tokenURI) external returns (bool) {
        require(msg.sender == ownerAddr, "!owner");

        _NFTs[tokenId] = NFT(_tokenURI, to);
        _Users[to].push(tokenId);
        totalNFTSupply++;

        return true;
    }

    function _getNFT(uint256 tokenId) public view returns (string memory, address) {
        return (_NFTs[tokenId].url, _NFTs[tokenId].owner);
    }

    function _NFTOfOwner(address to) public view returns (uint256[] memory) {
        return _Users[to];
    }

}