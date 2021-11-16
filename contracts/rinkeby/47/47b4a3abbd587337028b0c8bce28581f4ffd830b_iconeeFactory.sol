// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./OpenzeppelinERC721_.sol";


contract iconeeFactory{

    // need to deploy from iconee management wallet
    address iconeeOfficialAddress = msg.sender;

    mapping(address => uint) copyrightHolderIdMap;
    mapping(address => uint) copyrightHolderIdSupply;
    mapping(address => address) copyrightHolderContractMap;
    
    address[] iconeeNFTarray;
    
    function newIconee( ) public returns (address){
        require(copyrightHolderIdMap[msg.sender] != 0);
        iconeeNFT newContract = new iconeeNFT(iconeeOfficialAddress, copyrightHolderURI() ,copyrightHolderSupply() );
        copyrightHolderContractMap[msg.sender] = address(newContract) ;
        iconeeNFTarray.push(address(newContract));
        return address(newContract);
    }
    

    function listAddressToIconeeNFT() public view returns (address[] memory){
        return iconeeNFTarray;
    }
    
    function listIconeeNFTNumber(address _iconeeUserAddress , uint _nftnumber) public view returns(uint[] memory){
        uint[] memory nftnumberarray = new uint[](iconeeNFTarray.length) ;
        for (uint i = 0; i < iconeeNFTarray.length; i++){
            nftnumberarray[i] = iconeeNFT(iconeeNFTarray[i]).getNFTNumber(_iconeeUserAddress , _nftnumber);
        }
        return nftnumberarray;
    }


    function copyrightHolderIconeeNFTaddress(address _copyrightHolder) public view returns (address){
        return copyrightHolderContractMap[_copyrightHolder];
    }
    
    
    function copyrightHolderRegistration( address _copyrightHolder , uint _copyrightHolderID) public {
        require(msg.sender == iconeeOfficialAddress);
        copyrightHolderIdMap[_copyrightHolder] = _copyrightHolderID;
    }
    
    function copyrightHolderURI() internal view returns (string memory) {
        string memory uri = string(abi.encodePacked("https://dev-iconee-nft-metadata.s3.ap-northeast-1.amazonaws.com/", Strings.toString(copyrightHolderIdMap[msg.sender]) , "/" ));
        return uri;
    }
    
    function copyrightHolderSetSupply( address _copyrightHolder , uint _copyrightHolderSupply) public {
        require(msg.sender == iconeeOfficialAddress);
        copyrightHolderIdSupply[_copyrightHolder] = _copyrightHolderSupply;
    }
    
    function copyrightHolderSupply() internal view returns (uint) {
        if(copyrightHolderIdSupply[msg.sender] == 0 ){
            return 10000;
        } else {
            return copyrightHolderIdSupply[msg.sender];
        }
    }
    
}


contract iconeeNFT is  ERC721URIStorage , ERC721Enumerable {

    address public owner;
    uint public price;
    //Dummy iconee is vitalik.eth
    address iconeeOfficialAddress;
    
    mapping(uint => uint) specialPrice;
    uint iconeeDevide = 0;
    uint ownerDevide = 0;

    //debugging public
    string public base = "";
    uint public copyrightHolderSupply;
    
    event Mint();


    // function mint(uint _artnumber) public payable {
    //     require( _artnumber <= copyrightHolderSupply);
    //     require( 0 < _artnumber);
    //     require( msg.value == price); 
    //     //require( balanceOf(msg.sender) == 0);
    //     iconeeDevide = iconeeDevide + (msg.value / 100);
    //     ownerDevide = ownerDevide + ((msg.value / 100) * 99);
    //     _safeMint( owner , _artnumber);
    //     emit Mint();
    // }

    function rangeMint(uint _startnum ,  uint _endnum ) public payable{
        require( _endnum <= copyrightHolderSupply);
        require( 0 < _startnum );
        require( _startnum <= _endnum );
        require( msg.value == price); 
        for ( uint i = _startnum ; i <= _endnum ; i++){
//            if ( _owners[i] == 0x0000000000000000000000000000000000000000 ) {
            if ( _owners[i] == address(0) ) {
                iconeeDevide = iconeeDevide + (msg.value / 100);
                ownerDevide = ownerDevide + ((msg.value / 100) * 99);
                _safeMint( msg.sender , i );
                emit Mint();
                return;
            } 
        }
    } 
    
    function checkNFTInventoryCount(uint _startnum ,  uint _endnum) public view returns (uint) {
        require( _endnum <= copyrightHolderSupply);
        require( 0 < _startnum );
        require( _startnum <= _endnum );
        uint hitcount = 0;
        for ( uint i = _startnum ; i <= _endnum ; i++){
//            if( _owners[i] == 0x0000000000000000000000000000000000000000 ){
            if( _owners[i] == address(0) ){
                hitcount = hitcount + 1;
            }
        }
        return hitcount;        
    } 
    

    function getNFTNumber(address _userAddress , uint _nftnumber) public view returns(uint){
        if(balanceOf(_userAddress) == 0){
            return 0;
        }  else {
            return tokenOfOwnerByIndex(_userAddress , _nftnumber);
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

    function setPpecialPrice( uint _artnumber , uint _price) public{
        require(msg.sender == owner);
        specialPrice[_artnumber] = _price;
    }

    function setRangeSpecialPrice(uint _startnum ,  uint _endnum , uint _price ) public{
        require(msg.sender == owner);
        require( _endnum <= copyrightHolderSupply);
        require( 0 < _startnum );
        require( _startnum <= _endnum );
        for ( uint i = _startnum ; i <= _endnum ; i++){
            specialPrice[i] = _price;
        }
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

    constructor( address _iconeeOfficialAddress , string memory _URI , uint _supply ) ERC721( "iconee" , "ICONEE" ) {
        iconeeOfficialAddress = _iconeeOfficialAddress;
        owner = tx.origin;
        base = _URI;
        price = 100000000000000000;
        copyrightHolderSupply = _supply;
    } 
}