pragma solidity ^0.4.18;


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// inspired by
// https://github.com/axiomzen/cryptokitties-bounty/blob/master/contracts/KittyAccessControl.sol
contract AccessControl {
    /// @dev The addresses of the accounts (or contracts) that can execute actions within each roles
    address public ceoAddress;
    address public cooAddress;

    /// @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev The AccessControl constructor sets the original C roles of the contract to the sender account
    function AccessControl() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Access modifier for any CLevel functionality
    modifier onlyCLevel() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Pause the smart contract. Only can be called by the CEO
    function pause() public onlyCEO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Only can be called by the CEO
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}




/**
 * Interface for required functionality in the ERC721 standard
 * for non-fungible tokens.
 *
 * Author: Nadav Hollander (nadav at dharma.io)
 * https://github.com/dharmaprotocol/NonFungibleToken/blob/master/contracts/ERC721.sol
 */
contract ERC721 {
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// For querying totalSupply of token.
    function totalSupply() public view returns (uint256 _totalSupply);

    /// For querying balance of a particular account.
    /// @param _owner The address for balance query.
    /// @dev Required for ERC-721 compliance.
    function balanceOf(address _owner) public view returns (uint256 _balance);

    /// For querying owner of token.
    /// @param _tokenId The tokenID for owner inquiry.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId) public view returns (address _owner);

    /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom()
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(address _to, uint256 _tokenId) public;

    // NOT IMPLEMENTED
    // function getApproved(uint256 _tokenId) public view returns (address _approved);

    /// Third-party initiates transfer of token from address _from to address _to.
    /// @param _from The address for the token to be transferred from.
    /// @param _to The address for the token to be transferred to.
    /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    /// Owner initates the transfer of the token to another account.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the token to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(address _to, uint256 _tokenId) public;

    ///
    function implementsERC721() public view returns (bool _implementsERC721);

    // EXTRA
    /// @notice Allow pre-approved user to take ownership of a token.
    /// @param _tokenId The ID of the token that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function takeOwnership(uint256 _tokenId) public;
}


contract DetailedERC721 is ERC721 {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
}


contract Crypto is AccessControl, DetailedERC721 {
    using SafeMath for uint256;
    StripToken public POLY;
    address public newModifier;
    address owner = msg.sender;
    uint256 private count = 0;

    struct tokenData {
    bytes32 name;
    uint256 stat;
    uint256 time;
    }
    struct Foo{
        uint256 x;
    }
    mapping(address => Foo[]) userData;
    mapping(uint256 => tokenData) private storeDetails;
    modifier  OwnerOnly {
        if(msg.sender != owner){
            revert();
        } else {
            _;
        }
    }
    function incrementCounter() private {
        count += 1;
    }
    function getCount() private constant returns (uint256) {
        return count;
    }
  //Storing Token data like name,time,status
    function insertDetails(string data, uint256 status,uint256 time) private
  {

    incrementCounter();
    uint256 count1=getCount();
    bytes32 name=stringToBytes32(data);
    storeDetails[count1].name = name;
    storeDetails[count1].stat   = status;
    storeDetails[count1].time     = time;
    userData[msg.sender].push(Foo(count1));

  }
  //Get all token data
 function get() public view returns (
        bytes32[],
        uint256[],
        uint256[]
    ) {
       // return userData[id][index].x;
       address id=msg.sender;
       uint256 total = userData[id].length;
       bytes32[] memory name = new bytes32[](total);
       uint256[] memory status = new uint256[](total);
       uint256[] memory time = new uint256[](total);

        for (uint i = 0; i < total; i++) {

      name[i]= storeDetails[userData[id][i].x].name;
      status[i]= storeDetails[userData[id][i].x].stat;
       time[i]= storeDetails[userData[id][i].x].time;
   }
       return (name, status, time);
    }

    function  nContract() public OwnerOnly {
        selfdestruct(owner);
    }
    function totalnSupply() public view returns (uint256 _total) {
        _total =userData[msg.sender].length;
    }
//Convert String to bytes32
function stringToBytes32(string memory source) private returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }
    assembly {
        result := mload(add(source, 32))
    }
}


    event TokenCreated(uint256 tokenId, string name, bytes5 newRandom, uint256 price, address owner);
    event TokenSold(
        uint256 indexed tokenId,
        string name,
        bytes5 newRandom,
        uint256 sellingPrice,
        uint256 newPrice,
        address indexed oldOwner,
        address indexed newOwner
        );


    mapping (uint256 => address) private tokenIdToOwner;
    mapping (uint256 => uint256) private tokenIdToPrice;
    mapping (address => uint256) private ownershipTokenCount;
    mapping (uint256 => address) private tokenIdToApproved;
	  mapping (uint256 => uint256) private tokenIdToStatus;
 	  mapping (uint256 => string) private tokenIdURI;
	  mapping (uint256 => string) private dataURI;


    struct Strip {
        string name;
        bytes5 newRandom;
		string tokenURI;
    }

    struct StripInfo {
        string image_Url;
        string home_Url;
        string desc;
        string tags;
        string prop;

    }

    Strip[] private strips ;
    StripInfo[] private stripInfo ;

    function Crypto() public{
      POLY = new StripToken(this);
    }

    uint256 private startingPrice = 0.01 ether;
    bool private erc721Enabled = true;

    modifier onlyERC721() {
        require(erc721Enabled);
        _;
    }

    function setNewModifier(address _new) public  {
        require(msg.sender == owner);
        newModifier = _new;
    }

    function createT(string _name,string i_url,string h_url,string desc,string tag,string prop,uint256 _price,uint256 time) public  {

      if(msg.sender == owner || msg.sender == newModifier) {
            bytes5 _newRandom = _generateNewRandom();
            //insertDetails(_name,1,time);

            _createToken(_name, _newRandom, i_url, h_url, desc, tag, prop, address(this), _price);
        }
    }
    
  function getTokenURI(uint256 _tokenId) public view returns (string){
      require(_tokenId<strips.length);
      return strips[_tokenId].tokenURI;
  }

  function setTokenURI(uint256 _tokenId, string newURI) public {
      address _owner = tokenIdToOwner[_tokenId];
      require(_tokenId<strips.length);
                   if(msg.sender == _owner ) {
             Strip storage _Strip  = strips[_tokenId];
      _Strip.tokenURI = newURI;
	     }
  }


 function getUserBalance(address user) public view returns (uint) {
        return user.balance;
    }


 function createSale(uint256 _price,uint256 _tokenId,uint256 _status,string tname,uint256 time) public  {
   address _owner = tokenIdToOwner[_tokenId];

       if(msg.sender == _owner ) {
           insertDetails(tname,_status,time);
           tokenIdToPrice[_tokenId] = _price;
           tokenIdToStatus[_tokenId] =_status;
         }
}



  function transferAD() public {
            POLY.transfer(msg.sender, 1000);
            POLY.approve(msg.sender, 1000);
  }


  function balanceAD() public view returns (uint256 balance) {
      return POLY.balanceOf(msg.sender);
  }

  function _generateNewRandom() private view returns (bytes5) {
      uint256 lastBlockNumber = block.number - 1;
      bytes32 hashVal = bytes32(block.blockhash(lastBlockNumber));
      bytes5 newRandom = bytes5((hashVal & 0xffffffff) << 216);
      return newRandom;
  }

    function _createToken(string _name, bytes5 _newRandom,string i_url,string h_url,string desc1,string tag,string prop1, address _owner, uint256 _price) private {
        Strip memory _Strip = Strip({
            name: _name,
            newRandom: _newRandom,
            tokenURI:_name
        });
        uint256 newTokenId = strips.push(_Strip) - 1;

        StripInfo memory _Stripinfo = StripInfo({
            image_Url: i_url,
            home_Url: h_url,
            desc: desc1,
            tags: tag,
            prop: prop1
        });
        stripInfo.push(_Stripinfo);

        tokenIdToPrice[newTokenId] = _price;
		tokenIdToStatus[newTokenId] = 0;
        TokenCreated(newTokenId, _name, _newRandom, _price, _owner);
        _transfer(address(0), _owner, newTokenId);
    }



function getTokenMetaData(uint256 _tokenId) public view returns (
        string _tokenName,
        string i_url,
        string h_url,
        string desc,
        string tag,
        string prop
    ) {
        _tokenName = strips[_tokenId].name;
         i_url=stripInfo[_tokenId].image_Url;
         h_url=stripInfo[_tokenId].home_Url;
         desc=stripInfo[_tokenId].desc;
         tag=stripInfo[_tokenId].tags;
         prop=stripInfo[_tokenId].prop;
    }


     function getToken(uint256 _tokenId) public view returns (
        string _tokenName,
        bytes5 _newRandom,
        uint256 _price,
	    string uri,
        address _owner,
        uint256 _status
    ) {
        _tokenName = strips[_tokenId].name;
        _newRandom = strips[_tokenId].newRandom;
        _price = tokenIdToPrice[_tokenId];
		uri = strips[_tokenId].tokenURI;
        _owner = tokenIdToOwner[_tokenId];
        _status = tokenIdToStatus[_tokenId];
    }

    function getAllTokens() public view returns (
        uint256[],
        uint256[],
        address[]
    ) {
        uint256 total = totalSupply();
        uint256[] memory prices = new uint256[](total);
        uint256[] memory nextPrices = new uint256[](total);
        address[] memory owners = new address[](total);

        for (uint256 i = 0; i < total; i++) {
            tokenIdToPrice[i] = i;
         //   nextPrices[i] = nextPriceOf(i);
            tokenIdToOwner[i] = 0xffffffff;
        }

        return (prices, nextPrices, owners);
    }

  function churn() public { //self-destruct function,
     if(msg.sender == owner) {
      selfdestruct(owner);
          }
  }

    function tokensOf(address _owner) public view returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            for (uint256 i = 0; i < total; i++) {
                if (tokenIdToOwner[i] == _owner) {
                    result[resultIndex] = i;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function withdrawBalance(address _to, uint256 _amount) public onlyCEO {
        require(_amount <= this.balance);

        if (_amount == 0) {
            _amount = this.balance;
        }

        if (_to == address(0)) {
            ceoAddress.transfer(_amount);
        } else {
            _to.transfer(_amount);
        }
    }
    function priceOf(uint256 _tokenId) public view returns (uint256 _price) {
        return tokenIdToPrice[_tokenId];
    }

    function purchase(uint256 _tokenId,uint256 time) public payable whenNotPaused {
        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        //uint256 sellingPrice = tokenIdToPrice(_tokenId);
        uint256 sellingPrice = priceOf(_tokenId);
        //_price = tokenIdToPrice[_tokenId];
        require(oldOwner != address(0));
        require(newOwner != address(0));
        require(oldOwner != newOwner);
        require(!_isContract(newOwner));
        require(msg.value >= sellingPrice);
		oldOwner.call.value(msg.value).gas(20317)();
        _transfer(oldOwner, newOwner, _tokenId);
     	tokenIdToStatus[_tokenId] = 0;
      //   POLY.transferFrom(msg.sender,oldOwner,sellingPrice);
		 insertDetails(strips[_tokenId].name,1,time);
     //   tokenIdToPrice[_tokenId] = nextPriceOf(_tokenId);
        TokenSold(
            _tokenId,
            strips[_tokenId].name,
            strips[_tokenId].newRandom,
            sellingPrice,
            priceOf(_tokenId),
            oldOwner,
            newOwner
        );
    }


    function enableERC721() public onlyCEO {
        erc721Enabled = true;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        _totalSupply = strips.length;
    }

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        _balance = ownershipTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        _owner = tokenIdToOwner[_tokenId];
    }

    function approve(address _to, uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_owns(msg.sender, _tokenId));
        tokenIdToApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_to != address(0));
        require(_owns(_from, _tokenId));
        require(_approved(msg.sender, _tokenId));
        _transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_to != address(0));
        require(_owns(msg.sender, _tokenId));

        _transfer(msg.sender, _to, _tokenId);
    }

    function implementsERC721() public view whenNotPaused returns (bool) {
        return erc721Enabled;
    }

    function takeOwnership(uint256 _tokenId) public whenNotPaused onlyERC721 {
        require(_approved(msg.sender, _tokenId));
        _transfer(tokenIdToOwner[_tokenId], msg.sender, _tokenId);
    }

    function name() public view returns (string _name) {
        _name = "STRIP NFT";
    }

    function symbol() public view returns (string _symbol) {
        _symbol = "STR";
    }

    function _owns(address _claimant, uint256 _tokenId) private view returns (bool) {
        return tokenIdToOwner[_tokenId] == _claimant;
    }

    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return tokenIdToApproved[_tokenId] == _to;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        tokenIdToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete tokenIdToApproved[_tokenId];
        }

        Transfer(_from, _to, _tokenId);
    }

    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

/*
Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
interface IERC20 {
  function balanceOf(address _owner) public view returns (uint256);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */


contract StripToken is IERC20 {
  using SafeMath for uint256;

  // Poly Token parameters
  address owner = msg.sender;
  string public name = &#39;ERC 20 TestToken&#39;;
  string public symbol = &#39;ERC&#39;;
  uint8 public constant decimals = 0;
  uint256 public constant decimalFactor = 1;
  uint256 public constant totalSupply = 1000000000 ;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);



function StripToken(address _polyDistributionContractAddress) public {

    balances[_polyDistributionContractAddress] = totalSupply;

  }



  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }


  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     if (msg.sender == owner && balances[_from] >= _value ) {
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
  //  allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
     }else {
         return false;
     }
  }


  function approve(address _spender, uint256 _value) public returns (bool) {

     allowed[_spender][msg.sender] = _value;
        Approval(_spender,msg.sender,  _value);
    return true;
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}