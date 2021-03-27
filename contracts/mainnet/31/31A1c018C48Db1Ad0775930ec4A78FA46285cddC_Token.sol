/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.5.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract ERC721 is ERC165, IERC721 {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => uint256) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));

        return _ownedTokensCount[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));

        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _safeTransferFrom(from, to, tokenId, _data);
    }

    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId));
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to]++;

        emit Transfer(address(0), to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from]--;
        _ownedTokensCount[to]++;

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }

        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            _data
        ));

        if (!success) {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

contract Token is Ownable, ERC721{

    //-----------------
    // ERC721 & Ownable
    //-----------------
    constructor() Ownable() ERC721() public {
    }

    //-----------------
    // Metadata
    //-----------------
    string private _contract_meta_uri = "https://hakumai-iida.s3-ap-northeast-1.amazonaws.com/fcic/contract.json";
    string private _token_meta_prefix = "https://hakumai-iida.s3-ap-northeast-1.amazonaws.com/fcic/json/meta_";
    string private _token_meta_postfix = ".json";

    function setTokenMetaPrefix( string calldata prefix ) external onlyOwner { _token_meta_prefix = prefix; }
    function setTokenMetaPostfix( string calldata postfix ) external onlyOwner { _token_meta_postfix = postfix; }
    function setContractMetaUri( string calldata uri ) external onlyOwner { _contract_meta_uri = uri; }

    function name() external pure returns (string memory){ return( "Four Character Idiomatic Compounds" ); }

    function symbol() external pure returns (string memory){ return( "FCIC" ); }

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

    function contractURI() external view returns (string memory) { return( _contract_meta_uri ); }

    //-----------------
    // Token
    //-----------------
    uint256[] private _seeds;

    function totalSupply() external view returns (uint256) {
        return( _seeds.length );
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

            _mint( msg.sender, id );
        }
    }

    function withdraw( uint256 value ) external onlyOwner {
        msg.sender.transfer( value );
    }
}