pragma solidity ^0.8.0;
import './ERC721.sol';

contract SuperMarioWorld is ERC721{
    string public name;
    string public symbol;
    mapping(uint256 => string) private _tokenURIs;
    uint256 public tokenCount;

    constructor(string memory _name, string memory _symbol) public{
        name = _name;
        symbol = _symbol;
    }

    //Get token URI
    function tokenURI(uint256 tokenId) public view returns(string memory){
        return _tokenURIs[tokenId];
    }

    //Mint function
    function mint(string memory tokenURI) public returns(bool){
        tokenCount += 1;
        _balances[msg.sender] += 1;
        _owners[tokenCount - 1] = msg.sender;
        _tokenURIs[tokenCount - 1] = tokenURI;
        emit Transfer(address(0), msg.sender, tokenCount-1);
    }
}

pragma solidity ^0.8.0;

contract ERC721{

    //Keeps track of balances of users
    mapping(address => uint256) internal _balances;
    
    //Keep track of owners of NFTs
    mapping(uint256 => address) internal _owners;

    //Keep tracks of approvals for operators
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    //Mapping of approved address with the token ID
    mapping(uint256 => address) private _tokenApprovals;

    //Event for emitting Approvals
    event Approval(
        address indexed owner,
        address indexed to,
        uint256 tokenId
    );

    //Event for operator approvals
    event ApprovedForAll(
        address indexed _owner, 
        address indexed _operator, 
        bool _approved
        );
    
    //Event for transfer
    event Transfer(
        address indexed from, 
        address indexed to,
        uint256 tokenId
    );

    //Returns balances of owner
    function balanceOf(address owner) public view returns(uint256){
        require(owner != address(0), "Address is zero");
        return _balances[owner];
    }

    //Returns address of owner of tokenId
    function ownerOf(uint256 tokenId) public view returns(address){
        require(_owners[tokenId] != address(0),"TokenId does not exist");
        return _owners[tokenId];
    }


    //Sets approval for operators by owner
    function setApprovalForAll(address operator, bool approved) public{
        require(operator != address(0), "Operator cannot be address(0)");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovedForAll(msg.sender, operator, approved);
    } 

    //Checks if an address is an operator for another address
    function isApprovedForAll(address owner, address operator) public view returns(bool){
        require(
            owner!=address(0) && operator!=address(0),
            "Invalid address"
            );
        return _operatorApprovals[owner][operator];
    }

    //Approve for spending tokens
    function approve(address to, uint256 tokenId) public{
        require(
            ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender),
             "You're not the owner"
             );
        _tokenApprovals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    //Get the approved address for a tokenId
    function getApproved(uint256 tokenId) public view returns(address){
        require(_owners[tokenId] != address(0), "Invalid id");
        return _tokenApprovals[tokenId];
    }

    //Transfer from an address to another address
    function transferFrom(address from, address to, uint256 tokenId) public{
        require(_owners[tokenId] != address(0), "Token does not exist");
        require(to != address(0), "To cannot be zero address");
        require(
            _owners[tokenId] == msg.sender ||
            getApproved(tokenId) == msg.sender||
            isApprovedForAll(_owners[tokenId], msg.sender),
            "You are not approved for transferring this token"
            );
        require(from != to, "You cannot transfer tokens to yourself");
        require(from == ownerOf(tokenId), "From must be the owner");

        approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    //Also checks if onERC721Received() is implemented 
    // when sending to smart contracts
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public{
        require(_checkOnERC721Received(to), "Receiver not implemented");
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId) 
        public{
            safeTransferFrom(from, to, tokenId, "");
    }

    //Oversimplified
    function _checkOnERC721Received(address receiver) internal returns(bool){
        return true;
    }
}