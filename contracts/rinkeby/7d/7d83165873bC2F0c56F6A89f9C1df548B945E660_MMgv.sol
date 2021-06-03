pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: UNLICENSED



import {
  ITaker,
  IMaker,
  MgvCommon as MC,
  MgvEvents,
  IMgvMonitor
} from "./MgvCommon.sol";
import "./interfaces.sol";

/*
   This contract describes an orderbook-based exchange ("the Mangrove") where market makers *do not have to provision their offer*. See `structs.js` for a longer introduction. In a nutshell: each offer created by a maker specifies an address (`maker`) to call upon offer execution by a taker. In the normal mode of operation ('Flash Maker'), the Mangrove transfers the amount to be paid by the taker to the maker, calls the maker, attempts to transfer the amount promised by the maker to the taker, and reverts if it cannot.

   There is one Mangrove contract that manages all tradeable pairs. This reduces deployment costs for new pairs and makes it easier to have maker provisions for all pairs in the same place.

   There is a secondary mode of operation ('Flash Taker') in which the _maker_ flashloans the sold amount to the taker.

   The Mangrove contract is `abstract` and accomodates both modes. Two contracts, `MMgv` (Maker Mangrove) and `TMgv` (Taker Mangrove) inherit from it, one per mode of operation.
 */
abstract contract Mangrove {
  /* # State variables */
  //+clear+
  /* The `governance` address. Governance is the only address that can configure parameters. */
  address public governance;

  /* The `vault` address. If a pair has fees >0, those fees are sent to the vault. */
  address public vault;

  /* Global mgv configuration, encoded in a 256 bits word. The information encoded is detailed in `structs.js`. */
  bytes32 public global;
  /* Configuration mapping for each token pair. The information is also detailed in `structs.js`. */
  mapping(address => mapping(address => bytes32)) public locals;

  /* The signature of the low-level swapping function. Given at construction time by inheriting contracts. In FMD, for each offer executed, `FLASHLOANER` sends from taker to maker, then calls maker. In FTD, `FLASHLOANER` first sends from maker to taker for each offer, then calls taker once, then transfers back to each maker. */
  bytes4 immutable FLASHLOANER;

  /* Given a `base`,`quote` pair, the mappings `offers` and `offerDetails` associate two 256 bits words to each offer id. Those words encode information detailed in `structs.js`.

     The mapping are `base => quote => offerId => bytes32`.
   */
  mapping(address => mapping(address => mapping(uint => bytes32)))
    public offers;
  mapping(address => mapping(address => mapping(uint => bytes32)))
    public offerDetails;

  /* Takers may provide allowances on specific pairs, so other addresses can execute orders in their name. Allowance may be set using the usual `approve` function, or through an [EIP712](https://eips.ethereum.org/EIPS/eip-712) `permit`.

  The mapping is `base => quote => owner => spender => allowance` */
  mapping(address => mapping(address => mapping(address => mapping(address => uint))))
    public allowances;
  /* Storing nonces avoids replay attacks. */
  mapping(address => uint) public nonces;
  /* Following [EIP712](https://eips.ethereum.org/EIPS/eip-712), structured data signing has `keccak256("Permit(address base,address quote,address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")` in its prefix. */
  bytes32 public constant PERMIT_TYPEHASH =
    0xb7bf278e51ab1478b10530c0300f911d9ed3562fc93ab5e6593368fe23c077a2;
  /* Initialized in the constructor, `DOMAIN_SEPARATOR` avoids cross-application permit reuse. */
  bytes32 public immutable DOMAIN_SEPARATOR;

  /* Makers provision their possible penalties in the `balanceOf` mapping.

       Offers specify the amount of gas they require for successful execution (`gasreq`). To minimize book spamming, market makers must provision a *penalty*, which depends on their `gasreq` and on the pair's `*_gasbase`. This provision is deducted from their `balanceOf`. If an offer fails, part of that provision is given to the taker, as retribution. The exact amount depends on the gas used by the offer before failing.

       The Mangrove keeps track of their available balance in the `balanceOf` map, which is decremented every time a maker creates a new offer, and may be modified on offer updates/cancelations/takings.
   */
  mapping(address => uint) public balanceOf;

  /*
  # Mangrove Constructor
  To initialize a new instance, the deployer must provide initial configuration (see `structs.js` for more on configuration parameters):
  */
  constructor(
    /* `_gasprice` is underscored to avoid builtin `gasprice` name shadowing. */
    uint _gasprice,
    uint gasmax,
    /* `takerLends` determines whether the taker or maker does the flashlend. FMD initializes with `true`, FTD initializes with `false`. */
    bool takerLends,
    /* Used by [EIP712](https://eips.ethereum.org/EIPS/eip-712)'s `DOMAIN_SEPARATOR` */
    string memory contractName //+clear+
  ) {
    emit MgvEvents.NewMgv();

    /* Initialize governance. At this stage we cannot use the `setGovernance` method since no admin is set. */
    governance = msg.sender;
    emit MgvEvents.SetGovernance(msg.sender);

    /* Initialize vault to sender's address, and set initial gasprice and gasmax. */
    setVault(msg.sender);
    setGasprice(_gasprice);
    setGasmax(gasmax);
    /* In FMD, takers lend the liquidity to the maker. */
    /* In FTD, takers come ask the makers for liquidity. */
    FLASHLOANER = takerLends
      ? Mangrove.flashloan.selector
      : Mangrove.invertedFlashloan.selector;

    /* Initialize [EIP712](https://eips.ethereum.org/EIPS/eip-712) `DOMAIN_SEPARATOR`. */
    uint chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(contractName)),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  /* # Configuration */
  /* Returns the configuration in an ABI-compatible struct. Should not be called internally, would be a huge memory copying waste. Use `config` instead. */
  function getConfig(address base, address quote)
    external
    returns (MC.Config memory ret)
  {
    (bytes32 _global, bytes32 _local) = config(base, quote);
    ret.global = MC.Global({
      monitor: address(uint((_global << 0)) >> 96),
      useOracle: uint(uint((_global << 160)) >> 248) > 0,
      notify: uint(uint((_global << 168)) >> 248) > 0,
      gasprice: uint(uint((_global << 176)) >> 240),
      gasmax: uint(uint((_global << 192)) >> 232),
      dead: uint(uint((_global << 216)) >> 248) > 0
    });
    ret.local = MC.Local({
      active: uint(uint((_local << 0)) >> 248) > 0,
      overhead_gasbase: uint(uint((_local << 56)) >> 232),
      offer_gasbase: uint(uint((_local << 80)) >> 232),
      fee: uint(uint((_local << 8)) >> 240),
      density: uint(uint((_local << 24)) >> 224),
      best: uint(uint((_local << 112)) >> 232),
      lock: uint(uint((_local << 104)) >> 248) > 0,
      last: uint(uint((_local << 136)) >> 232)
    });
  }

  /* Returns information about an offer in ABI-compatible structs. Do not use internally, would be a huge memory-copying waste. Use `offers[base][quote]` and `offerDetails[base][quote]` instead. */
  function offerInfo(
    address base,
    address quote,
    uint offerId
  ) external view returns (MC.Offer memory, MC.OfferDetail memory) {
    bytes32 offer = offers[base][quote][offerId];
    MC.Offer memory offerStruct =
      MC.Offer({
        prev: uint(uint((offer << 0)) >> 232),
        next: uint(uint((offer << 24)) >> 232),
        wants: uint(uint((offer << 144)) >> 160),
        gives: uint(uint((offer << 48)) >> 160),
        gasprice: uint(uint((offer << 240)) >> 240)
      });

    bytes32 offerDetail = offerDetails[base][quote][offerId];

    MC.OfferDetail memory offerDetailStruct =
      MC.OfferDetail({
        maker: address(uint((offerDetail << 0)) >> 96),
        gasreq: uint(uint((offerDetail << 160)) >> 232),
        overhead_gasbase: uint(uint((offerDetail << 184)) >> 232),
        offer_gasbase: uint(uint((offerDetail << 208)) >> 232)
      });
    return (offerStruct, offerDetailStruct);
  }

  /* Convenience function to get best offer of the given pair */
  function best(address base, address quote) external view returns (uint) {
    bytes32 local = locals[base][quote];
    return uint(uint((local << 112)) >> 232);
  }

  /* Convenience function to check whether given pair is locked */
  function locked(address base, address quote) external view returns (bool) {
    bytes32 local = locals[base][quote];
    return uint(uint((local << 104)) >> 248) > 0;
  }

  /* Check whether an offer is 'live', that is: inserted in the order book. The Mangrove holds a `base => quote => id => bytes32` mapping in storage. Offer ids that are not yet assigned or that point to since-deleted offer will point to the null word. A common way to check for initialization is to add an `exists` field to a struct. In our case, liveness can be denoted by `offer.gives > 0`. So we just check the `gives` field. */
  function isLive(bytes32 offer) public pure returns (bool) {
    return uint(uint((offer << 48)) >> 160) > 0;
  }

  /*
  # Gatekeeping

  Gatekeeping functions are safety checks called in various places.
  */

  /* `unlockedMarketOnly` protects modifying the market while an order is in progress. Since external contracts are called during orders, allowing reentrancy would, for instance, let a market maker replace offers currently on the book with worse ones. Note that the external contracts _will_ be called again after the order is complete, this time without any lock on the market.  */
  function unlockedMarketOnly(bytes32 local) internal pure {
    require(uint(uint((local << 104)) >> 248) == 0, "mgv/reentrancyLocked");
  }

  /* <a id="Mangrove/definition/liveMgvOnly"></a>
     In case of emergency, the Mangrove can be `kill`ed. It cannot be resurrected. When a Mangrove is dead, the following operations are disabled :
       * Executing an offer
       * Sending ETH to the Mangrove the normal way. Usual [shenanigans](https://medium.com/@alexsherbuck/two-ways-to-force-ether-into-a-contract-1543c1311c56) are possible.
       * Creating a new offer
   */
  function liveMgvOnly(bytes32 _global) internal pure {
    require(uint(uint((_global << 216)) >> 248) == 0, "mgv/dead");
  }

  /* When the Mangrove is deployed, all pairs are inactive by default (since `locals[base][quote]` is 0 by default). Offers on inactive pairs cannot be taken or created. They can be updated and retracted. */
  function activeMarketOnly(bytes32 _global, bytes32 _local) internal pure {
    liveMgvOnly(_global);
    require(uint(uint((_local << 0)) >> 248) > 0, "mgv/inactive");
  }

  /* # Public Maker operations
     ## New Offer */
  //+clear+
  /* In the Mangrove, makers and takers call separate functions. Market makers call `newOffer` to fill the book, and takers call functions such as `marketOrder` to consume it.  */

  //+clear+

  /* The following structs holds offer creation/update parameters in memory. This frees up stack space for local variables. */
  struct OfferPack {
    address base;
    address quote;
    uint wants;
    uint gives;
    uint id;
    uint gasreq;
    uint gasprice;
    uint pivotId;
    bytes32 global;
    bytes32 local;
    // used on update only
    bytes32 oldOffer;
  }

  /* The function `newOffer` is for market makers only; no match with the existing book is done. A maker specifies how much `quote` it `wants` and how much `base` it `gives`.

     It also specify with `gasreq` how much gas should be given when executing their offer.

     `gasprice` indicates an upper bound on the gasprice at which the maker is ready to be penalised if their offer fails. Any value below the Mangrove's internal `gasprice` configuration value will be ignored.

    `gasreq`, together with `gasprice`, will contribute to determining the penalty provision set aside by the Mangrove from the market maker's `balanceOf` balance.

  Offers are always inserted at the correct place in the book. This requires walking through offers to find the correct insertion point. As in [Oasis](https://github.com/daifoundation/maker-otc/blob/f2060c5fe12fe3da71ac98e8f6acc06bca3698f5/src/matching_market.sol#L493), the maker should find the id of an offer close to its own and provide it as `pivotId`.

  An offer cannot be inserted in a closed market, nor when a reentrancy lock for `base`,`quote` is on.

  No more than $2^{24}-1$ offers can ever be created for one `base`,`quote` pair.

  The actual contents of the function is in `writeOffer`, which is called by both `newOffer` and `updateOffer`.
  */
  function newOffer(
    address base,
    address quote,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId
  ) external returns (uint) {
    /* In preparation for calling `writeOffer`, we read the `base`,`quote` pair configuration, check for reentrancy and market liveness, fill the `OfferPack` struct and increment the `base`,`quote` pair's `last`. */
    OfferPack memory ofp;
    (ofp.global, ofp.local) = config(base, quote);
    unlockedMarketOnly(ofp.local);
    activeMarketOnly(ofp.global, ofp.local);

    ofp.id = 1 + uint(uint((ofp.local << 136)) >> 232);
    require(uint24(ofp.id) == ofp.id, "mgv/offerIdOverflow");

    ofp.local = (ofp.local & bytes32(0xffffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff) | bytes32((uint(ofp.id) << 232) >> 136));

    ofp.base = base;
    ofp.quote = quote;
    ofp.wants = wants;
    ofp.gives = gives;
    ofp.gasreq = gasreq;
    ofp.gasprice = gasprice;
    ofp.pivotId = pivotId;

    /* The second parameter to writeOffer indicates that we are creating a new offer, not updating an existing one. */
    writeOffer(ofp, false);

    /* Since we locally modified a field of the local configuration (`last`), we save the change to storage. Note that `writeOffer` may have further modified the local configuration by updating the current `best` offer. */
    locals[ofp.base][ofp.quote] = ofp.local;
    return ofp.id;
  }

  /* ## Update Offer */
  //+clear+
  /* Very similar to `newOffer`, `updateOffer` prepares an `OfferPack` for `writeOffer`. Makers should use it for updating live offers, but also to save on gas by reusing old, already consumed offers.

     A `pivotId` should still be given to minimise reads in the offer book. It is OK to give the offers' own id as a pivot.


     Gas use is minimal when:
     1. The offer does not move in the book
     2. The offer does not change its `gasreq`
     3. The (`base`,`quote`)'s `*_gasbase` has not changed since the offer was last written
     4. `gasprice` has not changed since the offer was last written
     5. `gasprice` is greater than the Mangrove's gasprice estimation
  */
  function updateOffer(
    address base,
    address quote,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external returns (uint) {
    OfferPack memory ofp;
    (ofp.global, ofp.local) = config(base, quote);
    unlockedMarketOnly(ofp.local);
    activeMarketOnly(ofp.global, ofp.local);
    ofp.base = base;
    ofp.quote = quote;
    ofp.wants = wants;
    ofp.gives = gives;
    ofp.id = offerId;
    ofp.gasreq = gasreq;
    ofp.gasprice = gasprice;
    ofp.pivotId = pivotId;
    ofp.oldOffer = offers[base][quote][offerId];
    // Save local config
    bytes32 oldLocal = ofp.local;
    /* The second argument indicates that we are updating an existing offer, not creating a new one. */
    writeOffer(ofp, true);
    /* We saved the current pair's configuration before calling `writeOffer`, since that function may update the current `best` offer. We now check for any change to the configuration and update it if needed. */
    if (oldLocal != ofp.local) {
      locals[ofp.base][ofp.quote] = ofp.local;
    }
    return ofp.id;
  }

  /* ## Retract Offer */
  //+clear+
  /* `retractOffer` takes the offer `offerId` out of the book. However, `_deprovision == true` also refunds the provision associated with the offer. */
  function retractOffer(
    address base,
    address quote,
    uint offerId,
    bool _deprovision
  ) external {
    (, bytes32 local) = config(base, quote);
    unlockedMarketOnly(local);
    bytes32 offer = offers[base][quote][offerId];
    bytes32 offerDetail = offerDetails[base][quote][offerId];
    require(
      msg.sender == address(uint((offerDetail << 0)) >> 96),
      "mgv/retractOffer/unauthorized"
    );

    /* Here, we are about to un-live an offer, so we start by taking it out of the book by stitching together its previous and next offers. Note that unconditionally calling `stitchOffers` would break the book since it would connect offers that may have since moved. */
    if (isLive(offer)) {
      bytes32 oldLocal = local;
      local = stitchOffers(
        base,
        quote,
        uint(uint((offer << 0)) >> 232),
        uint(uint((offer << 24)) >> 232),
        local
      );
      /* If calling `stitchOffers` has changed the current `best` offer, we update the storage. */
      if (oldLocal != local) {
        locals[base][quote] = local;
      }
      /* Set `gives` to 0. Moreover, the last argument depends on whether the user wishes to get their provision back. */
      dirtyDeleteOffer(base, quote, offerId, offer, _deprovision);
    }

    /* If the user wants to get their provision back, we compute its provision from the offer's `gasprice`, `*_gasbase` and `gasreq`. */
    if (_deprovision) {
      uint provision =
        10**9 *
          uint(uint((offer << 240)) >> 240) * //gasprice is 0 if offer was deprovisioned
          (uint(uint((offerDetail << 160)) >> 232) +
            uint(uint((offerDetail << 184)) >> 232) +
            uint(uint((offerDetail << 208)) >> 232));
      // credit `balanceOf` and log transfer
      creditWei(msg.sender, provision);
    }
    emit MgvEvents.RetractOffer(base, quote, offerId);
  }

  /* ## Provisioning
  Market makers must have enough provisions for possible penalties. These provisions are in ETH. Every time a new offer is created or an offer is updated, `balanceOf` is adjusted to provision the offer's maximum possible penalty (`gasprice * (gasreq + overhead_gasbase + offer_gasbase)`).

  For instance, if the current `balanceOf` of a maker is 1 ether and they create an offer that requires a provision of 0.01 ethers, their `balanceOf` will be reduced to 0.99 ethers. No ethers will move; this is just an internal accounting movement to make sure the maker cannot `withdraw` the provisioned amounts.

  */
  //+clear+

  /* Fund may be called with a nonzero value (hence the `payable` modifier). The provision will be given to `maker`, not `msg.sender`. */
  function fund(address maker) public payable {
    (bytes32 _global, ) = config(address(0), address(0));
    liveMgvOnly(_global);
    creditWei(maker, msg.value);
  }

  /* A transfer with enough gas to the Mangrove will increase the caller's available `balanceOf` balance. _You should send enough gas to execute this function when sending money to the Mangrove._  */
  receive() external payable {
    fund(msg.sender);
  }

  /* Any provision not currently held to secure an offer's possible penalty is available for withdrawal. */
  function withdraw(uint amount) external returns (bool noRevert) {
    /* Since we only ever send money to the caller, we do not need to provide any particular amount of gas, the caller should manage this herself. */
    debitWei(msg.sender, amount);
    (noRevert, ) = msg.sender.call{value: amount}("");
  }

  /* # Public Taker operations */
  //+clear+

  /* ## Market Order */
  //+clear+

  /* A market order specifies a (`base`,`quote`) pair, a desired total amount of `base` (`takerWants`), and an available total amount of `quote` (`takerGives`). It returns two `uint`s: the total amount of `base` received and the total amount of `quote` spent.

     The `takerGives/takerWants` ratio induces a maximum average price that the taker is ready to pay across all offers that will be executed during the market order. It is thus possible to execute an offer with a price worse than given as argument to `marketOrder` if some cheaper offers were executed earlier in the market order (to request a specific volume (at any price), set `takerWants` to the amount desired and `takerGives` to max uint).

  The market order stops when `takerWants` units of `base` have been obtained, or when the price has become too high, or when the end of the book has been reached. */
  function marketOrder(
    address base,
    address quote,
    uint takerWants,
    uint takerGives
  ) external returns (uint, uint) {
    return generalMarketOrder(base, quote, takerWants, takerGives, msg.sender);
  }

  /* The delegate version of `marketOrder` is `marketOrderFor`, which takes a `taker` address as additional argument. Penalties incurred by failed offers will still be sent to `msg.sender`, but exchanged amounts will be transferred from and to the `taker`. If the `msg.sender`'s allowance for the given `base`,`quote` and `taker` are strictly less than the total amount eventually spent by `taker`, the call will fail. */
  function marketOrderFor(
    address base,
    address quote,
    uint takerWants,
    uint takerGives,
    address taker
  ) external returns (uint takerGot, uint takerGave) {
    (takerGot, takerGave) = generalMarketOrder(
      base,
      quote,
      takerWants,
      takerGives,
      taker
    );
    deductSenderAllowance(base, quote, taker, takerGave);
  }

  /* ## Sniping */
  //+clear+
  /* `snipe` takes a single offer `offerId` from the book. Since offers can be updated, we specify `takerWants`,`takerGives` and `gasreq`, and only execute if the offer price is acceptable and the offer's gasreq does not exceed `gasreq`.

  It is possible to ask for 0, so we return an additional boolean indicating if `offerId` was successfully executed. Note that we do not distinguish further between mismatched arguments/offer fields on the one hand, and an execution failure on the other. Still, a failed offer has to pay a penalty, and ultimately transaction logs explicitly mention execution failures (see `MgvCommon.sol`). */

  function snipe(
    address base,
    address quote,
    uint offerId,
    uint takerWants,
    uint takerGives,
    uint gasreq
  )
    external
    returns (
      bool,
      uint,
      uint
    )
  {
    return
      generalSnipe(
        base,
        quote,
        offerId,
        takerWants,
        takerGives,
        gasreq,
        msg.sender
      );
  }

  /* The delegate version of `snipe` is `snipeFor`, which takes a `taker` address as additional argument. */
  function snipeFor(
    address base,
    address quote,
    uint offerId,
    uint takerWants,
    uint takerGives,
    uint gasreq,
    address taker
  )
    external
    returns (
      bool success,
      uint takerGot,
      uint takerGave
    )
  {
    (success, takerGot, takerGave) = generalSnipe(
      base,
      quote,
      offerId,
      takerWants,
      takerGives,
      gasreq,
      taker
    );
    deductSenderAllowance(base, quote, taker, takerGave);
  }

  /* `snipes` executes multiple offers. It takes a `uint[4][]` as last argument, with each array element of the form `[offerId,takerWants,takerGives,gasreq]`. The return parameters are of the form `(successes,totalGot,totalGave)`. */
  function snipes(
    address base,
    address quote,
    uint[4][] memory targets
  )
    external
    returns (
      uint,
      uint,
      uint
    )
  {
    return generalSnipes(base, quote, targets, msg.sender);
  }

  /* The delegate version of `snipes` is `snipesFor`, which takes a `taker` address as additional argument. */
  function snipesFor(
    address base,
    address quote,
    uint[4][] memory targets,
    address taker
  )
    external
    returns (
      uint successes,
      uint takerGot,
      uint takerGave
    )
  {
    (successes, takerGot, takerGave) = generalSnipes(
      base,
      quote,
      targets,
      taker
    );
    deductSenderAllowance(base, quote, taker, takerGave);
  }

  /* # Low-level Maker functions */

  /* ## Write Offer */

  function writeOffer(OfferPack memory ofp, bool update) internal {
    /* We check all values before packing. Otherwise, for values with a lower bound (such as `gasprice`), a check could erroneously succeed on the raw value but fail on the truncated value. */
    require(
      uint16(ofp.gasprice) == ofp.gasprice,
      "mgv/writeOffer/gasprice/16bits"
    );
    /* * Check `gasreq` below limit. Implies `gasreq` at most 24 bits wide, which ensures no overflow in computation of `provision` (see below). */
    require(
      ofp.gasreq <= uint(uint((ofp.global << 192)) >> 232),
      "mgv/writeOffer/gasreq/tooHigh"
    );
    /* * Make sure `gives > 0` -- division by 0 would throw in several places otherwise, and `isLive` relies on it. */
    require(ofp.gives > 0, "mgv/writeOffer/gives/tooLow");
    /* * Make sure that the maker is posting a 'dense enough' offer: the ratio of `base` offered per gas consumed must be high enough. The actual gas cost paid by the taker is overapproximated by adding `offer_gasbase` to `gasreq`. */
    require(
      ofp.gives >=
        (ofp.gasreq + uint(uint((ofp.local << 80)) >> 232)) *
          uint(uint((ofp.local << 24)) >> 224),
      "mgv/writeOffer/density/tooLow"
    );

    /* The following checks are for the maker's convenience only. */
    require(uint96(ofp.gives) == ofp.gives, "mgv/writeOffer/gives/96bits");
    require(uint96(ofp.wants) == ofp.wants, "mgv/writeOffer/wants/96bits");

    /* `gasprice` given by maker will be bounded below by internal gasprice estimate at offer write time. With a large enough overapproximation of the gasprice, the maker can regularly update their offer without paying for writes to their `balanceOf`.  */
    if (ofp.gasprice < uint(uint((ofp.global << 176)) >> 240)) {
      ofp.gasprice = uint(uint((ofp.global << 176)) >> 240);
    }

    /* Log the write offer event with some packing to save a ~1k gas. */
    {
      bytes32 writeOfferData =
        (((((bytes32(0) | bytes32((uint(ofp.wants) << 160) >> 0)) | bytes32((uint(ofp.gives) << 160) >> 96)) | bytes32((uint(ofp.gasreq) << 232) >> 208)) | bytes32((uint(ofp.gasprice) << 240) >> 192)) | bytes32((uint(ofp.id) << 232) >> 232));
      emit MgvEvents.WriteOffer(
        ofp.base,
        ofp.quote,
        msg.sender,
        writeOfferData
      );
    }

    /* The position of the new or updated offer is found using `findPosition`. If the offer is the best one, `prev == 0`, and if it's the last in the book, `next == 0`.

       `findPosition` is only ever called here, but exists as a separate function to make the code easier to read.

    **Warning**: `findPosition` will call `better`, which may read the offer's `offerDetails`. So it is important to find the offer position _before_ we update its `offerDetail` in storage. We waste 1 read in that case but we deem that the code would get too ugly if we passed the old offerDetail as argument to `findPosition` and to `better`, just to save 1 read in that specific case.  */
    (uint prev, uint next) = findPosition(ofp);

    /* We now write the new offerDetails and remember the previous provision (0 by default, for new offers) to balance out maker's `balanceOf`. */
    uint oldProvision;
    {
      bytes32 offerDetail = offerDetails[ofp.base][ofp.quote][ofp.id];
      if (update) {
        require(
          msg.sender == address(uint((offerDetail << 0)) >> 96),
          "mgv/updateOffer/unauthorized"
        );
        oldProvision =
          10**9 *
          uint(uint((ofp.oldOffer << 240)) >> 240) *
          (uint(uint((offerDetail << 160)) >> 232) +
            uint(uint((offerDetail << 184)) >> 232) +
            uint(uint((offerDetail << 208)) >> 232));
      }

      /* If the offer is new, has a new gasreq, or if the Mangrove's `*_gasbase` configuration parameter has changed, we also update offerDetails. */
      if (
        !update ||
        uint(uint((offerDetail << 160)) >> 232) != ofp.gasreq ||
        uint(uint((offerDetail << 184)) >> 232) !=
        uint(uint((ofp.local << 56)) >> 232) ||
        uint(uint((offerDetail << 208)) >> 232) !=
        uint(uint((ofp.local << 80)) >> 232)
      ) {
        uint overhead_gasbase = uint(uint((ofp.local << 56)) >> 232);
        uint offer_gasbase = uint(uint((ofp.local << 80)) >> 232);
        offerDetails[ofp.base][ofp.quote][ofp.id] = ((((bytes32(0) | bytes32((uint(uint(msg.sender)) << 96) >> 0)) | bytes32((uint(ofp.gasreq) << 232) >> 160)) | bytes32((uint(overhead_gasbase) << 232) >> 184)) | bytes32((uint(offer_gasbase) << 232) >> 208));
      }
    }

    /* With every change to an offer, a maker must deduct provisions from its `balanceOf` balance, or get some back if the updated offer requires fewer provisions. */
    {
      uint provision =
        (ofp.gasreq +
          uint(uint((ofp.local << 80)) >> 232) +
          uint(uint((ofp.local << 56)) >> 232)) *
          ofp.gasprice *
          10**9;
      if (provision > oldProvision) {
        debitWei(msg.sender, provision - oldProvision);
      } else if (provision < oldProvision) {
        creditWei(msg.sender, oldProvision - provision);
      }
    }
    /* We now place the offer in the book at the position found by `findPosition`. */

    /* First, we test if the offer has moved in the book or is not currently in the book. If `!isLive(ofp.oldOffer)`, we must update its prev/next. If it is live but its prev has changed, we must also update them. Note that checking both `prev = oldPrev` and `next == oldNext` would be redundant. If either is true, then the updated offer has not changed position and there is nothing to update.

    As a note for future changes, there is a tricky edge case where `prev == oldPrev` yet the prev/next should be changed: a previously-used offer being brought back in the book, and ending with the same prev it had when it was in the book. In that case, the neighbor is currently pointing to _another_ offer, and thus must be updated. With the current code structure, this is taken care of as a side-effect of checking `!isLive`, but should be kept in mind. The same goes in the `next == oldNext` case. */
    if (!isLive(ofp.oldOffer) || prev != uint(uint((ofp.oldOffer << 0)) >> 232)) {
      /* * If the offer is not the best one, we update its predecessor; otherwise we update the `best` value. */
      if (prev != 0) {
        offers[ofp.base][ofp.quote][prev] = (offers[ofp.base][ofp.quote][prev] & bytes32(0xffffff000000ffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(ofp.id) << 232) >> 24));
      } else {
        ofp.local = (ofp.local & bytes32(0xffffffffffffffffffffffffffff000000ffffffffffffffffffffffffffffff) | bytes32((uint(ofp.id) << 232) >> 112));
      }

      /* * If the offer is not the last one, we update its successor. */
      if (next != 0) {
        offers[ofp.base][ofp.quote][next] = (offers[ofp.base][ofp.quote][next] & bytes32(0x000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(ofp.id) << 232) >> 0));
      }

      /* * Recall that in this branch, the offer has changed location, or is not currently in the book. If the offer is not new and already in the book, we must remove it from its previous location by stitching its previous prev/next. */
      if (update && isLive(ofp.oldOffer)) {
        ofp.local = stitchOffers(
          ofp.base,
          ofp.quote,
          uint(uint((ofp.oldOffer << 0)) >> 232),
          uint(uint((ofp.oldOffer << 24)) >> 232),
          ofp.local
        );
      }
    }

    /* With the `prev`/`next` in hand, we finally store the offer in the `offers` map. */
    bytes32 ofr =
      (((((bytes32(0) | bytes32((uint(prev) << 232) >> 0)) | bytes32((uint(next) << 232) >> 24)) | bytes32((uint(ofp.wants) << 160) >> 144)) | bytes32((uint(ofp.gives) << 160) >> 48)) | bytes32((uint(ofp.gasprice) << 240) >> 240));
    offers[ofp.base][ofp.quote][ofp.id] = ofr;
  }

  /* ## Find Position */
  /* `findPosition` takes a price in the form of a (`ofp.wants`,`ofp.gives`) pair, an offer id (`ofp.pivotId`) and walks the book from that offer (backward or forward) until the right position for the price is found. The position is returned as a `(prev,next)` pair, with `prev` or `next` at 0 to mark the beginning/end of the book (no offer ever has id 0).

  If prices are equal, `findPosition` will put the newest offer last. */
  function findPosition(OfferPack memory ofp)
    internal
    view
    returns (uint, uint)
  {
    uint prevId;
    uint nextId;
    uint pivotId = ofp.pivotId;
    /* Get `pivot`, optimizing for the case where pivot info is already known */
    bytes32 pivot =
      pivotId == ofp.id ? ofp.oldOffer : offers[ofp.base][ofp.quote][pivotId];

    /* In case pivotId is not an active offer, it is unusable (since it is out of the book). We default to the current best offer. If the book is empty pivot will be 0. That is handled through a test in the `better` comparison function. */
    if (!isLive(pivot)) {
      pivotId = uint(uint((ofp.local << 112)) >> 232);
      pivot = offers[ofp.base][ofp.quote][pivotId];
    }

    /* * Pivot is better than `wants/gives`, we follow `next`. */
    if (better(ofp, pivot, pivotId)) {
      bytes32 pivotNext;
      while (uint(uint((pivot << 24)) >> 232) != 0) {
        uint pivotNextId = uint(uint((pivot << 24)) >> 232);
        pivotNext = offers[ofp.base][ofp.quote][pivotNextId];
        if (better(ofp, pivotNext, pivotNextId)) {
          pivotId = pivotNextId;
          pivot = pivotNext;
        } else {
          break;
        }
      }
      // gets here on empty book
      (prevId, nextId) = (pivotId, uint(uint((pivot << 24)) >> 232));

      /* * Pivot is strictly worse than `wants/gives`, we follow `prev`. */
    } else {
      bytes32 pivotPrev;
      while (uint(uint((pivot << 0)) >> 232) != 0) {
        uint pivotPrevId = uint(uint((pivot << 0)) >> 232);
        pivotPrev = offers[ofp.base][ofp.quote][pivotPrevId];
        if (better(ofp, pivotPrev, pivotPrevId)) {
          break;
        } else {
          pivotId = pivotPrevId;
          pivot = pivotPrev;
        }
      }

      (prevId, nextId) = (uint(uint((pivot << 0)) >> 232), pivotId);
    }

    return (
      prevId == ofp.id ? uint(uint((ofp.oldOffer << 0)) >> 232) : prevId,
      nextId == ofp.id ? uint(uint((ofp.oldOffer << 24)) >> 232) : nextId
    );
  }

  /* ## Better */
  /* The utility method `better` takes an offer represented by `ofp` and another represented by `offer1`. It returns true iff `offer1` is better or as good as `ofp`.
    "better" is defined on the lexicographic order $\textrm{price} \times_{\textrm{lex}} \textrm{density}^{-1}$. This means that for the same price, offers that deliver more volume per gas are taken first.

      In addition to `offer1`, we also provide its id, `offerId1` in order to save gas. If necessary (ie. if the prices `wants1/gives1` and `wants2/gives2` are the same), we read storage to get `gasreq1` at `offerDetails[...][offerId1]. */
  function better(
    OfferPack memory ofp,
    bytes32 offer1,
    uint offerId1
  ) internal view returns (bool) {
    if (offerId1 == 0) {
      /* Happens on empty book. Returning `false` would work as well due to specifics of `findPosition` but true is more consistent. Here we just want to avoid reading `offerDetail[...][0]` for nothing. */
      return true;
    }
    uint wants1 = uint(uint((offer1 << 144)) >> 160);
    uint gives1 = uint(uint((offer1 << 48)) >> 160);
    uint wants2 = ofp.wants;
    uint gives2 = ofp.gives;
    uint weight1 = wants1 * gives2;
    uint weight2 = wants2 * gives1;
    if (weight1 == weight2) {
      uint gasreq1 =
        uint(uint((offerDetails[ofp.base][ofp.quote][offerId1] << 160)) >> 232);
      uint gasreq2 = ofp.gasreq;
      return (gives1 * gasreq2 >= gives2 * gasreq1);
    } else {
      return weight1 < weight2;
    }
  }

  /* # Low-level Taker functions */

  /* The `MultiOrder` struct is used by market orders and snipes. Some of its fields are only used by market orders (`initialWants, initialGives`), and `successCount` is only used by snipes. The struct is helpful in decreasing stack use. */
  struct MultiOrder {
    uint initialWants;
    uint initialGives;
    uint totalGot;
    uint totalGave;
    uint totalPenalty;
    address taker;
    uint successCount;
    uint failCount;
  }

  /* ## General Market Order */
  //+clear+
  /* General market orders set up the market order with a given `taker` (`msg.sender` in the most common case). Returns `(totalGot, totalGave)`. */
  function generalMarketOrder(
    address base,
    address quote,
    uint takerWants,
    uint takerGives,
    address taker
  ) internal returns (uint, uint) {
    /* Since amounts stored in offers are 96 bits wide, checking that `takerWants` fits in 160 bits prevents overflow during the main market order loop. */
    require(uint160(takerWants) == takerWants, "mgv/mOrder/takerWants/160bits");

    /* `SingleOrder` is defined in `MgvCommon.sol` and holds information for ordering the execution of one offer. */
    MC.SingleOrder memory sor;
    sor.base = base;
    sor.quote = quote;
    (sor.global, sor.local) = config(base, quote);
    /* Throughout the execution of the market order, the `sor`'s offer id and other parameters will change. We start with the current best offer id (0 if the book is empty). */
    sor.offerId = uint(uint((sor.local << 112)) >> 232);
    sor.offer = offers[base][quote][sor.offerId];
    /* `sor.wants` and `sor.gives` may evolve, but they are initially however much remains in the market order. */
    sor.wants = takerWants;
    sor.gives = takerGives;

    /* `MultiOrder` (defined above) maintains information related to the entire market order. During the order, initial `wants`/`gives` values minus the accumulated amounts traded so far give the amounts that remain to be traded. */
    MultiOrder memory mor;
    mor.initialWants = takerWants;
    mor.initialGives = takerGives;
    mor.taker = taker;

    /* For the market order to even start, the market needs to be both active, and not currently protected from reentrancy. */
    activeMarketOnly(sor.global, sor.local);
    unlockedMarketOnly(sor.local);

    /* ### Initialization */
    /* The market order will operate as follows : it will go through offers from best to worse, starting from `offerId`, and: */
    /* * will maintain remaining `takerWants` and `takerGives` values. The initial `takerGives/takerWants` ratio is the average price the taker will accept. Better prices may be found early in the book, and worse ones later.
     * will not set `prev`/`next` pointers to their correct locations at each offer taken (this is an optimization enabled by forbidding reentrancy).
     * after consuming a segment of offers, will update the current `best` offer to be the best remaining offer on the book. */

    /* We start be enabling the reentrancy lock for this (`base`,`quote`) pair. */
    sor.local = (sor.local & bytes32(0xffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffff) | bytes32((uint(1) << 248) >> 104));
    locals[base][quote] = sor.local;

    /* `internalMarketOrder` works recursively. Going downward, each successive offer is executed until the market order stops (due to: volume exhausted, bad price, or empty book). Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book.

    The last argument is a boolean named `proceed`. If an offer was not executed, it means the price has become too high. In that case, we notify the next recursive call that the market order should end. In this initial call, no offer has been executed yet so `proceed` is true. */
    internalMarketOrder(mor, sor, true);

    /* Over the course of the market order, a penalty reserved for `msg.sender` has accumulated in `mor.totalPenalty`. No actual transfers have occured yet -- all the ethers given by the makers as provision are owned by the Mangrove. `sendPenalty` finally gives the accumulated penalty to `msg.sender`. */
    sendPenalty(mor.totalPenalty);
    //+clear+
    return (mor.totalGot, mor.totalGave);
  }

  /* ### Recursive market order function */
  //+clear+
  function internalMarketOrder(
    MultiOrder memory mor,
    MC.SingleOrder memory sor,
    bool proceed
  ) internal {
    /* #### Case 1 : End of order */
    /* We execute the offer currently stored in `sor`. */
    if (proceed && sor.wants > 0 && sor.offerId > 0) {
      bool success; // execution success/failure
      uint gasused; // gas used by `makerTrade`
      bytes32 makerData; // data returned by maker
      bytes32 errorCode; // internal Mangrove error code
      /* `executed` is false if offer could not be executed against 2nd and 3rd argument of execute. Currently, we interrupt the loop and let the taker leave with less than they asked for (but at a correct price). We could also revert instead of breaking; this could be a configurable flag for the taker to pick. */
      // reduce stack size for recursion

      bool executed; // offer execution attempted or not

      /* Load additional information about the offer. We don't do it earlier to save one storage read in case `proceed` was false. */
      sor.offerDetail = offerDetails[sor.base][sor.quote][sor.offerId];

      /* `execute` will adjust `sor.wants`,`sor.gives`, and may attempt to execute the offer if its price is low enough. It is crucial that an error due to `taker` triggers a revert. That way, `!success && !executed` means there was no execution attempt, and `!success && executed` means the failure is the maker's fault. */
      /* Post-execution, `sor.wants`/`sor.gives` reflect how much was sent/taken by the offer. We will need it after the recursive call, so we save it in local variables. Same goes for `offerId`, `sor.offer` and `sor.offerDetail`. */

      (success, executed, gasused, makerData, errorCode) = execute(mor, sor);

      /* Keep cached copy of current `sor` values. */
      uint takerWants = sor.wants;
      uint takerGives = sor.gives;
      uint offerId = sor.offerId;
      bytes32 offer = sor.offer;
      bytes32 offerDetail = sor.offerDetail;

      /* If an execution was attempted, we move `sor` to the next offer. Note that the current state is inconsistent, since we have not yet updated `sor.offerDetails`. */
      if (executed) {
        /* It is known statically that `mor.initialWants - mor.totalGot` does not underflow since
      1. `mor.totalGot` was increased by `sor.wants` during `execute`,
      2. `sor.wants` was at most `mor.initialWants - mor.totalGot` from earlier step,
      3. `sor.wants` may be have been clamped _down_ to `offer.gives` during `execute`
      */
        sor.wants = mor.initialWants - mor.totalGot;
        /* It is known statically that `mor.initialGives - mor.totalGave` does not underflow since
           1. `mor.totalGave` was increase by `sor.gives` during `execute`,
           2. `sor.gives` was at most `mor.initialGives - mor.totalGave` from earlier step,
           3. `sor.gives` may have been clamped _down_ during `execute` (to `makerWouldWant`, cf. code of `execute`).
        */
        sor.gives = mor.initialGives - mor.totalGave;
        sor.offerId = uint(uint((sor.offer << 24)) >> 232);
        sor.offer = offers[sor.base][sor.quote][sor.offerId];
      }

      /* note that internalMarketOrder may be called twice with same offerId, but in that case `proceed` will be false! */
      internalMarketOrder(
        mor,
        sor,
        // `proceed` value for next call
        executed
      );

      /* Restore `sor` values from to before recursive call */
      sor.offerId = offerId;
      sor.wants = takerWants;
      sor.gives = takerGives;
      sor.offer = offer;
      sor.offerDetail = offerDetail;

      /* After an offer execution, we may run callbacks and increase the total penalty. As that part is common to market orders and snipes, it lives in its own `postExecute` function. */
      if (executed) {
        postExecute(mor, sor, success, gasused, makerData, errorCode);
      }
      /* #### Case 2 : End of market order */
      /* If `proceed` is false, the taker has gotten its requested volume, or we have reached the end of the book, we conclude the market order. */
    } else {
      /* During the market order, all executed offers have been removed from the book. We end by stitching together the `best` offer pointer and the new best offer. */
      sor.local = stitchOffers(sor.base, sor.quote, 0, sor.offerId, sor.local);
      /* Now that the market order is over, we can lift the lock on the book. In the same operation we

      * lift the reentrancy lock, and
      * update the storage

      so we are free from out of order storage writes.
      */
      sor.local = (sor.local & bytes32(0xffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffff) | bytes32((uint(0) << 248) >> 104));
      locals[sor.base][sor.quote] = sor.local;

      /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
      payTakerMinusFees(mor, sor);

      /* In an FTD, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in an FMD. */
      executeEnd(mor, sor);
    }
  }

  /* ## General Snipe(s) */
  /* A conduit from `snipe` and `snipeFor` to `generalSnipes`. Returns `(success,takerGot,takerGave)`. */
  function generalSnipe(
    address base,
    address quote,
    uint offerId,
    uint takerWants,
    uint takerGives,
    uint gasreq,
    address taker
  )
    internal
    returns (
      bool,
      uint,
      uint
    )
  {
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [offerId, takerWants, takerGives, gasreq];
    (uint successes, uint takerGot, uint takerGave) =
      generalSnipes(base, quote, targets, taker);
    return (successes == 1, takerGot, takerGave);
  }

  /*
     From an array of _n_ `[offerId, takerWants,takerGives,gasreq]` elements, execute each snipe in sequence. Returns `(successes, takerGot, takerGave)`. */
  function generalSnipes(
    address base,
    address quote,
    uint[4][] memory targets,
    address taker
  )
    internal
    returns (
      uint,
      uint,
      uint
    )
  {
    MC.SingleOrder memory sor;
    sor.base = base;
    sor.quote = quote;
    (sor.global, sor.local) = config(base, quote);

    MultiOrder memory mor;
    mor.taker = taker;

    /* For the snipes to even start, the market needs to be both active and not currently protected from reentrancy. */
    activeMarketOnly(sor.global, sor.local);
    unlockedMarketOnly(sor.local);

    /* ### Main loop */
    //+clear+

    /* We start be enabling the reentrancy lock for this (`base`,`quote`) pair. */
    sor.local = (sor.local & bytes32(0xffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffff) | bytes32((uint(1) << 248) >> 104));
    locals[base][quote] = sor.local;

    /* `internalSnipes` works recursively. Going downward, each successive offer is executed until each snipe in the array has been tried. Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book.

    The last argument is the array index for the current offer. It is initially 0. */
    internalSnipes(mor, sor, targets, 0);

    /* Over the course of the snipes order, a penalty reserved for `msg.sender` has accumulated in `mor.totalPenalty`. No actual transfers have occured yet -- all the ethers given by the makers as provision are owned by the Mangrove. `sendPenalty` finally gives the accumulated penalty to `msg.sender`. */
    sendPenalty(mor.totalPenalty);
    //+clear+
    return (mor.successCount, mor.totalGot, mor.totalGave);
  }

  /* ### Recursive snipes function */
  //+clear+
  function internalSnipes(
    MultiOrder memory mor,
    MC.SingleOrder memory sor,
    uint[4][] memory targets,
    uint i
  ) internal {
    /* #### Case 1 : continuation of snipes */
    if (i < targets.length) {
      sor.offerId = targets[i][0];
      sor.offer = offers[sor.base][sor.quote][sor.offerId];
      sor.offerDetail = offerDetails[sor.base][sor.quote][sor.offerId];

      /* If we removed the `isLive` conditional, a single expired or nonexistent offer in `targets` would revert the entire transaction (by the division by `offer.gives` below since `offer.gives` would be 0). We also check that `gasreq` is not worse than specified. A taker who does not care about `gasreq` can specify any amount larger than $2^{24}-1$. A mismatched price will be detected by `execute`. */
      if (
        !isLive(sor.offer) ||
        uint(uint((sor.offerDetail << 160)) >> 232) > targets[i][3]
      ) {
        /* We move on to the next offer in the array. */
        internalSnipes(mor, sor, targets, i + 1);
      } else {
        bool success;
        uint gasused;
        bool executed;
        bytes32 makerData;
        bytes32 errorCode;

        require(
          uint96(targets[i][1]) == targets[i][1],
          "mgv/snipes/takerWants/96bits"
        );
        sor.wants = targets[i][1];
        sor.gives = targets[i][2];

        /* `execute` will adjust `sor.wants`,`sor.gives`, and may attempt to execute the offer if its price is low enough. It is crucial that an error due to `taker` triggers a revert. That way, `!success && !executed` means there was no execution attempt, and `!success && executed` means the failure is the maker's fault. */
        /* Post-execution, `sor.wants`/`sor.gives` reflect how much was sent/taken by the offer. We will need it after the recursive call, so we save it in local variables. Same goes for `offerId`, `sor.offer` and `sor.offerDetail`. */
        (success, executed, gasused, makerData, errorCode) = execute(mor, sor);

        /* In the market order, we were able to avoid stitching back offers after every `execute` since we knew a continuous segment starting at best would be consumed. Here, we cannot do this optimisation since offers in the `targets` array may be anywhere in the book. So we stitch together offers immediately after each `execute`. */
        if (executed) {
          sor.local = stitchOffers(
            sor.base,
            sor.quote,
            uint(uint((sor.offer << 0)) >> 232),
            uint(uint((sor.offer << 24)) >> 232),
            sor.local
          );
        }

        {
          /* Keep cached copy of current `sor` values. */
          uint offerId = sor.offerId;
          uint takerWants = sor.wants;
          uint takerGives = sor.gives;
          bytes32 offer = sor.offer;
          bytes32 offerDetail = sor.offerDetail;

          /* We move on to the next offer in the array. */
          internalSnipes(mor, sor, targets, i + 1);

          /* Restore `sor` values from to before recursive call */
          sor.offerId = offerId;
          sor.wants = takerWants;
          sor.gives = takerGives;
          sor.offer = offer;
          sor.offerDetail = offerDetail;
        }

        /* After an offer execution, we may run callbacks and increase the total penalty. As that part is common to market orders and snipes, it lives in its own `postExecute` function. */
        if (executed) {
          postExecute(mor, sor, success, gasused, makerData, errorCode);
        }
      }
      /* #### Case 2 : End of snipes */
    } else {
      /* Now that the snipes is over, we can lift the lock on the book. In the same operation we
      * lift the reentrancy lock, and
      * update the storage

      so we are free from out of order storage writes.
      */
      sor.local = (sor.local & bytes32(0xffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffff) | bytes32((uint(0) << 248) >> 104));
      locals[sor.base][sor.quote] = sor.local;
      /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
      payTakerMinusFees(mor, sor);
      /* In an FTD, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in an FMD. */
      executeEnd(mor, sor);
    }
  }

  /* ## Execute */
  /* This function will compare `sor.wants` `sor.gives` with `sor.offer.wants` and `sor.offer.gives`. If the price of the offer is low enough, an execution will be attempted (with volume limited by the offer's advertised volume).

     Summary of the meaning of the return values:
    * `gasused` is the gas consumed by the execution
    * `makerData` is the data returned after executing the offer
    * `errorCode` is the internal Mangrove error code
    * `success -> executed`
    * `success && executed`: offer has succeeded
    * `!success && executed`: offer has failed
    * `!success && !executed`: offer has not been executed */
  function execute(MultiOrder memory mor, MC.SingleOrder memory sor)
    internal
    returns (
      bool success,
      bool executed,
      uint gasused,
      bytes32 makerData,
      bytes32 errorCode
    )
  {
    /* #### `makerWouldWant` */
    //+clear+
    /* The current offer has a price <code>_p_ = sor.offer.wants/sor.offer.gives</code>. `makerWouldWant` is the amount of `quote` the offer would require at price _p_ to provide `sor.wants` `base`. Computing `makeWouldWant` gives us both a test that _p_ is an acceptable price for the taker, and the amount of `quote` to send to the maker.

    **Note**: We never check that `offerId` is actually a `uint24`, or that `offerId` actually points to an offer: it is not possible to insert an offer with an id larger than that, and a wrong `offerId` will point to a zero-initialized offer, which will revert the call when dividing by `offer.gives`.

   Prices are rounded down.

   **Historical note**: prices used to be rounded up (`makerWouldWant = product/offer.gives + (product % offer.gives == 0 ? 0 : 1)`) because partially filled offers used to remain on the book. A snipe which names an offer by its id also specifies its price in the form of a `(wants,gives)` pair to be compared to the offers' `(wants,gives)`. When a snipe can specifies a wants and a gives, it accepts any offer price better than `wants/gives`.

   Now consider an order $r$ for the offer $o$. If $o$ is partially consumed into $o'$ before $r$ is mined, we still want $r$ to succeed (as long as $o'$ has enough volume). But `wants` and `gives` of $o$ are not equal to `wants` and `gives` of $o'$. Worse: their ratios are not equal, due to rounding errors.

   Our solution was to make sure that the price of a partially filled offer could only improve. To do that, we rounded up the amount required by the maker.
       */
    uint makerWouldWant =
      (sor.wants * uint(uint((sor.offer << 144)) >> 160)) / uint(uint((sor.offer << 48)) >> 160);

    /* If the price is too high, we return early. Otherwise we now know we'll execute the offer. */
    if (makerWouldWant > sor.gives) {
      return (false, false, 0, bytes32(0), bytes32(0));
    }

    executed = true;

    /* If the current offer is good enough for the taker can accept, we compute how much the taker should give/get on the _current offer_. So we adjust `sor.wants` and `sor.gives` as follow: if the offer cannot fully satisfy the taker (`sor.offer.gives < sor.wants`), we consume the entire offer. Otherwise `sor.wants` doesn't need to change (the taker will receive everything they wants), and `sor.gives` is adjusted downward to meet the offer's price. */
    if (uint(uint((sor.offer << 48)) >> 160) < sor.wants) {
      sor.wants = uint(uint((sor.offer << 48)) >> 160);
      sor.gives = uint(uint((sor.offer << 144)) >> 160);
    } else {
      sor.gives = makerWouldWant;
    }

    /* The flashloan is executed by call to `FLASHLOANER`. If the call reverts, it means the maker failed to send back `sor.wants` `base` to the taker. Notes :
     * `msg.sender` is the Mangrove itself in those calls -- all operations related to the actual caller should be done outside of this call.
     * any spurious exception due to an error in Mangrove code will be falsely blamed on the Maker, and its provision for the offer will be unfairly taken away.
     */
    bytes memory retdata;
    (success, retdata) = address(this).call(
      abi.encodeWithSelector(FLASHLOANER, sor, mor.taker)
    );

    /* `success` is true: trade is complete */
    if (success) {
      mor.successCount += 1;
      /* In case of success, `retdata` encodes the gas used by the offer. */
      gasused = abi.decode(retdata, (uint));

      emit MgvEvents.Success(
        sor.base,
        sor.quote,
        sor.offerId,
        mor.taker,
        sor.wants,
        sor.gives
      );

      /* If configured to do so, the Mangrove notifies an external contract that a successful trade has taken place. */
      if (uint(uint((sor.global << 168)) >> 248) > 0) {
        IMgvMonitor(address(uint((sor.global << 0)) >> 96)).notifySuccess(
          sor,
          mor.taker
        );
      }

      /* We update the totals in the multiorder based on the adjusted `sor.wants`/`sor.gives`. */
      mor.totalGot += sor.wants;
      mor.totalGave += sor.gives;
    } else {
      /* In case of failure, `retdata` encodes a short error code, the gas used by the offer, and an arbitrary 256 bits word sent by the maker. `errorCode` should not be exploitable by the maker! */
      (errorCode, gasused, makerData) = innerDecode(retdata);
      /* Note that in the `if`s, the literals are bytes32 (stack values), while as revert arguments, they are strings (memory pointers). */
      if (
        errorCode == "mgv/makerRevert" ||
        errorCode == "mgv/makerTransferFail" ||
        errorCode == "mgv/makerReceiveFail"
      ) {
        mor.failCount += 1;

        emit MgvEvents.MakerFail(
          sor.base,
          sor.quote,
          sor.offerId,
          mor.taker,
          sor.wants,
          sor.gives,
          errorCode,
          makerData
        );

        /* If configured to do so, the Mangrove notifies an external contract that a failed trade has taken place. */
        if (uint(uint((sor.global << 168)) >> 248) > 0) {
          IMgvMonitor(address(uint((sor.global << 0)) >> 96)).notifyFail(
            sor,
            mor.taker
          );
        }
        /* It is crucial that any error code which indicates an error caused by the taker triggers a revert, because functions that call `execute` consider that `execute && !success` should be blamed on the maker. */
      } else if (errorCode == "mgv/notEnoughGasForMakerTrade") {
        revert("mgv/notEnoughGasForMakerTrade");
      } else if (errorCode == "mgv/takerFailToPayMaker") {
        revert("mgv/takerFailToPayMaker");
      } else {
        /* This code must be unreachable. **Danger**: if a well-crafted offer/maker pair can force a revert of FLASHLOANER, the Mangrove will be stuck. */
        revert("mgv/swapError");
      }
    }

    /* Delete the offer. The last argument indicates whether the offer should be stripped of its provision (yes if execution failed, no otherwise). We delete offers whether the amount remaining on offer is > density or not for the sake of uniformity (code is much simpler). We also expect prices to move often enough that the maker will want to update their price anyway. To simulate leaving the remaining volume in the offer, the maker can program their `makerPosthook` to `updateOffer` and put the remaining volume back in. */
    if (executed) {
      dirtyDeleteOffer(sor.base, sor.quote, sor.offerId, sor.offer, !success);
    }
  }

  /* ## Post execute */
  /* After executing an offer (whether in a market order or in snipes), we
     1. FTD only, if execution successful: transfer the correct amount back to the maker.
     2. If offer was executed: call the maker's posthook and sum the total gas used. In FTD, the posthook is called with the amount already in the maker's hands.
     3. If offer failed: sum total penalty due to taker and give remainder to maker.
   */
  function postExecute(
    MultiOrder memory mor,
    MC.SingleOrder memory sor,
    bool success,
    uint gasused,
    bytes32 makerData,
    bytes32 errorCode
  ) internal {
    if (success) {
      executeCallback(sor);
    }

    uint gasreq = uint(uint((sor.offerDetail << 160)) >> 232);

    /* We are about to call back the maker, giving it its unused gas (`gasreq - gasused`). Since the gas used so far may exceed `gasreq`, we prevent underflow in the subtraction below by bounding `gasused` above with `gasreq`. We could have decided not to call back the maker at all when there is no gas left, but we do it for uniformity. */
    if (gasused > gasreq) {
      gasused = gasreq;
    }

    gasused =
      gasused +
      makerPosthook(sor, gasreq - gasused, success, makerData, errorCode);

    /* Once again, the gas used may exceed `gasreq`. Since penalties extracted depend on `gasused` and the maker has at most provisioned for `gasreq` being used, we prevent fund leaks by bounding `gasused` once more. */
    if (gasused > gasreq) {
      gasused = gasreq;
    }

    if (!success) {
      mor.totalPenalty += applyPenalty(sor, gasused, mor.failCount);
    }
  }

  /* ## Maker Posthook */
  function makerPosthook(
    MC.SingleOrder memory sor,
    uint gasLeft,
    bool success,
    bytes32 makerData,
    bytes32 errorCode
  ) internal returns (uint gasused) {
    /* At this point, errorCode can only be "mgv/makerRevert" or "mgv/makerTransferFail" */
    bytes memory cd =
      abi.encodeWithSelector(
        IMaker.makerPosthook.selector,
        sor,
        MC.OrderResult({
          success: success,
          makerData: makerData,
          errorCode: errorCode
        })
      );

    /* Calls an external function with controlled gas expense. A direct call of the form `(,bytes memory retdata) = maker.call{gas}(selector,...args)` enables a griefing attack: the maker uses half its gas to write in its memory, then reverts with that memory segment as argument. After a low-level call, solidity automaticaly copies `returndatasize` bytes of `returndata` into memory. So the total gas consumed to execute a failing offer could exceed `gasreq`. This yul call only retrieves the first byte of the maker's `returndata`. */
    bytes memory retdata = new bytes(32);

    address maker = address(uint((sor.offerDetail << 0)) >> 96);

    uint oldGas = gasleft();
    /* We let the maker pay for the overhead of checking remaining gas and making the call. So the `require` below is just an approximation: if the overhead of (`require` + cost of `CALL`) is $h$, the maker will receive at worst $\textrm{gasreq} - \frac{63h}{64}$ gas. */
    if (!(oldGas - oldGas / 64 >= gasLeft)) {
      revert("mgv/notEnoughGasForMakerPosthook");
    }

    assembly {
      let success2 := call(
        gasLeft,
        maker,
        0,
        add(cd, 32),
        mload(cd),
        add(retdata, 32),
        32
      )
    }
    gasused = oldGas - gasleft();
  }

  /* # Low-level offer deletion */

  /* When an offer is deleted, it is marked as such by setting `gives` to 0. Note that provision accounting in the Mangrove aims to minimize writes. Each maker `fund`s the Mangrove to increase its balance. When an offer is created/updated, we compute how much should be reserved to pay for possible penalties. That amount can always be recomputed with `offer.gasprice * (offerDetail.gasreq + offerDetail.overhead_gasbase + offerDetail.offer_gasbase)`. The balance is updated to reflect the remaining available ethers.

     Now, when an offer is deleted, the offer can stay provisioned, or be `deprovision`ed. In the latter case, we set `gasprice` to 0, which induces a provision of 0. */
  function dirtyDeleteOffer(
    address base,
    address quote,
    uint offerId,
    bytes32 offer,
    bool deprovision
  ) internal {
    offer = (offer & bytes32(0xffffffffffff000000000000000000000000ffffffffffffffffffffffffffff) | bytes32((uint(0) << 160) >> 48));
    if (deprovision) {
      offer = (offer & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000) | bytes32((uint(0) << 240) >> 240));
    }
    offers[base][quote][offerId] = offer;
  }

  /* Post-trade, `payTakerMinusFees` sends what's due to the taker and the rest (the fees) to the vault. Routing through the Mangrove like that also deals with blacklisting issues (separates the maker-blacklisted and the taker-blacklisted cases). */
  function payTakerMinusFees(MultiOrder memory mor, MC.SingleOrder memory sor)
    internal
  {
    /* Should be statically provable that the 2 transfers below cannot return false under well-behaved ERC20s and a non-blacklisted, non-0 target. */

    uint concreteFee = (mor.totalGot * uint(uint((sor.local << 8)) >> 240)) / 10_000;
    if (concreteFee > 0) {
      mor.totalGot -= concreteFee;
      require(
        transferToken(sor.base, vault, concreteFee),
        "mgv/feeTransferFail"
      );
    }
    if (mor.totalGot > 0) {
      require(
        transferToken(sor.base, mor.taker, mor.totalGot),
        "mgv/MgvFailToPayTaker"
      );
    }
  }

  /* # Penalties */
  /* Offers are just promises. They can fail. Penalty provisioning discourages from failing too much: we ask makers to provision more ETH than the expected gas cost of executing their offer and penalize them accoridng to wasted gas.

     Under normal circumstances, we should expect to see bots with a profit expectation dry-running offers locally and executing `snipe` on failing offers, collecting the penalty. The result should be a mostly clean book for actual takers (i.e. a book with only successful offers).

     **Incentive issue**: if the gas price increases enough after an offer has been created, there may not be an immediately profitable way to remove the fake offers. In that case, we count on 3 factors to keep the book clean:
     1. Gas price eventually comes down.
     2. Other market makers want to keep the Mangrove attractive and maintain their offer flow.
     3. Mangrove governance (who may collect a fee) wants to keep the Mangrove attractive and maximize exchange volume.

  //+clear+
  /* After an offer failed, part of its provision is given back to the maker and the rest is stored to be sent to the taker after the entire order completes. In `applyPenalty`, we _only_ credit the maker with its excess provision. So it looks like the maker is gaining something. In fact they're just getting back a fraction of what they provisioned earlier.
  /*
     Penalty application summary:

   * If the transaction was a success, we entirely refund the maker and send nothing to the taker.
   * Otherwise, the maker loses the cost of `gasused + overhead_gasbase/n + offer_gasbase` gas, where `n` is the number of failed offers. The gas price is estimated by `gasprice`.
   * To create the offer, the maker had to provision for `gasreq + overhead_gasbase/n + offer_gasbase` gas at a price of `offer.gasprice`.
   * We do not consider the tx.gasprice.
   * `offerDetail.gasbase` and `offer.gasprice` are the values of the Mangrove parameters `config.*_gasbase` and `config.gasprice` when the offer was created. Without caching those values, the provision set aside could end up insufficient to reimburse the maker (or to retribute the taker).
   */
  function applyPenalty(
    MC.SingleOrder memory sor,
    uint gasused,
    uint failCount
  ) internal returns (uint) {
    uint provision =
      10**9 *
        uint(uint((sor.offer << 240)) >> 240) *
        (uint(uint((sor.offerDetail << 160)) >> 232) +
          uint(uint((sor.offerDetail << 184)) >> 232) +
          uint(uint((sor.offerDetail << 208)) >> 232));

    /* We set `gasused = min(gasused,gasreq)` since `gasreq < gasused` is possible e.g. with `gasreq = 0` (all calls consume nonzero gas). */
    if (uint(uint((sor.offerDetail << 160)) >> 232) < gasused) {
      gasused = uint(uint((sor.offerDetail << 160)) >> 232);
    }

    /* As an invariant, `applyPenalty` is only called when `executed && !success`, and thus when `failCount > 0`. */
    uint penalty =
      10**9 *
        uint(uint((sor.global << 176)) >> 240) *
        (gasused +
          uint(uint((sor.local << 56)) >> 232) /
          failCount +
          uint(uint((sor.local << 80)) >> 232));

    if (penalty > provision) {
      penalty = provision;
    }

    /* Here we write to storage the new maker balance. This occurs _after_ possible reentrant calls. How do we know we're not crediting twice the same amounts? Because the `offer`'s provision was set to 0 in storage (through `dirtyDeleteOffer`) before the reentrant calls. In this function, we are working with cached copies of the offer as it was before it was consumed. */
    creditWei(address(uint((sor.offerDetail << 0)) >> 96), provision - penalty);

    return penalty;
  }

  function sendPenalty(uint amount) internal {
    if (amount > 0) {
      bool noRevert;
      (noRevert, ) = msg.sender.call{gas: 0, value: amount}("");
    }
  }

  /* # Get/set configuration and Mangrove state */

  function config(address base, address quote)
    public
    returns (bytes32 _global, bytes32 _local)
  {
    _global = global;
    _local = locals[base][quote];
    if (uint(uint((_global << 160)) >> 248) > 0) {
      (uint gasprice, uint density) =
        IMgvMonitor(address(uint((_global << 0)) >> 96)).read(base, quote);
      _global = (_global & bytes32(0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff) | bytes32((uint(gasprice) << 240) >> 176));
      _local = (_local & bytes32(0xffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(density) << 224) >> 24));
    }
  }

  /* ## Locals */
  /* ### `active` */
  function activate(
    address base,
    address quote,
    uint fee,
    uint density,
    uint overhead_gasbase,
    uint offer_gasbase
  ) public {
    authOnly();
    locals[base][quote] = (locals[base][quote] & bytes32(0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(1) << 248) >> 0));
    setFee(base, quote, fee);
    setDensity(base, quote, density);
    setGasbase(base, quote, overhead_gasbase, offer_gasbase);
    emit MgvEvents.SetActive(base, quote, true);
  }

  function deactivate(address base, address quote) public {
    authOnly();
    locals[base][quote] = (locals[base][quote] & bytes32(0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(0) << 248) >> 0));
    emit MgvEvents.SetActive(base, quote, false);
  }

  /* ### `fee` */
  function setFee(
    address base,
    address quote,
    uint value
  ) public {
    authOnly();
    /* `fee` is in basis points, i.e. in percents of a percent. */
    require(value <= 500, "mgv/config/fee/<=500"); // at most 5%
    locals[base][quote] = (locals[base][quote] & bytes32(0xff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(value) << 240) >> 8));
    emit MgvEvents.SetFee(base, quote, value);
  }

  /* ### `density` */
  /* Useless if `global.useOracle != 0` */
  function setDensity(
    address base,
    address quote,
    uint value
  ) public {
    authOnly();
    /* Checking the size of `density` is necessary to prevent overflow when `density` is used in calculations. */
    require(uint32(value) == value, "mgv/config/density/32bits");
    //+clear+
    locals[base][quote] = (locals[base][quote] & bytes32(0xffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(value) << 224) >> 24));
    emit MgvEvents.SetDensity(base, quote, value);
  }

  /* ### `gasbase` */
  function setGasbase(
    address base,
    address quote,
    uint overhead_gasbase,
    uint offer_gasbase
  ) public {
    authOnly();
    /* Checking the size of `*_gasbase` is necessary to prevent a) data loss when `*_gasbase` is copied to an `OfferDetail` struct, and b) overflow when `*_gasbase` is used in calculations. */
    require(
      uint24(overhead_gasbase) == overhead_gasbase,
      "mgv/config/overhead_gasbase/24bits"
    );
    require(
      uint24(offer_gasbase) == offer_gasbase,
      "mgv/config/offer_gasbase/24bits"
    );
    //+clear+
    locals[base][quote] = ((locals[base][quote] & bytes32(0xffffffffffffffffffff000000ffffffffffffffffffffffffffffffffffffff) | bytes32((uint(offer_gasbase) << 232) >> 80)) & bytes32(0xffffffffffffff000000ffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(overhead_gasbase) << 232) >> 56));
    emit MgvEvents.SetGasbase(overhead_gasbase, offer_gasbase);
  }

  /* ## Globals */
  /* ### `kill` */
  function kill() public {
    authOnly();
    global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffff) | bytes32((uint(1) << 248) >> 216));
    emit MgvEvents.Kill();
  }

  /* ### `gasprice` */
  /* Useless if `global.useOracle is != 0` */
  function setGasprice(uint value) public {
    authOnly();
    /* Checking the size of `gasprice` is necessary to prevent a) data loss when `gasprice` is copied to an `OfferDetail` struct, and b) overflow when `gasprice` is used in calculations. */
    require(uint16(value) == value, "mgv/config/gasprice/16bits");
    //+clear+

    global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff) | bytes32((uint(value) << 240) >> 176));
    emit MgvEvents.SetGasprice(value);
  }

  /* ### `gasmax` */
  function setGasmax(uint value) public {
    authOnly();
    /* Since any new `gasreq` is bounded above by `config.gasmax`, this check implies that all offers' `gasreq` is 24 bits wide at most. */
    require(uint24(value) == value, "mgv/config/gasmax/24bits");
    //+clear+
    global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff) | bytes32((uint(value) << 232) >> 192));
    emit MgvEvents.SetGasmax(value);
  }

  function setGovernance(address value) public {
    authOnly();
    governance = value;
    emit MgvEvents.SetGovernance(value);
  }

  function setVault(address value) public {
    authOnly();
    vault = value;
    emit MgvEvents.SetVault(value);
  }

  function setMonitor(address value) public {
    authOnly();
    global = (global & bytes32(0x0000000000000000000000000000000000000000ffffffffffffffffffffffff) | bytes32((uint(value) << 96) >> 0));
    emit MgvEvents.SetMonitor(value);
  }

  function authOnly() internal view {
    require(
      msg.sender == governance || msg.sender == address(this),
      "mgv/unauthorized"
    );
  }

  function setUseOracle(bool value) public {
    authOnly();
    if (value) {
      global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff) | bytes32((uint(1) << 248) >> 160));
    } else {
      global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff) | bytes32((uint(0) << 248) >> 160));
    }
    emit MgvEvents.SetUseOracle(value);
  }

  function setNotify(bool value) public {
    authOnly();
    if (value) {
      global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff) | bytes32((uint(1) << 248) >> 168));
    } else {
      global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff) | bytes32((uint(0) << 248) >> 168));
    }
    emit MgvEvents.SetNotify(value);
  }

  /* # Maker debit/credit utility functions */

  function debitWei(address maker, uint amount) internal {
    uint makerBalance = balanceOf[maker];
    require(makerBalance >= amount, "mgv/insufficientProvision");
    balanceOf[maker] = makerBalance - amount;
    emit MgvEvents.Debit(maker, amount);
  }

  function creditWei(address maker, uint amount) internal {
    balanceOf[maker] += amount;
    emit MgvEvents.Credit(maker, amount);
  }

  /* # Delegation public functions */

  /* Adapted from [Uniswap v2 contract](https://github.com/Uniswap/uniswap-v2-core/blob/55ae25109b7918565867e5c39f1e84b7edd19b2a/contracts/UniswapV2ERC20.sol#L81) */
  function permit(
    address base,
    address quote,
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, "mgv/permit/expired");

    uint nonce = nonces[owner]++;
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(
            abi.encode(
              PERMIT_TYPEHASH,
              base,
              quote,
              owner,
              spender,
              value,
              nonce,
              deadline
            )
          )
        )
      );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(
      recoveredAddress != address(0) && recoveredAddress == owner,
      "mgv/permit/invalidSignature"
    );

    allowances[base][quote][owner][spender] = value;
    emit MgvEvents.Approval(base, quote, owner, spender, value);
  }

  function approve(
    address base,
    address quote,
    address spender,
    uint value
  ) external returns (bool) {
    allowances[base][quote][msg.sender][spender] = value;
    emit MgvEvents.Approval(base, quote, msg.sender, spender, value);
    return true;
  }

  /* # Misc. low-level functions */

  /* Connect the predecessor and sucessor of `id` through their `next`/`prev` pointers. For more on the book structure, see `MangroveCommon.sol`. This step is not necessary during a market order, so we only call `dirtyDeleteOffer`.

  **Warning**: calling with `worseId = 0` will set `betterId` as the best. So with `worseId = 0` and `betterId = 0`, it sets the book to empty and loses track of existing offers.

  **Warning**: may make memory copy of `local.best` stale. Returns new `local`. */
  function stitchOffers(
    address base,
    address quote,
    uint worseId,
    uint betterId,
    bytes32 local
  ) internal returns (bytes32) {
    if (worseId != 0) {
      offers[base][quote][worseId] = (offers[base][quote][worseId] & bytes32(0xffffff000000ffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(betterId) << 232) >> 24));
    } else {
      local = (local & bytes32(0xffffffffffffffffffffffffffff000000ffffffffffffffffffffffffffffff) | bytes32((uint(betterId) << 232) >> 112));
    }

    if (betterId != 0) {
      offers[base][quote][betterId] = (offers[base][quote][betterId] & bytes32(0x000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(worseId) << 232) >> 0));
    }

    return local;
  }

  /* Used by `*For` functions, its both checks that `msg.sender` was allowed to use the taker's funds, and decreases the former's allowance. */
  function deductSenderAllowance(
    address base,
    address quote,
    address owner,
    uint amount
  ) internal {
    uint allowed = allowances[base][quote][owner][msg.sender];
    require(allowed > amount, "mgv/lowAllowance");
    allowances[base][quote][owner][msg.sender] = allowed - amount;
  }

  /* # Flashloans */
  //+clear+
  /* ## Flashloan */
  /*
     `flashloan` is for the 'normal' mode of operation. It:
     1. Flashloans `takerGives` `quote` from the taker to the maker and returns false if the loan fails.
     2. Runs `offerDetail.maker`'s `execute` function.
     3. Returns the result of the operations, with optional makerData to help the maker debug.
   */
  function flashloan(MC.SingleOrder calldata sor, address taker)
    external
    returns (uint gasused)
  {
    /* `flashloan` must be used with a call (hence the `external` modifier) so its effect can be reverted. But a call from the outside would be fatal. */
    require(msg.sender == address(this), "mgv/flashloan/protected");
    /* The transfer taker -> maker is in 2 steps. First, taker->mgv. Then
       mgv->maker. With a direct taker->maker transfer, if one of taker/maker
       is blacklisted, we can't tell which one. We need to know which one:
       if we incorrectly blame the taker, a blacklisted maker can block a pair forever; if we incorrectly blame the maker, a blacklisted taker can unfairly make makers fail all the time. Of course we assume the Mangrove is not blacklisted. Also note that this setup doesn not work well with tokens that take fees or recompute balances at transfer time. */
    if (transferTokenFrom(sor.quote, taker, address(this), sor.gives)) {
      if (
        transferToken(
          sor.quote,
          address(uint((sor.offerDetail << 0)) >> 96),
          sor.gives
        )
      ) {
        gasused = makerExecute(sor);
      } else {
        innerRevert([bytes32("mgv/makerReceiveFail"), bytes32(0), ""]);
      }
    } else {
      innerRevert([bytes32("mgv/takerFailToPayMaker"), "", ""]);
    }
  }

  /* ## Inverted Flashloan */
  /*
     `invertedFlashloan` is for the 'arbitrage' mode of operation. It:
     0. Calls the maker's `execute` function. If successful (tokens have been sent to taker):
     2. Runs `taker`'s `execute` function.
     4. Returns the results ofthe operations, with optional makerData to help the maker debug.

     There are two ways to do the flashloan:
     1. balanceOf before/after
     2. run transferFrom ourselves.

     ### balanceOf pros:
       * maker may `transferFrom` another address they control; saves gas compared to Mangrove's `transferFrom`
       * maker does not need to `approve` Mangrove

     ### balanceOf cons
       * if the ERC20 transfer method has a callback to receiver, the method does not work (the receiver can set its balance to 0 during the callback)
       * if the taker is malicious, they can analyze the maker code. If the maker goes on any Mangrove2, they may execute code provided by the taker. This would reduce the taker balance and make the maker fail. So the taker could steal the maker's balance.

    We choose `transferFrom`.
    */

  function invertedFlashloan(MC.SingleOrder calldata sor, address)
    external
    returns (uint gasused)
  {
    /* `invertedFlashloan` must be used with a call (hence the `external` modifier) so its effect can be reverted. But a call from the outside would be fatal. */
    require(msg.sender == address(this), "mgv/invertedFlashloan/protected");
    gasused = makerExecute(sor);
  }

  /* ## Maker Execute */

  function makerExecute(MC.SingleOrder calldata sor)
    internal
    returns (uint gasused)
  {
    bytes memory cd = abi.encodeWithSelector(IMaker.makerTrade.selector, sor);

    /* Calls an external function with controlled gas expense. A direct call of the form `(,bytes memory retdata) = maker.call{gas}(selector,...args)` enables a griefing attack: the maker uses half its gas to write in its memory, then reverts with that memory segment as argument. After a low-level call, solidity automaticaly copies `returndatasize` bytes of `returndata` into memory. So the total gas consumed to execute a failing offer could exceed `gasreq + overhead_gasbase/n + offer_gasbase` where `n` is the number of failing offers. This yul call only retrieves the first byte of the maker's `returndata`. */
    uint gasreq = uint(uint((sor.offerDetail << 160)) >> 232);
    address maker = address(uint((sor.offerDetail << 0)) >> 96);
    bytes memory retdata = new bytes(32);
    bool callSuccess;
    bytes32 makerData;
    uint oldGas = gasleft();
    /* We let the maker pay for the overhead of checking remaining gas and making the call. So the `require` below is just an approximation: if the overhead of (`require` + cost of `CALL`) is $h$, the maker will receive at worst $\textrm{gasreq} - \frac{63h}{64}$ gas. */
    /* Note : as a possible future feature, we could stop an order when there's not enough gas left to continue processing offers. This could be done safely by checking, as soon as we start processing an offer, whether `63/64(gasleft-overhead_gasbase-offer_gasbase) > gasreq`. If no, we'd know by induction that there is enough gas left to apply fees, stitch offers, etc (or could revert safely if no offer has been taken yet). */
    if (!(oldGas - oldGas / 64 >= gasreq)) {
      innerRevert([bytes32("mgv/notEnoughGasForMakerTrade"), "", ""]);
    }

    assembly {
      callSuccess := call(
        gasreq,
        maker,
        0,
        add(cd, 32),
        mload(cd),
        add(retdata, 32),
        32
      )
      makerData := mload(add(retdata, 32))
    }
    gasused = oldGas - gasleft();

    if (!callSuccess) {
      innerRevert([bytes32("mgv/makerRevert"), bytes32(gasused), makerData]);
    }

    bool transferSuccess =
      transferTokenFrom(sor.base, maker, address(this), sor.wants);

    if (!transferSuccess) {
      innerRevert(
        [bytes32("mgv/makerTransferFail"), bytes32(gasused), makerData]
      );
    }
  }

  /* ## Misc. functions */

  /* Regular solidity reverts prepend the string argument with a [function signature](https://docs.soliditylang.org/en/v0.7.6/control-structures.html#revert). Since we wish transfer data through a revert, the `innerRevert` function does a low-level revert with only the required data. `innerCode` decodes this data. */
  function innerDecode(bytes memory data)
    internal
    pure
    returns (
      bytes32 errorCode,
      uint gasused,
      bytes32 makerData
    )
  {
    /* The `data` pointer is of the form `[3,errorCode,gasused,makerData]` where each array element is contiguous and has size 256 bits. 3 is added by solidity as the length of the rest of the data. */
    assembly {
      errorCode := mload(add(data, 32))
      gasused := mload(add(data, 64))
      makerData := mload(add(data, 96))
    }
  }

  function innerRevert(bytes32[3] memory data) internal pure {
    assembly {
      revert(data, 96)
    }
  }

  /* `transferTokenFrom` is adapted from [existing code](https://soliditydeveloper.com/safe-erc20) and in particular avoids the
  "no return value" bug. It never throws and returns true iff the transfer was successful according to `tokenAddress`.

    Note that any spurious exception due to an error in Mangrove code will be falsely blamed on `from`.
  */
  function transferTokenFrom(
    address tokenAddress,
    address from,
    address to,
    uint value
  ) internal returns (bool) {
    bytes memory cd =
      abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value);
    (bool noRevert, bytes memory data) = tokenAddress.call(cd);
    return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
  }

  function transferToken(
    address tokenAddress,
    address to,
    uint value
  ) internal returns (bool) {
    bytes memory cd =
      abi.encodeWithSelector(IERC20.transfer.selector, to, value);
    (bool noRevert, bytes memory data) = tokenAddress.call(cd);
    return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
  }

  /* # Abstract functions */

  function executeEnd(MultiOrder memory mor, MC.SingleOrder memory sor)
    internal
    virtual;

  function executeCallback(MC.SingleOrder memory sor) internal virtual;
}

/* # FMD and FTD instanciations of Mangrove */

contract MMgv is Mangrove {
  constructor(uint gasprice, uint gasmax)
    Mangrove(gasprice, gasmax, true, "FMD")
  {}

  function executeEnd(MultiOrder memory mor, MC.SingleOrder memory sor)
    internal
    override
  {}

  function executeCallback(MC.SingleOrder memory sor) internal override {}
}

contract TMgv is Mangrove {
  constructor(uint gasprice, uint gasmax)
    Mangrove(gasprice, gasmax, false, "FTD")
  {}

  // execute taker trade
  function executeEnd(MultiOrder memory mor, MC.SingleOrder memory sor)
    internal
    override
  {
    ITaker(mor.taker).takerTrade(
      sor.base,
      sor.quote,
      mor.totalGot,
      mor.totalGave
    );
    bool success =
      transferTokenFrom(sor.quote, mor.taker, address(this), mor.totalGave);
    require(success, "mgv/takerFailToPayMaker");
  }

  /* We use `transferFrom` with takers (instead of checking `balanceOf` before/after the call) for the following reason we want the taker to be awaken after all loans have been made, so either
     1. The taker gets a list of all makers and loops through them to pay back, or
     2. we call a new taker method "payback" after returning from each maker call, or
     3. we call transferFrom after returning from each maker call

So :
   1. Would mean accumulating a list of all makers, which would make the market order code too complex
   2. Is OK, but has an extra CALL cost on top of the token transfer, one for each maker. This is unavoidable anyway when calling makerTrade (since the maker must be able to execute arbitrary code at that moment), but we can skip it here.
   3. Is the cheapest, but it has the drawbacks of `transferFrom`: money must end up owned by the taker, and taker needs to `approve` Mangrove
   */
  function executeCallback(MC.SingleOrder memory sor) internal override {
    /* If `transferToken` returns false here, we're in a special (and bad) situation. The taker is returning part of their total loan to a maker, but the maker can't receive the tokens. Only case we can see: maker is blacklisted. We could punish maker. We don't. We could send money back to taker. We don't. */
    transferToken(
      sor.quote,
      address(uint((sor.offerDetail << 0)) >> 96),
      sor.gives
    );
  }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: UNLICENSED




/* # Structs
The structs defined in `structs.js` have their counterpart as solidity structs that are easy to manipulate for outside contracts / callers of view functions. */
library MgvCommon {
  struct Offer {
    uint prev;
    uint next;
    uint gives;
    uint wants;
    uint gasprice;
  }

  struct OfferDetail {
    address maker;
    uint gasreq;
    uint overhead_gasbase;
    uint offer_gasbase;
  }
  struct Global {
    address monitor;
    bool useOracle;
    bool notify;
    uint gasprice;
    uint gasmax;
    bool dead;
  }

  struct Local {
    bool active;
    uint fee;
    uint density;
    uint overhead_gasbase;
    uint offer_gasbase;
    bool lock;
    uint best;
    uint last;
  }

  struct Config {
    Global global;
    Local local;
  }

  /*
   Some miscellaneous data types useful to `Mangrove` and external contracts */
  //+clear+

  /* `SingleOrder` holds data about an order-offer match in a struct. Used by `marketOrder` and `internalSnipes` (and some of their nested functions) to avoid stack too deep errors. */
  struct SingleOrder {
    address base;
    address quote;
    uint offerId;
    bytes32 offer;
    /* `wants`/`gives` mutate over execution. Initially the `wants`/`gives` from the taker's pov, then actual `wants`/`gives` adjusted by offer's price and volume. */
    uint wants;
    uint gives;
    /* `offerDetail` is only populated when necessary. */
    bytes32 offerDetail;
    bytes32 global;
    bytes32 local;
  }

  struct OrderResult {
    bool success;
    bytes32 makerData;
    bytes32 errorCode;
  }
}

/* # Events
The events emitted for use by bots are listed here: */
library MgvEvents {
  /* * Emitted at the creation of the new Mangrove contract on the pair (`quote`, `base`)*/
  event NewMgv();

  /* * Mangrove adds or removes wei from `maker`'s account */
  /* *Credit event occurs when an offer is removed from the Mangrove or when the `fund` function is called*/
  event Credit(address maker, uint amount);
  /* *Debit event occurs when an offer is posted or when the `withdraw` function is called*/
  event Debit(address maker, uint amount);

  /* * Mangrove reconfiguration */
  event SetActive(address base, address quote, bool value);
  event SetFee(address base, address quote, uint value);
  event SetGasbase(uint overhead_gasbase, uint offer_gasbase);
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetVault(address value);
  event SetUseOracle(bool value);
  event SetNotify(bool value);
  event SetGasmax(uint value);
  event SetDensity(address base, address quote, uint value);
  event SetGasprice(uint value);

  /* * Offer execution */
  event Success(
    address base,
    address quote,
    uint offerId,
    // maker's address is not logged because it can be retrieved from `WriteOffer` event using `offerId`, packed in `data`.
    address taker,
    uint takerWants,
    uint takerGives
  );
  event MakerFail(
    address base,
    address quote,
    uint offerId,
    // maker's address is not logged because it can be retrieved from `WriteOffer` event using `offerId`, packed in `data`.
    address taker,
    uint takerWants,
    uint takerGives,
    bytes32 errorCode,
    bytes32 makerData
  );

  /* * After `permit` and `approve` */
  event Approval(
    address base,
    address quote,
    address owner,
    address spender,
    uint value
  );

  /* * Mangrove closure */
  event Kill();

  /* * An offer was created or updated. `data` packs `makerWants`(96), `makerGives`(96), `gasprice`(16), `gasreq`(24), `offerId`(24)*/
  event WriteOffer(address base, address quote, address maker, bytes32 data);

  /* * `offerId` was present and is now removed from the book. */
  event RetractOffer(address base, address quote, uint offerId);
}

/* # IMaker interface */
interface IMaker {
  /* Called upon offer execution. If this function reverts, Mangrove will not try to transfer funds. Returned data (truncated to 32 bytes) can be accessed during the call to `makerPosthook` in the `result.errorCode` field.
  Reverting with a message (for further processing during posthook) should be done using low level `revertTrade(bytes32)` provided in the `MgvIt` library. It is not possible to reenter the order book of the traded pair whilst this function is executed.*/
  function makerTrade(MgvCommon.SingleOrder calldata order)
    external
    returns (bytes32);

  /* Called after all offers of an order have been executed. Posthook of the last executed order is called first and full reentrancy into the Mangrove is enabled at this time. `order` recalls key arguments of the order that was processed and `result` recalls important information for updating the current offer.*/
  function makerPosthook(
    MgvCommon.SingleOrder calldata order,
    MgvCommon.OrderResult calldata result
  ) external;
}

/* # ITaker interface */
interface ITaker {
  /* FTD only: call to taker after loans went through */
  function takerTrade(
    address base,
    address quote,
    // total amount of base token that was flashloaned to the taker
    uint totalGot,
    // total amount of quote token that should be made available
    uint totalGives
  ) external;
}

/* # Monitor interface
If enabled, the monitor receives notification after each offer execution and is read for each pair's `gasprice` and `density`. */
interface IMgvMonitor {
  function notifySuccess(MgvCommon.SingleOrder calldata sor, address taker)
    external;

  function notifyFail(MgvCommon.SingleOrder calldata sor, address taker)
    external;

  function read(address base, address quote)
    external
    returns (uint gasprice, uint density);
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: UNLICENSED



import {MgvCommon as MC} from "./MgvCommon.sol";

// IERC20 From OpenZeppelin code

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}