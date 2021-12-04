/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

pragma solidity 0.6.0;

library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract RastaNFT {
    using SafeMath for uint256;
    
    struct NFT { 
        string url;
        address owner;
        uint256 price;
    }

    string public _NFTURL = "https://ipfs.infura.io/ipfs/";
    address public ownerAddr;
    uint256 public totalNFTSupply = 0;

    mapping(uint256 => NFT) private _NFTs;
    mapping(address => uint256[]) private _ownedNFTs;
        mapping(uint256 => uint256) private _ownedNFTIndex;

    constructor (address _owner) public {
        ownerAddr = _owner;
    }

    event buy(address indexed buyer, uint256 price);
    
    function mint(uint256 tokenId, uint256 price, string calldata _tokenURI) external returns (bool) {
        require(msg.sender == ownerAddr, "!owner");

        _NFTs[tokenId] = NFT(_tokenURI, ownerAddr, price);
        _ownedNFTs[ownerAddr].push(tokenId);
        _ownedNFTIndex[tokenId] = _ownedNFTs[ownerAddr].length;


        totalNFTSupply++;

        return true;
    }

    function getNFT(uint256 tokenId) public view returns (string memory, address, uint256) {
        return (_NFTs[tokenId].url, _NFTs[tokenId].owner, _NFTs[tokenId].price);
    }

    function NFTOfOwner(address to) public view returns (uint256[] memory) {
        return _ownedNFTs[to];
    }

    function buyNFT(uint256 tokenId, uint256 amount) public virtual {
        require(amount == _NFTs[tokenId].price, "Price is not match");

        uint256 lastTokenIndex = _ownedNFTs[ownerAddr].length.sub(1);
        uint256 tokenIndex = _ownedNFTIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedNFTs[ownerAddr][lastTokenIndex];

            _ownedNFTs[ownerAddr][tokenIndex] = lastTokenId; 
            _ownedNFTIndex[lastTokenId] = tokenIndex; 
        }

        _ownedNFTs[ownerAddr].length - 1;

        _NFTs[tokenId].owner = msg.sender;
        _ownedNFTs[msg.sender].push(tokenId);
        _ownedNFTIndex[tokenId] = _ownedNFTs[msg.sender].length;

        emit buy(msg.sender, amount);
    }

}