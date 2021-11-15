pragma solidity >=0.4.22 <0.9.0;

contract ERC721{
     // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from token ID is exists
    //mapping (uint256 => bool) private _exists;

    

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    constructor (string memory name_, string memory symbol_)public {

        _name = name_;
        _symbol = symbol_;
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

    // function _isApprovedOrOwner(address sender,uint256 tokenId) public view returns (bool) {
    //     require(_exists[tokenId], "ERC721: approved query for nonexistent token");
    //     require(_exists[tokenId], "ERC721: approved query for nonexistent token");
    //     return _tokenApprovals[tokenId];
    // }
    

    function _approve(address to, uint256 tokenId) internal  {
        _tokenApprovals[tokenId] = to;
        //emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
     function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        //_beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

       // emit Transfer(address(0), to, tokenId);
    }
  

    
}


contract NFTMint is ERC721{
     mapping(string => bool) _nameexits;
     uint256 public tokenCount=0;
     mapping (uint256 => string) private _tokenURIs;
     mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    constructor (
        string memory name,
        string memory symbol
    ) public ERC721(name, symbol) {
      
    }
    
    function mint(string memory _name, string memory tokenuri) public {
        require(!_nameexits[_name]);
        tokenCount++;
        _mint(msg.sender, tokenCount);
        _nameexits[_name] = true;
        _setTokenURI(tokenCount, tokenuri);
    }
  
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
     function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
    }
}

