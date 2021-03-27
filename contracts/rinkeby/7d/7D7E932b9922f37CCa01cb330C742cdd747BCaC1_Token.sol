/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.5.0;

contract Token {
    //--------------------------------
    // ERC721
    //--------------------------------
    event Transfer( address from, address to, uint256 tokenId );
    event Approval( address owner, address approved, uint256 tokenId );

    bytes4 constant private InterfaceSignature_ERC165 = bytes4( keccak256('supportsInterface(bytes4)') );
    bytes4 constant private InterfaceSignature_ERC721 = bytes4( keccak256('name()') ) ^
                                                        bytes4( keccak256('symbol()') ) ^
                                                        bytes4( keccak256('totalSupply()') ) ^
                                                        bytes4( keccak256('balanceOf(address)') ) ^
                                                        bytes4( keccak256('ownerOf(uint256)') ) ^
                                                        bytes4( keccak256('approve(address,uint256)') ) ^
                                                        bytes4( keccak256('transfer(address,uint256)') ) ^
                                                        bytes4( keccak256('transferFrom(address,address,uint256)') ) ^
                                                        bytes4( keccak256('tokensOfOwner(address)') ) ^
                                                        bytes4( keccak256('tokenMetadata(uint256,string)') );

    string constant public name = "Four Character Idiomatic Compounds";
    string constant public symbol = "FCIC";

    uint256[] private _seeds;
    mapping( address => uint256 ) private _addressToNum;
    mapping( uint256 => address ) private _idToOwner;
    mapping( uint256 => address ) private _idToApproved;

    function supportsInterface( bytes4 id ) external pure returns (bool) {
        return( id==InterfaceSignature_ERC165 || id==InterfaceSignature_ERC721 );
    }

    function totalSupply() public view returns (uint) {
        return( _seeds.length );
    }

    function balanceOf( address owner ) public view returns (uint256) {
        return( _addressToNum[owner] );
    }

    function ownerOf( uint256 tokenId ) external view returns (address) {
        return( _idToOwner[tokenId] );
    }

    function approve( address to, uint256 tokenId ) external {
        require( _idToOwner[tokenId] == msg.sender );

        _idToApproved[tokenId] = to;

        emit Approval( msg.sender, to, tokenId );
    }

    function transfer( address to, uint256 tokenId ) external {
        require( _idToOwner[tokenId] == msg.sender );

        _transfer( msg.sender, to, tokenId );
    }

    function transferFrom( address from, address to, uint256 tokenId ) external {
        require( _idToOwner[tokenId] == from );
        require( _idToApproved[tokenId] == msg.sender );

        _transfer( from, to, tokenId );
    }

    function tokensOfOwner( address owner ) external view returns(uint256[] memory) {
        uint256 num = balanceOf( owner );

        if( num <= 0 ){
            return( new uint256[](0) );
        }

        uint256 hit = 0;
        uint256 total = totalSupply();
        uint256[] memory tokens = new uint256[](num);

        for( uint256 i=0; i<total; i++ ){
            if( _idToOwner[i] == owner ){
                tokens[hit++] = i;
            }
        }

        return( tokens );
    }

    function tokenMetadata( uint256 /*_tokenId*/, string calldata /*_preferredTransport*/ ) external pure returns (string memory) {
        return( "" );
    }

    function _transfer( address from, address to, uint256 tokenId ) internal {
        require( to != address(0) );

        _idToOwner[tokenId] = to;
        _addressToNum[to]++;

        if( from != address(0) ){
            delete _idToApproved[tokenId];
            _addressToNum[from]--;
        }

        emit Transfer( from, to, tokenId );
    }

    //--------------------------------
    // Ownable
    //--------------------------------
    address payable private _owner;

    modifier onlyOwner() {
        require( msg.sender == _owner );

        _;
    }

    function transferOwnership( address payable newOwner ) external onlyOwner {
        require( newOwner != address(0) );

        _owner = newOwner;
    }

    //--------------------------------
    // Token
    //--------------------------------
    string private _contract_meta_uri = "https://hakumai-iida.s3-ap-northeast-1.amazonaws.com/fcic/contract.json";
    string private _token_meta_prefix = "https://hakumai-iida.s3-ap-northeast-1.amazonaws.com/fcic/json/meta_";
    string private _token_meta_postfix = ".json";

    constructor() public {
        _owner = msg.sender;
    }

    function setContractMetaUri( string calldata uri ) external onlyOwner { _contract_meta_uri = uri; }
    function setTokenMetaPrefix( string calldata prefix ) external onlyOwner { _token_meta_prefix = prefix; }
    function setTokenMetaPostfix( string calldata postfix ) external onlyOwner { _token_meta_postfix = postfix; }

    function contractURI() external view returns (string memory) { return( _contract_meta_uri ); }

    function tokenURI( uint256 tokenId ) external view returns (string memory){
        bytes memory bufPre = bytes( _token_meta_prefix );
        uint256 lenPre = bufPre.length;

        bytes memory bufPost = bytes( _token_meta_postfix );
        uint256 lenPost = bufPost.length;

        uint256 len = 1;
        uint256 temp = tokenId;
        while( temp >= 10 ){
            temp = temp / 10;
            len++;
        }

        bytes memory buf = new bytes(lenPre + len + lenPost);

        for( uint256 i=0; i<lenPre; i++ ){
            buf[i] = bufPre[i];
        }

        temp = tokenId;
        for( uint256 i=0; i<len; i++ ){
            uint8 c = uint8(48 + (temp%10));
            buf[lenPre + len-(i+1)] = byte(c);
            temp /= 10;
        }

        for( uint256 i=0; i<lenPost; i++ ){
            buf[lenPre + len + i] = bufPost[i];
        }

        return( string(buf) );
    }

    function seed( uint256 tokenId ) external view returns (uint256) {
        return( _seeds[tokenId] );
    }

    function mintTokens( uint256 ofs, uint256 num, uint256[] calldata seeds ) external onlyOwner {
        require( ofs == _seeds.length );
        require( num == seeds.length );

        for( uint256 i=0; i<num; i++ ){
            uint256 id = _seeds.length;
            _seeds.length++;
            _seeds[id] = seeds[i];

            _transfer( address(0), _owner, id );
        }
    }

    function withdraw( uint256 value ) external onlyOwner {
        _owner.transfer( value );
    }
}