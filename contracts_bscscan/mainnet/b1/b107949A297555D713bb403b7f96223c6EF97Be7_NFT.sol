import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ERC721.sol";

pragma solidity ^0.6.12;
 
contract NFT is ERC721, Ownable {
    mapping(address => bool) public minters;
    using Counters for Counters.Counter;
    mapping(uint8 => uint256) public nftCount;
    Counters.Counter private _tokenIds;
    mapping(uint256 => uint8) private nftIds;
    mapping(uint8 => string) private nftNames;
    constructor(string memory _baseURI) public ERC721("Cheesecake NFTs", "CcakeNFT") {
        minters[ msg.sender ] = true;
        _setBaseURI(_baseURI);
    }
    function getNftId(uint256 _tokenId) external view returns (uint8) {
        return nftIds[_tokenId];
    }
    function getNftName(uint8 _nftId) external view returns (string memory){
        return nftNames[_nftId];
    }
    function getNftNameOfTokenId(uint256 _tokenId) external view returns (string memory){
        uint8 nftId = nftIds[_tokenId];
        return nftNames[nftId];
    }
    function mint(address _to, string calldata _tokenURI, uint8 _nftId) external onlyMinters returns (uint256) {
        uint256 newId = _tokenIds.current();
        _tokenIds.increment();
        nftIds[newId] = _nftId;
        nftCount[_nftId] = nftCount[_nftId].add(1);
        _mint(_to, newId);
        _setTokenURI(newId, _tokenURI); // _tokenURIs[tokenId] = _tokenURI;
        return newId;
    }
    function setNftName(uint8 _nftId, string calldata _name) external onlyMinters {
        nftNames[_nftId] = _name;
    }
    function changeBaseURI(string memory _baseURI) external onlyMinters {
        _setBaseURI(_baseURI);
    }
    function manageMinters( address _minter, bool _status) external onlyOwner {
        require( _minter != address(0x0) , "0x0 minter");
        minters[ _minter ] = _status;
    }

    // allow multiple contracts to mint nft's
    modifier onlyMinters() {
        require(minters[_msgSender()], "caller is not the minter");
        _;
    }

}