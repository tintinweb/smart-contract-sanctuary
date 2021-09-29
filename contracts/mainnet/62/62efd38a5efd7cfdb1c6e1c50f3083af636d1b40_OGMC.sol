// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeMath.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./ERC721Enumerable.sol";

interface IPremintKeys{
    function getPremintKeyType(uint256 _keyId) external pure returns(uint256);
    function exists(uint256 _tokenId) external view returns (bool);
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool);
}

interface IWalletOfOwner {
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
}

contract OGMC is ERC721Enumerable, IWalletOfOwner, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    IPremintKeys public premintKeysContract;
    IERC721 public premintKeysContractIERC721;
    
    uint256 public constant OGMC_PRICE = 70000000000000000; //0.07 ETH
    uint256 public constant OGMC_MAX = 6000;
    uint256 public constant OGMC_RESERVED = 100;
    
    uint256 public constant OGMC_PER_MINT = 10;
    uint256 public constant OGMC_LIMIT_GOLD = 3;
    uint256 public constant OGMC_LIMIT_SILVER = 2;

    uint256 public publicAmountMinted = 0;
    uint256 public reservedAmountMinted = 0;

    string private _baseTokenURI;
    string private _contractURI;
    
    mapping(uint256 => bool) public usedPremintKeys;

    string public provenanceHash;
    
    bool public presaleLive = false;
    bool public publicSaleLive = false;

    constructor(address _premintKeysContract) ERC721("Outlaw Gals MC", "OGMC")  {
        premintKeysContract = IPremintKeys(_premintKeysContract);
        premintKeysContractIERC721 = IERC721(_premintKeysContract);
    }

    function publicMint(uint256 _num) public payable nonReentrant{
        uint256 supply = OGMC_RESERVED + publicAmountMinted;
        require(publicSaleLive,                     "PUBLIC_SALE_PAUSED");
        require(_num <= OGMC_PER_MINT,              "EXCEED_PER_MINT");
        require(totalSupply() + _num <= OGMC_MAX,   "OUT_OF_STOCK");
        require(supply + _num <= OGMC_MAX,          "EXCEED_PUBLIC");
        require(msg.value == OGMC_PRICE * _num,     "ETH_INCORRECT");

        for(uint256 i = 1; i <= _num; i++){
            publicAmountMinted++;
            _safeMint( msg.sender, supply + i );
        }
    }

    function presaleMint(uint256 _num, uint256 _keyId) public payable nonReentrant{
        uint256 supply = OGMC_RESERVED + publicAmountMinted; 
        require(presaleLive,                                                "PRE_SALE_PAUSED");
        require(totalSupply() + _num <= OGMC_MAX,                           "OUT_OF_STOCK");
        require(supply + _num <= OGMC_MAX,                                  "EXCEED_PUBLIC");
        require(msg.value == OGMC_PRICE * _num,                             "ETH_INCORRECT");
        require(premintKeysContractIERC721.balanceOf(msg.sender) > 0,       "NO_KEY");
        require(premintKeysContract.isApprovedOrOwner(msg.sender, _keyId),  "NOT_OWNER_NOR_APPROVED");
        require(usedPremintKeys[_keyId] == false,                           "KEY_USED");
        
        //keyType 1 for Silver
        if (premintKeysContract.getPremintKeyType(_keyId) == 1){
            require( _num <= OGMC_LIMIT_SILVER,         "EXCEED_PER_MINT_SILVER");
            usedPremintKeys[_keyId] = true;
            for(uint256 i = 1; i <= _num; i++){
                publicAmountMinted++;
                _safeMint( msg.sender, supply + i );
            }
        }
        //keyType 2 for Gold
        if (premintKeysContract.getPremintKeyType(_keyId) == 2){
            require( _num <= OGMC_LIMIT_GOLD,           "EXCEED_PER_MINT_GOLD");
            usedPremintKeys[_keyId] = true;
            for(uint256 i = 1; i <= _num; i++){
                publicAmountMinted++;
                _safeMint( msg.sender, supply + i );
            }
        }
    }

    function giveAway(address _targetAddress, uint256 _amount) external onlyOwner {
        require(_amount + reservedAmountMinted <= OGMC_RESERVED,    "EXCEED_RESERVED");
        require(totalSupply() + _amount <= OGMC_MAX,                "OUT_OF_STOCK");
        
        for(uint256 i; i < _amount; i++){
            reservedAmountMinted++;
            _safeMint( _targetAddress, reservedAmountMinted );
        }
    }
    
    function walletOfOwner(address _owner) public view virtual override returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function isPremintKeyUsed(uint256 _keyId) public view returns (bool){
        return usedPremintKeys[_keyId] == true;
    }

    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "NOT_OWNER_NOR_APPROVED");
        _burn(_tokenId);
    }
    
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setContractURI(string calldata _uri) external onlyOwner {
        _contractURI = _uri;
    }

    function setProvenanceHash(string calldata _hash) external onlyOwner{
        provenanceHash = _hash;
    }

    function setPublicSaleLiveStatus(bool _val) public onlyOwner {
        publicSaleLive = _val;
    }

    function setPresaleLiveStatus(bool _val) public onlyOwner {
        presaleLive = _val;
    }
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}