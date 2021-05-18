pragma solidity ^0.8.0;

/**
 *
 * @author Alejandro Diaz <[email protected]>
 * SPDX-License-Identifier: 0BSD
 * 20210209c
 *
 */
import './Ownable.sol';
import './iERC20.sol';
import './iUtil.sol';


// ------------------------------------------------------------------------------------------------------------------
// an option contract, or Option, is a contract that bestows upon the bearer the right, but not the obligation to
// either purchase (call contract) or sell (put contract), an underlying security, for a fixed price (the StrikePrice).
// an individual contract between a two specified parties is represented by a Deal structure.
//
// notes: the Options supported in this smart contract are "American options"; that is, they can be exercised any time
// before the expiration date of the option. options are covered; which is to say, when you write an option you need
// to deposit the underlying security (in  case of a call option), or the funds equal to the strike-price (in case of
// a put).
//
// this smart contract provides functions to write option contracts; to transfer whole or partial beneficial ownership
// of option contracts; and to exercise, or partially excersise option contracts.
//
// write option contract:
// to write an option contract the caller must specify the terms, which are stored in a ContractMemo.
// these include:
//  identifying the underlying security
//  identifying the underlying expiration
//  identifying the underlying strike-price
//  specifying the option type (put or call)
// the security must be of a predetermined type, where the valid types are specified by the smart contract owner.
// the expiration dates are limited to specific intervals by built in rules. the strike-price must be within a range
// determined by an oracle -- or if there's no defined oracle then the strike-price can be anything.
//
// once contract terms have been established for a specific security/expiration combination, the strike-price for
// that combination cannot be modified; that is, once a ContractMemo is created, any new option contracts that reference
// the same security/expiration combination must use the same ContractMemo. The ContractMemo id unambigously identifies
// everything about the option contract.
//
// when an option contract is first written, the writer automatically becomes the holder of the entire amount of a new
// Deal.
//
// transfer an option contract:
// all or part of a Deal can be transferred from a current holder to a new holder. but before any transfer the
// old holder must reserve the amount to be transferred. reserving part of an option contract prevents the current
// holder from exercising that option, unless/until the reservation is released.
//
// note regarding transfers: after every transfer, option writers are "un-encumbered" as much as possible. that is to
// say that if at the end of a transfer the transferor or transferee (Mr T) is left as the writer of an option contract
// for which he is not the current holder; and Mr T. is also the holder of an equivalent option contract for which he
// is not the writer; then as much as possible he will be made the holder of the option contracts that he wrote; and
// the previous holder of any option contract Mr T. wrote will instead be assigned to writer of the option contract
// which Mr. T previously held (but for whom there was a different writer). the outcome of this policy is that the
// writer of an option contract can effectively cancel a sale by purchasing an equivalent option contract.
//
// exercise an option contract:
// any time before the expiration date, either all or part of an option contract can be exercised by the current holder.
// reserving part of an option contract prevents the current holder from exercising that option, unless/until the
// reservation is released.
//
// cancel an option contract:
// before the expiration date of a option contract, the writer can cancel any part of the contract that hasn't been
// transferred. after the expiration date of the contract the writer can cancel (expire) the entire contract. when
// a contract is canceled the underlying secirity is reurned to the original writer.
//
// internal representation
// each ContractMemo contains maps, indicating for each address the total amount of that ContractMemo written, and the
// total amount held and reserved. of course these totals might subsume multiple Deals, written by different
// writers and held by different holders. so each ContractMemo also contains a list of Deal structures. the
// Deal structures can be "split" as needed, so that if part of an option is tranferred, the Deal struture
// is split in two -- both parts referencing the original writer/holder, with the sum of their amounts now equal to
// the amount that was in the original Deal.
//
// ------------------------------------------------------------------------------------------------------------------


contract OptionContract is Ownable {


  //
  // events are generated when a user item, eg. an openOffer, is created or modified. on modification the event references the
  // same item id. in this way if events are processed in chronological order, then the lastest modification overwrites
  // the earlier.
  //
  event OptionContractEv(address indexed holder, uint256 indexed contractMemo, uint256 amount, uint8 whatEvent);


  //
  // defines
  //
  uint256 constant MAKER_COMMISION_PCTX100 = 25;     // 0.25%
  uint256 constant TAKER_COMMISION_PCTX100 = 35;     // 0.35%
  //
  uint8   constant OPTION_WRITTEN_EVENT         = 0x01;
  uint8   constant OPTION_OFFER_EVENT           = 0x02;
  uint8   constant OPTION_OFFER_CANCEL_EVENT    = 0x03;
  uint8   constant OPTION_XFER_FROM_EVENT       = 0x04;
  uint8   constant OPTION_XFER_TO_EVENT         = 0x05;
  uint8   constant OPTION_HOLDER_EXERCISE_EVENT = 0x06;  // holder exercised this option
  uint8   constant OPTION_WRITER_EXERCISE_EVENT = 0x07;  // writer's option was exercised
  uint8   constant OPTION_CANCELED_EVENT        = 0x08;
  uint8   constant OPTION_EXPIRED_EVENT         = 0x09;  // when canceled after expiration

  struct Security {
    bool    isPut;              // nz => put; z => call
    bool    isReplaced;         // nz => no new contracts based on this security
    address tokenAddr;          // address of ERC20 token that is the underlying security
    address priceOracleAddr;    // optional price oracle to retrict strike-price range
    uint256 priceMultiple;      // assert((strike-price % priceMultiple) == 0)
    uint256 contractMultiple;   // assert((xfer-amount % contractMultiple) == 0)
    uint256 tokensPerContract;  // how many tokens in each contract
    uint256 expirationBase;     // expirations will be calculated as offset from this date
    uint256 expirationInterval; // expirations will be multiple of this interval
    uint256 id;
  }

  struct ContractMemo {
    uint256 security;           // id of Security
    uint256 strikePrice;        // price (dai) at which the eth can be purchased
    uint256 expiration;         // date at which option expires
    uint256 id;
    uint256 openInterest;       // total contracts written, but not exercised

    // for every address (ADDR), we keep track of the number (count that can be used as IDX) of:
    //  free deals: written by ADDR, and held by ADDR
    //  writ deals: written by ADDR, but not held by ADDR (eg sold)
    //  held deals: held by ADDR, but not written by ADDR,
    mapping (address => uint256) freeDealsCount;
    mapping (address => uint256) writDealsCount;
    mapping (address => uint256) heldDealsCount;
    // IDX is used to index into the following maps, which all map Deal.Id by owner/writer, by IDX.
    // note: a back-link is stored in the Deal to recover each IDX
    mapping (address => mapping (uint256 => uint256)) freeDealIds;
    mapping (address => mapping (uint256 => uint256)) writDealIds;
    mapping (address => mapping (uint256 => uint256)) heldDealIds;
    // totals by ADDR
    mapping (address => uint256) amountFree;          // amount writen and held (inc. reserved)
    mapping (address => uint256) amountWrit;          // amount writen but not held
    mapping (address => uint256) amountHeld;          // amount held but not writen (inc. reserved)
    mapping (address => uint256) amountReserved;      // amount held and offered for sale
  }

  struct Deal {
    uint256 id;              // unique id of this Deal
    uint256 contractMemo;    // id of ContractMemo
    address writer;          // deposits the security / is obligated to sell
    address holder;          // the feller laying claim to this contract
    uint256 amount;          // amount of the contract held/written
    uint256 freeDealsIdx;    // back idx to ContractMemo.freeDealIds[writer/holder]
    uint256 writDealsIdx;    // back idx to ContractMemo.writDealIds[writer]
    uint256 heldDealsIdx;    // back idx to ContractMemo.heldDealIds[owner]
  }


  // ----------------------------------------------------------------------------------------------------------------
  // storage
  // ----------------------------------------------------------------------------------------------------------------
  bool       public isLocked;
  iUtil      public util;
  uint256    public securitiesCount;
  uint256    public contractMemosCount;
  uint256    public dealCount;
  mapping (address => bool)           public trusted;         // trusted partner contracts
  mapping (uint256 => Security)       public securities;      // securities by id
  mapping (uint256 => ContractMemo)   public contractMemos;   // contractMemos by id
  mapping (uint256 => Deal)           public deals;           // Deals by id
  mapping (uint256 => mapping (uint256 => mapping (uint256 => uint256)))
    public contractsByExpBySecByIdx;                          // contractMemo ids by expiration by security by strike-price idx


  // ----------------------------------------------------------------------------------------------------------------
  // modifiers
  // ----------------------------------------------------------------------------------------------------------------
  modifier trustedOnly {
    require(trusted[msg.sender] == true, "trusted only");
    _;
  }
  modifier unlockedOnly {
    require(!isLocked, "unlocked only");
    _;
  }


  // -------------------------------------------------------------------------------------------------------
  //  constructor
  // -------------------------------------------------------------------------------------------------------
  constructor(address _utilAddr) {
    util = iUtil(_utilAddr);
  }

  function setTrust(address _trustedAddr, bool _trust) public onlyOwner {
    trusted[_trustedAddr] = _trust;
  }

  function lock() public onlyOwner {
    isLocked = true;
  }

  function setPartners(address _utilAddr) public onlyOwner {
    util = iUtil(_utilAddr);
  }

  //default payable function. we don't accept eth
  receive() external payable {
    revert();
  }


  //
  // create a Security
  // contractAmounts have 18 decimals. contractMultiple sets the minimum trade-able denomination of contracts. for example, if contractMultiple
  // is (1 ether), then you can only trade integral numbers of contracts. if contractMultiple is 1 wei, then you can trade 1 wei of contracts.
  // if you want to be able to trade thousandth's of a contract, then set contractMultiple to (1 finney).
  //
  // if you want each contract to represent 1 WETH, then set tokensPerContract to 1 ether. if you want each contract to represent 100 WETH, then
  // set tokensPerContract to 100 ether.
  //
  function createSecurity(bool _isPut, address _tokenAddr, address _priceOracleAddr,
			  uint256 _priceMultiple, uint256 _contractMultiple, uint256 _tokensPerContract,
			  uint256 _expirationBase, uint256 _expirationInterval) public onlyOwner {
    Security storage _security = securities[++securitiesCount];
    _security.id = securitiesCount;
    _security.isPut = _isPut;
    _security.tokenAddr = _tokenAddr;
    _security.priceOracleAddr = _priceOracleAddr;
    _security.priceMultiple = _priceMultiple;
    _security.contractMultiple = _contractMultiple;
    _security.tokensPerContract = _tokensPerContract;
    _security.expirationBase = _expirationBase;
    _security.expirationInterval = _expirationInterval;
  }

  //
  // replacing a security prevents new contract memos from being created based on that security
  // note: once a contract memo exists, it's possible to write new options even after the underlying security
  // has been replaced.
  //
  // note: this function only flags that the passed security has been replaced; if you want to have a similar
  // replacement security then you need to actually create one via createSecurity.
  //
  function replaceSecurity(uint256 _securityId) public onlyOwner {
    Security storage _security = securities[_securityId];
    require(_security.id != 0 && _security.id == _securityId, "invalid security");
    _security.isReplaced = true;
  }


  //
  // get 6 legal strike prices for the passed security, for the pass expiration multiple
  //
  function getStrikePrices(uint256 _securityId, uint256 _expirationMultiple) public view returns(uint256 _nominalPrice, uint256[] memory _strikePrices) {
    Security storage _security = securities[_securityId];
    require(_security.id != 0 && _security.id == _securityId, "invalid security");
    (_nominalPrice, _strikePrices) = util.getStrikePrices(_securityId, _expirationMultiple, _security.priceOracleAddr, _security.priceMultiple);
  }


  //
  // get 36 open-interests the passed security, starting with the pass expiration multiple, and continuing with 5 more, for 6 strike-prices for each
  //
  function getOpenInterests(uint256 _securityId, uint256 _firstExpirationMultiple) public view returns(uint256[] memory _openInterests) {
    // sanity checks
    Security storage _security = securities[_securityId];
    require(_security.id != 0 && _security.id == _securityId, "invalid security");
    //
    _openInterests = new uint256[](36);
    for (uint256 _expirationIdx = 0; _expirationIdx < 6; ++_expirationIdx) {
      uint256 _expirationMultiple = _firstExpirationMultiple + _expirationIdx;
      for (uint256 _strikePriceIdx = 0; _strikePriceIdx < 6; ++_strikePriceIdx) {
	uint256 _contractMemoId = contractsByExpBySecByIdx[_expirationMultiple][_securityId][_strikePriceIdx];
	if (_contractMemoId == 0) {
	  _openInterests[_expirationIdx * 6 + _strikePriceIdx] = 0;
	} else {
	  ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
	  _openInterests[_expirationIdx * 6 + _strikePriceIdx] = _contractMemo.openInterest;
	}
      }
    }
  }


  //
  // create a ContractMemo
  // this version of createWrittenOption establishes a new ContractMemo
  //
  // the specified nominalPrice must be equal to the current oracle price (rounded); that is it must be equal to strikePrices[2];
  // the strikePriceIdx tells which strike price is desired from the strikePrices array.
  //
  // only one contractMemo can exists for a given securityId/expiration pair, and from then on the strike-price is locked-in. while
  // the contractAmount is in security.tokensPerContract; so eg. if the token has 18 decimals, like weth, and tokensPerContract is
  // equal to (1 ether), then the minimum contract amount is an option on 1 whole weth.
  //
  function _createContractMemo(uint256 _securityId, uint256 _expirationMultiple, uint256 _strikePriceIdx, uint256 _strikePrice) internal returns(uint256 _contractMemoId) {
    // sanity checks
    Security storage _security = securities[_securityId];
    require(_security.id != 0 && _security.id == _securityId, "invalid security");
    require(_security.isReplaced == false, "security has been replaced");
    require(contractsByExpBySecByIdx[_expirationMultiple][_securityId][_strikePriceIdx] == 0, "contract is already defined");
    ContractMemo storage _contractMemo = contractMemos[++contractMemosCount];
    _contractMemo.id = contractMemosCount;
    _contractMemo.security = _securityId;
    contractsByExpBySecByIdx[_expirationMultiple][_securityId][_strikePriceIdx] = contractMemosCount;
    // check strike-price
    (uint256 _nominalPrice, uint256[] memory _strikePrices) = util.getStrikePrices(_security.id, _expirationMultiple, _security.priceOracleAddr, _security.priceMultiple);
    require(_strikePriceIdx < 6 && _strikePrices[_strikePriceIdx] == _strikePrice, "invalid strike price");
    util.setStrikePrice(_securityId, _expirationMultiple, _nominalPrice);
    _contractMemo.strikePrice = _strikePrice;
    // calc expiration
    _contractMemo.expiration = _security.expirationBase + (_expirationMultiple * _security.expirationInterval);
    _contractMemoId = _contractMemo.id;
  }


  //
  // this version of createContractMemo is for the sortedMarket contract, so that it's possible to trade ContractMemos that have not yet been written
  //
  function createContractMemo(uint256 _securityId, uint256 _expirationMultiple, uint256 _strikePriceIdx, uint256 _strikePrice) external trustedOnly returns(uint256 _contractMemoId) {
    _contractMemoId = _createContractMemo(_securityId, _expirationMultiple, _strikePriceIdx, _strikePrice);
  }


  //
  // create a WrittenOption
  // this version of createWrittenOption establishes a new ContractMemo
  //
  // the specified nominalPrice must be equal to the current oracle price (rounded); that is it must be equal to strikePrices[2];
  // the strikePriceIdx tells which strike price is desired from the strikePrices array.
  //
  // only one contractMemo can exists for a given securityId/expiration pair, and from then on the strike-price is locked-in. while
  // the contractAmount is in security.tokensPerContract; so eg. if the token has 18 decimals, like weth, and tokensPerContract is
  // equal to (1 ether), then the minimum contract amount is an option on 1 whole weth.
  //
  function writeOption(uint256 _securityId, uint256 _expirationMultiple, uint256 _strikePriceIdx, uint256 _strikePrice, uint256 _contractAmount) public {
    uint256 _contractMemoId = _createContractMemo(_securityId, _expirationMultiple, _strikePriceIdx, _strikePrice);
    writeOption(_contractMemoId, _contractAmount);
  }


  //
  // create an option contract based on the specified ContractMemo
  // called by original writer. the writer is automatically the initial holder
  // note: once a contract memo exists, it's possible to write new options even after the underlying security
  // has been replaced.
  //
  function writeOption(uint256 _contractMemoId, uint256 _contractAmount) public {
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    Security storage _security = securities[_contractMemo.security];
    uint256 _tokenAmount = (_contractAmount * _security.tokensPerContract) / 1 ether;
    // sanity checks
    require(_contractMemo.id != 0 && _contractMemo.id == _contractMemoId, "invalid contract memo");
    require(_contractAmount != 0 && (_contractAmount % _security.contractMultiple) == 0, "invalid contract amount");
    require(block.timestamp < _contractMemo.expiration, "already expired");
    // create the asset: the undelying security for a Call; sufficient dai to purchase for a Put.
    if (_security.isPut) {
      uint256 _depositAmount = (_tokenAmount * _contractMemo.strikePrice) / 1 ether;
      util.collectPayment(msg.sender, _depositAmount);
    } else {
      util.collectAsset(msg.sender, _tokenAmount, _security.tokenAddr);
    }
    // create the Deal. msg.sender is the writer and holder
    Deal storage _deal = deals[++dealCount];
    _deal.id = dealCount;
    _deal.amount = _contractAmount;
    _deal.holder = _deal.writer = msg.sender;
    _deal.contractMemo = _contractMemoId;
    uint256 _freeDealsIdx = _contractMemo.freeDealsCount[_deal.writer]++;
    _deal.freeDealsIdx = _freeDealsIdx;
    _contractMemo.freeDealIds[_deal.writer][_freeDealsIdx] = _deal.id;
    _contractMemo.amountFree[_deal.writer] += _contractAmount;
    _contractMemo.openInterest += _contractAmount;
    emit OptionContractEv(_deal.writer, _contractMemoId, _deal.amount, OPTION_WRITTEN_EVENT);
  }


  //
  // options are reserved so they can be, eg. offered for sale
  // only reserved options are allowed to be transferred; only non-reserved options will be allowed to be exercised.
  // reserved options are still listed in the heldDeals map.
  //
  function reserveOption(address _from, uint256 _contractMemoId, uint256 _amount) external trustedOnly {
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    Security storage _security = securities[_contractMemo.security];
    //sanity check
    require(_contractMemo.id != 0 && _contractMemo.id == _contractMemoId, "invalid contract memo");
    require(block.timestamp < _contractMemo.expiration, "already expired");
    require(_amount != 0 && (_amount % _security.contractMultiple) == 0, "invalid contract amount");
    require(_contractMemo.amountFree[_from] + _contractMemo.amountHeld[_from] - _contractMemo.amountReserved[_from] > _amount, "insufficient holdings");
    _contractMemo.amountReserved[_from] += _amount;
    emit OptionContractEv(_from, _contractMemoId, _amount, OPTION_OFFER_EVENT);
  }

  function releaseOption(address _from, uint256 _contractMemoId, uint256 _amount) external trustedOnly {
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    Security storage _security = securities[_contractMemo.security];
    //sanity check
    require(_contractMemo.id != 0 && _contractMemo.id == _contractMemoId, "invalid contract memo");
    require(block.timestamp < _contractMemo.expiration, "already expired");
    require(_amount != 0 && (_amount % _security.contractMultiple) == 0, "invalid contract amount");
    _contractMemo.amountReserved[_from] -= _amount;
    emit OptionContractEv(_from, _contractMemoId, _amount, OPTION_OFFER_CANCEL_EVENT);
  }


  //
  // create a new deal by splitting an deal in two. the new deal can have a new holder.
  // this function takes care of all the [free|writ|held]DealIds, amount[Free|Writ|Held] bookkeeping, but not
  // amountReserved
  //
  function _splitDeal(Deal memory _srcDeal, address _newHolder, uint256 _amount) internal {
    uint256 _contractMemoId = _srcDeal.contractMemo;
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    Deal storage _destDeal = deals[++dealCount];
    _destDeal.contractMemo = _contractMemoId;
    _destDeal.writer = _srcDeal.writer;
    _destDeal.holder = _newHolder;
    _destDeal.amount = _amount;
    _destDeal.id = dealCount;
    if (_destDeal.writer == _destDeal.holder) {
      uint256 _freeDealsIdx = _contractMemo.freeDealsCount[_destDeal.writer]++;
      _contractMemo.freeDealIds[_destDeal.writer][_freeDealsIdx] = dealCount;
      _destDeal.freeDealsIdx = _freeDealsIdx;
      _contractMemo.amountFree[_destDeal.writer] += _amount;
    } else {
      uint256 _writDealsIdx = _contractMemo.writDealsCount[_destDeal.writer]++;
      _contractMemo.writDealIds[_destDeal.writer][_writDealsIdx] = dealCount;
      _destDeal.writDealsIdx = _writDealsIdx;
      uint256 _heldDealsIdx = _contractMemo.heldDealsCount[_destDeal.holder]++;
      _contractMemo.heldDealIds[_destDeal.holder][_heldDealsIdx] = dealCount;
      _destDeal.heldDealsIdx = _heldDealsIdx;
      _contractMemo.amountHeld[_destDeal.holder] += _amount;
      _contractMemo.amountWrit[_destDeal.writer] += _amount;
    }
    //
    if (_srcDeal.writer == _srcDeal.holder) {
      if ((_srcDeal.amount -= _amount) == 0) {
	uint256 _freeDealsIdx = _srcDeal.freeDealsIdx;
	_contractMemo.freeDealIds[_srcDeal.writer][_freeDealsIdx] = 0;
      }
      _contractMemo.amountFree[_srcDeal.writer] -= _amount;
    } else {
      if ((_srcDeal.amount -= _amount) == 0) {
	uint256 _writDealsIdx = _srcDeal.writDealsIdx;
	uint256 _heldDealsIdx = _srcDeal.heldDealsIdx;
	_contractMemo.writDealIds[_srcDeal.writer][_writDealsIdx] = 0;
	_contractMemo.heldDealIds[_srcDeal.holder][_heldDealsIdx] = 0;
      }
      _contractMemo.amountWrit[_srcDeal.writer] -= _amount;
      _contractMemo.amountHeld[_srcDeal.holder] -= _amount;
    }
  }


  //
  // swap the holders from two Deals in which the writer of the first is the holder of the second
  // on entry: _writDeal & _ownedOption are for the same amount, so we can do the swap.
  // on exit: instead of holding the heldDeal, the _writer will now hold the writDeal (for which he
  // is also the writer); the current holder of the writDeal will hold the heldDeal instead;
  //
  // note:
  // _writDeal.writer == _writer
  // _writDeal.holder != _writer
  // _heldDeal.writer == _writer
  // _heldDeal.holder != _writer
  // but it's possible that _writDeal.holder == _heldDeal.writer
  //
  // so if JACK is the writer, and LUCY is the holder of writDeal(52); and
  //       MARY is the writer, and JACK is the holder of heldDeal(87), then we have:
  //
  //                                                   writDeal
  //                ContractMemo                       Deal-52
  //         ----------------------------             -----------------------
  //         | writDealIds[JACK][A] = 52| ----------> | writer = JACK       |
  //         | heldDealIds[LUCY][B] = 52| ----------> | writDealsIdx = A    |
  //         |                          |             | holder = LUCY       |
  //         |                          |             | heldDealsIdx = B    |
  //         |                          |             -----------------------
  //         |                          |
  //         |                          |              heldDeal
  //         |                          |              Deal-87
  //         |                          |             -----------------------
  //         | writDealIds[MARY][C] = 87| ----------> | writer = MARY       |
  //         | heldDealIds[JACK][D] = 87| ----------> | writDealsIdx = C    |
  //         |                          |             | holder = JACK       |
  //         |                          |             | heldDealsIdx = D    |
  //         ----------------------------             -----------------------
  //
  // after the swap we want:
  //                                                       writDeal
  //                ContractMemo                           Deal-52
  //         ----------------------------                 -----------------------
  //         | writDealIds[JACK][A] = 0 |                 | writer = JACK       |
  //         | heldDealIds[LUCY][B] = 87| ------|         | writDealsIdx = 0    |
  //         | freeDealIds[JACK][E] = 52| ------|-------> | holder = JACK       |
  //         |                          |       |         | heldDealsIdx = 0    |
  //         |                          |       |         | freeDealsIdx = E    |
  //         |                          |       |         -----------------------
  //         |                          |       |
  //         |                          |       |          heldDeal
  //         |                          |       |          Deal-87
  //         |                          |       |         -----------------------
  //         |                          |       |-------> | writer = MARY       |
  //         | writDealIds[MARY][C] = 87| --------------> | writer = MARY       |
  //         | heldDealIds[JACK][D] = 0 |                 | writDealsIdx = C    |
  //         |                          |                 | holder = LUCY       |
  //         |                          |                 | heldDealsIdx = B    |
  //         ----------------------------                 -----------------------
  //
  // unless, of course MARY & LUCY are the same person, in which case we want:
  //
  //                                                       writDeal
  //                ContractMemo                           Deal-52
  //         ----------------------------                 -----------------------
  //         | writDealIds[JACK][A] = 0 |                 | writer = JACK       |
  //         | heldDealIds[LUCY][B] = 0 |                 | writDealsIdx = 0    |
  //         | freeDealIds[JACK][E] = 52| --------------> | holder = JACK       |
  //         |                          |                 | heldDealsIdx = 0    |
  //         |                          |                 | freeDealsIdx = E    |
  //         |                          |                 -----------------------
  //         |                          |
  //         |                          |                  heldDeal
  //         |                          |                  Deal-87
  //         |                          |                 -----------------------
  //         | writDealIds[MARY][C] = 0 |                 | writer = LUCY       |
  //         | heldDealIds[JACK][D] = 0 |                 | writDealsIdx = C    |
  //         | freeDealIds[LUCY][F] = 87| --------------> | holder = LUCY       |
  //         |                          |                 | heldDealsIdx = B    |
  //         |                          |                 | freeDealsIdx = F    |
  //         ----------------------------                 -----------------------
  //
  function _swapDealHolders(Deal memory _writDeal, Deal memory _heldDeal, uint256 _contractMemoId) internal {
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    address _writer = _writDeal.writer;
    uint256 _amount = _writDeal.amount;
    uint256 _heldDealId = _heldDeal.id;
    uint256 _writDealWritIdx = _writDeal.writDealsIdx;
    uint256 _writDealHeldIdx = _writDeal.heldDealsIdx;
    uint256 _heldDealWritIdx = _heldDeal.writDealsIdx;
    uint256 _heldDealHeldIdx = _heldDeal.heldDealsIdx;
    //address _writDealHolder  = _writDeal.holder;
    //address _heldDealWriter  = _heldDeal.writer;
    _contractMemo.writDealIds[_writer][_writDealWritIdx] = 0;
    _contractMemo.heldDealIds[_writer][_heldDealHeldIdx] = 0;
    uint256 _writDealFreeIdx = _contractMemo.freeDealsCount[_writer]++;
    _contractMemo.freeDealIds[_writer][_writDealFreeIdx] = _writDealWritIdx;
    _writDeal.writDealsIdx = _writDeal.heldDealsIdx = 0;
    _writDeal.freeDealsIdx = _writDealFreeIdx;
    _heldDeal.holder = _writDeal.holder;
    _contractMemo.amountFree[_writer] += _amount;
    _contractMemo.amountWrit[_writer] -= _amount;
    _contractMemo.amountHeld[_writer] -= _amount;
    if (_heldDeal.holder != _heldDeal.writer) {
      _contractMemo.heldDealIds[_heldDeal.holder][_writDealHeldIdx] = _heldDealId;
    } else {
      _contractMemo.heldDealIds[_writDeal.holder][_writDealHeldIdx] = 0;
      _contractMemo.writDealIds[_heldDeal.writer][_heldDealWritIdx] = 0;
      uint256 _heldDealFreeIdx = _contractMemo.freeDealsCount[_writDeal.holder]++;
      _contractMemo.freeDealIds[_heldDeal.holder][_heldDealFreeIdx] = _heldDealId;
      _contractMemo.amountFree[_heldDeal.holder] += _amount;
      _contractMemo.amountWrit[_heldDeal.holder] -= _amount;
      _contractMemo.amountHeld[_heldDeal.holder] -= _amount;
    }
    _writDeal.holder = _writDeal.writer;
  }


  //
  // if an address is a writer (but not holder) on one deal, and is a holder (but not writer) on another
  // deal (same contractMemo), then swap the holder address on the two deals, so that he is both
  // a writer and holder, thereby making the deal free.
  //
  function _unEncumberWriter(address _writer, uint256 _contractMemoId) internal {
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    uint256 _heldIdx = 0;
    uint256 _writIdx = 0;
    while (_contractMemo.amountWrit[_writer] > 0 && _contractMemo.amountHeld[_writer] > 0) {
      // find a written contract that we can switch out
      while (_contractMemo.writDealIds[_writer][_writIdx] == 0)
	++_writIdx;
      // find an held option that can take over as the writer
      while (_contractMemo.heldDealIds[_writer][_heldIdx] == 0)
	++_heldIdx;
      uint256 _writDealId = _contractMemo.writDealIds[_writer][_writIdx];
      uint256 _heldDealId = _contractMemo.heldDealIds[_writer][_heldIdx];
      Deal storage _writDeal = deals[_writDealId];
      Deal storage _heldDeal = deals[_heldDealId];
      uint256 _amount = _writDeal.amount;
      if (_heldDeal.amount > _amount) {
	uint256 _splitAmount = _heldDeal.amount - _amount;
	_splitDeal(_heldDeal, _heldDeal.holder, _splitAmount);
      } else if (_heldDeal.amount < _amount) {
	_amount = _heldDeal.amount;
	uint256 _splitAmount = _writDeal.amount - _amount;
	_splitDeal(_writDeal, _writDeal.holder, _splitAmount);
      }
      _swapDealHolders(_writDeal, _heldDeal, _contractMemoId);
    }
  }


  //
  // transfer all or part of a Deal
  // only reserved options are allowed to be transferred
  //
  function transferOption(address _from, address _to, uint256 _contractMemoId, uint256 _amount) external trustedOnly {
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    Security storage _security = securities[_contractMemo.security];
    //sanity check
    require(_contractMemo.id != 0 && _contractMemo.id == _contractMemoId, "invalid contract memo");
    require(block.timestamp < _contractMemo.expiration, "already expired");
    require(_amount != 0 && (_amount % _security.contractMultiple) == 0, "invalid contract amount");
    _contractMemo.amountReserved[_from] -= _amount;
    // first transfer held deals, then transfer free deals
    uint256 _heldXferAmount = (_amount > _contractMemo.amountHeld[_from]) ? _contractMemo.amountHeld[_from] : _amount;
    uint256 _freeXferAmount = _amount -= _heldXferAmount;
    _contractMemo.amountHeld[_from] -= _heldXferAmount;
    for (uint256 _heldDealsIdx = 0; _heldDealsIdx < _contractMemo.heldDealsCount[_from] && _heldXferAmount > 0; ++_heldDealsIdx) {
      uint256 _heldDealId = _contractMemo.heldDealIds[_from][_heldDealsIdx];
      Deal storage _heldDeal = deals[_heldDealId];
      uint256 _xferAmount = (_heldXferAmount > _heldDeal.amount) ? _heldDeal.amount : _heldXferAmount;
      if (_xferAmount != 0) {
	_splitDeal(_heldDeal, _to, _xferAmount);
	_heldXferAmount -= _xferAmount;
	emit OptionContractEv(_from, _contractMemoId, _xferAmount, OPTION_XFER_FROM_EVENT);
	emit OptionContractEv(_to,   _contractMemoId, _xferAmount, OPTION_XFER_TO_EVENT);
      }
    }
    //
    for (uint256 _freeDealsIdx = 0; _freeDealsIdx < _contractMemo.freeDealsCount[_from] && _freeXferAmount > 0; ++_freeDealsIdx) {
      uint256 _freeDealId = _contractMemo.freeDealIds[_from][_freeDealsIdx];
      Deal storage _freeDeal = deals[_freeDealId];
      uint256 _xferAmount = (_freeXferAmount > _freeDeal.amount) ? _freeDeal.amount : _freeXferAmount;
      if (_xferAmount != 0) {
	_splitDeal(_freeDeal, _to, _xferAmount);
	_freeXferAmount -= _xferAmount;
	emit OptionContractEv(_from, _contractMemoId, _xferAmount, OPTION_XFER_FROM_EVENT);
	emit OptionContractEv(_to,   _contractMemoId, _xferAmount, OPTION_XFER_TO_EVENT);
      }
    }
    require(_heldXferAmount == 0 && _freeXferAmount == 0, "unable to transfer option amount");
    _unEncumberWriter(_from, _contractMemoId);
    _unEncumberWriter(_to, _contractMemoId);
  }


  //
  // exercise option(s)
  // called directly by the contract holder
  // you cannot exercise a contract that is reserved
  //
  function excerciseOption(uint256 _contractMemoId, uint256 _amount) public {
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    Security storage _security = securities[_contractMemo.security];
    require(block.timestamp < _contractMemo.expiration, "already expired");
    require(_amount != 0 && (_amount % _security.contractMultiple) == 0, "invalid contract amount");
    _contractMemo.openInterest -= _amount;
    for (uint256 _heldDealsIdx = 0; _heldDealsIdx < _contractMemo.heldDealsCount[msg.sender] && _amount > 0; ++_heldDealsIdx) {
      uint256 _exerciseContractId = _contractMemo.heldDealIds[msg.sender][_heldDealsIdx];
      Deal storage _exerciseDeal = deals[_exerciseContractId];
      uint256 _exerciseAmount = (_amount > _exerciseDeal.amount) ? _exerciseDeal.amount : _amount;
      if ((_exerciseDeal.amount -= _exerciseAmount) == 0) {
	_contractMemo.heldDealIds[msg.sender][_heldDealsIdx] = 0;
	uint256 _writDealsIdx = _exerciseDeal.writDealsIdx;
	_contractMemo.writDealIds[_exerciseDeal.writer][_writDealsIdx] = 0;
      }
      _contractMemo.amountWrit[_exerciseDeal.writer] -= _exerciseAmount;
      _contractMemo.amountHeld[_exerciseDeal.holder] -= _exerciseAmount;
      // at this point we can effect the swap between the buyer and seller for this underlying security
      uint256 _tokenAmount = (_exerciseAmount * _security.tokensPerContract) / 1 ether;
      uint256 _totalCost = (_tokenAmount * _contractMemo.strikePrice) / 1 ether;
      // for a call, payment from the buyer (msg.sender) to seller (writer), transfer the security to the buyer.
      // for a put, transfer the security to the writer, payment to the seller (msg.sender).
      if (_security.isPut)
	util.sellAsset(true,  msg.sender, _exerciseDeal.writer, _tokenAmount, _security.tokenAddr, _totalCost);
      else
	util.sellAsset(false, _exerciseDeal.writer, msg.sender, _tokenAmount, _security.tokenAddr, _totalCost);
      _amount -= _exerciseAmount;
      emit OptionContractEv(msg.sender,           _contractMemoId, _exerciseAmount, OPTION_HOLDER_EXERCISE_EVENT);
      emit OptionContractEv(_exerciseDeal.writer, _contractMemoId, _exerciseAmount, OPTION_WRITER_EXERCISE_EVENT);
    }
    require(_amount == 0, "unable to exercise option amount");
  }


  //
  // cancel Option(s)
  // called directly by the option writer
  //
  function cancelOption(uint256 _contractMemoId, uint256 _amount) public {
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    Security storage _security = securities[_contractMemo.security];
    require(_amount != 0 && (_amount % _security.contractMultiple) == 0, "invalid contract amount");
    // for aesthetic bookkeeping, when option is expired, first cancel sold, then cancel free
    uint256 _writCancelAmount = 0;
    if (block.timestamp >= _contractMemo.expiration) {
      _writCancelAmount = (_amount > _contractMemo.amountWrit[msg.sender]) ? _contractMemo.amountWrit[msg.sender] : _amount;
      _contractMemo.amountWrit[msg.sender] -= _writCancelAmount;
    }
    uint256 _freeCancelAmount = _amount - _writCancelAmount;
    _contractMemo.amountFree[msg.sender] -= _freeCancelAmount;
    _contractMemo.openInterest -= _amount;
    // now we know he owned enough... let's find deals where he was the writer
    for (uint256 _writDealsIdx = 0; _writDealsIdx < _contractMemo.writDealsCount[msg.sender] && _writCancelAmount > 0; ++_writDealsIdx) {
      uint256 _writContractId = _contractMemo.writDealIds[msg.sender][_writDealsIdx];
      Deal storage _writDeal = deals[_writContractId];
      uint256 _cancelAmount = (_writCancelAmount > _writDeal.amount) ? _writDeal.amount : _writCancelAmount;
      if ((_writDeal.amount -= _cancelAmount) == 0)
	_contractMemo.writDealIds[msg.sender][_writDealsIdx] = 0;
      _writCancelAmount -= _cancelAmount;
      emit OptionContractEv(_writDeal.writer, _contractMemoId, _cancelAmount, OPTION_CANCELED_EVENT);
      emit OptionContractEv(_writDeal.holder, _contractMemoId, _cancelAmount, OPTION_EXPIRED_EVENT);
    }
    for (uint256 _freeDealsIdx = 0; _freeDealsIdx < _contractMemo.freeDealsCount[msg.sender] && _freeCancelAmount > 0; ++_freeDealsIdx) {
      uint256 _freeContractId = _contractMemo.freeDealIds[msg.sender][_freeDealsIdx];
      Deal storage _freeDeal = deals[_freeContractId];
      uint256 _cancelAmount = (_freeCancelAmount > _freeDeal.amount) ? _freeDeal.amount : _freeCancelAmount;
      if ((_freeDeal.amount -= _cancelAmount) == 0)
	_contractMemo.freeDealIds[msg.sender][_freeDealsIdx] = 0;
      _freeCancelAmount -= _cancelAmount;
      emit OptionContractEv(_freeDeal.writer, _contractMemoId, _cancelAmount, OPTION_CANCELED_EVENT);
    }
    require(_writCancelAmount == 0 && _freeCancelAmount == 0, "unable to cancel option amount");
    // at this point we can return the underlying security to the writer; that is, for a call, return the security. for
    // a put, return the strike-price funds
    uint256 _tokenAmount = _amount * _security.tokensPerContract;
    if (_security.isPut) {
      uint256 _totalCost = _tokenAmount * _contractMemo.strikePrice;
      util.refundPayment(msg.sender, _totalCost);
    } else {
      util.refundAsset(msg.sender, _tokenAmount, _security.tokenAddr);
    }
  }


  function getContractMemo(uint256 _contractMemoId, address _owner) public view returns (uint256 _amountFree, uint256 _amountWrit, uint256 _amountHeld, uint256 _amountReserved) {
    ContractMemo storage _contractMemo = contractMemos[_contractMemoId];
    _amountFree = _contractMemo.amountFree[_owner];
    _amountWrit = _contractMemo.amountWrit[_owner];
    _amountHeld = _contractMemo.amountHeld[_owner];
    _amountReserved = _contractMemo.amountReserved[_owner];
  }


  //
  // DEBUG DEBUG DEBUG
  // DEBUG DEBUG DEBUG
  // DEBUG DEBUG DEBUG
  //
  // for debug ONLY
  // only available before the writtenOption is locked
  //
  // DEBUG DEBUG DEBUG
  // DEBUG DEBUG DEBUG
  // DEBUG DEBUG DEBUG
  //
  function killOptionContract() public unlockedOnly {
    selfdestruct(payable(msg.sender));
  }
}