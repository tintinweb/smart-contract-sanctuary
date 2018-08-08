/**
 * Token name: KT
 * Interface: ERC721
 * This token is established by Krypital Group, mainly used as a commemorative token for Krypital supporters.
 * Total supply of KTs is limited to 2100.
 * A KT holder can either hold it as a souvenir (leave message on the message board), or play the game by merging/decomposing tokens.
 * Tokens can used to exchange for future holder benefits provided by Krypital. Details coming soon on Krypital&#39;s website: https://krypital.com/  
 * More news about Krypital on Telegram: https://t.me/KrypitalNews
 * @author: https://github.com/1994wyh-WYH
 */
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
  constructor () public {
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
    emit OwnershipTransferred(owner, newOwner);
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


/**
 *  @title KTaccess
 *  @author https://github.com/1994wyh-WYH
 *  @dev This contract is for regulating the owners&#39; addr.
 *  Inherited by KTfactory.
 */
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


/**
 * @title KTfactory
 * @author https://github.com/1994wyh-WYH
 * @dev This main contract for creating KTs.
 * 
 * A KT, which is the token issued by Krypital, has the following properties: 
 * an officail note that can be created only by the contract owner;
 * a personal note that can be modified by the current owner of the token;
 * a bool value indicating if the token is currently frozen by Krypital;
 * a gene which is a hashed value that changes when mutate (merge or decompose). This is for some future interesting apps :D 
 * level, namely, the level of the token. Apparently higher is better :D
 * id, the key used to map to the associated KT.
 * 
 */

contract KTfactory is ownable, KTaccess {

  using safemath for uint256;

  uint256 public maxId;

  uint256 public initial_supply;

  uint256 public curr_number;

  event NewKT(string note, uint256 gene, uint256 level, uint256 tokenId);
  event UpdateNote(string newNote, uint256 tokenId);
  event PauseToken(uint256 tokenId);
  event UnpauseToken(uint256 tokenId);
  event Burn(uint256 tokenId);

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

  modifier withinTotal() {
    require(curr_number<= initial_supply);
    _;
  }

  modifier hasKT(uint token_id) {
    require(KTs[token_id].id != 0);
    _;
  }
    
    /**
     * @dev The constructor. Sets the initial supply and some other global variables.
     * That&#39;s right, Krypital will only issue 2100 tokens in total. It also means the total number of KTs will not exceed this number!
     */
  constructor() public {
    initial_supply = 2100;
    maxId=0;
    curr_number=0;
  }

    /**
     * @dev The creator of KTs. Only done by Krypital.
     * @param oNote - the official, special note left only by Krypital!
     */
  function _createKT(string oNote) public onlyOLevel withinTotal {
    uint thisId = maxId + 1;
    uint256 thisGene = uint256(keccak256(oNote));
    
    KT memory thisKT = KT({
        officialNote: oNote, 
        personalNote: "", 
        paused: false, 
        gene: thisGene, 
        level: 1, 
        id: thisId
    });
    
    KTs[thisId] = thisKT;
    maxId = maxId + 1;
    curr_number = curr_number + 1;
    KTToOwner[thisId] = msg.sender;
    ownerKTCount[msg.sender]++;
    emit NewKT(oNote, thisGene, 1, thisId);
  }
    
    /**
     * @dev This method is for editing your personal note!
     * @param note - the note you want the old one to be replaced by
     * @param token_id - just token id
     */
  function _editPersonalNote(string note, uint token_id) public onlyOwnerOf(token_id) hasKT(token_id){
    KT storage currKT = KTs[token_id];
    currKT.personalNote = note;
    emit UpdateNote(note, token_id);
  }
    
    /**
     * @dev Pauses a token, done by Krypital
     * When a token is paused by Krypital, the owner of the token can still update the personal note but the ownership cannot be transferred.
     * @param token_id - just token id
     */
  function pauseToken(uint token_id) public onlyOLevel hasKT(token_id){
    KT storage currKT = KTs[token_id];
    currKT.paused = true;
    emit PauseToken(token_id);
  }
  
  /**
   * @dev Unpauses a token, done by Krypital
   * @param token_id - just token id
   */
  function unpauseToken(uint token_id) public onlyOLevel hasKT(token_id){
    KT storage currKT = KTs[token_id];
    currKT.paused = false;
    emit UnpauseToken(token_id);
  }
  
  /**
   * @dev Burns a token, reduce the current number of KTs by 1.
   * @param token_id - simply token id.
   */
   function burn(uint token_id) public onlyOLevel hasKT(token_id){
       KT storage currKT = KTs[token_id];
       currKT.id=0;
       currKT.level=0;
       currKT.gene=0;
       currKT.officialNote="";
       currKT.personalNote="";
       currKT.paused=true;
       curr_number=curr_number.sub(1);
       emit Burn(token_id);
   } 

}


/**
 * @title KT
 * @author https://github.com/1994wyh-WYH
 * @dev This contract is the contract regulating the transfer, decomposition, merging mechanism amaong the tokens.
 */
contract KT is KTfactory, erc721 {

  using safemath for uint256;

  mapping (uint => address) public KTApprovals;
  
  /**
   * @dev The modifer to regulate a KT&#39;s decomposability.
   * A level 1 KT is not decomposable.
   * @param token_id - simply token id.
   */
  modifier decomposeAllowed(uint token_id){
    require(KTs[token_id].level > 1);
    _;
  }

  event Decompose(uint256 tokenId);
  event Merge(uint256 tokenId1, uint256 tokenId2);

    /**
     * @dev This is for getting the ether back to the contract owner&#39;s account. Just in case someone generous sends the creator some ethers :P
     */
  function withdraw() external onlyOwner {
    owner.transfer(this.balance);
  }

    /**
     * @dev For checking how many tokens you own.
     * @param _owner - the owner&#39;s addr
     */
  function balanceOf(address _owner) public view returns(uint256) {
    return ownerKTCount[_owner];
  }
    
    /**
     * @dev For checking the owner of the given token.
     * @param _tokenId - just token id
     */
  function ownerOf(uint256 _tokenId) public view returns(address) {
    return KTToOwner[_tokenId];
  }

    /**
     * @dev the private helper function for transfering ownership.
     * @param _from - current KT owner
     * @param _to - new KT owner
     * @param _tokenId - just token id
     */
  function _transfer(address _from, address _to, uint256 _tokenId) private hasKT(_tokenId) {
    ownerKTCount[_to] = ownerKTCount[_to].add(1);
    ownerKTCount[msg.sender] = ownerKTCount[msg.sender].sub(1);
    KTToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

    /**
     * @dev This method can be called if you are the token owner and you want to transfer the token to someone else.
     * @param _to - new KT owner
     * @param _tokenId - just token id
     */
  function transfer(address _to, uint256 _tokenId) public whenNotFrozen(_tokenId) onlyOwnerOf(_tokenId) hasKT(_tokenId){
    require(_to != address(0));
    _transfer(msg.sender, _to, _tokenId);
  }
    
    /**
     * @dev An approved user can &#39;claim&#39; a token of another user.
     * @param _to - new KT owner
     * @param _tokenId - just token id
     */
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) hasKT(_tokenId) {
    KTApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }
    
    /**
     * @dev The user to be approved must be approved by the current token holder.
     * @param _tokenId - just token id
     */
  function takeOwnership(uint256 _tokenId) public whenNotFrozen(_tokenId) hasKT(_tokenId){
    require(KTApprovals[_tokenId] == msg.sender);
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }

  /**
   * @dev This method is for decomposing (or split) a token. Only can be done by token holder when token is not frozen.
   * Note: one of the tokens will take the original token&#39;s place, that is, the old ID will actually map to a new token!
   * Level down by 1!!! A level 1 token cannot be decomposed.
   * The genes of the two new born tokens will be both identical to the old token.
   * Notes of the two new tokens are identical to the original token.
   */
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

    /**
     * @dev This function is for merging 2 tokens. Only tokens with the same levels can be merge. A user can only choose to merge from his own tokens.
     * After merging, id and official note are merged to the previous token passed in the args.
     * NOTE that the notes associated with the second token will be wiped out! Use with your caution.
     * Level up by 1!!!
     * New gene = (gene1 + gene2) / 2
     * @param id1 - the ID to the 1st token, this ID will remain after merging.
     * @param id2 - the ID of the 2nd token, this ID will map to nothing after merging!!
     */
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
    curr_number = curr_number.sub(1);
    KTToOwner[id2] = address(0);
    ownerKTCount[msg.sender] = ownerKTCount[msg.sender].sub(1);

    emit Merge(id1, id2);
  }
  
}