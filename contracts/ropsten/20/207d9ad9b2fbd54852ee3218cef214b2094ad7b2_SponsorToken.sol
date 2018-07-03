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
            &quot;Only owner can call this function.&quot;
        );
        _;
    }
    modifier onlyAdmins() {
        require(
            admins[msg.sender],
            &quot;Only owner can call this function.&quot;
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
        return &quot;smartsignature.io&quot;;
    }

    function symbol() public view returns (string _symbol) {
        return &quot;&quot;;
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

contract SponsorToken is SmartSignature {

    event CreateToken(uint256 indexed id, address indexed creator);
    event Sponsor(uint256 indexed id, uint256 value, address indexed sponsor, address indexed referrer);
    event Reward(uint256 indexed id, uint256 value, address indexed to, address indexed from);

    struct Token {
        uint256 id;
        uint256 value;
        uint256 head;
        uint8 ponzi;
        address[] sponsors;
        mapping (address => uint256) remain;
        mapping (address => uint256) total;
    }

    Token[] public tokens;
    constructor() public {}

    function totalAndRemainOf(uint256 _id, address _sponsor) public view returns (uint256 total, uint256 remain)  {
        require(_id < tokens.length);
        Token storage token = tokens[_id];
        total = token.total[_sponsor];
        remain = token.remain[_sponsor];
    }

    function sponsorsOf(uint256 _id) public view returns (address[]) {
        require(_id < tokens.length);
        Token storage token = tokens[_id];
        return token.sponsors;
    }    

    function create(uint8 ponzi) public {
        require(ponzi >= 100 && ponzi <= 1000);

        uint256 tokenId = totalSupply();
        issueTokenAndTransfer(address(this));

        Token memory token = Token({
            id: tokenId,
            ponzi: ponzi,
            head: 0,
            value: 0,
            sponsors: new address[](0)
        });

        tokens.push(token);

        emit CreateToken(tokenId, msg.sender);
    }

    function sponsor(uint256 _id, address _referrer) public payable {
        require(msg.value > 0);
        require(_id < tokens.length);
        require(_referrer != msg.sender);
        require(!_referrer.isContract());

        Token storage token = tokens[_id];
        token.sponsors.push(msg.sender);

        emit Sponsor(_id, msg.value, msg.sender, _referrer);

        token.value += msg.value;
        // 存入尚未兑现的支票
        token.total[msg.sender] += msg.value * token.ponzi / 100;
        token.remain[msg.sender] += msg.value * token.ponzi / 100;

        uint256 msgValue = msg.value * 97 / 100; // 3% cut off for contract

        if (_referrer != address(0) && token.remain[_referrer] > 0) {
            if (msgValue <= token.remain[_referrer]) {
                token.remain[_referrer] -= msgValue;
                _referrer.transfer(msgValue);
                emit Reward(_id, msgValue, _referrer, msg.sender);
                return;
            } else {
                msgValue -= token.remain[_referrer];
                _referrer.transfer(token.remain[_referrer]);
                emit Reward(_id, token.remain[_referrer], _referrer, msg.sender);
                token.remain[_referrer] = 0;
            }
        }

        while (msgValue > 0) {
            // 除了自己之外，没有站岗的人了，把钱分给Token Creator
            if (token.head + 1 == token.sponsors.length) {
                ownerOf(_id).transfer(msgValue);
                emit Reward(_id, msgValue, ownerOf(_id), msg.sender);
                return;
            }

            //  把钱分给站岗者们
            address _sponsor = token.sponsors[token.head];
            if (msgValue <= token.remain[_sponsor]) {
                token.remain[_sponsor] -= msgValue;
                _sponsor.transfer(msgValue);
                emit Reward(_id, msgValue, _sponsor, msg.sender);
                return;
            } else {
                msgValue -= token.remain[_sponsor];
                _sponsor.transfer(token.remain[_sponsor]);
                emit Reward(_id, token.remain[_sponsor], _sponsor, msg.sender);
                token.remain[_sponsor] = 0;
                token.head++;
            }
        }
    }
}