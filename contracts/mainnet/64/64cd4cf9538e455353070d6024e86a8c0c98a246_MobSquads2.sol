pragma solidity ^0.4.19; //

// MobSquads2.io
// The End of the Beginning

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

contract MobSquads2 is ERC721 {

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new mobster comes into existence.
  event Birth(uint256 tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token is sold.
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner);

  /// @dev Transfer event as defined in current draft of ERC721.
  ///  ownership is assigned, including births.
  event Transfer(address from, address to, uint256 tokenId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "MobSquads2"; //
  string public constant SYMBOL = "MOBS2"; //

  uint256 public precision = 1000000000000; //0.000001 Eth

  uint256 public hitPrice =  0.010 ether;

  uint256 public setPriceFee = 0.02 ether; // must be a cost to set your own price.
  uint256 public setPriceCoolingPeriod = 5 minutes; // you can&#39;t set price until 5 minutes after buying

  /*** STORAGE ***/

  /// @dev A mapping from mobster IDs to the address that owns them. All mobsters have
  ///  some valid owner address.
  mapping (uint256 => address) public mobsterIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from mobsters to an address that has been approved to call
  ///  transferFrom(). Each mobster can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public mobsterIndexToApproved;

  // @dev A mapping from mobsters to the price of the token.
  mapping (uint256 => uint256) private mobsterIndexToPrice;

  // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;
  address public cooAddress;

  // sale started
  bool public saleStarted = false;

  /*** DATATYPES ***/
  struct Mobster {
    uint256 id; // needed for gnarly front end
    string name;
    uint256 boss; // which gang member of
    uint256 state; // 0 = normal , 1 = dazed
    uint256 dazedExipryTime; // if this mobster was disarmed, when does it expire
    uint256 buyPrice; // the price at which this mobster was bought
    uint256 startingPrice; // price through which no deflation can go
    uint256 buyTime;
    uint256 level;
    string show;
    bool hasWhacked;
  }

  Mobster[] private mobsters;
  uint256 public leadingGang;
  uint256 public leadingHitCount;
  uint256[] public gangHits;  // number of hits a gang has done
  uint256[] public gangBadges;  // number of whacking badges a gang has
  uint256 public currentHitTotal = 0; //
  uint256 public lethalBonusAtHitsLead = 10; // whan a squad takes the lead by this much they win the bonus
  uint256 public whackingPool;


  // @dev A mapping from mobsters to the price of the token.
  mapping (uint256 => uint256) private bossIndexToGang;

  mapping (address => uint256) public mobsterBalances;


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
  function MobSquads2() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    leadingHitCount = 0;
     gangHits.length++;
     gangBadges.length++;
  //  _createMobster("The Godfather",address(this),2000000000000000,0);
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

    mobsterIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  /// @dev Creates a new mobster with the given name.
  function createMobster(string _name, uint256 _startPrice, uint256 _boss, uint256 _level, string _show) public onlyCLevel {
    _createMobster(_name, address(this), _startPrice,_boss, _level, _show);
  }

  /// @dev Creates a new mobster with the given name.
  function createMobsterWithOwner(string _name, address _owner, uint256 _startPrice, uint256 _boss, uint256 _level, string _show) public onlyCLevel {
    address firstOwner = _owner;
    if (_owner==0 || _owner== address(0)){
      firstOwner =  address(this);
    }
    _createMobster(_name,firstOwner, _startPrice,_boss, _level, _show);
  }

  /// @notice Returns all the relevant information about a specific mobster.
  /// @param _tokenId The tokenId of the mobster of interest.
  function getMobster(uint256 _tokenId) public view returns (
    uint256 id,
    string name,
    uint256 boss,
    uint256 sellingPrice,
    address owner,
    uint256 state,
    uint256 dazedExipryTime,
    uint256 nextPrice,
    uint256 level,
    bool canSetPrice,
    string show,
    bool hasWhacked
  ) {
    id = _tokenId;
    Mobster storage mobster = mobsters[_tokenId];
    name = mobster.name;
    boss = mobster.boss;
    sellingPrice =priceOf(_tokenId);
    owner = mobsterIndexToOwner[_tokenId];
    state = mobster.state;
    if (mobster.state==1 && now>mobster.dazedExipryTime){
        state=0; // time expired so say they are armed
    }
    dazedExipryTime=mobster.dazedExipryTime;
    nextPrice=calculateNewPrice(_tokenId);
    level=mobster.level;
    canSetPrice=(mobster.buyTime + setPriceCoolingPeriod)<now;
    show=mobster.show;
    hasWhacked=mobster.hasWhacked;
  }


  function lethalBonusAtHitsLead (uint256 _count) public onlyCLevel {
    lethalBonusAtHitsLead = _count;
  }

  function startSale () public onlyCLevel {
    saleStarted = true; // no going back
  }

  function setHitPrice (uint256 _price) public onlyCLevel {
    hitPrice = _price;
  }

  /// hit a mobster
  function hitMobster(uint256 _victim  , uint256 _hitter) public payable returns (bool){
    address mobsterOwner = mobsterIndexToOwner[_victim];
    require(msg.sender != mobsterOwner); // it doesn&#39;t make sense, but hey
    require(msg.sender==mobsterIndexToOwner[_hitter]); // they must be a hitter owner
    require(saleStarted==true);

    // Godfather cannot be hit, bosses cannot be hit
    if (msg.value>=hitPrice && _victim!=0 && _hitter!=0 && mobsters[_victim].level>1){
        // hit mobster
        mobsters[_victim].state=1;
        mobsters[_victim].dazedExipryTime = now + (2 * 1 minutes);

        if(mobsters[_victim].hasWhacked==true){
          mobsters[_victim].hasWhacked=false; // injury removes your whacking badge, you have to whack again!
          gangBadges[SafeMath.div(mobsters[_victim].boss,16)+1]++;
        }

        uint256 gangNumber=SafeMath.div(mobsters[_hitter].boss,16)+1;

        gangHits[gangNumber]++; // increase the hit count for this gang
        currentHitTotal++;
        whackingPool+=hitPrice;

        if(mobsters[_hitter].hasWhacked==false){
          mobsters[_hitter].hasWhacked=true;
          gangBadges[gangNumber]++;
        }

        if  (gangHits[gangNumber]>leadingHitCount){
            leadingHitCount=gangHits[gangNumber];
            leadingGang=gangNumber;
        }

        // check to see if this lead is now insurmountable and the count >20
        bool lethalBonusTime = false;
        for (uint256 g = 0 ; g<gangHits.length;g++){
          if (leadingHitCount-gangHits[g]>lethalBonusAtHitsLead)
            {
              lethalBonusTime=true;
            }
        }

      // Whacking Bonus
     if (lethalBonusTime){
       uint256 lethalBonus = SafeMath.mul(SafeMath.div(whackingPool,120),SafeMath.div(100,gangBadges[leadingGang]+1));

         // each of the 16 members of the gang with the most hits receives an equal share of the pool
         // GF also receives his share
         uint256 winningMobsterIndex  = (16*(leadingGang-1))+1; // include the boss

         for (uint256 x = 1;x<totalSupply();x++){
             if (x>=winningMobsterIndex && x<16+winningMobsterIndex && mobsters[x].hasWhacked==true){
                mobsterBalances[ mobsterIndexToOwner[x]]+=lethalBonus; // available for withdrawal
             }
             mobsters[x].hasWhacked=false; // reset this for all
         }

         // Godfather always get&#39;s his share
         if (mobsterIndexToOwner[0]!=address(this)){
               mobsterBalances[mobsterIndexToOwner[0]]+=lethalBonus; // available for withdrawal
         }

         currentHitTotal=0; // reset the counter
         whackingPool=0; // reset this

         // need to reset the gangHits
         for (uint256 y = 0 ; y<gangHits.length;y++){
           gangHits[y]=0; // reset hit counters
           gangBadges[y]=0; // remove all bagdes
           leadingHitCount=0;
           leadingGang=0;
         }

     } // end if bonus time


   } // end if this is a hit

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
    owner = mobsterIndexToOwner[_tokenId];
    require(owner != address(0));
  }


  // Allows someone to send ether and obtain the token
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = mobsterIndexToOwner[_tokenId];

    uint256 sellingPrice = priceOf(_tokenId);

    // no sales until we have started
    require(saleStarted==true);

    // Making sure token owner is not sending to self
    require(oldOwner != msg.sender);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(msg.sender));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);


// Godfather when sold will raise by 17% (10% previous owner , 3.5% to contract, 3,5% to pool for mobsters)
// Bosses when sold will raise by 17% (10% previous owner , 3.5% to contract , 3.5% to Godfather owner)
// Mobsters when sold will raise by 22% (10% previous owner, 3.5% to Godfather, 3.5% to contract, 5% to their boss owner)
// Dealers when sold will raise by 40% (18% previous owner, 3.5% to Godfather, 3.5% to contract, 5% to their mobster , 3% to squad boss , 7% whacking pool)

    uint256 contractFee = roundIt(uint256(SafeMath.mul(SafeMath.div(mobsters[_tokenId].buyPrice,1000),35))); // 3.5%
    uint256 previousOwnerPayout = 0;

     // godfather is flipped fee goes into whacking pool
    if (_tokenId==0){
      whackingPool+= contractFee;
    }


    // godfather and contract receive 3.5% of all sales
    uint256 godFatherFee = 0;
    if (_tokenId!=0){
        godFatherFee = contractFee; // 3.5%
    }

    uint256 superiorFee = 0;

    // mobster or dealer - so their superior get&#39;s 5%
    if (mobsters[_tokenId].level==2 || mobsters[_tokenId].level==3){
        superiorFee =  roundIt(uint256(SafeMath.div(mobsters[_tokenId].buyPrice,20))); // 5% goes to superior
    }

    // dealer so 7% to whacking pool , 3% to bosses boss (mobster-->Boss) , 18% previous owner
    if (mobsters[_tokenId].level==3){
        whackingPool+= SafeMath.mul(SafeMath.div(mobsters[_tokenId].buyPrice, 100), 7); // 7% to whackingpool
        previousOwnerPayout = roundIt(SafeMath.mul(SafeMath.div(mobsters[_tokenId].buyPrice, 100), 118)); // 118% to previous owner
        uint256 bossFee = roundIt(SafeMath.mul(SafeMath.div(mobsters[_tokenId].buyPrice, 100), 3)); // 3% to squad boss
        address bossAddress = mobsterIndexToOwner[mobsters[mobsters[_tokenId].boss].boss]; // bosses boss
        if (bossAddress!=address(this)){
            bossAddress.transfer(bossFee);
        }
  }else{
        // otherwise 10% previous owner
        previousOwnerPayout = roundIt(SafeMath.mul(SafeMath.div(mobsters[_tokenId].buyPrice, 100), 110)); // 110% to previous owner
    }

    // pay the godfather if not owned by contract and not selling GF
    if (mobsterIndexToOwner[0]!=address(this) && _tokenId!=0){
        mobsterIndexToOwner[0].transfer(godFatherFee);
    }

     // pay the superiorFee if not owned by the contract
    if (_tokenId!=0 && superiorFee>0 && mobsterIndexToOwner[mobsters[_tokenId].boss]!=address(this)){
        mobsterIndexToOwner[mobsters[_tokenId].boss].transfer(superiorFee);
    }


     mobsterIndexToPrice[_tokenId]  = calculateNewPrice(_tokenId);
     mobsters[_tokenId].state=0;
     mobsters[_tokenId].buyPrice=sellingPrice;
     mobsters[_tokenId].buyTime = now;

    _transfer(oldOwner, msg.sender, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(previousOwnerPayout); 
    }

    TokenSold(_tokenId, sellingPrice, mobsterIndexToPrice[_tokenId], oldOwner, msg.sender);

    if(SafeMath.sub(msg.value, sellingPrice)>0){
             msg.sender.transfer(SafeMath.sub(msg.value, sellingPrice)); // return any additional amount
    }

  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return mobsterIndexToPrice[_tokenId];
  }


  function max(uint a, uint b) private pure returns (uint) {
         return a > b ? a : b;
  }

  function nextPrice(uint256 _tokenId) public view returns (uint256 nPrice) {
    return calculateNewPrice(_tokenId);
  }

  // allows an owner to set their own price and keep the fee structure
  function setTokenPrice(uint256 _tokenId , uint256 _newSellPrice) public payable {
    require(saleStarted==true);
    require(msg.sender==mobsterIndexToOwner[_tokenId]); // they must own this mobbie and not already be deflating
    require(msg.value>=setPriceFee); // they must own this mobbie and not already be deflating
    require((mobsters[_tokenId].buyTime + setPriceCoolingPeriod)<now); // no setting this until some 5 minutes after

    // rules for setting own price.
    // buy price becomes "would have been" buy price so contract rules abide
    // GF or bosses have sell price ==117% of buy price
    if (_tokenId==0 || mobsters[_tokenId].level==1){
          mobsters[_tokenId].buyPrice = roundIt(SafeMath.mul(SafeMath.div(_newSellPrice, 117), 100));
    }
    // level 2
    // mobsters have sell price ==122% of buy price
   if (mobsters[_tokenId].level==2){
     mobsters[_tokenId].buyPrice = roundIt(SafeMath.mul(SafeMath.div(_newSellPrice, 122), 100));
    }
    // level 3
    // Dealrs have sell price ==140% of buy price
   if (mobsters[_tokenId].level==3){
     mobsters[_tokenId].buyPrice = roundIt(SafeMath.mul(SafeMath.div(_newSellPrice, 140), 100));
    }

    mobsterIndexToPrice[_tokenId]=_newSellPrice;
  }


    function claimMobsterFunds() public {
      if (mobsterBalances[msg.sender]==0) revert();
      uint256 amount = mobsterBalances[msg.sender];
      if (amount>0){
        mobsterBalances[msg.sender] = 0;
        msg.sender.transfer(amount);
      }
    }


 function calculateNewPrice(uint256 _tokenId) internal view returns (uint256 price){
   uint256 sellingPrice = priceOf(_tokenId);
   uint256 newPrice;

   // level 0
   // Godfather when sold will raise by 17%
   if (_tokenId==0){
         newPrice = roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 117), 100));
   }
   // level 1
    //Bosses when sold will raise by 17%
  if (mobsters[_tokenId].level==1 ){
        newPrice = roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 117), 100));
   }
   // level 2
   // Mobsters when sold will raise by 22%
  if (mobsters[_tokenId].level==2){
        newPrice= roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 122), 100));
   }
   // level 3
   // Dealers will raise by 40%
  if (mobsters[_tokenId].level==3){
        newPrice= roundIt(SafeMath.div(SafeMath.mul(sellingPrice, 140), 100));
   }

   return newPrice;
 }

  /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  /// @param _newCEO The address of the new CEO
  function setCEO(address _newCEO) public onlyCEO {
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
    address oldOwner = mobsterIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose tokens we are interested in.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalmobsters = totalSupply();
      uint256 resultIndex = 0;

      uint256 mobsterId;
      for (mobsterId = 0; mobsterId <= totalmobsters; mobsterId++) {
        if (mobsterIndexToOwner[mobsterId] == _owner) {
          result[resultIndex] = mobsterId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return mobsters.length;
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

  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

  /// For checking approval of transfer for address _to
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return mobsterIndexToApproved[_tokenId] == _to;
  }


  /// For creating mobsters
  function _createMobster(string _name, address _owner, uint256 _price, uint256 _boss, uint256 _level, string _show) private {

    Mobster memory _mobster = Mobster({
      name: _name,
      boss: _boss,
      state: 0,
      dazedExipryTime: 0,
      buyPrice: _price,
      startingPrice: _price,
      id: mobsters.length-1,
      buyTime: now,
      level: _level,
      show: _show,
      hasWhacked: false
    });
    uint256 newMobsterId = mobsters.push(_mobster) - 1;
    mobsters[newMobsterId].id=newMobsterId;

    if (newMobsterId==0){
       mobsters[0].hasWhacked=true; // Godfather always has his badge
    }

    // creating new squads
    if (newMobsterId % 16 ==0 || newMobsterId==1)
    {
        gangHits.length++;
        gangBadges.length++;
    }



    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newMobsterId == uint256(uint32(newMobsterId)));

    Birth(newMobsterId, _name, _owner);

    mobsterIndexToPrice[newMobsterId] = _price;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newMobsterId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == mobsterIndexToOwner[_tokenId];
  }

 /// withdraw , but leave whacking pool amount in - players need
  function withdraw(uint256 amount) public onlyCLevel {
        require(this.balance>whackingPool);
        require(amount<=this.balance-whackingPool);
        if (amount==0){
            amount=this.balance-whackingPool;
        }
        ceoAddress.transfer(amount);
    }


  function canMakeUnrefusableOffer() public view returns (bool can){
      return (now > mobsters[0].buyTime + 48 hours);
  }

  /// Godfather can claim contract 48 hrs after card is purchased
  function anOfferWeCantRefuse() public {
     require(msg.sender==mobsterIndexToOwner[0]); // owner of Godfather
     require(now > mobsters[0].buyTime + 48 hours); // 48 hours after purchase
     ceoAddress = msg.sender; // now owner of contract
     cooAddress = msg.sender; // entitled to withdraw any new contract fees
  }


  /// @dev Assigns ownership of a specific mobster to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of mobsters is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    mobsterIndexToOwner[_tokenId] = _to;

    // When creating new mobsters _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete mobsterIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    Transfer(_from, _to, _tokenId);
  }

    // utility to round to the game precision
    function roundIt(uint256 amount) internal constant returns (uint256)
    {
        // round down to correct preicision
        uint256 result = (amount/precision)*precision;
        return result;
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