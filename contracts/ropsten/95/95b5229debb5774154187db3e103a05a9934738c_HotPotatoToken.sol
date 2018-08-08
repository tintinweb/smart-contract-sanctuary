pragma solidity ^0.4.23;
/// @author MinakoKojima(https://github.com/lychees)


contract OwnerableContract{
    address public owner;
    mapping (address => bool) public admins;

    constructor () public { 
        owner = msg.sender; 
        addAdmin(owner);
    }    
  
    /* Modifiers */
    // This contract only defines a modifier but does not use
    // it: it will be used in derived contracts.
    // The function body is inserted where the special symbol
    // `_;` in the definition of a modifier appears.
    // This means that if the owner calls this function, the
    // function is executed and otherwise, an exception is
    // thrown.
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
    modifier onlyAdmins() {
        require(
            admins[msg.sender],
            "Only owner can call this function."
        );
        _;
    }    
    
    /* Owner */
    function setOwner (address _owner) onlyOwner() public {
        owner = _owner;
    }

    function addAdmin (address _admin) onlyOwner() public {
        admins[_admin] = true;
    }

    function removeAdmin (address _admin) onlyOwner() public {
        delete admins[_admin];
    }  
    
      /* Withdraw */
    function withdrawAll () onlyAdmins() public {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawAmount (uint256 _amount) onlyAdmins() public {
        msg.sender.transfer(_amount);
    }  
}

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author MinakoKojima (https://github.com/lychees)
contract ERC721Interface {
// Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract ERC721 is ERC721Interface, OwnerableContract{
    event Bought (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
    event Sold (uint256 indexed _tokenId, address indexed _owner, uint256 _price);

	uint256 internal total;
    uint256[] internal listedTokens;
    mapping (uint256 => address) internal ownerOfToken;
    mapping (uint256 => address) internal approvedOfToken;
    

    constructor() public {
        owner = msg.sender;
        admins[owner] = true;    
    }

    /* ERC721 */
    function name() public view returns (string _name) {
        return "smartsignature.io";
    }

    function symbol() public view returns (string _symbol) {
        return "";
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return total;
    }

    function balanceOf (address _owner) public view returns (uint256 _balance) {
        require(_owner != address(0));
		uint256 counter = 0;
      	for (uint256 i = 0; i < total; i++) {
			if (ownerOf(i) == _owner) {
				counter++;
			}
		}
	  	return counter;
    }

    function ownerOf (uint256 _tokenId) public view returns (address _owner) {
      return ownerOfToken[_tokenId];
    }

    function tokensOf (address _owner) public view returns (uint256[] _tokenIds) {
      uint256[] memory Tokens = new uint256[](balanceOf(_owner));

      uint256 TokenCounter = 0;
      for (uint256 i = 0; i < listedTokens.length; i++) {
        if (ownerOf(listedTokens[i]) == _owner) {
          Tokens[TokenCounter] = listedTokens[i];
          TokenCounter += 1;
        }
      }

      return Tokens;
    }

    function approvedFor(uint256 _tokenId) public view returns (address _approved) {
      return approvedOfToken[_tokenId];
    }

    function approve(address _to, uint256 _tokenId) public {
      require(msg.sender != _to);
      require(ownerOf(_tokenId) == msg.sender);

      if (_to == 0) {
        if (approvedOfToken[_tokenId] != 0) {
          delete approvedOfToken[_tokenId];
          emit Approval(msg.sender, 0, _tokenId);
        }
      } else {
        approvedOfToken[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
      }
    }

    /* Transferring a country to another owner will entitle the new owner the profits from `buy` */
    function transfer(address _to, uint256 _tokenId) public {
      require(msg.sender == ownerOf(_tokenId));
      _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
      require(approvedFor(_tokenId) == msg.sender);
      _transfer(_from, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
      require(ownerOf(_tokenId) == _from);
      require(_to != address(0));
      require(_to != address(this));

      ownerOfToken[_tokenId] = _to;
      approvedOfToken[_tokenId] = 0;

      emit Transfer(_from, _to, _tokenId);
    }

    /* Read */
    function getListedTokens() public view returns (uint256[] _Tokens) {
      return listedTokens;
    }
    
    function isAdmin(address _admin) public view returns (bool _isAdmin) {
      return admins[_admin];
    }

    /* Issue */  
    function issueToken(uint256 l, uint256 r) onlyAdmins() public {
      for (uint256 i = l; i <= r; i++) {
        if (ownerOf(i) == address(0)) {
          ownerOfToken[i] = msg.sender;
          listedTokens.push(i);
        }
      }      
    }
    function issueTokenAndTransfer(uint256 l, uint256 r, address to) onlyAdmins() public {
      for (uint256 i = l; i <= r; i++) {
        if (ownerOf(i) == address(0)) {
          ownerOfToken[i] = to;
          listedTokens.push(i);
        }
      }      
    }    

    function issueTokenAndTransfer(address to) onlyAdmins() public {
        uint256 id = listedTokens.length;
        ownerOfToken[id] = to;
        listedTokens.push(id);      
    }      

    function issueTokenAndApprove(uint256 l, uint256 r, address to) onlyAdmins() public {
      for (uint256 i = l; i <= r; i++) {
        if (ownerOf(i) == address(0)) {
          ownerOfToken[i] = msg.sender;
          approve(to, i);
          listedTokens.push(i);
        }
      }          
    }    
}

library AddressUtils {

    /**
     * Returns whether there is code in the target address
     * @dev This function will return false if invoked during the constructor of a contract,
     *  as the code is not actually created until after the constructor finishes.
     * @param addr address address to check
     * @return whether there is code in the target address
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract SmartSignature is ERC721{
    using AddressUtils for address;

    constructor() public {
        owner = msg.sender;
        admins[owner] = true;    
    }

    function withdrawFromToken(uint256 _tokenId) public {
        // To be implement.
    }
}

contract HotPotatoToken is SmartSignature{
    struct Token {
        address creator;
        address owner;
        uint256 price;
        uint256 ratio;
        uint256 startTime;
        uint256 endTime;        
    }

    Token[] public tokens;
    uint256 public tokensSize;
    constructor() public {
        owner = msg.sender;
        admins[owner] = true;
    }
    
    function getNextPrice (uint256 _id) public view returns (uint256 _nextPrice) {
        return tokens[_id].price * tokens[_id].ratio / 100;
    }

     // TODO complete Token info
    function getToken(uint256 _id) public view returns (address _issuer /*, uint256 _tokenId, uint256 _ponzi*/) {
        return (tokens[_id].creator /**/ );
    }
  
    /* ... */
    function create(uint256 _price, uint256 _ratio, uint256 _startTime, uint256 _endTime) public {
        require(_startTime <= _endTime);
        issueTokenAndTransfer(address(this));
        Token memory token = Token({
            creator: msg.sender,
            owner: msg.sender,
            price: _price,
            ratio: _ratio,
            startTime: _startTime,
            endTime: _endTime
        });                
        if (tokensSize == tokens.length) {        
            tokens.push(token);
        } else {    
            tokens[tokensSize] = token;
        }
        tokensSize += 1;
    }

    function buy(uint256 _id) public payable{
        require(_id < tokensSize);  
        require(msg.value >= tokens[_id].price);
        require(msg.sender != tokens[_id].owner);
        require(!msg.sender.isContract());
        require(tokens[_id].startTime <= now && now <= tokens[_id].endTime);
        tokens[_id].owner.transfer(tokens[_id].price*24/25); // 96%
        tokens[_id].creator.transfer(tokens[_id].price/50);  // 2%    
        if (msg.value > tokens[_id].price) {
            msg.sender.transfer(msg.value - tokens[_id].price);
        }
        tokens[_id].owner = msg.sender;
        tokens[_id].price = getNextPrice(tokens[_id].price);
    }

    function redeem(uint256 _id) public {
        require(msg.sender == tokens[_id].owner);
        require(tokens[_id].endTime <= now);
        transfer(msg.sender, _id);    
        tokens[_id] = tokens[tokensSize-1];
        tokensSize -= 1;
    }
}