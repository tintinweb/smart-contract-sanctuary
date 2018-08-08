pragma solidity ^0.4.19;


/**
 * @title safemath
 * @dev Math operations with safety checks that throw on error
 */
library safemath {

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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



/**
 * @title ownable
 * @dev The ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract erc721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}



contract KTaccess is ownable{
    address public o1Address;
    address public o2Address;
    address public o3Address;
    
    modifier onlyOLevel() {
        require(
            msg.sender == o1Address ||
            msg.sender == o2Address ||
            msg.sender == o3Address ||
            msg.sender == owner
        );
        _;
    }

    function setO1(address _newAddr) external onlyOLevel {
        require(_newAddr != address(0));

        o1Address = _newAddr;
    }

    function setO2(address _newAddr) external onlyOLevel {
        require(_newAddr != address(0));

        o2Address = _newAddr;
    }
    
    function setO3(address _newAddr) external onlyOLevel {
        require(_newAddr != address(0));

        o3Address = _newAddr;
    }

}




contract KTfactory is ownable, KTaccess {

  using safemath for uint256;

  uint256 public maxId;

  uint256 public initial_supply;

  uint256 public curr_number;

  event NewKT(string note, uint256 gene, uint256 level, uint256 tokenId);
  event UpdateNote(string newNote, uint256 tokenId);
  event PauseToken(uint256 tokenId);

  struct KT {
    string officialNote;
    string personalNote;
    bool paused;
    uint256 gene;
    uint256 level;
    uint256 id;
  }

  mapping (uint256 => KT) public KTs;

  mapping (uint => address) public KTToOwner;
  mapping (address => uint) ownerKTCount;

  modifier onlyOwnerOf(uint token_id) {
    require(msg.sender == KTToOwner[token_id]);
    _;
  }

  modifier whenNotFrozen(uint token_id) {
    require(KTs[token_id].paused == false);
    _;
  }

  modifier decomposeAllowed(uint token_id){
    require(KTs[token_id].level >= 1);
    _;
  }

  modifier withinTotal() {
    require(curr_number<= initial_supply);
    _;
  }

  modifier hasKT(uint token_id) {
    require(KTs[token_id].id != 0);
    _;
  }

  constructor() public {
    initial_supply = 2100;
    maxId=0;
    curr_number=0;
  }

  function _createKT(string oNote) public onlyOLevel withinTotal {
    uint thisId = maxId + 1;
    string pNote;
    uint256 thisGene = uint256(keccak256(oNote));
    KT memory thisKT = KT({officialNote: oNote, personalNote: pNote, paused: false, gene: thisGene, level: 1, id: thisId});
    KTs[thisId] = thisKT;
    maxId = maxId + 1;
    curr_number = curr_number + 1;
    KTToOwner[thisId] = msg.sender;
    ownerKTCount[msg.sender]++;
    emit NewKT(oNote, thisGene, 1, thisId);
  }

  function _editPersonalNote(string note, uint token_id) public onlyOwnerOf(token_id) hasKT(token_id){
    KT storage currKT = KTs[token_id];
    currKT.personalNote = note;
    UpdateNote(note, token_id);
  }

  function pauseToken(uint token_id) onlyOLevel hasKT(token_id){
    KT storage currKT = KTs[token_id];
    currKT.paused = true;
    PauseToken(token_id);
  }

}


contract KTownership is KTfactory, erc721 {

  using safemath for uint256;

  mapping (uint => address) KTApprovals;

  //event Transfer(address from, address to, uint256 tokenId);
  //event Approval(address from, address to, uint256 tokenId);
  event Decompose(uint256 tokenId);
  event Merge(uint256 tokenId1, uint256 tokenId2);

  function withdraw() external onlyOwner {
    owner.transfer(this.balance);
  }

  function balanceOf(address _owner) public view returns(uint256) {
    return ownerKTCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns(address) {
    return KTToOwner[_tokenId];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) private hasKT(_tokenId) {
    ownerKTCount[_to] = ownerKTCount[_to].add(1);
    ownerKTCount[msg.sender] = ownerKTCount[msg.sender].sub(1);
    KTToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) public whenNotFrozen(_tokenId) onlyOwnerOf(_tokenId) hasKT(_tokenId){
    require(_to != address(0));
    _transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) hasKT(_tokenId) {
    require(_to != address(0));
    KTApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public whenNotFrozen(_tokenId) hasKT(_tokenId){
    require(KTApprovals[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }

  // level down!!!
  // gene remains identical!!!
  // notes identical!!!
  function decompose(uint256 token_id) public whenNotFrozen(token_id) onlyOwnerOf(token_id) decomposeAllowed(token_id) hasKT(token_id) withinTotal{
    KT storage decomposed = KTs[token_id];
    decomposed.level = decomposed.level-1;
    decomposed.gene = decomposed.gene/2;

    KT memory newKT = KT({
      officialNote: decomposed.officialNote,
      personalNote: decomposed.personalNote,
      paused: false,
      gene: decomposed.gene,
      level: decomposed.level,
      id: maxId.add(1)
    });
    
    maxId=maxId.add(1);
    curr_number=curr_number.add(1);
    KTs[maxId]=newKT;
    KTToOwner[maxId]=KTToOwner[token_id];
    ownerKTCount[msg.sender]=ownerKTCount[msg.sender].add(1);

    emit Decompose(token_id);
  }

  // id and officialNote merged to the previous one
  // level up!!!
  // gene = (gene1 + gene2) /2
  function merge(uint256 id1, uint256 id2) public hasKT(id1) hasKT(id2) whenNotFrozen(id1) whenNotFrozen(id2) onlyOwnerOf(id1) onlyOwnerOf(id2){
    require(KTs[id1].level == KTs[id2].level);
    KT storage token1 = KTs[id1];
    token1.gene = (token1.gene + KTs[id2].gene) / 2;
    token1.level = (token1.level).add(1);

    KT memory toDelete = KT ({
      officialNote: "",
      personalNote: "",
      paused: false,
      gene: 0,
      level: 0,
      id: 0
    });

    KTs[id2] = toDelete;
    curr_number=curr_number.sub(1);
    ownerKTCount[msg.sender]=ownerKTCount[msg.sender].sub(1);

    emit Merge(id1, id2);
  }
}