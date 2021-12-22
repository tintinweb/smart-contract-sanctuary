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
  type t is bytes32;

  function to_struct(t __packed) internal pure returns (OfferStruct memory __s) { unchecked {
    __s.prev = uint(uint((t.unwrap(__packed) << 0)) >> 224);
    __s.next = uint(uint((t.unwrap(__packed) << 32)) >> 224);
    __s.wants = uint(uint((t.unwrap(__packed) << 64)) >> 160);
    __s.gives = uint(uint((t.unwrap(__packed) << 160)) >> 160);
  }}

  function t_of_struct(OfferStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.prev, __s.next, __s.wants, __s.gives);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(uint __prev, uint __next, uint __wants, uint __gives) internal pure returns (t) { unchecked {
    return t.wrap(((((bytes32(0) | bytes32((__prev << 224) >> 0)) | bytes32((__next << 224) >> 32)) | bytes32((__wants << 160) >> 64)) | bytes32((__gives << 160) >> 160)));
  }}

  function unpack(t __packed) internal pure returns (uint __prev, uint __next, uint __wants, uint __gives) { unchecked {
    __prev = uint(uint((t.unwrap(__packed) << 0)) >> 224);
    __next = uint(uint((t.unwrap(__packed) << 32)) >> 224);
    __wants = uint(uint((t.unwrap(__packed) << 64)) >> 160);
    __gives = uint(uint((t.unwrap(__packed) << 160)) >> 160);
  }}

  function prev(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 0)) >> 224);
  }}
  function prev(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((val << 224) >> 0)));
  }}
  function next(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 32)) >> 224);
  }}
  function next(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((val << 224) >> 32)));
  }}
  function wants(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 64)) >> 160);
  }}
  function wants(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffff000000000000000000000000ffffffffffffffffffffffff) | bytes32((val << 160) >> 64)));
  }}
  function gives(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 160)) >> 160);
  }}
  function gives(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000) | bytes32((val << 160) >> 160)));
  }}
}

library OfferDetail {
  //some type safety for each struct
  type t is bytes32;

  function to_struct(t __packed) internal pure returns (OfferDetailStruct memory __s) { unchecked {
    __s.maker = address(uint160(uint((t.unwrap(__packed) << 0)) >> 96));
    __s.gasreq = uint(uint((t.unwrap(__packed) << 160)) >> 232);
    __s.offer_gasbase = uint(uint((t.unwrap(__packed) << 184)) >> 232);
    __s.gasprice = uint(uint((t.unwrap(__packed) << 208)) >> 240);
  }}

  function t_of_struct(OfferDetailStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.maker, __s.gasreq, __s.offer_gasbase, __s.gasprice);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) internal pure returns (t) { unchecked {
    return t.wrap(((((bytes32(0) | bytes32((uint(uint160(__maker)) << 96) >> 0)) | bytes32((__gasreq << 232) >> 160)) | bytes32((__offer_gasbase << 232) >> 184)) | bytes32((__gasprice << 240) >> 208)));
  }}

  function unpack(t __packed) internal pure returns (address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) { unchecked {
    __maker = address(uint160(uint((t.unwrap(__packed) << 0)) >> 96));
    __gasreq = uint(uint((t.unwrap(__packed) << 160)) >> 232);
    __offer_gasbase = uint(uint((t.unwrap(__packed) << 184)) >> 232);
    __gasprice = uint(uint((t.unwrap(__packed) << 208)) >> 240);
  }}

  function maker(t __packed) internal pure returns(address) { unchecked {
    return address(uint160(uint((t.unwrap(__packed) << 0)) >> 96));
  }}
  function maker(t __packed,address val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0x0000000000000000000000000000000000000000ffffffffffffffffffffffff) | bytes32((uint(uint160(val)) << 96) >> 0)));
  }}
  function gasreq(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 160)) >> 232);
  }}
  function gasreq(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff) | bytes32((val << 232) >> 160)));
  }}
  function offer_gasbase(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 184)) >> 232);
  }}
  function offer_gasbase(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff) | bytes32((val << 232) >> 184)));
  }}
  function gasprice(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 208)) >> 240);
  }}
  function gasprice(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff) | bytes32((val << 240) >> 208)));
  }}
}

library Global {
  //some type safety for each struct
  type t is bytes32;

  function to_struct(t __packed) internal pure returns (GlobalStruct memory __s) { unchecked {
    __s.monitor = address(uint160(uint((t.unwrap(__packed) << 0)) >> 96));
    __s.useOracle = ((uint((t.unwrap(__packed) << 160)) >> 248) > 0);
    __s.notify = ((uint((t.unwrap(__packed) << 168)) >> 248) > 0);
    __s.gasprice = uint(uint((t.unwrap(__packed) << 176)) >> 240);
    __s.gasmax = uint(uint((t.unwrap(__packed) << 192)) >> 232);
    __s.dead = ((uint((t.unwrap(__packed) << 216)) >> 248) > 0);
  }}

  function t_of_struct(GlobalStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.monitor, __s.useOracle, __s.notify, __s.gasprice, __s.gasmax, __s.dead);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) internal pure returns (t) { unchecked {
    return t.wrap(((((((bytes32(0) | bytes32((uint(uint160(__monitor)) << 96) >> 0)) | bytes32((uint_of_bool(__useOracle) << 248) >> 160)) | bytes32((uint_of_bool(__notify) << 248) >> 168)) | bytes32((__gasprice << 240) >> 176)) | bytes32((__gasmax << 232) >> 192)) | bytes32((uint_of_bool(__dead) << 248) >> 216)));
  }}

  function unpack(t __packed) internal pure returns (address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) { unchecked {
    __monitor = address(uint160(uint((t.unwrap(__packed) << 0)) >> 96));
    __useOracle = ((uint((t.unwrap(__packed) << 160)) >> 248) > 0);
    __notify = ((uint((t.unwrap(__packed) << 168)) >> 248) > 0);
    __gasprice = uint(uint((t.unwrap(__packed) << 176)) >> 240);
    __gasmax = uint(uint((t.unwrap(__packed) << 192)) >> 232);
    __dead = ((uint((t.unwrap(__packed) << 216)) >> 248) > 0);
  }}

  function monitor(t __packed) internal pure returns(address) { unchecked {
    return address(uint160(uint((t.unwrap(__packed) << 0)) >> 96));
  }}
  function monitor(t __packed,address val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0x0000000000000000000000000000000000000000ffffffffffffffffffffffff) | bytes32((uint(uint160(val)) << 96) >> 0)));
  }}
  function useOracle(t __packed) internal pure returns(bool) { unchecked {
    return ((uint((t.unwrap(__packed) << 160)) >> 248) > 0);
  }}
  function useOracle(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff) | bytes32((uint_of_bool(val) << 248) >> 160)));
  }}
  function notify(t __packed) internal pure returns(bool) { unchecked {
    return ((uint((t.unwrap(__packed) << 168)) >> 248) > 0);
  }}
  function notify(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff) | bytes32((uint_of_bool(val) << 248) >> 168)));
  }}
  function gasprice(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 176)) >> 240);
  }}
  function gasprice(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff) | bytes32((val << 240) >> 176)));
  }}
  function gasmax(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 192)) >> 232);
  }}
  function gasmax(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff) | bytes32((val << 232) >> 192)));
  }}
  function dead(t __packed) internal pure returns(bool) { unchecked {
    return ((uint((t.unwrap(__packed) << 216)) >> 248) > 0);
  }}
  function dead(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffff) | bytes32((uint_of_bool(val) << 248) >> 216)));
  }}
}

library Local {
  //some type safety for each struct
  type t is bytes32;

  function to_struct(t __packed) internal pure returns (LocalStruct memory __s) { unchecked {
    __s.active = ((uint((t.unwrap(__packed) << 0)) >> 248) > 0);
    __s.fee = uint(uint((t.unwrap(__packed) << 8)) >> 240);
    __s.density = uint(uint((t.unwrap(__packed) << 24)) >> 144);
    __s.offer_gasbase = uint(uint((t.unwrap(__packed) << 136)) >> 232);
    __s.lock = ((uint((t.unwrap(__packed) << 160)) >> 248) > 0);
    __s.best = uint(uint((t.unwrap(__packed) << 168)) >> 224);
    __s.last = uint(uint((t.unwrap(__packed) << 200)) >> 224);
  }}

  function t_of_struct(LocalStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.active, __s.fee, __s.density, __s.offer_gasbase, __s.lock, __s.best, __s.last);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) internal pure returns (t) { unchecked {
    return t.wrap((((((((bytes32(0) | bytes32((uint_of_bool(__active) << 248) >> 0)) | bytes32((__fee << 240) >> 8)) | bytes32((__density << 144) >> 24)) | bytes32((__offer_gasbase << 232) >> 136)) | bytes32((uint_of_bool(__lock) << 248) >> 160)) | bytes32((__best << 224) >> 168)) | bytes32((__last << 224) >> 200)));
  }}

  function unpack(t __packed) internal pure returns (bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) { unchecked {
    __active = ((uint((t.unwrap(__packed) << 0)) >> 248) > 0);
    __fee = uint(uint((t.unwrap(__packed) << 8)) >> 240);
    __density = uint(uint((t.unwrap(__packed) << 24)) >> 144);
    __offer_gasbase = uint(uint((t.unwrap(__packed) << 136)) >> 232);
    __lock = ((uint((t.unwrap(__packed) << 160)) >> 248) > 0);
    __best = uint(uint((t.unwrap(__packed) << 168)) >> 224);
    __last = uint(uint((t.unwrap(__packed) << 200)) >> 224);
  }}

  function active(t __packed) internal pure returns(bool) { unchecked {
    return ((uint((t.unwrap(__packed) << 0)) >> 248) > 0);
  }}
  function active(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint_of_bool(val) << 248) >> 0)));
  }}
  function fee(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 8)) >> 240);
  }}
  function fee(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((val << 240) >> 8)));
  }}
  function density(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 24)) >> 144);
  }}
  function density(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffff0000000000000000000000000000ffffffffffffffffffffffffffffff) | bytes32((val << 144) >> 24)));
  }}
  function offer_gasbase(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 136)) >> 232);
  }}
  function offer_gasbase(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff) | bytes32((val << 232) >> 136)));
  }}
  function lock(t __packed) internal pure returns(bool) { unchecked {
    return ((uint((t.unwrap(__packed) << 160)) >> 248) > 0);
  }}
  function lock(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff) | bytes32((uint_of_bool(val) << 248) >> 160)));
  }}
  function best(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 168)) >> 224);
  }}
  function best(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffff) | bytes32((val << 224) >> 168)));
  }}
  function last(t __packed) internal pure returns(uint) { unchecked {
    return uint(uint((t.unwrap(__packed) << 200)) >> 224);
  }}
  function last(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffff) | bytes32((val << 224) >> 200)));
  }}
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