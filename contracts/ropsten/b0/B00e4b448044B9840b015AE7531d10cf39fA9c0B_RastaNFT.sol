/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity 0.6.0;

contract RastaNFT {
    
    struct SNFT { 
        string url;
        address owner;
    }

    string public _NFTURL = "https://ipfs.infura.io/ipfs/";
    address public ownerAddr;
    uint256 public totalNFTSupply = 0;

    mapping(uint256 => SNFT) private _NFTs;
    mapping(address => uint256[]) private _Users;

    constructor (address _owner) public {
        ownerAddr = _owner;
    }
    
    function mint(address to, uint256 tokenId, string calldata _tokenURI) external returns (bool) {
        require(msg.sender == ownerAddr, "!owner");

        _NFTs[tokenId] = SNFT(_tokenURI, to);
        _Users[to].push(tokenId);
        totalNFTSupply++;

        return true;
    }

}