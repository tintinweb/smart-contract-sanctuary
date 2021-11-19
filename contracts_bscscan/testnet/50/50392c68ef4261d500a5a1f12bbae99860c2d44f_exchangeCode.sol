/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.5.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract IERC721Receiver {
    
    //support onERC721Received  
    //equl 'bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))''
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes public receivedData;
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4){
        receivedData = data;
        
        return _ERC721_RECEIVED;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract Context {

    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract exchangeCode is Ownable ,IERC721Receiver  {

    
    IERC721   public bsc721token;
    IERC721   public elfin721token;
    
    mapping(uint256=>uint256) eCode;
    
    uint256 public index;
    
    constructor () public {}
    
    function set721Tokens(address _bsc721token,address _elfin721token) public onlyOwner {
        bsc721token   = IERC721(_bsc721token);
        elfin721token = IERC721(_elfin721token);
    }
    
    function initECode(uint256 bsctokenid,uint256 elfintokenid) public onlyOwner {
        eCode[bsctokenid] = elfintokenid;
    }
    
    function batchInit(uint256[] memory bsctokenid, uint256[] memory elfintokenid) public onlyOwner {
        require( bsctokenid.length == elfintokenid.length );
        for(uint256 i = 0; i < bsctokenid.length; i++){
            initECode(bsctokenid[i],elfintokenid[i]);
        }
    }
    
    function getECode( uint256 bsctokenid ) public view  returns(uint256 ) {
        return eCode[bsctokenid];
    }
    
    function doExchange( uint256 bsctokenid ) public {
        bsc721token.safeTransferFrom(msg.sender,address(this),bsctokenid);
        elfin721token.safeTransferFrom(address(this),msg.sender,eCode[bsctokenid]);
    }
    
}