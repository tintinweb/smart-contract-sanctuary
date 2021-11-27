// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721_.sol";

contract iconeeFactory{

    address iconeeOfficialAddress = msg.sender;

    mapping(address => uint) copyrightHolderIdMap;
    mapping(address => uint) copyrightHolderIdSupply;
    mapping(address => uint) copyrightHolderIdPrice;
    mapping(address => address) copyrightHolderContractMap;
    address[] iconeeNFTarray;
    string baseMetadataURI = "https://dev-iconee-nft-metadata.s3.ap-northeast-1.amazonaws.com/";

    function newIconee( ) public returns (address){
        require(copyrightHolderIdMap[msg.sender] != 0);
        string memory uri = string(abi.encodePacked(baseMetadataURI, Strings.toString(copyrightHolderIdMap[msg.sender]) , "/" ));
        iconeeNFT newContract = new iconeeNFT(iconeeOfficialAddress , uri , copyrightHolderIdSupply[msg.sender] , copyrightHolderIdPrice[msg.sender]);
        copyrightHolderContractMap[msg.sender] = address(newContract) ;
        iconeeNFTarray.push(address(newContract));
        copyrightHolderIdMap[msg.sender] = 0;
        return address(newContract);
    }
    
    function listAddressToIconeeNFT() public view returns (address[] memory){
        return iconeeNFTarray;
    }
    
    function listIconeeNFTOfOwner(address _iconeeUserAddress) public view returns(string[] memory){
        string[] memory allTokenArray = new string[](iconeeNFTarray.length) ;
        for (uint i = 0; i < iconeeNFTarray.length; i++){
            allTokenArray[i] = iconeeNFT(iconeeNFTarray[i]).getAllTokenOfOwner(_iconeeUserAddress);
        }
        return allTokenArray;
    }

    function copyrightHolderIconeeNFTaddress(address _copyrightHolder) public view returns (address){
        return copyrightHolderContractMap[_copyrightHolder];
    }
    
    
    function copyrightHolderRegistration( address _copyrightHolder , uint _copyrightHolderID) public {
        require(msg.sender == iconeeOfficialAddress);
        copyrightHolderIdMap[_copyrightHolder] = _copyrightHolderID;
        copyrightHolderIdSupply[_copyrightHolder] = 10000;
        copyrightHolderIdPrice[_copyrightHolder] = 100000000000000000; // 0.1eth
    }
        
    function copyrightHolderSetSupply( address _copyrightHolder , uint _copyrightHolderSupply) public {
        require(msg.sender == iconeeOfficialAddress);
        copyrightHolderIdSupply[_copyrightHolder] = _copyrightHolderSupply;
    }
    
    function copyrightHolderSetPrice( address _copyrightHolder , uint _copyrightHolderPrice) public {
        require(msg.sender == iconeeOfficialAddress);
        require( 1000000000000 <= _copyrightHolderPrice); // 0.000001eth
        copyrightHolderIdPrice[_copyrightHolder] = _copyrightHolderPrice;
    }

    function setBaseMetadataURI( string memory _URI ) public {
        require(  msg.sender == iconeeOfficialAddress );
        baseMetadataURI = _URI;
    }

}


contract iconeeNFT is  ERC721URIStorage , ERC721Enumerable {

    address public owner;
    address iconeeOfficialAddress;
    
    uint public price;
    uint iconeeDevide = 0;
    uint ownerDevide = 0;
    uint public copyrightHolderSupply;

    string base = "";
    bool public isSale = false;
    mapping(uint => uint) public specialPrice;
    
    event Mint();

    function rangeMint(uint _startnum ,  uint _num ) public payable{
        uint endnum = _startnum + _num - 1;
        require(  endnum <= copyrightHolderSupply);
        require( 0 < _startnum );
        require( _startnum <= endnum );
        require( isSale );
        for ( uint i = _startnum ; i <= endnum ; i++){
            if ( _owners[i] == 0x0000000000000000000000000000000000000000 ) {
                if ( specialPrice[i] == 0 ){
                    require( msg.value == price); 
                }  else {
                    require( msg.value == specialPrice[i]);
                }

                iconeeDevide = iconeeDevide + (msg.value / 100);
                ownerDevide = ownerDevide + ((msg.value / 100) * 99);
                _safeMint( msg.sender , i );
                emit Mint();
                return;
            } 
        }
    } 
    
    function checkNFTInventoryCount(uint _startnum ,  uint _num) public view returns (uint) {
        uint endnum = _startnum + _num - 1;
        require( endnum <= copyrightHolderSupply);
        require( 0 < _startnum );
        require( _startnum <= endnum );
        uint hitcount = 0;
        for ( uint i = _startnum ; i <= endnum ; i++){
            if( _owners[i] == 0x0000000000000000000000000000000000000000 ){
                hitcount = hitcount + 1;
            }
        }
        return hitcount;        
    } 
    

    function getAllTokenOfOwner(address _userAddress) public view returns(string memory){
        uint lastIndexId = balanceOf(_userAddress);
        string memory ret = "";
        if(lastIndexId == 0){
            return ret;
        }  else {
            for ( uint i = 0 ; i < lastIndexId ; i++){
                uint tokenId = tokenOfOwnerByIndex(_userAddress ,i);
                ret =  string(abi.encodePacked(ret,"/" , Strings.toString(tokenId)));
            }
            return ret;
        }
    }

    function iconeeWithdraw() public{
        require(msg.sender == iconeeOfficialAddress);
        payable(iconeeOfficialAddress).transfer(iconeeDevide);
        iconeeDevide = 0;
    }

    function ownerWithdraw() public{
        require(msg.sender == owner);
        payable(owner).transfer(ownerDevide);
        ownerDevide = 0;
    }

    function giftFromOwner( address _gifted , uint _nftid ) public{
        require(msg.sender == owner);
        _safeMint( _gifted , _nftid);
    }

    function _baseURI() internal view override returns (string memory) {
        return base;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setRangeSpecialPrice(uint _startnum ,  uint _num , uint _price ) public{
        uint endnum = _startnum + _num - 1;
        require(msg.sender == owner || msg.sender == iconeeOfficialAddress );
        require( endnum <= copyrightHolderSupply);
        require( 0 < _startnum );
        require( _startnum <= endnum );
        for ( uint i = _startnum ; i <= endnum ; i++){
            specialPrice[i] = _price;
        }
    }

    function setIsSale(bool _isSale) public {
        require( msg.sender == owner || msg.sender == iconeeOfficialAddress );
        isSale = _isSale;
    }

    function setCopyrightHolderSupply( uint _copyrightHolderSupply ) public {
        require( msg.sender == iconeeOfficialAddress );
        copyrightHolderSupply = _copyrightHolderSupply;
    }

    function setMetadataBaseURI( string memory _URI ) public {
        require(  msg.sender == iconeeOfficialAddress );
        base = _URI;
    }

    function changeContractOwner( address _to ) public {
        require( msg.sender == iconeeOfficialAddress );
        owner = _to;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    constructor( address _iconeeOfficialAddress , string memory _URI , uint _supply , uint _price ) ERC721( "iconee" , "ICONEE" ) {
        iconeeOfficialAddress = _iconeeOfficialAddress;
        owner = tx.origin;
        base = _URI;
        copyrightHolderSupply = _supply;
        price = _price;
    } 
}