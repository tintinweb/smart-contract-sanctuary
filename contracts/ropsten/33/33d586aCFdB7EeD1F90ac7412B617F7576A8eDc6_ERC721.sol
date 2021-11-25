/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// File: contracts/nft.sol



pragma solidity ^0.8.3;
interface IERC721TokenReceiver {
           
            function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
         }

/// @title NFT
/// @author Luka Jevremovic
/// @notice This is authors fisrt code in soldity, be cearful!!!
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.

contract ERC721{
    
    
    
   
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;
    string public name;
    address public admin;
   
    mapping(uint256 => address) private owners;

    // Mapping owner address to token count
    mapping(address => uint256) private balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private approvals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operators;
    
    constructor(){
        admin=msg.sender;
        name="kita";
    }
    function balanceOf(address owner) public view  returns (uint256) {
        require(owner != address(0), "Not valid address");
        return balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        
        require(owners[tokenId] != address(0), "doenst exist");
        return owners[tokenId];
    }
    
    function approve(address to, uint256 _tokenId) public {
        require(to != owners[_tokenId], "already owner");

        require(
            msg.sender == owners[_tokenId] || isApprovedForAll(owners[_tokenId], msg.sender),
            "not alowed"
        );

        approvals[_tokenId]=to;
    }
    function setApprovalForAll(address _operator, bool _approved) public{
        require(_operator!=msg.sender,"owner can not be operator");
        operators[msg.sender][_operator]=_approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        require(_operator!=msg.sender,"owner can not be operator");
        return operators[_owner][_operator];
    }
    
    function getApproved(uint256 _tokenId) external view returns (address){
        require (owners[_tokenId]!=address(0),"not valid token");
        return approvals[_tokenId];
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable{
        address owner= owners[_tokenId];
         //da je sender owner opertar ili apoved za taj token
        require(msg.sender==owner||operators[owner][msg.sender]||msg.sender==approvals[_tokenId],"not allbbowed");
        require(_from==owner,"Not valid owner");
        require(_to!=address(0)&&isContract(_to),"not valid to adress");
        require(owner!=address(0),"nft deas not exist");
         
        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;
         
        require(IERC721TokenReceiver(_to).onERC721Received(_to,_from,_tokenId,data)==ERC721_RECEIVED,"recevier not caplable of receving nft");
        emit Transfer(_from, _to, _tokenId);
         
    }
     function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable{
         safeTransferFrom(_from,_to, _tokenId, "");
    }
     
     function transferFrom(address _from, address _to, uint256 _tokenId) public payable{
         safeTransferFrom(_from,_to, _tokenId, "");
    }
     function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
        size := extcodesize(_addr)
                    }
        return (size > 0);
    }
    
    function createAndSend(address _admin, uint256 _tokenId,address _to) public payable {
        require(_admin==admin,"not allowed");
        require(owners[_tokenId]==address(0),"nft exists");
        balances[msg.sender] += 1;
        owners[_tokenId] = msg.sender;
        
        safeTransferFrom(msg.sender,_to, _tokenId);
        // dali treba trasnim transfer
        
    }
}