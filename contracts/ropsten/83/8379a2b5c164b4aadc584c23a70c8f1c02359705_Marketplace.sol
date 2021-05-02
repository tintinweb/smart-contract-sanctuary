/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

pragma  solidity 0.8.0;



library AddressUtils
{

  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    uint256 size;
    assembly { size := extcodesize(_addr) } // solhint-disable-line
    addressCheck = size > 0;
  }

}

interface ERC721TokenReceiver {
    
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

interface ERC721 /* is ERC165 */ {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract ERC721Token is ERC721 {
    using AddressUtils for address;
    mapping(address => uint) private ownerToTokenCount;
    mapping(uint => address) private idToOwner;
    mapping(uint => address) private idToApproved;
    mapping(address => mapping(address => bool)) private ownerToOperators;
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    mapping(uint => string) private tokenURIs;
    string public name;
    string public symbol;
    string public tokenURIBase;

    constructor(
      string memory _name, 
      string memory _symbol,
      string memory _tokenURIBase) public {
      name = _name;
      symbol = _symbol;
      tokenURIBase = _tokenURIBase;
    }

    function tokenURI(uint _tokenId) external view returns(string memory) {
      return string(abi.encodePacked(tokenURIBase, _tokenId));
    }
    
    function balanceOf(address _owner) external view override returns(uint) {
        return ownerToTokenCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        return idToOwner[_tokenId];
    }
    
    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes calldata data) external override payable {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId) external override payable {
        _safeTransferFrom(_from, _to, _tokenId, ""); 
    }
    
    function transferFrom(address _from, address _to, uint _tokenId) external override payable {
        _transfer(_from, _to, _tokenId);
    }
    
    function approve(address _approved, uint _tokenId) external override payable {
        address owner = idToOwner[_tokenId];
        require(msg.sender == owner, 'Not authorized');
        idToApproved[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) override external {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function getApproved(uint _tokenId) external view  override returns (address) {
        return idToApproved[_tokenId];   
    }
    
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return ownerToOperators[_owner][_operator];
    }
    
    function _safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory data) internal {
       _transfer(_from, _to, _tokenId);
        
        if(_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
            require(retval == MAGIC_ON_ERC721_RECEIVED, 'recipient SC cannot handle ERC721 tokens');
        }
    }
    
    function _transfer(address _from, address _to, uint _tokenId) 
        internal 
        canTransfer(_tokenId) {
        ownerToTokenCount[_from] -= 1; 
        ownerToTokenCount[_to] += 1;
        idToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function _mint(address _owner, uint _tokenId) internal {
        require(idToOwner[_tokenId] == address(0), 'This token already exist..');
        idToOwner[_tokenId] = _owner;
        ownerToTokenCount[_owner] += 1;
        emit Transfer(address(0), _owner, _tokenId);
    }
    
    modifier canTransfer(uint _tokenId) {
        address owner = idToOwner[_tokenId];
        require(owner == msg.sender 
            || idToApproved[_tokenId] == msg.sender
            || ownerToOperators[owner][msg.sender] == true, 'Transfer not authorized');
        _;
    }
}


contract Marketplace is ERC721Token {
    struct art {
        uint id;
        uint price;
        string creator;
        
    }
    mapping(uint => art) private arts;
    uint public nextId;
    address public admin;
    ERC721Token private token;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenURIBase) ERC721Token(_name, _symbol, _tokenURIBase) public {
            admin = msg.sender;
    }
    
   
   
    function mint(uint price,string memory creator) external {
        require(msg.sender == admin, 'Only owner can Mint');
        arts[nextId]=art(nextId,price*1e18,creator);
        _mint(address(this),nextId);
        nextId++;
    } 
    
    function set(address _token) public Onlyowner{
       token=ERC721Token(_token); 
    }
    
    function buy(uint _tokenId) public payable {
        uint price= arts[_tokenId].price;
        require(msg.value>=price,"Insufficient fund");
        token.transferFrom(address(this),msg.sender,_tokenId);
        
    }
    modifier Onlyowner(){
        require(msg.sender==admin,"Only Owner can call this function");
        _;
        
    }
}