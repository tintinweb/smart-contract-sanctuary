// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721.sol";


interface store {
    function buildstore(address _storeBuilder) external;
}


library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

library LibRoyaltiesV2 {
    /*
    * bytes4(keccak256('getRoyalties(LibAsset.AssetType)')) == 0x44c74bcc
    */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;
}




contract metaaniGEN is  ERC721URIStorage , ERC721Enumerable {

    address public owner;

    string ipfs_base;

    bool mint_started = false;

    address storeAddress;
    bool storeOpened;

    mapping(uint => bool) public minted;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;

    //Creators of Metaani GEN.
//    address mekezzo = 0xcc344De89bB3CB8F6c6134dDb338847cE58f64cA;
//    address misoshita = 0xd9a126b386455925E7a464eAC06Ab603c5043b2f;
//    address nandemotoken = 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7;



    uint public price = 0.15 ether;

    address mekezzo = 0xcc344De89bB3CB8F6c6134dDb338847cE58f64cA;
    address misoshita = 0xd9a126b386455925E7a464eAC06Ab603c5043b2f;
    address nandemotoken = 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7;
    address metawallet = 0x60a89BB4C35A62DE53e4E1852E2d4037a008aC5b;


    mapping(address  => uint) priceCandidates;

    function setPrice(uint _priceCandidate) public {
        require(msg.sender == mekezzo || msg.sender == misoshita || msg.sender == nandemotoken);
        priceCandidates[msg.sender] = _priceCandidate;
    }

    function getPrice() internal view returns (uint) {
        if (priceCandidates[mekezzo]      ==  priceCandidates[misoshita]    &&
            priceCandidates[misoshita]    ==  priceCandidates[nandemotoken] &&
            priceCandidates[nandemotoken] !=  0 ){ return priceCandidates[mekezzo];}
        return price;
    }


    function mintNFT(uint256 _nftid) public payable {
        require(msg.value == getPrice() );
        require( mint_started );
        require( _nftid <= 10000);
        _safeMint( msg.sender , _nftid);
        minted[_nftid] = true;
    }

    //args example ["20","40","60","80","100","120","140","160","180","200"]

    function mint10(uint256[10] memory _nftids) public payable {
        require(msg.value == getPrice() * 10 - 0.1 ether );
        require( mint_started );
        for (uint i = 0 ; i < 10 ; i++ ){
            require( _nftids[i] <= 10000);
            _safeMint( msg.sender , _nftids[i]);
            minted[_nftids[i]] = true;
        }
    }


    function setStoreAddress( address _storeAddress ) public {
        require(msg.sender == metawallet);
        storeAddress = _storeAddress;
    }

    function storeOpen() public {
        require(msg.sender == metawallet);
        storeOpened = true;
    }
    

    //args example ["20","40","60","80","100","120","140","160","180","200"]

    function mint100(uint256[10] memory _nftids) public payable {
        require(msg.value == getPrice() * 90 );
        require( mint_started );
        require( storeOpened );
        store(storeAddress).buildstore(msg.sender);
        for (uint i = 0 ; i < 10 ; i++ ){
            require( _nftids[i] <= 10000);
            uint adj = 0;
            for (uint j = 0 ; j < 10 ; j++ ){
            while (minted[_nftids[i]+j+adj]){
                adj = adj + 1;
            }
            _safeMint( msg.sender , _nftids[i]+j + adj);
            minted[_nftids[i]+j + adj] = true;
            }
        }
    }


    function gift(uint256 _nftid , address _friend ) public payable {
        require(msg.value == getPrice() );
        require( mint_started );
        require( _nftid <= 10000);
        _safeMint( _friend , _nftid);
        minted[_nftid] = true;
    }


    function mintStart() public {
        require(msg.sender == metawallet);
        mint_started = true;
    }


    function mintStop() public {
        require(msg.sender == metawallet);
        mint_started = false;
    }

    function withdraw() public {
        require(msg.sender == metawallet);
        uint balance = address(this).balance;
        payable(metawallet).transfer(balance);
    }

    function withdrawSpare() public {
        require(msg.sender == misoshita);
        uint balance = address(this).balance;
        payable(mekezzo).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 _id) public {
        require( msg.sender == ownerOf(_id));
        _burn(_id);
    }

    function _baseURI() internal view override returns (string memory) {
        return ipfs_base;
    }

    function setbaseURI(string memory _ipfs_base) public {
        require(msg.sender == metawallet );
        ipfs_base = _ipfs_base;
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    struct Part_ {
        address payable account;
        uint96 value;
    }


    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public pure returns (address receiver, uint256 royaltyAmount) {
            _tokenId;
            //----------------------------------------
            return (0x60a89BB4C35A62DE53e4E1852E2d4037a008aC5b, (_salePrice * 2000)/10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        if(interfaceId == _INTERFACE_ID_ROYALTIES) {
            return true;
        }
        
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        
        return super.supportsInterface(interfaceId);
    }

    mapping (uint256 => LibPart.Part[]) public royalties;

    function _saveRoyalties(uint256 _id, LibPart.Part[] memory _royalties) internal {
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            royalties[_id].push(_royalties[i]);
        }
        _onRoyaltiesSet(_id, _royalties);
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
    }


    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory) {
        id;
        return royalties[1];
    }

    function _onRoyaltiesSet(uint256 _id, LibPart.Part[] memory _royalties) internal {
        emit RoyaltiesSet(_id, _royalties);
    }


    constructor() ERC721("MetaaniGEN" , "MTANG" ) {
        owner = msg.sender;

        //MetaaniGEN
        ipfs_base = "ipfs://QmTiW6V5AG3tVJuewTV2NX1yqFJzLb28MpS7ctTHnPzKXT/";
        _safeMint( msg.sender , 1);
        minted[1] = true;

        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = 2000;
        _royalties[0].account = payable(0x60a89BB4C35A62DE53e4E1852E2d4037a008aC5b);
        _saveRoyalties(1, _royalties);
    } 

}