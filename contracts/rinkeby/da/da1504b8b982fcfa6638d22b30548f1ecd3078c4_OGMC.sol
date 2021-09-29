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
    ERC721 public premintKeysContractERC721;
    
    uint256 public constant OGMC_PRICE = 70000000000000000; //0.07 ETH
    uint256 public constant OGMC_MAX = 6000;
    uint256 public constant OGMC_RESERVED = 100;
    
    uint256 public constant OGMC_PER_MINT = 10;
    uint256 public constant OGMC_LIMIT_GOLD = 3;
    uint256 public constant OGMC_LIMIT_SILVER = 2;

    uint256 public reservedAmount = 0;

    string private _baseTokenURI;
    string private _contractURI;
    
    mapping(uint256 => bool) public usedPremintKeys;

    
    string public provenanceHash;
    bool public publicSaleLive = false;
    bool public privateSaleLive = false;
    
    
    
    //gutterCats zone
    //
    IERC1155 public constant gutterCatNFTAddressIERC1155 = IERC1155(0xEdB61f74B0d09B2558F1eeb79B247c1F363Ae452);
    uint256 public OGMC_RESERVED_FOR_CATS = 115;
    mapping(uint256 => bool) public unusedBikerCats;
    uint256 public reservedForCatsAmount = 0;
    bool public catSaleLive = false;
    //
    //gutterCats zone


    constructor(address _premintKeysContract) ERC721("OG Motorcycle Club", "OGMC")  {
        premintKeysContract = IPremintKeys(_premintKeysContract);
        premintKeysContractERC721 = ERC721(_premintKeysContract);
    }

    function publicMint(uint256 _num) public payable nonReentrant{
        uint256 supply = OGMC_RESERVED + totalSupply();
        require(publicSaleLive,                                                     "PUBLIC_SALE_PAUSED" );
        require(_num <= OGMC_PER_MINT,                                              "EXCEED_PER_MINT" );
        require(supply + _num <= OGMC_MAX - OGMC_RESERVED - OGMC_RESERVED_FOR_CATS, "EXCEED_PUBLIC" );
        require(msg.value == OGMC_PRICE * _num,                                     "ETH_INCORRECT" );

        for(uint256 i = 1; i <= _num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function privateMint(uint256 _num, uint256 _keyId) public payable nonReentrant{
        uint256 supply = OGMC_RESERVED + totalSupply(); 
        require(privateSaleLive,                                                        "PRIVATE_SALE_PAUSED" );
        require(supply + _num <= OGMC_MAX - OGMC_RESERVED - OGMC_RESERVED_FOR_CATS,     "EXCEED_PUBLIC" );
        require(msg.value == OGMC_PRICE * _num,                                         "ETH_INCORRECT" );
        require(premintKeysContractERC721.balanceOf(msg.sender) > 0,                    "NO_KEY");
        // require(premintKeysContractERC721.ownerOf(_keyId) == msg.sender,     "You are not owner of the Premint Key");
        require(premintKeysContract.isApprovedOrOwner(msg.sender, _keyId),              "NOT_OWNER_NOR_APPROVED");
        require(usedPremintKeys[_keyId] == false,                                       "KEY_USED");
        
        //keyType 1 for Silver
        if (premintKeysContract.getPremintKeyType(_keyId) == 1){
            require( _num <= OGMC_LIMIT_SILVER,         "EXCEED_PER_MINT_SILVER" );
            usedPremintKeys[_keyId] = true;
            for(uint256 i = 1; i <= _num; i++){
                _safeMint( msg.sender, supply + i );
            }
        }
        //keyType 2 for Gold
        if (premintKeysContract.getPremintKeyType(_keyId) == 2){
            require( _num <= OGMC_LIMIT_GOLD,           "EXCEED_PER_MINT_GOLD" );
            usedPremintKeys[_keyId] = true;
            for(uint256 i = 1; i <= _num; i++){
                _safeMint( msg.sender, supply + i );
            }
        }
    }



    //gutterCats zone
    //
    function mintWithBikerCats(uint256 _num, uint256[] calldata _catIds) public nonReentrant{
        uint256 supply = OGMC_RESERVED + totalSupply();
        require(catSaleLive,                                                "CAT_SALE_PAUSED");
        require(_num == _catIds.length,                                     "INVALID_INPUT");
        require(_num <= OGMC_PER_MINT,                                      "EXCEED_PER_MINT");
        require(_num + reservedForCatsAmount <= OGMC_RESERVED_FOR_CATS,     "EXCEED_CATS");
        require(supply + _num <= OGMC_MAX - OGMC_RESERVED,                  "EXCEED_PUBLIC");
        
        for(uint256 i; i < _catIds.length; i++){
            uint256 _catId = _catIds[i];
            require(gutterCatNFTAddressIERC1155.balanceOf(msg.sender, _catId) > 0,  "NO_CAT_NOR_OWNER");
            require(unusedBikerCats[_catId] == true,    "CAT_USED");
        }

        for(uint256 i = 1; i <= _num; i++){
            uint256 _catId = _catIds[i-1];
            unusedBikerCats[_catId] = false;
            reservedForCatsAmount++;
            _safeMint( msg.sender, supply + i );
        }
    }

    function addBikerCatId(uint256[] calldata _idList) external onlyOwner{
        for(uint256 i; i < _idList.length; i++){
            uint256 _id = _idList[i];
            require(unusedBikerCats[_id] == false,      "DUPLICATE_CAT");
            unusedBikerCats[_id] = true;
        }
    }
    
    function removeBikerCatId(uint256[] calldata _idList) external onlyOwner{
        for(uint256 i; i < _idList.length; i++){
            uint256 _id = _idList[i];
            unusedBikerCats[_id] = false;
        }
    }

    function removeReservedForCats() external onlyOwner{
        OGMC_RESERVED_FOR_CATS = 0;
    }
    
    function setCatSaleLiveStatus(bool _val) public onlyOwner {
        catSaleLive = _val;
    }
    //
    //gutterCats zone
    
    
    
    
    
    
    function giveAway(address _targetAddress, uint256 _amount) external onlyOwner {
        require(_amount + reservedAmount <= OGMC_RESERVED, "EXCEED_RESERVED");
        
        for(uint256 i; i < _amount; i++){
            reservedAmount++;
            _safeMint( _targetAddress, reservedAmount );
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

    function setPrivateSaleLiveStatus(bool _val) public onlyOwner {
        privateSaleLive = _val;
    }
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}