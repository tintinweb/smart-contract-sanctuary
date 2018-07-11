pragma solidity ^0.4.23;

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

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    uint256 public total;
    mapping (uint256 => address) private ownerOfToken;
    mapping (uint256 => address) private approvedOfToken;


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
        for (uint256 i = 0; i < total; i++) {
            if (ownerOf(i) == _owner) {
                Tokens[TokenCounter] = i;
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
    function isAdmin(address _admin) public view returns (bool _isAdmin) {
      return admins[_admin];
    }

    /* Issue */  
    function issueToken() onlyAdmins() public {
        uint256 id = total;
        ownerOfToken[id] = msg.sender;   
    }

    function issueTokenAndTransfer(address to) onlyAdmins() public {
        uint256 id = total;
        ownerOfToken[id] = to;
    }      
}

/*
    Test crowdsale controller with start time < now < end time
*/
contract CryptoHeroCard is ERC721 {
    mapping (uint256 => uint256) private characterOfToken;
    mapping (uint256 => uint256) private statusOfToken;
    address public DappTokenContractAddr;    

    // Events
    event Claim(address from);
    event Draw(address from);
    
    uint256[] characterRatio = [500, 250, 10, 1];
    uint256 drawPrice = 1;

    function setDappTokenContractAddr(address _addr) public onlyOwner {
        DappTokenContractAddr = _addr;
    }

    function getCharacter(uint256 r) public returns (uint256 offset, uint256 count) {
        if (r <= characterRatio[1] * 36) {
            return (1, 36);        
        }
        r -= characterRatio[1] * 36;
        if (r <= characterRatio[0] * 72) {
            return (37, 72);
        }
        r -= characterRatio[0] * 72;
        if (r <= characterRatio[2] * 6) {
            return (109, 6);
        }
        return (0, 1);
    }

    function getDrawCount(uint256 value) internal returns (uint256 result) {
        return value / drawPrice;
    }

    function getRandomInt(uint256 n) internal returns (uint256 result) {
      /* get a random number. */
      return uint256(keccak256(abi.encodePacked(block.difficulty, now))) % n;
    }

    function isClaimed(uint256 tokenId) public returns (bool result){
        return statusOfToken[tokenId] & 1 == 0;
    }

    function claim() public {
        uint256[] memory tokens = tokensOf(msg.sender);
        uint256[] memory tags = new uint256[](115);
        uint256 counter = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 id = tokens[i];
            if (isClaimed(id)) continue;
            uint256 heroId = characterOfToken[id];
            if (tags[heroId] == 1) continue;
            if (1 <= heroId && heroId <= 108) {
                tags[heroId] = 1;
                counter += 1;
            }            
        }

        if (counter < 108) return;
        emit Claim(msg.sender);
        for (i = 0; i < tokens.length; i++) { 
            id = tokens[i];          
            if (tags[heroId] == 1) continue;
            tags[heroId] = 2;
            statusOfToken[id] |= 1;
        }        
    }
  
    /* Issue */
    function drawToken() public payable {
        uint256 n = getDrawCount(msg.value);
        DappTokenContractAddr.transfer(msg.value);
        while (n > 0) {
            uint256 id = total;
            issueToken();
            uint256 offset;
            uint256 count;
            (offset, count) = getCharacter(getRandomInt(45061));
            characterOfToken[id] = offset + getRandomInt(count);
            n -= 1;
        }
    }
}