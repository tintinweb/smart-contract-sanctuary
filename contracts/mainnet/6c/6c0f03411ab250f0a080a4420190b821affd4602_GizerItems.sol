pragma solidity ^0.4.20;

// ----------------------------------------------------------------------------
//
// Gizer Items - ERC721(ish) contract
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// SafeMath
//
// ----------------------------------------------------------------------------

library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require( a == 0 || c / a == b );
  }

  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require( c >= a );
  }

  function sub(uint a, uint b) internal pure returns (uint c) {
    require( b <= a );
    c = a - b;
  }

}


// ----------------------------------------------------------------------------
//
// Owned
//
// ----------------------------------------------------------------------------

contract Owned {

  address public owner;
  address public newOwner;

  mapping(address => bool) public isAdmin;

  // Events ---------------------------

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);
  event AdminChange(address indexed _admin, bool _status);

  // Modifiers ------------------------

  modifier onlyOwner { require( msg.sender == owner ); _; }
  modifier onlyAdmin { require( isAdmin[msg.sender] ); _; }

  // Functions ------------------------

  function Owned() public {
    owner = msg.sender;
    isAdmin[owner] = true;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require( _newOwner != address(0x0) );
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
  function addAdmin(address _a) public onlyOwner {
    require( isAdmin[_a] == false );
    isAdmin[_a] = true;
    AdminChange(_a, true);
  }

  function removeAdmin(address _a) public onlyOwner {
    require( isAdmin[_a] == true );
    isAdmin[_a] = false;
    AdminChange(_a, false);
  }
  
}


// ----------------------------------------------------------------------------
//
// ERC721(ish) Token Interface 
//
// ----------------------------------------------------------------------------


interface ERC721Interface /* is ERC165 */ {

    event Transfer(address indexed _from, address indexed _to, uint256 _deedId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _deedId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256 _balance);
    function ownerOf(uint256 _deedId) external view returns (address _owner);
    function transfer(address _to, uint256 _deedId) external;                    // removed payable
    function transferFrom(address _from, address _to, uint256 _deedId) external; // removed payable
    function approve(address _approved, uint256 _deedId) external;               // removed payable
    // function setApprovalForAll(address _operateor, boolean _approved);        // removed payable
    // function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721Metadata /* is ERC721 */ {
    function name() external pure returns (string _name);
    function symbol() external pure returns (string _symbol);
    function deedUri(uint256 _deedId) external view returns (string _deedUri);
}

interface ERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (uint256 _count);
    function deedByIndex(uint256 _index) external view returns (uint256 _deedId);
    function countOfOwners() external view returns (uint256 _count);
    // function ownerByIndex(uint256 _index) external view returns (address _owner);
    // function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId);
}


// ----------------------------------------------------------------------------
//
// ERC721 Token
//
// ----------------------------------------------------------------------------

contract ERC721Token is ERC721Interface, ERC721Metadata, ERC721Enumerable, Owned {
  
  using SafeMath for uint;

  uint public ownerCount = 0;
  uint public deedCount = 0;
  
  mapping(address => uint) public balances;
  mapping(uint => address) public mIdOwner;
  mapping(uint => address) public mIdApproved;

  // Required Functions ------------------------

  /* Get the number of tokens held by an address */

  function balanceOf(address _owner) external view returns (uint balance) {
    balance = balances[_owner];
  }

  /* Get the owner of a certain token */

  function ownerOf(uint _id) external view returns (address owner) {
    owner = mIdOwner[_id];
    require( owner != address(0x0) );
  }

  /* Transfer token */
  
  function transfer(address _to, uint _id) external {
    // check ownership and address
    require( msg.sender == mIdOwner[_id] );
    require( _to != address(0x0) );

    // transfer ownership
    mIdOwner[_id] = _to;
    mIdApproved[_id] = address(0x0);

    // update balances
    updateBalances(msg.sender, _to);

    // register event
    Transfer(msg.sender, _to, _id);
  }

  /* Transfer from */
  
  function transferFrom(address _from, address _to, uint _id) external {
    // check if the sender has the right to transfer
    require( _from == mIdOwner[_id] && mIdApproved[_id] == msg.sender );

    // transfer ownership and reset approval (if any)
    mIdOwner[_id] = _to;
    mIdApproved[_id] = address(0x0);

    // update balances
    updateBalances(_from, _to);

    // register event
    Transfer(_from, _to, _id);
  }

  /* Approve token transfer (we do not make it payable) */
  
   function approve(address _approved, uint _id) external {
       require( msg.sender == mIdOwner[_id] );
       require( msg.sender != _approved );
       mIdApproved[_id] = _approved;
       Approval(msg.sender, _approved, _id);
   }

  // Metadata Functions ---------------


  // Enumeration Functions ------------
  
  function totalSupply() external view returns (uint count) {
    count = deedCount;
  }

  function deedByIndex(uint _index) external view returns (uint id) {
    id = _index;
    require( id < deedCount );
  }  
  
  function countOfOwners() external view returns (uint count) {
    count = ownerCount;
  }
  
  // Internal functions ---------------
  
  function updateBalances(address _from, address _to) internal {
    // process from (skip if minted)
    if (_from != address(0x0)) {
      balances[_from]--;
      if (balances[_from] == 0) { ownerCount--; }
    }
    // process to
    balances[_to]++;
    if (balances[_to] == 1) { ownerCount++; }
  }
      
}


// ----------------------------------------------------------------------------
//
// ERC721 Token
//
// ----------------------------------------------------------------------------

contract GizerItems is ERC721Token {

  /* Basic token data */
  
  string constant cName   = "Gizer Item";
  string constant cSymbol = "GZR721";
  
  /* uuid information */

  bytes32[] public code;
  uint[] public weight;
  uint public sumOfWeights;
  
  mapping(bytes32 => uint) public mCodeIndexPlus; // index + 1

  /* Pseudo-randomisation variables */

  uint public nonce = 0;
  uint public lastRandom = 0;
  
  /* mapping from item index to uuid */
  
  mapping(uint => bytes32) public mIdxUuid;
  
  // Events ---------------------------
  
  event MintToken(address indexed minter, address indexed _owner, bytes32 indexed _code, uint _input);
  
  event CodeUpdate(uint8 indexed _type, bytes32 indexed _code, uint _weight, uint _sumOfWeights);
  
  // Basic Functions ------------------
  
  function GizerItems() public { }
  
  function () public payable { revert(); }
  
  // Information functions ------------

  function name() external pure returns (string) {
    return cName;
  }
  
  function symbol() external pure returns (string) {
    return cSymbol;
  }
  
  function deedUri(uint _id) external view returns (string) {
    return bytes32ToString(mIdxUuid[_id]);
  }
  
  function getUuid(uint _id) external view returns (string) {
    require( _id < code.length );
    return bytes32ToString(code[_id]);  
  }

  // Token Minting --------------------
  
  function mint(address _to) public onlyAdmin returns (uint idx) {
    
    // initial checks
    require( sumOfWeights > 0 );
    require( _to != address(0x0) );
    require( _to != address(this) );

    // get random uuid
    bytes32 uuid32 = getRandomUuid();

    // mint token
    deedCount++;
    idx = deedCount;
    mIdxUuid[idx] = uuid32;

    // update balance and owner count
    updateBalances(address(0x0), _to);
    mIdOwner[idx] = _to;

    // log event and return
    MintToken(msg.sender, _to, uuid32, idx);
  }
  
  // Random
  
  function getRandomUuid() internal returns (bytes32) {
    // case where there is only one item type
    if (code.length == 1) return code[0];

    // more than one
    updateRandom();
    uint res = lastRandom % sumOfWeights;
    uint cWeight = 0;
    for (uint i = 0; i < code.length; i++) {
      cWeight = cWeight + weight[i];
      if (cWeight >= res) return code[i];
    }

    // we should never get here
    revert();
  }

  function updateRandom() internal {
    nonce++;
    lastRandom = uint(keccak256(
        nonce,
        lastRandom,
        block.blockhash(block.number - 1),
        block.coinbase,
        block.difficulty
    ));
  }
  
  // uuid functions -------------------
  
  /* add a new code + weight */
  
  function addCode(string _code, uint _weight) public onlyAdmin returns (bool success) {

    bytes32 uuid32 = stringToBytes32(_code);

    // weight posiitve & code not yet registered
    require( _weight > 0 );
    require( mCodeIndexPlus[uuid32] == 0 );

    // add to end of array
    uint idx = code.length;
    code.push(uuid32);
    weight.push(_weight);
    mCodeIndexPlus[uuid32] = idx + 1;

    // update sum of weights
    sumOfWeights = sumOfWeights.add(_weight);

    // register event and return
    CodeUpdate(1, uuid32, _weight, sumOfWeights);
    return true;
  }
  
  /* update the weight of an existing code */
  
  function updateCodeWeight(string _code, uint _weight) public onlyAdmin returns (bool success) {

    bytes32 uuid32 = stringToBytes32(_code);

    // weight positive & code must be registered
    require( _weight > 0 );
    require( mCodeIndexPlus[uuid32] > 0 );

    // update weight and sum of weights
    uint idx = mCodeIndexPlus[uuid32] - 1;
    uint oldWeight = weight[idx];
    weight[idx] = _weight;
    sumOfWeights = sumOfWeights.sub(oldWeight).add(_weight);

    // register event and return
    CodeUpdate(2, uuid32, _weight, sumOfWeights);
    return true;
  }
  
  /* remove an existing code */
  
  function removeCode(string _code) public onlyAdmin returns (bool success) {

    bytes32 uuid32 = stringToBytes32(_code);

    // code must be registered
    require( mCodeIndexPlus[uuid32] > 0 );

    // index of code to be deleted
    uint idx = mCodeIndexPlus[uuid32] - 1;
    uint idxLast = code.length - 1;

    // update sum of weights and remove mapping
    sumOfWeights = sumOfWeights.sub(weight[idx]);
    mCodeIndexPlus[uuid32] = 0;

    if (idx != idxLast) {
      // if we are not deleting the last element:
      // move last element to index of deleted element
      code[idx] = code[idxLast];
      weight[idx] = weight[idxLast];
      mCodeIndexPlus[code[idxLast]] = idx;
    }
    // delete last element of arrays
    delete code[idxLast];
    code.length--;
    delete weight[idxLast];
    weight.length--;

    // register event and return
    CodeUpdate(3, uuid32, 0, sumOfWeights);
    return true;
  }

  /* Transfer out any accidentally sent ERC20 tokens */

  function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }
  
  // Utility functions ----------------

  /* https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32 */
  
  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
  }
  
  /* https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string */

  function bytes32ToString(bytes32 x) public pure returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
      byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }
  
}

// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
// ----------------------------------------------------------------------------

contract ERC20Interface {
  function transfer(address _to, uint _value) public returns (bool success);
}