// SPDX-License-Identifier:	AGPL-3.0

// AbstractMangrove.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML} from "./MgvLib.sol";

import {MgvOfferMaking} from "./MgvOfferMaking.sol";
import {MgvOfferTakingWithPermit} from "./MgvOfferTakingWithPermit.sol";
import {MgvGovernable} from "./MgvGovernable.sol";

/* `AbstractMangrove` inherits the three contracts that implement generic Mangrove functionality (`MgvGovernable`,`MgvOfferTakingWithPermit` and `MgvOfferMaking`) but does not implement the abstract functions. */
abstract contract AbstractMangrove is
  MgvGovernable,
  MgvOfferTakingWithPermit,
  MgvOfferMaking
{
  constructor(
    address governance,
    uint gasprice,
    uint gasmax,
    string memory contractName
  )
    MgvOfferTakingWithPermit(contractName)
    MgvGovernable(governance, gasprice, gasmax)
  {}
}

// SPDX-License-Identifier: Unlicense

// MgvLib.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./IERC20.sol";
import "./MgvPack.sol" as P;

/* # Structs
The structs defined in `structs.js` have their counterpart as solidity structs that are easy to manipulate for outside contracts / callers of view functions. */

library MgvLib {
  /*
   Some miscellaneous data types useful to `Mangrove` and external contracts */
  //+clear+

  /* `SingleOrder` holds data about an order-offer match in a struct. Used by `marketOrder` and `internalSnipes` (and some of their nested functions) to avoid stack too deep errors. */
  struct SingleOrder {
    address outbound_tkn;
    address inbound_tkn;
    uint offerId;
    P.Offer.t offer;
    /* `wants`/`gives` mutate over execution. Initially the `wants`/`gives` from the taker's pov, then actual `wants`/`gives` adjusted by offer's price and volume. */
    uint wants;
    uint gives;
    /* `offerDetail` is only populated when necessary. */
    P.OfferDetail.t offerDetail;
    P.Global.t global;
    P.Local.t local;
  }

  /* <a id="MgvLib/OrderResult"></a> `OrderResult` holds additional data for the maker and is given to them _after_ they fulfilled an offer. It gives them their own returned data from the previous call, and an `mgvData` specifying whether the Mangrove encountered an error. */

  struct OrderResult {
    /* `makerdata` holds a message that was either returned by the maker or passed as revert message at the end of the trade execution*/
    bytes32 makerData;
    /* `mgvData` is an [internal Mangrove status](#MgvOfferTaking/statusCodes) code. */
    bytes32 mgvData;
  }
}

/* # Events
The events emitted for use by bots are listed here: */
contract HasMgvEvents {
  /* * Emitted at the creation of the new Mangrove contract on the pair (`inbound_tkn`, `outbound_tkn`)*/
  event NewMgv();

  /* Mangrove adds or removes wei from `maker`'s account */
  /* * Credit event occurs when an offer is removed from the Mangrove or when the `fund` function is called*/
  event Credit(address indexed maker, uint amount);
  /* * Debit event occurs when an offer is posted or when the `withdraw` function is called */
  event Debit(address indexed maker, uint amount);

  /* * Mangrove reconfiguration */
  event SetActive(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    bool value
  );
  event SetFee(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasbase(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offer_gasbase
  );
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetVault(address value);
  event SetUseOracle(bool value);
  event SetNotify(bool value);
  event SetGasmax(uint value);
  event SetDensity(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasprice(uint value);

  /* Market order execution */
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address taker,
    uint takerGot,
    uint takerGave
  );

  /* * Offer execution */
  event OfferSuccess(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives
  );

  /* Log information when a trade execution reverts or returns a non empty bytes32 word */
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives,
    // `mgvData` may only be `"mgv/makerRevert"`, `"mgv/makerAbort"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"`
    bytes32 mgvData
  );

  /* Log information when a posthook reverts */
  event PosthookFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId
  );

  /* * After `permit` and `approve` */
  event Approval(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address owner,
    address spender,
    uint value
  );

  /* * Mangrove closure */
  event Kill();

  /* * An offer was created or updated.
  A few words about why we include a `prev` field, and why we don't include a
  `next` field: in theory clients should need neither `prev` nor a `next` field.
  They could just 1. Read the order book state at a given block `b`.  2. On
  every event, update a local copy of the orderbook.  But in practice, we do not
  want to force clients to keep a copy of the *entire* orderbook. There may be a
  long tail of spam. Now if they only start with the first $N$ offers and
  receive a new offer that goes to the end of the book, they cannot tell if
  there are missing offers between the new offer and the end of the local copy
  of the book.
  
  So we add a prev pointer so clients with only a prefix of the book can receive
  out-of-prefix offers and know what to do with them. The `next` pointer is an
  optimization useful in Solidity (we traverse fewer memory locations) but
  useless in client code.
  */
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );

  /* * `offerId` was present and is now removed from the book. */
  event OfferRetract(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id
  );
}

/* # IMaker interface */
interface IMaker {
  /* Called upon offer execution. If the call returns normally with the first 32 bytes are 0, Mangrove will try to transfer funds; otherwise not. Returned data (truncated to leftmost 32 bytes) can be accessed during the call to `makerPosthook` in the `result.mgvData` field. To revert with a 32 bytes value, use something like:
     ```
     function tradeRevert(bytes32 data) internal pure {
       bytes memory revData = new bytes(32);
         assembly {
           mstore(add(revData, 32), data)
           revert(add(revData, 32), 32)
         }
     }
     ```
     */
  function makerExecute(MgvLib.SingleOrder calldata order)
    external
    returns (bytes32);

  /* Called after all offers of an order have been executed. Posthook of the last executed order is called first and full reentrancy into the Mangrove is enabled at this time. `order` recalls key arguments of the order that was processed and `result` recalls important information for updating the current offer. (see [above](#MgvLib/OrderResult))*/
  function makerPosthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata result
  ) external;
}

/* # ITaker interface */
interface ITaker {
  /* Inverted mangrove only: call to taker after loans went through */
  function takerTrade(
    address outbound_tkn,
    address inbound_tkn,
    // total amount of outbound_tkn token that was flashloaned to the taker
    uint totalGot,
    // total amount of inbound_tkn token that should be made available
    uint totalGives
  ) external;
}

/* # Monitor interface
If enabled, the monitor receives notification after each offer execution and is read for each pair's `gasprice` and `density`. */
interface IMgvMonitor {
  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker)
    external;

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external;

  function read(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint gasprice, uint density);
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOfferMaking.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {IMaker, HasMgvEvents, P} from "./MgvLib.sol";
import {MgvHasOffers} from "./MgvHasOffers.sol";

/* `MgvOfferMaking` contains market-making-related functions. */
contract MgvOfferMaking is MgvHasOffers {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  /* # Public Maker operations
     ## New Offer */
  //+clear+
  /* In the Mangrove, makers and takers call separate functions. Market makers call `newOffer` to fill the book, and takers call functions such as `marketOrder` to consume it.  */

  //+clear+

  /* The following structs holds offer creation/update parameters in memory. This frees up stack space for local variables. */
  struct OfferPack {
    address outbound_tkn;
    address inbound_tkn;
    uint wants;
    uint gives;
    uint id;
    uint gasreq;
    uint gasprice;
    uint pivotId;
    P.Global.t global;
    P.Local.t local;
    // used on update only
    P.Offer.t oldOffer;
  }

  /* The function `newOffer` is for market makers only; no match with the existing book is done. A maker specifies how much `inbound_tkn` it `wants` and how much `outbound_tkn` it `gives`.

     It also specify with `gasreq` how much gas should be given when executing their offer.

     `gasprice` indicates an upper bound on the gasprice at which the maker is ready to be penalised if their offer fails. Any value below the Mangrove's internal `gasprice` configuration value will be ignored.

    `gasreq`, together with `gasprice`, will contribute to determining the penalty provision set aside by the Mangrove from the market maker's `balanceOf` balance.

  Offers are always inserted at the correct place in the book. This requires walking through offers to find the correct insertion point. As in [Oasis](https://github.com/daifoundation/maker-otc/blob/f2060c5fe12fe3da71ac98e8f6acc06bca3698f5/src/matching_market.sol#L493), the maker should find the id of an offer close to its own and provide it as `pivotId`.

  An offer cannot be inserted in a closed market, nor when a reentrancy lock for `outbound_tkn`,`inbound_tkn` is on.

  No more than $2^{24}-1$ offers can ever be created for one `outbound_tkn`,`inbound_tkn` pair.

  The actual contents of the function is in `writeOffer`, which is called by both `newOffer` and `updateOffer`.
  */
  function newOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId
  ) external returns (uint) { unchecked {
    /* In preparation for calling `writeOffer`, we read the `outbound_tkn`,`inbound_tkn` pair configuration, check for reentrancy and market liveness, fill the `OfferPack` struct and increment the `outbound_tkn`,`inbound_tkn` pair's `last`. */
    OfferPack memory ofp;
    (ofp.global, ofp.local) = config(outbound_tkn, inbound_tkn);
    unlockedMarketOnly(ofp.local);
    activeMarketOnly(ofp.global, ofp.local);

    ofp.id = 1 + ofp.local.last();
    require(uint32(ofp.id) == ofp.id, "mgv/offerIdOverflow");

    ofp.local = ofp.local.last(ofp.id);

    ofp.outbound_tkn = outbound_tkn;
    ofp.inbound_tkn = inbound_tkn;
    ofp.wants = wants;
    ofp.gives = gives;
    ofp.gasreq = gasreq;
    ofp.gasprice = gasprice;
    ofp.pivotId = pivotId;

    /* The second parameter to writeOffer indicates that we are creating a new offer, not updating an existing one. */
    writeOffer(ofp, false);

    /* Since we locally modified a field of the local configuration (`last`), we save the change to storage. Note that `writeOffer` may have further modified the local configuration by updating the current `best` offer. */
    locals[ofp.outbound_tkn][ofp.inbound_tkn] = ofp.local;
    return ofp.id;
  }}

  /* ## Update Offer */
  //+clear+
  /* Very similar to `newOffer`, `updateOffer` prepares an `OfferPack` for `writeOffer`. Makers should use it for updating live offers, but also to save on gas by reusing old, already consumed offers.

     A `pivotId` should still be given to minimise reads in the offer book. It is OK to give the offers' own id as a pivot.


     Gas use is minimal when:
     1. The offer does not move in the book
     2. The offer does not change its `gasreq`
     3. The (`outbound_tkn`,`inbound_tkn`)'s `offer_gasbase` has not changed since the offer was last written
     4. `gasprice` has not changed since the offer was last written
     5. `gasprice` is greater than the Mangrove's gasprice estimation
  */
  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external { unchecked {
    OfferPack memory ofp;
    (ofp.global, ofp.local) = config(outbound_tkn, inbound_tkn);
    unlockedMarketOnly(ofp.local);
    activeMarketOnly(ofp.global, ofp.local);
    ofp.outbound_tkn = outbound_tkn;
    ofp.inbound_tkn = inbound_tkn;
    ofp.wants = wants;
    ofp.gives = gives;
    ofp.id = offerId;
    ofp.gasreq = gasreq;
    ofp.gasprice = gasprice;
    ofp.pivotId = pivotId;
    ofp.oldOffer = offers[outbound_tkn][inbound_tkn][offerId];
    // Save local config
    P.Local.t oldLocal = ofp.local;
    /* The second argument indicates that we are updating an existing offer, not creating a new one. */
    writeOffer(ofp, true);
    /* We saved the current pair's configuration before calling `writeOffer`, since that function may update the current `best` offer. We now check for any change to the configuration and update it if needed. */
    if (!oldLocal.eq(ofp.local)) {
      locals[ofp.outbound_tkn][ofp.inbound_tkn] = ofp.local;
    }
  }}

  /* ## Retract Offer */
  //+clear+
  /* `retractOffer` takes the offer `offerId` out of the book. However, `deprovision == true` also refunds the provision associated with the offer. */
  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision
  ) external returns (uint provision) { unchecked {
    (, P.Local.t local) = config(outbound_tkn, inbound_tkn);
    unlockedMarketOnly(local);
    P.Offer.t offer = offers[outbound_tkn][inbound_tkn][offerId];
    P.OfferDetail.t offerDetail = offerDetails[outbound_tkn][inbound_tkn][offerId];
    require(
      msg.sender == offerDetail.maker(),
      "mgv/retractOffer/unauthorized"
    );

    /* Here, we are about to un-live an offer, so we start by taking it out of the book by stitching together its previous and next offers. Note that unconditionally calling `stitchOffers` would break the book since it would connect offers that may have since moved. */
    if (isLive(offer)) {
      P.Local.t oldLocal = local;
      local = stitchOffers(
        outbound_tkn,
        inbound_tkn,
        offer.prev(),
        offer.next(),
        local
      );
      /* If calling `stitchOffers` has changed the current `best` offer, we update the storage. */
      if (!oldLocal.eq(local)) {
        locals[outbound_tkn][inbound_tkn] = local;
      }
    }
    /* Set `gives` to 0. Moreover, the last argument depends on whether the user wishes to get their provision back (if true, `gasprice` will be set to 0 as well). */
    dirtyDeleteOffer(
      outbound_tkn,
      inbound_tkn,
      offerId,
      offer,
      offerDetail,
      deprovision
    );

    /* If the user wants to get their provision back, we compute its provision from the offer's `gasprice`, `offer_gasbase` and `gasreq`. */
    if (deprovision) {
      provision =
        10**9 *
        offerDetail.gasprice() * //gasprice is 0 if offer was deprovisioned
        (offerDetail.gasreq() + offerDetail.offer_gasbase());
      // credit `balanceOf` and log transfer
      creditWei(msg.sender, provision);
    }
    emit OfferRetract(outbound_tkn, inbound_tkn, offerId);
  }}

  /* ## Provisioning
  Market makers must have enough provisions for possible penalties. These provisions are in ETH. Every time a new offer is created or an offer is updated, `balanceOf` is adjusted to provision the offer's maximum possible penalty (`gasprice * (gasreq + offer_gasbase)`).

  For instance, if the current `balanceOf` of a maker is 1 ether and they create an offer that requires a provision of 0.01 ethers, their `balanceOf` will be reduced to 0.99 ethers. No ethers will move; this is just an internal accounting movement to make sure the maker cannot `withdraw` the provisioned amounts.

  */
  //+clear+

  /* Fund should be called with a nonzero value (hence the `payable` modifier). The provision will be given to `maker`, not `msg.sender`. */
  function fund(address maker) public payable { unchecked {
    (P.Global.t _global, ) = config(address(0), address(0));
    liveMgvOnly(_global);
    creditWei(maker, msg.value);
  }}

  function fund() external payable { unchecked {
    fund(msg.sender);
  }}

  /* A transfer with enough gas to the Mangrove will increase the caller's available `balanceOf` balance. _You should send enough gas to execute this function when sending money to the Mangrove._  */
  receive() external payable { unchecked {
    fund(msg.sender);
  }}

  /* Any provision not currently held to secure an offer's possible penalty is available for withdrawal. */
  function withdraw(uint amount) external returns (bool noRevert) { unchecked {
    /* Since we only ever send money to the caller, we do not need to provide any particular amount of gas, the caller should manage this herself. */
    debitWei(msg.sender, amount);
    (noRevert, ) = msg.sender.call{value: amount}("");
  }}

  /* # Low-level Maker functions */

  /* ## Write Offer */

  function writeOffer(OfferPack memory ofp, bool update) internal { unchecked {
    /* `gasprice`'s floor is Mangrove's own gasprice estimate, `ofp.global.gasprice`. We first check that gasprice fits in 16 bits. Otherwise it could be that `uint16(gasprice) < global_gasprice < gasprice`, and the actual value we store is `uint16(gasprice)`. */
    require(
      uint16(ofp.gasprice) == ofp.gasprice,
      "mgv/writeOffer/gasprice/16bits"
    );

    if (ofp.gasprice < ofp.global.gasprice()) {
      ofp.gasprice = ofp.global.gasprice();
    }

    /* * Check `gasreq` below limit. Implies `gasreq` at most 24 bits wide, which ensures no overflow in computation of `provision` (see below). */
    require(
      ofp.gasreq <= ofp.global.gasmax(),
      "mgv/writeOffer/gasreq/tooHigh"
    );
    /* * Make sure `gives > 0` -- division by 0 would throw in several places otherwise, and `isLive` relies on it. */
    require(ofp.gives > 0, "mgv/writeOffer/gives/tooLow");
    /* * Make sure that the maker is posting a 'dense enough' offer: the ratio of `outbound_tkn` offered per gas consumed must be high enough. The actual gas cost paid by the taker is overapproximated by adding `offer_gasbase` to `gasreq`. */
    require(
      ofp.gives >=
        (ofp.gasreq + ofp.local.offer_gasbase()) * ofp.local.density(),
      "mgv/writeOffer/density/tooLow"
    );

    /* The following checks are for the maker's convenience only. */
    require(uint96(ofp.gives) == ofp.gives, "mgv/writeOffer/gives/96bits");
    require(uint96(ofp.wants) == ofp.wants, "mgv/writeOffer/wants/96bits");

    /* The position of the new or updated offer is found using `findPosition`. If the offer is the best one, `prev == 0`, and if it's the last in the book, `next == 0`.

       `findPosition` is only ever called here, but exists as a separate function to make the code easier to read.

    **Warning**: `findPosition` will call `better`, which may read the offer's `offerDetails`. So it is important to find the offer position _before_ we update its `offerDetail` in storage. We waste 1 (hot) read in that case but we deem that the code would get too ugly if we passed the old `offerDetail` as argument to `findPosition` and to `better`, just to save 1 hot read in that specific case.  */
    (uint prev, uint next) = findPosition(ofp);

    /* Log the write offer event. */
    emit OfferWrite(
      ofp.outbound_tkn,
      ofp.inbound_tkn,
      msg.sender,
      ofp.wants,
      ofp.gives,
      ofp.gasprice,
      ofp.gasreq,
      ofp.id,
      prev
    );

    /* We now write the new `offerDetails` and remember the previous provision (0 by default, for new offers) to balance out maker's `balanceOf`. */
    uint oldProvision;
    {
      P.OfferDetail.t offerDetail = offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][
        ofp.id
      ];
      if (update) {
        require(
          msg.sender == offerDetail.maker(),
          "mgv/updateOffer/unauthorized"
        );
        oldProvision =
          10**9 *
          offerDetail.gasprice() *
          (offerDetail.gasreq() + offerDetail.offer_gasbase());
      }

      /* If the offer is new, has a new `gasprice`, `gasreq`, or if the Mangrove's `offer_gasbase` configuration parameter has changed, we also update `offerDetails`. */
      if (
        !update ||
        offerDetail.gasreq() != ofp.gasreq ||
        offerDetail.gasprice() != ofp.gasprice ||
        offerDetail.offer_gasbase() !=
        ofp.local.offer_gasbase()
      ) {
        uint offer_gasbase = ofp.local.offer_gasbase();
        offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][ofp.id] = 
        P.OfferDetail.pack({
          __maker: msg.sender,
          __gasreq: ofp.gasreq,
          __offer_gasbase: offer_gasbase,
          __gasprice: ofp.gasprice
        });
      }
    }

    /* With every change to an offer, a maker may deduct provisions from its `balanceOf` balance. It may also get provisions back if the updated offer requires fewer provisions than before. */
    {
      uint provision = (ofp.gasreq +
        ofp.local.offer_gasbase()) *
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
    if (!isLive(ofp.oldOffer) || prev != ofp.oldOffer.prev()) {
      /* * If the offer is not the best one, we update its predecessor; otherwise we update the `best` value. */
      if (prev != 0) {
        offers[ofp.outbound_tkn][ofp.inbound_tkn][prev] = offers[ofp.outbound_tkn][ofp.inbound_tkn][prev].next(ofp.id);
      } else {
        ofp.local = ofp.local.best(ofp.id);
      }

      /* * If the offer is not the last one, we update its successor. */
      if (next != 0) {
        offers[ofp.outbound_tkn][ofp.inbound_tkn][next] = offers[ofp.outbound_tkn][ofp.inbound_tkn][next].prev(ofp.id);
      }

      /* * Recall that in this branch, the offer has changed location, or is not currently in the book. If the offer is not new and already in the book, we must remove it from its previous location by stitching its previous prev/next. */
      if (update && isLive(ofp.oldOffer)) {
        ofp.local = stitchOffers(
          ofp.outbound_tkn,
          ofp.inbound_tkn,
          ofp.oldOffer.prev(),
          ofp.oldOffer.next(),
          ofp.local
        );
      }
    }

    /* With the `prev`/`next` in hand, we finally store the offer in the `offers` map. */
    P.Offer.t ofr = P.Offer.pack({
      __prev: prev,
      __next: next,
      __wants: ofp.wants,
      __gives: ofp.gives
    });
    offers[ofp.outbound_tkn][ofp.inbound_tkn][ofp.id] = ofr;
  }}

  /* ## Find Position */
  /* `findPosition` takes a price in the form of a (`ofp.wants`,`ofp.gives`) pair, an offer id (`ofp.pivotId`) and walks the book from that offer (backward or forward) until the right position for the price is found. The position is returned as a `(prev,next)` pair, with `prev` or `next` at 0 to mark the beginning/end of the book (no offer ever has id 0).

  If prices are equal, `findPosition` will put the newest offer last. */
  function findPosition(OfferPack memory ofp)
    internal
    view
    returns (uint, uint)
  { unchecked {
    uint prevId;
    uint nextId;
    uint pivotId = ofp.pivotId;
    /* Get `pivot`, optimizing for the case where pivot info is already known */
    P.Offer.t pivot = pivotId == ofp.id
      ? ofp.oldOffer
      : offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotId];

    /* In case pivotId is not an active offer, it is unusable (since it is out of the book). We default to the current best offer. If the book is empty pivot will be 0. That is handled through a test in the `better` comparison function. */
    if (!isLive(pivot)) {
      pivotId = ofp.local.best();
      pivot = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotId];
    }

    /* * Pivot is better than `wants/gives`, we follow `next`. */
    if (better(ofp, pivot, pivotId)) {
      P.Offer.t pivotNext;
      while (pivot.next() != 0) {
        uint pivotNextId = pivot.next();
        pivotNext = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotNextId];
        if (better(ofp, pivotNext, pivotNextId)) {
          pivotId = pivotNextId;
          pivot = pivotNext;
        } else {
          break;
        }
      }
      // gets here on empty book
      (prevId, nextId) = (pivotId, pivot.next());

      /* * Pivot is strictly worse than `wants/gives`, we follow `prev`. */
    } else {
      P.Offer.t pivotPrev;
      while (pivot.prev() != 0) {
        uint pivotPrevId = pivot.prev();
        pivotPrev = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotPrevId];
        if (better(ofp, pivotPrev, pivotPrevId)) {
          break;
        } else {
          pivotId = pivotPrevId;
          pivot = pivotPrev;
        }
      }

      (prevId, nextId) = (pivot.prev(), pivotId);
    }

    return (
      prevId == ofp.id ? ofp.oldOffer.prev() : prevId,
      nextId == ofp.id ? ofp.oldOffer.next() : nextId
    );
  }}

  /* ## Better */
  /* The utility method `better` takes an offer represented by `ofp` and another represented by `offer1`. It returns true iff `offer1` is better or as good as `ofp`.
    "better" is defined on the lexicographic order $\textrm{price} \times_{\textrm{lex}} \textrm{density}^{-1}$. This means that for the same price, offers that deliver more volume per gas are taken first.

      In addition to `offer1`, we also provide its id, `offerId1` in order to save gas. If necessary (ie. if the prices `wants1/gives1` and `wants2/gives2` are the same), we read storage to get `gasreq1` at `offerDetails[...][offerId1]. */
  function better(
    OfferPack memory ofp,
    P.Offer.t offer1,
    uint offerId1
  ) internal view returns (bool) { unchecked {
    if (offerId1 == 0) {
      /* Happens on empty book. Returning `false` would work as well due to specifics of `findPosition` but true is more consistent. Here we just want to avoid reading `offerDetail[...][0]` for nothing. */
      return true;
    }
    uint wants1 = offer1.wants();
    uint gives1 = offer1.gives();
    uint wants2 = ofp.wants;
    uint gives2 = ofp.gives;
    uint weight1 = wants1 * gives2;
    uint weight2 = wants2 * gives1;
    if (weight1 == weight2) {
      uint gasreq1 = 
          offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][offerId1].gasreq();
      uint gasreq2 = ofp.gasreq;
      return (gives1 * gasreq2 >= gives2 * gasreq1);
    } else {
      return weight1 < weight2;
    }
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOfferTakingWithPermit.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;
pragma abicoder v2;
import {HasMgvEvents} from "./MgvLib.sol";

import {MgvOfferTaking} from "./MgvOfferTaking.sol";

abstract contract MgvOfferTakingWithPermit is MgvOfferTaking {
  /* Takers may provide allowances on specific pairs, so other addresses can execute orders in their name. Allowance may be set using the usual `approve` function, or through an [EIP712](https://eips.ethereum.org/EIPS/eip-712) `permit`.

  The mapping is `outbound_tkn => inbound_tkn => owner => spender => allowance` */
  mapping(address => mapping(address => mapping(address => mapping(address => uint))))
    public allowances;
  /* Storing nonces avoids replay attacks. */
  mapping(address => uint) public nonces;
  /* Following [EIP712](https://eips.ethereum.org/EIPS/eip-712), structured data signing has `keccak256("Permit(address outbound_tkn,address inbound_tkn,address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")` in its prefix. */
  bytes32 public constant PERMIT_TYPEHASH =
    0xb7bf278e51ab1478b10530c0300f911d9ed3562fc93ab5e6593368fe23c077a2;
  /* Initialized in the constructor, `DOMAIN_SEPARATOR` avoids cross-application permit reuse. */
  bytes32 public immutable DOMAIN_SEPARATOR;

  constructor(string memory contractName) {
    /* Initialize [EIP712](https://eips.ethereum.org/EIPS/eip-712) `DOMAIN_SEPARATOR`. */
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(contractName)),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );
  }

  /* # Delegation public functions */

  /* Adapted from [Uniswap v2 contract](https://github.com/Uniswap/uniswap-v2-core/blob/55ae25109b7918565867e5c39f1e84b7edd19b2a/contracts/UniswapV2ERC20.sol#L81) */
  function permit(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    unchecked {
      require(deadline >= block.timestamp, "mgv/permit/expired");

      uint nonce = nonces[owner]++;
      bytes32 digest = keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(
            abi.encode(
              PERMIT_TYPEHASH,
              outbound_tkn,
              inbound_tkn,
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

      allowances[outbound_tkn][inbound_tkn][owner][spender] = value;
      emit Approval(outbound_tkn, inbound_tkn, owner, spender, value);
    }
  }

  function approve(
    address outbound_tkn,
    address inbound_tkn,
    address spender,
    uint value
  ) external returns (bool) {
    unchecked {
      allowances[outbound_tkn][inbound_tkn][msg.sender][spender] = value;
      emit Approval(outbound_tkn, inbound_tkn, msg.sender, spender, value);
      return true;
    }
  }

  /* The delegate version of `marketOrder` is `marketOrderFor`, which takes a `taker` address as additional argument. Penalties incurred by failed offers will still be sent to `msg.sender`, but exchanged amounts will be transferred from and to the `taker`. If the `msg.sender`'s allowance for the given `outbound_tkn`,`inbound_tkn` and `taker` are strictly less than the total amount eventually spent by `taker`, the call will fail. */

  /* *Note:* `marketOrderFor` and `snipesFor` may emit ERC20 `Transfer` events of value 0 from `taker`, but that's already the case with common ERC20 implementations. */
  function marketOrderFor(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint takerGot,
      uint takerGave,
      uint bounty
    )
  {
    unchecked {
      (takerGot, takerGave, bounty) = generalMarketOrder(
        outbound_tkn,
        inbound_tkn,
        takerWants,
        takerGives,
        fillWants,
        taker
      );
      /* The sender's allowance is verified after the order complete so that `takerGave` rather than `takerGives` is checked against the allowance. The former may be lower. */
      deductSenderAllowance(outbound_tkn, inbound_tkn, taker, takerGave);
    }
  }

  /* The delegate version of `snipes` is `snipesFor`, which takes a `taker` address as additional argument. */
  function snipesFor(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint successes,
      uint takerGot,
      uint takerGave,
      uint bounty
    )
  {
    unchecked {
      (successes, takerGot, takerGave, bounty) = generalSnipes(
        outbound_tkn,
        inbound_tkn,
        targets,
        fillWants,
        taker
      );
      /* The sender's allowance is verified after the order complete so that the actual amounts are checked against the allowance, instead of the declared `takerGives`. The former may be lower.
    
    An immediate consequence is that any funds availale to Mangrove through `approve` can be used to clean offers. After a `snipesFor` where all offers have failed, all token transfers have been reverted, so `takerGave=0` and the check will succeed -- but the sender will still have received the bounty of the failing offers. */
      deductSenderAllowance(outbound_tkn, inbound_tkn, taker, takerGave);
    }
  }

  /* # Misc. low-level functions */

  /* Used by `*For` functions, its both checks that `msg.sender` was allowed to use the taker's funds, and decreases the former's allowance. */
  function deductSenderAllowance(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    uint amount
  ) internal {
    unchecked {
      uint allowed = allowances[outbound_tkn][inbound_tkn][owner][msg.sender];
      require(allowed >= amount, "mgv/lowAllowance");
      allowances[outbound_tkn][inbound_tkn][owner][msg.sender] =
        allowed -
        amount;
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvGovernable.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {HasMgvEvents, P} from "./MgvLib.sol";
import {MgvRoot} from "./MgvRoot.sol";

contract MgvGovernable is MgvRoot {
  // using P.Offer for P.Offer.t;
  // using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  /* The `governance` address. Governance is the only address that can configure parameters. */
  address public governance;

  constructor(
    address _governance,
    uint _gasprice,
    uint gasmax
  ) MgvRoot() { unchecked {
    emit NewMgv();

    /* Initially, governance is open to anyone. */

    /* Initialize vault to governance address, and set initial gasprice and gasmax. */
    setVault(_governance);
    setGasprice(_gasprice);
    setGasmax(gasmax);
    /* Initialize governance to `_governance` after parameter setting. */
    setGovernance(_governance);
  }}

  /* ## `authOnly` check */

  function authOnly() internal view { unchecked {
    require(
      msg.sender == governance ||
        msg.sender == address(this) ||
        governance == address(0),
      "mgv/unauthorized"
    );
  }}

  /* # Set configuration and Mangrove state */

  /* ## Locals */
  /* ### `active` */
  function activate(
    address outbound_tkn,
    address inbound_tkn,
    uint fee,
    uint density,
    uint offer_gasbase
  ) public { unchecked {
    authOnly();
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].active(true);
    emit SetActive(outbound_tkn, inbound_tkn, true);
    setFee(outbound_tkn, inbound_tkn, fee);
    setDensity(outbound_tkn, inbound_tkn, density);
    setGasbase(outbound_tkn, inbound_tkn, offer_gasbase);
  }}

  function deactivate(address outbound_tkn, address inbound_tkn) public {
    authOnly();
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].active(false);
    emit SetActive(outbound_tkn, inbound_tkn, false);
  }

  /* ### `fee` */
  function setFee(
    address outbound_tkn,
    address inbound_tkn,
    uint fee
  ) public { unchecked {
    authOnly();
    /* `fee` is in basis points, i.e. in percents of a percent. */
    require(fee <= 500, "mgv/config/fee/<=500"); // at most 5%
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].fee(fee);
    emit SetFee(outbound_tkn, inbound_tkn, fee);
  }}

  /* ### `density` */
  /* Useless if `global.useOracle != 0` */
  function setDensity(
    address outbound_tkn,
    address inbound_tkn,
    uint density
  ) public { unchecked {
    authOnly();

    require(checkDensity(density), "mgv/config/density/112bits");
    //+clear+
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].density(density);
    emit SetDensity(outbound_tkn, inbound_tkn, density);
  }}

  /* ### `gasbase` */
  function setGasbase(
    address outbound_tkn,
    address inbound_tkn,
    uint offer_gasbase
  ) public { unchecked {
    authOnly();
    /* Checking the size of `offer_gasbase` is necessary to prevent a) data loss when copied to an `OfferDetail` struct, and b) overflow when used in calculations. */
    require(
      uint24(offer_gasbase) == offer_gasbase,
      "mgv/config/offer_gasbase/24bits"
    );
    //+clear+
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].offer_gasbase(offer_gasbase);
    emit SetGasbase(outbound_tkn, inbound_tkn, offer_gasbase);
  }}

  /* ## Globals */
  /* ### `kill` */
  function kill() public { unchecked {
    authOnly();
    internal_global = internal_global.dead(true);
    emit Kill();
  }}

  /* ### `gasprice` */
  /* Useless if `global.useOracle is != 0` */
  function setGasprice(uint gasprice) public { unchecked {
    authOnly();
    require(checkGasprice(gasprice), "mgv/config/gasprice/16bits");

    //+clear+

    internal_global = internal_global.gasprice(gasprice);
    emit SetGasprice(gasprice);
  }}

  /* ### `gasmax` */
  function setGasmax(uint gasmax) public { unchecked {
    authOnly();
    /* Since any new `gasreq` is bounded above by `config.gasmax`, this check implies that all offers' `gasreq` is 24 bits wide at most. */
    require(uint24(gasmax) == gasmax, "mgv/config/gasmax/24bits");
    //+clear+
    internal_global = internal_global.gasmax(gasmax);
    emit SetGasmax(gasmax);
  }}

  /* ### `governance` */
  function setGovernance(address governanceAddress) public { unchecked {
    authOnly();
    governance = governanceAddress;
    emit SetGovernance(governanceAddress);
  }}

  /* ### `vault` */
  function setVault(address vaultAddress) public { unchecked {
    authOnly();
    vault = vaultAddress;
    emit SetVault(vaultAddress);
  }}

  /* ### `monitor` */
  function setMonitor(address monitor) public { unchecked {
    authOnly();
    internal_global = internal_global.monitor(monitor);
    emit SetMonitor(monitor);
  }}

  /* ### `useOracle` */
  function setUseOracle(bool useOracle) public { unchecked {
    authOnly();
    internal_global = internal_global.useOracle(useOracle);
    emit SetUseOracle(useOracle);
  }}

  /* ### `notify` */
  function setNotify(bool notify) public { unchecked {
    authOnly();
    internal_global = internal_global.notify(notify);
    emit SetNotify(notify);
  }}
}

// SPDX-License-Identifier: Unlicense

// IERC20.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  function symbol() external view returns (string memory);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  /// for wETH contract
  function deposit() external payable;

  function withdraw(uint) external;

  function decimals() external view returns (uint8);
}

pragma solidity ^0.8.10;

// SPDX-License-Identifier: Unlicense

// MgvPack.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

// fields are of the form [name,bits,type]

// Can't put all structs under a 'Structs' library due to bad variable shadowing rules in Solidity
// (would generate lots of spurious warnings about a nameclash between Structs.Offer and library Offer for instance)
// struct_defs are of the form [name,obj]
struct OfferStruct {
  uint prev;
  uint next;
  uint wants;
  uint gives;
}
struct OfferDetailStruct {
  address maker;
  uint gasreq;
  uint offer_gasbase;
  uint gasprice;
}
struct GlobalStruct {
  address monitor;
  bool useOracle;
  bool notify;
  uint gasprice;
  uint gasmax;
  bool dead;
}
struct LocalStruct {
  bool active;
  uint fee;
  uint density;
  uint offer_gasbase;
  bool lock;
  uint best;
  uint last;
}

library Offer {
  //some type safety for each struct
  type t is uint;

  uint constant prev_bits  = 32;
  uint constant next_bits  = 32;
  uint constant wants_bits = 96;
  uint constant gives_bits = 96;

  uint constant prev_before  = 0;
  uint constant next_before  = prev_before  + prev_bits ;
  uint constant wants_before = next_before  + next_bits ;
  uint constant gives_before = wants_before + wants_bits;

  uint constant prev_mask  = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant next_mask  = 0xffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant wants_mask = 0xffffffffffffffff000000000000000000000000ffffffffffffffffffffffff;
  uint constant gives_mask = 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000;

  function to_struct(t __packed) internal pure returns (OfferStruct memory __s) { unchecked {
    __s.prev = (t.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __s.next = (t.unwrap(__packed) << next_before) >> (256-next_bits);
    __s.wants = (t.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __s.gives = (t.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function t_of_struct(OfferStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.prev, __s.next, __s.wants, __s.gives);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(uint __prev, uint __next, uint __wants, uint __gives) internal pure returns (t) { unchecked {
    return t.wrap(((((0
                  | ((__prev << (256-prev_bits)) >> prev_before))
                  | ((__next << (256-next_bits)) >> next_before))
                  | ((__wants << (256-wants_bits)) >> wants_before))
                  | ((__gives << (256-gives_bits)) >> gives_before)));
  }}

  function unpack(t __packed) internal pure returns (uint __prev, uint __next, uint __wants, uint __gives) { unchecked {
    __prev = (t.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __next = (t.unwrap(__packed) << next_before) >> (256-next_bits);
    __wants = (t.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __gives = (t.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function prev(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << prev_before) >> (256-prev_bits);
  }}
  function prev(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & prev_mask)
                  | ((val << (256-prev_bits) >> prev_before)));
  }}
  function next(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << next_before) >> (256-next_bits);
  }}
  function next(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & next_mask)
                  | ((val << (256-next_bits) >> next_before)));
  }}
  function wants(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << wants_before) >> (256-wants_bits);
  }}
  function wants(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & wants_mask)
                  | ((val << (256-wants_bits) >> wants_before)));
  }}
  function gives(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}
  function gives(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gives_mask)
                  | ((val << (256-gives_bits) >> gives_before)));
  }}
}

library OfferDetail {
  //some type safety for each struct
  type t is uint;

  uint constant maker_bits         = 160;
  uint constant gasreq_bits        = 24;
  uint constant offer_gasbase_bits = 24;
  uint constant gasprice_bits      = 16;

  uint constant maker_before         = 0;
  uint constant gasreq_before        = maker_before         + maker_bits        ;
  uint constant offer_gasbase_before = gasreq_before        + gasreq_bits       ;
  uint constant gasprice_before      = offer_gasbase_before + offer_gasbase_bits;

  uint constant maker_mask         = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
  uint constant gasreq_mask        = 0xffffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
  uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
  uint constant gasprice_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff;

  function to_struct(t __packed) internal pure returns (OfferDetailStruct memory __s) { unchecked {
    __s.maker = address(uint160((t.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __s.gasreq = (t.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __s.offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function t_of_struct(OfferDetailStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.maker, __s.gasreq, __s.offer_gasbase, __s.gasprice);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) internal pure returns (t) { unchecked {
    return t.wrap(((((0
                  | ((uint(uint160(__maker)) << (256-maker_bits)) >> maker_before))
                  | ((__gasreq << (256-gasreq_bits)) >> gasreq_before))
                  | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                  | ((__gasprice << (256-gasprice_bits)) >> gasprice_before)));
  }}

  function unpack(t __packed) internal pure returns (address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) { unchecked {
    __maker = address(uint160((t.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __gasreq = (t.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function maker(t __packed) internal pure returns(address) { unchecked {
    return address(uint160((t.unwrap(__packed) << maker_before) >> (256-maker_bits)));
  }}
  function maker(t __packed,address val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & maker_mask)
                  | ((uint(uint160(val)) << (256-maker_bits) >> maker_before)));
  }}
  function gasreq(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
  }}
  function gasreq(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasreq_mask)
                  | ((val << (256-gasreq_bits) >> gasreq_before)));
  }}
  function offer_gasbase(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & offer_gasbase_mask)
                  | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function gasprice(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasprice_mask)
                  | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
}

library Global {
  //some type safety for each struct
  type t is uint;

  uint constant monitor_bits   = 160;
  uint constant useOracle_bits = 8;
  uint constant notify_bits    = 8;
  uint constant gasprice_bits  = 16;
  uint constant gasmax_bits    = 24;
  uint constant dead_bits      = 8;

  uint constant monitor_before   = 0;
  uint constant useOracle_before = monitor_before   + monitor_bits  ;
  uint constant notify_before    = useOracle_before + useOracle_bits;
  uint constant gasprice_before  = notify_before    + notify_bits   ;
  uint constant gasmax_before    = gasprice_before  + gasprice_bits ;
  uint constant dead_before      = gasmax_before    + gasmax_bits   ;

  uint constant monitor_mask   = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
  uint constant useOracle_mask = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
  uint constant notify_mask    = 0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff;
  uint constant gasprice_mask  = 0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff;
  uint constant gasmax_mask    = 0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff;
  uint constant dead_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffff;

  function to_struct(t __packed) internal pure returns (GlobalStruct memory __s) { unchecked {
    __s.monitor = address(uint160((t.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __s.useOracle = (((t.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __s.notify = (((t.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __s.gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __s.gasmax = (t.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __s.dead = (((t.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function t_of_struct(GlobalStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.monitor, __s.useOracle, __s.notify, __s.gasprice, __s.gasmax, __s.dead);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) internal pure returns (t) { unchecked {
    return t.wrap(((((((0
                  | ((uint(uint160(__monitor)) << (256-monitor_bits)) >> monitor_before))
                  | ((uint_of_bool(__useOracle) << (256-useOracle_bits)) >> useOracle_before))
                  | ((uint_of_bool(__notify) << (256-notify_bits)) >> notify_before))
                  | ((__gasprice << (256-gasprice_bits)) >> gasprice_before))
                  | ((__gasmax << (256-gasmax_bits)) >> gasmax_before))
                  | ((uint_of_bool(__dead) << (256-dead_bits)) >> dead_before)));
  }}

  function unpack(t __packed) internal pure returns (address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) { unchecked {
    __monitor = address(uint160((t.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __useOracle = (((t.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __notify = (((t.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __gasmax = (t.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __dead = (((t.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function monitor(t __packed) internal pure returns(address) { unchecked {
    return address(uint160((t.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
  }}
  function monitor(t __packed,address val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & monitor_mask)
                  | ((uint(uint160(val)) << (256-monitor_bits) >> monitor_before)));
  }}
  function useOracle(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
  }}
  function useOracle(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & useOracle_mask)
                  | ((uint_of_bool(val) << (256-useOracle_bits) >> useOracle_before)));
  }}
  function notify(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
  }}
  function notify(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & notify_mask)
                  | ((uint_of_bool(val) << (256-notify_bits) >> notify_before)));
  }}
  function gasprice(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasprice_mask)
                  | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
  function gasmax(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
  }}
  function gasmax(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasmax_mask)
                  | ((val << (256-gasmax_bits) >> gasmax_before)));
  }}
  function dead(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}
  function dead(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & dead_mask)
                  | ((uint_of_bool(val) << (256-dead_bits) >> dead_before)));
  }}
}

library Local {
  //some type safety for each struct
  type t is uint;

  uint constant active_bits        = 8;
  uint constant fee_bits           = 16;
  uint constant density_bits       = 112;
  uint constant offer_gasbase_bits = 24;
  uint constant lock_bits          = 8;
  uint constant best_bits          = 32;
  uint constant last_bits          = 32;

  uint constant active_before        = 0;
  uint constant fee_before           = active_before        + active_bits       ;
  uint constant density_before       = fee_before           + fee_bits          ;
  uint constant offer_gasbase_before = density_before       + density_bits      ;
  uint constant lock_before          = offer_gasbase_before + offer_gasbase_bits;
  uint constant best_before          = lock_before          + lock_bits         ;
  uint constant last_before          = best_before          + best_bits         ;

  uint constant active_mask        = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant fee_mask           = 0xff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant density_mask       = 0xffffff0000000000000000000000000000ffffffffffffffffffffffffffffff;
  uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
  uint constant lock_mask          = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
  uint constant best_mask          = 0xffffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffff;
  uint constant last_mask          = 0xffffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffff;

  function to_struct(t __packed) internal pure returns (LocalStruct memory __s) { unchecked {
    __s.active = (((t.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __s.fee = (t.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __s.density = (t.unwrap(__packed) << density_before) >> (256-density_bits);
    __s.offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.lock = (((t.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __s.best = (t.unwrap(__packed) << best_before) >> (256-best_bits);
    __s.last = (t.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function t_of_struct(LocalStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.active, __s.fee, __s.density, __s.offer_gasbase, __s.lock, __s.best, __s.last);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) internal pure returns (t) { unchecked {
    return t.wrap((((((((0
                  | ((uint_of_bool(__active) << (256-active_bits)) >> active_before))
                  | ((__fee << (256-fee_bits)) >> fee_before))
                  | ((__density << (256-density_bits)) >> density_before))
                  | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                  | ((uint_of_bool(__lock) << (256-lock_bits)) >> lock_before))
                  | ((__best << (256-best_bits)) >> best_before))
                  | ((__last << (256-last_bits)) >> last_before)));
  }}

  function unpack(t __packed) internal pure returns (bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) { unchecked {
    __active = (((t.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __fee = (t.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __density = (t.unwrap(__packed) << density_before) >> (256-density_bits);
    __offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __lock = (((t.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __best = (t.unwrap(__packed) << best_before) >> (256-best_bits);
    __last = (t.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function active(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
  }}
  function active(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & active_mask)
                  | ((uint_of_bool(val) << (256-active_bits) >> active_before)));
  }}
  function fee(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << fee_before) >> (256-fee_bits);
  }}
  function fee(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & fee_mask)
                  | ((val << (256-fee_bits) >> fee_before)));
  }}
  function density(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << density_before) >> (256-density_bits);
  }}
  function density(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & density_mask)
                  | ((val << (256-density_bits) >> density_before)));
  }}
  function offer_gasbase(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & offer_gasbase_mask)
                  | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function lock(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
  }}
  function lock(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & lock_mask)
                  | ((uint_of_bool(val) << (256-lock_bits) >> lock_before)));
  }}
  function best(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << best_before) >> (256-best_bits);
  }}
  function best(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & best_mask)
                  | ((val << (256-best_bits) >> best_before)));
  }}
  function last(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << last_before) >> (256-last_bits);
  }}
  function last(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & last_mask)
                  | ((val << (256-last_bits) >> last_before)));
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvHasOffers.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, HasMgvEvents, IMgvMonitor,P} from "./MgvLib.sol";
import {MgvRoot} from "./MgvRoot.sol";

/* `MgvHasOffers` contains the state variables and functions common to both market-maker operations and market-taker operations. Mostly: storing offers, removing them, updating market makers' provisions. */
contract MgvHasOffers is MgvRoot {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Local for P.Local.t;
  /* # State variables */
  /* Given a `outbound_tkn`,`inbound_tkn` pair, the mappings `offers` and `offerDetails` associate two 256 bits words to each offer id. Those words encode information detailed in [`structs.js`](#structs.js).

     The mappings are `outbound_tkn => inbound_tkn => offerId => P.Offer.t|P.OfferDetail.t`.
   */
  mapping(address => mapping(address => mapping(uint => P.Offer.t)))
    public offers;
  mapping(address => mapping(address => mapping(uint => P.OfferDetail.t)))
    public offerDetails;

  /* Makers provision their possible penalties in the `balanceOf` mapping.

       Offers specify the amount of gas they require for successful execution ([`gasreq`](#structs.js/gasreq)). To minimize book spamming, market makers must provision a *penalty*, which depends on their `gasreq` and on the pair's [`offer_gasbase`](#structs.js/gasbase). This provision is deducted from their `balanceOf`. If an offer fails, part of that provision is given to the taker, as retribution. The exact amount depends on the gas used by the offer before failing.

       The Mangrove keeps track of their available balance in the `balanceOf` map, which is decremented every time a maker creates a new offer, and may be modified on offer updates/cancelations/takings.
     */
  mapping(address => uint) public balanceOf;

  /* # Read functions */
  /* Convenience function to get best offer of the given pair */
  function best(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint)
  { unchecked {
    P.Local.t local = locals[outbound_tkn][inbound_tkn];
    return local.best();
  }}

  /* Returns information about an offer in ABI-compatible structs. Do not use internally, would be a huge memory-copying waste. Use `offers[outbound_tkn][inbound_tkn]` and `offerDetails[outbound_tkn][inbound_tkn]` instead. */
  function offerInfo(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) external view returns (P.OfferStruct memory offer, P.OfferDetailStruct memory offerDetail) { unchecked {

    P.Offer.t _offer = offers[outbound_tkn][inbound_tkn][offerId];
    offer = _offer.to_struct();

    P.OfferDetail.t _offerDetail = offerDetails[outbound_tkn][inbound_tkn][offerId];
    offerDetail = _offerDetail.to_struct();
  }}

  /* # Provision debit/credit utility functions */
  /* `balanceOf` is in wei of ETH. */

  function debitWei(address maker, uint amount) internal { unchecked {
    uint makerBalance = balanceOf[maker];
    require(makerBalance >= amount, "mgv/insufficientProvision");
    balanceOf[maker] = makerBalance - amount;
    emit Debit(maker, amount);
  }}

  function creditWei(address maker, uint amount) internal { unchecked {
    balanceOf[maker] += amount;
    emit Credit(maker, amount);
  }}

  /* # Misc. low-level functions */
  /* ## Offer deletion */

  /* When an offer is deleted, it is marked as such by setting `gives` to 0. Note that provision accounting in the Mangrove aims to minimize writes. Each maker `fund`s the Mangrove to increase its balance. When an offer is created/updated, we compute how much should be reserved to pay for possible penalties. That amount can always be recomputed with `offerDetail.gasprice * (offerDetail.gasreq + offerDetail.offer_gasbase)`. The balance is updated to reflect the remaining available ethers.

     Now, when an offer is deleted, the offer can stay provisioned, or be `deprovision`ed. In the latter case, we set `gasprice` to 0, which induces a provision of 0. All code calling `dirtyDeleteOffer` with `deprovision` set to `true` must be careful to correctly account for where that provision is going (back to the maker's `balanceOf`, or sent to a taker as compensation). */
  function dirtyDeleteOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    P.Offer.t offer,
    P.OfferDetail.t offerDetail,
    bool deprovision
  ) internal { unchecked {
    offer = offer.gives(0);
    if (deprovision) {
      offerDetail = offerDetail.gasprice(0);
    }
    offers[outbound_tkn][inbound_tkn][offerId] = offer;
    offerDetails[outbound_tkn][inbound_tkn][offerId] = offerDetail;
  }}

  /* ## Stitching the orderbook */

  /* Connect the offers `betterId` and `worseId` through their `next`/`prev` pointers. For more on the book structure, see [`structs.js`](#structs.js). Used after executing an offer (or a segment of offers), after removing an offer, or moving an offer.

  **Warning**: calling with `betterId = 0` will set `worseId` as the best. So with `betterId = 0` and `worseId = 0`, it sets the book to empty and loses track of existing offers.

  **Warning**: may make memory copy of `local.best` stale. Returns new `local`. */
  function stitchOffers(
    address outbound_tkn,
    address inbound_tkn,
    uint betterId,
    uint worseId,
    P.Local.t local
  ) internal returns (P.Local.t) { unchecked {
    if (betterId != 0) {
      offers[outbound_tkn][inbound_tkn][betterId] = offers[outbound_tkn][inbound_tkn][betterId].next(worseId);
    } else {
      local = local.best(worseId);
    }

    if (worseId != 0) {
      offers[outbound_tkn][inbound_tkn][worseId] = offers[outbound_tkn][inbound_tkn][worseId].prev(betterId);
    }

    return local;
  }}

  /* ## Check offer is live */
  /* Check whether an offer is 'live', that is: inserted in the order book. The Mangrove holds a `outbound_tkn => inbound_tkn => id => P.Offer.t` mapping in storage. Offer ids that are not yet assigned or that point to since-deleted offer will point to an offer with `gives` field at 0. */
  function isLive(P.Offer.t offer) public pure returns (bool) { unchecked {
    return offer.gives() > 0;
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvRoot.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* `MgvRoot` and its descendants describe an orderbook-based exchange ("the Mangrove") where market makers *do not have to provision their offer*. See `structs.js` for a longer introduction. In a nutshell: each offer created by a maker specifies an address (`maker`) to call upon offer execution by a taker. In the normal mode of operation, the Mangrove transfers the amount to be paid by the taker to the maker, calls the maker, attempts to transfer the amount promised by the maker to the taker, and reverts if it cannot.

   There is one Mangrove contract that manages all tradeable pairs. This reduces deployment costs for new pairs and lets market makers have all their provision for all pairs in the same place.

   The interaction map between the different actors is as follows:
   <img src="./contactMap.png" width="190%"></img>

   The sequence diagram of a market order is as follows:
   <img src="./sequenceChart.png" width="190%"></img>

   There is a secondary mode of operation in which the _maker_ flashloans the sold amount to the taker.

   The Mangrove contract is `abstract` and accomodates both modes. Two contracts, `Mangrove` and `InvertedMangrove` inherit from it, one per mode of operation.

   The contract structure is as follows:
   <img src="./modular_mangrove.svg" width="180%"> </img>
 */

pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, HasMgvEvents, IMgvMonitor, P} from "./MgvLib.sol";

/* `MgvRoot` contains state variables used everywhere in the operation of the Mangrove and their related function. */
contract MgvRoot is HasMgvEvents {
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;


  /* # State variables */
  //+clear+
  /* The `vault` address. If a pair has fees >0, those fees are sent to the vault. */
  address public vault;

  /* Global mgv configuration, encoded in a 256 bits word. The information encoded is detailed in [`structs.js`](#structs.js). */
  P.Global.t internal internal_global;
  /* Configuration mapping for each token pair of the form `outbound_tkn => inbound_tkn => P.Local.t`. The structure of each `P.Local.t` value is detailed in [`structs.js`](#structs.js). It fits in one word. */
  mapping(address => mapping(address => P.Local.t)) internal locals;

  /* Checking the size of `density` is necessary to prevent overflow when `density` is used in calculations. */
  function checkDensity(uint density) internal pure returns (bool) { unchecked {
    return uint112(density) == density;
  }}

  /* Checking the size of `gasprice` is necessary to prevent a) data loss when `gasprice` is copied to an `OfferDetail` struct, and b) overflow when `gasprice` is used in calculations. */
  function checkGasprice(uint gasprice) internal pure returns (bool) { unchecked {
    return uint16(gasprice) == gasprice;
  }}

  /* # Configuration Reads */
  /* Reading the configuration for a pair involves reading the config global to all pairs and the local one. In addition, a global parameter (`gasprice`) and a local one (`density`) may be read from the oracle. */
  function config(address outbound_tkn, address inbound_tkn)
    public
    view
    returns (P.Global.t _global, P.Local.t _local)
  { unchecked {
    _global = internal_global;
    _local = locals[outbound_tkn][inbound_tkn];
    if (_global.useOracle()) {
      (uint gasprice, uint density) = IMgvMonitor(_global.monitor())
        .read(outbound_tkn, inbound_tkn);
      if (checkGasprice(gasprice)) {
        _global = _global.gasprice(gasprice);
      }
      if (checkDensity(density)) {
        _local = _local.density(density);
      }
    }
  }}

  /* Returns the configuration in an ABI-compatible struct. Should not be called internally, would be a huge memory copying waste. Use `config` instead. */
  function configInfo(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (P.GlobalStruct memory global, P.LocalStruct memory local)
  { unchecked {
    (P.Global.t _global, P.Local.t _local) = config(outbound_tkn, inbound_tkn);
    global = _global.to_struct();
    local = _local.to_struct();
  }}

  /* Convenience function to check whether given pair is locked */
  function locked(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (bool)
  {
    P.Local.t local = locals[outbound_tkn][inbound_tkn];
    return local.lock();
  }

  /*
  # Gatekeeping

  Gatekeeping functions are safety checks called in various places.
  */

  /* `unlockedMarketOnly` protects modifying the market while an order is in progress. Since external contracts are called during orders, allowing reentrancy would, for instance, let a market maker replace offers currently on the book with worse ones. Note that the external contracts _will_ be called again after the order is complete, this time without any lock on the market.  */
  function unlockedMarketOnly(P.Local.t local) internal pure {
    require(!local.lock(), "mgv/reentrancyLocked");
  }

  /* <a id="Mangrove/definition/liveMgvOnly"></a>
     In case of emergency, the Mangrove can be `kill`ed. It cannot be resurrected. When a Mangrove is dead, the following operations are disabled :
       * Executing an offer
       * Sending ETH to the Mangrove the normal way. Usual [shenanigans](https://medium.com/@alexsherbuck/two-ways-to-force-ether-into-a-contract-1543c1311c56) are possible.
       * Creating a new offer
   */
  function liveMgvOnly(P.Global.t _global) internal pure {
    require(!_global.dead(), "mgv/dead");
  }

  /* When the Mangrove is deployed, all pairs are inactive by default (since `locals[outbound_tkn][inbound_tkn]` is 0 by default). Offers on inactive pairs cannot be taken or created. They can be updated and retracted. */
  function activeMarketOnly(P.Global.t _global, P.Local.t _local) internal pure {
    liveMgvOnly(_global);
    require(_local.active(), "mgv/inactive");
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOfferTaking.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {IERC20, HasMgvEvents, IMaker, IMgvMonitor, MgvLib as ML, P} from "./MgvLib.sol";
import {MgvHasOffers} from "./MgvHasOffers.sol";

abstract contract MgvOfferTaking is MgvHasOffers {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  /* # MultiOrder struct */
  /* The `MultiOrder` struct is used by market orders and snipes. Some of its fields are only used by market orders (`initialWants, initialGives`). We need a common data structure for both since low-level calls are shared between market orders and snipes. The struct is helpful in decreasing stack use. */
  struct MultiOrder {
    uint initialWants; // used globally by market order, not used by snipes
    uint initialGives; // used globally by market order, not used by snipes
    uint totalGot; // used globally by market order, per-offer by snipes
    uint totalGave; // used globally by market order, per-offer by snipes
    uint totalPenalty; // used globally
    address taker; // used globally
    bool fillWants; // used globally
  }

  /* # Market Orders */

  /* ## Market Order */
  //+clear+

  /* A market order specifies a (`outbound_tkn`,`inbound_tkn`) pair, a desired total amount of `outbound_tkn` (`takerWants`), and an available total amount of `inbound_tkn` (`takerGives`). It returns two `uint`s: the total amount of `outbound_tkn` received and the total amount of `inbound_tkn` spent.

     The `takerGives/takerWants` ratio induces a maximum average price that the taker is ready to pay across all offers that will be executed during the market order. It is thus possible to execute an offer with a price worse than the initial (`takerGives`/`takerWants`) ratio given as argument to `marketOrder` if some cheaper offers were executed earlier in the market order.

  The market order stops when the price has become too high, or when the end of the book has been reached, or:
  * If `fillWants` is true, the market order stops when `takerWants` units of `outbound_tkn` have been obtained. With `fillWants` set to true, to buy a specific volume of `outbound_tkn` at any price, set `takerWants` to the amount desired and `takerGives` to $2^{160}-1$.
  * If `fillWants` is false, the taker is filling `gives` instead: the market order stops when `takerGives` units of `inbound_tkn` have been sold. With `fillWants` set to false, to sell a specific volume of `inbound_tkn` at any price, set `takerGives` to the amount desired and `takerWants` to $0$. */
  function marketOrder(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants
  )
    external
    returns (
      uint,
      uint,
      uint
    )
  { unchecked {
    return
      generalMarketOrder(
        outbound_tkn,
        inbound_tkn,
        takerWants,
        takerGives,
        fillWants,
        msg.sender
      );
  }}

  /* # General Market Order */
  //+clear+
  /* General market orders set up the market order with a given `taker` (`msg.sender` in the most common case). Returns `(totalGot, totalGave)`.
  Note that the `taker` can be anyone. This is safe when `taker == msg.sender`, but `generalMarketOrder` must not be called with `taker != msg.sender` unless a security check is done after (see [`MgvOfferTakingWithPermit`](#mgvoffertakingwithpermit.sol)`. */
  function generalMarketOrder(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    address taker
  )
    internal
    returns (
      uint,
      uint,
      uint
    )
  { unchecked {
    /* Since amounts stored in offers are 96 bits wide, checking that `takerWants` and `takerGives` fit in 160 bits prevents overflow during the main market order loop. */
    require(uint160(takerWants) == takerWants, "mgv/mOrder/takerWants/160bits");
    require(uint160(takerGives) == takerGives, "mgv/mOrder/takerGives/160bits");

    /* `SingleOrder` is defined in `MgvLib.sol` and holds information for ordering the execution of one offer. */
    ML.SingleOrder memory sor;
    sor.outbound_tkn = outbound_tkn;
    sor.inbound_tkn = inbound_tkn;
    (sor.global, sor.local) = config(outbound_tkn, inbound_tkn);
    /* Throughout the execution of the market order, the `sor`'s offer id and other parameters will change. We start with the current best offer id (0 if the book is empty). */
    sor.offerId = sor.local.best();
    sor.offer = offers[outbound_tkn][inbound_tkn][sor.offerId];
    /* `sor.wants` and `sor.gives` may evolve, but they are initially however much remains in the market order. */
    sor.wants = takerWants;
    sor.gives = takerGives;

    /* `MultiOrder` (defined above) maintains information related to the entire market order. During the order, initial `wants`/`gives` values minus the accumulated amounts traded so far give the amounts that remain to be traded. */
    MultiOrder memory mor;
    mor.initialWants = takerWants;
    mor.initialGives = takerGives;
    mor.taker = taker;
    mor.fillWants = fillWants;

    /* For the market order to even start, the market needs to be both active, and not currently protected from reentrancy. */
    activeMarketOnly(sor.global, sor.local);
    unlockedMarketOnly(sor.local);

    /* ### Initialization */
    /* The market order will operate as follows : it will go through offers from best to worse, starting from `offerId`, and: */
    /* * will maintain remaining `takerWants` and `takerGives` values. The initial `takerGives/takerWants` ratio is the average price the taker will accept. Better prices may be found early in the book, and worse ones later.
     * will not set `prev`/`next` pointers to their correct locations at each offer taken (this is an optimization enabled by forbidding reentrancy).
     * after consuming a segment of offers, will update the current `best` offer to be the best remaining offer on the book. */

    /* We start be enabling the reentrancy lock for this (`outbound_tkn`,`inbound_tkn`) pair. */
    sor.local = sor.local.lock(true);
    locals[outbound_tkn][inbound_tkn] = sor.local;

    /* Call recursive `internalMarketOrder` function.*/
    internalMarketOrder(mor, sor, true);

    /* Over the course of the market order, a penalty reserved for `msg.sender` has accumulated in `mor.totalPenalty`. No actual transfers have occured yet -- all the ethers given by the makers as provision are owned by the Mangrove. `sendPenalty` finally gives the accumulated penalty to `msg.sender`. */
    sendPenalty(mor.totalPenalty);

    emit OrderComplete(
      outbound_tkn,
      inbound_tkn,
      taker,
      mor.totalGot,
      mor.totalGave
    );

    //+clear+
    return (mor.totalGot, mor.totalGave, mor.totalPenalty);
  }}

  /* ## Internal market order */
  //+clear+
  /* `internalMarketOrder` works recursively. Going downward, each successive offer is executed until the market order stops (due to: volume exhausted, bad price, or empty book). Then the [reentrancy lock is lifted](#internalMarketOrder/liftReentrancy). Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book.

    The last argument is a boolean named `proceed`. If an offer was not executed, it means the price has become too high. In that case, we notify the next recursive call that the market order should end. In this initial call, no offer has been executed yet so `proceed` is true. */
  function internalMarketOrder(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    bool proceed
  ) internal { unchecked {
    /* #### Case 1 : End of order */
    /* We execute the offer currently stored in `sor`. */
    if (
      proceed &&
      (mor.fillWants ? sor.wants > 0 : sor.gives > 0) &&
      sor.offerId > 0
    ) {
      uint gasused; // gas used by `makerExecute`
      bytes32 makerData; // data returned by maker

      /* <a id="MgvOfferTaking/statusCodes"></a> `mgvData` is an internal Mangrove status code. It may appear in an [`OrderResult`](#MgvLib/OrderResult). Its possible values are:
      * `"mgv/notExecuted"`: offer was not executed.
      * `"mgv/tradeSuccess"`: offer execution succeeded. Will appear in `OrderResult`.
      * `"mgv/notEnoughGasForMakerTrade"`: cannot give maker close enough to `gasreq`. Triggers a revert of the entire order.
      * `"mgv/makerRevert"`: execution of `makerExecute` reverted. Will appear in `OrderResult`.
      * `"mgv/makerAbort"`: execution of `makerExecute` returned normally, but returndata did not start with 32 bytes of 0s. Will appear in `OrderResult`.
      * `"mgv/makerTransferFail"`: maker could not send outbound_tkn tokens. Will appear in `OrderResult`.
      * `"mgv/makerReceiveFail"`: maker could not receive inbound_tkn tokens. Will appear in `OrderResult`.
      * `"mgv/takerTransferFail"`: taker could not send inbound_tkn tokens. Triggers a revert of the entire order.

      `mgvData` should not be exploitable by the maker! */
      bytes32 mgvData;

      /* Load additional information about the offer. We don't do it earlier to save one storage read in case `proceed` was false. */
      sor.offerDetail = offerDetails[sor.outbound_tkn][sor.inbound_tkn][
        sor.offerId
      ];

      /* `execute` will adjust `sor.wants`,`sor.gives`, and may attempt to execute the offer if its price is low enough. It is crucial that an error due to `taker` triggers a revert. That way, [`mgvData`](#MgvOfferTaking/statusCodes) not in `["mgv/notExecuted","mgv/tradeSuccess"]` means the failure is the maker's fault. */
      /* Post-execution, `sor.wants`/`sor.gives` reflect how much was sent/taken by the offer. We will need it after the recursive call, so we save it in local variables. Same goes for `offerId`, `sor.offer` and `sor.offerDetail`. */

      (gasused, makerData, mgvData) = execute(mor, sor);

      /* Keep cached copy of current `sor` values. */
      uint takerWants = sor.wants;
      uint takerGives = sor.gives;
      uint offerId = sor.offerId;
      P.Offer.t offer = sor.offer;
      P.OfferDetail.t offerDetail = sor.offerDetail;

      /* If an execution was attempted, we move `sor` to the next offer. Note that the current state is inconsistent, since we have not yet updated `sor.offerDetails`. */
      if (mgvData != "mgv/notExecuted") {
        sor.wants = mor.initialWants > mor.totalGot
          ? mor.initialWants - mor.totalGot
          : 0;
        /* It is known statically that `mor.initialGives - mor.totalGave` does not underflow since
           1. `mor.totalGave` was increased by `sor.gives` during `execute`,
           2. `sor.gives` was at most `mor.initialGives - mor.totalGave` from earlier step,
           3. `sor.gives` may have been clamped _down_ during `execute` (to "`offer.wants`" if the offer is entirely consumed, or to `makerWouldWant`, cf. code of `execute`).
        */
        sor.gives = mor.initialGives - mor.totalGave;
        sor.offerId = sor.offer.next();
        sor.offer = offers[sor.outbound_tkn][sor.inbound_tkn][sor.offerId];
      }

      /* note that internalMarketOrder may be called twice with same offerId, but in that case `proceed` will be false! */
      internalMarketOrder(
        mor,
        sor,
        /* `proceed` value for next call. Currently, when an offer did not execute, it's because the offer's price was too high. In that case we interrupt the loop and let the taker leave with less than they asked for (but at a correct price). We could also revert instead of breaking; this could be a configurable flag for the taker to pick. */
        mgvData != "mgv/notExecuted"
      );

      /* Restore `sor` values from to before recursive call */
      sor.offerId = offerId;
      sor.wants = takerWants;
      sor.gives = takerGives;
      sor.offer = offer;
      sor.offerDetail = offerDetail;

      /* After an offer execution, we may run callbacks and increase the total penalty. As that part is common to market orders and snipes, it lives in its own `postExecute` function. */
      if (mgvData != "mgv/notExecuted") {
        postExecute(mor, sor, gasused, makerData, mgvData);
      }

      /* #### Case 2 : End of market order */
      /* If `proceed` is false, the taker has gotten its requested volume, or we have reached the end of the book, we conclude the market order. */
    } else {
      /* During the market order, all executed offers have been removed from the book. We end by stitching together the `best` offer pointer and the new best offer. */
      sor.local = stitchOffers(
        sor.outbound_tkn,
        sor.inbound_tkn,
        0,
        sor.offerId,
        sor.local
      );
      /* <a id="internalMarketOrder/liftReentrancy"></a>Now that the market order is over, we can lift the lock on the book. In the same operation we

      * lift the reentrancy lock, and
      * update the storage

      so we are free from out of order storage writes.
      */
      sor.local = sor.local.lock(false);
      locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

      /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
      payTakerMinusFees(mor, sor);

      /* In an inverted Mangrove, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in a normal Mangrove. */
      executeEnd(mor, sor);
    }
  }}

  /* # Sniping */
  /* ## Snipes */
  //+clear+

  /* `snipes` executes multiple offers. It takes a `uint[4][]` as penultimate argument, with each array element of the form `[offerId,takerWants,takerGives,offerGasreq]`. The return parameters are of the form `(successes,snipesGot,snipesGave,bounty)`. 
  Note that we do not distinguish further between mismatched arguments/offer fields on the one hand, and an execution failure on the other. Still, a failed offer has to pay a penalty, and ultimately transaction logs explicitly mention execution failures (see `MgvLib.sol`). */
  function snipes(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants
  )
    external
    returns (
      uint,
      uint,
      uint,
      uint
    )
  { unchecked {
    return
      generalSnipes(outbound_tkn, inbound_tkn, targets, fillWants, msg.sender);
  }}

  /*
     From an array of _n_ `[offerId, takerWants,takerGives,gasreq]` elements, execute each snipe in sequence. Returns `(successes, takerGot, takerGave, bounty)`. 

     Note that if this function is not internal, anyone can make anyone use Mangrove.
     Note that unlike general market order, the returned total values are _not_ `mor.totalGot` and `mor.totalGave`, since those are reset at every iteration of the `targets` array. Instead, accumulators `snipesGot` and `snipesGave` are used. */
  function generalSnipes(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants,
    address taker
  )
    internal
    returns (
      uint,
      uint,
      uint,
      uint
    )
  { unchecked {
    ML.SingleOrder memory sor;
    sor.outbound_tkn = outbound_tkn;
    sor.inbound_tkn = inbound_tkn;
    (sor.global, sor.local) = config(outbound_tkn, inbound_tkn);

    MultiOrder memory mor;
    mor.taker = taker;
    mor.fillWants = fillWants;

    /* For the snipes to even start, the market needs to be both active and not currently protected from reentrancy. */
    activeMarketOnly(sor.global, sor.local);
    unlockedMarketOnly(sor.local);

    /* ### Main loop */
    //+clear+

    /* Call `internalSnipes` function. */
    (uint successCount, uint snipesGot, uint snipesGave) = internalSnipes(mor, sor, targets);

    /* Over the course of the snipes order, a penalty reserved for `msg.sender` has accumulated in `mor.totalPenalty`. No actual transfers have occured yet -- all the ethers given by the makers as provision are owned by the Mangrove. `sendPenalty` finally gives the accumulated penalty to `msg.sender`. */
    sendPenalty(mor.totalPenalty);
    //+clear+

    emit OrderComplete(
      outbound_tkn,
      inbound_tkn,
      taker,
      snipesGot,
      snipesGave
    );

    return (successCount, snipesGot, snipesGave, mor.totalPenalty);
  }}

  /* ## Internal snipes */
  //+clear+
  /* `internalSnipes` works by looping over targets. Each successive offer is executed under a [reentrancy lock](#internalSnipes/liftReentrancy), then its posthook is called.y lock [is lifted](). Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book. */
  function internalSnipes(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    uint[4][] calldata targets
  ) internal returns (uint successCount, uint snipesGot, uint snipesGave) { unchecked {
    for (uint i = 0; i < targets.length; i++) {
      /* Reset these amounts since every snipe is treated individually. Only the total penalty is sent at the end of all snipes. */
      mor.totalGot = 0;
      mor.totalGave = 0;

      /* Initialize single order struct. */
      sor.offerId = targets[i][0];
      sor.offer = offers[sor.outbound_tkn][sor.inbound_tkn][sor.offerId];
      sor.offerDetail = offerDetails[sor.outbound_tkn][sor.inbound_tkn][
        sor.offerId
      ];

      /* If we removed the `isLive` conditional, a single expired or nonexistent offer in `targets` would revert the entire transaction (by the division by `offer.gives` below since `offer.gives` would be 0). We also check that `gasreq` is not worse than specified. A taker who does not care about `gasreq` can specify any amount larger than $2^{24}-1$. A mismatched price will be detected by `execute`. */
      if (
        !isLive(sor.offer) ||
        sor.offerDetail.gasreq() > targets[i][3]
      ) {
        /* We move on to the next offer in the array. */
        continue;
      } else {
        require(
          uint96(targets[i][1]) == targets[i][1],
          "mgv/snipes/takerWants/96bits"
        );
        require(
          uint96(targets[i][2]) == targets[i][2],
          "mgv/snipes/takerGives/96bits"
        );
        sor.wants = targets[i][1];
        sor.gives = targets[i][2];

        /* We start be enabling the reentrancy lock for this (`outbound_tkn`,`inbound_tkn`) pair. */
        sor.local = sor.local.lock(true);
        locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

        /* `execute` will adjust `sor.wants`,`sor.gives`, and may attempt to execute the offer if its price is low enough. It is crucial that an error due to `taker` triggers a revert. That way [`mgvData`](#MgvOfferTaking/statusCodes) not in `["mgv/tradeSuccess","mgv/notExecuted"]` means the failure is the maker's fault. */
        /* Post-execution, `sor.wants`/`sor.gives` reflect how much was sent/taken by the offer. */
        (uint gasused, bytes32 makerData, bytes32 mgvData) = execute(mor, sor);

        if (mgvData == "mgv/tradeSuccess") {
          successCount += 1;
        }

        /* In the market order, we were able to avoid stitching back offers after every `execute` since we knew a continuous segment starting at best would be consumed. Here, we cannot do this optimisation since offers in the `targets` array may be anywhere in the book. So we stitch together offers immediately after each `execute`. */
        if (mgvData != "mgv/notExecuted") {
          sor.local = stitchOffers(
            sor.outbound_tkn,
            sor.inbound_tkn,
            sor.offer.prev(),
            sor.offer.next(),
            sor.local
          );
        }

        /* <a id="internalSnipes/liftReentrancy"></a> Now that the current snipe is over, we can lift the lock on the book. In the same operation we
        * lift the reentrancy lock, and
        * update the storage

        so we are free from out of order storage writes.
        */
        sor.local = sor.local.lock(false);
        locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

        /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
        payTakerMinusFees(mor, sor);

        /* In an inverted Mangrove, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in a normal Mangrove. */
        executeEnd(mor, sor);

        /* After an offer execution, we may run callbacks and increase the total penalty. As that part is common to market orders and snipes, it lives in its own `postExecute` function. */
        if (mgvData != "mgv/notExecuted") {
          postExecute(mor, sor, gasused, makerData, mgvData);
        }


        snipesGot += mor.totalGot;
        snipesGave += mor.totalGave;
      }
    }
  }}

  /* # General execution */
  /* During a market order or a snipes, offers get executed. The following code takes care of executing a single offer with parameters given by a `SingleOrder` within a larger context given by a `MultiOrder`. */

  /* ## Execute */
  /* This function will compare `sor.wants` `sor.gives` with `sor.offer.wants` and `sor.offer.gives`. If the price of the offer is low enough, an execution will be attempted (with volume limited by the offer's advertised volume).

     Summary of the meaning of the return values:
    * `gasused` is the gas consumed by the execution
    * `makerData` is the data returned after executing the offer
    * `mgvData` is an [internal Mangrove status code](#MgvOfferTaking/statusCodes).
  */
  function execute(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    returns (
      uint gasused,
      bytes32 makerData,
      bytes32 mgvData
    )
  { unchecked {
    /* #### `Price comparison` */
    //+clear+
    /* The current offer has a price `p = offerWants ÷ offerGives` and the taker is ready to accept a price up to `p' = takerGives ÷ takerWants`. Comparing `offerWants * takerWants` and `offerGives * takerGives` tels us whether `p < p'`.
     */
    {
      uint offerWants = sor.offer.wants();
      uint offerGives = sor.offer.gives();
      uint takerWants = sor.wants;
      uint takerGives = sor.gives;
      /* <a id="MgvOfferTaking/checkPrice"></a>If the price is too high, we return early.

         Otherwise we now know we'll execute the offer. */
      if (offerWants * takerWants > offerGives * takerGives) {
        return (0, bytes32(0), "mgv/notExecuted");
      }

      /* ### Specification of value transfers:

      Let $o_w$ be `offerWants`, $o_g$ be `offerGives`, $t_w$ be `takerWants`, $t_g$ be `takerGives`, and `f ∈ {w,g}` be $w$ if `fillWants` is true, $g$ otherwise.

      Let $\textrm{got}$ be the amount that the taker will receive, and $\textrm{gave}$ be the amount that the taker will pay.

      #### Case $f = w$

      If $f = w$, let $\textrm{got} = \min(o_g,t_w)$, and let $\textrm{gave} = \left\lceil\dfrac{o_w \textrm{got}}{o_g}\right\rceil$. This is well-defined since, for live offers, $o_g > 0$.

      In plain english, we only give to the taker up to what they wanted (or what the offer has to give), and follow the offer price to determine what the taker will give.

      Since $\textrm{gave}$ is rounded up, the price might be overevaluated. Still, we cannot spend more than what the taker specified as `takerGives`. At this point [we know](#MgvOfferTaking/checkPrice) that $o_w t_w \leq o_g t_g$, so since $t_g$ is an integer we have
      
      $t_g \geq \left\lceil\dfrac{o_w t_w}{o_g}\right\rceil \geq \left\lceil\dfrac{o_w \textrm{got}}{o_g}\right\rceil = \textrm{gave}$.


      #### Case $f = g$

      If $f = g$, let $\textrm{gave} = \min(o_w,t_g)$, and $\textrm{got} = o_g$ if $o_w = 0$, $\textrm{got} = \left\lfloor\dfrac{o_g \textrm{gave}}{o_w}\right\rfloor$ otherwise.

      In plain english, we spend up to what the taker agreed to pay (or what the offer wants), and follow the offer price to determine what the taker will get. This may exceed $t_w$.

      #### Price adjustment

      Prices are rounded up to ensure maker is not drained on small amounts. It's economically unlikely, but `density` protects the taker from being drained anyway so it is better to default towards protecting the maker here.
      */

      /*
      ### Implementation

      First we check the cases $(f=w \wedge o_g < t_w)\vee(f_g \wedge o_w < t_g)$, in which case the above spec simplifies to $\textrm{got} = o_g, \textrm{gave} = o_w$.

      Otherwise the offer may be partially consumed.
      
      In the case $f=w$ we don't touch $\textrm{got}$ (which was initialized to $t_w$) and compute $\textrm{gave} = \left\lceil\dfrac{o_w t_w}{o_g}\right\rceil$. As shown above we have $\textrm{gave} \leq t_g$.

      In the case $f=g$ we don't touch $\textrm{gave}$ (which was initialized to $t_g$) and compute $\textrm{got} = o_g$ if $o_w = 0$, and $\textrm{got} = \left\lfloor\dfrac{o_g t_g}{o_w}\right\rfloor$ otherwise.
      */
      if (
        (mor.fillWants && offerGives < takerWants) ||
        (!mor.fillWants && offerWants < takerGives)
      ) {
        sor.wants = offerGives;
        sor.gives = offerWants;
      } else {
        if (mor.fillWants) {
          uint product = offerWants * takerWants;
          sor.gives =
            product /
            offerGives +
            (product % offerGives == 0 ? 0 : 1);
        } else {
          if (offerWants == 0) {
            sor.wants = offerGives;
          } else {
            sor.wants = (offerGives * takerGives) / offerWants;
          }
        }
      }
    }
    /* The flashloan is executed by call to `flashloan`. If the call reverts, it means the maker failed to send back `sor.wants` `outbound_tkn` to the taker. Notes :
     * `msg.sender` is the Mangrove itself in those calls -- all operations related to the actual caller should be done outside of this call.
     * any spurious exception due to an error in Mangrove code will be falsely blamed on the Maker, and its provision for the offer will be unfairly taken away.
     */
    (bool success, bytes memory retdata) = address(this).call(
      abi.encodeWithSelector(this.flashloan.selector, sor, mor.taker)
    );

    /* `success` is true: trade is complete */
    if (success) {
      /* In case of success, `retdata` encodes the gas used by the offer. */
      gasused = abi.decode(retdata, (uint));
      /* `mgvData` indicates trade success */
      mgvData = bytes32("mgv/tradeSuccess");
      emit OfferSuccess(
        sor.outbound_tkn,
        sor.inbound_tkn,
        sor.offerId,
        mor.taker,
        sor.wants,
        sor.gives
      );

      /* If configured to do so, the Mangrove notifies an external contract that a successful trade has taken place. */
      if (sor.global.notify()) {
        IMgvMonitor(sor.global.monitor()).notifySuccess(
          sor,
          mor.taker
        );
      }

      /* We update the totals in the multiorder based on the adjusted `sor.wants`/`sor.gives`. */
      /* overflow: sor.{wants,gives} are on 96bits, sor.total{Got,Gave} are on 256 bits. */
      mor.totalGot += sor.wants;
      mor.totalGave += sor.gives;
    } else {
      /* In case of failure, `retdata` encodes a short [status code](#MgvOfferTaking/statusCodes), the gas used by the offer, and an arbitrary 256 bits word sent by the maker.  */
      (mgvData, gasused, makerData) = innerDecode(retdata);
      /* Note that in the `if`s, the literals are bytes32 (stack values), while as revert arguments, they are strings (memory pointers). */
      if (
        mgvData == "mgv/makerRevert" ||
        mgvData == "mgv/makerAbort" ||
        mgvData == "mgv/makerTransferFail" ||
        mgvData == "mgv/makerReceiveFail"
      ) {

        emit OfferFail(
          sor.outbound_tkn,
          sor.inbound_tkn,
          sor.offerId,
          mor.taker,
          sor.wants,
          sor.gives,
          mgvData
        );

        /* If configured to do so, the Mangrove notifies an external contract that a failed trade has taken place. */
        if (sor.global.notify()) {
          IMgvMonitor(sor.global.monitor()).notifyFail(
            sor,
            mor.taker
          );
        }
        /* It is crucial that any error code which indicates an error caused by the taker triggers a revert, because functions that call `execute` consider that `mgvData` not in `["mgv/notExecuted","mgv/tradeSuccess"]` should be blamed on the maker. */
      } else if (mgvData == "mgv/notEnoughGasForMakerTrade") {
        revert("mgv/notEnoughGasForMakerTrade");
      } else if (mgvData == "mgv/takerTransferFail") {
        revert("mgv/takerTransferFail");
      } else {
        /* This code must be unreachable. **Danger**: if a well-crafted offer/maker pair can force a revert of `flashloan`, the Mangrove will be stuck. */
        revert("mgv/swapError");
      }
    }

    /* Delete the offer. The last argument indicates whether the offer should be stripped of its provision (yes if execution failed, no otherwise). We delete offers whether the amount remaining on offer is > density or not for the sake of uniformity (code is much simpler). We also expect prices to move often enough that the maker will want to update their price anyway. To simulate leaving the remaining volume in the offer, the maker can program their `makerPosthook` to `updateOffer` and put the remaining volume back in. */
    dirtyDeleteOffer(
      sor.outbound_tkn,
      sor.inbound_tkn,
      sor.offerId,
      sor.offer,
      sor.offerDetail,
      mgvData != "mgv/tradeSuccess"
    );
  }}

  /* ## flashloan (abstract) */
  /* Externally called by `execute`, flashloan lends money (from the taker to the maker, or from the maker to the taker, depending on the implementation) then calls `makerExecute` to run the maker liquidity fetching code. If `makerExecute` is unsuccessful, `flashloan` reverts (but the larger orderbook traversal will continue). 

  All `flashloan` implementations must `require(msg.sender) == address(this))`. */
  function flashloan(ML.SingleOrder calldata sor, address taker)
    external
    virtual
    returns (uint gasused);

  /* ## Maker Execute */
  /* Called by `flashloan`, `makerExecute` runs the maker code and checks that it can safely send the desired assets to the taker. */

  function makerExecute(ML.SingleOrder calldata sor)
    internal
    returns (uint gasused)
  { unchecked {
    bytes memory cd = abi.encodeWithSelector(IMaker.makerExecute.selector, sor);

    uint gasreq = sor.offerDetail.gasreq();
    address maker = sor.offerDetail.maker();
    uint oldGas = gasleft();
    /* We let the maker pay for the overhead of checking remaining gas and making the call, as well as handling the return data (constant gas since only the first 32 bytes of return data are read). So the `require` below is just an approximation: if the overhead of (`require` + cost of `CALL`) is $h$, the maker will receive at worst $\textrm{gasreq} - \frac{63h}{64}$ gas. */
    /* Note : as a possible future feature, we could stop an order when there's not enough gas left to continue processing offers. This could be done safely by checking, as soon as we start processing an offer, whether `63/64(gasleft-offer_gasbase) > gasreq`. If no, we could stop and know by induction that there is enough gas left to apply fees, stitch offers, etc for the offers already executed. */
    if (!(oldGas - oldGas / 64 >= gasreq)) {
      innerRevert([bytes32("mgv/notEnoughGasForMakerTrade"), "", ""]);
    }

    (bool callSuccess, bytes32 makerData) = controlledCall(maker, gasreq, cd);

    gasused = oldGas - gasleft();

    if (!callSuccess) {
      innerRevert([bytes32("mgv/makerRevert"), bytes32(gasused), makerData]);
    }

    /* Successful execution must have a returndata that begins with `bytes32("")`.
     */
    if (makerData != "") {
      innerRevert([bytes32("mgv/makerAbort"), bytes32(gasused), makerData]);
    }

    bool transferSuccess = transferTokenFrom(
      sor.outbound_tkn,
      maker,
      address(this),
      sor.wants
    );

    if (!transferSuccess) {
      innerRevert(
        [bytes32("mgv/makerTransferFail"), bytes32(gasused), makerData]
      );
    }
  }}

  /* ## executeEnd (abstract) */
  /* Called by `internalSnipes` and `internalMarketOrder`, `executeEnd` may run implementation-specific code after all makers have been called once. In [`InvertedMangrove`](#InvertedMangrove), the function calls the taker once so they can act on their flashloan. In [`Mangrove`], it does nothing. */
  function executeEnd(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    virtual;

  /* ## Post execute */
  /* At this point, we know `mgvData != "mgv/notExecuted"`. After executing an offer (whether in a market order or in snipes), we
     1. Call the maker's posthook and sum the total gas used.
     2. If offer failed: sum total penalty due to taker and give remainder to maker.
   */
  function postExecute(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    uint gasused,
    bytes32 makerData,
    bytes32 mgvData
  ) internal { unchecked {
    if (mgvData == "mgv/tradeSuccess") {
      beforePosthook(sor);
    }

    uint gasreq = sor.offerDetail.gasreq();

    /* We are about to call back the maker, giving it its unused gas (`gasreq - gasused`). Since the gas used so far may exceed `gasreq`, we prevent underflow in the subtraction below by bounding `gasused` above with `gasreq`. We could have decided not to call back the maker at all when there is no gas left, but we do it for uniformity. */
    if (gasused > gasreq) {
      gasused = gasreq;
    }

    gasused =
      gasused +
      makerPosthook(sor, gasreq - gasused, makerData, mgvData);

    if (mgvData != "mgv/tradeSuccess") {
      mor.totalPenalty += applyPenalty(sor, gasused);
    }
  }}

  /* ## beforePosthook (abstract) */
  /* Called by `makerPosthook`, this function can run implementation-specific code before calling the maker has been called a second time. In [`InvertedMangrove`](#InvertedMangrove), all makers are called once so the taker gets all of its money in one shot. Then makers are traversed again and the money is sent back to each taker using `beforePosthook`. In [`Mangrove`](#Mangrove), `beforePosthook` does nothing. */

  function beforePosthook(ML.SingleOrder memory sor) internal virtual;

  /* ## Maker Posthook */
  function makerPosthook(
    ML.SingleOrder memory sor,
    uint gasLeft,
    bytes32 makerData,
    bytes32 mgvData
  ) internal returns (uint gasused) { unchecked {
    /* At this point, mgvData can only be `"mgv/tradeSuccess"`, `"mgv/makerAbort"`, `"mgv/makerRevert"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"` */
    bytes memory cd = abi.encodeWithSelector(
      IMaker.makerPosthook.selector,
      sor,
      ML.OrderResult({makerData: makerData, mgvData: mgvData})
    );

    address maker = sor.offerDetail.maker();

    uint oldGas = gasleft();
    /* We let the maker pay for the overhead of checking remaining gas and making the call. So the `require` below is just an approximation: if the overhead of (`require` + cost of `CALL`) is $h$, the maker will receive at worst $\textrm{gasreq} - \frac{63h}{64}$ gas. */
    if (!(oldGas - oldGas / 64 >= gasLeft)) {
      revert("mgv/notEnoughGasForMakerPosthook");
    }

    (bool callSuccess, ) = controlledCall(maker, gasLeft, cd);

    gasused = oldGas - gasleft();

    if (!callSuccess) {
      emit PosthookFail(sor.outbound_tkn, sor.inbound_tkn, sor.offerId);
    }
  }}

  /* ## `controlledCall` */
  /* Calls an external function with controlled gas expense. A direct call of the form `(,bytes memory retdata) = maker.call{gas}(selector,...args)` enables a griefing attack: the maker uses half its gas to write in its memory, then reverts with that memory segment as argument. After a low-level call, solidity automaticaly copies `returndatasize` bytes of `returndata` into memory. So the total gas consumed to execute a failing offer could exceed `gasreq + offer_gasbase` where `n` is the number of failing offers. This yul call only retrieves the first 32 bytes of the maker's `returndata`. */
  function controlledCall(
    address callee,
    uint gasreq,
    bytes memory cd
  ) internal returns (bool success, bytes32 data) { unchecked {
    bytes32[1] memory retdata;

    assembly {
      success := call(gasreq, callee, 0, add(cd, 32), mload(cd), retdata, 32)
    }

    data = retdata[0];
  }}

  /* # Penalties */
  /* Offers are just promises. They can fail. Penalty provisioning discourages from failing too much: we ask makers to provision more ETH than the expected gas cost of executing their offer and penalize them accoridng to wasted gas.

     Under normal circumstances, we should expect to see bots with a profit expectation dry-running offers locally and executing `snipe` on failing offers, collecting the penalty. The result should be a mostly clean book for actual takers (i.e. a book with only successful offers).

     **Incentive issue**: if the gas price increases enough after an offer has been created, there may not be an immediately profitable way to remove the fake offers. In that case, we count on 3 factors to keep the book clean:
     1. Gas price eventually comes down.
     2. Other market makers want to keep the Mangrove attractive and maintain their offer flow.
     3. Mangrove governance (who may collect a fee) wants to keep the Mangrove attractive and maximize exchange volume. */

  //+clear+
  /* After an offer failed, part of its provision is given back to the maker and the rest is stored to be sent to the taker after the entire order completes. In `applyPenalty`, we _only_ credit the maker with its excess provision. So it looks like the maker is gaining something. In fact they're just getting back a fraction of what they provisioned earlier. */
  /*
     Penalty application summary:

   * If the transaction was a success, we entirely refund the maker and send nothing to the taker.
   * Otherwise, the maker loses the cost of `gasused + offer_gasbase` gas. The gas price is estimated by `gasprice`.
   * To create the offer, the maker had to provision for `gasreq + offer_gasbase` gas at a price of `offerDetail.gasprice`.
   * We do not consider the tx.gasprice.
   * `offerDetail.gasbase` and `offerDetail.gasprice` are the values of the Mangrove parameters `config.offer_gasbase` and `config.gasprice` when the offer was created. Without caching those values, the provision set aside could end up insufficient to reimburse the maker (or to retribute the taker).
   */
  function applyPenalty(
    ML.SingleOrder memory sor,
    uint gasused
  ) internal returns (uint) { unchecked {
    uint gasreq = sor.offerDetail.gasreq();

    uint provision = 10**9 *
      sor.offerDetail.gasprice() * 
      (gasreq + sor.offerDetail.offer_gasbase());

    /* We set `gasused = min(gasused,gasreq)` since `gasreq < gasused` is possible e.g. with `gasreq = 0` (all calls consume nonzero gas). */
    if (gasused > gasreq) {
      gasused = gasreq;
    }

    /* As an invariant, `applyPenalty` is only called when `mgvData` is not in `["mgv/notExecuted","mgv/tradeSuccess"]` */
    uint penalty = 10**9 *
      sor.global.gasprice() *
      (gasused +
        sor.local.offer_gasbase());

    if (penalty > provision) {
      penalty = provision;
    }

    /* Here we write to storage the new maker balance. This occurs _after_ possible reentrant calls. How do we know we're not crediting twice the same amounts? Because the `offer`'s provision was set to 0 in storage (through `dirtyDeleteOffer`) before the reentrant calls. In this function, we are working with cached copies of the offer as it was before it was consumed. */
    creditWei(sor.offerDetail.maker(), provision - penalty);

    return penalty;
  }}

  function sendPenalty(uint amount) internal { unchecked {
    if (amount > 0) {
      (bool noRevert, ) = msg.sender.call{value: amount}("");
      require(noRevert, "mgv/sendPenaltyReverted");
    }
  }}

  /* Post-trade, `payTakerMinusFees` sends what's due to the taker and the rest (the fees) to the vault. Routing through the Mangrove like that also deals with blacklisting issues (separates the maker-blacklisted and the taker-blacklisted cases). */
  function payTakerMinusFees(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
  { unchecked {
    /* Should be statically provable that the 2 transfers below cannot return false under well-behaved ERC20s and a non-blacklisted, non-0 target. */

    uint concreteFee = (mor.totalGot * sor.local.fee()) / 10_000;
    if (concreteFee > 0) {
      mor.totalGot -= concreteFee;
      require(
        transferToken(sor.outbound_tkn, vault, concreteFee),
        "mgv/feeTransferFail"
      );
    }
    if (mor.totalGot > 0) {
      require(
        transferToken(sor.outbound_tkn, mor.taker, mor.totalGot),
        "mgv/MgvFailToPayTaker"
      );
    }
  }}

  /* # Misc. functions */

  /* Regular solidity reverts prepend the string argument with a [function signature](https://docs.soliditylang.org/en/v0.7.6/control-structures.html#revert). Since we wish to transfer data through a revert, the `innerRevert` function does a low-level revert with only the required data. `innerCode` decodes this data. */
  function innerDecode(bytes memory data)
    internal
    pure
    returns (
      bytes32 mgvData,
      uint gasused,
      bytes32 makerData
    )
  { unchecked {
    /* The `data` pointer is of the form `[mgvData,gasused,makerData]` where each array element is contiguous and has size 256 bits. */
    assembly {
      mgvData := mload(add(data, 32))
      gasused := mload(add(data, 64))
      makerData := mload(add(data, 96))
    }
  }}

  /* <a id="MgvOfferTaking/innerRevert"></a>`innerRevert` reverts a raw triple of values to be interpreted by `innerDecode`.    */
  function innerRevert(bytes32[3] memory data) internal pure { unchecked {
    assembly {
      revert(data, 96)
    }
  }}

  /* `transferTokenFrom` is adapted from [existing code](https://soliditydeveloper.com/safe-erc20) and in particular avoids the
  "no return value" bug. It never throws and returns true iff the transfer was successful according to `tokenAddress`.

    Note that any spurious exception due to an error in Mangrove code will be falsely blamed on `from`.
  */
  function transferTokenFrom(
    address tokenAddress,
    address from,
    address to,
    uint value
  ) internal returns (bool) { unchecked {
    bytes memory cd = abi.encodeWithSelector(
      IERC20.transferFrom.selector,
      from,
      to,
      value
    );
    (bool noRevert, bytes memory data) = tokenAddress.call(cd);
    return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
  }}

  function transferToken(
    address tokenAddress,
    address to,
    uint value
  ) internal returns (bool) { unchecked {
    bytes memory cd = abi.encodeWithSelector(
      IERC20.transfer.selector,
      to,
      value
    );
    (bool noRevert, bytes memory data) = tokenAddress.call(cd);
    return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "../AbstractMangrove.sol";
import "hardhat/console.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";

// In these tests, the testing contract is the market maker.
contract Vault_Test {
  receive() external payable {}

  AbstractMangrove mgv;
  TestMaker mkr;
  address base;
  address quote;

  function a_beforeAll() public {
    TestToken baseT = TokenSetup.setup("A", "$A");
    TestToken quoteT = TokenSetup.setup("B", "$B");
    base = address(baseT);
    quote = address(quoteT);
    mgv = MgvSetup.setup(baseT, quoteT);
    mkr = MakerSetup.setup(mgv, base, quote);

    payable(mkr).transfer(10 ether);

    mkr.provisionMgv(5 ether);
    bool noRevert;
    (noRevert, ) = address(mgv).call{value: 10 ether}("");

    baseT.mint(address(mkr), 2 ether);
    quoteT.mint(address(this), 2 ether);

    baseT.approve(address(mgv), 1 ether);
    quoteT.approve(address(mgv), 1 ether);

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "Test Contract");
    Display.register(base, "$A");
    Display.register(quote, "$B");
    Display.register(address(mgv), "mgv");
    Display.register(address(mkr), "maker[$A,$B]");
  }

  function initial_vault_value_test() public {
    TestEvents.eq(
      mgv.vault(),
      address(this),
      "initial vault value should be mgv creator"
    );
  }

  function gov_can_set_vault_test() public {
    mgv.setVault(address(0));
    TestEvents.eq(mgv.vault(), address(0), "gov should be able to set vault");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
// Encode structs
pragma abicoder v2;

import "../Agents/TestTaker.sol";
import "../Agents/MakerDeployer.sol";
import "../Agents/TestMoriartyMaker.sol";
import "../Agents/TestToken.sol";

import {Display, Test as TestEvents} from "@giry/hardhat-test-solidity/test.sol";
import "../../InvertedMangrove.sol";
import "../../Mangrove.sol";
import "../../MgvLib.sol";

library TestUtils {
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  /* Various utilities */

  function uint2str(uint _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    unchecked {
      if (_i == 0) {
        return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
        len++;
        j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len - 1;
      while (_i != 0) {
        bstr[k--] = bytes1(uint8(48 + (_i % 10)));
        _i /= 10;
      }
      return string(bstr);
    }
  }

  function append(string memory a, string memory b)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(a, b));
  }

  function append(
    string memory a,
    string memory b,
    string memory c
  ) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b, c));
  }

  function append(
    string memory a,
    string memory b,
    string memory c,
    string memory d
  ) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b, c, d));
  }

  function toEthUnits(uint w, string memory units)
    internal
    pure
    returns (string memory eth)
  {
    string memory suffix = append(" ", units);

    if (w == 0) {
      return (append("0", suffix));
    }
    uint i = 0;
    while (w % 10 == 0) {
      w = w / 10;
      i += 1;
    }
    if (i >= 18) {
      w = w * (10**(i - 18));
      return append(uint2str(w), suffix);
    } else {
      uint zeroBefore = 18 - i;
      string memory zeros = "";
      while (zeroBefore > 1) {
        zeros = append(zeros, "0");
        zeroBefore--;
      }
      return (append("0.", zeros, uint2str(w), suffix));
    }
  }

  /* Log offer book */

  event OBState(
    address base,
    address quote,
    uint[] offerIds,
    uint[] wants,
    uint[] gives,
    address[] makerAddr,
    uint[] gasreqs
  );

  /** Two different OB logging methods.
   *
   *  `logOfferBook` will be well-interlaced with tests so you can easily see what's going on.
   *
   *  `printOfferBook` will survive reverts so you can log inside a reverting call.
   */

  /* Log OB with events and hardhat-test-solidity */
  function logOfferBook(
    AbstractMangrove mgv,
    address base,
    address quote,
    uint size
  ) internal {
    uint offerId = mgv.best(base, quote);

    uint[] memory wants = new uint[](size);
    uint[] memory gives = new uint[](size);
    address[] memory makerAddr = new address[](size);
    uint[] memory offerIds = new uint[](size);
    uint[] memory gasreqs = new uint[](size);
    uint c = 0;
    while ((offerId != 0) && (c < size)) {
      (P.OfferStruct memory offer, P.OfferDetailStruct memory od) = mgv.offerInfo(
        base,
        quote,
        offerId
      );
      wants[c] = offer.wants;
      gives[c] = offer.gives;
      makerAddr[c] = od.maker;
      offerIds[c] = offerId;
      gasreqs[c] = od.gasreq;
      offerId = offer.next;
      c++;
    }
    emit OBState(base, quote, offerIds, wants, gives, makerAddr, gasreqs);
  }

  /* Log OB with hardhat's console.log */
  function printOfferBook(
    AbstractMangrove mgv,
    address base,
    address quote
  ) internal view {
    uint offerId = mgv.best(base, quote);
    TestToken req_tk = TestToken(quote);
    TestToken ofr_tk = TestToken(base);

    console.log("-----Best offer: %d-----", offerId);
    while (offerId != 0) {
      (P.OfferStruct memory ofr, ) = mgv.offerInfo(base, quote, offerId);
      console.log(
        "[offer %d] %s/%s",
        offerId,
        TestUtils.toEthUnits(ofr.wants, req_tk.symbol()),
        TestUtils.toEthUnits(ofr.gives, ofr_tk.symbol())
      );
      // console.log(
      //   "(%d gas, %d to finish, %d penalty)",
      //   gasreq,
      //   minFinishGas,
      //   gasprice
      // );
      // console.log(name(makerAddr));
      offerId = ofr.next;
    }
    console.log("-----------------------");
  }

  /* Additional testing functions */

  function revertEq(string memory actual_reason, string memory expected_reason)
    internal
    returns (bool)
  {
    return TestEvents.eq(actual_reason, expected_reason, "wrong revert reason");
  }

  event TestNot0x(bool success, address addr);

  function not0x(address actual) internal returns (bool) {
    bool success = actual != address(0);
    emit TestNot0x(success, actual);
    return success;
  }

  event GasCost(string callname, uint value);

  function execWithCost(
    string memory callname,
    address addr,
    bytes memory data
  ) internal returns (bytes memory) {
    uint g0 = gasleft();
    (bool noRevert, bytes memory retdata) = addr.delegatecall(data);
    require(noRevert, "execWithCost should not revert");
    emit GasCost(callname, g0 - gasleft());
    return retdata;
  }

  struct Balances {
    uint mgvBalanceWei;
    uint mgvBalanceFees;
    uint takerBalanceA;
    uint takerBalanceB;
    uint takerBalanceWei;
    uint[] makersBalanceA;
    uint[] makersBalanceB;
    uint[] makersBalanceWei;
  }
  enum Info {
    makerWants,
    makerGives,
    nextId,
    gasreqreceive_on,
    gasprice,
    gasreq
  }

  function getReason(bytes memory returnData)
    internal
    pure
    returns (string memory reason)
  {
    /* returnData for a revert(reason) is the result of
       abi.encodeWithSignature("Error(string)",reason)
       but abi.decode assumes the first 4 bytes are padded to 32
       so we repad them. See:
       https://github.com/ethereum/solidity/issues/6012
     */
    bytes memory pointer = abi.encodePacked(bytes28(0), returnData);
    uint len = returnData.length - 4;
    assembly {
      pointer := add(32, pointer)
      mstore(pointer, len)
    }
    reason = abi.decode(pointer, (string));
  }

  function isEmptyOB(
    AbstractMangrove mgv,
    address base,
    address quote
  ) internal view returns (bool) {
    return mgv.best(base, quote) == 0;
  }

  function adminOf(AbstractMangrove mgv) internal view returns (address) {
    return mgv.governance();
  }

  function getFee(
    AbstractMangrove mgv,
    address base,
    address quote,
    uint price
  ) internal view returns (uint) {
    (, P.Local.t local) = mgv.config(base, quote);
    return ((price * local.fee()) / 10000);
  }

  function getProvision(
    AbstractMangrove mgv,
    address base,
    address quote,
    uint gasreq
  ) internal view returns (uint) {
    (P.Global.t glo_cfg, P.Local.t loc_cfg) = mgv.config(base, quote);
    return ((gasreq + loc_cfg.offer_gasbase()) *
      uint(glo_cfg.gasprice()) *
      10**9);
  }

  function getProvision(
    AbstractMangrove mgv,
    address base,
    address quote,
    uint gasreq,
    uint gasprice
  ) internal view returns (uint) {
    (P.Global.t glo_cfg, P.Local.t loc_cfg) = mgv.config(base, quote);
    uint _gp;
    if (glo_cfg.gasprice() > gasprice) {
      _gp = uint(glo_cfg.gasprice());
    } else {
      _gp = gasprice;
    }
    return ((gasreq +
      loc_cfg.offer_gasbase()) *
      _gp *
      10**9);
  }

  function getOfferInfo(
    AbstractMangrove mgv,
    address base,
    address quote,
    Info infKey,
    uint offerId
  ) internal view returns (uint) {
    (P.OfferStruct memory offer, P.OfferDetailStruct memory offerDetail) = mgv.offerInfo(
      base,
      quote,
      offerId
    );
    if (!mgv.isLive(mgv.offers(base, quote, offerId))) {
      return 0;
    }
    if (infKey == Info.makerWants) {
      return offer.wants;
    }
    if (infKey == Info.makerGives) {
      return offer.gives;
    }
    if (infKey == Info.nextId) {
      return offer.next;
    }
    if (infKey == Info.gasreq) {
      return offerDetail.gasreq;
    } else {
      return offerDetail.gasprice;
    }
  }

  function hasOffer(
    AbstractMangrove mgv,
    address base,
    address quote,
    uint offerId
  ) internal view returns (bool) {
    return (getOfferInfo(mgv, base, quote, Info.makerGives, offerId) > 0);
  }

  function makerOf(
    AbstractMangrove mgv,
    address base,
    address quote,
    uint offerId
  ) internal view returns (address) {
    (, P.OfferDetailStruct memory od) = mgv.offerInfo(base, quote, offerId);
    return od.maker;
  }
}

// Pretest libraries are for deploying large contracts independently.
// Otherwise bytecode can be too large. See EIP 170 for more on size limit:
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-170.md

library TokenSetup {
  function setup(string memory name, string memory ticker)
    public
    returns (TestToken)
  {
    return new TestToken(address(this), name, ticker);
  }
}

library MgvSetup {
  function deploy(address governance) public returns (AbstractMangrove mgv) {
    mgv = new Mangrove({
      governance: governance,
      gasprice: 40,
      gasmax: 1_000_000
    });
  }

  function invertedDeploy(address governance)
    public
    returns (AbstractMangrove mgv)
  {
    mgv = new InvertedMangrove({
      governance: governance,
      gasprice: 40,
      gasmax: 1_000_000
    });
  }

  function setup(TestToken base, TestToken quote)
    public
    returns (AbstractMangrove)
  {
    return setup(base, quote, false);
  }

  function setup(
    TestToken base,
    TestToken quote,
    bool inverted
  ) public returns (AbstractMangrove mgv) {
    TestUtils.not0x(address(base));
    TestUtils.not0x(address(quote));
    if (inverted) {
      mgv = invertedDeploy(address(this));
    } else {
      mgv = deploy(address(this));
    }
    mgv.activate(address(base), address(quote), 0, 100, 20_000);
    mgv.activate(address(quote), address(base), 0, 100, 20_000);
  }
}

library MakerSetup {
  function setup(
    AbstractMangrove mgv,
    address base,
    address quote,
    uint failer // 1 shouldFail, 2 shouldRevert
  ) external returns (TestMaker) {
    TestMaker tm = new TestMaker(mgv, IERC20(base), IERC20(quote));
    tm.shouldFail(failer == 1);
    tm.shouldRevert(failer == 2);
    return (tm);
  }

  function setup(
    AbstractMangrove mgv,
    address base,
    address quote
  ) external returns (TestMaker) {
    return new TestMaker(mgv, IERC20(base), IERC20(quote));
  }
}

library MakerDeployerSetup {
  function setup(
    AbstractMangrove mgv,
    address base,
    address quote
  ) external returns (MakerDeployer) {
    TestUtils.not0x(address(mgv));
    return (new MakerDeployer(mgv, base, quote));
  }
}

library TakerSetup {
  function setup(
    AbstractMangrove mgv,
    address base,
    address quote
  ) external returns (TestTaker) {
    TestUtils.not0x(address(mgv));
    return new TestTaker(mgv, IERC20(base), IERC20(quote));
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;

import "./TestTokenWithDecimals.sol";

contract TestToken is TestTokenWithDecimals {
  constructor(
    address admin,
    string memory name,
    string memory symbol
  ) TestTokenWithDecimals(admin, name, symbol, 18) {}
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;
import "../../AbstractMangrove.sol";
import "./OfferManager.sol";

contract TestTaker is ITaker {
  AbstractMangrove _mgv;
  address _base;
  address _quote;

  constructor(
    AbstractMangrove mgv,
    IERC20 base,
    IERC20 quote
  ) {
    _mgv = mgv;
    _base = address(base);
    _quote = address(quote);
  }

  receive() external payable {}

  function approveMgv(IERC20 token, uint amount) external {
    token.approve(address(_mgv), amount);
  }

  function approveSpender(address spender, uint amount) external {
    _mgv.approve(_base, _quote, spender, amount);
  }

  function take(uint offerId, uint takerWants) external returns (bool success) {
    //uint taken = TestEvents.min(makerGives, takerWants);
    (success, , ) = this.takeWithInfo(offerId, takerWants);
  }

  function takeWithInfo(uint offerId, uint takerWants)
    external
    returns (
      bool,
      uint,
      uint
    )
  {
    //uint taken = TestEvents.min(makerGives, takerWants);
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [offerId, takerWants, type(uint96).max, type(uint48).max];
    (uint successes, uint got, uint gave, ) = _mgv.snipes(
      _base,
      _quote,
      targets,
      true
    );
    return (successes == 1, got, gave);
    //return taken;
  }

  function snipe(
    AbstractMangrove __mgv,
    address __base,
    address __quote,
    uint offerId,
    uint takerWants,
    uint takerGives,
    uint gasreq
  ) external returns (bool) {
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [offerId, takerWants, takerGives, gasreq];
    (uint successes, , , ) = __mgv.snipes(__base, __quote, targets, true);
    return successes == 1;
  }

  function takerTrade(
    address,
    address,
    uint,
    uint
  ) external pure override {}

  function marketOrder(uint wants, uint gives)
    external
    returns (uint takerGot, uint takerGave)
  {
    (takerGot, takerGave, ) = _mgv.marketOrder(
      _base,
      _quote,
      wants,
      gives,
      true
    );
  }

  function marketOrder(
    AbstractMangrove __mgv,
    address __base,
    address __quote,
    uint takerWants,
    uint takerGives
  ) external returns (uint takerGot, uint takerGave) {
    (takerGot, takerGave, ) = __mgv.marketOrder(
      __base,
      __quote,
      takerWants,
      takerGives,
      true
    );
  }

  function marketOrderWithFail(uint wants, uint gives)
    external
    returns (uint takerGot, uint takerGave)
  {
    (takerGot, takerGave, ) = _mgv.marketOrder(
      _base,
      _quote,
      wants,
      gives,
      true
    );
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;

import "../../Mangrove.sol";
import "./TestMaker.sol";
import "./TestToken.sol";
import "hardhat/console.sol";

//import "./TestMaker.sol";
//import "./TestToken.sol";

contract MakerDeployer {
  address payable[] makers;
  bool deployed;
  AbstractMangrove mgv;
  address base;
  address quote;

  constructor(
    AbstractMangrove _mgv,
    address _base,
    address _quote
  ) {
    mgv = _mgv;
    base = _base;
    quote = _quote;
  }

  receive() external payable {
    uint k = makers.length;
    uint perMaker = msg.value / k;
    require(perMaker > 0, "0 ether to transfer");
    for (uint i = 0; i < k; i++) {
      address payable maker = makers[i];
      bool ok = maker.send(perMaker);
      require(ok);
    }
  }

  function length() external view returns (uint) {
    return makers.length;
  }

  function getMaker(uint i) external view returns (TestMaker) {
    return TestMaker(makers[i]);
  }

  function deploy(uint k) external {
    if (!deployed) {
      makers = new address payable[](k);
      for (uint i = 0; i < k; i++) {
        makers[i] = payable(
          address(new TestMaker(mgv, TestToken(base), TestToken(quote)))
        );
        TestMaker(makers[i]).approveMgv(TestToken(base), 10 ether);
        TestMaker(makers[i]).shouldFail(i == 0); //maker-0 is failer
      }
    }
    deployed = true;
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./Passthrough.sol";
import "../../AbstractMangrove.sol";
import "../../MgvLib.sol";

contract TestMoriartyMaker is IMaker, Passthrough {
  using P.Local for P.Local.t;

  AbstractMangrove mgv;
  address base;
  address quote;
  bool succeed;
  uint dummy;

  constructor(
    AbstractMangrove _mgv,
    address _base,
    address _quote
  ) {
    mgv = _mgv;
    base = _base;
    quote = _quote;
    succeed = true;
  }

  function makerExecute(ML.SingleOrder calldata order)
    public
    override
    returns (bytes32 ret)
  {
    bool _succeed = succeed;
    if (order.offerId == dummy) {
      succeed = false;
    }
    if (_succeed) {
      ret = "";
    } else {
      assert(false);
    }
  }

  function makerPosthook(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) external override {}

  function newOffer(
    uint wants,
    uint gives,
    uint gasreq,
    uint pivotId
  ) public {
    mgv.newOffer(base, quote, wants, gives, gasreq, 0, pivotId);
    mgv.newOffer(base, quote, wants, gives, gasreq, 0, pivotId);
    mgv.newOffer(base, quote, wants, gives, gasreq, 0, pivotId);
    mgv.newOffer(base, quote, wants, gives, gasreq, 0, pivotId);
    (, P.Local.t cfg) = mgv.config(base, quote);
    uint density = cfg.density();
    uint offer_gasbase = cfg.offer_gasbase();
    dummy = mgv.newOffer({
      outbound_tkn: base,
      inbound_tkn: quote,
      wants: 1,
      gives: density * (offer_gasbase + 100000),
      gasreq: 100000,
      gasprice: 0,
      pivotId: 0
    }); //dummy offer
  }

  function provisionMgv(uint amount) public {
    (bool success, ) = address(mgv).call{value: amount}("");
    require(success);
  }

  function approveMgv(IERC20 token, uint amount) public {
    token.approve(address(mgv), amount);
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// Should be kept in sync with ./lib.js

library Test {
  /* 
   * Expect events from contracts
   */
  event ExpectFrom(address from);
  event StopExpecting();

  // Usage: from a test contract `t`, call `expectFrom(a)`. 
  // Any subsequent non-special event emitted by `t` will mean 
  // "I expect `a` to emit the exact same event". 
  // The order of expectations must be respected.
  function expectFrom(address from) internal {
    emit ExpectFrom(from);
  }

  // After using `expectFrom` and emitting some events you expect
  // to see emitted elsewhere, you can use `stopExpecting` to emit 
  // further, normal events from your test.
  function stopExpecting() internal {
    emit StopExpecting();
  }


  /* 
   * Boolean test
   */
  event TestTrue(bool success, string message);

  // Succeed iff success is true
  function check(bool success, string memory message) internal {
    emit TestTrue(success, message);
  }


  /* 
   * Always fail, always succeed
   */
  function fail(string memory message) internal {
    emit TestTrue(false, message);
  }

  function succeed() internal {
    emit TestTrue(true, "Success");
  }

  /* 
   * Equality testing
   * ! overloaded as `eq` for everything except for bytes use `eq0`.
   */

  // Bytes
  event TestEqBytes(bool success, bytes actual, bytes expected, string message);

  function eq0(
    bytes memory actual,
    bytes memory expected,
    string memory message
  ) internal returns (bool) {
    bool success = keccak256((actual)) == keccak256((expected));
    emit TestEqBytes(success, actual, expected, message);
    return success;
  }

   // Byte32
  event TestEqBytes32(
    bool success,
    bytes32 actual,
    bytes32 expected,
    string message
  );

  function eq(
    bytes32 actual,
    bytes32 expected,
    string memory message
  ) internal returns (bool) {
    bool success = (actual == expected);
    emit TestEqBytes32(success, actual, expected, message);
    return success;
  }

  // Bool
  event TestEqBool(bool success, bool actual, bool expected, string message);
  function eq(
    bool actual,
    bool expected,
    string memory message
  ) internal returns (bool) {
    bool success = (actual == expected);
    emit TestEqBool(success, actual, expected, message);
    return success;
  }

  // uints
  event TestEqUint(bool success, uint actual, uint expected, string message);

  function eq(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual == expected;
    emit TestEqUint(success, actual, expected, message);
    return success;
  }

  // strings
  event TestEqString(
    bool success,
    string actual,
    string expected,
    string message
  );

  function eq(
    string memory actual,
    string memory expected,
    string memory message
  ) internal returns (bool) {
    bool success = keccak256(bytes((actual))) == keccak256(bytes((expected)));
    emit TestEqString(success, actual, expected, message);
    return success;
  }

  // addresses
  event TestEqAddress(
    bool success,
    address actual,
    address expected,
    string message
  );


  function eq(
    address actual,
    address expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual == expected;
    emit TestEqAddress(success, actual, expected, message);
    return success;
  }

  /* 
   * Inequality testing
   */
  event TestLess(bool success, uint actual, uint expected, string message);
  function less(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual < expected;
    emit TestLess(success, actual, expected, message);
    return success;
  }

  function more(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual > expected;
    emit TestLess(success, actual, expected, message);
    return success;
  }
}

// /* Either cast your arguments to address when you call balanceOf logging functions
//    or add `is address` to your ERC20s
//    or use the overloads with `address` types */
interface ERC20BalanceOf {
  function balanceOf(address account) view external returns (uint);
}


library Display {
  /* ****************************************************************
   * Register/read address->name mappings to make logs easier to read.
   *****************************************************************/
  /* 
   * Names are stored in the contract using the library.
   */

  // Disgusting hack so a library can manipulate storage refs.
  bytes32 constant NAMES_POS = keccak256("Display.NAMES_POS");
  // Store mapping in library caller's storage.
  // That's quite fragile.
  struct Registers {
    mapping(address => string) map;
  }

  // Also send mapping to javascript test interpreter.  The interpreter COULD
  // just make an EVM call to map every name but that would probably be very
  // slow.  So we cache locally.
  event Register(address addr, string name);

  function registers() internal view returns (Registers storage) {
    this; // silence warning about pure mutability
    Registers storage regs;
    bytes32 _slot = NAMES_POS;
    assembly {
      regs.slot := _slot
    }
    return regs;
  }

  /*
   * Give a name to an address for logging purposes
   * @example
   * ```solidity
   * address addr = address(new Contract());
   * register(addr,"My Contract instance");
   * ```
   */

  function register(address addr, string memory name) internal {
    registers().map[addr] = name;
    emit Register(addr, name);
  }

  /*
   * Read the name of a registered address. Default: "<not found>". 
   */
  function nameOf(address addr) internal view returns (string memory) {
    string memory s = registers().map[addr];
    if (keccak256(bytes(s)) != keccak256(bytes(""))) {
      return s;
    } else {
      return "<not found>";
    }
  }

  /* 1 arg logging (string/uint) */

  event LogString(string a);

  function log(string memory a) internal {
    emit LogString(a);
  }

  event LogUint(uint a);

  function log(uint a) internal {
    emit LogUint(a);
  }

  /* 2 arg logging (string/uint) */

  event LogStringString(string a, string b);

  function log(string memory a, string memory b) internal {
    emit LogStringString(a, b);
  }

  event LogStringUint(string a, uint b);

  function log(string memory a, uint b) internal {
    emit LogStringUint(a, b);
  }

  event LogUintUint(uint a, uint b);

  function log(uint a, uint b) internal {
    emit LogUintUint(a, b);
  }

  event LogUintString(uint a, string b);

  function log(uint a, string memory b) internal {
    emit LogUintString(a, b);
  }

  /* 3 arg logging (string/uint) */

  event LogStringStringString(string a, string b, string c);

  function log(
    string memory a,
    string memory b,
    string memory c
  ) internal {
    emit LogStringStringString(a, b, c);
  }

  event LogStringStringUint(string a, string b, uint c);

  function log(
    string memory a,
    string memory b,
    uint c
  ) internal {
    emit LogStringStringUint(a, b, c);
  }

  event LogStringUintUint(string a, uint b, uint c);

  function log(
    string memory a,
    uint b,
    uint c
  ) internal {
    emit LogStringUintUint(a, b, c);
  }

  event LogStringUintString(string a, uint b, string c);

  function log(
    string memory a,
    uint b,
    string memory c
  ) internal {
    emit LogStringUintString(a, b, c);
  }

  event LogUintUintUint(uint a, uint b, uint c);

  function log(
    uint a,
    uint b,
    uint c
  ) internal {
    emit LogUintUintUint(a, b, c);
  }

  event LogUintStringUint(uint a, string b, uint c);

  function log(
    uint a,
    string memory b,
    uint c
  ) internal {
    emit LogUintStringUint(a, b, c);
  }

  event LogUintStringString(uint a, string b, string c);

  function log(
    uint a,
    string memory b,
    string memory c
  ) internal {
    emit LogUintStringString(a, b, c);
  }

  /* End of register/read section */
  event ERC20Balances(address[] tokens, address[] accounts, uint[] balances);

  function logBalances(
    address[1] memory _tokens, 
    address _a0
  ) internal {
    address[] memory tokens = new address[](1);
    tokens[0] = _tokens[0];
    address[] memory accounts = new address[](1);
    accounts[0] = _a0;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[1] memory _tokens,
    address _a0,
    address _a1
  ) internal {
    address[] memory tokens = new address[](1);
    tokens[0] = _tokens[0];
    address[] memory accounts = new address[](2);
    accounts[0] = _a0;
    accounts[1] = _a1;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[1] memory _tokens,
    address _a0,
    address _a1,
    address _a2
  ) internal {
    address[] memory tokens = new address[](1);
    tokens[0] = _tokens[0];
    address[] memory accounts = new address[](3);
    accounts[0] = _a0;
    accounts[1] = _a1;
    accounts[2] = _a2;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[2] memory _tokens,
    address _a0
  ) internal {
    address[] memory tokens = new address[](2);
    tokens[0] = _tokens[0];
    tokens[1] = _tokens[1];
    address[] memory accounts = new address[](1);
    accounts[0] = _a0;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[2] memory _tokens,
    address _a0,
    address _a1
  ) internal {
    address[] memory tokens = new address[](2);
    tokens[0] = _tokens[0];
    tokens[1] = _tokens[1];
    address[] memory accounts = new address[](2);
    accounts[0] = _a0;
    accounts[1] = _a1;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[2] memory _tokens,
    address _a0,
    address _a1,
    address _a2
  ) internal {
    address[] memory tokens = new address[](2);
    tokens[0] = _tokens[0];
    tokens[1] = _tokens[1];
    address[] memory accounts = new address[](3);
    accounts[0] = _a0;
    accounts[1] = _a1;
    accounts[2] = _a2;
    logBalances(tokens, accounts);
  }

  /* takes [t1,...,tM], [a1,...,aN]
       logs also [...b(t1,aj) ... b(tM,aj) ...] */

  function logBalances(address[] memory tokens, address[] memory accounts)
    internal
  {
    uint[] memory balances = new uint[](tokens.length * accounts.length);
    for (uint i = 0; i < tokens.length; i++) {
      for (uint j = 0; j < accounts.length; j++) {
        uint bal = ERC20BalanceOf(tokens[i]).balanceOf(accounts[j]);
        balances[i * accounts.length + j] = bal;
        //console.log(tokens[i].symbol(),nameOf(accounts[j]),bal);
      }
    }
    emit ERC20Balances(tokens, accounts, balances);
  }

}

// SPDX-License-Identifier:	AGPL-3.0

// InvertedMangrove.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {ITaker, MgvLib as ML, P} from "./MgvLib.sol";

import {AbstractMangrove} from "./AbstractMangrove.sol";

/* <a id="InvertedMangrove"></a> The `InvertedMangrove` contract implements the "inverted" version of Mangrove, where each maker loans money to the taker. The taker is then called, and finally each maker is sent its payment and called again (with the orderbook unlocked). */
contract InvertedMangrove is AbstractMangrove {
  // prettier-ignore
  using P.OfferDetail for P.OfferDetail.t;
  constructor(
    address governance,
    uint gasprice,
    uint gasmax
  ) AbstractMangrove(governance, gasprice, gasmax, "InvertedMangrove") {}

  // execute taker trade
  function executeEnd(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    override
  { unchecked {
    ITaker(mor.taker).takerTrade(
      sor.outbound_tkn,
      sor.inbound_tkn,
      mor.totalGot,
      mor.totalGave
    );
    bool success = transferTokenFrom(
      sor.inbound_tkn,
      mor.taker,
      address(this),
      mor.totalGave
    );
    require(success, "mgv/takerFailToPayTotal");
  }}

  /* We use `transferFrom` with takers (instead of checking `balanceOf` before/after the call) for the following reason we want the taker to be awaken after all loans have been made, so either
     1. The taker gets a list of all makers and loops through them to pay back, or
     2. we call a new taker method "payback" after returning from each maker call, or
     3. we call transferFrom after returning from each maker call

So :
   1. Would mean accumulating a list of all makers, which would make the market order code too complex
   2. Is OK, but has an extra CALL cost on top of the token transfer, one for each maker. This is unavoidable anyway when calling makerExecute (since the maker must be able to execute arbitrary code at that moment), but we can skip it here.
   3. Is the cheapest, but it has the drawbacks of `transferFrom`: money must end up owned by the taker, and taker needs to `approve` Mangrove
   */
  function beforePosthook(ML.SingleOrder memory sor) internal override { unchecked {
    /* If `transferToken` returns false here, we're in a special (and bad) situation. The taker is returning part of their total loan to a maker, but the maker can't receive the tokens. Only case we can see: maker is blacklisted. In that case, we send the tokens to the vault, so things have a chance of getting sorted out later (Mangrove is a token black hole). */
    if (
      !transferToken(
        sor.inbound_tkn,
        sor.offerDetail.maker(),
        sor.gives
      )
    ) {
      /* If that transfer fails there's nothing we can do -- reverting would punish the taker for the maker's blacklisting. */
      transferToken(sor.inbound_tkn, vault, sor.gives);
    }
  }}

  /* # Flashloans */
  //+clear+
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

  function flashloan(ML.SingleOrder calldata sor, address)
    external
    override
    returns (uint gasused)
  { unchecked {
    /* `invertedFlashloan` must be used with a call (hence the `external` modifier) so its effect can be reverted. But a call from the outside would be fatal. */
    require(msg.sender == address(this), "mgv/invertedFlashloan/protected");
    gasused = makerExecute(sor);
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

// Mangrove.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, P} from "./MgvLib.sol";

import {AbstractMangrove} from "./AbstractMangrove.sol";

/* <a id="Mangrove"></a> The `Mangrove` contract implements the "normal" version of Mangrove, where the taker flashloans the desired amount to each maker. Each time, makers are called after the loan. When the order is complete, each maker is called once again (with the orderbook unlocked). */
contract Mangrove is AbstractMangrove {
  using P.OfferDetail for P.OfferDetail.t;

  constructor(
    address governance,
    uint gasprice,
    uint gasmax
  ) AbstractMangrove(governance, gasprice, gasmax, "Mangrove") {}

  function executeEnd(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    override
  {}

  function beforePosthook(ML.SingleOrder memory sor) internal override {}

  /* ## Flashloan */
  /*
     `flashloan` is for the 'normal' mode of operation. It:
     1. Flashloans `takerGives` `inbound_tkn` from the taker to the maker and returns false if the loan fails.
     2. Runs `offerDetail.maker`'s `execute` function.
     3. Returns the result of the operations, with optional makerData to help the maker debug.
   */
  function flashloan(ML.SingleOrder calldata sor, address taker)
    external
    override
    returns (uint gasused)
  { unchecked {
    /* `flashloan` must be used with a call (hence the `external` modifier) so its effect can be reverted. But a call from the outside would be fatal. */
    require(msg.sender == address(this), "mgv/flashloan/protected");
    /* The transfer taker -> maker is in 2 steps. First, taker->mgv. Then
       mgv->maker. With a direct taker->maker transfer, if one of taker/maker
       is blacklisted, we can't tell which one. We need to know which one:
       if we incorrectly blame the taker, a blacklisted maker can block a pair forever; if we incorrectly blame the maker, a blacklisted taker can unfairly make makers fail all the time. Of course we assume the Mangrove is not blacklisted. Also note that this setup doesn't not work well with tokens that take fees or recompute balances at transfer time. */
    if (transferTokenFrom(sor.inbound_tkn, taker, address(this), sor.gives)) {
      if (
        transferToken(
          sor.inbound_tkn,
          sor.offerDetail.maker(),
          sor.gives
        )
      ) {
        gasused = makerExecute(sor);
      } else {
        innerRevert([bytes32("mgv/makerReceiveFail"), bytes32(0), ""]);
      }
    } else {
      innerRevert([bytes32("mgv/takerTransferFail"), "", ""]);
    }
  }}
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../../AbstractMangrove.sol";
//import "../../MgvLib.sol";
import {IERC20, IMaker, ITaker, MgvLib as ML, HasMgvEvents, IMgvMonitor, P} from "../../MgvLib.sol";
import "hardhat/console.sol";

contract OfferManager is IMaker, ITaker {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  // erc_addr -> owner_addr -> balance
  AbstractMangrove mgv;
  AbstractMangrove invMgv;
  address caller_id;
  // mgv_addr -> base_addr -> quote_addr -> offerId -> owner
  mapping(address => mapping(address => mapping(address => mapping(uint => address)))) owners;
  uint constant gas_to_execute = 100_000;

  constructor(AbstractMangrove _mgv, AbstractMangrove _inverted) {
    mgv = _mgv;
    invMgv = _inverted;
  }

  //posthook data:
  //outbound_tkn: orp.outbound_tkn,
  // inbound_tkn: orp.inbound_tkn,
  // takerWants: takerWants,
  // takerGives: takerGives,
  // offerId: offerId,
  // offerDeleted: toDelete

  function takerTrade(
    //NB this is not called if mgv is not a flashTaker mgv
    address base,
    address quote,
    uint netReceived,
    uint shouldGive
  ) external override {
    if (msg.sender == address(invMgv)) {
      ITaker(caller_id).takerTrade(base, quote, netReceived, shouldGive); // taker will find funds
      IERC20(quote).transferFrom(caller_id, address(this), shouldGive); // ready to be withdawn by Mangrove
    }
  }

  function makerPosthook(
    ML.SingleOrder calldata _order,
    ML.OrderResult calldata
  ) external override {
    if (msg.sender == address(invMgv)) {
      //should have received funds by now
      address owner = owners[msg.sender][_order.outbound_tkn][
        _order.inbound_tkn
      ][_order.offerId];
      require(owner != address(0), "Unkown owner");
      IERC20(_order.inbound_tkn).transfer(owner, _order.gives);
    }
  }

  // Maker side execute for residual offer
  event Execute(
    address mgv,
    address base,
    address quote,
    uint offerId,
    uint takerWants,
    uint takerGives
  );

  function makerExecute(ML.SingleOrder calldata _order)
    external
    override
    returns (bytes32 ret)
  {
    emit Execute(
      msg.sender,
      _order.outbound_tkn,
      _order.inbound_tkn,
      _order.offerId,
      _order.wants,
      _order.gives
    );
    bool inverted;
    address MGV;
    if (msg.sender == address(mgv)) {
      MGV = address(mgv);
    }
    if (msg.sender == address(invMgv)) {
      MGV = address(invMgv);
      inverted = true;
    }
    require(MGV != address(0), "Unauth call");
    // if residual of offerId is < dust, offer will be removed and dust lost
    // also freeWeil[this] will increase, offerManager may chose to give it back to owner
    address owner = owners[address(MGV)][_order.outbound_tkn][
      _order.inbound_tkn
    ][_order.offerId];
    console.log(owner);
    if (owner == address(0)) {
      ret = "mgvOffer/unknownOwner";
    }
    if (!inverted) {
      try IERC20(_order.inbound_tkn).transfer(owner, _order.gives) {
        console.log("Success");
        ret = "";
      } catch Error(string memory message) {
        console.log(message);
        ret = "mgvOffer/transferToOwnerFail";
      }
    } else {
      ret = "";
    }
  }

  //marketOrder (base,quote) + NewOffer(quote,base)
  function order(
    AbstractMangrove MGV,
    address base,
    address quote,
    uint wants,
    uint gives,
    bool invertedResidual
  ) external payable {
    bool flashTaker = (address(MGV) == address(invMgv));
    caller_id = msg.sender; // this should come with a reentrancy lock
    if (!flashTaker) {
      // else caller_id will be called when takerTrade is called by Mangrove
      IERC20(quote).transferFrom(msg.sender, address(this), gives); // OfferManager must be approved by sender
    }
    IERC20(quote).approve(address(MGV), 100 ether); // to pay maker
    IERC20(base).approve(address(MGV), 100 ether); // takerfee

    (uint netReceived, , ) = MGV.marketOrder(base, quote, wants, gives, true); // OfferManager might collect provisions of failing offers

    try IERC20(base).transfer(msg.sender, netReceived) {
      uint residual_w = wants - netReceived;
      uint residual_g = (gives * residual_w) / wants;

      AbstractMangrove _MGV;
      if (invertedResidual) {
        _MGV = invMgv;
      } else {
        _MGV = mgv;
      }
      (P.Global.t config, ) = _MGV.config(base, quote);
      require(
        msg.value >=
          gas_to_execute * uint(config.gasprice()) * 10**9,
        "Insufficent funds to delegate order"
      ); //not checking overflow issues
      (bool success, ) = address(_MGV).call{value: msg.value}("");
      require(success, "provision mgv failed");
      uint residual_ofr = _MGV.newOffer(
        quote,
        base,
        residual_w,
        residual_g,
        gas_to_execute,
        0,
        0
      );
      owners[address(_MGV)][quote][base][residual_ofr] = msg.sender;
    } catch {
      require(false, "Failed to send market order money to owner");
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./Passthrough.sol";
import "../../AbstractMangrove.sol";
import "hardhat/console.sol";
import {IERC20, IMaker} from "../../MgvLib.sol";
import {Test as TestEvents} from "@giry/hardhat-test-solidity/test.sol";

contract TestMaker is IMaker, Passthrough {
  AbstractMangrove _mgv;
  address _base;
  address _quote;
  bool _shouldFail; // will set mgv allowance to 0
  bool _shouldAbort; // will not return bytes32("")
  bool _shouldRevert; // will revert
  bytes32 _expectedStatus;

  constructor(
    AbstractMangrove mgv,
    IERC20 base,
    IERC20 quote
  ) {
    _mgv = mgv;
    _base = address(base);
    _quote = address(quote);
  }

  receive() external payable {}

  event Execute(
    address mgv,
    address base,
    address quote,
    uint offerId,
    uint takerWants,
    uint takerGives
  );

  function logExecute(
    address mgv,
    address base,
    address quote,
    uint offerId,
    uint takerWants,
    uint takerGives
  ) external {
    emit Execute(mgv, base, quote, offerId, takerWants, takerGives);
  }

  function shouldRevert(bool should) external {
    _shouldRevert = should;
  }

  function shouldFail(bool should) external {
    _shouldFail = should;
  }

  function shouldAbort(bool should) external {
    _shouldAbort = should;
  }

  function approveMgv(IERC20 token, uint amount) public {
    token.approve(address(_mgv), amount);
  }

  function expect(bytes32 mgvData) external {
    _expectedStatus = mgvData;
  }

  function transferToken(
    IERC20 token,
    address to,
    uint amount
  ) external {
    token.transfer(to, amount);
  }

  function makerExecute(ML.SingleOrder calldata order)
    public
    virtual
    override
    returns (bytes32)
  {
    if (_shouldRevert) {
      bytes32[1] memory revert_msg = [bytes32("testMaker/revert")];
      assembly {
        revert(revert_msg, 32)
      }
    }
    emit Execute(
      msg.sender,
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId,
      order.wants,
      order.gives
    );
    if (_shouldFail) {
      IERC20(order.outbound_tkn).approve(address(_mgv), 0);
      // bytes32[1] memory refuse_msg = [bytes32("testMaker/transferFail")];
      // assembly {
      //   return(refuse_msg, 32)
      // }
      //revert("testMaker/fail");
    }
    if (_shouldAbort) {
      return "abort";
    } else {
      return "";
    }
  }

  bool _shouldFailHook;

  function setShouldFailHook(bool should) external {
    _shouldFailHook = should;
  }

  function makerPosthook(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) external virtual override {
    order; //shh
    if (_shouldFailHook) {
      bytes32[1] memory refuse_msg = [bytes32("posthookFail")];
      assembly {
        revert(refuse_msg, 32)
      }
    }

    if (_expectedStatus != bytes32("")) {
      TestEvents.eq(
        result.mgvData,
        _expectedStatus,
        "Incorrect status message"
      );
    }
  }

  function newOffer(
    uint wants,
    uint gives,
    uint gasreq,
    uint pivotId
  ) public returns (uint) {
    return (_mgv.newOffer(_base, _quote, wants, gives, gasreq, 0, pivotId));
  }

  function newOffer(
    address base,
    address quote,
    uint wants,
    uint gives,
    uint gasreq,
    uint pivotId
  ) public returns (uint) {
    return (_mgv.newOffer(base, quote, wants, gives, gasreq, 0, pivotId));
  }

  function newOffer(
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId
  ) public returns (uint) {
    return (
      _mgv.newOffer(_base, _quote, wants, gives, gasreq, gasprice, pivotId)
    );
  }

  function updateOffer(
    uint wants,
    uint gives,
    uint gasreq,
    uint pivotId,
    uint offerId
  ) public {
    _mgv.updateOffer(_base, _quote, wants, gives, gasreq, 0, pivotId, offerId);
  }

  function retractOffer(uint offerId) public returns (uint) {
    return _mgv.retractOffer(_base, _quote, offerId, false);
  }

  function retractOfferWithDeprovision(uint offerId) public returns (uint) {
    return _mgv.retractOffer(_base, _quote, offerId, true);
  }

  function provisionMgv(uint amount) public {
    _mgv.fund{value: amount}(address(this));
  }

  function withdrawMgv(uint amount) public returns (bool) {
    return _mgv.withdraw(amount);
  }

  function freeWei() public view returns (uint) {
    return _mgv.balanceOf(address(this));
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;

/* 
  Experimental contract to simulate an EOA which can call arbitrary functions.
  How to use :
  
  p = new Passthrough();
  p.calls(<address>,Contract.function.selector,arg1,...argN);
*/

contract Passthrough {
  function calls(
    address addr,
    bytes4 signature,
    uint arg1
  ) public returns (bool, bytes memory) {
    return addr.call(abi.encodeWithSelector(signature, arg1));
  }

  function calls(
    address addr,
    bytes4 signature,
    uint arg1,
    uint arg2
  ) public returns (bool, bytes memory) {
    return addr.call(abi.encodeWithSelector(signature, arg1, arg2));
  }

  function calls(
    address addr,
    bytes4 signature,
    uint arg1,
    uint arg2,
    uint arg3
  ) public returns (bool, bytes memory) {
    return addr.call(abi.encodeWithSelector(signature, arg1, arg2, arg3));
  }

  function calls(
    address addr,
    bytes4 signature,
    uint arg1,
    uint arg2,
    uint arg3,
    uint arg4
  ) public returns (bool, bytes memory) {
    return addr.call(abi.encodeWithSelector(signature, arg1, arg2, arg3, arg4));
  }

  function calls(
    address addr,
    bytes4 signature,
    address arg1
  ) public returns (bool, bytes memory) {
    return addr.call(abi.encodeWithSelector(signature, arg1));
  }

  function calls(
    address addr,
    bytes4 signature,
    string memory arg1
  ) public returns (bool, bytes memory) {
    return addr.call(abi.encodeWithSelector(signature, arg1));
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
import "../ERC20BLWithDecimals.sol";

contract TestTokenWithDecimals is ERC20BLWithDecimals {
  mapping(address => bool) admins;

  constructor(
    address admin,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20BLWithDecimals(name, symbol, decimals) {
    admins[admin] = true;
  }

  function requireAdmin() internal view {
    require(admins[msg.sender], "TestToken/adminOnly");
  }

  function addAdmin(address admin) external {
    requireAdmin();
    admins[admin] = true;
  }

  function mint(address to, uint amount) external {
    requireAdmin();
    _mint(to, amount);
  }

  function burn(address account, uint amount) external {
    requireAdmin();
    _burn(account, amount);
  }

  function blacklists(address account) external {
    requireAdmin();
    _blacklists(account);
  }

  function whitelists(address account) external {
    requireAdmin();
    _whitelists(account);
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
import "./ERC20BL.sol";

contract ERC20BLWithDecimals is ERC20BL {
  constructor(
    string memory __name,
    string memory __symbol,
    uint8 __decimals
  ) ERC20BL(__name, __symbol) {
    _decimals = __decimals;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./SafeMath.sol";
import {IERC20} from "../MgvLib.sol";

// From OpenZeppelin & Giry
//The MIT License (MIT)

//Copyright (c) 2016-2020 zOS Global Limited

//Permission is hereby granted, free of charge, to any person obtaining
//a copy of this software and associated documentation files (the
//"Software"), to deal in the Software without restriction, including
//without limitation the rights to use, copy, modify, merge, publish,
//distribute, sublicense, and/or sell copies of the Software, and to
//permit persons to whom the Software is furnished to do so, subject to
//the following conditions:

//The above copyright notice and this permission notice shall be included
//in all copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20BL is Context, IERC20 {
  using SafeMath for uint;

  mapping(address => bool) private _blacklisted;
  mapping(address => uint) private _balances;

  mapping(address => mapping(address => uint)) private _allowances;

  uint private _totalSupply;

  string internal _name;
  string internal _symbol;
  uint8 internal _decimals;

  modifier notBlackListed(address addr) {
    require(
      !_blacklisted[addr] && !_blacklisted[_msgSender()],
      "ERC20BL/Blacklisted"
    );
    _;
  }

  function _blacklists(address addr) public {
    _blacklisted[addr] = true;
  }

  function _whitelists(address addr) public {
    _blacklisted[addr] = false;
  }

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory __name, string memory __symbol) {
    _name = __name;
    _symbol = __symbol;
    _decimals = 18;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint amount)
    public
    virtual
    override
    notBlackListed(recipient)
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint amount)
    public
    virtual
    override
    notBlackListed(spender)
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  )
    public
    virtual
    override
    notBlackListed(sender)
    notBlackListed(recipient)
    returns (bool)
  {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint addedValue)
    public
    virtual
    notBlackListed(spender)
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(
      amount,
      "ERC20: transfer amount exceeds balance"
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(
      amount,
      "ERC20: burn amount exceeds balance"
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint amount
  ) internal virtual {}

  function deposit() external payable override {}

  function withdraw(uint) external override {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// From OpenZeppelin
//The MIT License (MIT)

//Copyright (c) 2016-2020 zOS Global Limited

//Permission is hereby granted, free of charge, to any person obtaining
//a copy of this software and associated documentation files (the
//"Software"), to deal in the Software without restriction, including
//without limitation the rights to use, copy, modify, merge, publish,
//distribute, sublicense, and/or sell copies of the Software, and to
//permit persons to whom the Software is furnished to do so, subject to
//the following conditions:

//The above copyright notice and this permission notice shall be included
//in all copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint a, uint b) internal pure returns (uint) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    require(b <= a, errorMessage);
    uint c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint a, uint b) internal pure returns (uint) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint a, uint b) internal pure returns (uint) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    require(b > 0, errorMessage);
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint a, uint b) internal pure returns (uint) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "../AbstractMangrove.sol";
import "../MgvLib.sol";
import "hardhat/console.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";
import "./Agents/MakerDeployer.sol";
import "./Agents/TestTaker.sol";

/* The following constructs an ERC20 with a transferFrom callback method,
   and a TestTaker which throws away any funds received upon getting
   a callback.
*/
contract TakerOperations_Test is HasMgvEvents {
  TestToken baseT;
  TestToken quoteT;
  address base;
  address quote;
  AbstractMangrove mgv;
  TestMaker mkr;
  TestMaker refusemkr;
  TestMaker failmkr;

  bool refuseReceive = false;

  receive() external payable {
    if (refuseReceive) {
      revert("no");
    }
  }

  function a_beforeAll() public {
    baseT = TokenSetup.setup("A", "$A");
    quoteT = TokenSetup.setup("B", "$B");
    base = address(baseT);
    quote = address(quoteT);
    mgv = MgvSetup.setup(baseT, quoteT);

    mkr = MakerSetup.setup(mgv, base, quote);
    refusemkr = MakerSetup.setup(mgv, base, quote, 1);
    failmkr = MakerSetup.setup(mgv, base, quote, 2);

    payable(mkr).transfer(10 ether);
    payable(refusemkr).transfer(10 ether);
    payable(failmkr).transfer(10 ether);

    mkr.provisionMgv(10 ether);
    mkr.approveMgv(baseT, 10 ether);

    refusemkr.provisionMgv(1 ether);
    refusemkr.approveMgv(baseT, 10 ether);
    failmkr.provisionMgv(1 ether);
    failmkr.approveMgv(baseT, 10 ether);

    baseT.mint(address(mkr), 5 ether);
    baseT.mint(address(failmkr), 5 ether);
    baseT.mint(address(refusemkr), 5 ether);

    quoteT.mint(address(this), 5 ether);
    quoteT.mint(address(this), 5 ether);

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "taker");
    Display.register(base, "$A");
    Display.register(quote, "$B");
    Display.register(address(mgv), "mgv");

    Display.register(address(mkr), "maker");
    Display.register(address(failmkr), "reverting maker");
    Display.register(address(refusemkr), "refusing maker");
  }

  function snipe_reverts_if_taker_is_blacklisted_for_quote_test() public {
    uint weiBalanceBefore = mgv.balanceOf(address(this));
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 1 ether);
    quoteT.blacklists(address(this));

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 100_000];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.fail("Snipe should fail");
    } catch Error(string memory errorMsg) {
      TestEvents.eq(
        errorMsg,
        "mgv/takerTransferFail",
        "Unexpected revert reason"
      );
      TestEvents.eq(
        weiBalanceBefore,
        mgv.balanceOf(address(this)),
        "Taker should not take bounty"
      );
    }
  }

  function snipe_reverts_if_taker_is_blacklisted_for_base_test() public {
    uint weiBalanceBefore = mgv.balanceOf(address(this));
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 1 ether);
    baseT.blacklists(address(this));

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 100_000];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.fail("Snipe should fail");
    } catch Error(string memory errorMsg) {
      TestEvents.eq(
        errorMsg,
        "mgv/MgvFailToPayTaker",
        "Unexpected revert reason"
      );
      TestEvents.eq(
        weiBalanceBefore,
        mgv.balanceOf(address(this)),
        "Taker should not take bounty"
      );
    }
  }

  function snipe_fails_if_price_has_changed_test() public {
    uint weiBalanceBefore = mgv.balanceOf(address(this));
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 1 ether);
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 0.5 ether, 100_000];
    try mgv.snipes(base, quote, targets, false) returns (
      uint successes,
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.check(successes == 0, "Snipe should fail");
      TestEvents.eq(
        weiBalanceBefore,
        mgv.balanceOf(address(this)),
        "Taker should not take bounty"
      );
      TestEvents.check(
        (got == gave && gave == 0),
        "Taker should not give or take anything"
      );
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function taker_cannot_drain_maker_test() public {
    mgv.setDensity(base, quote, 0);
    quoteT.approve(address(mgv), 1 ether);
    uint ofr = mkr.newOffer(9, 10, 100_000, 0);
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1, 15 ether, 100_000];
    uint oldBal = quoteT.balanceOf(address(this));
    mgv.snipes(base, quote, targets, true);
    uint newBal = quoteT.balanceOf(address(this));
    TestEvents.more(oldBal, newBal, "oldBal should be strictly higher");
  }

  function snipe_fillWants_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 1 ether);
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0.5 ether, 1 ether, 100_000];
    try mgv.snipes(base, quote, targets, true) returns (
      uint successes,
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.check(successes == 1, "Snipe should not fail");
      TestEvents.eq(got, 0.5 ether, "Taker did not get enough");
      TestEvents.eq(gave, 0.5 ether, "Taker did not give enough");
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function multiple_snipes_fillWants_test() public {
    uint i;
    uint[] memory ofrs = new uint[](3);
    ofrs[i++] = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    ofrs[i++] = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    ofrs[i++] = mkr.newOffer(1 ether, 1 ether, 100_000, 0);

    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 3 ether);
    uint[4][] memory targets = new uint[4][](3);
    uint j;
    targets[j] = [ofrs[j], 0.5 ether, 1 ether, 100_000];
    j++;
    targets[j] = [ofrs[j], 1 ether, 1 ether, 100_000];
    j++;
    targets[j] = [ofrs[j], 0.8 ether, 1 ether, 100_000];

    try mgv.snipes(base, quote, targets, true) returns (
      uint successes,
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.check(successes == 3, "Snipes should not fail");
      TestEvents.eq(got, 2.3 ether, "Taker did not get enough");
      TestEvents.eq(gave, 2.3 ether, "Taker did not give enough");
      TestEvents.expectFrom(address(mgv));
      emit OrderComplete(
        address(base),
        address(quote),
        address(this),
        got,
        gave
      );
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  event Transfer(address indexed from, address indexed to, uint value);

  function snipe_fillWants_zero_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    TestEvents.check(
      TestUtils.hasOffer(mgv, base, quote, ofr),
      "Offer should be in the book"
    );
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 1 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0, 0, 100_000];
    try mgv.snipes(base, quote, targets, true) returns (
      uint successes,
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.check(successes == 1, "Snipe should not fail");
      TestEvents.eq(got, 0 ether, "Taker had too much");
      TestEvents.eq(gave, 0 ether, "Taker gave too much");
      TestEvents.check(
        !TestUtils.hasOffer(mgv, base, quote, ofr),
        "Offer should not be in the book"
      );
      TestEvents.expectFrom(address(quote));
      emit Transfer(address(this), address(mgv), 0);
      emit Transfer(address(mgv), address(mkr), 0);
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function snipe_free_offer_fillWants_respects_spec_test() public {
    uint ofr = mkr.newOffer(0, 1 ether, 100_000, 0);
    TestEvents.check(
      TestUtils.hasOffer(mgv, base, quote, ofr),
      "Offer should be in the book"
    );
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 1 ether);

    /* Setting fillWants = true means we should not receive more than `wants`.
       Here we are asking for 0.1 eth to an offer that gives 1eth for nothing.
       We should still only receive 0.1 eth */

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0.1 ether, 0, 100_000];
    try mgv.snipes(base, quote, targets, true) returns (
      uint successes,
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.check(successes == 1, "Snipe should not fail");
      TestEvents.eq(got, 0.1 ether, "Wrong got value");
      TestEvents.eq(gave, 0 ether, "Wrong gave value");
      TestEvents.check(
        !TestUtils.hasOffer(mgv, base, quote, ofr),
        "Offer should not be in the book"
      );
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function snipe_free_offer_fillGives_respects_spec_test() public {
    uint ofr = mkr.newOffer(0, 1 ether, 100_000, 0);
    TestEvents.check(
      TestUtils.hasOffer(mgv, base, quote, ofr),
      "Offer should be in the book"
    );
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 1 ether);

    /* Setting fillWants = false means we should spend as little as possible to receive
       as much as possible.
       Here despite asking for .1eth the offer gives 1eth for 0 so we should receive 1eth. */

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0.1 ether, 0, 100_000];
    try mgv.snipes(base, quote, targets, false) returns (
      uint successes,
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.check(successes == 1, "Snipe should not fail");
      TestEvents.eq(got, 1 ether, "Wrong got value");
      TestEvents.eq(gave, 0 ether, "Wrong gave value");
      TestEvents.check(
        !TestUtils.hasOffer(mgv, base, quote, ofr),
        "Offer should not be in the book"
      );
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function snipe_fillGives_zero_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    TestEvents.check(
      TestUtils.hasOffer(mgv, base, quote, ofr),
      "Offer should be in the book"
    );
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 1 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0, 0, 100_000];
    try mgv.snipes(base, quote, targets, false) returns (
      uint successes,
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.check(successes == 1, "Snipe should not fail");
      TestEvents.eq(got, 0 ether, "Taker had too much");
      TestEvents.eq(gave, 0 ether, "Taker gave too much");
      TestEvents.check(
        !TestUtils.hasOffer(mgv, base, quote, ofr),
        "Offer should not be in the book"
      );
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function snipe_fillGives_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 1 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0.5 ether, 1 ether, 100_000];
    try mgv.snipes(base, quote, targets, false) returns (
      uint successes,
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.check(successes == 1, "Snipe should not fail");
      TestEvents.eq(got, 1 ether, "Taker did not get enough");
      TestEvents.eq(gave, 1 ether, "Taker did not get enough");
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function mo_fillWants_test() public {
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 2 ether);
    try mgv.marketOrder(base, quote, 1.1 ether, 2 ether, true) returns (
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.eq(got, 1.1 ether, "Taker did not get enough");
      TestEvents.eq(gave, 1.1 ether, "Taker did not get enough");
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function mo_fillGives_test() public {
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 2 ether);
    try mgv.marketOrder(base, quote, 1.1 ether, 2 ether, false) returns (
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.eq(got, 2 ether, "Taker did not get enough");
      TestEvents.eq(gave, 2 ether, "Taker did not get enough");
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function mo_fillGivesAll_no_approved_fails_test() public {
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 2 ether);
    try mgv.marketOrder(base, quote, 0 ether, 3 ether, false) {} catch Error(
      string memory errorMsg
    ) {
      TestEvents.eq(
        errorMsg,
        "mgv/takerTransferFail",
        "Invalid revert message"
      );
    }
  }

  function mo_fillGivesAll_succeeds_test() public {
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/tradeSuccess"); // trade should be OK on the maker side
    quoteT.approve(address(mgv), 3 ether);
    try mgv.marketOrder(base, quote, 0 ether, 3 ether, false) returns (
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.eq(got, 3 ether, "Taker did not get enough");
      TestEvents.eq(gave, 3 ether, "Taker did not get enough");
    } catch {
      TestEvents.fail("Transaction should not revert");
    }
  }

  function taker_reimbursed_if_maker_doesnt_pay_test() public {
    uint mkr_provision = TestUtils.getProvision(mgv, base, quote, 100_000);
    quoteT.approve(address(mgv), 1 ether);
    uint ofr = refusemkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/makerTransferFail"); // status visible in the posthook
    uint beforeQuote = quoteT.balanceOf(address(this));
    uint beforeWei = address(this).balance;

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 100_000];
    (uint successes, uint takerGot, uint takerGave, ) = mgv.snipes(
      base,
      quote,
      targets,
      true
    );
    uint penalty = address(this).balance - beforeWei;
    TestEvents.check(penalty > 0, "Taker should have been compensated");
    TestEvents.check(successes == 0, "Snipe should fail");
    TestEvents.check(
      takerGot == takerGave && takerGave == 0,
      "Incorrect transaction information"
    );
    TestEvents.check(
      beforeQuote == quoteT.balanceOf(address(this)),
      "taker balance should not be lower if maker doesn't pay back"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferFail(
      base,
      quote,
      ofr,
      address(this),
      1 ether,
      1 ether,
      "mgv/makerTransferFail"
    );
    emit Credit(address(refusemkr), mkr_provision - penalty);
  }

  function taker_reverts_on_penalty_triggers_revert_test() public {
    uint ofr = refusemkr.newOffer(1 ether, 1 ether, 50_000, 0);
    refuseReceive = true;
    quoteT.approve(address(mgv), 1 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 100_000];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.fail(
        "Snipe should fail because taker has reverted on penalty send."
      );
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/sendPenaltyReverted", "wrong revert reason");
    }
  }

  function taker_reimbursed_if_maker_is_blacklisted_for_base_test() public {
    uint mkr_provision = TestUtils.getProvision(mgv, base, quote, 100_000);
    quoteT.approve(address(mgv), 1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/makerTransferFail"); // status visible in the posthook

    baseT.blacklists(address(mkr));
    uint beforeQuote = quoteT.balanceOf(address(this));
    uint beforeWei = address(this).balance;

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 100_000];
    (uint successes, uint takerGot, uint takerGave, ) = mgv.snipes(
      base,
      quote,
      targets,
      true
    );
    uint penalty = address(this).balance - beforeWei;
    TestEvents.check(penalty > 0, "Taker should have been compensated");
    TestEvents.check(successes == 0, "Snipe should fail");
    TestEvents.check(
      takerGot == takerGave && takerGave == 0,
      "Incorrect transaction information"
    );
    TestEvents.check(
      beforeQuote == quoteT.balanceOf(address(this)),
      "taker balance should not be lower if maker doesn't pay back"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferFail(
      base,
      quote,
      ofr,
      address(this),
      1 ether,
      1 ether,
      "mgv/makerTransferFail"
    );
    emit Credit(address(mkr), mkr_provision - penalty);
  }

  function taker_reimbursed_if_maker_is_blacklisted_for_quote_test() public {
    uint mkr_provision = TestUtils.getProvision(mgv, base, quote, 100_000);
    quoteT.approve(address(mgv), 1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.expect("mgv/makerReceiveFail"); // status visible in the posthook

    quoteT.blacklists(address(mkr));
    uint beforeQuote = quoteT.balanceOf(address(this));
    uint beforeWei = address(this).balance;

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 100_000];
    (uint successes, uint takerGot, uint takerGave, ) = mgv.snipes(
      base,
      quote,
      targets,
      true
    );
    uint penalty = address(this).balance - beforeWei;
    TestEvents.check(penalty > 0, "Taker should have been compensated");
    TestEvents.check(successes == 0, "Snipe should fail");
    TestEvents.check(
      takerGot == takerGave && takerGave == 0,
      "Incorrect transaction information"
    );
    TestEvents.check(
      beforeQuote == quoteT.balanceOf(address(this)),
      "taker balance should not be lower if maker doesn't pay back"
    );
    TestEvents.expectFrom(address(mgv));

    emit OfferFail(
      base,
      quote,
      ofr,
      address(this),
      1 ether,
      1 ether,
      "mgv/makerReceiveFail"
    );
    emit Credit(address(mkr), mkr_provision - penalty);
  }

  function taker_collects_failing_offer_test() public {
    quoteT.approve(address(mgv), 1 ether);
    uint ofr = failmkr.newOffer(1 ether, 1 ether, 50_000, 0);
    uint beforeWei = address(this).balance;

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0, 0, 100_000];
    (uint successes, uint takerGot, uint takerGave, ) = mgv.snipes(
      base,
      quote,
      targets,
      true
    );
    TestEvents.check(successes == 0, "Snipe should fail");
    TestEvents.check(
      takerGot == takerGave && takerGave == 0,
      "Transaction data should be 0"
    );
    TestEvents.check(
      address(this).balance > beforeWei,
      "Taker was not compensated"
    );
  }

  function taker_reimbursed_if_maker_reverts_test() public {
    uint mkr_provision = TestUtils.getProvision(mgv, base, quote, 50_000);
    quoteT.approve(address(mgv), 1 ether);
    uint ofr = failmkr.newOffer(1 ether, 1 ether, 50_000, 0);
    uint beforeQuote = quoteT.balanceOf(address(this));
    uint beforeWei = address(this).balance;

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 100_000];
    (uint successes, uint takerGot, uint takerGave, ) = mgv.snipes(
      base,
      quote,
      targets,
      true
    );
    uint penalty = address(this).balance - beforeWei;
    TestEvents.check(penalty > 0, "Taker should have been compensated");
    TestEvents.check(successes == 0, "Snipe should fail");
    TestEvents.check(
      takerGot == takerGave && takerGave == 0,
      "Incorrect transaction information"
    );
    TestEvents.check(
      beforeQuote == quoteT.balanceOf(address(this)),
      "taker balance should not be lower if maker doesn't pay back"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferFail(
      base,
      quote,
      ofr,
      address(this),
      1 ether,
      1 ether,
      "mgv/makerRevert"
    );
    emit Credit(address(failmkr), mkr_provision - penalty);
  }

  function taker_hasnt_approved_base_succeeds_order_with_fee_test() public {
    mgv.setFee(base, quote, 3);
    uint balTaker = baseT.balanceOf(address(this));
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50_000, 0);
    quoteT.approve(address(mgv), 1 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 50_000];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.eq(
        baseT.balanceOf(address(this)) - balTaker,
        1 ether,
        "Incorrect delivered amount"
      );
    } catch {
      TestEvents.fail("Snipe should succeed");
    }
  }

  function taker_hasnt_approved_base_succeeds_order_wo_fee_test() public {
    uint balTaker = baseT.balanceOf(address(this));
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50_000, 0);
    quoteT.approve(address(mgv), 1 ether);
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 50_000];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.eq(
        baseT.balanceOf(address(this)) - balTaker,
        1 ether,
        "Incorrect delivered amount"
      );
    } catch {
      TestEvents.fail("Snipe should succeed");
    }
  }

  function taker_hasnt_approved_quote_fails_order_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50_000, 0);
    baseT.approve(address(mgv), 1 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 50_000];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.fail("Order should fail when base is not mgv approved");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/takerTransferFail", "wrong revert reason");
    }
  }

  function simple_snipe_test() public {
    uint ofr = mkr.newOffer(1.1 ether, 1 ether, 50_000, 0);
    baseT.approve(address(mgv), 10 ether);
    quoteT.approve(address(mgv), 10 ether);
    uint balTaker = baseT.balanceOf(address(this));
    uint balMaker = quoteT.balanceOf(address(mkr));

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1.1 ether, 50_000];
    try mgv.snipes(base, quote, targets, true) returns (
      uint successes,
      uint takerGot,
      uint takerGave,
      uint
    ) {
      TestEvents.check(successes == 1, "Snipe should succeed");
      TestEvents.eq(
        baseT.balanceOf(address(this)) - balTaker,
        1 ether,
        "Incorrect delivered amount (taker)"
      );
      TestEvents.eq(
        quoteT.balanceOf(address(mkr)) - balMaker,
        1.1 ether,
        "Incorrect delivered amount (maker)"
      );
      TestEvents.eq(takerGot, 1 ether, "Incorrect transaction information");
      TestEvents.eq(takerGave, 1.1 ether, "Incorrect transaction information");
      TestEvents.expectFrom(address(mgv));
      emit OfferSuccess(base, quote, ofr, address(this), 1 ether, 1.1 ether);
    } catch {
      TestEvents.fail("Snipe should succeed");
    }
  }

  function simple_marketOrder_test() public {
    mkr.newOffer(1.1 ether, 1 ether, 50_000, 0);
    mkr.newOffer(1.2 ether, 1 ether, 50_000, 0);
    mkr.expect("mgv/tradeSuccess");

    baseT.approve(address(mgv), 10 ether);
    quoteT.approve(address(mgv), 10 ether);
    uint balTaker = baseT.balanceOf(address(this));
    uint balMaker = quoteT.balanceOf(address(mkr));

    try mgv.marketOrder(base, quote, 2 ether, 4 ether, true) returns (
      uint takerGot,
      uint takerGave,
      uint
    ) {
      TestEvents.eq(
        takerGot,
        2 ether,
        "Incorrect declared delivered amount (taker)"
      );
      TestEvents.eq(
        takerGave,
        2.3 ether,
        "Incorrect declared delivered amount (maker)"
      );
      TestEvents.eq(
        baseT.balanceOf(address(this)) - balTaker,
        2 ether,
        "Incorrect delivered amount (taker)"
      );
      TestEvents.eq(
        quoteT.balanceOf(address(mkr)) - balMaker,
        2.3 ether,
        "Incorrect delivered amount (maker)"
      );
    } catch {
      TestEvents.fail("Market order should succeed");
    }
  }

  function simple_fillWants_test() public {
    mkr.newOffer(2 ether, 2 ether, 50_000, 0);
    mkr.expect("mgv/tradeSuccess");
    quoteT.approve(address(mgv), 10 ether);

    (uint takerGot, uint takerGave, ) = mgv.marketOrder(
      base,
      quote,
      1 ether,
      2 ether,
      true
    );
    TestEvents.eq(
      takerGot,
      1 ether,
      "Incorrect declared delivered amount (taker)"
    );
    TestEvents.eq(
      takerGave,
      1 ether,
      "Incorrect declared delivered amount (maker)"
    );
  }

  function simple_fillGives_test() public {
    mkr.newOffer(2 ether, 2 ether, 50_000, 0);
    mkr.expect("mgv/tradeSuccess");
    quoteT.approve(address(mgv), 10 ether);

    (uint takerGot, uint takerGave, ) = mgv.marketOrder(
      base,
      quote,
      1 ether,
      2 ether,
      false
    );
    TestEvents.eq(
      takerGave,
      2 ether,
      "Incorrect declared delivered amount (maker)"
    );
    TestEvents.eq(
      takerGot,
      2 ether,
      "Incorrect declared delivered amount (taker)"
    );
  }

  function fillGives_at_0_wants_works_test() public {
    uint ofr = mkr.newOffer(0 ether, 2 ether, 50_000, 0);
    mkr.expect("mgv/tradeSuccess");
    quoteT.approve(address(mgv), 10 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 2 ether, 0 ether, 300_000];

    (, uint takerGot, uint takerGave, ) = mgv.snipes(
      base,
      quote,
      targets,
      false
    );
    TestEvents.eq(
      takerGave,
      0 ether,
      "Incorrect declared delivered amount (maker)"
    );
    TestEvents.eq(
      takerGot,
      2 ether,
      "Incorrect declared delivered amount (taker)"
    );
  }

  function empty_wants_fillGives_test() public {
    mkr.newOffer(2 ether, 2 ether, 50_000, 0);
    mkr.expect("mgv/tradeSuccess");
    quoteT.approve(address(mgv), 10 ether);

    (uint takerGot, uint takerGave, ) = mgv.marketOrder(
      base,
      quote,
      0 ether,
      2 ether,
      false
    );
    TestEvents.eq(
      takerGave,
      2 ether,
      "Incorrect declared delivered amount (maker)"
    );
    TestEvents.eq(
      takerGot,
      2 ether,
      "Incorrect declared delivered amount (taker)"
    );
  }

  function empty_wants_fillWants_test() public {
    mkr.newOffer(2 ether, 2 ether, 50_000, 0);
    mkr.expect("mgv/tradeSuccess");
    quoteT.approve(address(mgv), 10 ether);

    (uint takerGot, uint takerGave, ) = mgv.marketOrder(
      base,
      quote,
      0 ether,
      2 ether,
      true
    );
    TestEvents.eq(
      takerGave,
      0 ether,
      "Incorrect declared delivered amount (maker)"
    );
    TestEvents.eq(
      takerGot,
      0 ether,
      "Incorrect declared delivered amount (taker)"
    );
  }

  function taker_has_no_quote_fails_order_test() public {
    uint ofr = mkr.newOffer(100 ether, 2 ether, 50_000, 0);
    mkr.expect("mgv/tradeSuccess");

    quoteT.approve(address(mgv), 100 ether);
    baseT.approve(address(mgv), 1 ether); // not necessary since no fee

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 2 ether, 100 ether, 100_000];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.fail(
        "Taker does not have enough quote tokens, order should fail"
      );
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/takerTransferFail", "wrong revert reason");
    }
  }

  function maker_has_not_enough_base_fails_order_test() public {
    uint ofr = mkr.newOffer(1 ether, 100 ether, 100_000, 0);
    mkr.expect("mgv/makerTransferFail");
    // getting rid of base tokens
    //mkr.transferToken(baseT,address(this),5 ether);
    quoteT.approve(address(mgv), 0.5 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 50 ether, 0.5 ether, 100_000];
    (uint successes, , , ) = mgv.snipes(base, quote, targets, true);
    TestEvents.check(successes == 0, "order should fail");
    TestEvents.expectFrom(address(mgv));
    emit OfferFail(
      base,
      quote,
      ofr,
      address(this),
      50 ether,
      0.5 ether,
      "mgv/makerTransferFail"
    );
  }

  function maker_revert_is_logged_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50_000, 0);
    mkr.expect("mgv/makerRevert");
    mkr.shouldRevert(true);
    quoteT.approve(address(mgv), 1 ether);
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 50_000];
    mgv.snipes(base, quote, targets, true);
    TestEvents.expectFrom(address(mgv));
    emit OfferFail(
      base,
      quote,
      ofr,
      address(this),
      1 ether,
      1 ether,
      "mgv/makerRevert"
    );
  }

  function snipe_on_higher_price_fails_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    quoteT.approve(address(mgv), 0.5 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 0.5 ether, 100_000];
    (uint successes, , , ) = mgv.snipes(base, quote, targets, true);
    TestEvents.check(
      successes == 0,
      "Order should fail when order price is higher than offer"
    );
  }

  function snipe_on_higher_gas_fails_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    quoteT.approve(address(mgv), 1 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 50_000];
    (uint successes, , , ) = mgv.snipes(base, quote, targets, true);
    TestEvents.check(
      successes == 0,
      "Order should fail when order gas is higher than offer"
    );
  }

  function detect_lowgas_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    quoteT.approve(address(mgv), 100 ether);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 100_000];
    bytes memory cd = abi.encodeWithSelector(
      mgv.snipes.selector,
      base,
      quote,
      targets,
      true
    );

    (bool noRevert, bytes memory data) = address(mgv).call{gas: 130000}(cd);
    if (noRevert) {
      TestEvents.fail("take should fail due to low gas");
    } else {
      TestUtils.revertEq(
        TestUtils.getReason(data),
        "mgv/notEnoughGasForMakerTrade"
      );
    }
  }

  function snipe_on_lower_price_succeeds_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    quoteT.approve(address(mgv), 2 ether);
    uint balTaker = baseT.balanceOf(address(this));
    uint balMaker = quoteT.balanceOf(address(mkr));

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 2 ether, 100_000];
    (uint successes, , , ) = mgv.snipes(base, quote, targets, true);
    TestEvents.check(
      successes == 1,
      "Order should succeed when order price is lower than offer"
    );
    // checking order was executed at Maker's price
    TestEvents.eq(
      baseT.balanceOf(address(this)) - balTaker,
      1 ether,
      "Incorrect delivered amount (taker)"
    );
    TestEvents.eq(
      quoteT.balanceOf(address(mkr)) - balMaker,
      1 ether,
      "Incorrect delivered amount (maker)"
    );
  }

  /* Note as for jan 5 2020: by locally pushing the block gas limit to 38M, you can go up to 162 levels of recursion before hitting "revert for an unknown reason" -- I'm assuming that's the stack limit. */
  function recursion_depth_is_acceptable_test() public {
    for (uint i = 0; i < 50; i++) {
      mkr.newOffer(0.001 ether, 0.001 ether, 50_000, i);
    }
    quoteT.approve(address(mgv), 10 ether);
    // 6/1/20 : ~50k/offer with optims
    //uint g = gasleft();
    //console.log("gas used per offer: ",(g-gasleft())/50);
  }

  function partial_fill_test() public {
    quoteT.approve(address(mgv), 1 ether);
    mkr.newOffer(0.1 ether, 0.1 ether, 50_000, 0);
    mkr.newOffer(0.1 ether, 0.1 ether, 50_000, 1);
    mkr.expect("mgv/tradeSuccess");
    (uint takerGot, , ) = mgv.marketOrder(
      base,
      quote,
      0.15 ether,
      0.15 ether,
      true
    );
    TestEvents.eq(
      takerGot,
      0.15 ether,
      "Incorrect declared partial fill amount"
    );
    TestEvents.eq(
      baseT.balanceOf(address(this)),
      0.15 ether,
      "incorrect partial fill"
    );
  }

  // ! unreliable test, depends on gas use
  function market_order_stops_for_high_price_test() public {
    quoteT.approve(address(mgv), 1 ether);
    for (uint i = 0; i < 10; i++) {
      mkr.newOffer((i + 1) * (0.1 ether), 0.1 ether, 50_000, i);
    }
    mkr.expect("mgv/tradeSuccess");
    // first two offers are at right price
    uint takerWants = 2 * (0.1 ether + 0.1 ether);
    uint takerGives = 2 * (0.1 ether + 0.2 ether);
    mgv.marketOrder{gas: 350_000}(base, quote, takerWants, takerGives, true);
  }

  // ! unreliable test, depends on gas use
  function market_order_stops_for_filled_mid_offer_test() public {
    quoteT.approve(address(mgv), 1 ether);
    for (uint i = 0; i < 10; i++) {
      mkr.newOffer(i * (0.1 ether), 0.1 ether, 50_000, i);
    }
    mkr.expect("mgv/tradeSuccess");
    // first two offers are at right price
    uint takerWants = 0.1 ether + 0.05 ether;
    uint takerGives = 0.1 ether + 0.1 ether;
    mgv.marketOrder{gas: 350_000}(base, quote, takerWants, takerGives, true);
  }

  function market_order_stops_for_filled_after_offer_test() public {
    quoteT.approve(address(mgv), 1 ether);
    for (uint i = 0; i < 10; i++) {
      mkr.newOffer(i * (0.1 ether), 0.1 ether, 50_000, i);
    }
    mkr.expect("mgv/tradeSuccess");
    // first two offers are at right price
    uint takerWants = 0.1 ether + 0.1 ether;
    uint takerGives = 0.1 ether + 0.2 ether;
    mgv.marketOrder{gas: 350_000}(base, quote, takerWants, takerGives, true);
  }

  function takerWants_wider_than_160_bits_fails_marketOrder_test() public {
    try mgv.marketOrder(base, quote, 2**160, 1, true) {
      TestEvents.fail("TakerWants > 160bits, order should fail");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/mOrder/takerWants/160bits", "wrong revert reason");
    }
  }

  function snipe_with_0_wants_ejects_offer_test() public {
    quoteT.approve(address(mgv), 1 ether);
    uint mkrBal = baseT.balanceOf(address(mkr));
    uint ofr = mkr.newOffer(0.1 ether, 0.1 ether, 50_000, 0);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0, 1 ether, 50_000];
    (uint successes, , , ) = mgv.snipes(base, quote, targets, true);
    TestEvents.check(successes == 1, "snipe should succeed");
    TestEvents.eq(mgv.best(base, quote), 0, "offer should be gone");
    TestEvents.eq(
      baseT.balanceOf(address(mkr)),
      mkrBal,
      "mkr balance should not change"
    );
  }

  function unsafe_gas_left_fails_order_test() public {
    mgv.setGasbase(base, quote, 1);
    quoteT.approve(address(mgv), 1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 120_000, 0);
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 120_000];
    try mgv.snipes{gas: 120_000}(base, quote, targets, true) {
      TestEvents.fail("unsafe gas amount, order should fail");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/notEnoughGasForMakerTrade", "wrong revert reason");
    }
  }

  function marketOrder_on_empty_book_returns_test() public {
    try mgv.marketOrder(base, quote, 1 ether, 1 ether, true) {
      TestEvents.succeed();
    } catch Error(string memory) {
      TestEvents.fail("market order on empty book should not fail");
    }
  }

  function marketOrder_on_empty_book_does_not_leave_lock_on_test() public {
    mgv.marketOrder(base, quote, 1 ether, 1 ether, true);
    TestEvents.check(
      !mgv.locked(base, quote),
      "mgv should not be locked after marketOrder on empty OB"
    );
  }

  function takerWants_is_zero_succeeds_test() public {
    try mgv.marketOrder(base, quote, 0, 1 ether, true) returns (
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.eq(got, 0, "Taker got too much");
      TestEvents.eq(gave, 0 ether, "Taker gave too much");
    } catch {
      TestEvents.fail("Unexpected revert");
    }
  }

  function takerGives_is_zero_succeeds_test() public {
    try mgv.marketOrder(base, quote, 1 ether, 0, true) returns (
      uint got,
      uint gave,
      uint
    ) {
      TestEvents.eq(got, 0, "Taker got too much");
      TestEvents.eq(gave, 0 ether, "Taker gave too much");
    } catch {
      TestEvents.fail("Unexpected revert");
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "../AbstractMangrove.sol";
import "../MgvLib.sol";
import "hardhat/console.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";
import "./Agents/TestMoriartyMaker.sol";
import "./Agents/MakerDeployer.sol";
import "./Agents/TestTaker.sol";

/* *********************************************** */
/* THIS IS NOT A `hardhat test-solidity` TEST FILE */
/* *********************************************** */

/* See test/permit.js, this helper sets up a mgv for the javascript tester of the permit functionality */

contract PermitHelper is IMaker {
  receive() external payable {}

  AbstractMangrove mgv;
  address base;
  address quote;

  function makerExecute(ML.SingleOrder calldata)
    external
    pure
    override
    returns (bytes32)
  {
    return "";
  }

  function makerPosthook(ML.SingleOrder calldata, ML.OrderResult calldata)
    external
    override
  {}

  constructor() payable {
    TestToken baseT = TokenSetup.setup("A", "$A");
    TestToken quoteT = TokenSetup.setup("B", "$B");
    base = address(baseT);
    quote = address(quoteT);
    mgv = MgvSetup.setup(baseT, quoteT);

    bool noRevert;
    (noRevert, ) = address(mgv).call{value: 10 ether}("");

    baseT.mint(address(this), 2 ether);
    quoteT.mint(msg.sender, 2 ether);

    baseT.approve(address(mgv), 1 ether);

    Display.register(msg.sender, "Permit signer");
    Display.register(address(this), "Permit Helper");
    Display.register(base, "$A");
    Display.register(quote, "$B");
    Display.register(address(mgv), "mgv");

    mgv.newOffer(base, quote, 1 ether, 1 ether, 100_000, 0, 0);
  }

  function mgvAddress() external view returns (address) {
    return address(mgv);
  }

  function baseAddress() external view returns (address) {
    return base;
  }

  function quoteAddress() external view returns (address) {
    return quote;
  }

  function no_allowance() external {
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [uint(1), 1 ether, 1 ether, 300_000];
    try mgv.snipesFor(base, quote, targets, true, msg.sender) {
      revert("snipesFor without allowance should revert");
    } catch Error(string memory reason) {
      if (keccak256(bytes(reason)) != keccak256("mgv/lowAllowance")) {
        revert("revert when no allowance should be due to no allowance");
      }
    }
  }

  function wrong_permit(
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    try
      mgv.permit({
        outbound_tkn: base,
        inbound_tkn: quote,
        owner: msg.sender,
        spender: address(this),
        value: value,
        deadline: deadline,
        v: v,
        r: r,
        s: s
      })
    {
      revert("Permit with bad v,r,s should revert");
    } catch Error(string memory reason) {
      if (
        keccak256(bytes(reason)) != keccak256("mgv/permit/invalidSignature")
      ) {
        revert("permit failed, but signature should be deemed invalid");
      }
    }
  }

  function expired_permit(
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    try
      mgv.permit({
        outbound_tkn: base,
        inbound_tkn: quote,
        owner: msg.sender,
        spender: address(this),
        value: value,
        deadline: deadline,
        v: v,
        r: r,
        s: s
      })
    {
      revert("Permit with expired deadline should revert");
    } catch Error(string memory reason) {
      if (keccak256(bytes(reason)) != keccak256("mgv/permit/expired")) {
        revert("permit failed, but deadline should be deemed expired");
      }
    }
  }

  function good_permit(
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    mgv.permit(
      base,
      quote,
      msg.sender,
      address(this),
      value,
      deadline,
      v,
      r,
      s
    );

    if (mgv.allowances(base, quote, msg.sender, address(this)) != value) {
      revert("Allowance not set");
    }

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [uint(1), 1 ether, 1 ether, 300_000];
    (uint successes, uint takerGot, uint takerGave, ) = mgv.snipesFor(
      base,
      quote,
      targets,
      true,
      msg.sender
    );
    if (successes != 0) {
      revert("Snipe should succeed");
    }
    if (takerGot != 1 ether) {
      revert("takerGot should be 1 ether");
    }

    if (takerGave != 1 ether) {
      revert("takerGave should be 1 ether");
    }

    if (
      mgv.allowances(base, quote, msg.sender, address(this)) !=
      (value - 1 ether)
    ) {
      revert("Allowance incorrectly decreased");
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "../AbstractMangrove.sol";
import "../MgvLib.sol";
import "hardhat/console.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";
import "./Agents/TestMoriartyMaker.sol";
import "./Agents/MakerDeployer.sol";
import "./Agents/TestTaker.sol";
import "./Agents/Compound.sol";

contract Pedagogical_Test {
  receive() external payable {}

  AbstractMangrove mgv;
  TestToken bat;
  TestToken dai;
  TestTaker tkr;
  TestMaker mkr;
  Compound compound;

  function example_1_offerbook_test() public {
    setupMakerBasic();

    Display.log("Filling book");

    mkr.newOffer({wants: 1 ether, gives: 1 ether, gasreq: 300_000, pivotId: 0});

    mkr.newOffer({
      wants: 1.1 ether,
      gives: 1 ether,
      gasreq: 300_000,
      pivotId: 0
    });

    mkr.newOffer({
      wants: 1.2 ether,
      gives: 1 ether,
      gasreq: 300_000,
      pivotId: 0
    });

    //logBook
    TestUtils.logOfferBook(mgv, address(bat), address(dai), 3);
    Display.logBalances(
      [address(bat), address(dai)],
      address(mkr),
      address(tkr)
    );
  }

  function example_2_markerOrder_test() public {
    example_1_offerbook_test();

    Display.log(
      "Market order. Taker wants 2.7 exaunits and gives 3.5 exaunits."
    );
    (uint got, uint gave) = tkr.marketOrder({
      wants: 2.7 ether,
      gives: 3.5 ether
    });
    Display.log("Market order ended. Got / gave", got, gave);

    TestUtils.logOfferBook(mgv, address(bat), address(dai), 1);
    Display.logBalances(
      [address(bat), address(dai)],
      address(mkr),
      address(tkr)
    );
  }

  function example_3_redeem_test() public {
    setupMakerCompound();

    Display.log("Maker posts an offer for 1 exaunit");
    uint ofr = mkr.newOffer({
      wants: 1 ether,
      gives: 1 ether,
      gasreq: 600_000,
      pivotId: 0
    });

    TestUtils.logOfferBook(mgv, address(bat), address(dai), 1);
    Display.logBalances(
      [address(bat), address(dai)],
      address(mkr),
      address(tkr),
      address(compound)
    );
    Display.logBalances(
      [address(compound.c(bat)), address(compound.c(dai))],
      address(mkr)
    );

    Display.log("Taker takes offer for 0.3 exaunits");
    bool took = tkr.take(ofr, 0.3 ether);
    if (took) {
      Display.log("Take successful");
    } else {
      Display.log("Take failed");
    }

    TestUtils.logOfferBook(mgv, address(bat), address(dai), 1);
    Display.logBalances(
      [address(bat), address(dai)],
      address(mkr),
      address(tkr),
      address(compound)
    );
  }

  function example_4_callback_test() public {
    setupMakerCallback();

    Display.log("Maker posts 1 offer");
    mkr.newOffer({wants: 1 ether, gives: 1 ether, gasreq: 400_000, pivotId: 0});

    TestUtils.logOfferBook(mgv, address(bat), address(dai), 1);
    Display.logBalances(
      [address(bat), address(dai)],
      address(mkr),
      address(tkr)
    );

    Display.log(
      "Market order begins. Maker will be called back and reinsert its offer"
    );
    (uint got, uint gave) = tkr.marketOrder({wants: 1 ether, gives: 1 ether});
    Display.log("Market order complete. got / gave:", got, gave);

    TestUtils.logOfferBook(mgv, address(bat), address(dai), 1);
    Display.logBalances(
      [address(bat), address(dai)],
      address(mkr),
      address(tkr)
    );
  }

  function _beforeAll() public {
    bat = new TestToken({
      admin: address(this),
      name: "Basic attention token",
      symbol: "BAT"
    });

    dai = new TestToken({admin: address(this), name: "Dai", symbol: "DAI"});

    mgv = new Mangrove({
      governance: address(this),
      gasprice: 40,
      gasmax: 1_000_000
    });

    // activate a market where taker buys BAT using DAI
    mgv.activate({
      outbound_tkn: address(bat),
      inbound_tkn: address(dai),
      fee: 0,
      density: 100,
      offer_gasbase: 10_000
    });

    tkr = new TestTaker({mgv: mgv, base: bat, quote: dai});

    mgv.fund{value: 10 ether}(address(this));

    dai.mint({amount: 10 ether, to: address(tkr)});
    tkr.approveMgv({amount: 10 ether, token: dai});

    Display.register({addr: msg.sender, name: "Test Runner"});
    Display.register({addr: address(this), name: "Testing Contract"});
    Display.register({addr: address(bat), name: "BAT"});
    Display.register({addr: address(dai), name: "DAI"});
    Display.register({addr: address(mgv), name: "mgv"});
    Display.register({addr: address(tkr), name: "taker"});
  }

  function setupMakerBasic() internal {
    mkr = new Maker_basic({mgv: mgv, base: bat, quote: dai});

    Display.register({addr: address(mkr), name: "maker-basic"});

    // testing contract starts with 1000 ETH
    payable(mkr).transfer(10 ether);
    mkr.provisionMgv({amount: 5 ether});
    bat.mint({amount: 10 ether, to: address(mkr)});
  }

  function setupMakerCompound() internal {
    compound = new Compound();
    Display.register(address(compound), "compound");
    Display.register(address(compound.c(bat)), "cBAT");
    Display.register(address(compound.c(dai)), "cDAI");

    Maker_compound _mkr = new Maker_compound({
      mgv: mgv,
      base: bat,
      quote: dai,
      compound: compound
    });

    mkr = _mkr;

    bat.mint({amount: 10 ether, to: address(mkr)});
    _mkr.useCompound();

    Display.register({addr: address(mkr), name: "maker-compound"});

    // testing contract starts with 1000 ETH
    payable(mkr).transfer(10 ether);
    mkr.provisionMgv({amount: 5 ether});
  }

  function setupMakerCallback() internal {
    Display.log("Setting up maker with synchronous callback");
    mkr = new Maker_callback({mgv: mgv, base: bat, quote: dai});

    Display.register({addr: address(mkr), name: "maker-callback"});

    // testing contract starts with 1000 ETH
    payable(mkr).transfer(10 ether);
    mkr.provisionMgv({amount: 5 ether});

    bat.mint({amount: 10 ether, to: address(mkr)});
  }
}

// Provisioned.
// Sends amount to taker.
contract Maker_basic is TestMaker {
  constructor(
    AbstractMangrove mgv,
    ERC20BL base,
    ERC20BL quote
  ) TestMaker(mgv, base, quote) {
    approveMgv(base, 500 ether);
  }

  function makerExecute(ML.SingleOrder calldata)
    public
    pure
    override
    returns (bytes32)
  {
    return "";
    //ERC20(order.outbound_tkn).transfer({recipient: taker, amount: order.wants});
  }
}

// Not provisioned.
// Redeems money from fake-Compound
contract Maker_compound is TestMaker {
  Compound _compound;

  constructor(
    AbstractMangrove mgv,
    ERC20BL base,
    ERC20BL quote,
    Compound compound
  ) TestMaker(mgv, base, quote) {
    _compound = compound;
    approveMgv(base, 500 ether);
    base.approve(address(compound), 500 ether);
    quote.approve(address(compound), 500 ether);
  }

  function useCompound() external {
    Display.log("Maker deposits 10 exaunits at Compound.");
    _compound.mint(ERC20BL(_base), 10 ether);
  }

  function makerExecute(ML.SingleOrder calldata order)
    public
    override
    returns (bytes32)
  {
    _compound.mint({token: ERC20BL(order.inbound_tkn), amount: order.gives});
    Display.log("Maker redeems from Compound.");
    _compound.redeem({
      token: ERC20BL(order.outbound_tkn),
      amount: order.wants,
      to: address(this)
    });
    return "";
  }
}

// Provisioned.
// Reinserts the offer if necessary.
contract Maker_callback is TestMaker {
  constructor(
    AbstractMangrove mgv,
    ERC20BL base,
    ERC20BL quote
  ) TestMaker(mgv, base, quote) {
    approveMgv(base, 500 ether);
  }

  function makerExecute(ML.SingleOrder calldata)
    public
    pure
    override
    returns (bytes32)
  {
    return "";
    //ERC20BL(order.outbound_tkn).transfer({recipient: taker, amount: order.wants});
  }

  uint volume = 1 ether;
  uint price = 340; // in %
  uint gasreq = 400_000;

  function makerPosthook(ML.SingleOrder calldata order, ML.OrderResult calldata)
    external
    override
  {
    Display.log("Reinserting offer...");
    AbstractMangrove mgv = AbstractMangrove(payable(msg.sender));
    mgv.updateOffer({
      outbound_tkn: order.outbound_tkn,
      inbound_tkn: order.inbound_tkn,
      wants: (price * volume) / 100,
      gives: volume,
      gasreq: gasreq,
      gasprice: 0,
      pivotId: 0,
      offerId: order.offerId
    });
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "hardhat/console.sol";

import "../Toolbox/TestUtils.sol";

import "./TestToken.sol";

contract Compound {
  constructor() {}

  mapping(ERC20BL => mapping(address => uint)) deposits;
  mapping(ERC20BL => TestToken) cTokens;

  //function grant(address to, IERC20 token, uint amount) {
  //deposits[token][to] += amount;
  //c(token).mint(to, amount);
  //}

  function c(ERC20BL token) public returns (TestToken) {
    if (address(cTokens[token]) == address(0)) {
      string memory cName = TestUtils.append("c", token.name());
      string memory cSymbol = TestUtils.append("c", token.symbol());
      cTokens[token] = new TestToken(address(this), cName, cSymbol);
    }

    return cTokens[token];
  }

  function mint(ERC20BL token, uint amount) external {
    token.transferFrom(msg.sender, address(this), amount);
    deposits[token][msg.sender] += amount;
    c(token).mint(msg.sender, amount);
  }

  function redeem(
    address to,
    ERC20BL token,
    uint amount
  ) external {
    c(token).burn(msg.sender, amount);
    token.transfer(to, amount);
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "../AbstractMangrove.sol";
import "hardhat/console.sol";
import "../MgvLib.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMonitor.sol";

// In these tests, the testing contract is the market maker.
contract Monitor_Test {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  receive() external payable {}

  AbstractMangrove mgv;
  TestMaker mkr;
  MgvMonitor monitor;
  address base;
  address quote;

  function a_beforeAll() public {
    TestToken baseT = TokenSetup.setup("A", "$A");
    TestToken quoteT = TokenSetup.setup("B", "$B");
    monitor = new MgvMonitor();
    base = address(baseT);
    quote = address(quoteT);
    mgv = MgvSetup.setup(baseT, quoteT);
    mkr = MakerSetup.setup(mgv, base, quote);

    payable(mkr).transfer(10 ether);

    mkr.provisionMgv(5 ether);
    bool noRevert;
    (noRevert, ) = address(mgv).call{value: 10 ether}("");

    baseT.mint(address(mkr), 2 ether);
    quoteT.mint(address(this), 2 ether);

    baseT.approve(address(mgv), 1 ether);
    quoteT.approve(address(mgv), 1 ether);

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "Test Contract");
    Display.register(base, "$A");
    Display.register(quote, "$B");
    Display.register(address(mgv), "mgv");
    Display.register(address(mkr), "maker[$A,$B]");
  }

  function initial_monitor_values_test() public {
    (P.Global.t config, ) = mgv.config(base, quote);
    TestEvents.check(
      !config.useOracle(),
      "initial useOracle should be false"
    );
    TestEvents.check(
      !config.notify(),
      "initial notify should be false"
    );
  }

  function set_monitor_values_test() public {
    mgv.setMonitor(address(monitor));
    mgv.setUseOracle(true);
    mgv.setNotify(true);
    (P.Global.t config, ) = mgv.config(base, quote);
    TestEvents.eq(
      config.monitor(),
      address(monitor),
      "monitor should be set"
    );
    TestEvents.check(
      config.useOracle(),
      "useOracle should be set"
    );
    TestEvents.check(
      config.notify(),
      "notify should be set"
    );
  }

  function set_oracle_density_with_useOracle_works_test() public {
    mgv.setMonitor(address(monitor));
    mgv.setUseOracle(true);
    mgv.setDensity(base, quote, 898);
    monitor.setDensity(base, quote, 899);
    (, P.Local.t config) = mgv.config(base, quote);
    TestEvents.eq(
      config.density(),
      899,
      "density should be set oracle"
    );
  }

  function set_oracle_density_without_useOracle_fails_test() public {
    mgv.setMonitor(address(monitor));
    mgv.setDensity(base, quote, 898);
    monitor.setDensity(base, quote, 899);
    (, P.Local.t config) = mgv.config(base, quote);
    TestEvents.eq(
      config.density(),
      898,
      "density should be set by mgv"
    );
  }

  function set_oracle_gasprice_with_useOracle_works_test() public {
    mgv.setMonitor(address(monitor));
    mgv.setUseOracle(true);
    mgv.setGasprice(900);
    monitor.setGasprice(901);
    (P.Global.t config, ) = mgv.config(base, quote);
    TestEvents.eq(
      config.gasprice(),
      901,
      "gasprice should be set by oracle"
    );
  }

  function set_oracle_gasprice_without_useOracle_fails_test() public {
    mgv.setMonitor(address(monitor));
    mgv.setGasprice(900);
    monitor.setGasprice(901);
    (P.Global.t config, ) = mgv.config(base, quote);
    TestEvents.eq(
      config.gasprice(),
      900,
      "gasprice should be set by mgv"
    );
  }

  function invalid_oracle_address_throws_test() public {
    mgv.setMonitor(address(42));
    mgv.setUseOracle(true);
    try mgv.config(base, quote) {
      TestEvents.fail("Call to invalid oracle address should throw");
    } catch {
      TestEvents.succeed();
    }
  }

  function notify_works_on_success_when_set_test() public {
    mkr.approveMgv(IERC20(base), 1 ether);
    mgv.setMonitor(address(monitor));
    mgv.setNotify(true);
    uint ofrId = mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    P.Offer.t offer = mgv.offers(base, quote, ofrId);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofrId, 0.04 ether, 0.05 ether, 100_000];
    (uint successes, , , ) = mgv.snipes(base, quote, targets, true);
    TestEvents.check(successes == 1, "snipe should succeed");
    (P.Global.t _global, P.Local.t _local) = mgv.config(base, quote);
    _local = _local.best(1).lock(true);

    ML.SingleOrder memory order = ML.SingleOrder({
      outbound_tkn: base,
      inbound_tkn: quote,
      offerId: ofrId,
      offer: offer,
      wants: 0.04 ether,
      gives: 0.04 ether, // wants has been updated to offer price
      offerDetail: mgv.offerDetails(base, quote, ofrId),
      global: _global,
      local: _local
    });

    TestEvents.expectFrom(address(monitor));
    emit L.TradeSuccess(order, address(this));
  }

  function notify_works_on_fail_when_set_test() public {
    mgv.setMonitor(address(monitor));
    mgv.setNotify(true);
    uint ofrId = mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    P.Offer.t offer = mgv.offers(base, quote, ofrId);
    P.OfferDetail.t offerDetail = mgv.offerDetails(base, quote, ofrId);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofrId, 0.04 ether, 0.05 ether, 100_000];
    (uint successes, , , ) = mgv.snipes(base, quote, targets, true);
    TestEvents.check(successes == 0, "snipe should fail");

    (P.Global.t _global, P.Local.t _local) = mgv.config(base, quote);
    // config sent during maker callback has stale best and, is locked
    _local = _local.best(1).lock(true);

    ML.SingleOrder memory order = ML.SingleOrder({
      outbound_tkn: base,
      inbound_tkn: quote,
      offerId: ofrId,
      offer: offer,
      wants: 0.04 ether,
      gives: 0.04 ether, // gives has been updated to offer price
      offerDetail: offerDetail, // gasprice logged will still be as before failure
      global: _global,
      local: _local
    });

    TestEvents.expectFrom(address(monitor));
    emit L.TradeFail(order, address(this));
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "../../MgvLib.sol";

library L {
  event TradeSuccess(MgvLib.SingleOrder order, address taker);
  event TradeFail(MgvLib.SingleOrder order, address taker);
}

contract MgvMonitor is IMgvMonitor {
  uint gasprice;
  mapping(address => mapping(address => uint)) private densities;

  function setGasprice(uint _gasprice) external {
    gasprice = _gasprice;
  }

  function setDensity(
    address base,
    address quote,
    uint _density
  ) external {
    densities[base][quote] = _density;
  }

  function read(address base, address quote)
    external
    view
    override
    returns (uint, uint)
  {
    return (gasprice, densities[base][quote]);
  }

  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker)
    external
    override
  {
    emit L.TradeSuccess(sor, taker);
  }

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker)
    external
    override
  {
    emit L.TradeFail(sor, taker);
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "../AbstractMangrove.sol";
import "../MgvLib.sol";
import "hardhat/console.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";
import "./Agents/TestTaker.sol";
import "./Agents/MM1.sol";

contract MM1T_Test {
  receive() external payable {}

  AbstractMangrove mgv;
  TestTaker tkr;
  TestMaker mkr;
  MM1 mm1;
  address base;
  address quote;

  function a_beforeAll() public {
    TestToken baseT = TokenSetup.setup("A", "$A");
    TestToken quoteT = TokenSetup.setup("B", "$B");
    base = address(baseT);
    quote = address(quoteT);
    mgv = MgvSetup.setup(baseT, quoteT);
    tkr = TakerSetup.setup(mgv, base, quote);
    mkr = MakerSetup.setup(mgv, base, quote);
    mm1 = new MM1{value: 2 ether}(mgv, base, quote);

    payable(tkr).transfer(10 ether);
    payable(mkr).transfer(10 ether);

    //bool noRevert;
    //(noRevert, ) = address(mgv).call{value: 10 ether}("");

    mkr.provisionMgv(5 ether);

    baseT.mint(address(tkr), 10 ether);
    baseT.mint(address(mkr), 10 ether);
    baseT.mint(address(mm1), 2 ether);

    quoteT.mint(address(tkr), 10 ether);
    quoteT.mint(address(mkr), 10 ether);
    quoteT.mint(address(mm1), 2 ether);

    mm1.refresh();

    //baseT.approve(address(mgv), 1 ether);
    //quoteT.approve(address(mgv), 1 ether);
    tkr.approveMgv(quoteT, 1000 ether);
    tkr.approveMgv(baseT, 1000 ether);
    mkr.approveMgv(quoteT, 1000 ether);
    mkr.approveMgv(baseT, 1000 ether);

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "Gatekeeping_Test/maker");
    Display.register(base, "$A");
    Display.register(quote, "$B");
    Display.register(address(mgv), "mgv");
    Display.register(address(tkr), "taker[$A,$B]");
    //Display.register(address(dual_mkr), "maker[$B,$A]");
    Display.register(address(mkr), "maker");
    Display.register(address(mm1), "MM1");
  }

  function ta_test() public {
    TestUtils.logOfferBook(mgv, base, quote, 3);
    TestUtils.logOfferBook(mgv, quote, base, 3);
    (P.OfferStruct memory ofr, ) = mgv.offerInfo(base, quote, 1);
    console.log("prev", ofr.prev);
    mkr.newOffer(base, quote, 0.05 ether, 0.1 ether, 200_000, 0);
    mkr.newOffer(quote, base, 0.05 ether, 0.05 ether, 200_000, 0);
    TestUtils.logOfferBook(mgv, base, quote, 3);
    TestUtils.logOfferBook(mgv, quote, base, 3);

    tkr.marketOrder(0.01 ether, 0.01 ether);
    TestUtils.logOfferBook(mgv, base, quote, 3);
    TestUtils.logOfferBook(mgv, quote, base, 3);

    mkr.newOffer(base, quote, 0.05 ether, 0.1 ether, 200_000, 0);
    mm1.refresh();
    TestUtils.logOfferBook(mgv, base, quote, 3);
    TestUtils.logOfferBook(mgv, quote, base, 3);
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;
import {ITaker, IMaker, MgvLib as DC, HasMgvEvents, IMgvMonitor, P} from "../../MgvLib.sol";
import "../../AbstractMangrove.sol";
import "../Toolbox/TestUtils.sol";
import "hardhat/console.sol";

/* TODO
 * dans makerExecute: check oracle price to see if I'm still in reasonable spread
 * don't sell all liquidity otherwie what is my price when I have 0 balance ? at least check that.
 */

contract MM1 {
  uint immutable sell_id;
  uint immutable buy_id;
  address immutable a_addr;
  address immutable b_addr;
  AbstractMangrove immutable mgv;

  /* This MM has 1 offer on each side of a book. After each take, it updates both offers.
     The new price is based on the midprice between each books, a base_spread,
     and the ratio of a/b inventories normalized by the current midprice. */

  constructor(
    AbstractMangrove _mgv,
    address _a_addr,
    address _b_addr
  ) payable {
    mgv = _mgv;
    a_addr = _a_addr;
    b_addr = _b_addr;

    _mgv.fund{value: 1 ether}(address(this));

    IERC20(_a_addr).approve(address(_mgv), 10000 ether);
    IERC20(_b_addr).approve(address(_mgv), 10000 ether);

    sell_id = _mgv.newOffer(_a_addr, _b_addr, 1, 1 ether, 40_000, 0, 0);
    buy_id = _mgv.newOffer(_b_addr, _a_addr, 1, 1 ether, 40_000, 0, 0);
  }

  function refresh() external {
    doMakerPosthook();
  }

  function makerExecute(DC.SingleOrder calldata) external pure returns (bytes32) {
    return "";
  }

  function makerPosthook(DC.SingleOrder calldata, DC.OrderResult calldata)
    external
  {
    doMakerPosthook();
  }

  /* Shifting to avoid overflows during intermediary steps */
  /* TODO use a fixed point library */
  uint constant SHF = 30;

  function doMakerPosthook() internal {
    // a&b must be k bits at most
    uint b = IERC20(b_addr).balanceOf(address(this)) >> SHF;
    uint a = IERC20(a_addr).balanceOf(address(this)) >> SHF;

    //console.log("b",b);
    //console.log("a",a);

    uint base_spread = 500; // base_spread is in basis points
    uint d_d = 10000; // delta = d_n / d_d

    // best offers
    uint best_sell_id = mgv.best(a_addr, b_addr);
    (P.OfferStruct memory best_sell, ) = mgv.offerInfo(a_addr, b_addr, best_sell_id);

    //console.log("initial bs.w",best_sell.wants);
    //console.log("initial bs.g",best_sell.gives);

    // if no offer on a/b pair
    if (
      best_sell_id == sell_id || (best_sell.wants == 0 && best_sell.gives == 0)
    ) {
      //console.log("no offer on a/b pair");
      best_sell.wants = b;
      best_sell.gives = a;
    } else {
      best_sell.wants = best_sell.wants >> SHF;
      best_sell.gives = best_sell.gives >> SHF;
    }

    //console.log("bs.w",best_sell.wants);
    //console.log("bs.g",best_sell.gives);

    uint best_buy_id = mgv.best(b_addr, a_addr);
    (P.OfferStruct memory best_buy, ) = mgv.offerInfo(b_addr, a_addr, best_buy_id);

    //console.log("initial bb.w",best_buy.wants);
    //console.log("initial bb.g",best_buy.gives);

    // if no offer on b/a pair
    if (best_buy_id == buy_id || (best_buy.wants == 0 && best_buy.gives == 0)) {
      //console.log("no offer on b/a pair");
      best_buy.wants = a;
      best_buy.gives = b;
    } else {
      best_buy.wants = best_buy.wants >> SHF;
      best_buy.gives = best_buy.gives >> SHF;
    }

    //console.log("bb.w",best_buy.wants);
    //console.log("bb.g",best_buy.gives);

    // average price numerator (same for buy&sell)
    // at most (96-SHF)*2+1 bits
    uint m_n = best_sell.wants *
      best_buy.wants +
      best_sell.gives *
      best_buy.gives;
    //console.log("m_n",m_n);

    uint d_n = 10000 + base_spread; // at most 14 bits

    /* SELL */
    /********/
    {
      // midprice of A in B is m_n/sell_m_d
      // at most (96-SHF)*2+1 bits
      uint sell_m_d = 2 * best_sell.gives * best_buy.wants;
      //console.log("sell_m_d",sell_m_d);

      uint sell_gives = a << SHF;
      //console.log("sell_gives",sell_gives);
      // normalized_BA_inv_ratio = b / (2 * a * b)
      // skew = 0.5 + inv/2 = (m_n * a + sell_m_d * b) / (2 * m_n * a)
      // sell_wants = delta * midprice * a * skew

      uint sell_wants_n = (d_n * (m_n * a + sell_m_d * b)) << (3 * SHF);
      //console.log("sell_wants_n",sell_wants_n);
      uint sell_wants_d = (2 * sell_m_d * d_d) << (3 * SHF);
      //console.log("sell_wants_d",sell_wants_d);
      uint sell_wants = (sell_wants_n / sell_wants_d) << SHF;

      //console.log("sell_wants",sell_wants);
      //console.log("sell_gives",sell_gives);
      Display.log(sell_wants, sell_gives);

      mgv.updateOffer({
        outbound_tkn: a_addr,
        inbound_tkn: b_addr,
        wants: sell_wants,
        gives: sell_gives,
        gasreq: 400_000,
        gasprice: 0,
        pivotId: sell_id,
        offerId: sell_id
      });
    }

    /* BUY */
    /*******/

    uint buy_m_d = 2 * best_sell.wants * best_buy.gives;

    uint buy_gives = b << SHF;

    // buy_wants = buy_delta * buy_midprice * b * buy_skew;
    uint buy_wants_n = d_n * (m_n * b + buy_m_d * a);
    uint buy_wants_d = 2 * buy_m_d * d_d;
    uint buy_wants = (buy_wants_n / buy_wants_d) << SHF;

    mgv.updateOffer({
      outbound_tkn: b_addr,
      inbound_tkn: a_addr,
      wants: buy_wants,
      gives: buy_gives,
      gasreq: 400_000,
      gasprice: 0,
      pivotId: buy_id,
      offerId: buy_id
    });
  }
}

// SPDX-License-Identifier: Unlicense

// We can't even encode storage references without the experimental encoder
pragma abicoder v2;

pragma solidity ^0.8.10;
import {Test as T} from "@giry/hardhat-test-solidity/test.sol";
import "hardhat/console.sol";

contract Throw_Test {
  bool called;

  receive() external payable {}

  function throws() external {
    bytes memory s = new bytes(1000); //spend some gas
    s;
    called = true;
  }

  function not_enough_gas_to_call_test() public {
    try this.throws{gas: 100}() {
      T.fail("Function should have failed");
    } catch {
      T.check(!called, "Function should not have been called");
    }
  }

  function enough_gas_to_call_test() public {
    try this.throws{gas: 1000}() {
      T.fail("Function should have failed");
    } catch {
      T.check(!called, "Function should have run out of gas");
    }
  }
}

// SPDX-License-Identifier: Unlicense

/* Testing bad storage encoding */

// We can't even encode storage references without the experimental encoder
pragma abicoder v2;

pragma solidity ^0.8.10;
import {Test as TestEvents} from "@giry/hardhat-test-solidity/test.sol";
import "hardhat/console.sol";

contract StorageEncoding {}

struct S {
  uint a;
}

library Lib {
  function a(S storage s) public view {
    s; // silence warning about unused parameter
    console.log("in Lib.a: calldata received");
    console.logBytes(msg.data);
  }
}

contract Failer_Test {
  receive() external payable {}

  function exec() external view {
    console.log("exec");
    require(false);
  }

  function execBig() external view {
    console.log("execBig");
    string memory wtf = new string(100_000);
    require(false, wtf);
  }

  function failed_yul_test() public {
    bytes memory b = new bytes(100_000);
    b;
    uint g0 = gasleft();
    bytes memory cd = abi.encodeWithSelector(this.execBig.selector);
    bytes memory retdata = new bytes(32);
    assembly {
      let success := delegatecall(
        500000,
        address(),
        add(cd, 32),
        4,
        add(retdata, 32),
        0
      )
    }
    console.log("GasUsed: %d", g0 - gasleft());
  }

  function failer_small_test() public {
    uint g0 = gasleft();
    (bool success, bytes memory retdata) = address(this).delegatecall{
      gas: 500_000
    }(abi.encodeWithSelector(this.exec.selector));
    success;
    retdata;
    console.log("GasUsed: %d", g0 - gasleft());
  }

  function failer_big_with_retdata_bytes_test() public {
    bytes memory b = new bytes(100_000);
    b;
    uint g0 = gasleft();
    (bool success, bytes memory retdata) = address(this).delegatecall{
      gas: 500_000
    }(abi.encodeWithSelector(this.execBig.selector));
    success;
    retdata;

    console.log("GasUsed: %d", g0 - gasleft());
  }
}

contract StorageEncoding_Test {
  receive() external payable {}

  S sss; // We add some padding so the storage ref for s is not 0
  S ss;
  S s;

  function _test() public {
    console.log("Lib.a selector:");
    console.logBytes4(Lib.a.selector);
    console.log("___________________");

    console.log("[Encoding s manually]");
    console.log("abi.encodeWithSelector(Lib.a.selector,s)):");
    bytes memory data = abi.encodeWithSelector(Lib.a.selector, s);
    console.logBytes(data);
    console.log("Calling address(Lib).delegatecall(u)...");
    bool success;
    (success, ) = address(Lib).delegatecall(data);
    console.log("___________________");

    console.log("[Encoding s with compiler]");
    console.log("Calling Lib.a(s)...");
    Lib.a(s);
    console.log("___________________");
  }
}

contract Abi_Test {
  receive() external payable {}

  function wordOfBytes(bytes memory data) internal pure returns (bytes32 w) {
    assembly {
      w := mload(add(data, 32))
    }
  }

  function bytesOfWord(bytes32 w) internal pure returns (bytes memory data) {
    data = new bytes(32);
    assembly {
      mstore(add(data, 32), w)
    }
  }

  function wordOfUint(uint x) internal pure returns (bytes32 w) {
    w = bytes32(x);
  }

  enum Arity {
    N,
    U,
    B,
    T
  }
  bytes32 constant MASKHEADER =
    0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  bytes32 constant MASKFIRSTARG =
    0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffff;

  function encode_decode_test() public {
    bytes memory x = abi.encodePacked(
      Arity.B,
      uint96(1 ether),
      uint96(2 ether)
    );
    bytes32 w = wordOfBytes(x);
    console.logBytes32(w);
    console.logBytes32(w >> (31 * 8));
    bytes memory header = bytesOfWord(w >> (31 * 8)); // header is encode in the first byte
    Arity t = abi.decode(header, (Arity));
    TestEvents.check(t == Arity.B, "Incorrect decoding of header");
    bytes memory arg1 = bytesOfWord((w & MASKHEADER) >> (19 * 8));
    console.logBytes(arg1);
    TestEvents.check(
      uint96(1 ether) == abi.decode(arg1, (uint96)),
      "Incorrect decoding of arg1"
    );
    bytes memory arg2 = bytesOfWord((w & MASKFIRSTARG) >> (7 * 8));
    console.logBytes(arg2);
    TestEvents.check(
      uint96(2 ether) == abi.decode(arg2, (uint96)),
      "Incorrect decoding of arg2"
    );
  }
}

// contract EncodeDecode_Test {
//   receive() external payable {}
//   enum T {U,B}

//   function encode(uint192 x) internal view returns (bytes memory){
//     console.log("encoding",uint(x));
//     bytes memory data = new bytes(32);
//     data = abi.encode(T.U,abi.encode(x));
//     console.logBytes(data);
//     return data;
//   }
//   function encode(uint96 x, uint96 y) internal view returns (bytes memory){
//     console.log("encoding",uint(x),uint(y));

//     bytes memory data = new bytes(32);
//     data = abi.encode(T.B,abi.encode(x,y));
//     console.logBytes(data);
//     return data;
//   }

//   function decode(bytes memory data) internal view returns (uint[] memory) {
//     console.log("Decoding");
//     console.logBytes(data);
//     (T t,bytes memory data_) = abi.decode(data,(T,bytes));
//     if (t==T.B) {
//       console.log("Binary predicate detected");
//       uint[] memory args = new uint[](2);
//       (uint96 x, uint96 y) = abi.decode(data_,(uint96,uint96));
//       args[0] = uint(x);
//       args[1] = uint(y);
//       return args;
//     }
//     else{
//       console.log("Unary predicate detected");
//       uint[] memory args = new uint[](1);
//       args[0] = uint(abi.decode(data_,(uint192)));
//       return args;
//     }
//   }

//   function encode_decode(uint x) internal view {
//     bytes memory data = encode(uint192(x));
//     uint[] memory args = decode(data);
//     for (uint i=0;i<args.length;i++){
//       console.log(args[i]);
//     }
//   }

//   function encode_decode(uint x, uint y) internal view {
//     bytes memory data = encode(uint96(x), uint96(y));
//     uint[] memory args = decode(data);
//     for (uint i=0;i<args.length;i++){
//       console.log(args[i]);
//     }
//   }

//   function encode_decode_test() public view {
//     encode_decode(123456789);
//     encode_decode(1234,56789);
//   }

// }

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "../AbstractMangrove.sol";
import "../MgvLib.sol";
import "hardhat/console.sol";
import "@giry/hardhat-test-solidity/test.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";
import "./Agents/MakerDeployer.sol";
import "./Agents/TestTaker.sol";
import {MgvReader} from "../periphery/MgvReader.sol";

contract Oracle {
  function read(address /*base*/, address /*quote*/)
    external
    pure
    returns (uint, uint)
  {
    return (23, 2);
  }
}

// In these tests, the testing contract is the market maker.
contract MgvReader_Test is HasMgvEvents {
  receive() external payable {}

  AbstractMangrove mgv;
  TestMaker mkr;
  MgvReader reader;
  address base;
  address quote;
  Oracle oracle;

  function a_beforeAll() public {
    TestToken baseT = TokenSetup.setup("A", "$A");
    TestToken quoteT = TokenSetup.setup("B", "$B");
    oracle = new Oracle();

    base = address(baseT);
    quote = address(quoteT);
    mgv = MgvSetup.setup(baseT, quoteT);
    mkr = MakerSetup.setup(mgv, base, quote);
    reader = new MgvReader(address(mgv));

    payable(mkr).transfer(10 ether);

    bool noRevert;
    (noRevert, ) = address(mgv).call{value: 10 ether}("");

    mkr.provisionMgv(5 ether);

    baseT.mint(address(this), 2 ether);
    quoteT.mint(address(mkr), 1 ether);

    baseT.approve(address(mgv), 1 ether);
    quoteT.approve(address(mgv), 1 ether);

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "Gatekeeping_Test/maker");
    Display.register(base, "$A");
    Display.register(quote, "$B");
    Display.register(address(mgv), "mgv");
    Display.register(address(mkr), "maker[$A,$B]");
  }

  function read_packed_test() public {
    (
      uint currentId,
      uint[] memory offerIds,
      P.OfferStruct[] memory offers,
      P.OfferDetailStruct[] memory details
    ) = reader.offerList(base, quote, 0, 50);

    TestEvents.eq(offerIds.length, 0, "ids: wrong length on 2elem");
    TestEvents.eq(offers.length, 0, "offers: wrong length on 1elem");
    TestEvents.eq(details.length, 0, "details: wrong length on 1elem");
    // test 1 elem
    mkr.newOffer(1 ether, 1 ether, 10_000, 0);

    (currentId, offerIds, offers, details) = reader.offerList(
      base,
      quote,
      0,
      50
    );

    TestEvents.eq(offerIds.length, 1, "ids: wrong length on 1elem");
    TestEvents.eq(offers.length, 1, "offers: wrong length on 1elem");
    TestEvents.eq(details.length, 1, "details: wrong length on 1elem");

    // test 2 elem
    mkr.newOffer(0.9 ether, 1 ether, 10_000, 0);

    (currentId, offerIds, offers, details) = reader.offerList(
      base,
      quote,
      0,
      50
    );

    TestEvents.eq(offerIds.length, 2, "ids: wrong length on 2elem");
    TestEvents.eq(offers.length, 2, "offers: wrong length on 1elem");
    TestEvents.eq(details.length, 2, "details: wrong length on 1elem");

    // test 2 elem read from elem 1
    (currentId, offerIds, offers, details) = reader.offerList(
      base,
      quote,
      1,
      50
    );
    TestEvents.eq(
      offerIds.length,
      1,
      "ids: wrong length 2elem start from id 1"
    );
    TestEvents.eq(offers.length, 1, "offers: wrong length on 1elem");
    TestEvents.eq(details.length, 1, "details: wrong length on 1elem");

    // test 3 elem read in chunks of 2
    mkr.newOffer(0.8 ether, 1 ether, 10_000, 0);
    (currentId, offerIds, offers, details) = reader.offerList(
      base,
      quote,
      0,
      2
    );
    TestEvents.eq(
      offerIds.length,
      2,
      "ids: wrong length on 3elem chunk size 2"
    );
    TestEvents.eq(offers.length, 2, "offers: wrong length on 1elem");
    TestEvents.eq(details.length, 2, "details: wrong length on 1elem");

    // test offer order
    (currentId, offerIds, offers, details) = reader.offerList(
      base,
      quote,
      0,
      50
    );
    TestEvents.eq(offers[0].wants, 0.8 ether, "wrong wants for offers[0]");
    TestEvents.eq(offers[1].wants, 0.9 ether, "wrong wants for offers[0]");
    TestEvents.eq(offers[2].wants, 1 ether, "wrong wants for offers[0]");
  }

  function returns_zero_on_nonexisting_offer_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 10_000, 0);
    mkr.retractOffer(ofr);
    (, uint[] memory offerIds, , ) = reader.offerList(base, quote, ofr, 50);
    TestEvents.eq(
      offerIds.length,
      0,
      "should have 0 offers since starting point is out of the book"
    );
  }

  function no_wasted_time_test() public {
    reader.offerList(base, quote, 0, 50); // warming up caches

    uint g = gasleft();
    reader.offerList(base, quote, 0, 50);
    uint used1 = g - gasleft();

    g = gasleft();
    reader.offerList(base, quote, 0, 50000000);
    uint used2 = g - gasleft();

    TestEvents.eq(
      used1,
      used2,
      "gas spent should not depend on maxOffers when offers length < maxOffers"
    );
  }

  function correct_endpoints_0_test() public {
    uint startId;
    uint length;
    (startId, length) = reader.offerListEndPoints(base, quote, 0, 100000);
    TestEvents.eq(startId, 0, "0.0 wrong startId");
    TestEvents.eq(length, 0, "0.0 wrong length");

    (startId, length) = reader.offerListEndPoints(base, quote, 32, 100000);
    TestEvents.eq(startId, 0, "0.1 wrong startId");
    TestEvents.eq(length, 0, "0.1 wrong length");
  }

  function correct_endpoints_1_test() public {
    uint startId;
    uint length;
    uint ofr;
    ofr = mkr.newOffer(1 ether, 1 ether, 50_000, 0);

    (startId, length) = reader.offerListEndPoints(base, quote, 0, 0);
    TestEvents.eq(startId, 1, "1.0 wrong startId");
    TestEvents.eq(length, 0, "1.0 wrong length");

    (startId, length) = reader.offerListEndPoints(base, quote, 1, 1);
    TestEvents.eq(startId, 1, "1.1 wrong startId");
    TestEvents.eq(length, 1, "1.1 wrong length");

    (startId, length) = reader.offerListEndPoints(base, quote, 1, 1321);
    TestEvents.eq(startId, 1, "1.2 wrong startId");
    TestEvents.eq(length, 1, "1.2 wrong length");

    (startId, length) = reader.offerListEndPoints(base, quote, 2, 12);
    TestEvents.eq(startId, 0, "1.0 wrong startId");
    TestEvents.eq(length, 0, "1.0 wrong length");
  }

  function try_provision() internal {
    uint prov = reader.getProvision(base, quote, 0, 0);
    uint bal1 = mgv.balanceOf(address(mkr));
    mkr.newOffer(1 ether, 1 ether, 0, 0);
    uint bal2 = mgv.balanceOf(address(mkr));
    TestEvents.eq(bal1 - bal2, prov, "provision computation is wrong");
  }

  function provision_0_test() public {
    try_provision();
  }

  function provision_1_test() public {
    mgv.setGasbase(base, quote, 17_000);
    try_provision();
  }

  function provision_oracle_test() public {
    mgv.setMonitor(address(oracle));
    mgv.setUseOracle(true);
    try_provision();
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvReader.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, P} from "../MgvLib.sol";

interface MangroveLike {
  function best(address, address) external view returns (uint);

  function offers(
    address,
    address,
    uint
  ) external view returns (P.Offer.t);

  function offerDetails(
    address,
    address,
    uint
  ) external view returns (P.OfferDetail.t);

  function offerInfo(
    address,
    address,
    uint
  ) external view returns (P.OfferStruct memory, P.OfferDetailStruct memory);

  function config(address, address) external view returns (P.Global.t, P.Local.t);
}

contract MgvReader {
  using P.Offer for P.Offer.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  MangroveLike immutable mgv;

  constructor(address _mgv) {
    mgv = MangroveLike(payable(_mgv));
  }

  /*
   * Returns two uints.
   *
   * `startId` is the id of the best live offer with id equal or greater than
   * `fromId`, 0 if there is no such offer.
   *
   * `length` is 0 if `startId == 0`. Other it is the number of live offers as good or worse than the offer with
   * id `startId`.
   */
  function offerListEndPoints(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  ) public view returns (uint startId, uint length) { unchecked {
    if (fromId == 0) {
      startId = mgv.best(outbound_tkn, inbound_tkn);
    } else {
      startId = mgv.offers(outbound_tkn, inbound_tkn, fromId).gives()
      > 0
        ? fromId
        : 0;
    }

    uint currentId = startId;

    while (currentId != 0 && length < maxOffers) {
      currentId = mgv.offers(outbound_tkn, inbound_tkn, currentId).next();
      length = length + 1;
    }

    return (startId, length);
  }}

  // Returns the orderbook for the outbound_tkn/inbound_tkn pair in packed form. First number is id of next offer (0 is we're done). First array is ids, second is offers (as bytes32), third is offerDetails (as bytes32). Array will be of size `min(# of offers in out/in list, maxOffers)`.
  function packedOfferList(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  )
    public
    view
    returns (
      uint,
      uint[] memory,
      P.Offer.t[] memory,
      P.OfferDetail.t[] memory
    )
  { unchecked {
    (uint currentId, uint length) = offerListEndPoints(
      outbound_tkn,
      inbound_tkn,
      fromId,
      maxOffers
    );

    uint[] memory offerIds = new uint[](length);
    P.Offer.t[] memory offers = new P.Offer.t[](length);
    P.OfferDetail.t[] memory details = new P.OfferDetail.t[](length);

    uint i = 0;

    while (currentId != 0 && i < length) {
      offerIds[i] = currentId;
      offers[i] = mgv.offers(outbound_tkn, inbound_tkn, currentId);
      details[i] = mgv.offerDetails(outbound_tkn, inbound_tkn, currentId);
      currentId = offers[i].next();
      i = i + 1;
    }

    return (currentId, offerIds, offers, details);
  }}
  // Returns the orderbook for the outbound_tkn/inbound_tkn pair in unpacked form. First number is id of next offer (0 if we're done). First array is ids, second is offers (as structs), third is offerDetails (as structs). Array will be of size `min(# of offers in out/in list, maxOffers)`.
  function offerList(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  )
    public
    view
    returns (
      uint,
      uint[] memory,
      P.OfferStruct[] memory,
      P.OfferDetailStruct[] memory
    )
  { unchecked {
    (uint currentId, uint length) = offerListEndPoints(
      outbound_tkn,
      inbound_tkn,
      fromId,
      maxOffers
    );

    uint[] memory offerIds = new uint[](length);
    P.OfferStruct[] memory offers = new P.OfferStruct[](length);
    P.OfferDetailStruct[] memory details = new P.OfferDetailStruct[](length);

    uint i = 0;
    while (currentId != 0 && i < length) {
      offerIds[i] = currentId;
      (offers[i], details[i]) = mgv.offerInfo(
        outbound_tkn,
        inbound_tkn,
        currentId
      );
      currentId = offers[i].next;
      i = i + 1;
    }

    return (currentId, offerIds, offers, details);
  }}

  function getProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint ofr_gasreq,
    uint ofr_gasprice
  ) external view returns (uint) { unchecked {
    (P.Global.t global, P.Local.t local) = mgv.config(outbound_tkn, inbound_tkn);
    uint _gp;
    uint global_gasprice = global.gasprice();
    if (global_gasprice > ofr_gasprice) {
      _gp = global_gasprice;
    } else {
      _gp = ofr_gasprice;
    }
    return
      (ofr_gasreq + local.offer_gasbase()) *
      _gp *
      10**9;
  }}
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../MangroveOffer.sol";
import "../../../periphery/MgvReader.sol";

abstract contract MultiUser is MangroveOffer {
  mapping(address => mapping(address => mapping(uint => address)))
    internal _offerOwners; // outbound_tkn => inbound_tkn => offerId => ownerAddress

  mapping(address => uint) public mgvBalanceOf; // owner => WEI balance on mangrove
  mapping(address => mapping(address => uint)) public tokenBalanceOf; // erc20 => owner => balance on `this`

  MgvReader immutable reader;

  constructor(address _reader) {
    reader = MgvReader(_reader);
  }

  // Offer management
  event NewOffer(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint indexed offerId,
    address owner
  );

  function offerOwners(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  )
    public
    view
    returns (
      uint nextId,
      uint[] memory offerIds,
      address[] memory __offerOwners
    )
  {
    (
      nextId,
      offerIds, /*offers*/ /*offerDetails*/
      ,

    ) = reader.offerList(outbound_tkn, inbound_tkn, fromId, maxOffers);
    __offerOwners = new address[](offerIds.length);
    for (uint i = 0; i < offerIds.length; i++) {
      __offerOwners[i] = ownerOf(outbound_tkn, inbound_tkn, offerIds[i]);
    }
  }

  function creditOnMgv(address owner, uint balance) internal {
    mgvBalanceOf[owner] += balance;
  }

  function debitOnMgv(address owner, uint amount) internal {
    require(
      mgvBalanceOf[owner] >= amount,
      "MultiOwner/debitOnMgv/insufficient"
    );
    mgvBalanceOf[owner] -= amount;
  }

  function creditToken(
    address token,
    address owner,
    uint balance
  ) internal {
    tokenBalanceOf[token][owner] += balance;
  }

  function debitToken(
    address token,
    address owner,
    uint amount
  ) internal {
    require(
      tokenBalanceOf[token][owner] >= amount,
      "MultiOwner/debitToken/insufficient"
    );
    tokenBalanceOf[token][owner] -= amount;
  }

  function redeemToken(address token, uint amount)
    external
    override
    returns (bool success)
  {
    require(msg.sender != address(this), "MutliUser/noReentrancy");
    debitToken(token, msg.sender, amount);
    success = _transferToken(token, msg.sender, amount);
  }

  function transferToken(
    address token,
    address owner,
    uint amount
  ) internal returns (bool success) {
    debitToken(token, owner, amount);
    success = _transferToken(token, owner, amount);
  }

  function addOwner(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    address owner
  ) internal {
    _offerOwners[outbound_tkn][inbound_tkn][offerId] = owner;
    emit NewOffer(outbound_tkn, inbound_tkn, offerId, owner);
  }

  function ownerOf(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) public view returns (address owner) {
    owner = _offerOwners[outbound_tkn][inbound_tkn][offerId];
    require(owner != address(0), "multiUser/unkownOffer");
  }

  /// trader needs to approve Mangrove to let it perform outbound token transfer at the end of the `makerExecute` function
  /// Warning: anyone can approve here.
  function approveMangrove(address outbound_tkn, uint amount)
    external
    override
  {
    _approveMangrove(outbound_tkn, amount);
  }

  /// withdraws ETH from the bounty vault of the Mangrove.
  /// NB: `Mangrove.fund` function need not be called by `this` so is not included here.
  /// Warning: this function should not be called internally for msg.sender provision is being checked
  function withdrawFromMangrove(address receiver, uint amount)
    external
    override
    returns (bool noRevert)
  {
    require(msg.sender != address(this), "MutliUser/noReentrancy");
    debitOnMgv(msg.sender, amount);
    return _withdrawFromMangrove(receiver, amount);
  }

  function fundMangrove() external payable override {
    require(msg.sender != address(this), "MutliUser/noReentrancy");
    // increasing the provision of `this` contract
    MGV.fund{value: msg.value}();
    // increasing the virtual provision of owner
    creditOnMgv(msg.sender, msg.value);
  }

  function updateUserBalanceOnMgv(address user, uint mgvBalanceBefore)
    internal
  {
    uint mgvBalanceAfter = MGV.balanceOf(address(this));
    if (mgvBalanceAfter == mgvBalanceBefore) {
      return;
    }
    if (mgvBalanceAfter > mgvBalanceBefore) {
      creditOnMgv(user, mgvBalanceAfter - mgvBalanceBefore);
    } else {
      debitOnMgv(user, mgvBalanceBefore - mgvBalanceAfter);
    }
  }

  function newOffer(
    address outbound_tkn, // address of the ERC20 contract managing outbound tokens
    address inbound_tkn, // address of the ERC20 contract managing outbound tokens
    uint wants, // amount of `inbound_tkn` required for full delivery
    uint gives, // max amount of `outbound_tkn` promised by the offer
    uint gasreq, // max gas required by the offer when called. If maxUint256 is used here, default `OFR_GASREQ` will be considered instead
    uint gasprice, // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId // identifier of an offer in the (`outbound_tkn,inbound_tkn`) Offer List after which the new offer should be inserted (gas cost of insertion will increase if the `pivotId` is far from the actual position of the new offer)
  ) external payable override returns (uint offerId) {
    require(msg.sender != address(this), "MutliUser/noReentrancy");
    uint weiBalanceBefore = MGV.balanceOf(address(this));
    if (msg.value > 0) {
      MGV.fund{value: msg.value}();
    }
    // this call could revert if this contract does not have the provision to cover the bounty
    offerId = MGV.newOffer(
      outbound_tkn,
      inbound_tkn,
      wants,
      gives,
      gasreq,
      gasprice,
      pivotId
    );
    //setting owner of offerId
    addOwner(outbound_tkn, inbound_tkn, offerId, msg.sender);
    //updating wei balance of owner will revert if msg.sender does not have the funds
    updateUserBalanceOnMgv(msg.sender, weiBalanceBefore);
  }

  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable override {
    address owner = ownerOf(outbound_tkn, inbound_tkn, offerId);
    require(owner == msg.sender, "mgvOffer/MultiOwner/unauthorized");
    if (msg.value > 0) {
      MGV.fund{value: msg.value}();
    }
    MGV.updateOffer(
      outbound_tkn,
      inbound_tkn,
      wants,
      gives,
      gasreq,
      gasprice,
      pivotId,
      offerId
    );
    uint weiBalanceAfter = MGV.balanceOf(address(this));
    updateUserBalanceOnMgv(owner, weiBalanceAfter);
  }

  // Retracts `offerId` from the (`outbound_tkn`,`inbound_tkn`) Offer list of Mangrove. Function call will throw if `this` contract is not the owner of `offerId`.
  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external override returns (uint received) {
    require(
      _offerOwners[outbound_tkn][inbound_tkn][offerId] == msg.sender,
      "mgvOffer/MultiOwner/unauthorized"
    );
    received = MGV.retractOffer(
      outbound_tkn,
      inbound_tkn,
      offerId,
      deprovision
    );
    if (received > 0) {
      creditOnMgv(msg.sender, received);
    }
  }

  function getMissingProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) public view override returns (uint) {
    uint balance;
    address owner = ownerOf(outbound_tkn, inbound_tkn, offerId);
    if (owner == address(0)) {
      balance = 0;
    } else {
      balance = mgvBalanceOf[owner];
    }
    return
      _getMissingProvision(
        MGV,
        balance,
        outbound_tkn,
        inbound_tkn,
        gasreq,
        gasprice,
        offerId
      );
  }

  // put received inbound tokens on offer owner account
  function __put__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    creditToken(order.inbound_tkn, owner, amount);
    return 0;
  }

  // get outbound tokens from offer owner account
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    uint ownerBalance = tokenBalanceOf[order.outbound_tkn][owner];
    if (ownerBalance < amount) {
      debitToken(order.outbound_tkn, owner, ownerBalance);
      return (amount - ownerBalance);
    } else {
      debitToken(order.outbound_tkn, owner, amount);
      return 0;
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../lib/AccessControlled.sol";
import "../lib/Exponential.sol";
import "../lib/TradeHandler.sol";
import "../lib/consolerr/consolerr.sol";
import "../interfaces/IOfferLogic.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract MangroveOffer is
  AccessControlled,
  IOfferLogic,
  TradeHandler,
  Exponential
{
  Mangrove immutable MGV; // Address of the deployed Mangrove contract

  // default values
  uint public override OFR_GASREQ = 100_000;

  constructor(address payable _mgv) {
    MGV = Mangrove(_mgv);
  }

  function setGasreq(uint gasreq) public override internalOrAdmin {
    require(uint24(gasreq) == gasreq, "MangroveOffer/gasreq/overflow");
    OFR_GASREQ = gasreq;
  }

  function _transferToken(
    address token,
    address recipient,
    uint amount
  ) internal returns (bool success) {
    success = IERC20(token).transfer(recipient, amount);
  }

  // get back any ETH that might linger in the contract
  function transferETH(address recipient, uint amount)
    external
    onlyAdmin
    returns (bool success)
  {
    (success,) = recipient.call{value: amount}("");
  }

  /// trader needs to approve Mangrove to let it perform outbound token transfer at the end of the `makerExecute` function
  function _approveMangrove(address outbound_tkn, uint amount) internal {
    require(
      IERC20(outbound_tkn).approve(address(MGV), amount),
      "mgvOffer/approve/Fail"
    );
  }

  /// withdraws ETH from the bounty vault of the Mangrove.
  /// NB: `Mangrove.fund` function need not be called by `this` so is not included here.
  function _withdrawFromMangrove(address receiver, uint amount)
    internal
    returns (bool noRevert)
  {
    require(MGV.withdraw(amount));
    (noRevert, ) = receiver.call{value: amount}("");
  }

  /////// Mandatory callback functions

  // `makerExecute` is the callback function to execute all offers that were posted on Mangrove by `this` contract.
  // it may not be overriden although it can be customized using `__lastLook__`, `__put__` and `__get__` hooks.
  // NB #1: When overriding the above hooks, the Offer Maker SHOULD make sure they do not revert in order to be able to post logs in case of bad executions.
  // NB #2: if `makerExecute` does revert, the offer will be considered to be refusing the trade.
  function makerExecute(MgvLib.SingleOrder calldata order)
    external
    override
    onlyCaller(address(MGV))
    returns (bytes32 ret)
  {
    if (!__lastLook__(order)) {
      // hook to check order details and decide whether `this` contract should renege on the offer.
      emit Reneged(order.outbound_tkn, order.inbound_tkn, order.offerId);
      return RENEGED;
    }
    uint missingPut = __put__(order.gives, order); // implements what should be done with the liquidity that is flashswapped by the offer taker to `this` contract
    if (missingPut > 0) {
      emit PutFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        missingPut
      );
      return PUTFAILURE;
    }
    uint missingGet = __get__(order.wants, order); // implements how `this` contract should make the outbound tokens available
    if (missingGet > 0) {
      emit GetFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        missingGet
      );
      return OUTOFLIQUIDITY;
    }
  }

  // `makerPosthook` is the callback function that is called by Mangrove *after* the offer execution.
  // It may not be overriden although it can be customized via the post-hooks `__posthookSuccess__`, `__posthookGetFailure__`, `__posthookReneged__` and `__posthookFallback__` (see below).
  // Offer Maker SHOULD make sure the overriden posthooks do not revert in order to be able to post logs in case of bad executions.
  function makerPosthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata result
  ) external override onlyCaller(address(MGV)) {
    if (result.mgvData == "mgv/tradeSuccess") {
      // if trade was a success
      __posthookSuccess__(order);
      return;
    }
    // if trade was aborted because of a lack of liquidity
    if (result.makerData == OUTOFLIQUIDITY) {
      __posthookGetFailure__(order);
      return;
    }
    // if trade was reneged on during lastLook
    if (result.makerData == RENEGED) {
      __posthookReneged__(order);
      return;
    }
    // if trade failed unexpectedly (`makerExecute` reverted or Mangrove failed to transfer the outbound tokens to the Offer Taker)
    __posthookFallback__(order, result);
    return;
  }

  ////// Customizable hooks for Taker Order'execution

  // Override this hook to describe where the inbound token, which are flashswapped by the Offer Taker, should go during Taker Order's execution.
  // `amount` is the quantity of outbound tokens whose destination is to be resolved.
  // All tokens that are not transfered to a different contract remain listed in the balance of `this` contract
  function __put__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    returns (uint);

  // Override this hook to implement fetching `amount` of outbound tokens, possibly from another source than `this` contract during Taker Order's execution.
  // For composability, return value MUST be the remaining quantity (i.e <= `amount`) of tokens remaining to be fetched.
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    returns (uint);

  // Override this hook to implement a last look check during Taker Order's execution.
  // Return value should be `true` if Taker Order is acceptable.
  function __lastLook__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    returns (bool proceed)
  {
    order; //shh
    proceed = true;
  }

  ////// Customizable post-hooks.

  // Override this post-hook to implement what `this` contract should do when called back after a successfully executed order.
  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    virtual
  {
    order; // shh
  }

  // Override this post-hook to implement what `this` contract should do when called back after an order that failed to be executed because of a lack of liquidity (not enough outbound tokens).
  function __posthookGetFailure__(MgvLib.SingleOrder calldata order)
    internal
    virtual
  {
    order;
  }

  // Override this post-hook to implement what `this` contract should do when called back after an order that did not pass its last look (see `__lastLook__` hook).
  function __posthookReneged__(MgvLib.SingleOrder calldata order)
    internal
    virtual
  {
    order; //shh
  }

  // Override this post-hook to implement fallback behavior when Taker Order's execution failed unexpectedly. Information from Mangrove is accessible in `result.mgvData` for logging purpose.
  function __posthookFallback__(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata result
  ) internal virtual {
    order;
    result;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// AccessedControlled.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

contract AccessControlled {
  address public admin;

  constructor() {
    admin = msg.sender;
  }

  modifier onlyCaller(address caller) {
    require(
      caller == address(0) || msg.sender == caller,
      "AccessControlled/Invalid"
    );
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "AccessControlled/Invalid");
    _;
  }

  modifier internalOrAdmin() {
    require(
      msg.sender == admin || msg.sender == address(this),
      "AccessControlled/Invalid"
    );
    _;
  }

  function setAdmin(address _admin) external onlyAdmin {
    admin = _admin;
  }
}

// SPDX-License-Identifier:	BSD-3-Clause

// Copyright 2020 Compound Labs, Inc.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;

import "./CarefulMath.sol";
import "./ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
  /**
   * @dev Creates an exponential from numerator and denominator values.
   *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
   *            or if `denom` is zero.
   */
  function getExp(uint num, uint denom)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: rational}));
  }

  /**
   * @dev Adds two exponentials, returning a new exponential.
   */
  function addExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

    return (error, Exp({mantissa: result}));
  }

  /**
   * @dev Subtracts two exponentials, returning a new exponential.
   */
  function subExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

    return (error, Exp({mantissa: result}));
  }

  /**
   * @dev Multiply an Exp by a scalar, returning a new Exp.
   */
  function mulScalar(Exp memory a, uint scalar)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mulScalarTruncate(Exp memory a, uint scalar)
    internal
    pure
    returns (MathError, uint)
  {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(product));
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mulScalarTruncateAddUInt(
    Exp memory a,
    uint scalar,
    uint addend
  ) internal pure returns (MathError, uint) {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return addUInt(truncate(product), addend);
  }

  /**
   * @dev Divide an Exp by a scalar, returning a new Exp.
   */
  function divScalar(Exp memory a, uint scalar)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
  }

  /**
   * @dev Divide a scalar by an Exp, returning a new Exp.
   */
  function divScalarByExp(uint scalar, Exp memory divisor)
    internal
    pure
    returns (MathError, Exp memory)
  {
    /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
    (MathError err0, uint numerator) = mulUInt(expScale, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }
    return getExp(numerator, divisor.mantissa);
  }

  /**
   * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
   */
  function divScalarByExpTruncate(uint scalar, Exp memory divisor)
    internal
    pure
    returns (MathError, uint)
  {
    (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(fraction));
  }

  /**
   * @dev Multiplies two exponentials, returning a new exponential.
   */
  function mulExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint doubleScaledProduct) = mulUInt(
      a.mantissa,
      b.mantissa
    );
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    // We add half the scale before dividing so that we get rounding instead of truncation.
    //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
    // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
    (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(
      halfExpScale,
      doubleScaledProduct
    );
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({mantissa: 0}));
    }

    (MathError err2, uint product) = divUInt(
      doubleScaledProductWithHalfScale,
      expScale
    );
    // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
    assert(err2 == MathError.NO_ERROR);

    return (MathError.NO_ERROR, Exp({mantissa: product}));
  }

  /**
   * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
   */
  function mulExp(uint a, uint b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
  }

  /**
   * @dev Multiplies three exponentials, returning a new exponential.
   */
  function mulExp3(
    Exp memory a,
    Exp memory b,
    Exp memory c
  ) internal pure returns (MathError, Exp memory) {
    (MathError err, Exp memory ab) = mulExp(a, b);
    if (err != MathError.NO_ERROR) {
      return (err, ab);
    }
    return mulExp(ab, c);
  }

  /**
   * @dev Divides two exponentials, returning a new exponential.
   *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
   *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
   */
  function divExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    return getExp(a.mantissa, b.mantissa);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// TradeHandler.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../../Mangrove.sol";
import "../../MgvLib.sol";



//import "hardhat/console.sol";

contract TradeHandler {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  // internal bytes32 to select appropriate posthook
  bytes32 constant RENEGED = "mgvOffer/reneged";
  bytes32 constant OUTOFLIQUIDITY = "mgvOffer/outOfLiquidity";
  bytes32 constant PUTFAILURE = "mgvOffer/putFailure";

  /// @notice extracts old offer from the order that is received from the Mangrove
  function unpackOfferFromOrder(MgvLib.SingleOrder calldata order)
    internal
    pure
    returns (
      uint offer_wants,
      uint offer_gives,
      uint gasreq,
      uint gasprice
    )
  {
    gasreq = order.offerDetail.gasreq();
    gasprice = order.offerDetail.gasprice();
    offer_wants = order.offer.wants();
    offer_gives = order.offer.gives();
  }

  function _getMissingProvision(
    Mangrove mgv,
    uint balance, // offer owner balance on Mangrove
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) internal view returns (uint) {
    (P.Global.t globalData, P.Local.t localData) = mgv.config(
      outbound_tkn,
      inbound_tkn
    );
    P.OfferDetail.t offerDetailData = mgv.offerDetails(
      outbound_tkn,
      inbound_tkn,
      offerId
    );
    uint _gp;
    if (globalData.gasprice() > gasprice) {
      _gp = globalData.gasprice();
    } else {
      _gp = gasprice;
    }
    uint bounty = (gasreq + localData.offer_gasbase()) *
      _gp *
      10**9; // in WEI
    uint currentProvisionLocked = (offerDetailData.gasreq() +
      offerDetailData.offer_gasbase()) * 
      offerDetailData.gasprice() *
      10**9;
    uint currentProvision = currentProvisionLocked + balance;
    return (currentProvision >= bounty ? 0 : bounty - currentProvision);
  }

  //queries the mangrove to get current gasprice (considered to compute bounty)
  function _getCurrentGasPrice(Mangrove mgv) internal view returns (uint) {
    (P.Global.t global_pack, ) = mgv.config(address(0), address(0));
    return global_pack.gasprice();
  }

  //truncate some bytes into a byte32 word
  function truncateBytes(bytes memory data) internal pure returns (bytes32 w) {
    assembly {
      w := mload(add(data, 32))
    }
  }

  function bytesOfWord(bytes32 w) internal pure returns (bytes memory) {
    bytes memory b = new bytes(32);
    assembly {
      mstore(add(b, 32), w)
    }
    return b;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.10 <=0.8.10;

/*
 * Error logging
 * Author: Zac Williamson, AZTEC
 * Licensed under the Apache 2.0 license
 */

library consolerr {
  function errorBytes(string memory reasonString, bytes memory varA)
    internal
    pure
  {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendBytes(varA, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function error(string memory reasonString, bytes32 varA) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    append0x(errorPtr);
    appendBytes32(varA, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function error(
    string memory reasonString,
    bytes32 varA,
    bytes32 varB
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    append0x(errorPtr);
    appendBytes32(varA, errorPtr);
    appendComma(errorPtr);
    append0x(errorPtr);
    appendBytes32(varB, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function error(
    string memory reasonString,
    bytes32 varA,
    bytes32 varB,
    bytes32 varC
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    append0x(errorPtr);
    appendBytes32(varA, errorPtr);
    appendComma(errorPtr);
    append0x(errorPtr);
    appendBytes32(varB, errorPtr);
    appendComma(errorPtr);
    append0x(errorPtr);
    appendBytes32(varC, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorBytes32(string memory reasonString, bytes32 varA)
    internal
    pure
  {
    error(reasonString, varA);
  }

  function errorBytes32(
    string memory reasonString,
    bytes32 varA,
    bytes32 varB
  ) internal pure {
    error(reasonString, varA, varB);
  }

  function errorBytes32(
    string memory reasonString,
    bytes32 varA,
    bytes32 varB,
    bytes32 varC
  ) internal pure {
    error(reasonString, varA, varB, varC);
  }

  function errorAddress(string memory reasonString, address varA)
    internal
    pure
  {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendAddress(varA, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorAddress(
    string memory reasonString,
    address varA,
    address varB
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendAddress(varA, errorPtr);
    appendComma(errorPtr);
    appendAddress(varB, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorAddress(
    string memory reasonString,
    address varA,
    address varB,
    address varC
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendAddress(varA, errorPtr);
    appendComma(errorPtr);
    appendAddress(varB, errorPtr);
    appendComma(errorPtr);
    appendAddress(varC, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorUint(string memory reasonString, uint varA) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendUint(varA, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorUint(
    string memory reasonString,
    uint varA,
    uint varB
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendUint(varA, errorPtr);
    appendComma(errorPtr);
    appendUint(varB, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorUint(
    string memory reasonString,
    uint varA,
    uint varB,
    uint varC
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendUint(varA, errorPtr);
    appendComma(errorPtr);
    appendUint(varB, errorPtr);
    appendComma(errorPtr);
    appendUint(varC, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function toAscii(bytes32 input)
    internal
    pure
    returns (bytes32 hi, bytes32 lo)
  {
    assembly {
      for {
        let j := 0
      } lt(j, 32) {
        j := add(j, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        if gt(slice, 0x39) {
          slice := add(slice, 39)
        }
        lo := add(lo, shl(mul(8, j), slice))
        input := shr(4, input)
      }
      for {
        let k := 0
      } lt(k, 32) {
        k := add(k, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        if gt(slice, 0x39) {
          slice := add(slice, 39)
        }
        hi := add(hi, shl(mul(8, k), slice))
        input := shr(4, input)
      }
    }
  }

  function appendComma(bytes32 stringPtr) internal pure {
    assembly {
      let stringLen := mload(stringPtr)

      mstore(add(stringPtr, add(stringLen, 0x20)), ", ")
      mstore(stringPtr, add(stringLen, 2))
    }
  }

  function append0x(bytes32 stringPtr) internal pure {
    assembly {
      let stringLen := mload(stringPtr)
      mstore(add(stringPtr, add(stringLen, 0x20)), "0x")
      mstore(stringPtr, add(stringLen, 2))
    }
  }

  function appendString(string memory toAppend, bytes32 stringPtr)
    internal
    pure
  {
    assembly {
      let appendLen := mload(toAppend)
      let stringLen := mload(stringPtr)
      let appendPtr := add(stringPtr, add(0x20, stringLen))
      for {
        let i := 0
      } lt(i, appendLen) {
        i := add(i, 0x20)
      } {
        mstore(add(appendPtr, i), mload(add(toAppend, add(i, 0x20))))
      }

      // update string length
      mstore(stringPtr, add(stringLen, appendLen))
    }
  }

  function appendBytes(bytes memory toAppend, bytes32 stringPtr) internal pure {
    uint bytesLen;
    bytes32 inPtr;
    assembly {
      bytesLen := mload(toAppend)
      inPtr := add(toAppend, 0x20)
    }

    for (uint i = 0; i < bytesLen; i += 0x20) {
      bytes32 slice;
      assembly {
        slice := mload(inPtr)
        inPtr := add(inPtr, 0x20)
      }
      appendBytes32(slice, stringPtr);
    }

    uint offset = bytesLen % 0x20;
    if (offset > 0) {
      // update length
      assembly {
        let lengthReduction := sub(0x20, offset)
        let len := mload(stringPtr)
        mstore(stringPtr, sub(len, lengthReduction))
      }
    }
  }

  function appendBytes32(bytes32 input, bytes32 stringPtr) internal pure {
    assembly {
      let hi
      let lo
      for {
        let j := 0
      } lt(j, 32) {
        j := add(j, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        slice := add(slice, mul(39, gt(slice, 0x39)))
        lo := add(lo, shl(mul(8, j), slice))
        input := shr(4, input)
      }
      for {
        let k := 0
      } lt(k, 32) {
        k := add(k, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        if gt(slice, 0x39) {
          slice := add(slice, 39)
        }
        hi := add(hi, shl(mul(8, k), slice))
        input := shr(4, input)
      }

      let stringLen := mload(stringPtr)

      // mstore(add(stringPtr, add(stringLen, 0x20)), '0x')
      mstore(add(stringPtr, add(stringLen, 0x20)), hi)
      mstore(add(stringPtr, add(stringLen, 0x40)), lo)
      mstore(stringPtr, add(stringLen, 0x40))
    }
  }

  function appendAddress(address input, bytes32 stringPtr) internal pure {
    assembly {
      let hi
      let lo
      for {
        let j := 0
      } lt(j, 8) {
        j := add(j, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        slice := add(slice, mul(39, gt(slice, 0x39)))
        lo := add(lo, shl(mul(8, j), slice))
        input := shr(4, input)
      }

      lo := shl(192, lo)
      for {
        let k := 0
      } lt(k, 32) {
        k := add(k, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        if gt(slice, 0x39) {
          slice := add(slice, 39)
        }
        hi := add(hi, shl(mul(8, k), slice))
        input := shr(4, input)
      }

      let stringLen := mload(stringPtr)

      mstore(add(stringPtr, add(stringLen, 0x20)), "0x")
      mstore(add(stringPtr, add(stringLen, 0x22)), hi)
      mstore(add(stringPtr, add(stringLen, 0x42)), lo)
      mstore(stringPtr, add(stringLen, 42))
    }
  }

  function appendUint(uint input, bytes32 stringPtr) internal pure {
    assembly {
      // Clear out some low bytes
      let result := mload(0x40)
      if lt(result, 0x200) {
        result := 0x200
      }
      mstore(add(result, 0xa0), mload(0x40))
      mstore(add(result, 0xc0), mload(0x60))
      mstore(add(result, 0xe0), mload(0x80))
      mstore(add(result, 0x100), mload(0xa0))
      mstore(add(result, 0x120), mload(0xc0))
      mstore(add(result, 0x140), mload(0xe0))
      mstore(add(result, 0x160), mload(0x100))
      mstore(add(result, 0x180), mload(0x120))
      mstore(add(result, 0x1a0), mload(0x140))

      // Store lookup table that maps an integer from 0 to 99 into a 2-byte ASCII equivalent
      mstore(
        0x00,
        0x0000000000000000000000000000000000000000000000000000000000003030
      )
      mstore(
        0x20,
        0x3031303230333034303530363037303830393130313131323133313431353136
      )
      mstore(
        0x40,
        0x3137313831393230323132323233323432353236323732383239333033313332
      )
      mstore(
        0x60,
        0x3333333433353336333733383339343034313432343334343435343634373438
      )
      mstore(
        0x80,
        0x3439353035313532353335343535353635373538353936303631363236333634
      )
      mstore(
        0xa0,
        0x3635363636373638363937303731373237333734373537363737373837393830
      )
      mstore(
        0xc0,
        0x3831383238333834383538363837383838393930393139323933393439353936
      )
      mstore(
        0xe0,
        0x3937393839390000000000000000000000000000000000000000000000000000
      )

      // Convert integer into string slices
      function slice(v) -> y {
        y := add(
          add(
            add(
              add(
                and(mload(shl(1, mod(v, 100))), 0xffff),
                shl(16, and(mload(shl(1, mod(div(v, 100), 100))), 0xffff))
              ),
              add(
                shl(32, and(mload(shl(1, mod(div(v, 10000), 100))), 0xffff)),
                shl(48, and(mload(shl(1, mod(div(v, 1000000), 100))), 0xffff))
              )
            ),
            add(
              add(
                shl(
                  64,
                  and(mload(shl(1, mod(div(v, 100000000), 100))), 0xffff)
                ),
                shl(
                  80,
                  and(mload(shl(1, mod(div(v, 10000000000), 100))), 0xffff)
                )
              ),
              add(
                shl(
                  96,
                  and(mload(shl(1, mod(div(v, 1000000000000), 100))), 0xffff)
                ),
                shl(
                  112,
                  and(mload(shl(1, mod(div(v, 100000000000000), 100))), 0xffff)
                )
              )
            )
          ),
          add(
            add(
              add(
                shl(
                  128,
                  and(
                    mload(shl(1, mod(div(v, 10000000000000000), 100))),
                    0xffff
                  )
                ),
                shl(
                  144,
                  and(
                    mload(shl(1, mod(div(v, 1000000000000000000), 100))),
                    0xffff
                  )
                )
              ),
              add(
                shl(
                  160,
                  and(
                    mload(shl(1, mod(div(v, 100000000000000000000), 100))),
                    0xffff
                  )
                ),
                shl(
                  176,
                  and(
                    mload(shl(1, mod(div(v, 10000000000000000000000), 100))),
                    0xffff
                  )
                )
              )
            ),
            add(
              add(
                shl(
                  192,
                  and(
                    mload(shl(1, mod(div(v, 1000000000000000000000000), 100))),
                    0xffff
                  )
                ),
                shl(
                  208,
                  and(
                    mload(
                      shl(1, mod(div(v, 100000000000000000000000000), 100))
                    ),
                    0xffff
                  )
                )
              ),
              add(
                shl(
                  224,
                  and(
                    mload(
                      shl(1, mod(div(v, 10000000000000000000000000000), 100))
                    ),
                    0xffff
                  )
                ),
                shl(
                  240,
                  and(
                    mload(
                      shl(1, mod(div(v, 1000000000000000000000000000000), 100))
                    ),
                    0xffff
                  )
                )
              )
            )
          )
        )
      }

      mstore(0x100, 0x00)
      mstore(0x120, 0x00)
      mstore(0x140, slice(input))
      input := div(input, 100000000000000000000000000000000)
      if input {
        mstore(0x120, slice(input))
        input := div(input, 100000000000000000000000000000000)
        if input {
          mstore(0x100, slice(input))
        }
      }

      function getMsbBytePosition(inp) -> y {
        inp := sub(
          inp,
          0x3030303030303030303030303030303030303030303030303030303030303030
        )
        let v := and(
          add(
            inp,
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
          ),
          0x8080808080808080808080808080808080808080808080808080808080808080
        )
        v := or(v, shr(1, v))
        v := or(v, shr(2, v))
        v := or(v, shr(4, v))
        v := or(v, shr(8, v))
        v := or(v, shr(16, v))
        v := or(v, shr(32, v))
        v := or(v, shr(64, v))
        v := or(v, shr(128, v))
        y := mul(
          iszero(iszero(inp)),
          and(
            div(
              0x201f1e1d1c1b1a191817161514131211100f0e0d0c0b0a090807060504030201,
              add(shr(8, v), 1)
            ),
            0xff
          )
        )
      }

      let len := getMsbBytePosition(mload(0x140))
      if mload(0x120) {
        len := add(getMsbBytePosition(mload(0x120)), 32)
        if mload(0x100) {
          len := add(getMsbBytePosition(mload(0x100)), 64)
        }
      }

      let currentStringLength := mload(stringPtr)

      let writePtr := add(stringPtr, add(currentStringLength, 0x20))

      let offset := sub(96, len)
      // mstore(result, len)
      mstore(writePtr, mload(add(0x100, offset)))
      mstore(add(writePtr, 0x20), mload(add(0x120, offset)))
      mstore(add(writePtr, 0x40), mload(add(0x140, offset)))

      // // update length
      mstore(stringPtr, add(currentStringLength, len))

      mstore(0x40, mload(add(result, 0xa0)))
      mstore(0x60, mload(add(result, 0xc0)))
      mstore(0x80, mload(add(result, 0xe0)))
      mstore(0xa0, mload(add(result, 0x100)))
      mstore(0xc0, mload(add(result, 0x120)))
      mstore(0xe0, mload(add(result, 0x140)))
      mstore(0x100, mload(add(result, 0x160)))
      mstore(0x120, mload(add(result, 0x180)))
      mstore(0x140, mload(add(result, 0x1a0)))
    }
  }

  function initErrorPtr() internal pure returns (bytes32, bytes32) {
    bytes32 mPtr;
    bytes32 errorPtr;
    assembly {
      mPtr := mload(0x40)
      if lt(mPtr, 0x200) {
        // our uint -> base 10 ascii method requires about 0x200 bytes of mem
        mPtr := 0x200
      }
      mstore(0x40, add(mPtr, 0x1000)) // let's reserve a LOT of memory for our error string.
      mstore(
        mPtr,
        0x08c379a000000000000000000000000000000000000000000000000000000000
      )
      mstore(add(mPtr, 0x04), 0x20)
      mstore(add(mPtr, 0x24), 0)
      errorPtr := add(mPtr, 0x24)
    }

    return (mPtr, errorPtr);
  }
}

pragma solidity >=0.7.0;
pragma abicoder v2;

import "../../MgvLib.sol";

interface IOfferLogic is IMaker {
  ///////////////////
  // MangroveOffer //
  ///////////////////

  /** @notice Events */

  // Logged whenever something went wrong during `makerPosthook` execution
  event PosthookFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId,
    string message
  );

  // Logged whenever `__get__` hook failed to fetch the totality of the requested amount
  event GetFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId,
    uint missingAmount
  );

  // Logged whenever `__put__` hook failed to deposit the totality of the requested amount
  event PutFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId,
    uint missingAmount
  );

  // Logged whenever `__lastLook__` hook returned `false`
  event Reneged(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId
  );

  // Offer logic default gas required --value is used in update and new offer if maxUint is given
  function OFR_GASREQ() external returns (uint);

  // returns missing provision on Mangrove, should `offerId` be reposted using `gasreq` and `gasprice` parameters
  // if `offerId` is not in the `outbound_tkn,inbound_tkn` offer list, the totality of the necessary provision is returned
  function getMissingProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) external view returns (uint);

  // Changing OFR_GASREQ of the logic
  function setGasreq(uint gasreq) external;

  function redeemToken(address token, uint amount)
    external
    returns (bool success);

  function approveMangrove(address outbound_tkn, uint amount) external;

  function withdrawFromMangrove(address receiver, uint amount)
    external
    returns (bool noRevert);

  function fundMangrove() external payable;

  function newOffer(
    address outbound_tkn, // address of the ERC20 contract managing outbound tokens
    address inbound_tkn, // address of the ERC20 contract managing outbound tokens
    uint wants, // amount of `inbound_tkn` required for full delivery
    uint gives, // max amount of `outbound_tkn` promised by the offer
    uint gasreq, // max gas required by the offer when called. If maxUint256 is used here, default `OFR_GASREQ` will be considered instead
    uint gasprice, // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId // identifier of an offer in the (`outbound_tkn,inbound_tkn`) Offer List after which the new offer should be inserted (gas cost of insertion will increase if the `pivotId` is far from the actual position of the new offer)
  ) external payable returns (uint offerId);

  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable;

  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external returns (uint received);
}

// SPDX-License-Identifier:	BSD-3-Clause

// Copyright 2020 Compound Labs, Inc.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;

/**
 * @title Careful Math
 * @author Compound
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
  /**
   * @dev Possible error codes that we can return
   */
  enum MathError {
    NO_ERROR,
    DIVISION_BY_ZERO,
    INTEGER_OVERFLOW,
    INTEGER_UNDERFLOW
  }

  /**
   * @dev Multiplies two numbers, returns an error on overflow.
   */
  function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
    if (a == 0) {
      return (MathError.NO_ERROR, 0);
    }

    uint c = a * b;

    if (c / a != b) {
      return (MathError.INTEGER_OVERFLOW, 0);
    } else {
      return (MathError.NO_ERROR, c);
    }
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
    if (b == 0) {
      return (MathError.DIVISION_BY_ZERO, 0);
    }

    return (MathError.NO_ERROR, a / b);
  }

  /**
   * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
   */
  function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
    if (b <= a) {
      return (MathError.NO_ERROR, a - b);
    } else {
      return (MathError.INTEGER_UNDERFLOW, 0);
    }
  }

  /**
   * @dev Adds two numbers, returns an error on overflow.
   */
  function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
    uint c = a + b;

    if (c >= a) {
      return (MathError.NO_ERROR, c);
    } else {
      return (MathError.INTEGER_OVERFLOW, 0);
    }
  }

  /**
   * @dev add a and b and then subtract c
   */
  function addThenSubUInt(
    uint a,
    uint b,
    uint c
  ) internal pure returns (MathError, uint) {
    (MathError err0, uint sum) = addUInt(a, b);

    if (err0 != MathError.NO_ERROR) {
      return (err0, 0);
    }

    return subUInt(sum, c);
  }

  /**
   * @dev min and max functions
   */
  function min(uint a, uint b) internal pure returns (uint) {
    return (a < b ? a : b);
  }

  function max(uint a, uint b) internal pure returns (uint) {
    return (a > b ? a : b);
  }

  uint constant MAXUINT = type(uint).max;
  uint constant MAXUINT96 = type(uint96).max;
  uint constant MAXUINT24 = type(uint24).max;
}

// SPDX-License-Identifier:	BSD-3-Clause

// Copyright 2020 Compound Labs, Inc.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
  uint constant expScale = 1e18;
  uint constant doubleScale = 1e36;
  uint constant halfExpScale = expScale / 2;
  uint constant mantissaOne = expScale;

  struct Exp {
    uint mantissa;
  }

  struct Double {
    uint mantissa;
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint) {
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return exp.mantissa / expScale;
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mul_ScalarTruncate(Exp memory a, uint scalar)
    internal
    pure
    returns (uint)
  {
    Exp memory product = mul_(a, scalar);
    return truncate(product);
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mul_ScalarTruncateAddUInt(
    Exp memory a,
    uint scalar,
    uint addend
  ) internal pure returns (uint) {
    Exp memory product = mul_(a, scalar);
    return add_(truncate(product), addend);
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function lessThanExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa < right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function lessThanOrEqualExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa <= right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function greaterThanExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa > right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function isZeroExp(Exp memory value) internal pure returns (bool) {
    return value.mantissa == 0;
  }

  function safe224(uint n, string memory errorMessage)
    internal
    pure
    returns (uint224)
  {
    require(n < 2**224, errorMessage);
    return uint224(n);
  }

  function safe32(uint n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(uint a, uint b) internal pure returns (uint) {
    return add_(a, b, "addition overflow");
  }

  function add_(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(uint a, uint b) internal pure returns (uint) {
    return sub_(a, b, "subtraction underflow");
  }

  function sub_(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
  }

  function mul_(Exp memory a, uint b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint a, Exp memory b) internal pure returns (uint) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
  }

  function mul_(Double memory a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint a, Double memory b) internal pure returns (uint) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint a, uint b) internal pure returns (uint) {
    return mul_(a, b, "multiplication overflow");
  }

  function mul_(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint c = a * b;
    require(c / a == b, errorMessage);
    return c;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
  }

  function div_(Exp memory a, uint b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint a, Exp memory b) internal pure returns (uint) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
  }

  function div_(Double memory a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint a, Double memory b) internal pure returns (uint) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint a, uint b) internal pure returns (uint) {
    return div_(a, b, "divide by zero");
  }

  function div_(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function fraction(uint a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a, doubleScale), b)});
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Persistent.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./MultiUser.sol";

//import "hardhat/console.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract MultiUserPersistent is MultiUser {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
  {
    uint new_gives = order.offer.gives() - order.wants;
    uint new_wants = order.offer.wants() - order.gives;
    try
      MGV.updateOffer(
        order.outbound_tkn,
        order.inbound_tkn,
        new_wants,
        new_gives,
        order.offerDetail.gasreq(),
        order.offerDetail.gasprice(),
        order.offer.next(),
        order.offerId
      )
    {} catch Error(string memory message) {
      // density could be too low, or offer provision be insufficient
      emit PosthookFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        message
      );
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// AdvancedCompoundRetail.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../AaveLender.sol";
import "../Persistent.sol";

contract OfferProxy is MultiUserAaveLender, MultiUserPersistent {
  constructor(
    address _addressesProvider,
    address _MgvReader,
    address payable _MGV
  )
    AaveModule(_addressesProvider, 0)
    MultiUser(_MgvReader)
    MangroveOffer(_MGV)
  {
    setGasreq(800_000); // Offer proxy requires AAVE interactions
  }

  // overrides AaveLender.__put__ with MutliUser's one in order to put inbound token directly to user account
  function __put__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    override(MultiUser, MultiUserAaveLender)
    returns (uint missing)
  {
    // puts amount inbound_tkn in `this`
    missing = MultiUser.__put__(amount, order);
    // transfers the deposited tokens to owner
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    // NOTE this could be done off chain by the owner
    transferToken(order.inbound_tkn, owner, amount);
  }

  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    override(MultiUser, MultiUserAaveLender)
    returns (uint)
  {
    // gets tokens from AAVE's owner deposit -- will transfer aTokens from owner first
    return MultiUserAaveLender.__get__(amount, order);
  }

  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    override(MangroveOffer, MultiUserPersistent)
  {
    MultiUserPersistent.__posthookSuccess__(order);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AaveLender.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;
import "./MultiUser.sol";
import "../AaveModule.sol";

abstract contract MultiUserAaveLender is MultiUser, AaveModule {
  /**************************************************************************/
  ///@notice Required functions to let `this` contract interact with Aave
  /**************************************************************************/

  ///@notice approval of ctoken contract by the underlying is necessary for minting and repaying borrow
  ///@notice user must use this function to do so.
  function approveLender(address token, uint amount) external onlyAdmin {
    _approveLender(token, amount);
  }

  // function mint(
  //   uint amount,
  //   address asset,
  //   address onBehalf
  // ) external onlyAdmin {
  //   _mint(amount, asset, onBehalf);
  // }

  // tokens are fetched on Aave (on behalf of offer owner)
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    (
      uint redeemable, /*maxBorrowAfterRedeem*/

    ) = maxGettableUnderlying(order.outbound_tkn, false, owner);
    if (amount > redeemable) {
      return amount; // give up if amount is not redeemable (anti flashloan manipulation of AAVE)
    }
    // need to retreive overlyings from msg.sender (we suppose `this` is approved for that)
    IERC20 aToken = overlying(IERC20(order.outbound_tkn));
    try aToken.transferFrom(owner, address(this), amount) returns (
      bool 
    ) {
      if (aaveRedeem(amount, address(this), order) == 0) {
        // amount was transfered to `owner`
        return 0;
      }
      emit ErrorOnRedeem(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        amount,
        "lender/multi/redeemFailed"
      );
    } catch {
      emit ErrorOnRedeem(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        amount,
        "lender/multi/transferFromFail"
      );
    }
    return amount; // nothing was fetched
  }

  // received inbound token are put on Aave on behalf of offer owner
  function __put__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    //optim
    if (amount == 0) {
      return 0;
    }
    address owner = ownerOf(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId
    );
    // minted Atokens are sent to owner
    return aaveMint(amount, owner, order);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AaveLender.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;
import "../interfaces/Aave/ILendingPool.sol";
import "../interfaces/Aave/ILendingPoolAddressesProvider.sol";
import "../interfaces/Aave/IPriceOracleGetter.sol";
import "../lib/Exponential.sol";
import "../../IERC20.sol";
import "../../MgvLib.sol";

//import "hardhat/console.sol";

contract AaveModule is Exponential {
  event ErrorOnRedeem(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint indexed offerId,
    uint amount,
    string errorCode
  );
  event ErrorOnMint(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint indexed offerId,
    uint amount,
    string errorCode
  );

  // address of the lendingPool
  ILendingPool public immutable lendingPool;
  IPriceOracleGetter public immutable priceOracle;
  uint16 referralCode;

  constructor(address _addressesProvider, uint _referralCode) {
    require(
      uint16(_referralCode) == _referralCode,
      "Referral code should be uint16"
    );
    referralCode = uint16(referralCode); // for aave reference, put 0 for tests
    address _lendingPool = ILendingPoolAddressesProvider(_addressesProvider)
      .getLendingPool();
    address _priceOracle = ILendingPoolAddressesProvider(_addressesProvider)
      .getPriceOracle();
    require(_lendingPool != address(0), "Invalid lendingPool address");
    require(_priceOracle != address(0), "Invalid priceOracle address");
    lendingPool = ILendingPool(_lendingPool);
    priceOracle = IPriceOracleGetter(_priceOracle);
  }

  /**************************************************************************/
  ///@notice Required functions to let `this` contract interact with Aave
  /**************************************************************************/

  ///@notice approval of ctoken contract by the underlying is necessary for minting and repaying borrow
  ///@notice user must use this function to do so.
  function _approveLender(address token, uint amount) internal {
    IERC20(token).approve(address(lendingPool), amount);
  }

  ///@notice exits markets
  function _exitMarket(IERC20 underlying) internal {
    lendingPool.setUserUseReserveAsCollateral(address(underlying), false);
  }

  function _enterMarkets(IERC20[] calldata underlyings) internal {
    for (uint i = 0; i < underlyings.length; i++) {
      lendingPool.setUserUseReserveAsCollateral(address(underlyings[i]), true);
    }
  }

  function overlying(IERC20 asset) public view returns (IERC20 aToken) {
    aToken = IERC20(lendingPool.getReserveData(address(asset)).aTokenAddress);
  }

  // structs to avoir stack too deep in maxGettableUnderlying
  struct Underlying {
    uint ltv;
    uint liquidationThreshold;
    uint decimals;
    uint price;
  }

  struct Account {
    uint collateral;
    uint debt;
    uint borrowPower;
    uint redeemPower;
    uint ltv;
    uint liquidationThreshold;
    uint health;
    uint balanceOfUnderlying;
  }

  /// @notice Computes maximal maximal redeem capacity (R) and max borrow capacity (B|R) after R has been redeemed
  /// returns (R, B|R)

  function maxGettableUnderlying(
    address asset,
    bool tryBorrow,
    address onBehalf
  ) public view returns (uint, uint) {
    Underlying memory underlying; // asset parameters
    Account memory account; // accound parameters
    (
      account.collateral,
      account.debt,
      account.borrowPower, // avgLtv * sumCollateralEth - sumDebtEth
      account.liquidationThreshold,
      account.ltv,
      account.health // avgLiquidityThreshold * sumCollateralEth / sumDebtEth  -- should be less than 10**18
    ) = lendingPool.getUserAccountData(onBehalf);
    DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(
      asset
    );
    (
      underlying.ltv, // collateral factor for lending
      underlying.liquidationThreshold, // collateral factor for borrowing
      ,
      /*liquidationBonus*/
      underlying.decimals,
      /*reserveFactor*/

    ) = DataTypes.getParams(reserveData.configuration);
    account.balanceOfUnderlying = IERC20(reserveData.aTokenAddress).balanceOf(
      onBehalf
    );

    underlying.price = priceOracle.getAssetPrice(asset); // divided by 10**underlying.decimals

    // account.redeemPower = account.liquidationThreshold * account.collateral - account.debt
    account.redeemPower = sub_(
      div_(mul_(account.liquidationThreshold, account.collateral), 10**4),
      account.debt
    );
    // max redeem capacity = account.redeemPower/ underlying.liquidationThreshold * underlying.price
    // unless account doesn't have enough collateral in asset token (hence the min())

    uint maxRedeemableUnderlying = div_( // in 10**underlying.decimals
      account.redeemPower * 10**(underlying.decimals) * 10**4,
      mul_(underlying.liquidationThreshold, underlying.price)
    );

    maxRedeemableUnderlying = min(
      maxRedeemableUnderlying,
      account.balanceOfUnderlying
    );

    if (!tryBorrow) {
      //gas saver
      return (maxRedeemableUnderlying, 0);
    }
    // computing max borrow capacity on the premisses that maxRedeemableUnderlying has been redeemed.
    // max borrow capacity = (account.borrowPower - (ltv*redeemed)) / underlying.ltv * underlying.price

    uint borrowPowerImpactOfRedeemInUnderlying = div_(
      mul_(maxRedeemableUnderlying, underlying.ltv),
      10**4
    );
    uint borrowPowerInUnderlying = div_(
      mul_(account.borrowPower, 10**underlying.decimals),
      underlying.price
    );

    if (borrowPowerImpactOfRedeemInUnderlying > borrowPowerInUnderlying) {
      // no more borrowPower left after max redeem operation
      return (maxRedeemableUnderlying, 0);
    }

    uint maxBorrowAfterRedeemInUnderlying = sub_( // max borrow power in underlying after max redeem has been withdrawn
      borrowPowerInUnderlying,
      borrowPowerImpactOfRedeemInUnderlying
    );
    return (maxRedeemableUnderlying, maxBorrowAfterRedeemInUnderlying);
  }

  function aaveRedeem(
    uint amountToRedeem,
    address onBehalf,
    MgvLib.SingleOrder calldata order
  ) internal returns (uint) {
    try
      lendingPool.withdraw(order.outbound_tkn, amountToRedeem, onBehalf)
    returns (uint withdrawn) {
      //aave redeem was a success
      if (amountToRedeem == withdrawn) {
        return 0;
      } else {
        return (amountToRedeem - withdrawn);
      }
    } catch Error(string memory message) {
      emit ErrorOnRedeem(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        amountToRedeem,
        message
      );
      return amountToRedeem;
    }
  }

  function _mint(
    uint amount,
    address token,
    address onBehalf
  ) internal {
    lendingPool.deposit(token, amount, onBehalf, referralCode);
  }

  // adapted from https://medium.com/compound-finance/supplying-assets-to-the-compound-protocol-ec2cf5df5aa#afff
  // utility to supply erc20 to compound
  // NB `ctoken` contract MUST be approved to perform `transferFrom token` by `this` contract.
  /// @notice user need to approve ctoken in order to mint
  function aaveMint(
    uint amount,
    address onBehalf,
    MgvLib.SingleOrder calldata order
  ) internal returns (uint) {
    // contract must haveallowance()to spend funds on behalf ofmsg.sender for at-leastamount for the asset being deposited. This can be done via the standard ERC20 approve() method.
    try lendingPool.deposit(order.inbound_tkn, amount, onBehalf, referralCode) {
      return 0;
    } catch Error(string memory message) {
      emit ErrorOnMint(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        amount,
        message
      );
    } catch {
      emit ErrorOnMint(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        amount,
        "unexpected"
      );
    }
    return amount;
  }
}

// SPDX-License-Identifier: agpl-3.0
// Copyright (C) 2020 Aave

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.en.html)
pragma solidity >=0.6.12;
pragma abicoder v2;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from './DataTypes.sol';

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
// Copyright (C) 2020 Aave

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.en.html)
pragma solidity >=0.6.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
// Copyright (C) 2020 Aave

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.en.html)
pragma solidity >=0.6.12;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/

interface IPriceOracleGetter {
  /**
   * @dev returns the asset price in ETH
   * @param asset the address of the asset
   * @return the ETH price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
// Copyright (C) 2020 Aave

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.en.html)
//for more details
pragma solidity >=0.6.12;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint data;
  }

  struct UserConfigurationMap {
    uint data;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint constant IS_FROZEN_START_BIT_POSITION = 57;
  uint constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint constant RESERVE_FACTOR_START_BIT_POSITION = 64;

  function getParams(ReserveConfigurationMap memory configMap)
    internal
    pure
    returns (
      uint,
      uint,
      uint,
      uint,
      uint
    )
  {
    uint dataLocal = configMap.data;
    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >>
        LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >>
        LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }

  function isUsingAsCollateral(
    DataTypes.UserConfigurationMap memory configMap,
    uint reserveIndex
  ) internal pure returns (bool) {
    require(reserveIndex < 128, "Invalid index");
    return (configMap.data >> (reserveIndex * 2 + 1)) & 1 != 0;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AaveLender.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;
import "./SingleUser.sol";
import "../AaveModule.sol";

abstract contract AaveLender is SingleUser, AaveModule {
  /**************************************************************************/
  ///@notice Required functions to let `this` contract interact with Aave
  /**************************************************************************/

  ///@notice approval of ctoken contract by the underlying is necessary for minting and repaying borrow
  ///@notice user must use this function to do so.
  function approveLender(address token, uint amount) external onlyAdmin {
    _approveLender(token, amount);
  }

  ///@notice exits markets
  function exitMarket(IERC20 underlying) external onlyAdmin {
    _exitMarket(underlying);
  }

  function enterMarkets(IERC20[] calldata underlyings) external onlyAdmin {
    _enterMarkets(underlyings);
  }

  function mint(
    uint amount,
    address token,
    address onBehalf
  ) external onlyAdmin {
    _mint(amount, token, onBehalf);
  }

  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    (
      uint redeemable, /*maxBorrowAfterRedeem*/

    ) = maxGettableUnderlying(order.outbound_tkn, false, address(this));
    if (amount > redeemable) {
      return amount; // give up if amount is not redeemable (anti flashloan manipulation of AAVE)
    }

    if (aaveRedeem(amount, address(this), order) == 0) {
      // amount was transfered to `this`
      return 0;
    }
    return amount;
  }

  function __put__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    //optim
    if (amount == 0) {
      return 0;
    }
    return aaveMint(amount, address(this), order);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../MangroveOffer.sol";

//import "hardhat/console.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract SingleUser is MangroveOffer {
  receive() external payable {}

  /// transfers token stored in `this` contract to some recipient address
  function redeemToken(address token, uint amount)
    external
    override
    onlyAdmin
    returns (bool success)
  {
    success = _transferToken(token, msg.sender, amount);
  }

  /// trader needs to approve Mangrove to let it perform outbound token transfer at the end of the `makerExecute` function
  function approveMangrove(address outbound_tkn, uint amount)
    external
    override
    onlyAdmin
  {
    _approveMangrove(outbound_tkn, amount);
  }

  function fundMangrove() external payable override {
    MGV.fund{value: msg.value}();
  }

  /// withdraws ETH from the bounty vault of the Mangrove.
  function withdrawFromMangrove(address receiver, uint amount)
    external
    override
    onlyAdmin
    returns (bool)
  {
    return _withdrawFromMangrove(receiver, amount);
  }

  // Posting a new offer on the (`outbound_tkn,inbound_tkn`) Offer List of Mangrove.
  // NB #1: Offer maker MUST:
  // * Approve Mangrove for at least `gives` amount of `outbound_tkn`.
  // * Make sure that offer maker has enough WEI provision on Mangrove to cover for the new offer bounty
  // * Make sure that `gasreq` and `gives` yield a sufficient offer density
  // NB #2: This function may revert when the above points are not met, it is thus made external only so that it can be encapsulated when called during `makerExecute`.
  function newOffer(
    address outbound_tkn, // address of the ERC20 contract managing outbound tokens
    address inbound_tkn, // address of the ERC20 contract managing outbound tokens
    uint wants, // amount of `inbound_tkn` required for full delivery
    uint gives, // max amount of `outbound_tkn` promised by the offer
    uint gasreq, // max gas required by the offer when called. If maxUint256 is used here, default `OFR_GASREQ` will be considered instead
    uint gasprice, // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId // identifier of an offer in the (`outbound_tkn,inbound_tkn`) Offer List after which the new offer should be inserted (gas cost of insertion will increase if the `pivotId` is far from the actual position of the new offer)
  ) external payable override onlyAdmin returns (uint offerId) {
    if (msg.value > 0) {
      MGV.fund{value: msg.value}();
    }
    if (gasreq == type(uint).max) {
      gasreq = OFR_GASREQ;
    }
    return
      MGV.newOffer(
        outbound_tkn,
        inbound_tkn,
        wants,
        gives,
        gasreq,
        gasprice,
        pivotId
      );
  }

  //  Updates an existing `offerId` on the Mangrove. `updateOffer` rely on the same offer requirements as `newOffer` and may throw if they are not met.
  //  Additionally `updateOffer` will thow if `this` contract is not the owner of `offerId`.
  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable override onlyAdmin {
    if (msg.value > 0) {
      MGV.fund{value: msg.value}();
    }
    if (gasreq == type(uint).max) {
      gasreq = OFR_GASREQ;
    }
    MGV.updateOffer(
      outbound_tkn,
      inbound_tkn,
      wants,
      gives,
      gasreq,
      gasprice,
      pivotId,
      offerId
    );
  }

  // Retracts `offerId` from the (`outbound_tkn`,`inbound_tkn`) Offer list of Mangrove. Function call will throw if `this` contract is not the owner of `offerId`.
  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external override onlyAdmin returns (uint) {
    return (MGV.retractOffer(outbound_tkn, inbound_tkn, offerId, deprovision));
  }

  function getMissingProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) public view override returns (uint) {
    return
      _getMissingProvision(
        MGV,
        MGV.balanceOf(address(this)),
        outbound_tkn,
        inbound_tkn,
        gasreq,
        gasprice,
        offerId
      );
  }

  function __put__(uint /*amount*/, MgvLib.SingleOrder calldata)
    internal
    virtual
    override
    returns (uint)
  {
    return 0;
  }

  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    uint balance = IERC20(order.outbound_tkn).balanceOf(address(this));
    if (balance >= amount) {
      return 0;
    } else {
      return (amount - balance);
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// PriceFed.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../../Defensive.sol";
import "../../AaveLender.sol";

contract PriceFed is Defensive, AaveLender {
  constructor(
    address _oracle,
    address _addressesProvider,
    address payable _MGV
  ) Defensive(_oracle) AaveModule(_addressesProvider, 0) MangroveOffer(_MGV) {
    setGasreq(800_000);
  }

  event Slippage(uint indexed offerId, uint old_wants, uint new_wants);

  // reposts only if offer was reneged due to a price slippage
  function __posthookReneged__(MgvLib.SingleOrder calldata order)
    internal
    override
  {
    (uint old_wants, uint old_gives, , ) = unpackOfferFromOrder(order);
    uint price_quote = oracle.getPrice(order.inbound_tkn);
    uint price_base = oracle.getPrice(order.outbound_tkn);

    uint new_offer_wants = div_(mul_(old_gives, price_base), price_quote);
    emit Slippage(order.offerId, old_wants, new_offer_wants);
    // since offer is persistent it will auto refill if contract does not have enough provision on the Mangrove
    try
      MGV.updateOffer(
        order.outbound_tkn,
        order.inbound_tkn,
        new_offer_wants,
        old_gives,
        OFR_GASREQ,
        0,
        0,
        order.offerId
      )
    {} catch Error(string memory message) {
      emit PosthookFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        message
      );
    }
  }

  // Closing diamond inheritance for solidity compiler
  // get/put and lender strat's functions
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    override(SingleUser, AaveLender)
    returns (uint)
  {
    return AaveLender.__get__(amount, order);
  }

  function __put__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    override(SingleUser, AaveLender)
    returns (uint)
  {
    return AaveLender.__put__(amount, order);
  }

  // lastlook is defensive strat's function
  function __lastLook__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    override(MangroveOffer, Defensive)
    returns (bool)
  {
    return Defensive.__lastLook__(order);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Defensive.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./SingleUser.sol";
import "../../interfaces/IOracle.sol";

// import "hardhat/console.sol";

abstract contract Defensive is SingleUser {
  uint16 slippage_num;
  uint16 constant slippage_den = 10**4;
  IOracle public oracle;

  // emitted when no price data is available for given token
  event MissingPrice(address token);

  constructor(address _oracle) {
    require(!(_oracle == address(0)), "Invalid oracle address");
    oracle = IOracle(_oracle);
  }

  function setSlippage(uint _slippage) external onlyAdmin {
    require(uint16(_slippage) == _slippage, "Slippage overflow");
    require(uint16(_slippage) <= slippage_den, "Slippage should be <= 1");
    slippage_num = uint16(_slippage);
  }

  function __lastLook__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool)
  {
    uint offer_gives_REF = mul_(
      order.wants,
      oracle.getPrice(order.outbound_tkn) // returns price in oracle base units (i.e ETH or USD)
    );
    uint offer_wants_REF = mul_(
      order.gives,
      oracle.getPrice(order.inbound_tkn) // returns price is oracle base units (i.e ETH or USD)
    );
    // abort trade if price data is not available
    if (offer_gives_REF == 0) {
      emit MissingPrice(order.outbound_tkn);
      return false;
    }
    if (offer_wants_REF == 0) {
      emit MissingPrice(order.inbound_tkn);
      return false;
    }
    // if offer_gives_REF * (1-slippage) > offer_wants_REF one is getting arb'ed
    // i.e slippage_den * OGR - slippage_num * OGR > OWR * slippage_den
    return (sub_(
      mul_(offer_gives_REF, slippage_den),
      mul_(offer_gives_REF, slippage_num)
    ) <= mul_(offer_wants_REF, slippage_den));
  }
}

// SPDX-License-Identifier: Unlicense

// IOracle.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>
pragma solidity ^0.8.10;
pragma abicoder v2;

interface IOracle {
  function decimals() external view returns (uint8);

  function getPrice(address token) external view returns (uint96);

  function setPrice(address token, uint price) external;
}

// SPDX-License-Identifier:	BSD-2-Clause

// SimpleOrale.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../interfaces/IOracle.sol";
import "./AccessControlled.sol";
import {IERC20} from "../../MgvLib.sol";

contract SimpleOracle is IOracle, AccessControlled {
  address reader; // if unset, anyone can read price
  IERC20 public immutable base_token;
  mapping(address => uint96) internal priceData;

  constructor(address _base) {
    try IERC20(_base).decimals() returns (uint8 d) {
      require(d != 0, "Invalid decimals number for Oracle base");
      base_token = IERC20(_base);
    } catch {
      revert("Invalid Oracle base address");
    }
  }

  function decimals() external view override returns (uint8) {
    return base_token.decimals();
  }

  function setReader(address _reader) external onlyAdmin {
    reader = _reader;
  }

  function setPrice(address token, uint price) external override onlyAdmin {
    require(uint96(price) == price, "price overflow");
    priceData[token] = uint96(price);
  }

  function getPrice(address token)
    external
    view
    override
    onlyCaller(reader)
    returns (uint96 price)
  {
    price = priceData[token];
    require(price != 0, "missing price data");
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Basic.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../SingleUser.sol";

//import "hardhat/console.sol";

/* Simply inherits SingleUser and is deployable. No internal logic. */
contract SimpleMaker is SingleUser {
  constructor(address payable _MGV) MangroveOffer(_MGV) {}
}

// SPDX-License-Identifier:	BSD-2-Clause

// Persistent.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./SingleUser.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract Persistent is SingleUser {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
  {
    uint new_gives = order.offer.gives() - order.wants;
    uint new_wants = order.offer.wants() - order.gives;
    try
      MGV.updateOffer(
        order.outbound_tkn,
        order.inbound_tkn,
        new_wants,
        new_gives,
        order.offerDetail.gasreq(),
        order.offerDetail.gasprice(),
        order.offer.next(),
        order.offerId
      )
    {} catch Error(string memory message) {
      emit PosthookFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        message
      );
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Basic.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../Persistent.sol";

contract Reposting is Persistent {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  constructor(address payable _MGV) MangroveOffer(_MGV) {}

  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    override
  {
    uint wants = order.offer.wants();// amount with token1.decimals() decimals
    uint gives = order.offer.gives();// amount with token1.decimals() decimals
    uint gasreq = order.offerDetail.gasreq();
    uint gasprice = order.offerDetail.gasprice();

    try
      MGV.updateOffer({
        outbound_tkn: order.outbound_tkn,
        inbound_tkn: order.inbound_tkn,
        wants: wants,
        gives: gives,
        gasreq: gasreq,
        gasprice: gasprice,
        pivotId: 0,
        offerId: order.offerId
      })
    {} catch Error(string memory error_msg) {
      emit PosthookFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        error_msg
      );
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Basic.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../Persistent.sol";

//import "hardhat/console.sol";

contract Basic is Persistent {
  constructor(address payable _MGV) MangroveOffer(_MGV) {}
}

// SPDX-License-Identifier:	BSD-2-Clause

// CompoundLender.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../CompoundModule.sol";
import "./SingleUser.sol";

abstract contract CompoundLender is SingleUser, CompoundModule {
  function approveLender(IcERC20 ctoken, uint amount) external onlyAdmin {
    require(_approveLender(ctoken, amount), "Lender/ApproveFail");
  }

  function enterMarkets(address[] calldata ctokens) external onlyAdmin {
    _enterMarkets(ctokens);
  }

  function exitMarket(IcERC20 ctoken) external onlyAdmin {
    _exitMarket(ctoken);
  }

  function claimComp() external onlyAdmin {
    _claimComp();
  }

  function mint(
    uint amount,
    IcERC20 ctoken,
    address
  ) external onlyAdmin {
    uint errCode = _mint(amount, ctoken);
    if (errCode != 0) {
      consolerr.errorUint("Lender/mintFailed: ", errCode);
    }
  }

  function __get__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    if (!isPooled(IERC20(order.outbound_tkn))) {
      // if flag says not to fetch liquidity on compound
      return amount;
    }
    // if outbound_tkn == weth, overlying will return cEth
    IcERC20 outbound_cTkn = overlyings[IERC20(order.outbound_tkn)]; // this is 0x0 if outbound_tkn is not compound sourced.
    if (address(outbound_cTkn) == address(0)) {
      return amount;
    }
    (uint redeemable, ) = maxGettableUnderlying(
      address(outbound_cTkn),
      address(this)
    );
    if (redeemable < amount) {
      return amount; //give up if __get__ cannot withdraw enough
    }
    // else try redeem on compound
    if (compoundRedeem(amount, order) == 0) {
      // redeemAmount was transfered to `this`
      return 0;
    }
    return amount;
  }

  function __put__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    //optim
    if (!isPooled(IERC20(order.inbound_tkn))) {
      return amount;
    }
    return compoundMint(amount, order);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// CompoundModule.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../interfaces/compound/ICompound.sol";
import "../lib/Exponential.sol";
import {MgvLib as ML} from "../../MgvLib.sol";

//import "hardhat/console.sol";

contract CompoundModule is Exponential {
  event ErrorOnRedeem(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint indexed offerId,
    uint amount,
    uint errorCode
  );
  event ErrorOnMint(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint indexed offerId,
    uint amount,
    uint errorCode
  );

  event ComptrollerError(address comp, uint errorCode);

  // mapping : ERC20 -> cERC20
  mapping(IERC20 => IcERC20) overlyings;

  // address of the comptroller
  IComptroller public immutable comptroller;

  // address of the price oracle used by the comptroller
  ICompoundPriceOracle public immutable oracle;

  IERC20 immutable weth;

  constructor(address _unitroller, address wethAddress) {
    comptroller = IComptroller(_unitroller); // unitroller is a proxy for comptroller calls
    require(_unitroller != address(0), "Invalid comptroller address");
    ICompoundPriceOracle _oracle = IComptroller(_unitroller).oracle(); // pricefeed used by the comptroller
    require(address(_oracle) != address(0), "Failed to get price oracle");
    oracle = _oracle;
    weth = IERC20(wethAddress);
  }

  function isCeth(IcERC20 ctoken) internal view returns (bool) {
    return (keccak256(abi.encodePacked(ctoken.symbol())) ==
      keccak256(abi.encodePacked("cETH")));
  }

  //dealing with cEth special case
  function underlying(IcERC20 ctoken) internal view returns (IERC20) {
    require(ctoken.isCToken(), "Invalid ctoken address");
    if (isCeth(ctoken)) {
      // cETH has no underlying() function...
      return weth;
    } else {
      return IERC20(ctoken.underlying());
    }
  }

  function _approveLender(IcERC20 ctoken, uint amount) internal returns (bool) {
    IERC20 token = underlying(ctoken);
    return token.approve(address(ctoken), amount);
  }

  function _enterMarkets(address[] calldata ctokens) internal {
    uint[] memory results = comptroller.enterMarkets(ctokens);
    for (uint i = 0; i < ctokens.length; i++) {
      require(results[i] == 0, "Failed to enter market");
      IERC20 token = underlying(IcERC20(ctokens[i]));
      // adding ctoken.underlying --> ctoken mapping
      overlyings[token] = IcERC20(ctokens[i]);
    }
  }

  function _exitMarket(IcERC20 ctoken) internal {
    require(
      comptroller.exitMarket(address(ctoken)) == 0,
      "failed to exit marker"
    );
  }

  function _claimComp() internal {
    comptroller.claimComp(address(this));
  }

  function isPooled(IERC20 token) public view returns (bool) {
    IcERC20 ctoken = overlyings[token];
    return comptroller.checkMembership(address(this), ctoken);
  }

  /// @notice struct to circumvent stack too deep error in `maxGettableUnderlying` function
  struct Heap {
    uint ctokenBalance;
    uint cDecimals;
    uint decimals;
    uint exchangeRateMantissa;
    uint liquidity;
    uint collateralFactorMantissa;
    uint maxRedeemable;
    uint balanceOfUnderlying;
    uint priceMantissa;
    uint underlyingLiquidity;
    MathError mErr;
    uint errCode;
  }

  function heapError(Heap memory heap) private pure returns (bool) {
    return (heap.errCode != 0 || heap.mErr != MathError.NO_ERROR);
  }

  /// @notice Computes maximal maximal redeem capacity (R) and max borrow capacity (B|R) after R has been redeemed
  /// returns (R, B|R)
  function maxGettableUnderlying(address _ctoken, address account)
    public
    view
    returns (uint, uint)
  {
    IcERC20 ctoken = IcERC20(_ctoken);
    Heap memory heap;
    // NB balance below is underestimated unless accrue interest was triggered earlier in the transaction
    (heap.errCode, heap.ctokenBalance, , heap.exchangeRateMantissa) = ctoken
      .getAccountSnapshot(address(this)); // underapprox
    heap.priceMantissa = oracle.getUnderlyingPrice(ctoken); //18 decimals

    // balanceOfUnderlying(A) : cA.balance * exchange_rate(cA,A)

    (heap.mErr, heap.balanceOfUnderlying) = mulScalarTruncate(
      Exp({mantissa: heap.exchangeRateMantissa}),
      heap.ctokenBalance // ctokens have 8 decimals precision
    );

    if (heapError(heap)) {
      return (0, 0);
    }

    // max amount of outbound_Tkn token than can be borrowed
    (
      heap.errCode,
      heap.liquidity, // is USD:18 decimals
      /*shortFall*/

    ) = comptroller.getAccountLiquidity(account); // underapprox

    // to get liquidity expressed in outbound_Tkn token instead of USD
    (heap.mErr, heap.underlyingLiquidity) = divScalarByExpTruncate(
      heap.liquidity,
      Exp({mantissa: heap.priceMantissa})
    );
    if (heapError(heap)) {
      return (0, 0);
    }
    (, heap.collateralFactorMantissa, ) = comptroller.markets(address(ctoken));

    // if collateral factor is 0 then any token can be redeemed from the pool w/o impacting borrow power
    // also true if market is not entered
    if (
      heap.collateralFactorMantissa == 0 ||
      !comptroller.checkMembership(account, ctoken)
    ) {
      return (heap.balanceOfUnderlying, heap.underlyingLiquidity);
    }

    // maxRedeem:[underlying] = liquidity:[USD / 18 decimals ] / (price(outbound_tkn):[USD.underlying^-1 / 18 decimals] * collateralFactor(outbound_tkn): [0-1] 18 decimals)
    (heap.mErr, heap.maxRedeemable) = divScalarByExpTruncate(
      heap.liquidity,
      mul_(
        Exp({mantissa: heap.collateralFactorMantissa}),
        Exp({mantissa: heap.priceMantissa})
      )
    );
    if (heapError(heap)) {
      return (0, 0);
    }
    heap.maxRedeemable = min(heap.maxRedeemable, heap.balanceOfUnderlying);
    // B|R = B - R*CF
    return (
      heap.maxRedeemable,
      sub_(
        heap.underlyingLiquidity, //borrow power
        mul_ScalarTruncate(
          Exp({mantissa: heap.collateralFactorMantissa}),
          heap.maxRedeemable
        )
      )
    );
  }

  function compoundRedeem(uint amountToRedeem, ML.SingleOrder calldata order)
    internal
    returns (uint)
  {
    IcERC20 outbound_cTkn = overlyings[IERC20(order.outbound_tkn)]; // this is 0x0 if outbound_tkn is not compound sourced.
    if (address(outbound_cTkn) == address(0)) {
      return amountToRedeem;
    }
    uint errorCode = outbound_cTkn.redeemUnderlying(amountToRedeem); // accrues interests
    if (errorCode == 0) {
      //compound redeem was a success
      // if ETH was redeemed, one needs to convert them into wETH
      if (isCeth(outbound_cTkn)) {
        weth.deposit{value: amountToRedeem}();
      }
      return 0;
    } else {
      //compound redeem failed
      emit ErrorOnRedeem(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        amountToRedeem,
        errorCode
      );
      return amountToRedeem;
    }
  }

  function _mint(uint amount, IcERC20 ctoken) internal returns (uint errCode) {
    if (isCeth(ctoken)) {
      // turning `amount` of wETH into ETH
      try weth.withdraw(amount) {
        // minting amount of ETH into cETH
        ctoken.mint{value: amount}();
      } catch {
        if (amount == weth.balanceOf(address(this))) {}
        require(false);
      }
    } else {
      // Approve transfer on the ERC20 contract (not needed if cERC20 is already approved for `this`)
      // IERC20(ctoken.underlying()).approve(ctoken, amount);
      errCode = ctoken.mint(amount); // accrues interest
    }
  }

  // adapted from https://medium.com/compound-finance/supplying-assets-to-the-compound-protocol-ec2cf5df5aa#afff
  // utility to supply erc20 to compound
  function compoundMint(uint amount, ML.SingleOrder calldata order)
    internal
    returns (uint missing)
  {
    IcERC20 ctoken = overlyings[IERC20(order.inbound_tkn)];
    uint errCode = _mint(amount, ctoken);
    // Mint ctokens
    if (errCode != 0) {
      emit ErrorOnMint(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        amount,
        errCode
      );
      missing = amount;
    }
  }
}

// SPDX-License-Identifier: Unlicense

// ICompound.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

pragma solidity ^0.8.10;
pragma abicoder v2;

import "../../../IERC20.sol";

interface ICompoundPriceOracle {
  function getUnderlyingPrice(IcERC20 cToken) external view returns (uint);
}

interface IComptroller {
  // adding usefull public getters
  function oracle() external returns (ICompoundPriceOracle priceFeed);

  function markets(address cToken)
    external
    view
    returns (
      bool isListed,
      uint collateralFactorMantissa,
      bool isComped
    );

  /*** Assets You Are In ***/

  function enterMarkets(address[] calldata cTokens)
    external
    returns (uint[] memory);

  function exitMarket(address cToken) external returns (uint);

  function getAccountLiquidity(address user)
    external
    view
    returns (
      uint errorCode,
      uint liquidity,
      uint shortfall
    );

  function claimComp(address holder) external;

  function checkMembership(address account, IcERC20 cToken)
    external
    view
    returns (bool);
}

interface IcERC20 is IERC20 {
  // from https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
  function redeem(uint redeemTokens) external returns (uint);

  function borrow(uint borrowAmount) external returns (uint);

  // for non cETH only
  function repayBorrow(uint repayAmount) external returns (uint);

  // for cETH only
  function repayBorrow() external payable;

  // for non cETH only
  function repayBorrowBehalf(address borrower, uint repayAmount)
    external
    returns (uint);

  // for cETH only
  function repayBorrowBehalf(address borrower) external payable;

  function balanceOfUnderlying(address owner) external returns (uint);

  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint,
      uint,
      uint,
      uint
    );

  function borrowRatePerBlock() external view returns (uint);

  function supplyRatePerBlock() external view returns (uint);

  function totalBorrowsCurrent() external returns (uint);

  function borrowBalanceCurrent(address account) external returns (uint);

  function borrowBalanceStored(address account) external view returns (uint);

  function exchangeRateCurrent() external returns (uint);

  function exchangeRateStored() external view returns (uint);

  function getCash() external view returns (uint);

  function accrueInterest() external returns (uint);

  function seize(
    address liquidator,
    address borrower,
    uint seizeTokens
  ) external returns (uint);

  function redeemUnderlying(uint redeemAmount) external returns (uint);

  function mint(uint mintAmount) external returns (uint);

  // only in cETH
  function mint() external payable;

  // non cETH only
  function underlying() external view returns (address); // access to public variable containing the address of the underlying ERC20

  function isCToken() external view returns (bool); // public constant froim CTokenInterfaces.sol
}

// SPDX-License-Identifier:	BSD-2-Clause

// SimpleCompoundRetail.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../../CompoundLender.sol";

//import "hardhat/console.sol";

contract SimpleCompoundRetail is CompoundLender {
  constructor(
    address _unitroller,
    address payable _MGV,
    address wethAddress
  ) CompoundModule(_unitroller, wethAddress) MangroveOffer(_MGV) {
    setGasreq(1_000_000);
  }

  // Tries to take base directly from `this` balance. Fetches the remainder on Compound.
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    uint missing = SingleUser.__get__(amount, order);
    if (missing > 0) {
      return super.__get__(missing, order);
    }
    return 0;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// CompoundTrader.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./CompoundLender.sol";

abstract contract CompoundTrader is CompoundLender {
  event ErrorOnBorrow(address cToken, uint amount, uint errorCode);
  event ErrorOnRepay(address cToken, uint amount, uint errorCode);

  function __get__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    if (!isPooled(IERC20(order.outbound_tkn))) {
      return amount;
    }
    IcERC20 outbound_cTkn = overlyings[IERC20(order.outbound_tkn)]; // this is 0x0 if outbound_tkn is not compound sourced for borrow.

    if (address(outbound_cTkn) == address(0)) {
      return amount;
    }

    // 1. Computing total borrow and redeem capacities of underlying asset
    (uint redeemable, uint liquidity_after_redeem) = maxGettableUnderlying(
      address(outbound_cTkn),
      address(this)
    );

    // give up if amount is not gettable
    if (add_(redeemable, liquidity_after_redeem) < amount) {
      return amount;
    }

    // 2. trying to redeem liquidity from Compound
    uint toRedeem = min(redeemable, amount);

    uint notRedeemed = compoundRedeem(toRedeem, order);
    if (notRedeemed > 0 && toRedeem > 0) {
      // => notRedeemed == toRedeem
      // this should not happen unless compound is out of cash, thus no need to try to borrow
      // log already emitted by `compoundRedeem`
      return amount;
    }
    amount = sub_(amount, toRedeem);
    uint toBorrow = min(liquidity_after_redeem, amount);
    if (toBorrow == 0) {
      return amount;
    }
    // 3. trying to borrow missing liquidity
    uint errorCode = outbound_cTkn.borrow(toBorrow);
    if (errorCode != 0) {
      emit ErrorOnBorrow(address(outbound_cTkn), toBorrow, errorCode);
      return amount; // unable to borrow requested amount
    }
    // if ETH were borrowed, one needs to turn them into wETH
    if (isCeth(outbound_cTkn)) {
      weth.deposit{value: toBorrow}();
    }
    return sub_(amount, toBorrow);
  }

  /// @notice contract need to have approved `inbound_tkn` overlying in order to repay borrow
  function __put__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    //optim
    if (!isPooled(IERC20(order.inbound_tkn))) {
      return amount;
    }
    // NB: overlyings[wETH] = cETH
    IcERC20 inbound_cTkn = overlyings[IERC20(order.inbound_tkn)];
    if (address(inbound_cTkn) == address(0)) {
      return amount;
    }
    // trying to repay debt if user is in borrow position for inbound_tkn token
    uint toRepay = min(
      inbound_cTkn.borrowBalanceCurrent(address(this)),
      amount
    ); //accrues interests

    uint errCode;
    if (isCeth(inbound_cTkn)) {
      // turning WETHs to ETHs
      weth.withdraw(toRepay);
      // OK since repayBorrow throws if failing in the case of Eth
      inbound_cTkn.repayBorrow{value: toRepay}();
    } else {
      errCode = inbound_cTkn.repayBorrow(toRepay);
    }
    uint toMint;
    if (errCode != 0) {
      emit ErrorOnRepay(address(inbound_cTkn), toRepay, errCode);
      toMint = amount;
    } else {
      toMint = amount - toRepay;
    }
    return compoundMint(toMint, order);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// SwingingMarketMaker.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../../CompoundTrader.sol";

contract SwingingMarketMaker is CompoundTrader {
  using P.Offer for P.Offer.t;
  event MissingPriceConverter(address token0, address token1);
  event NotEnoughProvision(uint amount);

  // price[B][A] : price of A in B = p(B|A) = volume of B obtained/volume of A given
  mapping(address => mapping(address => uint)) private price; // price[tk0][tk1] is in tk0 precision
  mapping(address => mapping(address => uint)) private offers;

  constructor(
    address _unitroller,
    address payable _MGV,
    address wethAddress
  ) CompoundModule(_unitroller, wethAddress) MangroveOffer(_MGV) {
    setGasreq(1_000_000);
  }

  // sets P(tk0|tk1)
  // one wants P(tk0|tk1).P(tk1|tk0) >= 1
  function setPrice(
    address tk0,
    address tk1,
    uint p
  ) external onlyAdmin {
    price[tk0][tk1] = p; // has tk0.decimals() decimals
  }

  function startStrat(
    address tk0,
    address tk1,
    uint gives // amount of tk0 (with tk0.decimals() decimals)
  ) external payable onlyAdmin {
    MGV.fund{value: msg.value}();
    require(repostOffer(tk0, tk1, gives), "Could not start strategy");
    IERC20(tk0).approve(address(MGV), type(uint).max); // approving MGV for tk0 transfer
    IERC20(tk1).approve(address(MGV), type(uint).max); // approving MGV for tk1 transfer
  }

  // at this stage contract has `received` amount in token0
  function repostOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint gives // in outbound_tkn
  ) internal returns (bool) {
    // computing how much inbound_tkn one should ask for `gives` amount of outbound tokens
    // NB p_10 has inbound_tkn.decimals() number of decimals
    uint p_10 = price[inbound_tkn][outbound_tkn];
    if (p_10 == 0) {
      // ! p_10 has the decimals of inbound_tkn
      emit MissingPriceConverter(inbound_tkn, outbound_tkn);
      return false;
    }
    uint wants = div_(
      mul_(p_10, gives), // p(base|quote).(gives:quote) : base
      10**(IERC20(outbound_tkn).decimals())
    ); // in base units
    uint offerId = offers[outbound_tkn][inbound_tkn];
    if (offerId == 0) {
      try
        MGV.newOffer(outbound_tkn, inbound_tkn, wants, gives, OFR_GASREQ, 0, 0)
      returns (uint id) {
        if (id > 0) {
          offers[outbound_tkn][inbound_tkn] = id;
          return true;
        } else {
          return false;
        }
      } catch {
        return false;
      }
    } else {
      try
        MGV.updateOffer(
          outbound_tkn,
          inbound_tkn,
          wants,
          gives,
          // offerId is already on the book so a good pivot
          OFR_GASREQ, // default value
          0, // default value
          offerId,
          offerId
        )
      {
        return true;
      } catch Error(string memory message) {
        emit PosthookFail(outbound_tkn, inbound_tkn, offerId, message);
        return false;
      }
    }
  }

  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    override
  {
    address token0 = order.outbound_tkn;
    address token1 = order.inbound_tkn;
    uint offer_received = order.offer.wants(); // amount with token1.decimals() decimals
    repostOffer({
      outbound_tkn: token1,
      inbound_tkn: token0,
      gives: offer_received
    });
  }

  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    // checks whether `this` contract has enough `base` token
    uint missingGet = SingleUser.__get__(amount, order);
    // if not tries to fetch missing liquidity on compound using `CompoundTrader`'s strat
    return super.__get__(missingGet, order);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// AdvancedCompoundRetail.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../../CompoundTrader.sol";

contract AdvancedCompoundRetail is CompoundTrader {
  constructor(
    address _unitroller,
    address payable _MGV,
    address wethAddress
  ) CompoundModule(_unitroller, wethAddress) MangroveOffer(_MGV) {
    setGasreq(1_000_000);
  }

  // Tries to take base directly from `this` balance. Fetches the remainder on Compound.
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    uint missing = SingleUser.__get__(amount, order);
    if (missing > 0) {
      return super.__get__(missing, order);
    }
    return 0;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// AdvancedCompoundRetail.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../../AaveLender.sol";

contract SimpleAaveRetail is AaveLender {
  constructor(address _addressesProvider, address payable _MGV)
    AaveModule(_addressesProvider, 0)
    MangroveOffer(_MGV)
  {
    setGasreq(1_000_000);
  }

  // Tries to take base directly from `this` balance. Fetches the remainder on Aave.
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    uint missing = SingleUser.__get__(amount, order);
    if (missing > 0) {
      return super.__get__(missing, order);
    }
    return 0;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// AaveTrader.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;
import "./AaveLender.sol";

abstract contract AaveTrader is AaveLender {
  uint public immutable interestRateMode;

  constructor(uint _interestRateMode) {
    interestRateMode = _interestRateMode;
  }

  event ErrorOnBorrow(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint indexed offerId,
    uint amount,
    string errorCode
  );
  event ErrorOnRepay(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint indexed offerId,
    uint amount,
    string errorCode
  );

  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    // 1. Computing total borrow and redeem capacities of underlying asset
    (uint redeemable, uint liquidity_after_redeem) = maxGettableUnderlying(
      order.outbound_tkn,
      true,
      address(this)
    );

    if (add_(redeemable, liquidity_after_redeem) < amount) {
      return amount; // give up early if not possible to fetch amount of underlying
    }
    // 2. trying to redeem liquidity from Compound
    uint toRedeem = min(redeemable, amount);

    uint notRedeemed = aaveRedeem(toRedeem, address(this), order);
    if (notRedeemed > 0 && toRedeem > 0) {
      // => notRedeemed == toRedeem
      // this should not happen unless compound is out of cash, thus no need to try to borrow
      // log already emitted by `compoundRedeem`
      return amount;
    }
    amount = sub_(amount, toRedeem);
    uint toBorrow = min(liquidity_after_redeem, amount);
    if (toBorrow == 0) {
      return amount;
    }
    // 3. trying to borrow missing liquidity
    try
      lendingPool.borrow(
        order.outbound_tkn,
        toBorrow,
        interestRateMode,
        referralCode,
        address(this)
      )
    {
      return sub_(amount, toBorrow);
    } catch Error(string memory message) {
      emit ErrorOnBorrow(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        toBorrow,
        message
      );
      return amount;
    }
  }

  function __put__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    //optim
    if (amount == 0) {
      return 0;
    }
    // trying to repay debt if user is in borrow position for inbound_tkn token
    DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(
      order.inbound_tkn
    );

    uint debtOfUnderlying;
    if (interestRateMode == 1) {
      debtOfUnderlying = IERC20(reserveData.stableDebtTokenAddress).balanceOf(
        address(this)
      );
    } else {
      debtOfUnderlying = IERC20(reserveData.variableDebtTokenAddress).balanceOf(
          address(this)
        );
    }

    uint toRepay = min(debtOfUnderlying, amount);

    uint toMint;
    try
      lendingPool.repay(
        order.inbound_tkn,
        toRepay,
        interestRateMode,
        address(this)
      )
    {
      toMint = sub_(amount, toRepay);
    } catch Error(string memory message) {
      emit ErrorOnRepay(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        toRepay,
        message
      );
      toMint = amount;
    }
    return aaveMint(toMint, address(this), order);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// AdvancedAaveRetail.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../../AaveTrader.sol";

contract AdvancedAaveRetail is AaveTrader(2) {
  constructor(address addressesProvider, address payable _MGV)
    AaveModule(addressesProvider, 0)
    MangroveOffer(_MGV)
  {
    setGasreq(1_000_000);
  }

  // Tries to take base directly from `this` balance. Fetches the remainder on Aave.
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    uint missing = SingleUser.__get__(amount, order);
    if (missing > 0) {
      return super.__get__(missing, order);
    }
    return 0;
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "../periphery/MgvCleaner.sol";

import "../MgvLib.sol";
import "hardhat/console.sol";
import "@giry/hardhat-test-solidity/test.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";
// import "./Agents/TestMoriartyMaker.sol";
import "./Agents/TestTaker.sol";

// In these tests, the testing contract is the market maker.
contract MgvCleaner_Test is HasMgvEvents {
  receive() external payable {}

  AbstractMangrove mgv;
  TestTaker tkr;
  TestMaker mkr;
  address outbound;
  address inbound;
  MgvCleaner cleaner;

  function a_beforeAll() public {
    TestToken Outbound = TokenSetup.setup("A", "$A");
    TestToken Inbound = TokenSetup.setup("B", "$B");
    outbound = address(Outbound);
    inbound = address(Inbound);
    mgv = MgvSetup.setup(Outbound, Inbound);
    mkr = MakerSetup.setup(mgv, outbound, inbound);
    cleaner = new MgvCleaner(address(mgv));

    payable(mkr).transfer(10 ether);

    mkr.provisionMgv(5 ether);

    Inbound.mint(address(this), 2 ether);
    Outbound.mint(address(mkr), 1 ether);

    Outbound.approve(address(mgv), 1 ether);
    Inbound.approve(address(mgv), 1 ether);
    mkr.approveMgv(Outbound, 1 ether);

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "MgvCleaner_Test");
    Display.register(outbound, "$A");
    Display.register(inbound, "$B");
    Display.register(address(mgv), "mgv");
    Display.register(address(mkr), "maker[$A,$B]");
    Display.register(address(cleaner), "cleaner");
  }

  /* # Test Config */

  function single_failing_offer_test() public {
    mgv.approve(outbound, inbound, address(cleaner), type(uint).max);

    mkr.shouldFail(true);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50_000, 0);

    uint oldBal = address(this).balance;

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, type(uint).max];
    cleaner.collect(outbound, inbound, targets, true);

    uint newBal = address(this).balance;

    TestEvents.more(newBal, oldBal, "balance should have increased");
  }

  function mult_failing_offer_test() public {
    mgv.approve(outbound, inbound, address(cleaner), type(uint).max);

    mkr.shouldFail(true);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50_000, 0);
    uint ofr2 = mkr.newOffer(1 ether, 1 ether, 50_000, 0);

    uint oldBal = address(this).balance;

    uint[4][] memory targets = new uint[4][](2);
    targets[0] = [ofr, 1 ether, 1 ether, type(uint).max];
    targets[1] = [ofr2, 1 ether, 1 ether, type(uint).max];
    cleaner.collect(outbound, inbound, targets, true);

    uint newBal = address(this).balance;

    TestEvents.more(newBal, oldBal, "balance should have increased");
  }

  function no_fail_no_cleaning_test() public {
    mgv.approve(outbound, inbound, address(cleaner), type(uint).max);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50_000, 0);

    uint oldBal = address(this).balance;

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, type(uint).max];
    try cleaner.collect(outbound, inbound, targets, true) {
      TestEvents.fail("collect should fail since offer succeeded");
    } catch Error(string memory reason) {
      TestEvents.eq(
        "mgvCleaner/anOfferDidNotFail",
        reason,
        "fail should be due to offer execution succeeding"
      );
    }

    uint newBal = address(this).balance;

    TestEvents.eq(newBal, oldBal, "balance should be the same");
  }

  // For now there is no need to approve
  // function no_approve_no_cleaning_test() public {
  //   uint ofr = mkr.newOffer(1 ether, 1 ether, 50_000,0);

  //   uint[4][] memory targets = new uint[4][](1);
  //   targets[0] = [ofr, 1 ether, 1 ether, type(uint).max];

  //   try cleaner.collect(outbound, inbound,targets,true) {
  //     TestEvents.fail("collect should fail since cleaner was not approved");
  //   } catch Error(string memory reason) {
  //     TestEvents.eq("mgv/lowAllowance",reason,"Fail should be due to no allowance");
  //   }
  // }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvCleaner.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, P} from "../MgvLib.sol";

interface MangroveLike {
  function snipesFor(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint successes,
      uint takerGot,
      uint takerGave,
      uint bounty
    );

  function offerInfo(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) external view returns (P.OfferStruct memory, P.OfferStruct memory);
}

/* The purpose of the Cleaner contract is to execute failing offers and collect
 * their associated bounty. It takes an array of offers with same definition as
 * `Mangrove.snipes` and expects them all to fail or not execute. */

/* How to use:
   1) Ensure *your* address approved Mangrove for the token you will provide to the offer (`inbound_tkn`).
   2) Run `collect` on the offers that you detected were failing.

   You can adjust takerWants/takerGives and gasreq as needed.

   Note: in the current version you do not need to set MgvCleaner's allowance in Mangrove.
   TODO: add `collectWith` with an additional `taker` argument.
*/
contract MgvCleaner {
  MangroveLike immutable MGV;

  constructor(address _MGV) {
    MGV = MangroveLike(_MGV);
  }

  receive() external payable {}

  /* Returns the entire balance, not just the bounty collected */
  function collect(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants
  ) external returns (uint bal) { unchecked {
    (uint successes, , , ) = MGV.snipesFor(
      outbound_tkn,
      inbound_tkn,
      targets,
      fillWants,
      msg.sender
    );
    require(successes == 0, "mgvCleaner/anOfferDidNotFail");
    bal = address(this).balance;
    bool noRevert;
    (noRevert, ) = msg.sender.call{value: bal}("");
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "../AbstractMangrove.sol";
import "../MgvLib.sol";
import "hardhat/console.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";
import "./Agents/TestMoriartyMaker.sol";
import "./Agents/MakerDeployer.sol";
import "./Agents/TestTaker.sol";

contract MakerOperations_Test is IMaker, HasMgvEvents {
  using P.Global for P.Global.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Offer for P.Offer.t;
  using P.Local for P.Local.t;
  AbstractMangrove mgv;
  TestMaker mkr;
  TestMaker mkr2;
  TestTaker tkr;
  TestToken base;
  TestToken quote;
  address _base;
  address _quote;

  receive() external payable {}

  function a_beforeAll() public {
    base = TokenSetup.setup("A", "$A");
    _base = address(base);
    quote = TokenSetup.setup("B", "$B");
    _quote = address(quote);

    mgv = MgvSetup.setup(base, quote);
    mkr = MakerSetup.setup(mgv, _base, _quote);
    mkr2 = MakerSetup.setup(mgv, _base, _quote);
    tkr = TakerSetup.setup(mgv, _base, _quote);

    payable(mkr).transfer(10 ether);
    mkr.approveMgv(base, 10 ether);
    payable(mkr2).transfer(10 ether);
    mkr2.approveMgv(base, 10 ether);

    payable(tkr).transfer(10 ether);

    quote.mint(address(tkr), 1 ether);
    tkr.approveMgv(quote, 1 ether);

    base.approve(address(mgv), 10 ether);

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "MakerOperations_Test");
    Display.register(_base, "$A");
    Display.register(_quote, "$B");
    Display.register(address(mgv), "mgv");
    Display.register(address(mkr), "maker");
    Display.register(address(mkr2), "maker2");
    Display.register(address(tkr), "taker");
  }

  function provision_adds_freeWei_and_ethers_test() public {
    uint mgv_bal = address(mgv).balance;
    uint amt1 = 235;
    uint amt2 = 1.3 ether;

    mkr.provisionMgv(amt1);

    TestEvents.eq(mkr.freeWei(), amt1, "incorrect mkr freeWei amount (1)");
    TestEvents.eq(
      address(mgv).balance,
      mgv_bal + amt1,
      "incorrect mgv ETH balance (1)"
    );

    mkr.provisionMgv(amt2);

    TestEvents.eq(
      mkr.freeWei(),
      amt1 + amt2,
      "incorrect mkr freeWei amount (2)"
    );
    TestEvents.eq(
      address(mgv).balance,
      mgv_bal + amt1 + amt2,
      "incorrect mgv ETH balance (2)"
    );
  }

  // since we check calldata, execute must be internal
  function makerExecute(ML.SingleOrder calldata order)
    external
    override
    returns (bytes32 ret)
  {
    ret; // silence unused function parameter warning
    uint num_args = 9;
    uint selector_bytes = 4;
    uint length = selector_bytes + num_args * 32;
    TestEvents.eq(
      msg.data.length,
      length,
      "calldata length in execute is incorrect"
    );

    TestEvents.eq(order.outbound_tkn, _base, "wrong base");
    TestEvents.eq(order.inbound_tkn, _quote, "wrong quote");
    TestEvents.eq(order.wants, 0.05 ether, "wrong takerWants");
    TestEvents.eq(order.gives, 0.05 ether, "wrong takerGives");
    TestEvents.eq(
      order.offerDetail.gasreq(),
      200_000,
      "wrong gasreq"
    );
    TestEvents.eq(order.offerId, 1, "wrong offerId");
    TestEvents.eq(
      order.offer.wants(),
      0.05 ether,
      "wrong offerWants"
    );
    TestEvents.eq(
      order.offer.gives(),
      0.05 ether,
      "wrong offerGives"
    );
    // test flashloan
    TestEvents.eq(
      quote.balanceOf(address(this)),
      0.05 ether,
      "wrong quote balance"
    );
    return "";
  }

  function makerPosthook(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) external override {}

  function calldata_and_balance_in_makerExecute_are_correct_test() public {
    bool funded;
    (funded, ) = address(mgv).call{value: 1 ether}("");
    base.mint(address(this), 1 ether);
    uint ofr = mgv.newOffer(
      _base,
      _quote,
      0.05 ether,
      0.05 ether,
      200_000,
      0,
      0
    );
    require(tkr.take(ofr, 0.05 ether), "take must work or test is void");
  }

  function withdraw_removes_freeWei_and_ethers_test() public {
    uint mgv_bal = address(mgv).balance;
    uint amt1 = 0.86 ether;
    uint amt2 = 0.12 ether;

    mkr.provisionMgv(amt1);
    bool success = mkr.withdrawMgv(amt2);
    TestEvents.check(success, "mkr was not able to withdraw from mgv");
    TestEvents.eq(mkr.freeWei(), amt1 - amt2, "incorrect mkr freeWei amount");
    TestEvents.eq(
      address(mgv).balance,
      mgv_bal + amt1 - amt2,
      "incorrect mgv ETH balance"
    );
  }

  function withdraw_too_much_fails_test() public {
    uint amt1 = 6.003 ether;
    mkr.provisionMgv(amt1);
    try mkr.withdrawMgv(amt1 + 1) {
      TestEvents.fail("mkr cannot withdraw more than it has");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/insufficientProvision", "wrong revert reason");
    }
  }

  function newOffer_without_freeWei_fails_test() public {
    try mkr.newOffer(1 ether, 1 ether, 0, 0) {
      TestEvents.fail("mkr cannot create offer without provision");
    } catch Error(string memory r) {
      TestEvents.eq(
        r,
        "mgv/insufficientProvision",
        "new offer failed for wrong reason"
      );
    }
  }

  function posthook_fail_message_test() public {
    mkr.provisionMgv(1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50000, 0);

    mkr.setShouldFailHook(true);
    tkr.take(ofr, 0.1 ether); // fails but we don't care

    TestEvents.expectFrom(address(mgv));
    emit PosthookFail(_base, _quote, ofr);
  }

  function badReturn_fails_test() public {
    mkr.provisionMgv(1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50000, 0);

    mkr.shouldAbort(true);
    bool success = tkr.take(ofr, 0.1 ether);
    TestEvents.check(!success, "take should fail");
    mkr.expect("abort");
  }

  function delete_restores_balance_test() public {
    mkr.provisionMgv(1 ether);
    uint bal = mkr.freeWei(); // should be 1 ether
    uint offerId = mkr.newOffer(1 ether, 1 ether, 2300, 0);
    uint bal_ = mkr.freeWei(); // 1 ether minus provision
    uint collected = mkr.retractOfferWithDeprovision(offerId); // provision
    TestEvents.eq(
      bal - bal_,
      collected,
      "retract does not return a correct amount"
    );
    TestEvents.eq(mkr.freeWei(), bal, "delete has not restored balance");
  }

  function delete_offer_log_test() public {
    mkr.provisionMgv(1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 2300, 0);
    mkr.retractOfferWithDeprovision(ofr);
    TestEvents.expectFrom(address(mgv));
    emit OfferRetract(_base, _quote, ofr);
  }

  function retract_retracted_does_not_drain_test() public {
    mkr.provisionMgv(1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 10_000, 0);

    mkr.retractOffer(ofr);

    uint bal1 = mgv.balanceOf(address(mkr));
    uint collected = mkr.retractOfferWithDeprovision(ofr);
    TestEvents.check(collected > 0, "deprovision should give credit");
    uint bal2 = mgv.balanceOf(address(mkr));
    TestEvents.less(bal1, bal2, "Balance should have increased");

    uint collected2 = mkr.retractOfferWithDeprovision(ofr);
    TestEvents.check(
      collected2 == 0,
      "second deprovision should not give credit"
    );
    uint bal3 = mgv.balanceOf(address(mkr));
    TestEvents.eq(bal3, bal2, "Balance should not have increased");
  }

  function retract_taken_does_not_drain_test() public {
    mkr.provisionMgv(1 ether);
    base.mint(address(mkr), 1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);

    bool success = tkr.take(ofr, 0.1 ether);
    TestEvents.eq(success, true, "Snipe should succeed");

    uint bal1 = mgv.balanceOf(address(mkr));
    mkr.retractOfferWithDeprovision(ofr);
    uint bal2 = mgv.balanceOf(address(mkr));
    TestEvents.less(bal1, bal2, "Balance should have increased");

    uint collected = mkr.retractOfferWithDeprovision(ofr);
    TestEvents.check(
      collected == 0,
      "second deprovision should not give credit"
    );
    uint bal3 = mgv.balanceOf(address(mkr));
    TestEvents.eq(bal3, bal2, "Balance should not have increased");
  }

  function retract_offer_log_test() public {
    mkr.provisionMgv(1 ether);
    uint ofr = mkr.newOffer(0.9 ether, 1 ether, 2300, 100);
    mkr.retractOffer(ofr);
    TestEvents.expectFrom(address(mgv));
    emit OfferRetract(_base, _quote, ofr);
  }

  function retract_offer_maintains_balance_test() public {
    mkr.provisionMgv(1 ether);
    uint bal = mkr.freeWei();
    uint prov = TestUtils.getProvision(mgv, _base, _quote, 2300);
    mkr.retractOffer(mkr.newOffer(1 ether, 1 ether, 2300, 0));
    TestEvents.eq(mkr.freeWei(), bal - prov, "unexpected maker balance");
  }

  function retract_middle_offer_leaves_a_valid_book_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(0.9 ether, 1 ether, 2300, 100);
    uint ofr = mkr.newOffer({
      wants: 1 ether,
      gives: 1 ether,
      gasreq: 2300,
      gasprice: 100,
      pivotId: 0
    });
    uint ofr1 = mkr.newOffer(1.1 ether, 1 ether, 2300, 100);

    mkr.retractOffer(ofr);
    TestEvents.check(
      !mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Offer was not removed from OB"
    );
    (P.OfferStruct memory offer, P.OfferDetailStruct memory offerDetail) = mgv.offerInfo(
      _base,
      _quote,
      ofr
    );
    TestEvents.eq(offer.prev, ofr0, "Invalid prev");
    TestEvents.eq(offer.next, ofr1, "Invalid next");
    TestEvents.eq(offer.gives, 0, "offer gives was not set to 0");
    TestEvents.eq(offerDetail.gasprice, 100, "offer gasprice is incorrect");

    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, offer.prev)),
      "Invalid OB"
    );
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, offer.next)),
      "Invalid OB"
    );
    (P.OfferStruct memory offer0, ) = mgv.offerInfo(_base, _quote, offer.prev);
    (P.OfferStruct memory offer1, ) = mgv.offerInfo(_base, _quote, offer.next);
    TestEvents.eq(offer1.prev, ofr0, "Invalid snitching for ofr1");
    TestEvents.eq(offer0.next, ofr1, "Invalid snitching for ofr0");
  }

  function retract_best_offer_leaves_a_valid_book_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr = mkr.newOffer({
      wants: 1 ether,
      gives: 1 ether,
      gasreq: 2300,
      gasprice: 100,
      pivotId: 0
    });
    uint ofr1 = mkr.newOffer(1.1 ether, 1 ether, 2300, 100);
    mkr.retractOffer(ofr);
    TestEvents.check(
      !mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Offer was not removed from OB"
    );
    (P.OfferStruct memory offer, P.OfferDetailStruct memory offerDetail) = mgv.offerInfo(
      _base,
      _quote,
      ofr
    );
    TestEvents.eq(offer.prev, 0, "Invalid prev");
    TestEvents.eq(offer.next, ofr1, "Invalid next");
    TestEvents.eq(offer.gives, 0, "offer gives was not set to 0");
    TestEvents.eq(offerDetail.gasprice, 100, "offer gasprice is incorrect");

    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, offer.next)),
      "Invalid OB"
    );
    (P.OfferStruct memory offer1, ) = mgv.offerInfo(_base, _quote, offer.next);
    TestEvents.eq(offer1.prev, 0, "Invalid snitching for ofr1");
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(
      cfg.best(),
      ofr1,
      "Invalid best after retract"
    );
  }

  function retract_worst_offer_leaves_a_valid_book_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr = mkr.newOffer({
      wants: 1 ether,
      gives: 1 ether,
      gasreq: 2300,
      gasprice: 100,
      pivotId: 0
    });
    uint ofr0 = mkr.newOffer(0.9 ether, 1 ether, 2300, 100);
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Offer was not removed from OB"
    );
    mkr.retractOffer(ofr);
    (P.OfferStruct memory offer, P.OfferDetailStruct memory offerDetail) = mgv.offerInfo(
      _base,
      _quote,
      ofr
    );
    TestEvents.eq(offer.prev, ofr0, "Invalid prev");
    TestEvents.eq(offer.next, 0, "Invalid next");
    TestEvents.eq(offer.gives, 0, "offer gives was not set to 0");
    TestEvents.eq(offerDetail.gasprice, 100, "offer gasprice is incorrect");

    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, offer.prev)),
      "Invalid OB"
    );
    (P.OfferStruct memory offer0, ) = mgv.offerInfo(_base, _quote, offer.prev);
    TestEvents.eq(offer0.next, 0, "Invalid snitching for ofr0");
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(
      cfg.best(),
      ofr0,
      "Invalid best after retract"
    );
  }

  function delete_wrong_offer_fails_test() public {
    mkr.provisionMgv(1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 2300, 0);
    try mkr2.retractOfferWithDeprovision(ofr) {
      TestEvents.fail("mkr2 should not be able to delete mkr's offer");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/retractOffer/unauthorized", "wrong revert reason");
    }
  }

  function retract_wrong_offer_fails_test() public {
    mkr.provisionMgv(1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 2300, 0);
    try mkr2.retractOffer(ofr) {
      TestEvents.fail("mkr2 should not be able to retract mkr's offer");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/retractOffer/unauthorized", "wrong revert reason");
    }
  }

  function gasreq_max_with_newOffer_ok_test() public {
    mkr.provisionMgv(1 ether);
    uint gasmax = 750000;
    mgv.setGasmax(gasmax);
    mkr.newOffer(1 ether, 1 ether, gasmax, 0);
  }

  function gasreq_too_high_fails_newOffer_test() public {
    uint gasmax = 12;
    mgv.setGasmax(gasmax);
    try mkr.newOffer(1 ether, 1 ether, gasmax + 1, 0) {
      TestEvents.fail("gasreq above gasmax, newOffer should fail");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/writeOffer/gasreq/tooHigh", "wrong revert reason");
    }
  }

  function min_density_with_newOffer_ok_test() public {
    mkr.provisionMgv(1 ether);
    uint density = 10**7;
    mgv.setGasbase(_base, _quote, 1);
    mgv.setDensity(_base, _quote, density);
    mkr.newOffer(1 ether, density, 0, 0);
  }

  function low_density_fails_newOffer_test() public {
    uint density = 10**7;
    mgv.setGasbase(_base, _quote, 1);
    mgv.setDensity(_base, _quote, density);
    try mkr.newOffer(1 ether, density - 1, 0, 0) {
      TestEvents.fail("density too low, newOffer should fail");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/writeOffer/density/tooLow", "wrong revert reason");
    }
  }

  function maker_gets_no_freeWei_on_partial_fill_test() public {
    mkr.provisionMgv(1 ether);
    base.mint(address(mkr), 1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    uint oldBalance = mgv.balanceOf(address(mkr));
    bool success = tkr.take(ofr, 0.1 ether);
    TestEvents.check(success, "take must succeed");
    TestEvents.eq(
      mgv.balanceOf(address(mkr)),
      oldBalance,
      "mkr balance must not change"
    );
  }

  function maker_gets_no_freeWei_on_full_fill_test() public {
    mkr.provisionMgv(1 ether);
    base.mint(address(mkr), 1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    uint oldBalance = mgv.balanceOf(address(mkr));
    bool success = tkr.take(ofr, 1 ether);
    TestEvents.check(success, "take must succeed");
    TestEvents.eq(
      mgv.balanceOf(address(mkr)),
      oldBalance,
      "mkr balance must not change"
    );
  }

  function insertions_are_correctly_ordered_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr2 = mkr.newOffer(1.1 ether, 1 ether, 100_000, 0);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.1 ether, 1 ether, 50_000, 0);
    uint ofr01 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    (, P.Local.t loc_cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, loc_cfg.best(), "Wrong best offer");
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr0)),
      "Oldest equivalent offer should be first"
    );
    (P.OfferStruct memory offer, ) = mgv.offerInfo(_base, _quote, ofr0);
    uint _ofr01 = offer.next;
    TestEvents.eq(_ofr01, ofr01, "Wrong 2nd offer");
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, _ofr01)),
      "Oldest equivalent offer should be first"
    );
    (offer, ) = mgv.offerInfo(_base, _quote, _ofr01);
    uint _ofr1 = offer.next;
    TestEvents.eq(_ofr1, ofr1, "Wrong 3rd offer");
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, _ofr1)),
      "Oldest equivalent offer should be first"
    );
    (offer, ) = mgv.offerInfo(_base, _quote, _ofr1);
    uint _ofr2 = offer.next;
    TestEvents.eq(_ofr2, ofr2, "Wrong 4th offer");
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, _ofr2)),
      "Oldest equivalent offer should be first"
    );
    (offer, ) = mgv.offerInfo(_base, _quote, _ofr2);
    TestEvents.eq(offer.next, 0, "Invalid OB");
  }

  // insertTest price, density (gives/gasreq) vs (gives'/gasreq'), age
  // nolongerBest
  // idemPrice
  // idemBest
  // A.BCD --> ABC.D

  function update_offer_resets_age_and_updates_best_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, cfg.best(), "Wrong best offer");
    mkr.updateOffer(1.0 ether, 1.0 ether, 100_000, ofr0, ofr0);
    (, cfg) = mgv.config(_base, _quote);
    TestEvents.eq(
      ofr1,
      cfg.best(),
      "Best offer should have changed"
    );
  }

  function update_offer_price_nolonger_best_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, cfg.best(), "Wrong best offer");
    mkr.updateOffer(1.0 ether + 1, 1.0 ether, 100_000, ofr0, ofr0);
    (, cfg) = mgv.config(_base, _quote);
    TestEvents.eq(
      ofr1,
      cfg.best(),
      "Best offer should have changed"
    );
  }

  function update_offer_density_nolonger_best_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, cfg.best(), "Wrong best offer");
    mkr.updateOffer(1.0 ether, 1.0 ether, 100_001, ofr0, ofr0);
    (, cfg) = mgv.config(_base, _quote);
    TestEvents.eq(
      ofr1,
      cfg.best(),
      "Best offer should have changed"
    );
  }

  function update_offer_price_with_self_as_pivot_becomes_best_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, cfg.best(), "Wrong best offer");
    mkr.updateOffer(1.0 ether, 1.0 ether + 1, 100_000, ofr1, ofr1);
    (, cfg) = mgv.config(_base, _quote);
    TestEvents.eq(
      ofr1,
      cfg.best(),
      "Best offer should have changed"
    );
  }

  function update_offer_density_with_self_as_pivot_becomes_best_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1.0 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1.0 ether, 100_000, 0);
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, cfg.best(), "Wrong best offer");
    mkr.updateOffer(1.0 ether, 1.0 ether, 99_999, ofr1, ofr1);
    (, cfg) = mgv.config(_base, _quote);
    TestUtils.logOfferBook(mgv, _base, _quote, 2);
    TestEvents.eq(
      cfg.best(),
      ofr1,
      "Best offer should have changed"
    );
  }

  function update_offer_price_with_best_as_pivot_becomes_best_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, cfg.best(), "Wrong best offer");
    mkr.updateOffer(1.0 ether, 1.0 ether + 1, 100_000, ofr0, ofr1);
    (, cfg) = mgv.config(_base, _quote);
    TestEvents.eq(
      ofr1,
      cfg.best(),
      "Best offer should have changed"
    );
  }

  function update_offer_density_with_best_as_pivot_becomes_best_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1.0 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1.0 ether, 100_000, 0);
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, cfg.best(), "Wrong best offer");
    mkr.updateOffer(1.0 ether, 1.0 ether, 99_999, ofr0, ofr1);
    (, cfg) = mgv.config(_base, _quote);
    TestUtils.logOfferBook(mgv, _base, _quote, 2);
    TestEvents.eq(
      cfg.best(),
      ofr1,
      "Best offer should have changed"
    );
  }

  function update_offer_price_with_best_as_pivot_changes_prevnext_test()
    public
  {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr2 = mkr.newOffer(1.1 ether, 1 ether, 100_000, 0);
    uint ofr3 = mkr.newOffer(1.2 ether, 1 ether, 100_000, 0);

    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Insertion error"
    );
    (P.OfferStruct memory offer, ) = mgv.offerInfo(_base, _quote, ofr);
    TestEvents.eq(offer.prev, ofr0, "Wrong prev offer");
    TestEvents.eq(offer.next, ofr1, "Wrong next offer");
    mkr.updateOffer(1.1 ether, 1.0 ether, 100_000, ofr0, ofr);
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Insertion error"
    );
    (offer, ) = mgv.offerInfo(_base, _quote, ofr);
    TestEvents.eq(offer.prev, ofr2, "Wrong prev offer after update");
    TestEvents.eq(offer.next, ofr3, "Wrong next offer after update");
  }

  function update_offer_price_with_self_as_pivot_changes_prevnext_test()
    public
  {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr2 = mkr.newOffer(1.1 ether, 1 ether, 100_000, 0);
    uint ofr3 = mkr.newOffer(1.2 ether, 1 ether, 100_000, 0);

    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Insertion error"
    );
    (P.OfferStruct memory offer, ) = mgv.offerInfo(_base, _quote, ofr);
    TestEvents.eq(offer.prev, ofr0, "Wrong prev offer");
    TestEvents.eq(offer.next, ofr1, "Wrong next offer");
    mkr.updateOffer(1.1 ether, 1.0 ether, 100_000, ofr, ofr);
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Insertion error"
    );
    (offer, ) = mgv.offerInfo(_base, _quote, ofr);
    TestEvents.eq(offer.prev, ofr2, "Wrong prev offer after update");
    TestEvents.eq(offer.next, ofr3, "Wrong next offer after update");
  }

  function update_offer_density_with_best_as_pivot_changes_prevnext_test()
    public
  {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr2 = mkr.newOffer(1.0 ether, 1 ether, 100_001, 0);
    uint ofr3 = mkr.newOffer(1.0 ether, 1 ether, 100_002, 0);

    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Insertion error"
    );
    (P.OfferStruct memory offer, ) = mgv.offerInfo(_base, _quote, ofr);
    TestEvents.eq(offer.prev, ofr0, "Wrong prev offer");
    TestEvents.eq(offer.next, ofr1, "Wrong next offer");
    mkr.updateOffer(1.0 ether, 1.0 ether, 100_001, ofr0, ofr);
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Update error"
    );
    (offer, ) = mgv.offerInfo(_base, _quote, ofr);
    TestEvents.eq(offer.prev, ofr2, "Wrong prev offer after update");
    TestEvents.eq(offer.next, ofr3, "Wrong next offer after update");
  }

  function update_offer_density_with_self_as_pivot_changes_prevnext_test()
    public
  {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr1 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    uint ofr2 = mkr.newOffer(1.0 ether, 1 ether, 100_001, 0);
    uint ofr3 = mkr.newOffer(1.0 ether, 1 ether, 100_002, 0);

    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Insertion error"
    );
    (P.OfferStruct memory offer, ) = mgv.offerInfo(_base, _quote, ofr);
    TestEvents.eq(offer.prev, ofr0, "Wrong prev offer");
    TestEvents.eq(offer.next, ofr1, "Wrong next offer");
    mkr.updateOffer(1.0 ether, 1.0 ether, 100_001, ofr, ofr);
    TestEvents.check(
      mgv.isLive(mgv.offers(_base, _quote, ofr)),
      "Insertion error"
    );
    (offer, ) = mgv.offerInfo(_base, _quote, ofr);
    TestEvents.eq(offer.prev, ofr2, "Wrong prev offer after update");
    TestEvents.eq(offer.next, ofr3, "Wrong next offer after update");
  }

  function update_offer_after_higher_gasprice_change_fails_test() public {
    uint provision = TestUtils.getProvision(mgv, _base, _quote, 100_000);
    mkr.provisionMgv(provision);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    (P.Global.t cfg, ) = mgv.config(_base, _quote);
    mgv.setGasprice(cfg.gasprice() + 1); //gasprice goes up
    try mkr.updateOffer(1.0 ether + 2, 1.0 ether, 100_000, ofr0, ofr0) {
      TestEvents.fail("Update offer should have failed");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/insufficientProvision", "wrong revert reason");
    }
  }

  function update_offer_after_higher_gasprice_change_succeeds_when_over_provisioned_test()
    public
  {
    (P.Global.t cfg, ) = mgv.config(_base, _quote);
    uint gasprice = cfg.gasprice();
    uint provision = TestUtils.getProvision(
      mgv,
      _base,
      _quote,
      100_000,
      gasprice
    );
    mkr.provisionMgv(provision * 2); // provisionning twice the required amount
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0); // locking exact bounty
    mgv.setGasprice(gasprice + 1); //gasprice goes up
    uint provision_ = TestUtils.getProvision( // new theoretical provision
      mgv,
      _base,
      _quote,
      100_000,
      gasprice + 1
    );
    (cfg, ) = mgv.config(_base, _quote);
    try mkr.updateOffer(1.0 ether + 2, 1.0 ether, 100_000, ofr0, ofr0) {
      TestEvents.expectFrom(address(mgv));
      emit Credit(address(mkr), provision * 2);
      emit OfferWrite(
        _base,
        _quote,
        address(mkr),
        1.0 ether,
        1.0 ether,
        gasprice, // offer at old gasprice
        100_000,
        ofr0,
        0
      );
      emit Debit(address(mkr), provision); // transfering missing provision into offer bounty
      emit OfferWrite(
        _base,
        _quote,
        address(mkr),
        1.0 ether + 2,
        1.0 ether,
        cfg.gasprice(), // offer gasprice should be the new gasprice
        100_000,
        ofr0,
        0
      );
      emit Debit(address(mkr), provision_ - provision); // transfering missing provision into offer bounty
    } catch {
      TestEvents.fail("Update offer should have succeeded");
    }
  }

  function update_offer_after_lower_gasprice_change_succeeds_test() public {
    uint provision = TestUtils.getProvision(mgv, _base, _quote, 100_000);
    mkr.provisionMgv(provision);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    (P.Global.t cfg, ) = mgv.config(_base, _quote);
    mgv.setGasprice(cfg.gasprice() - 1); //gasprice goes down
    uint _provision = TestUtils.getProvision(mgv, _base, _quote, 100_000);
    try mkr.updateOffer(1.0 ether + 2, 1.0 ether, 100_000, ofr0, ofr0) {
      TestEvents.eq(
        mgv.balanceOf(address(mkr)),
        provision - _provision,
        "Maker balance is incorrect"
      );
      TestEvents.expectFrom(address(mgv));
      emit Credit(address(mkr), provision - _provision);
    } catch {
      TestEvents.fail("Update offer should have succeeded");
    }
  }

  function update_offer_next_to_itself_does_not_break_ob_test() public {
    mkr.provisionMgv(1 ether);
    uint left = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    uint right = mkr.newOffer(1 ether + 3, 1 ether, 100_000, 0);
    uint center = mkr.newOffer(1 ether + 1, 1 ether, 100_000, 0);
    mkr.updateOffer(1 ether + 2, 1 ether, 100_000, center, center);
    (P.OfferStruct memory ofr, ) = mgv.offerInfo(_base, _quote, center);
    TestEvents.eq(ofr.prev, left, "ofr.prev should be unchanged");
    TestEvents.eq(ofr.next, right, "ofr.next should be unchanged");
  }

  function update_on_retracted_offer_test() public {
    uint provision = TestUtils.getProvision(mgv, _base, _quote, 100_000);
    mkr.provisionMgv(provision);
    uint offerId = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    mkr.retractOfferWithDeprovision(offerId);
    mkr.withdrawMgv(provision);
    TestEvents.eq(
      mgv.balanceOf(address(mkr)),
      0,
      "Maker should have no more provision on Mangrove"
    );
    (P.OfferStruct memory ofr, P.OfferDetailStruct memory dtl) = mgv.offerInfo(
      _base,
      _quote,
      offerId
    );
    TestEvents.eq(ofr.gives, 0, "Retracted offer should have 0 gives");
    TestEvents.eq(
      dtl.gasprice,
      0,
      "Deprovisioned offer should have 0 gasprice"
    );
    try mkr.updateOffer(1 ether + 2, 1 ether, 100_000, offerId, offerId) {
      TestEvents.fail(
        "Deprovisioned offer cannot be updated unless reprovisioned"
      );
    } catch Error(string memory message) {
      TestEvents.eq(message, "mgv/insufficientProvision", "");
      mkr.provisionMgv(provision);
      try mkr.updateOffer(1 ether + 2, 1 ether, 100_000, offerId, offerId) {
        (ofr, ) = mgv.offerInfo(_base, _quote, offerId);
        TestEvents.eq(ofr.gives, 1 ether, "Offer not correctly updated");
      } catch {
        TestEvents.fail("Updating offer should succeed");
      }
    }
  }

  function testOBBest(uint id) internal {
    (P.OfferStruct memory ofr, ) = mgv.offerInfo(_base, _quote, id);
    TestEvents.eq(mgv.best(_base, _quote), id, "testOBBest: not best");
    TestEvents.eq(ofr.prev, 0, "testOBBest: prev not 0");
  }

  function testOBWorst(uint id) internal {
    (P.OfferStruct memory ofr, ) = mgv.offerInfo(_base, _quote, id);
    TestEvents.eq(ofr.next, 0, "testOBWorst fail");
  }

  function testOBLink(uint left, uint right) internal {
    (P.OfferStruct memory ofr, ) = mgv.offerInfo(_base, _quote, left);
    TestEvents.eq(ofr.next, right, "testOBLink: wrong ofr.next");
    (ofr, ) = mgv.offerInfo(_base, _quote, right);
    TestEvents.eq(ofr.prev, left, "testOBLink: wrong ofr.prev");
  }

  function testOBOrder(uint[1] memory ids) internal {
    testOBBest(ids[0]);
    testOBWorst(ids[0]);
  }

  function testOBOrder(uint[2] memory ids) internal {
    testOBBest(ids[0]);
    testOBLink(ids[0], ids[1]);
    testOBWorst(ids[1]);
  }

  function testOBOrder(uint[3] memory ids) internal {
    testOBBest(ids[0]);
    testOBLink(ids[0], ids[1]);
    testOBLink(ids[1], ids[2]);
    testOBWorst(ids[2]);
  }

  function complex_offer_update_left_1_1_test() public {
    mkr.provisionMgv(1 ether);
    uint x = 1 ether;
    uint g = 100_000;

    uint one = mkr.newOffer(x, x, g, 0);
    uint two = mkr.newOffer(x + 3, x, g, 0);
    mkr.updateOffer(x + 1, x, g, 0, two);

    testOBOrder([one, two]);
  }

  function complex_offer_update_right_1_test() public {
    mkr.provisionMgv(1 ether);
    uint x = 1 ether;
    uint g = 100_000;

    uint one = mkr.newOffer(x, x, g, 0);
    uint two = mkr.newOffer(x + 3, x, g, 0);
    mkr.updateOffer(x + 1, x, g, two, two);

    testOBOrder([one, two]);
  }

  function complex_offer_update_left_1_2_test() public {
    mkr.provisionMgv(1 ether);
    uint x = 1 ether;
    uint g = 100_000;

    uint one = mkr.newOffer(x, x, g, 0);
    uint two = mkr.newOffer(x + 3, x, g, 0);
    mkr.updateOffer(x + 5, x, g, 0, two);

    testOBOrder([one, two]);
  }

  function complex_offer_update_right_1_2_test() public {
    mkr.provisionMgv(1 ether);
    uint x = 1 ether;
    uint g = 100_000;

    uint one = mkr.newOffer(x, x, g, 0);
    uint two = mkr.newOffer(x + 3, x, g, 0);
    mkr.updateOffer(x + 5, x, g, two, two);

    testOBOrder([one, two]);
  }

  function complex_offer_update_left_2_test() public {
    mkr.provisionMgv(1 ether);
    uint x = 1 ether;
    uint g = 100_000;

    uint one = mkr.newOffer(x, x, g, 0);
    uint two = mkr.newOffer(x + 3, x, g, 0);
    uint three = mkr.newOffer(x + 5, x, g, 0);
    mkr.updateOffer(x + 1, x, g, 0, three);

    testOBOrder([one, three, two]);
  }

  function complex_offer_update_right_2_test() public {
    mkr.provisionMgv(1 ether);
    uint x = 1 ether;
    uint g = 100_000;

    uint one = mkr.newOffer(x, x, g, 0);
    uint two = mkr.newOffer(x + 3, x, g, 0);
    uint three = mkr.newOffer(x + 5, x, g, 0);
    mkr.updateOffer(x + 4, x, g, three, one);

    testOBOrder([two, one, three]);
  }

  function complex_offer_update_left_3_test() public {
    mkr.provisionMgv(1 ether);
    uint x = 1 ether;
    uint g = 100_000;

    uint one = mkr.newOffer(x, x, g, 0);
    uint two = mkr.newOffer(x + 3, x, g, 0);
    mkr.retractOffer(two);
    mkr.updateOffer(x + 3, x, g, 0, two);

    testOBOrder([one, two]);
  }

  function complex_offer_update_right_3_test() public {
    mkr.provisionMgv(1 ether);
    uint x = 1 ether;
    uint g = 100_000;

    uint one = mkr.newOffer(x, x, g, 0);
    uint two = mkr.newOffer(x + 3, x, g, 0);
    mkr.retractOffer(one);
    mkr.updateOffer(x, x, g, 0, one);

    testOBOrder([one, two]);
  }

  function update_offer_prev_to_itself_does_not_break_ob_test() public {
    mkr.provisionMgv(1 ether);
    uint left = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    uint right = mkr.newOffer(1 ether + 3, 1 ether, 100_000, 0);
    uint center = mkr.newOffer(1 ether + 2, 1 ether, 100_000, 0);
    mkr.updateOffer(1 ether + 1, 1 ether, 100_000, center, center);
    (P.OfferStruct memory ofr, ) = mgv.offerInfo(_base, _quote, center);
    TestEvents.eq(ofr.prev, left, "ofr.prev should be unchanged");
    TestEvents.eq(ofr.next, right, "ofr.next should be unchanged");
  }

  function update_offer_price_stays_best_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    mkr.newOffer(1.0 ether + 2, 1 ether, 100_000, 0);
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, cfg.best(), "Wrong best offer");
    mkr.updateOffer(1.0 ether + 1, 1.0 ether, 100_000, ofr0, ofr0);
    (, cfg) = mgv.config(_base, _quote);
    TestEvents.eq(
      ofr0,
      cfg.best(),
      "Best offer should not have changed"
    );
  }

  function update_offer_density_stays_best_test() public {
    mkr.provisionMgv(10 ether);
    uint ofr0 = mkr.newOffer(1.0 ether, 1 ether, 100_000, 0);
    mkr.newOffer(1.0 ether, 1 ether, 100_002, 0);
    (, P.Local.t cfg) = mgv.config(_base, _quote);
    TestEvents.eq(ofr0, cfg.best(), "Wrong best offer");
    mkr.updateOffer(1.0 ether, 1.0 ether, 100_001, ofr0, ofr0);
    (, cfg) = mgv.config(_base, _quote);
    TestEvents.eq(
      ofr0,
      cfg.best(),
      "Best offer should not have changed"
    );
  }

  function gasbase_is_deducted_1_test() public {
    uint offer_gasbase = 20_000;
    mkr.provisionMgv(1 ether);
    mgv.setGasbase(_base, _quote, offer_gasbase);
    mgv.setGasprice(1);
    mgv.setDensity(_base, _quote, 0);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 0, 0);
    tkr.take(ofr, 0.1 ether);
    TestEvents.eq(
      mgv.balanceOf(address(mkr)),
      1 ether - offer_gasbase * 10**9,
      "Wrong gasbase deducted"
    );
  }

  function gasbase_is_deducted_2_test() public {
    uint offer_gasbase = 20_000;
    mkr.provisionMgv(1 ether);
    mgv.setGasbase(_base, _quote, offer_gasbase);
    mgv.setGasprice(1);
    mgv.setDensity(_base, _quote, 0);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 0, 0);
    tkr.take(ofr, 0.1 ether);
    TestEvents.eq(
      mgv.balanceOf(address(mkr)),
      1 ether - offer_gasbase * 10**9,
      "Wrong gasbase deducted"
    );
  }

  function penalty_gasprice_is_mgv_gasprice_test() public {
    mgv.setGasprice(10);
    mkr.shouldFail(true);
    mkr.provisionMgv(1 ether);
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    uint oldProvision = mgv.balanceOf(address(mkr));
    mgv.setGasprice(10000);
    (uint gave, uint got) = tkr.marketOrder(1 ether, 1 ether);
    TestEvents.check(gave == got && got == 0, "market Order should be noop");
    uint gotBack = mgv.balanceOf(address(mkr)) - oldProvision;
    TestEvents.eq(gotBack, 0, "Should not have gotten any provision back");
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

//import "../Mangrove.sol";
//import "../MgvLib.sol";
import "hardhat/console.sol";

import "../Toolbox/TestUtils.sol";
// import "../Toolbox/Display.sol";

import "../Agents/TestToken.sol";
import "../Agents/TestMaker.sol";
import "../Agents/TestMoriartyMaker.sol";
import "../Agents/MakerDeployer.sol";
import "../Agents/TestTaker.sol";
import "../Agents/TestDelegateTaker.sol";
import "../Agents/OfferManager.sol";

import "./TestCancelOffer.sol";
import "./TestCollectFailingOffer.sol";
import "./TestInsert.sol";
import "./TestSnipe.sol";
import "./TestFailingMarketOrder.sol";
import "./TestMarketOrder.sol";

// Pretest libraries are for deploying large contracts independently.
// Otherwise bytecode can be too large. See EIP 170 for more on size limit:
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-170.md

contract Scenarii_Test is HasMgvEvents {
  AbstractMangrove mgv;
  TestTaker taker;
  MakerDeployer makers;
  TestToken base;
  TestToken quote;
  TestUtils.Balances balances;
  uint[] offerOf;

  mapping(uint => mapping(TestUtils.Info => uint)) offers;

  receive() external payable {}

  function saveOffers() internal {
    uint offerId = mgv.best(address(base), address(quote));
    while (offerId != 0) {
      (P.OfferStruct memory offer, P.OfferDetailStruct memory offerDetail) = mgv
        .offerInfo(address(base), address(quote), offerId);
      offers[offerId][TestUtils.Info.makerWants] = offer.wants;
      offers[offerId][TestUtils.Info.makerGives] = offer.gives;
      offers[offerId][TestUtils.Info.gasreq] = offerDetail.gasreq;
      offerId = offer.next;
    }
  }

  function saveBalances() internal {
    uint[] memory balA = new uint[](makers.length());
    uint[] memory balB = new uint[](makers.length());
    uint[] memory balWei = new uint[](makers.length());
    for (uint i = 0; i < makers.length(); i++) {
      balA[i] = base.balanceOf(address(makers.getMaker(i)));
      balB[i] = quote.balanceOf(address(makers.getMaker(i)));
      balWei[i] = mgv.balanceOf(address(makers.getMaker(i)));
    }
    balances = TestUtils.Balances({
      mgvBalanceWei: address(mgv).balance,
      mgvBalanceFees: base.balanceOf(TestUtils.adminOf(mgv)),
      takerBalanceA: base.balanceOf(address(taker)),
      takerBalanceB: quote.balanceOf(address(taker)),
      takerBalanceWei: mgv.balanceOf(address(taker)),
      makersBalanceA: balA,
      makersBalanceB: balB,
      makersBalanceWei: balWei
    });
  }

  function a_deployToken_beforeAll() public {
    //console.log("IN BEFORE ALL");
    base = TokenSetup.setup("A", "$A");
    quote = TokenSetup.setup("B", "$B");

    TestUtils.not0x(address(base));
    TestUtils.not0x(address(quote));

    Display.register(address(0), "NULL_ADDRESS");
    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "Mgv_Test");
    Display.register(address(base), "base");
    Display.register(address(quote), "quote");
  }

  function b_deployMgv_beforeAll() public {
    mgv = MgvSetup.setup(base, quote);
    Display.register(address(mgv), "Mgv");
    TestUtils.not0x(address(mgv));
    mgv.setFee(address(base), address(quote), 300);
  }

  function c_deployMakersTaker_beforeAll() public {
    makers = MakerDeployerSetup.setup(mgv, address(base), address(quote));
    makers.deploy(4);
    for (uint i = 1; i < makers.length(); i++) {
      Display.register(
        address(makers.getMaker(i)),
        TestUtils.append("maker-", TestUtils.uint2str(i))
      );
    }
    Display.register(address(makers.getMaker(0)), "failer");
    taker = TakerSetup.setup(mgv, address(base), address(quote));
    Display.register(address(taker), "taker");
  }

  function d_provisionAll_beforeAll() public {
    // low level tranfer because makers needs gas to transfer to each maker
    (bool success, ) = address(makers).call{gas: gasleft(), value: 80 ether}(
      ""
    ); // msg.value is distributed evenly amongst makers
    require(success, "maker transfer");

    for (uint i = 0; i < makers.length(); i++) {
      TestMaker maker = makers.getMaker(i);
      maker.provisionMgv(10 ether);
      base.mint(address(maker), 5 ether);
    }

    quote.mint(address(taker), 5 ether);
    taker.approveMgv(quote, 5 ether);
    taker.approveMgv(base, 50 ether);
    saveBalances();
  }

  function snipe_insert_and_fail_test() public {
    offerOf = TestInsert.run(balances, mgv, makers, taker, base, quote);
    //TestUtils.printOfferBook(mgv);
    TestUtils.logOfferBook(mgv, address(base), address(quote), 4);

    //TestEvents.logString("=== Snipe test ===", 0);
    saveBalances();
    saveOffers();
    (uint takerGot, uint takerGave) = TestSnipe.run(
      balances,
      offers,
      mgv,
      makers,
      taker,
      base,
      quote
    );
    TestEvents.expectFrom(address(mgv));
    emit OrderComplete(
      address(base),
      address(quote),
      address(taker),
      takerGot,
      takerGave
    );
    TestEvents.stopExpecting();

    TestUtils.logOfferBook(mgv, address(base), address(quote), 4);

    // restore offer that was deleted after partial fill, minus taken amount
    makers.getMaker(2).updateOffer(
      1 ether - 0.375 ether,
      0.8 ether - 0.3 ether,
      80_000,
      0,
      2
    );

    TestUtils.logOfferBook(mgv, address(base), address(quote), 4);

    //TestEvents.logString("=== Market order test ===", 0);
    saveBalances();
    saveOffers();
    TestMarketOrder.run(balances, offers, mgv, makers, taker, base, quote);
    TestUtils.logOfferBook(mgv, address(base), address(quote), 4);

    //TestEvents.logString("=== Failling offer test ===", 0);
    saveBalances();
    saveOffers();
    TestCollectFailingOffer.run(
      balances,
      offers,
      mgv,
      offerOf[0],
      makers,
      taker,
      base,
      quote
    );
    TestUtils.logOfferBook(mgv, address(base), address(quote), 4);
    saveBalances();
    saveOffers();
  }
}

contract DeepCollect_Test {
  TestToken base;
  TestToken quote;
  AbstractMangrove mgv;
  TestTaker tkr;
  TestMoriartyMaker evil;

  receive() external payable {}

  function a_beforeAll() public {
    base = TokenSetup.setup("A", "$A");
    quote = TokenSetup.setup("B", "$B");
    mgv = MgvSetup.setup(base, quote);
    tkr = TakerSetup.setup(mgv, address(base), address(quote));

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "DeepCollect_Tester");
    Display.register(address(base), "$A");
    Display.register(address(quote), "$B");
    Display.register(address(mgv), "mgv");
    Display.register(address(tkr), "taker");

    quote.mint(address(tkr), 5 ether);
    tkr.approveMgv(quote, 20 ether);
    tkr.approveMgv(base, 20 ether);

    evil = new TestMoriartyMaker(mgv, address(base), address(quote));
    Display.register(address(evil), "Moriarty");

    (bool success, ) = address(evil).call{gas: gasleft(), value: 20 ether}("");
    require(success, "maker transfer");
    evil.provisionMgv(10 ether);
    base.mint(address(evil), 5 ether);
    evil.approveMgv(base, 5 ether);

    evil.newOffer({
      wants: 1 ether,
      gives: 0.5 ether,
      gasreq: 100000,
      pivotId: 0
    });
  }

  function market_with_failures_test() public {
    //TestEvents.logString("=== DeepCollect test ===", 0);
    TestFailingMarketOrder.moWithFailures(
      mgv,
      address(base),
      address(quote),
      tkr
    );
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;
import "../../AbstractMangrove.sol";
import "./OfferManager.sol";
import "./TestToken.sol";

contract TestDelegateTaker is ITaker {
  OfferManager ofrMgr;
  TestToken base;
  TestToken quote;

  constructor(
    OfferManager _ofrMgr,
    TestToken _base,
    TestToken _quote
  ) {
    ofrMgr = _ofrMgr;
    base = _base;
    quote = _quote;
  }

  receive() external payable {}

  function takerTrade(
    //NB this is not called if mgv is not a flashTaker mgv
    address,
    address,
    uint,
    uint shouldGive
  ) external override {
    if (msg.sender == address(ofrMgr)) {
      TestToken(quote).mint(address(this), shouldGive); // taker should have been given admin status for quote
    } // taker should have approved ofrMgr for quote
  }

  function delegateOrder(
    OfferManager mgr,
    uint wants,
    uint gives,
    AbstractMangrove mgv,
    bool invertedResidual
  ) public {
    try quote.approve(address(mgr), gives) {
      mgr.order{value: 0.01 ether}(
        mgv,
        address(base),
        address(quote),
        wants,
        gives,
        invertedResidual
      );
    } catch {
      require(false, "failed to approve mgr");
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
import "../Toolbox/TestUtils.sol";

library TestCancelOffer {
  function run(
    TestUtils.Balances storage balances,
    mapping(uint => mapping(TestUtils.Info => uint)) storage offers,
    AbstractMangrove mgv,
    TestMaker wrongOwner,
    TestMaker maker,
    uint offerId,
    TestTaker, /* taker */
    TestToken base,
    TestToken quote
  ) external {
    try wrongOwner.retractOfferWithDeprovision(offerId) {
      TestEvents.fail("Invalid authorization to cancel order");
    } catch Error(string memory reason) {
      TestEvents.eq(reason, "mgv/cancelOffer/unauthorized", "Unexpected throw");
      try maker.retractOfferWithDeprovision(offerId) {
        maker.retractOfferWithDeprovision(0);
        uint provisioned = TestUtils.getProvision(
          mgv,
          address(base),
          address(quote),
          offers[offerId][TestUtils.Info.gasreq]
        );
        TestEvents.eq(
          mgv.balanceOf(address(maker)),
          balances.makersBalanceWei[offerId] + provisioned,
          "Incorrect returned provision to maker"
        );
      } catch {
        TestEvents.fail("Cancel order failed unexpectedly");
      }
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../Toolbox/TestUtils.sol";

library TestCollectFailingOffer {
  function run(
    TestUtils.Balances storage balances,
    mapping(uint => mapping(TestUtils.Info => uint)) storage offers,
    AbstractMangrove mgv,
    uint failingOfferId,
    MakerDeployer makers,
    TestTaker taker,
    TestToken base,
    TestToken quote
  ) external {
    // executing failing offer
    try taker.takeWithInfo(failingOfferId, 0.5 ether) returns (
      bool success,
      uint takerGot,
      uint takerGave
    ) {
      // take should return false not throw
      TestEvents.check(!success, "Failer should fail");
      TestEvents.eq(takerGot, 0, "Failed offer should declare 0 takerGot");
      TestEvents.eq(takerGave, 0, "Failed offer should declare 0 takerGave");
      // failingOffer should have been removed from Mgv
      {
        TestEvents.check(
          !mgv.isLive(
            mgv.offers(address(base), address(quote), failingOfferId)
          ),
          "Failing offer should have been removed from Mgv"
        );
      }
      uint provision = TestUtils.getProvision(
        mgv,
        address(base),
        address(quote),
        offers[failingOfferId][TestUtils.Info.gasreq]
      );
      uint returned = mgv.balanceOf(address(makers.getMaker(0))) -
        balances.makersBalanceWei[0];
      TestEvents.eq(
        address(mgv).balance,
        balances.mgvBalanceWei - (provision - returned),
        "Mangrove has not send the correct amount to taker"
      );
    } catch (bytes memory errorMsg) {
      string memory err = abi.decode(errorMsg, (string));
      TestEvents.fail(err);
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../Toolbox/TestUtils.sol";

library TestInsert {
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  function run(
    TestUtils.Balances storage balances,
    AbstractMangrove mgv,
    MakerDeployer makers,
    TestTaker, /* taker */ // silence warning about unused argument
    TestToken base,
    TestToken quote
  ) public returns (uint[] memory) {
    // each maker publishes an offer
    uint[] memory offerOf = new uint[](makers.length());
    offerOf[1] = makers.getMaker(1).newOffer({ // offer 1
      wants: 1 ether,
      gives: 0.5 ether,
      gasreq: 50_000,
      pivotId: 0
    });
    offerOf[2] = makers.getMaker(2).newOffer({ // offer 2
      wants: 1 ether,
      gives: 0.8 ether,
      gasreq: 80_000,
      pivotId: 1
    });
    offerOf[3] = makers.getMaker(3).newOffer({ // offer 3
      wants: 0.5 ether,
      gives: 1 ether,
      gasreq: 90_000,
      pivotId: 72
    });
    (P.Global.t cfg, ) = mgv.config(address(base), address(quote));
    offerOf[0] = makers.getMaker(0).newOffer({ //failer offer 4
      wants: 20 ether,
      gives: 10 ether,
      gasreq: cfg.gasmax(),
      pivotId: 0
    });
    //TestUtils.printOfferBook(mgv);
    //Checking makers have correctly provisoned their offers
    for (uint i = 0; i < makers.length(); i++) {
      uint gasreq_i = TestUtils.getOfferInfo(
        mgv,
        address(base),
        address(quote),
        TestUtils.Info.gasreq,
        offerOf[i]
      );
      uint provision_i = TestUtils.getProvision(
        mgv,
        address(base),
        address(quote),
        gasreq_i
      );
      TestEvents.eq(
        mgv.balanceOf(address(makers.getMaker(i))),
        balances.makersBalanceWei[i] - provision_i,
        TestUtils.append(
          "Incorrect wei balance for maker ",
          TestUtils.uint2str(i)
        )
      );
    }
    //Checking offers are correctly positioned (3 > 2 > 1 > 0)
    uint offerId = mgv.best(address(base), address(quote));
    uint expected_maker = 3;
    while (offerId != 0) {
      (P.OfferStruct memory offer, P.OfferDetailStruct memory od) = mgv.offerInfo(
        address(base),
        address(quote),
        offerId
      );
      TestEvents.eq(
        od.maker,
        address(makers.getMaker(expected_maker)),
        TestUtils.append(
          "Incorrect maker address at offer ",
          TestUtils.uint2str(offerId)
        )
      );

      unchecked {
        expected_maker -= 1;
      }
      offerId = offer.next;
    }
    return offerOf;
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../Toolbox/TestUtils.sol";

library TestSnipe {
  function run(
    TestUtils.Balances storage balances,
    mapping(uint => mapping(TestUtils.Info => uint)) storage offers,
    AbstractMangrove mgv,
    MakerDeployer makers,
    TestTaker taker,
    TestToken base,
    TestToken quote
  ) external returns (uint takerGot, uint takerGave) {
    uint orderAmount = 0.3 ether;
    uint snipedId = 2;
    TestMaker maker = makers.getMaker(snipedId); // maker whose offer will be sniped

    //(uint init_mkr_wants, uint init_mkr_gives,,,,,)=mgv.getOfferInfo(2);
    //---------------SNIPE------------------//
    {
      bool takeSuccess;
      (takeSuccess, takerGot, takerGave) = taker.takeWithInfo(
        snipedId,
        orderAmount
      );

      TestEvents.check(takeSuccess, "snipe should be a success");
    }
    TestEvents.eq(
      base.balanceOf(TestUtils.adminOf(mgv)), //actual
      balances.mgvBalanceFees +
        TestUtils.getFee(mgv, address(base), address(quote), orderAmount), //expected
      "incorrect Mangrove A balance"
    );
    TestEvents.eq(
      base.balanceOf(address(taker)), // actual
      balances.takerBalanceA +
        orderAmount -
        TestUtils.getFee(mgv, address(base), address(quote), orderAmount), // expected
      "incorrect taker A balance"
    );
    TestEvents.eq(
      takerGot,
      orderAmount -
        TestUtils.getFee(mgv, address(base), address(quote), orderAmount),
      "Incorrect takerGot"
    );
    {
      uint shouldGive = (orderAmount *
        offers[snipedId][TestUtils.Info.makerWants]) /
        offers[snipedId][TestUtils.Info.makerGives];
      TestEvents.eq(
        quote.balanceOf(address(taker)),
        balances.takerBalanceB - shouldGive,
        "incorrect taker B balance"
      );
      TestEvents.eq(takerGave, shouldGive, "Incorrect takerGave");
    }
    TestEvents.eq(
      base.balanceOf(address(maker)),
      balances.makersBalanceA[snipedId] - orderAmount,
      "incorrect maker A balance"
    );
    TestEvents.eq(
      quote.balanceOf(address(maker)),
      balances.makersBalanceB[snipedId] +
        (orderAmount * offers[snipedId][TestUtils.Info.makerWants]) /
        offers[snipedId][TestUtils.Info.makerGives],
      "incorrect maker B balance"
    );
    // Testing residual offer
    (P.OfferStruct memory ofr, ) = mgv.offerInfo(
      address(base),
      address(quote),
      snipedId
    );
    TestEvents.check(ofr.gives == 0, "Offer should not have a residual");
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../Toolbox/TestUtils.sol";

library TestFailingMarketOrder {
  function moWithFailures(
    AbstractMangrove mgv,
    address base,
    address quote,
    TestTaker taker
  ) external {
    taker.marketOrderWithFail({wants: 10 ether, gives: 30 ether});
    TestEvents.check(
      TestUtils.isEmptyOB(mgv, base, quote),
      "Offer book should be empty"
    );
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
import "../Toolbox/TestUtils.sol";

library TestMarketOrder {
  function run(
    TestUtils.Balances storage balances,
    mapping(uint => mapping(TestUtils.Info => uint)) storage offers,
    AbstractMangrove mgv,
    MakerDeployer makers,
    TestTaker taker,
    TestToken base,
    TestToken quote
  ) external {
    uint takerWants = 1.6 ether; // of B token
    uint takerGives = 2 ether; // of A token

    (uint takerGot, uint takerGave) = taker.marketOrder(takerWants, takerGives);

    // Checking Makers balances
    for (uint i = 2; i < 4; i++) {
      // offers 2 and 3 were consumed entirely
      TestEvents.eq(
        base.balanceOf(address(makers.getMaker(i))),
        balances.makersBalanceA[i] - offers[i][TestUtils.Info.makerGives],
        TestUtils.append(
          "Incorrect A balance for maker ",
          TestUtils.uint2str(i)
        )
      );
      TestEvents.eq(
        quote.balanceOf(address(makers.getMaker(i))),
        balances.makersBalanceB[i] + offers[i][TestUtils.Info.makerWants],
        TestUtils.append(
          "Incorrect B balance for maker ",
          TestUtils.uint2str(i)
        )
      );
    }
    uint leftMkrWants;
    {
      uint leftTkrWants = takerWants -
        (offers[2][TestUtils.Info.makerGives] +
          offers[3][TestUtils.Info.makerGives]);

      leftMkrWants =
        (offers[1][TestUtils.Info.makerWants] * leftTkrWants) /
        offers[1][TestUtils.Info.makerGives];

      TestEvents.eq(
        base.balanceOf(address(makers.getMaker(1))),
        balances.makersBalanceA[1] - leftTkrWants,
        "Incorrect A balance for maker 1"
      );
    }

    TestEvents.eq(
      quote.balanceOf(address(makers.getMaker(1))),
      balances.makersBalanceB[1] + leftMkrWants,
      "Incorrect B balance for maker 1"
    );

    // Checking taker balance
    TestEvents.eq(
      base.balanceOf(address(taker)), // actual
      balances.takerBalanceA +
        takerWants -
        TestUtils.getFee(mgv, address(base), address(quote), takerWants), // expected
      "incorrect taker A balance"
    );

    TestEvents.eq(
      takerGot,
      takerWants -
        TestUtils.getFee(mgv, address(base), address(quote), takerWants),
      "Incorrect declared takerGot"
    );

    uint shouldGive = (offers[3][TestUtils.Info.makerWants] +
      offers[2][TestUtils.Info.makerWants] +
      leftMkrWants);
    TestEvents.eq(
      quote.balanceOf(address(taker)), // actual
      balances.takerBalanceB - shouldGive, // expected
      "incorrect taker B balance"
    );

    TestEvents.eq(takerGave, shouldGive, "Incorrect declared takerGave");

    // Checking DEX Fee Balance
    TestEvents.eq(
      base.balanceOf(TestUtils.adminOf(mgv)), //actual
      balances.mgvBalanceFees +
        TestUtils.getFee(mgv, address(base), address(quote), takerWants), //expected
      "incorrect Mangrove balances"
    );
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "hardhat/console.sol";
import "../../MgvLib.sol";
import "../Toolbox/TestUtils.sol";

import "../Agents/TestToken.sol";
import "../Agents/TestDelegateTaker.sol";
import "../Agents/OfferManager.sol";
import "../Agents/UniSwapMaker.sol";

contract AMM_Test is HasMgvEvents {
  using P.Global for P.Global.t;

  AbstractMangrove mgv;
  AbstractMangrove invMgv;
  TestToken tk0;
  TestToken tk1;

  receive() external payable {}

  function a_deployToken_beforeAll() public {
    //console.log("IN BEFORE ALL");
    tk0 = TokenSetup.setup("tk0", "$tk0");
    tk1 = TokenSetup.setup("tk1", "$tk1");

    TestUtils.not0x(address(tk0));
    TestUtils.not0x(address(tk1));

    Display.register(address(0), "NULL_ADDRESS");
    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "AMM_Test");
    Display.register(address(tk0), "tk0");
    Display.register(address(tk1), "tk1");
  }

  function b_deployMgv_beforeAll() public {
    mgv = MgvSetup.setup(tk0, tk1);
    Display.register(address(mgv), "Mgv");
    TestUtils.not0x(address(mgv));
    //mgv.setFee(address(tk0), address(tk1), 300);

    invMgv = MgvSetup.setup(tk0, tk1, true);
    Display.register(address(invMgv), "InvMgv");
    TestUtils.not0x(address(invMgv));
    //invMgv.setFee(address(tk0), address(tk1), 300);
  }

  function prepare_offer_manager()
    internal
    returns (
      OfferManager,
      TestDelegateTaker,
      TestDelegateTaker
    )
  {
    OfferManager mgr = new OfferManager(mgv, invMgv);
    Display.register(address(mgr), "OfrMgr");

    TestDelegateTaker tkr = new TestDelegateTaker(mgr, tk0, tk1);
    TestDelegateTaker _tkr = new TestDelegateTaker(mgr, tk1, tk0);
    Display.register(address(tkr), "Taker (tk0,tk1)");
    Display.register(address(_tkr), "Taker (tk1,tk0)");
    bool noRevert0;
    (noRevert0, ) = address(_tkr).call{value: 1 ether}("");
    bool noRevert1;
    (noRevert1, ) = address(tkr).call{value: 1 ether}("");
    require(noRevert1 && noRevert0);

    TestMaker maker = MakerSetup.setup(mgv, address(tk0), address(tk1));
    Display.register(address(maker), "Maker");
    tk0.mint(address(maker), 10 ether);
    (bool success, ) = address(maker).call{gas: gasleft(), value: 10 ether}("");
    require(success);
    maker.provisionMgv(10 ether);
    maker.approveMgv(tk0, 10 ether);
    maker.newOffer({
      wants: 1 ether,
      gives: 0.5 ether,
      gasreq: 50_000,
      pivotId: 0
    });
    maker.newOffer({
      wants: 1 ether,
      gives: 0.8 ether,
      gasreq: 80_000,
      pivotId: 1
    });
    maker.newOffer({
      wants: 0.5 ether,
      gives: 1 ether,
      gasreq: 90_000,
      pivotId: 72
    });
    return (mgr, tkr, _tkr);
  }

  function check_logs(address mgr, bool inverted) internal {
    TestEvents.expectFrom(address(mgv));
    emit OfferSuccess(
      address(tk0),
      address(tk1),
      3,
      address(mgr),
      1 ether,
      0.5 ether
    );
    emit OfferSuccess(
      address(tk0),
      address(tk1),
      2,
      address(mgr),
      0.8 ether,
      1 ether
    );
    AbstractMangrove MGV = mgv;
    if (inverted) {
      TestEvents.expectFrom(address(invMgv));
      MGV = invMgv;
    }
    (P.Global.t global, ) = MGV.config(address(0), address(0));
    emit OfferWrite(
      address(tk1),
      address(tk0),
      mgr,
      1.2 ether,
      1.2 ether,
      global.gasprice(),
      100_000,
      1,
      0
    );
    emit OfferSuccess(
      address(tk1),
      address(tk0),
      1,
      address(mgr),
      1.2 ether,
      1.2 ether
    );
    TestEvents.expectFrom(address(mgv));

    (P.Global.t cfg, ) = mgv.config(address(0), address(0));
    emit OfferWrite(
      address(tk0),
      address(tk1),
      mgr,
      0.6 ether,
      0.6 ether,
      cfg.gasprice(),
      100_000,
      4,
      0
    );
  }

  function offer_manager_test() public {
    (
      OfferManager mgr,
      TestDelegateTaker tkr,
      TestDelegateTaker _tkr
    ) = prepare_offer_manager();
    tk1.mint(address(tkr), 5 ether);
    tk0.mint(address(_tkr), 5 ether);

    TestUtils.logOfferBook(mgv, address(tk0), address(tk1), 5);
    Display.logBalances(
      [address(tk0), address(tk1)],
      address(tkr),
      address(_tkr)
    );

    tkr.delegateOrder(mgr, 3 ether, 3 ether, mgv, false); // (A,B) order

    Display.logBalances(
      [address(tk0), address(tk1)],
      address(tkr),
      address(_tkr)
    );
    TestUtils.logOfferBook(mgv, address(tk0), address(tk1), 5); // taker has more A
    TestUtils.logOfferBook(mgv, address(tk1), address(tk0), 2);
    //Display.logBalances(tk0, tk1, address(taker));

    _tkr.delegateOrder(mgr, 1.8 ether, 1.8 ether, mgv, false); // (B,A) order
    TestUtils.logOfferBook(mgv, address(tk0), address(tk1), 5);
    TestUtils.logOfferBook(mgv, address(tk1), address(tk0), 2);
    Display.logBalances(
      [address(tk0), address(tk1)],
      address(tkr),
      address(_tkr)
    );

    check_logs(address(mgr), false);
  }

  function inverted_offer_manager_test() public {
    (
      OfferManager mgr,
      TestDelegateTaker tkr,
      TestDelegateTaker _tkr
    ) = prepare_offer_manager();

    tk1.mint(address(tkr), 5 ether);
    //tk0.mint(address(_taker), 5 ether);
    tk0.addAdmin(address(_tkr)); // to test flashloan on the taker side

    TestUtils.logOfferBook(mgv, address(tk0), address(tk1), 5);
    Display.logBalances(
      [address(tk0), address(tk1)],
      address(tkr),
      address(_tkr)
    );

    tkr.delegateOrder(mgr, 3 ether, 3 ether, mgv, true); // (A,B) order, residual posted on invertedMgv(B,A)

    Display.logBalances(
      [address(tk0), address(tk1)],
      address(tkr),
      address(_tkr)
    );
    TestUtils.logOfferBook(mgv, address(tk0), address(tk1), 5); // taker has more A
    TestUtils.logOfferBook(invMgv, address(tk1), address(tk0), 2);
    Display.logBalances([address(tk0), address(tk1)], address(tkr));

    _tkr.delegateOrder(mgr, 1.8 ether, 1.8 ether, invMgv, false); // (B,A) FlashTaker order
    TestUtils.logOfferBook(mgv, address(tk0), address(tk1), 5);
    TestUtils.logOfferBook(invMgv, address(tk1), address(tk0), 2);
    Display.logBalances(
      [address(tk0), address(tk1)],
      address(tkr),
      address(_tkr)
    );
    check_logs(address(mgr), true);
  }

  function uniswap_like_maker_test() public {
    UniSwapMaker amm = new UniSwapMaker(mgv, 100, 3); // creates the amm

    Display.register(address(amm), "UnisWapMaker");
    Display.register(address(this), "TestRunner");

    tk1.mint(address(amm), 1000 ether);
    tk0.mint(address(amm), 500 ether);

    mgv.fund{value: 5 ether}(address(amm));

    tk1.mint(address(this), 5 ether);
    tk1.approve(address(mgv), 2**160 - 1);

    tk0.mint(address(this), 5 ether);
    tk0.approve(address(mgv), 2**160 - 1);

    amm.newMarket(address(tk0), address(tk1));

    TestUtils.logOfferBook(mgv, address(tk0), address(tk1), 1);
    TestUtils.logOfferBook(mgv, address(tk1), address(tk0), 1);

    mgv.marketOrder(address(tk0), address(tk1), 3 ether, 2**160 - 1, true);

    TestUtils.logOfferBook(mgv, address(tk0), address(tk1), 1);
    TestUtils.logOfferBook(mgv, address(tk1), address(tk0), 1);
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./TestToken.sol";
import "../../AbstractMangrove.sol";
import {IMaker} from "../../MgvLib.sol";

// Mangrove must be provisioned in the name of UniSwapMaker
// UniSwapMaker must have ERC20 credit in tk0 and tk1 and these credits should not be shared (since contract is memoryless)
contract UniSwapMaker is IMaker {
  AbstractMangrove mgv;
  address private admin;
  uint gasreq = 80_000;
  uint8 share; // [1,100] for 1/1 to 1/100
  uint8 fee; // per 1000
  uint32 ofr0;
  uint32 ofr1;

  constructor(
    AbstractMangrove _mgv,
    uint _share,
    uint _fee
  ) {
    require(_share > 1, "Invalid parameters");
    require(uint8(_fee) == _fee && uint8(_share) == _share);
    admin = msg.sender;
    mgv = _mgv; // Abstract Mangrove
    share = uint8(_share);
    fee = uint8(_fee);
  }

  receive() external payable {}

  function setParams(uint _fee, uint _share) external {
    require(_share > 1, "Invalid parameters");
    require(uint8(_fee) == _fee && uint8(_share) == _share);
    if (msg.sender == admin) {
      fee = uint8(_fee);
      share = uint8(_share);
    }
  }

  event Execute(
    address mgv,
    address base,
    address quote,
    uint offerId,
    uint takerWants,
    uint takerGives
  );

  function makerExecute(ML.SingleOrder calldata order)
    external
    override
    returns (bytes32 avoid_compilation_warning)
  {
    avoid_compilation_warning;
    require(msg.sender == address(mgv), "Illegal call");
    emit Execute(
      msg.sender,
      order.outbound_tkn, // takerWants
      order.inbound_tkn, // takerGives
      order.offerId,
      order.wants,
      order.gives
    );
    return "";
  }

  // newPrice(makerWants,makerGives)
  function newPrice(uint pool0, uint pool1) internal view returns (uint, uint) {
    uint newGives = pool1 / share; // share = 100 for 1%
    uint x = (newGives * pool0) / (pool1 - newGives); // forces newGives < poolGives
    uint newWants = (1000 * x) / (1000 - fee); // fee < 1000
    return (newWants, newGives);
  }

  function newMarket(address tk0, address tk1) public {
    TestToken(tk0).approve(address(mgv), 2**256 - 1);
    TestToken(tk1).approve(address(mgv), 2**256 - 1);

    uint pool0 = TestToken(tk0).balanceOf(address(this));
    uint pool1 = TestToken(tk1).balanceOf(address(this));

    (uint wants0, uint gives1) = newPrice(pool0, pool1);
    (uint wants1, uint gives0) = newPrice(pool1, pool0);
    ofr0 = uint32(mgv.newOffer(tk0, tk1, wants0, gives1, gasreq, 0, 0));
    ofr1 = uint32(mgv.newOffer(tk1, tk0, wants1, gives0, gasreq, 0, 0)); // natural OB
  }

  function makerPosthook(ML.SingleOrder calldata order, ML.OrderResult calldata)
    external
    override
  {
    // taker has paid maker
    require(msg.sender == address(mgv)); // may not be necessary
    uint pool0 = TestToken(order.inbound_tkn).balanceOf(address(this)); // pool0 has increased
    uint pool1 = TestToken(order.outbound_tkn).balanceOf(address(this)); // pool1 has decreased

    (uint newWants, uint newGives) = newPrice(pool0, pool1);

    mgv.updateOffer(
      order.outbound_tkn,
      order.inbound_tkn,
      newWants,
      newGives,
      gasreq,
      0, // gasprice
      0, // best pivot
      order.offerId // the offer that was executed
    );
    // for all pairs in opposite Dex:
    uint OFR = ofr0;
    if (order.offerId == ofr0) {
      OFR = ofr1;
    }

    (newWants, newGives) = newPrice(pool1, pool0);
    mgv.updateOffer(
      order.inbound_tkn,
      order.outbound_tkn,
      newWants,
      newGives,
      gasreq,
      0,
      OFR,
      OFR
    );
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "../AbstractMangrove.sol";
import "../MgvLib.sol";
import "hardhat/console.sol";
import "@giry/hardhat-test-solidity/test.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";
import "./Agents/TestMoriartyMaker.sol";
import "./Agents/MakerDeployer.sol";
import "./Agents/TestTaker.sol";

contract NotAdmin {
  AbstractMangrove mgv;

  constructor(AbstractMangrove _mgv) {
    mgv = _mgv;
  }

  function setGasprice(uint value) public {
    mgv.setGasprice(value);
  }

  function setFee(
    address base,
    address quote,
    uint fee
  ) public {
    mgv.setFee(base, quote, fee);
  }

  function setGovernance(address newGovernance) public {
    mgv.setGovernance(newGovernance);
  }

  function kill() public {
    mgv.kill();
  }

  function activate(
    address base,
    address quote,
    uint fee,
    uint density,
    uint offer_gasbase
  ) public {
    mgv.activate(base, quote, fee, density, offer_gasbase);
  }

  function setGasbase(
    address base,
    address quote,
    uint offer_gasbase
  ) public {
    mgv.setGasbase(base, quote, offer_gasbase);
  }

  function setGasmax(uint value) public {
    mgv.setGasmax(value);
  }

  function setDensity(
    address base,
    address quote,
    uint value
  ) public {
    mgv.setDensity(base, quote, value);
  }

  function setVault(address value) public {
    mgv.setVault(value);
  }

  function setMonitor(address value) public {
    mgv.setMonitor(value);
  }
}

contract Deployer {
  AbstractMangrove mgv;

  function deploy() public returns (AbstractMangrove) {
    mgv = MgvSetup.deploy(msg.sender);
    return mgv;
  }

  function setGovernance(address governance) public {
    mgv.setGovernance(governance);
  }
}

// In these tests, the testing contract is the market maker.
contract Gatekeeping_Test is IMaker, HasMgvEvents {
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  receive() external payable {}

  AbstractMangrove mgv;
  TestTaker tkr;
  TestMaker mkr;
  TestMaker dual_mkr;
  address base;
  address quote;

  function gov_is_not_sender_test() public {
    Deployer deployer = new Deployer();
    AbstractMangrove _mgv = deployer.deploy();

    TestEvents.eq(
      _mgv.governance(),
      address(this),
      "governance should return this"
    );
  }

  function a_beforeAll() public {
    TestToken baseT = TokenSetup.setup("A", "$A");
    TestToken quoteT = TokenSetup.setup("B", "$B");
    base = address(baseT);
    quote = address(quoteT);
    mgv = MgvSetup.setup(baseT, quoteT);
    tkr = TakerSetup.setup(mgv, base, quote);
    mkr = MakerSetup.setup(mgv, base, quote);
    dual_mkr = MakerSetup.setup(mgv, quote, base);

    payable(tkr).transfer(10 ether);
    payable(mkr).transfer(10 ether);
    payable(dual_mkr).transfer(10 ether);

    bool noRevert;
    (noRevert, ) = address(mgv).call{value: 10 ether}("");

    mkr.provisionMgv(5 ether);
    dual_mkr.provisionMgv(5 ether);

    baseT.mint(address(this), 2 ether);
    quoteT.mint(address(tkr), 1 ether);
    quoteT.mint(address(mkr), 1 ether);
    baseT.mint(address(dual_mkr), 1 ether);

    baseT.approve(address(mgv), 1 ether);
    quoteT.approve(address(mgv), 1 ether);
    tkr.approveMgv(quoteT, 1 ether);

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "Gatekeeping_Test/maker");
    Display.register(base, "$A");
    Display.register(quote, "$B");
    Display.register(address(mgv), "mgv");
    Display.register(address(tkr), "taker[$A,$B]");
    Display.register(address(dual_mkr), "maker[$B,$A]");
    Display.register(address(mkr), "maker[$A,$B]");
  }

  /* # Test Config */

  function gov_can_transfer_rights_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    mgv.setGovernance(address(notAdmin));

    try mgv.setFee(base, quote, 0) {
      TestEvents.fail("testing contracts should no longer be admin");
    } catch {}

    try notAdmin.setFee(base, quote, 1) {} catch {
      TestEvents.fail("notAdmin should have been given admin rights");
    }
    // Logging tests
    TestEvents.expectFrom(address(mgv));
    emit SetGovernance(address(notAdmin));
    emit SetFee(base, quote, 1);
  }

  function only_gov_can_set_fee_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    try notAdmin.setFee(base, quote, 0) {
      TestEvents.fail("nonadmin cannot set fee");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/unauthorized");
    }
  }

  function only_gov_can_set_density_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    try notAdmin.setDensity(base, quote, 0) {
      TestEvents.fail("nonadmin cannot set density");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/unauthorized");
    }
  }

  function set_zero_density_test() public {
    try mgv.setDensity(base, quote, 0) {} catch Error(string memory) {
      TestEvents.fail("setting density to 0 should work");
    }
    // Logging tests
    TestEvents.expectFrom(address(mgv));
    emit SetDensity(base, quote, 0);
  }

  function only_gov_can_kill_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    try notAdmin.kill() {
      TestEvents.fail("nonadmin cannot kill");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/unauthorized");
    }
  }

  function killing_updates_config_test() public {
    (P.Global.t global, ) = mgv.config(address(0), address(0));
    TestEvents.check(
      !global.dead(),
      "mgv should not be dead "
    );
    mgv.kill();
    (global, ) = mgv.config(address(0), address(0));
    TestEvents.check(global.dead(), "mgv should be dead ");
    // Logging tests
    TestEvents.expectFrom(address(mgv));
    emit Kill();
  }

  function kill_is_idempotent_test() public {
    (P.Global.t global, ) = mgv.config(address(0), address(0));
    TestEvents.check(
      !global.dead(),
      "mgv should not be dead "
    );
    mgv.kill();
    (global, ) = mgv.config(address(0), address(0));
    TestEvents.check(global.dead(), "mgv should be dead");
    mgv.kill();
    (global, ) = mgv.config(address(0), address(0));
    TestEvents.check(
      global.dead(),
      "mgv should still be dead"
    );
    // Logging tests
    TestEvents.expectFrom(address(mgv));
    emit Kill();
    emit Kill();
  }

  function only_gov_can_set_vault_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    try notAdmin.setVault(address(this)) {
      TestEvents.fail("nonadmin cannot set vault");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/unauthorized");
    }
  }

  function only_gov_can_set_monitor_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    try notAdmin.setMonitor(address(this)) {
      TestEvents.fail("nonadmin cannot set monitor");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/unauthorized");
    }
  }

  function only_gov_can_set_active_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    try notAdmin.activate(quote, base, 0, 100, 0) {
      TestEvents.fail("nonadmin cannot set active");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/unauthorized");
    }
  }

  function only_gov_can_set_gasprice_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    try notAdmin.setGasprice(0) {
      TestEvents.fail("nonadmin cannot set gasprice");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/unauthorized");
    }
  }

  function only_gov_can_set_gasmax_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    try notAdmin.setGasmax(0) {
      TestEvents.fail("nonadmin cannot set gasmax");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/unauthorized");
    }
  }

  function only_gov_can_set_gasbase_test() public {
    NotAdmin notAdmin = new NotAdmin(mgv);
    try notAdmin.setGasbase(base, quote, 0) {
      TestEvents.fail("nonadmin cannot set gasbase");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/unauthorized");
    }
  }

  function empty_mgv_ok_test() public {
    try tkr.marketOrder(0, 0) {} catch {
      TestEvents.fail("market order on empty mgv should not fail");
    }
    // Logging tests
  }

  function set_fee_ceiling_test() public {
    try mgv.setFee(base, quote, 501) {} catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/config/fee/<=500");
    }
  }

  function set_density_ceiling_test() public {
    try mgv.setDensity(base, quote, uint(type(uint112).max) + 1) {
      TestEvents.fail("density above ceiling should fail");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/config/density/112bits");
    }
  }

  function set_gasprice_ceiling_test() public {
    try mgv.setGasprice(uint(type(uint16).max) + 1) {
      TestEvents.fail("gasprice above ceiling should fail");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/config/gasprice/16bits");
    }
  }

  function set_zero_gasbase_test() public {
    try mgv.setGasbase(base, quote, 0) {} catch Error(string memory) {
      TestEvents.fail("setting gasbases to 0 should work");
    }
  }

  function set_gasbase_ceiling_test() public {
    try mgv.setGasbase(base, quote, uint(type(uint24).max) + 1) {
      TestEvents.fail("offer_gasbase above ceiling should fail");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/config/offer_gasbase/24bits");
    }
  }

  function set_gasmax_ceiling_test() public {
    try mgv.setGasmax(uint(type(uint24).max) + 1) {
      TestEvents.fail("gasmax above ceiling should fail");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/config/gasmax/24bits");
    }
  }

  function makerWants_wider_than_96_bits_fails_newOffer_test() public {
    try mkr.newOffer(2**96, 1 ether, 10_000, 0) {
      TestEvents.fail("Too wide offer should not be inserted");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/writeOffer/wants/96bits", "wrong revert reason");
    }
  }

  function retractOffer_wrong_owner_fails_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 10_000, 0);
    try mgv.retractOffer(base, quote, ofr, false) {
      TestEvents.fail("Too wide offer should not be inserted");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/retractOffer/unauthorized", "wrong revert reason");
    }
  }

  function makerGives_wider_than_96_bits_fails_newOffer_test() public {
    try mkr.newOffer(1, 2**96, 10_000, 0) {
      TestEvents.fail("Too wide offer should not be inserted");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/writeOffer/gives/96bits", "wrong revert reason");
    }
  }

  function makerGasreq_wider_than_24_bits_fails_newOffer_test() public {
    try mkr.newOffer(1, 1, 2**24, 0) {
      TestEvents.fail("Too wide offer should not be inserted");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/writeOffer/gasreq/tooHigh", "wrong revert reason");
    }
  }

  function makerGasreq_bigger_than_gasmax_fails_newOffer_test() public {
    (P.Global.t cfg, ) = mgv.config(base, quote);
    try mkr.newOffer(1, 1, cfg.gasmax() + 1, 0) {
      TestEvents.fail("Offer should not be inserted");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/writeOffer/gasreq/tooHigh", "wrong revert reason");
    }
  }

  function makerGasreq_at_gasmax_succeeds_newOffer_test() public {
    (P.Global.t cfg, ) = mgv.config(base, quote);
    try
      mkr.newOffer(1 ether, 1 ether, cfg.gasmax(), 0)
    returns (uint ofr) {
      TestEvents.check(
        mgv.isLive(mgv.offers(base, quote, ofr)),
        "Offer should have been inserted"
      );
      // Logging tests
      TestEvents.expectFrom(address(mgv));
      emit OfferWrite(
        address(base),
        address(quote),
        address(mkr),
        1 ether, //base
        1 ether, //quote
        cfg.gasprice(), //gasprice
        cfg.gasmax(), //gasreq
        ofr, //ofrId
        0 // prev
      );
      emit Debit(
        address(mkr),
        TestUtils.getProvision(
          mgv,
          address(base),
          address(quote),
          cfg.gasmax(),
          0
        )
      );
    } catch {
      TestEvents.fail("Offer at gasmax should pass");
    }
  }

  function makerGasreq_lower_than_density_fails_newOffer_test() public {
    (, P.Local.t cfg) = mgv.config(base, quote);
    uint amount = (1 + cfg.offer_gasbase()) *
      cfg.density();
    try mkr.newOffer(amount - 1, amount - 1, 1, 0) {
      TestEvents.fail("Offer should not be inserted");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/writeOffer/density/tooLow", "wrong revert reason");
    }
  }

  function makerGasreq_at_density_suceeds_test() public {
    (P.Global.t glob, P.Local.t cfg) = mgv.config(base, quote);
    uint amount = (1 + cfg.offer_gasbase()) *
      cfg.density();
    try mkr.newOffer(amount, amount, 1, 0) returns (uint ofr) {
      TestEvents.check(
        mgv.isLive(mgv.offers(base, quote, ofr)),
        "Offer should have been inserted"
      );
      // Logging tests
      TestEvents.expectFrom(address(mgv));
      emit OfferWrite(
        address(base),
        address(quote),
        address(mkr),
        amount, //base
        amount, //quote
        glob.gasprice(), //gasprice
        1, //gasreq
        ofr, //ofrId
        0 // prev
      );
      emit Debit(
        address(mkr),
        TestUtils.getProvision(mgv, address(base), address(quote), 1, 0)
      );
    } catch {
      TestEvents.fail("Offer at density should pass");
    }
  }

  function makerGasprice_wider_than_16_bits_fails_newOffer_test() public {
    try mkr.newOffer(1, 1, 1, 2**16, 0) {
      TestEvents.fail("Too wide offer should not be inserted");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/writeOffer/gasprice/16bits", "wrong revert reason");
    }
  }

  function takerWants_wider_than_160_bits_fails_marketOrder_test() public {
    try tkr.marketOrder(2**160, 0) {
      TestEvents.fail("takerWants > 160bits, order should fail");
    } catch Error(string memory r) {
      TestEvents.eq(r, "mgv/mOrder/takerWants/160bits", "wrong revert reason");
    }
  }

  function takerWants_above_96bits_fails_snipes_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [
      ofr,
      uint(type(uint96).max) + 1,
      type(uint96).max,
      type(uint).max
    ];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.fail("Snipes with takerWants > 96bits should fail");
    } catch Error(string memory reason) {
      TestUtils.revertEq(reason, "mgv/snipes/takerWants/96bits");
    }
  }

  function takerGives_above_96bits_fails_snipes_test() public {
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [
      ofr,
      type(uint96).max,
      uint(type(uint96).max) + 1,
      type(uint).max
    ];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.fail("Snipes with takerGives > 96bits should fail");
    } catch Error(string memory reason) {
      TestUtils.revertEq(reason, "mgv/snipes/takerGives/96bits");
    }
  }

  function initial_allowance_is_zero_test() public {
    TestEvents.eq(
      mgv.allowances(base, quote, address(tkr), address(this)),
      0,
      "initial allowance should be 0"
    );
  }

  function cannot_snipesFor_for_without_allowance_test() public {
    TestToken(base).mint(address(mkr), 1 ether);
    mkr.approveMgv(TestToken(base), 1 ether);
    uint ofr = mkr.newOffer(1 ether, 1 ether, 100_000, 0);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 300_000];
    try mgv.snipesFor(base, quote, targets, true, address(tkr)) {
      TestEvents.fail("snipeFor should fail without allowance");
    } catch Error(string memory reason) {
      TestUtils.revertEq(reason, "mgv/lowAllowance");
    }
  }

  function cannot_marketOrderFor_for_without_allowance_test() public {
    TestToken(base).mint(address(mkr), 1 ether);
    mkr.approveMgv(TestToken(base), 1 ether);
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    try mgv.marketOrderFor(base, quote, 1 ether, 1 ether, true, address(tkr)) {
      TestEvents.fail("marketOrderfor should fail without allowance");
    } catch Error(string memory reason) {
      TestUtils.revertEq(reason, "mgv/lowAllowance");
    }
  }

  function can_marketOrderFor_for_with_allowance_test() public {
    TestToken(base).mint(address(mkr), 1 ether);
    mkr.approveMgv(TestToken(base), 1 ether);
    mkr.newOffer(1 ether, 1 ether, 100_000, 0);
    tkr.approveSpender(address(this), 1.2 ether);
    uint takerGot;
    (takerGot, , ) = mgv.marketOrderFor(
      base,
      quote,
      1 ether,
      1 ether,
      true,
      address(tkr)
    );
    TestEvents.eq(
      mgv.allowances(base, quote, address(tkr), address(this)),
      0.2 ether,
      "allowance should have correctly reduced"
    );
  }

  /* # Internal IMaker setup */

  bytes trade_cb;
  bytes posthook_cb;

  // maker's trade fn for the mgv
  function makerExecute(ML.SingleOrder calldata)
    external
    override
    returns (bytes32 ret)
  {
    ret; // silence unused function parameter
    bool success;
    if (trade_cb.length > 0) {
      (success, ) = address(this).call(trade_cb);
      require(success, "makerExecute callback must work");
    }
    return "";
  }

  function makerPosthook(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) external override {
    bool success;
    order; // silence compiler warning
    if (posthook_cb.length > 0) {
      (success, ) = address(this).call(posthook_cb);
      bool tradeResult = (result.mgvData == "mgv/tradeSuccess");
      require(success == tradeResult, "makerPosthook callback must work");
    }
  }

  /* # Reentrancy */

  /* New Offer failure */

  function newOfferKO() external {
    try mgv.newOffer(base, quote, 1 ether, 1 ether, 30_000, 0, 0) {
      TestEvents.fail("newOffer on same pair should fail");
    } catch Error(string memory reason) {
      TestUtils.revertEq(reason, "mgv/reentrancyLocked");
    }
  }

  function newOffer_on_reentrancy_fails_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 100_000, 0, 0);
    trade_cb = abi.encodeWithSelector(this.newOfferKO.selector);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
  }

  /* New Offer success */

  // ! may be called with inverted _base and _quote
  function newOfferOK(address _base, address _quote) external {
    mgv.newOffer(_base, _quote, 1 ether, 1 ether, 30_000, 0, 0);
  }

  function newOffer_on_reentrancy_succeeds_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 200_000, 0, 0);
    trade_cb = abi.encodeWithSelector(this.newOfferOK.selector, quote, base);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
    require(mgv.best(quote, base) == 1, "newOffer on swapped pair must work");
  }

  function newOffer_on_posthook_succeeds_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 200_000, 0, 0);
    posthook_cb = abi.encodeWithSelector(this.newOfferOK.selector, base, quote);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
    require(mgv.best(base, quote) == 2, "newOffer on posthook must work");
  }

  /* Update offer failure */

  function updateOfferKO(uint ofr) external {
    try mgv.updateOffer(base, quote, 1 ether, 2 ether, 35_000, 0, 0, ofr) {
      TestEvents.fail("update offer on same pair should fail");
    } catch Error(string memory reason) {
      TestUtils.revertEq(reason, "mgv/reentrancyLocked");
    }
  }

  function updateOffer_on_reentrancy_fails_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 100_000, 0, 0);
    trade_cb = abi.encodeWithSelector(this.updateOfferKO.selector, ofr);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
  }

  /* Update offer success */

  // ! may be called with inverted _base and _quote
  function updateOfferOK(
    address _base,
    address _quote,
    uint ofr
  ) external {
    mgv.updateOffer(_base, _quote, 1 ether, 2 ether, 35_000, 0, 0, ofr);
  }

  function updateOffer_on_reentrancy_succeeds_test() public {
    uint other_ofr = mgv.newOffer(quote, base, 1 ether, 1 ether, 100_000, 0, 0);

    trade_cb = abi.encodeWithSelector(
      this.updateOfferOK.selector,
      quote,
      base,
      other_ofr
    );
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 400_000, 0, 0);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
    (, P.OfferDetailStruct memory od) = mgv.offerInfo(quote, base, other_ofr);
    require(od.gasreq == 35_000, "updateOffer on swapped pair must work");
  }

  function updateOffer_on_posthook_succeeds_test() public {
    uint other_ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 100_000, 0, 0);
    posthook_cb = abi.encodeWithSelector(
      this.updateOfferOK.selector,
      base,
      quote,
      other_ofr
    );
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 300_000, 0, 0);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
    (, P.OfferDetailStruct memory od) = mgv.offerInfo(base, quote, other_ofr);
    require(od.gasreq == 35_000, "updateOffer on posthook must work");
  }

  /* Cancel Offer failure */

  function retractOfferKO(uint id) external {
    try mgv.retractOffer(base, quote, id, false) {
      TestEvents.fail("retractOffer on same pair should fail");
    } catch Error(string memory reason) {
      TestUtils.revertEq(reason, "mgv/reentrancyLocked");
    }
  }

  function retractOffer_on_reentrancy_fails_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 100_000, 0, 0);
    trade_cb = abi.encodeWithSelector(this.retractOfferKO.selector, ofr);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
  }

  /* Cancel Offer success */

  function retractOfferOK(
    address _base,
    address _quote,
    uint id
  ) external {
    uint collected = mgv.retractOffer(_base, _quote, id, false);
    TestEvents.eq(
      collected,
      0,
      "Unexpected collected provision after retract w/o deprovision"
    );
  }

  function retractOffer_on_reentrancy_succeeds_test() public {
    uint other_ofr = mgv.newOffer(quote, base, 1 ether, 1 ether, 90_000, 0, 0);
    trade_cb = abi.encodeWithSelector(
      this.retractOfferOK.selector,
      quote,
      base,
      other_ofr
    );

    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 90_000, 0, 0);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
    require(
      mgv.best(quote, base) == 0,
      "retractOffer on swapped pair must work"
    );
  }

  function retractOffer_on_posthook_succeeds_test() public {
    uint other_ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 190_000, 0, 0);
    posthook_cb = abi.encodeWithSelector(
      this.retractOfferOK.selector,
      base,
      quote,
      other_ofr
    );

    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 90_000, 0, 0);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
    require(mgv.best(base, quote) == 0, "retractOffer on posthook must work");
  }

  /* Market Order failure */

  function marketOrderKO() external {
    try mgv.marketOrder(base, quote, 0.2 ether, 0.2 ether, true) {
      TestEvents.fail("marketOrder on same pair should fail");
    } catch Error(string memory reason) {
      TestUtils.revertEq(reason, "mgv/reentrancyLocked");
    }
  }

  function marketOrder_on_reentrancy_fails_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 100_000, 0, 0);
    trade_cb = abi.encodeWithSelector(this.marketOrderKO.selector);
    require(tkr.take(ofr, 0.1 ether), "take must succeed or test is void");
  }

  /* Market Order Success */

  function marketOrderOK(address _base, address _quote) external {
    try
      mgv.marketOrder(_base, _quote, 0.5 ether, 0.5 ether, true)
    {} catch Error(string memory r) {
      console.log("ERR", r);
    }
  }

  function marketOrder_on_reentrancy_succeeds_test() public {
    console.log(
      "dual mkr offer",
      dual_mkr.newOffer(0.5 ether, 0.5 ether, 30_000, 0)
    );
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 392_000, 0, 0);
    console.log("normal offer", ofr);
    trade_cb = abi.encodeWithSelector(this.marketOrderOK.selector, quote, base);
    require(tkr.take(ofr, 0.1 ether), "take must succeed or test is void");
    require(
      mgv.best(quote, base) == 0,
      "2nd market order must have emptied mgv"
    );
  }

  function marketOrder_on_posthook_succeeds_test() public {
    uint ofr = mgv.newOffer(base, quote, 0.5 ether, 0.5 ether, 500_000, 0, 0);
    mgv.newOffer(base, quote, 0.5 ether, 0.5 ether, 200_000, 0, 0);
    posthook_cb = abi.encodeWithSelector(
      this.marketOrderOK.selector,
      base,
      quote
    );
    require(tkr.take(ofr, 0.6 ether), "take must succeed or test is void");
    require(
      mgv.best(base, quote) == 0,
      "2nd market order must have emptied mgv"
    );
  }

  /* Snipe failure */

  function snipesKO(uint id) external {
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [id, 1 ether, type(uint96).max, type(uint48).max];
    try mgv.snipes(base, quote, targets, true) {
      TestEvents.fail("snipe on same pair should fail");
    } catch Error(string memory reason) {
      TestUtils.revertEq(reason, "mgv/reentrancyLocked");
    }
  }

  function snipe_on_reentrancy_fails_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 60_000, 0, 0);
    trade_cb = abi.encodeWithSelector(this.snipesKO.selector, ofr);
    require(tkr.take(ofr, 0.1 ether), "take must succeed or test is void");
  }

  /* Snipe success */

  function snipesOK(
    address _base,
    address _quote,
    uint id
  ) external {
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [id, 1 ether, type(uint96).max, type(uint48).max];
    mgv.snipes(_base, _quote, targets, true);
  }

  function snipes_on_reentrancy_succeeds_test() public {
    uint other_ofr = dual_mkr.newOffer(1 ether, 1 ether, 30_000, 0);
    trade_cb = abi.encodeWithSelector(
      this.snipesOK.selector,
      quote,
      base,
      other_ofr
    );

    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 190_000, 0, 0);
    require(tkr.take(ofr, 0.1 ether), "take must succeed or test is void");
    require(mgv.best(quote, base) == 0, "snipe in swapped pair must work");
  }

  function snipes_on_posthook_succeeds_test() public {
    uint other_ofr = mkr.newOffer(1 ether, 1 ether, 30_000, 0);
    posthook_cb = abi.encodeWithSelector(
      this.snipesOK.selector,
      base,
      quote,
      other_ofr
    );

    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 190_000, 0, 0);
    require(tkr.take(ofr, 1 ether), "take must succeed or test is void");
    require(mgv.best(base, quote) == 0, "snipe in posthook must work");
  }

  function newOffer_on_closed_fails_test() public {
    mgv.kill();
    try mgv.newOffer(base, quote, 1 ether, 1 ether, 0, 0, 0) {
      TestEvents.fail("newOffer should fail on closed market");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/dead");
    }
  }

  /* # Mangrove closed/inactive */

  function take_on_closed_fails_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 0, 0, 0);

    mgv.kill();
    try tkr.take(ofr, 1 ether) {
      TestEvents.fail("take offer should fail on closed market");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/dead");
    }
  }

  function newOffer_on_inactive_fails_test() public {
    mgv.deactivate(base, quote);
    try mgv.newOffer(base, quote, 1 ether, 1 ether, 0, 0, 0) {
      TestEvents.fail("newOffer should fail on closed market");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/inactive");
    }
  }

  function receive_on_closed_fails_test() public {
    mgv.kill();

    (bool success, bytes memory retdata) = address(mgv).call{value: 10 ether}(
      ""
    );
    if (success) {
      TestEvents.fail("receive() should fail on closed market");
    } else {
      string memory r = TestUtils.getReason(retdata);
      TestUtils.revertEq(r, "mgv/dead");
    }
  }

  function marketOrder_on_closed_fails_test() public {
    mgv.kill();
    try tkr.marketOrder(1 ether, 1 ether) {
      TestEvents.fail("marketOrder should fail on closed market");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/dead");
    }
  }

  function snipe_on_closed_fails_test() public {
    mgv.kill();
    try tkr.take(0, 1 ether) {
      TestEvents.fail("snipe should fail on closed market");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/dead");
    }
  }

  function withdraw_on_closed_ok_test() public {
    mgv.kill();
    mgv.withdraw(0.1 ether);
  }

  function retractOffer_on_closed_ok_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 0, 0, 0);
    mgv.kill();
    mgv.retractOffer(base, quote, ofr, false);
  }

  function updateOffer_on_closed_fails_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 0, 0, 0);
    mgv.kill();
    try mgv.updateOffer(base, quote, 1 ether, 1 ether, 0, 0, 0, ofr) {
      TestEvents.fail("update offer should fail on closed market");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/dead");
    }
  }

  function activation_emits_events_in_order_test() public {
    mgv.activate(quote, base, 7, 0, 3);
    TestEvents.expectFrom(address(mgv));
    emit SetActive(quote, base, true);
    emit SetFee(quote, base, 7);
    emit SetDensity(quote, base, 0);
    emit SetGasbase(quote, base, 3);
  }

  function updateOffer_on_inactive_fails_test() public {
    uint ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, 0, 0, 0);
    mgv.deactivate(base, quote);
    try mgv.updateOffer(base, quote, 1 ether, 1 ether, 0, 0, 0, ofr) {
      TestEvents.fail("update offer should fail on inactive market");
    } catch Error(string memory r) {
      TestUtils.revertEq(r, "mgv/inactive");
      TestEvents.expectFrom(address(mgv));
      emit SetActive(base, quote, false);
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "../AbstractMangrove.sol";
import "../MgvLib.sol";
import "hardhat/console.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";
import "./Agents/TestMoriartyMaker.sol";
import "./Agents/MakerDeployer.sol";
import "./Agents/TestTaker.sol";

// In these tests, the testing contract is the market maker.
contract Gas_Test is IMaker {
  receive() external payable {}

  AbstractMangrove _mgv;
  TestTaker _tkr;
  address _base;
  address _quote;

  function a_beforeAll() public {
    TestToken baseT = TokenSetup.setup("A", "$A");
    TestToken quoteT = TokenSetup.setup("B", "$B");
    _base = address(baseT);
    _quote = address(quoteT);
    _mgv = MgvSetup.setup(baseT, quoteT);

    bool noRevert;
    (noRevert, ) = address(_mgv).call{value: 10 ether}("");

    baseT.mint(address(this), 2 ether);
    baseT.approve(address(_mgv), 2 ether);
    quoteT.approve(address(_mgv), 1 ether);

    Display.register(msg.sender, "Test Runner");
    Display.register(address(this), "Gatekeeping_Test/maker");
    Display.register(_base, "$A");
    Display.register(_quote, "$B");
    Display.register(address(_mgv), "mgv");

    _mgv.newOffer(_base, _quote, 1 ether, 1 ether, 100_000, 0, 0);
    console.log("mgv", address(_mgv));

    _tkr = TakerSetup.setup(_mgv, _base, _quote);
    quoteT.mint(address(_tkr), 2 ether);
    _tkr.approveMgv(quoteT, 2 ether);
    Display.register(address(_tkr), "Taker");

    /* set lock to 1 to avoid spurious 15k gas cost */
    uint ofr = _mgv.newOffer(
      _base,
      _quote,
      0.1 ether,
      0.1 ether,
      100_000,
      0,
      0
    );
    _tkr.take(ofr, 0.1 ether);
  }

  function getStored()
    internal
    view
    returns (
      AbstractMangrove,
      TestTaker,
      address,
      address
    )
  {
    return (_mgv, _tkr, _base, _quote);
  }

  function makerExecute(ML.SingleOrder calldata)
    external
    pure
    override
    returns (bytes32)
  {
    return ""; // silence unused function parameter
  }

  function makerPosthook(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) external override {}

  function update_min_move_0_offer_test() public {
    (AbstractMangrove mgv, , address base, address quote) = getStored();
    uint g = gasleft();
    mgv.updateOffer(base, quote, 1 ether, 1 ether, 100_000, 0, 1, 1);
    console.log("Gas used", g - gasleft());
  }

  function update_full_offer_test() public {
    (AbstractMangrove mgv, , address base, address quote) = getStored();
    uint g = gasleft();
    mgv.updateOffer(base, quote, 0.5 ether, 1 ether, 100_001, 0, 1, 1);
    console.log("Gas used", g - gasleft());
  }

  function update_min_move_3_offer_before() public {
    (AbstractMangrove mgv, , address base, address quote) = getStored();
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
  }

  function update_min_move_3_offer_test() public {
    (AbstractMangrove mgv, , address base, address quote) = getStored();
    uint g = gasleft();
    mgv.updateOffer(base, quote, 1.0 ether, 0.1 ether, 100_00, 0, 1, 1);
    console.log("Gas used", g - gasleft());
  }

  function update_min_move_6_offer_before() public {
    (AbstractMangrove mgv, , address base, address quote) = getStored();
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
  }

  function update_min_move_6_offer_test() public {
    (AbstractMangrove mgv, , address base, address quote) = getStored();
    uint g = gasleft();
    mgv.updateOffer(base, quote, 1.0 ether, 0.1 ether, 100_00, 0, 1, 1);
    console.log("Gas used", g - gasleft());
  }

  function new_offer_test() public {
    (AbstractMangrove mgv, , address base, address quote) = getStored();
    uint g = gasleft();
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 1);
    console.log("Gas used", g - gasleft());
  }

  function take_offer_test() public {
    (
      AbstractMangrove mgv,
      TestTaker tkr,
      address base,
      address quote
    ) = getStored();
    uint g = gasleft();
    tkr.snipe(mgv, base, quote, 1, 1 ether, 1 ether, 100_000);
    console.log("Gas used", g - gasleft());
  }

  function partial_take_offer_test() public {
    (
      AbstractMangrove mgv,
      TestTaker tkr,
      address base,
      address quote
    ) = getStored();
    uint g = gasleft();
    tkr.snipe(mgv, base, quote, 1, 0.5 ether, 0.5 ether, 100_000);
    console.log("Gas used", g - gasleft());
  }

  function market_order_1_test() public {
    (
      AbstractMangrove mgv,
      TestTaker tkr,
      address base,
      address quote
    ) = getStored();
    uint g = gasleft();
    tkr.marketOrder(mgv, base, quote, 1 ether, 1 ether);
    console.log("Gas used", g - gasleft());
  }

  function market_order_8_before() public {
    (AbstractMangrove mgv, , address base, address quote) = getStored();
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
    mgv.newOffer(base, quote, 0.1 ether, 0.1 ether, 100_000, 0, 0);
  }

  function market_order_8_test() public {
    (
      AbstractMangrove mgv,
      TestTaker tkr,
      address base,
      address quote
    ) = getStored();
    uint g = gasleft();
    tkr.marketOrder(mgv, base, quote, 2 ether, 2 ether);
    console.log("Gas used", g - gasleft());
  }
}

// SPDX-License-Identifier:	AGPL-3.0

pragma solidity ^0.8.10;
pragma abicoder v2;

import "../AbstractMangrove.sol";
import {IMaker as IM, MgvLib} from "../MgvLib.sol";
import "hardhat/console.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";
import "./Agents/TestMaker.sol";

/* The following constructs an ERC20 with a transferFrom callback method,
   and a TestTaker which throws away any funds received upon getting
   a callback.
*/
contract InvertedTakerOperations_Test is ITaker, HasMgvEvents {
  TestToken baseT;
  TestToken quoteT;
  address base;
  address quote;
  AbstractMangrove mgv;
  TestMaker mkr;
  bytes4 takerTrade_bytes;
  uint baseBalance;
  uint quoteBalance;

  receive() external payable {}

  function a_beforeAll() public {
    baseT = TokenSetup.setup("A", "$A");
    quoteT = TokenSetup.setup("B", "$B");
    base = address(baseT);
    quote = address(quoteT);
    mgv = MgvSetup.setup(baseT, quoteT, true);

    mkr = MakerSetup.setup(mgv, base, quote);

    payable(mkr).transfer(10 ether);
    mkr.provisionMgv(1 ether);
    mkr.approveMgv(baseT, 10 ether);

    baseT.mint(address(mkr), 5 ether);
    quoteT.mint(address(this), 5 ether);
    quoteT.approve(address(mgv), 5 ether);
    baseBalance = baseT.balanceOf(address(this));
    quoteBalance = quoteT.balanceOf(address(this));

    Display.register(msg.sender, "Test Runner");
    Display.register(base, "$A");
    Display.register(quote, "$B");
    Display.register(address(mgv), "mgv");
    Display.register(address(mkr), "maker");
    Display.register(mgv.vault(), "vault");
  }

  uint toPay;

  function checkPay(
    address,
    address,
    uint totalGives
  ) external {
    TestEvents.eq(
      toPay,
      totalGives,
      "totalGives should be the sum of taker flashborrows"
    );
  }

  bool skipCheck;

  function takerTrade(
    address _base,
    address _quote,
    uint totalGot,
    uint totalGives
  ) public override {
    require(msg.sender == address(mgv));
    if (!skipCheck) {
      TestEvents.eq(
        baseBalance + totalGot,
        baseT.balanceOf(address(this)),
        "totalGot should be sum of maker flashloans"
      );
    }
    (bool success, ) = address(this).call(
      abi.encodeWithSelector(takerTrade_bytes, _base, _quote, totalGives)
    );
    require(success, "TradeFail");
  }

  function taker_gets_sum_of_borrows_in_execute_test() public {
    mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    takerTrade_bytes = this.checkPay.selector;
    toPay = 0.2 ether;
    (, uint gave, ) = mgv.marketOrder(base, quote, 0.2 ether, 0.2 ether, true);
    TestEvents.eq(
      quoteBalance - gave,
      quoteT.balanceOf(address(this)),
      "totalGave should be sum of taker flashborrows"
    );
  }

  function revertTrade(
    address,
    address,
    uint
  ) external pure {
    require(false);
  }

  function taker_reverts_during_trade_test() public {
    uint ofr = mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    uint _ofr = mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    takerTrade_bytes = this.revertTrade.selector;
    skipCheck = true;
    try mgv.marketOrder(base, quote, 0.2 ether, 0.2 ether, true) {
      TestEvents.fail("Market order should have reverted");
    } catch Error(string memory reason) {
      TestEvents.eq("TradeFail", reason, "Unexpected throw");
      TestEvents.check(
        TestUtils.hasOffer(mgv, address(base), address(quote), ofr),
        "Offer 1 should be present"
      );
      TestEvents.check(
        TestUtils.hasOffer(mgv, address(base), address(quote), _ofr),
        "Offer 2 should be present"
      );
    }
  }

  function refuseFeeTrade(
    address _base,
    address,
    uint
  ) external {
    IERC20(_base).approve(address(mgv), 0);
  }

  function refusePayTrade(
    address,
    address _quote,
    uint
  ) external {
    IERC20(_quote).approve(address(mgv), 0);
  }

  function taker_refuses_to_deliver_during_trade_test() public {
    mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    takerTrade_bytes = this.refusePayTrade.selector;
    try mgv.marketOrder(base, quote, 0.2 ether, 0.2 ether, true) {
      TestEvents.fail("Market order should have reverted");
    } catch Error(string memory reason) {
      TestEvents.eq(
        reason,
        "mgv/takerFailToPayTotal",
        "Unexpected throw message"
      );
    }
  }

  function vault_receives_quote_tokens_if_maker_is_blacklisted_for_quote_test()
    public
  {
    takerTrade_bytes = this.noop.selector;
    quoteT.blacklists(address(mkr));
    uint ofr = mkr.newOffer(1 ether, 1 ether, 50_000, 0);
    address vault = address(1);
    mgv.setVault(vault);
    uint vaultBal = quoteT.balanceOf(vault);

    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 1 ether, 1 ether, 50_000];

    (uint successes, , , ) = mgv.snipes(base, quote, targets, true);
    TestEvents.check(successes == 1, "Trade should succeed");
    TestEvents.eq(
      quoteT.balanceOf(vault) - vaultBal,
      1 ether,
      "Vault balance should have increased"
    );
  }

  function noop(
    address,
    address,
    uint
  ) external {}

  function reenter(
    address _base,
    address _quote,
    uint
  ) external {
    takerTrade_bytes = this.noop.selector;
    skipCheck = true;
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [uint(2), 0.1 ether, 0.1 ether, 100_000];
    (uint successes, uint totalGot, uint totalGave, ) = mgv.snipes(
      _base,
      _quote,
      targets,
      true
    );
    TestEvents.check(successes == 1, "Snipe on reentrancy should succeed");
    TestEvents.eq(totalGot, 0.1 ether, "Incorrect totalGot");
    TestEvents.eq(totalGave, 0.1 ether, "Incorrect totalGave");
  }

  function taker_snipe_mgv_during_trade_test() public {
    mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    takerTrade_bytes = this.reenter.selector;
    (uint got, uint gave, ) = mgv.marketOrder(
      base,
      quote,
      0.1 ether,
      0.1 ether,
      true
    );
    TestEvents.eq(
      quoteBalance - gave - 0.1 ether,
      quoteT.balanceOf(address(this)),
      "Incorrect transfer (gave) during reentrancy"
    );
    TestEvents.eq(
      baseBalance + got + 0.1 ether,
      baseT.balanceOf(address(this)),
      "Incorrect transfer (got) during reentrancy"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferSuccess(base, quote, 1, address(this), 0.1 ether, 0.1 ether);
    emit OfferSuccess(base, quote, 2, address(this), 0.1 ether, 0.1 ether);
  }

  function taker_pays_back_correct_amount_1_test() public {
    uint ofr = mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    uint bal = quoteT.balanceOf(address(this));
    takerTrade_bytes = this.noop.selector;
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0.05 ether, 0.05 ether, 100_000];
    mgv.snipes(base, quote, targets, true);
    TestEvents.eq(
      quoteT.balanceOf(address(this)),
      bal - 0.05 ether,
      "wrong taker balance"
    );
  }

  function taker_pays_back_correct_amount_2_test() public {
    uint ofr = mkr.newOffer(0.1 ether, 0.1 ether, 100_000, 0);
    uint bal = quoteT.balanceOf(address(this));
    takerTrade_bytes = this.noop.selector;
    uint[4][] memory targets = new uint[4][](1);
    targets[0] = [ofr, 0.02 ether, 0.02 ether, 100_000];
    mgv.snipes(base, quote, targets, true);
    TestEvents.eq(
      quoteT.balanceOf(address(this)),
      bal - 0.02 ether,
      "wrong taker balance"
    );
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "../AbstractMangrove.sol";
import "../MgvLib.sol";
import "hardhat/console.sol";

import "./Toolbox/TestUtils.sol";

import "./Agents/TestToken.sol";

contract MakerPosthook_Test is IMaker, HasMgvEvents {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;

  AbstractMangrove mgv;
  TestTaker tkr;
  TestToken baseT;
  TestToken quoteT;
  address base;
  address quote;
  uint gasreq = 200_000;
  uint ofr;
  bytes4 posthook_bytes;
  uint _gasprice = 50; // will cover for a gasprice of 50 gwei/gas uint
  uint weiBalMaker;
  bool abort = false;
  bool willFail = false;
  bool makerRevert = false;
  bool called;

  event Execute(
    address mgv,
    address base,
    address quote,
    uint offerId,
    uint takerWants,
    uint takerGives
  );

  receive() external payable {}

  function tradeRevert(bytes32 data) internal pure {
    bytes memory revData = new bytes(32);
    assembly {
      mstore(add(revData, 32), data)
      revert(add(revData, 32), 32)
    }
  }

  function makerExecute(MgvLib.SingleOrder calldata trade)
    external
    override
    returns (bytes32)
  {
    require(msg.sender == address(mgv));
    if (makerRevert) {
      tradeRevert("NOK");
    }
    if (abort) {
      return "NOK";
    }
    emit Execute(
      msg.sender,
      trade.outbound_tkn,
      trade.inbound_tkn,
      trade.offerId,
      trade.wants,
      trade.gives
    );
    //MakerTrade.returnWithData("OK");
    return "";
  }

  function renew_offer_at_posthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata
  ) external {
    require(msg.sender == address(this));
    called = true;
    mgv.updateOffer(
      order.outbound_tkn,
      order.inbound_tkn,
      1 ether,
      1 ether,
      gasreq,
      _gasprice,
      order.offerId,
      order.offerId
    );
  }

  function update_gas_offer_at_posthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata
  ) external {
    require(msg.sender == address(this));
    called = true;
    mgv.updateOffer(
      order.outbound_tkn,
      order.inbound_tkn,
      1 ether,
      1 ether,
      gasreq,
      _gasprice,
      order.offerId,
      order.offerId
    );
  }

  function failer_posthook(
    MgvLib.SingleOrder calldata,
    MgvLib.OrderResult calldata
  ) external {
    require(msg.sender == address(this));
    called = true;
    TestEvents.fail("Posthook should not be called");
  }

  function retractOffer_posthook(
    MgvLib.SingleOrder calldata,
    MgvLib.OrderResult calldata
  ) external {
    require(msg.sender == address(this));
    called = true;
    uint bal = mgv.balanceOf(address(this));
    mgv.retractOffer(base, quote, ofr, true);
    if (abort) {
      TestEvents.eq(
        bal,
        mgv.balanceOf(address(this)),
        "Cancel offer of a failed offer should not give provision to maker"
      );
    }
  }

  function makerPosthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata result
  ) external override {
    require(msg.sender == address(mgv));
    bool success = (result.mgvData == "mgv/tradeSuccess");
    TestEvents.eq(
      success,
      !(abort || makerRevert || willFail),
      "incorrect success flag"
    );
    if (makerRevert) {
      TestEvents.eq(
        result.mgvData,
        "mgv/makerRevert",
        "mgvData should be makerRevert"
      );
    } else if (abort) {
      TestEvents.eq(
        result.mgvData,
        "mgv/makerAbort",
        "mgvData should be makerAbort"
      );
    } else {
      TestEvents.eq(
        result.mgvData,
        bytes32("mgv/tradeSuccess"),
        "mgvData should be tradeSuccess"
      );
    }
    TestEvents.check(
      !TestUtils.hasOffer(
        mgv,
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId
      ),
      "Offer was not removed after take"
    );
    bool noRevert;
    (noRevert, ) = address(this).call(
      abi.encodeWithSelector(posthook_bytes, order, result)
    );
  }

  function a_beforeAll() public {
    Display.register(address(this), "Test runner");

    baseT = TokenSetup.setup("A", "$A");
    quoteT = TokenSetup.setup("B", "$B");
    base = address(baseT);
    quote = address(quoteT);
    Display.register(base, "base");
    Display.register(quote, "quote");

    mgv = MgvSetup.setup(baseT, quoteT);
    Display.register(address(mgv), "Mgv");

    tkr = TakerSetup.setup(mgv, base, quote);
    Display.register(address(tkr), "Taker");

    baseT.approve(address(mgv), 10 ether);

    payable(tkr).transfer(10 ether);
    quoteT.mint(address(tkr), 1 ether);
    baseT.mint(address(this), 5 ether);

    tkr.approveMgv(baseT, 1 ether); // takerFee
    tkr.approveMgv(quoteT, 1 ether);

    mgv.fund{value: 10 ether}(address(this)); // for new offer and further updates
    weiBalMaker = mgv.balanceOf(address(this));
  }

  function renew_offer_after_partial_fill_test() public {
    uint mkr_provision = TestUtils.getProvision(
      mgv,
      base,
      quote,
      gasreq,
      _gasprice
    );
    posthook_bytes = this.renew_offer_at_posthook.selector;

    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker - mkr_provision, // maker has provision for his gasprice
      "Incorrect maker balance before take"
    );

    bool success = tkr.take(ofr, 0.5 ether);
    TestEvents.check(success, "Snipe should succeed");
    TestEvents.check(called, "PostHook not called");

    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker - mkr_provision, // maker reposts
      "Incorrect maker balance after take"
    );
    TestEvents.eq(
      TestUtils.getOfferInfo(mgv, base, quote, TestUtils.Info.makerGives, ofr),
      1 ether,
      "Offer was not correctly updated"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferWrite(
      base,
      quote,
      address(this),
      1 ether,
      1 ether,
      _gasprice,
      gasreq,
      ofr,
      0
    );
  }

  function renew_offer_after_complete_fill_test() public {
    uint mkr_provision = TestUtils.getProvision(
      mgv,
      base,
      quote,
      gasreq,
      _gasprice
    );
    posthook_bytes = this.renew_offer_at_posthook.selector;

    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);

    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker - mkr_provision, // maker has provision for his gasprice
      "Incorrect maker balance before take"
    );

    bool success = tkr.take(ofr, 2 ether);
    TestEvents.check(called, "PostHook not called");
    TestEvents.check(success, "Snipe should succeed");

    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker - mkr_provision, // maker reposts
      "Incorrect maker balance after take"
    );
    TestEvents.eq(
      TestUtils.getOfferInfo(mgv, base, quote, TestUtils.Info.makerGives, ofr),
      1 ether,
      "Offer was not correctly updated"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferWrite(
      base,
      quote,
      address(this),
      1 ether,
      1 ether,
      _gasprice,
      gasreq,
      ofr,
      0
    );
  }

  function renew_offer_after_failed_execution_test() public {
    posthook_bytes = this.renew_offer_at_posthook.selector;

    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    abort = true;

    bool success = tkr.take(ofr, 2 ether);
    TestEvents.check(!success, "Snipe should fail");
    TestEvents.check(called, "PostHook not called");

    TestEvents.eq(
      TestUtils.getOfferInfo(mgv, base, quote, TestUtils.Info.makerGives, ofr),
      1 ether,
      "Offer was not correctly updated"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferWrite(
      base,
      quote,
      address(this),
      1 ether,
      1 ether,
      _gasprice,
      gasreq,
      ofr,
      0
    );
  }

  function treat_fail_at_posthook(
    MgvLib.SingleOrder calldata,
    MgvLib.OrderResult calldata res
  ) external {
    bool success = (res.mgvData == "mgv/tradeSuccess");
    TestEvents.check(!success, "Offer should be marked as failed");
    TestEvents.check(res.makerData == "NOK", "Incorrect maker data");
  }

  function failed_offer_is_not_executed_test() public {
    posthook_bytes = this.treat_fail_at_posthook.selector;
    uint balMaker = baseT.balanceOf(address(this));
    uint balTaker = quoteT.balanceOf(address(tkr));
    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    abort = true;

    bool success = tkr.take(ofr, 1 ether);
    TestEvents.check(!success, "Snipe should fail");
    TestEvents.eq(
      baseT.balanceOf(address(this)),
      balMaker,
      "Maker should not have been debited of her base tokens"
    );
    TestEvents.eq(
      quoteT.balanceOf(address(tkr)),
      balTaker,
      "Taker should not have been debited of her quote tokens"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferFail(
      base,
      quote,
      ofr,
      address(tkr),
      1 ether,
      1 ether,
      "mgv/makerAbort"
    );
  }

  function update_offer_with_more_gasprice_test() public {
    uint mkr_provision = TestUtils.getProvision(
      mgv,
      base,
      quote,
      gasreq,
      _gasprice
    );
    uint standard_provision = TestUtils.getProvision(mgv, base, quote, gasreq);
    posthook_bytes = this.update_gas_offer_at_posthook.selector;
    // provision for mgv.global.gasprice
    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, 0, 0);

    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker - standard_provision, // maker has provision for his gasprice
      "Incorrect maker balance before take"
    );

    bool success = tkr.take(ofr, 2 ether);
    TestEvents.check(success, "Snipe should succeed");
    TestEvents.check(called, "PostHook not called");

    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker - mkr_provision, // maker reposts
      "Incorrect maker balance after take"
    );
    TestEvents.eq(
      TestUtils.getOfferInfo(mgv, base, quote, TestUtils.Info.makerGives, ofr),
      1 ether,
      "Offer was not correctly updated"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferWrite(
      base,
      quote,
      address(this),
      1 ether,
      1 ether,
      _gasprice,
      gasreq,
      ofr,
      0
    );
  }

  function posthook_of_skipped_offer_wrong_gas_should_not_be_called_test()
    public
  {
    posthook_bytes = this.failer_posthook.selector;

    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);

    bool success = tkr.snipe(
      mgv,
      base,
      quote,
      ofr,
      1 ether,
      1 ether,
      gasreq - 1
    );
    TestEvents.check(!called, "PostHook was called");
    TestEvents.check(!success, "Snipe should fail");
  }

  function posthook_of_skipped_offer_wrong_price_should_not_be_called_test()
    public
  {
    posthook_bytes = this.failer_posthook.selector;
    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    bool success = tkr.snipe(mgv, base, quote, ofr, 1.1 ether, 1 ether, gasreq);
    TestEvents.check(!success, "Snipe should fail");
    TestEvents.check(!called, "PostHook was called");
  }

  function retract_offer_in_posthook_test() public {
    uint mkr_provision = TestUtils.getProvision(
      mgv,
      base,
      quote,
      gasreq,
      _gasprice
    );
    posthook_bytes = this.retractOffer_posthook.selector;
    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker - mkr_provision, // maker has provision for his gasprice
      "Incorrect maker balance before take"
    );
    bool success = tkr.take(ofr, 2 ether);
    TestEvents.check(success, "Snipe should succeed");
    TestEvents.check(called, "PostHook not called");

    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker, // provision returned to taker
      "Incorrect maker balance after take"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferSuccess(base, quote, ofr, address(tkr), 1 ether, 1 ether);
    emit Credit(address(this), mkr_provision);
    emit OfferRetract(base, quote, ofr);
  }

  function balance_after_fail_and_retract_test() public {
    uint mkr_provision = TestUtils.getProvision(
      mgv,
      base,
      quote,
      gasreq,
      _gasprice
    );
    uint tkr_weis = address(tkr).balance;
    posthook_bytes = this.retractOffer_posthook.selector;
    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker - mkr_provision, // maker has provision for his gasprice
      "Incorrect maker balance before take"
    );
    abort = true;
    bool success = tkr.take(ofr, 2 ether);
    TestEvents.check(!success, "Snipe should fail");
    uint penalty = weiBalMaker - mgv.balanceOf(address(this));
    TestEvents.eq(
      penalty,
      address(tkr).balance - tkr_weis,
      "Incorrect overall balance after penalty for taker"
    );
    TestEvents.expectFrom(address(mgv));
    emit OfferFail(
      base,
      quote,
      ofr,
      address(tkr),
      1 ether,
      1 ether,
      "mgv/makerAbort"
    );
    emit OfferRetract(base, quote, ofr);
    emit Credit(address(this), mkr_provision - penalty);
  }

  function update_offer_after_deprovision_in_posthook_succeeds_test() public {
    posthook_bytes = this.retractOffer_posthook.selector;
    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    bool success = tkr.take(ofr, 2 ether);
    TestEvents.check(called, "PostHook not called");

    TestEvents.check(success, "Snipe should succeed");
    mgv.updateOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0, ofr);
    TestEvents.expectFrom(address(mgv));
    emit OfferSuccess(base, quote, ofr, address(tkr), 1 ether, 1 ether);
    emit OfferRetract(base, quote, ofr);
  }

  function check_best_in_posthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata
  ) external {
    called = true;
    (, P.Local.t cfg) = mgv.config(order.outbound_tkn, order.inbound_tkn);
    TestEvents.eq(
      cfg.best(),
      ofr,
      "Incorrect best offer id in posthook"
    );
  }

  function best_in_posthook_is_correct_test() public {
    mgv.newOffer(base, quote, 2 ether, 1 ether, gasreq, _gasprice, 0);
    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    uint best = mgv.newOffer(
      base,
      quote,
      0.5 ether,
      1 ether,
      gasreq,
      _gasprice,
      0
    );
    posthook_bytes = this.check_best_in_posthook.selector;
    bool success = tkr.take(best, 1 ether);
    TestEvents.check(called, "PostHook not called");
    TestEvents.check(success, "Snipe should succeed");
  }

  function check_offer_in_posthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata
  ) external {
    called = true;
    uint __wants = order.offer.wants();
    uint __gives = order.offer.gives();
    address __maker = order.offerDetail.maker();
    uint __gasreq = order.offerDetail.gasreq();
    uint __gasprice = order.offerDetail.gasprice();
    TestEvents.eq(__wants, 1 ether, "Incorrect wants for offer in posthook");
    TestEvents.eq(__gives, 2 ether, "Incorrect gives for offer in posthook");
    TestEvents.eq(__gasprice, 500, "Incorrect gasprice for offer in posthook");
    TestEvents.eq(__maker, address(this), "Incorrect maker address");
    TestEvents.eq(__gasreq, gasreq, "Incorrect gasreq");
  }

  function check_offer_in_posthook_test() public {
    ofr = mgv.newOffer(base, quote, 1 ether, 2 ether, gasreq, 500, 0);
    posthook_bytes = this.check_offer_in_posthook.selector;
    bool success = tkr.take(ofr, 2 ether);
    TestEvents.check(called, "PostHook not called");
    TestEvents.check(success, "Snipe should succeed");
  }

  function check_lastId_in_posthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata
  ) external {
    called = true;
    (, P.Local.t cfg) = mgv.config(order.outbound_tkn, order.inbound_tkn);
    TestEvents.eq(
      cfg.last(),
      ofr,
      "Incorrect last offer id in posthook"
    );
  }

  function lastId_in_posthook_is_correct_test() public {
    mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    ofr = mgv.newOffer(base, quote, 0.5 ether, 1 ether, gasreq, _gasprice, 0);
    posthook_bytes = this.check_lastId_in_posthook.selector;
    bool success = tkr.take(ofr, 1 ether);
    TestEvents.check(called, "PostHook not called");
    TestEvents.check(success, "Snipe should succeed");
  }

  function retract_offer_after_fail_in_posthook_test() public {
    uint mkr_provision = TestUtils.getProvision(
      mgv,
      base,
      quote,
      gasreq,
      _gasprice
    );
    posthook_bytes = this.retractOffer_posthook.selector;
    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    TestEvents.eq(
      mgv.balanceOf(address(this)),
      weiBalMaker - mkr_provision, // maker has provision for his gasprice
      "Incorrect maker balance before take"
    );
    abort = true; // maker should fail
    bool success = tkr.take(ofr, 2 ether);
    TestEvents.check(called, "PostHook not called");

    TestEvents.check(!success, "Snipe should fail");

    TestEvents.less(
      mgv.balanceOf(address(this)),
      weiBalMaker,
      "Maker balance after take should be less than original balance"
    );
    uint refund = mgv.balanceOf(address(this)) + mkr_provision - weiBalMaker;
    TestEvents.expectFrom(address(mgv));
    emit OfferFail(
      base,
      quote,
      ofr,
      address(tkr),
      1 ether,
      1 ether,
      "mgv/makerAbort"
    );
    emit OfferRetract(base, quote, ofr);
    emit Credit(address(this), refund);
  }

  function makerRevert_is_logged_test() public {
    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    makerRevert = true; // maker should fail
    bool success;
    success = tkr.take(ofr, 2 ether);
    TestEvents.expectFrom(address(mgv));
    emit OfferFail(
      base,
      quote,
      ofr,
      address(tkr),
      1 ether,
      1 ether,
      "mgv/makerRevert"
    );
  }

  function reverting_posthook(
    MgvLib.SingleOrder calldata,
    MgvLib.OrderResult calldata
  ) external pure {
    assert(false);
  }

  function reverting_posthook_does_not_revert_offer_test() public {
    TestUtils.getProvision(mgv, base, quote, gasreq, _gasprice);
    uint balMaker = baseT.balanceOf(address(this));
    uint balTaker = quoteT.balanceOf(address(tkr));
    posthook_bytes = this.reverting_posthook.selector;

    ofr = mgv.newOffer(base, quote, 1 ether, 1 ether, gasreq, _gasprice, 0);
    bool success = tkr.take(ofr, 1 ether);
    TestEvents.check(success, "snipe should succeed");
    TestEvents.eq(
      balMaker - 1 ether,
      baseT.balanceOf(address(this)),
      "Incorrect maker balance"
    );
    TestEvents.eq(
      balTaker - 1 ether,
      quoteT.balanceOf(address(tkr)),
      "Incorrect taker balance"
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./SafeMath.sol";
import {IERC20} from "../MgvLib.sol";

// From OpenZeppelin
//The MIT License (MIT)

//Copyright (c) 2016-2020 zOS Global Limited

//Permission is hereby granted, free of charge, to any person obtaining
//a copy of this software and associated documentation files (the
//"Software"), to deal in the Software without restriction, including
//without limitation the rights to use, copy, modify, merge, publish,
//distribute, sublicense, and/or sell copies of the Software, and to
//permit persons to whom the Software is furnished to do so, subject to
//the following conditions:

//The above copyright notice and this permission notice shall be included
//in all copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
  using SafeMath for uint;

  mapping(address => uint) private _balances;

  mapping(address => mapping(address => uint)) private _allowances;

  uint private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory __name, string memory __symbol) {
    _name = __name;
    _symbol = __symbol;
    _decimals = 18;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(
      amount,
      "ERC20: transfer amount exceeds balance"
    );
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(
      amount,
      "ERC20: burn amount exceeds balance"
    );
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint amount
  ) internal virtual {}

  function deposit() external payable override {}

  function withdraw(uint) external override {}
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.10;
import "./ERC20BLWithDecimals.sol";
import "./SafeMath.sol";

contract MintableERC20BLWithDecimals is ERC20BLWithDecimals {
  using SafeMath for uint;

  mapping(address => bool) admins;

  constructor(
    address admin,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20BLWithDecimals(name, symbol, decimals) {
    admins[admin] = true;
  }

  function requireAdmin() internal view {
    require(admins[msg.sender], "MintableERC20BLWithDecimals/adminOnly");
  }

  function addAdmin(address admin) external {
    requireAdmin();
    admins[admin] = true;
  }

  function mint(uint amount) external {
    uint limit = 1000;
    require(
      amount <= limit.mul(pow(10, decimals())),
      "MintableERC20BLWithDecimals/mintLimitExceeded"
    );
    _mint(_msgSender(), amount);
  }

  function mintAdmin(address to, uint amount) external {
    requireAdmin();
    _mint(to, amount);
  }

  function burn(address account, uint amount) external {
    requireAdmin();
    _burn(account, amount);
  }

  function blacklists(address account) external {
    requireAdmin();
    _blacklists(account);
  }

  function whitelists(address account) external {
    requireAdmin();
    _whitelists(account);
  }

  function pow(uint n, uint e) public pure returns (uint) {
    if (e == 0) {
      return 1;
    } else if (e == 1) {
      return n;
    } else {
      uint p = pow(n, e.div(2));
      p = p.mul(p);
      if (e.mod(2) == 1) {
        p = p.mul(n);
      }
      return p;
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma abicoder v2;
pragma solidity ^0.8.10;

import "./TestToken.sol";
import {SafeMath as S} from "../SafeMath.sol";

contract MoneyMarket {
  // all prices are 1:1
  // interest rate is 0
  // the market has infinite liquidity

  // money market must be admin of all tokens to work
  // use token.addAdmin(address(moneyMarket)) to give it admin power

  uint constant RATIO = 13_000; // basis points
  TestToken[] tokens;
  mapping(TestToken => mapping(address => uint)) borrows;
  mapping(TestToken => mapping(address => uint)) lends;

  constructor(TestToken[] memory _tokens) {
    tokens = _tokens;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function borrow(TestToken token, uint amount) external returns (bool) {
    uint lent = getLends();
    uint borrowed = getBorrows();
    if (S.div(S.mul(S.add(borrowed, amount), RATIO), 10_000) <= lent) {
      borrows[token][msg.sender] += amount;
      token.mint(address(this), amount); // magic minting
      token.transfer(msg.sender, amount);
      return true;
    } else {
      return false;
    }
  }

  function lend(TestToken token, uint amount) external {
    token.transferFrom(msg.sender, address(this), amount);
    lends[token][msg.sender] += amount;
  }

  function repay(TestToken token, uint _amount) external {
    uint amount = min(borrows[token][msg.sender], _amount);
    token.transferFrom(msg.sender, address(this), amount);
    borrows[token][msg.sender] -= amount;
  }

  function redeem(TestToken token, uint _amount) external {
    uint amount = min(lends[token][msg.sender], _amount);
    token.transfer(msg.sender, amount);
    lends[token][msg.sender] -= amount;
  }

  function getBorrows() public view returns (uint total) {
    for (uint i = 0; i < tokens.length; i++) {
      total += borrows[tokens[i]][msg.sender];
    }
  }

  function getLends() public view returns (uint total) {
    for (uint i = 0; i < tokens.length; i++) {
      total += lends[tokens[i]][msg.sender];
    }
  }
}

// SPDX-License-Identifier: Unlicense

// IOracle.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>
pragma solidity ^0.8.10;
pragma abicoder v2;

import {IERC20} from "../../MgvLib.sol";

interface IMintableERC20 is IERC20 {
  function mint(uint value) external;
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOracle.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../MgvLib.sol";

/* The purpose of the Oracle contract is to act as a gas price and density
 * oracle for the Mangrove. It bridges to an external oracle, and allows
 * a given sender to update the gas price and density which the oracle
 * reports to Mangrove. */
contract MgvOracle is IMgvMonitor {
  address governance;
  address mutator;

  uint lastReceivedGasPrice;
  uint lastReceivedDensity;

  constructor(address _governance, address _initialMutator) {
    governance = _governance;
    mutator = _initialMutator;

    //NOTE: Hardwiring density for now
    /* Mangrove will reject densities from the Monitor that don't fit in 32 bits and use its internal density instead, so setting this contract's density to `type(uint).max` is a way to let Mangrove deal with density on its own. */
    lastReceivedDensity = type(uint).max;
  }

  /* ## `authOnly` check */
  // NOTE: Should use standard auth method, instead of this copy from MgvGovernable

  function authOnly() internal view {
    require(
      msg.sender == governance ||
        msg.sender == address(this) ||
        governance == address(0),
      "MgvOracle/unauthorized"
    );
  }

  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker)
    external
    override
  {
    // Do nothing
  }

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker)
    external
    override
  {
    // Do nothing
  }

  function setMutator(address _mutator) external {
    authOnly();

    mutator = _mutator;
  }

  function setGasPrice(uint gasPrice) external {
    // governance or mutator are allowed to update the gasprice
    require(
      msg.sender == governance || msg.sender == mutator,
      "MgvOracle/unauthorized"
    );

    lastReceivedGasPrice = gasPrice;
  }

  function setDensity(uint /*density*/) private view {
    // governance or mutator are allowed to update the density
    require(
      msg.sender == governance || msg.sender == mutator,
      "MgvOracle/unauthorized"
    );

    //NOTE: Not implemented, so not made external yet
  }

  function read(address /*outbound_tkn*/, address /*inbound_tkn*/)
    external
    view
    override
    returns (uint gasprice, uint density)
  {
    return (lastReceivedGasPrice, lastReceivedDensity);
  }
}