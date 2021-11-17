pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: Unlicense

// IERC20.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */




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

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: Unlicense

// MgvLib.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */




import "./IERC20.sol";

/* # Structs
The structs defined in `structs.js` have their counterpart as solidity structs that are easy to manipulate for outside contracts / callers of view functions. */
library MgvLib {
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

  /*
   Some miscellaneous data types useful to `Mangrove` and external contracts */
  //+clear+

  /* `SingleOrder` holds data about an order-offer match in a struct. Used by `marketOrder` and `internalSnipes` (and some of their nested functions) to avoid stack too deep errors. */
  struct SingleOrder {
    address outbound_tkn;
    address inbound_tkn;
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
    uint overhead_gasbase,
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

pragma solidity ^0.7.0;

// SPDX-License-Identifier: Unlicense

// MgvPack.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>



library MgvPack {

  // fields are of the form [name,bits,type]


  

  

  function offer_pack(uint __prev, uint __next, uint __wants, uint __gives, uint __gasprice) internal pure returns (bytes32) {
    return (((((bytes32(0) | bytes32((uint(__prev) << 232) >> 0)) | bytes32((uint(__next) << 232) >> 24)) | bytes32((uint(__wants) << 160) >> 48)) | bytes32((uint(__gives) << 160) >> 144)) | bytes32((uint(__gasprice) << 240) >> 240));
  }

  function offer_unpack(bytes32 __packed) internal pure returns (uint __prev, uint __next, uint __wants, uint __gives, uint __gasprice) {
    __prev = uint(uint((__packed << 0)) >> 232);
    __next = uint(uint((__packed << 24)) >> 232);
    __wants = uint(uint((__packed << 48)) >> 160);
    __gives = uint(uint((__packed << 144)) >> 160);
    __gasprice = uint(uint((__packed << 240)) >> 240);
  }

  function offer_unpack_prev(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 0)) >> 232);
  }
  function offer_unpack_next(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 24)) >> 232);
  }
  function offer_unpack_wants(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 48)) >> 160);
  }
  function offer_unpack_gives(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 144)) >> 160);
  }
  function offer_unpack_gasprice(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 240)) >> 240);
  }


  

  

  function offerDetail_pack(address __maker, uint __gasreq, uint __overhead_gasbase, uint __offer_gasbase) internal pure returns (bytes32) {
    return ((((bytes32(0) | bytes32((uint(__maker) << 96) >> 0)) | bytes32((uint(__gasreq) << 232) >> 160)) | bytes32((uint(__overhead_gasbase) << 232) >> 184)) | bytes32((uint(__offer_gasbase) << 232) >> 208));
  }

  function offerDetail_unpack(bytes32 __packed) internal pure returns (address __maker, uint __gasreq, uint __overhead_gasbase, uint __offer_gasbase) {
    __maker = address(uint((__packed << 0)) >> 96);
    __gasreq = uint(uint((__packed << 160)) >> 232);
    __overhead_gasbase = uint(uint((__packed << 184)) >> 232);
    __offer_gasbase = uint(uint((__packed << 208)) >> 232);
  }

  function offerDetail_unpack_maker(bytes32 __packed) internal pure returns(address) {
    return address(uint((__packed << 0)) >> 96);
  }
  function offerDetail_unpack_gasreq(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 160)) >> 232);
  }
  function offerDetail_unpack_overhead_gasbase(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 184)) >> 232);
  }
  function offerDetail_unpack_offer_gasbase(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 208)) >> 232);
  }


  

  

  function global_pack(address __monitor, uint __useOracle, uint __notify, uint __gasprice, uint __gasmax, uint __dead) internal pure returns (bytes32) {
    return ((((((bytes32(0) | bytes32((uint(__monitor) << 96) >> 0)) | bytes32((uint(__useOracle) << 248) >> 160)) | bytes32((uint(__notify) << 248) >> 168)) | bytes32((uint(__gasprice) << 240) >> 176)) | bytes32((uint(__gasmax) << 232) >> 192)) | bytes32((uint(__dead) << 248) >> 216));
  }

  function global_unpack(bytes32 __packed) internal pure returns (address __monitor, uint __useOracle, uint __notify, uint __gasprice, uint __gasmax, uint __dead) {
    __monitor = address(uint((__packed << 0)) >> 96);
    __useOracle = uint(uint((__packed << 160)) >> 248);
    __notify = uint(uint((__packed << 168)) >> 248);
    __gasprice = uint(uint((__packed << 176)) >> 240);
    __gasmax = uint(uint((__packed << 192)) >> 232);
    __dead = uint(uint((__packed << 216)) >> 248);
  }

  function global_unpack_monitor(bytes32 __packed) internal pure returns(address) {
    return address(uint((__packed << 0)) >> 96);
  }
  function global_unpack_useOracle(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 160)) >> 248);
  }
  function global_unpack_notify(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 168)) >> 248);
  }
  function global_unpack_gasprice(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 176)) >> 240);
  }
  function global_unpack_gasmax(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 192)) >> 232);
  }
  function global_unpack_dead(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 216)) >> 248);
  }


  

  

  function local_pack(uint __active, uint __fee, uint __density, uint __overhead_gasbase, uint __offer_gasbase, uint __lock, uint __best, uint __last) internal pure returns (bytes32) {
    return ((((((((bytes32(0) | bytes32((uint(__active) << 248) >> 0)) | bytes32((uint(__fee) << 240) >> 8)) | bytes32((uint(__density) << 128) >> 24)) | bytes32((uint(__overhead_gasbase) << 232) >> 152)) | bytes32((uint(__offer_gasbase) << 232) >> 176)) | bytes32((uint(__lock) << 248) >> 200)) | bytes32((uint(__best) << 232) >> 208)) | bytes32((uint(__last) << 232) >> 232));
  }

  function local_unpack(bytes32 __packed) internal pure returns (uint __active, uint __fee, uint __density, uint __overhead_gasbase, uint __offer_gasbase, uint __lock, uint __best, uint __last) {
    __active = uint(uint((__packed << 0)) >> 248);
    __fee = uint(uint((__packed << 8)) >> 240);
    __density = uint(uint((__packed << 24)) >> 128);
    __overhead_gasbase = uint(uint((__packed << 152)) >> 232);
    __offer_gasbase = uint(uint((__packed << 176)) >> 232);
    __lock = uint(uint((__packed << 200)) >> 248);
    __best = uint(uint((__packed << 208)) >> 232);
    __last = uint(uint((__packed << 232)) >> 232);
  }

  function local_unpack_active(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 0)) >> 248);
  }
  function local_unpack_fee(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 8)) >> 240);
  }
  function local_unpack_density(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 24)) >> 128);
  }
  function local_unpack_overhead_gasbase(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 152)) >> 232);
  }
  function local_unpack_offer_gasbase(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 176)) >> 232);
  }
  function local_unpack_lock(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 200)) >> 248);
  }
  function local_unpack_best(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 208)) >> 232);
  }
  function local_unpack_last(bytes32 __packed) internal pure returns(uint) {
    return uint(uint((__packed << 232)) >> 232);
  }

}

pragma solidity ^0.7.6;
pragma abicoder v2;

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


import {MgvLib as ML} from "../MgvLib.sol";
import {MgvPack as MP} from "../MgvPack.sol";

interface MangroveLike {
  function best(address, address) external view returns (uint);

  function offers(
    address,
    address,
    uint
  ) external view returns (bytes32);

  function offerDetails(
    address,
    address,
    uint
  ) external view returns (bytes32);

  function offerInfo(
    address,
    address,
    uint
  ) external view returns (ML.Offer memory, ML.OfferDetail memory);

  function config(address, address) external view returns (bytes32, bytes32);
}

contract MgvReader {
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
  ) public view returns (uint startId, uint length) {
    if (fromId == 0) {
      startId = mgv.best(outbound_tkn, inbound_tkn);
    } else {
      startId = MP.offer_unpack_gives(
        mgv.offers(outbound_tkn, inbound_tkn, fromId)
      ) > 0
        ? fromId
        : 0;
    }

    uint currentId = startId;

    while (currentId != 0 && length < maxOffers) {
      currentId = MP.offer_unpack_next(
        mgv.offers(outbound_tkn, inbound_tkn, currentId)
      );
      length = length + 1;
    }

    return (startId, length);
  }

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
      bytes32[] memory,
      bytes32[] memory
    )
  {
    (uint currentId, uint length) = offerListEndPoints(
      outbound_tkn,
      inbound_tkn,
      fromId,
      maxOffers
    );

    uint[] memory offerIds = new uint[](length);
    bytes32[] memory offers = new bytes32[](length);
    bytes32[] memory details = new bytes32[](length);

    uint i = 0;

    while (currentId != 0 && i < length) {
      offerIds[i] = currentId;
      offers[i] = mgv.offers(outbound_tkn, inbound_tkn, currentId);
      details[i] = mgv.offerDetails(outbound_tkn, inbound_tkn, currentId);
      currentId = MP.offer_unpack_next(offers[i]);
      i = i + 1;
    }

    return (currentId, offerIds, offers, details);
  }

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
      ML.Offer[] memory,
      ML.OfferDetail[] memory
    )
  {
    (uint currentId, uint length) = offerListEndPoints(
      outbound_tkn,
      inbound_tkn,
      fromId,
      maxOffers
    );

    uint[] memory offerIds = new uint[](length);
    ML.Offer[] memory offers = new ML.Offer[](length);
    ML.OfferDetail[] memory details = new ML.OfferDetail[](length);

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
  }

  function getProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint ofr_gasreq,
    uint ofr_gasprice
  ) external view returns (uint) {
    (bytes32 global, bytes32 local) = mgv.config(outbound_tkn, inbound_tkn);
    uint _gp;
    uint global_gasprice = MP.global_unpack_gasprice(global);
    if (global_gasprice > ofr_gasprice) {
      _gp = global_gasprice;
    } else {
      _gp = ofr_gasprice;
    }
    return
      (ofr_gasreq +
        MP.local_unpack_overhead_gasbase(local) +
        MP.local_unpack_offer_gasbase(local)) *
      _gp *
      10**9;
  }

  /* Returns the configuration in an ABI-compatible struct. Should not be called internally, would be a huge memory copying waste. Use `config` instead. */
  function config(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (ML.Global memory global, ML.Local memory local)
  {
    (bytes32 _global, bytes32 _local) = mgv.config(outbound_tkn, inbound_tkn);
    return (
      ML.Global({
        monitor: address(uint((_global << 0)) >> 96),
        useOracle: uint(uint((_global << 160)) >> 248) > 0,
        notify: uint(uint((_global << 168)) >> 248) > 0,
        gasprice: uint(uint((_global << 176)) >> 240),
        gasmax: uint(uint((_global << 192)) >> 232),
        dead: uint(uint((_global << 216)) >> 248) > 0
      }),
      ML.Local({
        active: uint(uint((_local << 0)) >> 248) > 0,
        overhead_gasbase: uint(uint((_local << 152)) >> 232),
        offer_gasbase: uint(uint((_local << 176)) >> 232),
        fee: uint(uint((_local << 8)) >> 240),
        density: uint(uint((_local << 24)) >> 128),
        best: uint(uint((_local << 208)) >> 232),
        lock: uint(uint((_local << 200)) >> 248) > 0,
        last: uint(uint((_local << 232)) >> 232)
      })
    );
  }
}