pragma solidity ^0.4.18; // solhint-disable-line



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="274342534267465f4e484a5d4249094448">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}


contract OpinionToken is ERC721 {

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new opinion comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721. 
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "Cryptopinions"; // solhint-disable-line
  string public constant SYMBOL = "OpinionToken"; // solhint-disable-line
  string public constant DEFAULT_TEXT = "";

  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;
  uint256 private numIssued=5; //number of tokens issued initially
  uint256 private constant stepMultiplier=2;//multiplier for initial opinion registration cost, not sponsorship
  uint256 private startingPrice = 0.001 ether; //will increase every token issued by stepMultiplier times
  uint256 private sponsorStartingCost=0.01 ether;//initial cost to sponsor an opinion
  //uint256 private currentIssueRemaining;
  /*** STORAGE ***/

  /// @dev A mapping from opinion IDs to the address that owns them. All opinions have
  ///  some valid owner address.
  mapping (uint256 => address) public opinionIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from opinionIDs to an address that has been approved to call
  ///  transferFrom(). Each opinion can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public opinionIndexToApproved;

  // @dev A mapping from opinionIDs to the price of the token.
  mapping (uint256 => uint256) private opinionIndexToPrice;
  
  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;

  /*** DATATYPES ***/
  struct Opinion {
    string text;
    bool claimed;
    bool deleted;
    uint8 comment;
    address sponsor;
    address antisponsor;
    uint256 totalsponsored;
    uint256 totalantisponsored;
    uint256 timestamp;
  }

  Opinion[] private opinions;

  /*** ACCESS MODIFIERS ***/
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

  /// Access modifier for contract owner only functionality
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

  /*** CONSTRUCTOR ***/
  function OpinionToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

  /*** PUBLIC FUNCTIONS ***/
  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    opinionIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }
  /// @dev Creates initial set of opinions. Can only be called once.
  function createInitialItems() public onlyCOO {
    require(opinions.length==0);
    _createOpinionSet();
  }

  /// @notice Returns all the relevant information about a specific opinion.
  /// @param _tokenId The tokenId of the opinion of interest.
  function getOpinion(uint256 _tokenId) public view returns (
    uint256 sellingPrice,
    address owner,
    address sponsor,
    address antisponsor,
    uint256 amountsponsored,
    uint256 amountantisponsored,
    uint8 acomment,
    uint256 timestamp,
    string opinionText
  ) {
    Opinion storage opinion = opinions[_tokenId];
    opinionText = opinion.text;
    sellingPrice = opinionIndexToPrice[_tokenId];
    owner = opinionIndexToOwner[_tokenId];
    acomment=opinion.comment;
    sponsor=opinion.sponsor;
    antisponsor=opinion.antisponsor;
    amountsponsored=opinion.totalsponsored;
    amountantisponsored=opinion.totalantisponsored;
    timestamp=opinion.timestamp;
  }

  function compareStrings (string a, string b) public pure returns (bool){
       return keccak256(a) == keccak256(b);
   }
  
  function hasDuplicate(string _tocheck) public view returns (bool){
    return hasPriorDuplicate(_tocheck,opinions.length);
  }
  
  function hasPriorDuplicate(string _tocheck,uint256 index) public view returns (bool){
    for(uint i = 0; i<index; i++){
        if(compareStrings(_tocheck,opinions[i].text)){
            return true;
        }
    }
    return false;
  }
  
  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /// @dev Required for ERC-721 compliance.
  function name() public pure returns (string) {
    return NAME;
  }

  /// For querying owner of token
  /// @param _tokenId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = opinionIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

  function sponsorOpinion(uint256 _tokenId,uint8 comment,bool _likesOpinion) public payable {
      //ensure comment corresponds to status of token. Tokens with a comment of 0 are unregistered.
      require(comment!=0);
      require((_likesOpinion && comment<100) || (!_likesOpinion && comment>100));
      address sponsorAdr = msg.sender;
      require(_addressNotNull(sponsorAdr));
      // Making sure sent amount is greater than or equal to the sellingPrice
      uint256 sellingPrice = opinionIndexToPrice[_tokenId];
      address currentOwner=opinionIndexToOwner[_tokenId];
      address newOwner = msg.sender;
      require(_addressNotNull(newOwner));
      require(_addressNotNull(currentOwner));
      require(msg.value >= sellingPrice);
      uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 90), 100));
      uint256 ownerTake=uint256(SafeMath.div(SafeMath.mul(sellingPrice, 10), 100));
      uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
          // Update prices
    if (sellingPrice < firstStepLimit) {
      // first stage
      opinionIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 90);
    } else if (sellingPrice < secondStepLimit) {
      // second stage
      opinionIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 90);
    } else {
      // third stage
      opinionIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 90);
    }
    Opinion storage opinion = opinions[_tokenId];
    require(opinion.claimed);
    require(sponsorAdr!=opinion.sponsor);
    require(sponsorAdr!=opinion.antisponsor);
    require(sponsorAdr!=currentOwner);
    opinion.comment=comment;
    if(_likesOpinion){
        if(_addressNotNull(opinion.sponsor)){
            opinion.sponsor.transfer(payment);
            currentOwner.transfer(ownerTake);
        }
        else{
            currentOwner.transfer(sellingPrice);
        }
        opinion.sponsor=sponsorAdr;
        opinion.totalsponsored=SafeMath.add(opinion.totalsponsored,sellingPrice);
    }
    else{
        if(_addressNotNull(opinion.sponsor)){
            opinion.antisponsor.transfer(payment);
            ceoAddress.transfer(ownerTake);
        }
        else{
            ceoAddress.transfer(sellingPrice); //eth for initial antisponsor goes to Cryptopinions, because you wouldn&#39;t want it to go to the creator of an opinion you don&#39;t like
        }
        opinion.antisponsor=sponsorAdr;
        opinion.totalantisponsored=SafeMath.add(opinion.totalantisponsored,sellingPrice);
    }
    msg.sender.transfer(purchaseExcess);
  }
  
  //lets you permanently delete someone elses opinion.
  function deleteThis(uint256 _tokenId) public payable{
    //Cost is 1 eth or five times the current valuation of the opinion, whichever is higher.
    uint256 sellingPrice = SafeMath.mul(opinionIndexToPrice[_tokenId],5);
    if(sellingPrice<1 ether){
        sellingPrice=1 ether;
    }
    require(msg.value >= sellingPrice);
    ceoAddress.transfer(sellingPrice);
    Opinion storage opinion = opinions[_tokenId];
    opinion.deleted=true;
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    msg.sender.transfer(purchaseExcess);
  }
  
  // Allows someone to send ether and obtain the (unclaimed only) token
  function registerOpinion(uint256 _tokenId,string _newOpinion) public payable {
    
    //Set opinion to the new opinion
    _initOpinion(_tokenId,_newOpinion);
    
    address oldOwner = opinionIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = opinionIndexToPrice[_tokenId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);
    
    uint256 payment = sellingPrice;
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    opinionIndexToPrice[_tokenId] = sponsorStartingCost; //initial cost to sponsor

    _transfer(oldOwner, newOwner, _tokenId);

    ceoAddress.transfer(payment);

    TokenSold(_tokenId, sellingPrice, opinionIndexToPrice[_tokenId], oldOwner, newOwner, opinions[_tokenId].text);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return opinionIndexToPrice[_tokenId];
  }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
    _setCEO(_newCEO);
  }
   function _setCEO(address _newCEO) private{
         require(_newCEO != address(0));
         ceoAddress = _newCEO;
   }
  /// @dev Assigns a new address to act as the COO. Only available to the current COO.
  /// @param _newCOO The address of the new COO
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  /// @notice Allow pre-approved user to take ownership of a token
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = opinionIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire opinions array looking for opinions belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalOpinions = totalSupply();
      uint256 resultIndex = 0;

      uint256 opinionId;
      for (opinionId = 0; opinionId <= totalOpinions; opinionId++) {
        if (opinionIndexToOwner[opinionId] == _owner) {
          result[resultIndex] = opinionId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return opinions.length;
  }

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

  /// Third-party initiates transfer of token from address _from to address _to
  /// @param _from The address for the token to be transferred from.
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }
  
//Allows purchase of the entire contract. All revenue provisioned to ceoAddress will go to the new address specified.
//If you contact us following purchase we will transfer domain, website source code etc. to you free of charge, otherwise we will continue to maintain the frontend site for 1 year.
uint256 contractPrice=300 ether;
function buyCryptopinions(address _newCEO) payable public{
    require(msg.value >= contractPrice);
    ceoAddress.transfer(msg.value);
    _setCEO(_newCEO);
    _setPrice(9999999 ether);
}
function setPrice(uint256 newprice) public onlyCEO{
    _setPrice(newprice);
}
function _setPrice(uint256 newprice) private{
    contractPrice=newprice;
}

  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /// For checking approval of transfer for address _to
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return opinionIndexToApproved[_tokenId] == _to;
  }
  
  function _createOpinionSet() private {
      for(uint i = 0; i<numIssued; i++){
        _createOpinion(DEFAULT_TEXT,ceoAddress,startingPrice);
      }
      //startingPrice = SafeMath.mul(startingPrice,stepMultiplier); //increase the price for the next set of tokens
      //currentIssueRemaining=numIssued;
      
  }
  
  //for registering an Opinion
  function _initOpinion(uint256 _tokenId,string _newOpinion) private {
      Opinion storage opinion = opinions[_tokenId];
      opinion.timestamp=now;
      opinion.text=_newOpinion;
      opinion.comment=1;
      require(!opinion.claimed);
        uint256 newprice=SafeMath.mul(stepMultiplier,opinionIndexToPrice[_tokenId]);
        //max price 1 eth
        if(newprice > 0.1 ether){ //max price for a new opinion, 1 ether
            newprice=0.1 ether;
        }
        _createOpinion("",ceoAddress,newprice); //make a new opinion for someone else to buy
        opinion.claimed=true;
      
          //currentIssueRemaining=SafeMath.sub(currentIssueRemaining,1);
          //if this is the last remaining token for sale, issue more
          //if(currentIssueRemaining == 0){
          //    _createOpinionSet();
          //}
      
      
  }
  
  /// For creating Opinion
  function _createOpinion(string _name, address _owner, uint256 _price) private {
    Opinion memory _opinion = Opinion({
      text: _name,
      claimed: false,
      deleted: false,
      comment: 0,
      sponsor: _owner,
      antisponsor: ceoAddress,
      totalsponsored:0,
      totalantisponsored:0,
      timestamp:now
    });
    uint256 newOpinionId = opinions.push(_opinion) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newOpinionId == uint256(uint32(newOpinionId)));

    Birth(newOpinionId, _name, _owner);

    opinionIndexToPrice[newOpinionId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newOpinionId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == opinionIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

  /// @dev Assigns ownership of a specific opinion to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of opinions is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    opinionIndexToOwner[_tokenId] = _to;

    // When creating new opinions _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete opinionIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }
}
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