// File: contracts/NFTMint.sol

pragma solidity ^0.5.0;
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public{
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) internal onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract NFTBANK721 is Ownable{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed from, address indexed to, uint256 indexed tokenId);
     // Token name
    string private _name;
    uint256 public tokenCount;

    // Token symbol
    string private _symbol;


    // Mapping from token ID to owner address
    mapping (uint256 => address) public _owners;

    // Mapping owner address to token count
    mapping (address => uint256) public _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) public _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (uint256 => string) private _tokenURIs;
    mapping (uint256 => address) public _creator;
    constructor (string memory name_, string memory symbol_) public{

        _name = name_;
        _symbol = symbol_;
    }
    function _transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        transferOwnership(newOwner);
       
    }
    function balanceOf(address owner) public view  returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
     function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view  returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function _approve(address to, uint256 tokenId) public  onlyOwner{
        _tokenApprovals[tokenId] = to;
    }
     function _mint(address to, uint256 tokenId,string memory _tokenuri) public onlyOwner{
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;
        _creator[tokenId] = to;
        _setTokenURI(tokenId, _tokenuri);
        tokenCount++;
        emit Transfer(address(0), to, tokenId);
    }
    function setApprovalForAll(address from, address to, bool approved, uint256 tokenId) public onlyOwner{
        require(to == msg.sender, "ERC721: approve to caller");
        _approve(to, tokenId);
        _operatorApprovals[from][to] = approved;
        emit Approval(from, to, tokenId);
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal onlyOwner{
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function tokenTransfer(address from, address to, uint256 tokenId) public onlyOwner{
        _transfer(from, to, tokenId);
    }
    function _transfer(address from, address to, uint256 tokenId) public onlyOwner{
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_operatorApprovals[_creator[tokenId]][owner()] == true , "Need operator approval for 3rd party transfers.");
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId, address from, address admin) public onlyOwner{
        require(_owners[tokenId] == from || from == owner(), "Only Burn Allowed Token Owner or Admin");
        require(_operatorApprovals[_creator[tokenId]][admin] == true, "Need operator approval for 3rd party burns.");

        // // Clear approvals
        _approve(address(0), tokenId);
        _operatorApprovals[_creator[tokenId]][admin] = false;
        _balances[_owners[tokenId]] -= 1;
        delete _owners[tokenId];
        delete _creator[tokenId];
        emit Transfer(from, address(0), tokenId);
    }
}

contract NFTMint is NFTBANK721{
     mapping(string => bool) _nameexits;
    // uint256 public tokenCount;
    constructor(
        string memory name,
        string memory symbol
    ) NFTBANK721(name, symbol) public{
      
    }     
}