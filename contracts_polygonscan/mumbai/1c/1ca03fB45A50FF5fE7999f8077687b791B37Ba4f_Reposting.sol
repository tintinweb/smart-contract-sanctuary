pragma solidity ^0.7.0;
pragma abicoder v2;

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


import {MgvLib as ML} from "./MgvLib.sol";

import {AbstractMangrove} from "./AbstractMangrove.sol";

/* <a id="Mangrove"></a> The `Mangrove` contract implements the "normal" version of Mangrove, where the taker flashloans the desired amount to each maker. Each time, makers are called after the loan. When the order is complete, each maker is called once again (with the orderbook unlocked). */
contract Mangrove is AbstractMangrove {
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
  {
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
          address(uint((sor.offerDetail << 0)) >> 96),
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
  }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

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


import {HasMgvEvents} from "./MgvLib.sol";
import {MgvRoot} from "./MgvRoot.sol";

contract MgvGovernable is MgvRoot {
  /* The `governance` address. Governance is the only address that can configure parameters. */
  address public governance;

  constructor(
    address _governance,
    uint _gasprice,
    uint gasmax
  ) MgvRoot() {
    emit NewMgv();

    /* Initially, governance is open to anyone. */

    /* Initialize vault to governance address, and set initial gasprice and gasmax. */
    setVault(_governance);
    setGasprice(_gasprice);
    setGasmax(gasmax);
    /* Initialize governance to `_governance` after parameter setting. */
    setGovernance(_governance);
  }

  /* ## `authOnly` check */

  function authOnly() internal view {
    require(
      msg.sender == governance ||
        msg.sender == address(this) ||
        governance == address(0),
      "mgv/unauthorized"
    );
  }

  /* # Set configuration and Mangrove state */

  /* ## Locals */
  /* ### `active` */
  function activate(
    address outbound_tkn,
    address inbound_tkn,
    uint fee,
    uint density,
    uint overhead_gasbase,
    uint offer_gasbase
  ) public {
    authOnly();
    locals[outbound_tkn][inbound_tkn] = (locals[outbound_tkn][inbound_tkn] & bytes32(0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(1) << 248) >> 0));
    emit SetActive(outbound_tkn, inbound_tkn, true);
    setFee(outbound_tkn, inbound_tkn, fee);
    setDensity(outbound_tkn, inbound_tkn, density);
    setGasbase(outbound_tkn, inbound_tkn, overhead_gasbase, offer_gasbase);
  }

  function deactivate(address outbound_tkn, address inbound_tkn) public {
    authOnly();
    locals[outbound_tkn][inbound_tkn] = (locals[outbound_tkn][inbound_tkn] & bytes32(0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(0) << 248) >> 0));
    emit SetActive(outbound_tkn, inbound_tkn, false);
  }

  /* ### `fee` */
  function setFee(
    address outbound_tkn,
    address inbound_tkn,
    uint fee
  ) public {
    authOnly();
    /* `fee` is in basis points, i.e. in percents of a percent. */
    require(fee <= 500, "mgv/config/fee/<=500"); // at most 5%
    locals[outbound_tkn][inbound_tkn] = (locals[outbound_tkn][inbound_tkn] & bytes32(0xff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(fee) << 240) >> 8));
    emit SetFee(outbound_tkn, inbound_tkn, fee);
  }

  /* ### `density` */
  /* Useless if `global.useOracle != 0` */
  function setDensity(
    address outbound_tkn,
    address inbound_tkn,
    uint density
  ) public {
    authOnly();

    require(checkDensity(density), "mgv/config/density/128bits");
    //+clear+
    locals[outbound_tkn][inbound_tkn] = (locals[outbound_tkn][inbound_tkn] & bytes32(0xffffff00000000000000000000000000000000ffffffffffffffffffffffffff) | bytes32((uint(density) << 128) >> 24));
    emit SetDensity(outbound_tkn, inbound_tkn, density);
  }

  /* ### `gasbase` */
  function setGasbase(
    address outbound_tkn,
    address inbound_tkn,
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
    locals[outbound_tkn][inbound_tkn] = ((locals[outbound_tkn][inbound_tkn] & bytes32(0xffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffffff) | bytes32((uint(offer_gasbase) << 232) >> 176)) & bytes32(0xffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffffff) | bytes32((uint(overhead_gasbase) << 232) >> 152));
    emit SetGasbase(outbound_tkn, inbound_tkn, overhead_gasbase, offer_gasbase);
  }

  /* ## Globals */
  /* ### `kill` */
  function kill() public {
    authOnly();
    global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffff) | bytes32((uint(1) << 248) >> 216));
    emit Kill();
  }

  /* ### `gasprice` */
  /* Useless if `global.useOracle is != 0` */
  function setGasprice(uint gasprice) public {
    authOnly();
    require(checkGasprice(gasprice), "mgv/config/gasprice/16bits");

    //+clear+

    global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff) | bytes32((uint(gasprice) << 240) >> 176));
    emit SetGasprice(gasprice);
  }

  /* ### `gasmax` */
  function setGasmax(uint gasmax) public {
    authOnly();
    /* Since any new `gasreq` is bounded above by `config.gasmax`, this check implies that all offers' `gasreq` is 24 bits wide at most. */
    require(uint24(gasmax) == gasmax, "mgv/config/gasmax/24bits");
    //+clear+
    global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff) | bytes32((uint(gasmax) << 232) >> 192));
    emit SetGasmax(gasmax);
  }

  /* ### `governance` */
  function setGovernance(address governanceAddress) public {
    authOnly();
    governance = governanceAddress;
    emit SetGovernance(governanceAddress);
  }

  /* ### `vault` */
  function setVault(address vaultAddress) public {
    authOnly();
    vault = vaultAddress;
    emit SetVault(vaultAddress);
  }

  /* ### `monitor` */
  function setMonitor(address monitor) public {
    authOnly();
    global = (global & bytes32(0x0000000000000000000000000000000000000000ffffffffffffffffffffffff) | bytes32((uint(monitor) << 96) >> 0));
    emit SetMonitor(monitor);
  }

  /* ### `useOracle` */
  function setUseOracle(bool useOracle) public {
    authOnly();
    uint _useOracle = useOracle ? 1 : 0;
    global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff) | bytes32((uint(_useOracle) << 248) >> 160));
    emit SetUseOracle(useOracle);
  }

  /* ### `notify` */
  function setNotify(bool notify) public {
    authOnly();
    uint _notify = notify ? 1 : 0;
    global = (global & bytes32(0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff) | bytes32((uint(_notify) << 248) >> 168));
    emit SetNotify(notify);
  }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

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


import {MgvLib as ML, HasMgvEvents, IMgvMonitor} from "./MgvLib.sol";
import {MgvRoot} from "./MgvRoot.sol";

/* `MgvHasOffers` contains the state variables and functions common to both market-maker operations and market-taker operations. Mostly: storing offers, removing them, updating market makers' provisions. */
contract MgvHasOffers is MgvRoot {
  /* # State variables */
  /* Given a `outbound_tkn`,`inbound_tkn` pair, the mappings `offers` and `offerDetails` associate two 256 bits words to each offer id. Those words encode information detailed in [`structs.js`](#structs.js).

     The mappings are `outbound_tkn => inbound_tkn => offerId => bytes32`.
   */
  mapping(address => mapping(address => mapping(uint => bytes32)))
    public offers;
  mapping(address => mapping(address => mapping(uint => bytes32)))
    public offerDetails;

  /* Makers provision their possible penalties in the `balanceOf` mapping.

       Offers specify the amount of gas they require for successful execution ([`gasreq`](#structs.js/gasreq)). To minimize book spamming, market makers must provision a *penalty*, which depends on their `gasreq` and on the pair's [`*_gasbase`](#structs.js/gasbase). This provision is deducted from their `balanceOf`. If an offer fails, part of that provision is given to the taker, as retribution. The exact amount depends on the gas used by the offer before failing.

       The Mangrove keeps track of their available balance in the `balanceOf` map, which is decremented every time a maker creates a new offer, and may be modified on offer updates/cancelations/takings.
     */
  mapping(address => uint) public balanceOf;

  /* # Read functions */
  /* Convenience function to get best offer of the given pair */
  function best(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint)
  {
    bytes32 local = locals[outbound_tkn][inbound_tkn];
    return uint(uint((local << 208)) >> 232);
  }

  /* Returns information about an offer in ABI-compatible structs. Do not use internally, would be a huge memory-copying waste. Use `offers[outbound_tkn][inbound_tkn]` and `offerDetails[outbound_tkn][inbound_tkn]` instead. */
  function offerInfo(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) external view returns (ML.Offer memory, ML.OfferDetail memory) {
    bytes32 offer = offers[outbound_tkn][inbound_tkn][offerId];
    ML.Offer memory offerStruct = ML.Offer({
      prev: uint(uint((offer << 0)) >> 232),
      next: uint(uint((offer << 24)) >> 232),
      wants: uint(uint((offer << 48)) >> 160),
      gives: uint(uint((offer << 144)) >> 160),
      gasprice: uint(uint((offer << 240)) >> 240)
    });

    bytes32 offerDetail = offerDetails[outbound_tkn][inbound_tkn][offerId];

    ML.OfferDetail memory offerDetailStruct = ML.OfferDetail({
      maker: address(uint((offerDetail << 0)) >> 96),
      gasreq: uint(uint((offerDetail << 160)) >> 232),
      overhead_gasbase: uint(uint((offerDetail << 184)) >> 232),
      offer_gasbase: uint(uint((offerDetail << 208)) >> 232)
    });
    return (offerStruct, offerDetailStruct);
  }

  /* # Provision debit/credit utility functions */
  /* `balanceOf` is in wei of ETH. */

  function debitWei(address maker, uint amount) internal {
    uint makerBalance = balanceOf[maker];
    require(makerBalance >= amount, "mgv/insufficientProvision");
    balanceOf[maker] = makerBalance - amount;
    emit Debit(maker, amount);
  }

  function creditWei(address maker, uint amount) internal {
    balanceOf[maker] += amount;
    emit Credit(maker, amount);
  }

  /* # Misc. low-level functions */
  /* ## Offer deletion */

  /* When an offer is deleted, it is marked as such by setting `gives` to 0. Note that provision accounting in the Mangrove aims to minimize writes. Each maker `fund`s the Mangrove to increase its balance. When an offer is created/updated, we compute how much should be reserved to pay for possible penalties. That amount can always be recomputed with `offer.gasprice * (offerDetail.gasreq + offerDetail.overhead_gasbase + offerDetail.offer_gasbase)`. The balance is updated to reflect the remaining available ethers.

     Now, when an offer is deleted, the offer can stay provisioned, or be `deprovision`ed. In the latter case, we set `gasprice` to 0, which induces a provision of 0. All code calling `dirtyDeleteOffer` with `deprovision` set to `true` must be careful to correctly account for where that provision is going (back to the maker's `balanceOf`, or sent to a taker as compensation). */
  function dirtyDeleteOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bytes32 offer,
    bool deprovision
  ) internal {
    offer = (offer & bytes32(0xffffffffffffffffffffffffffffffffffff000000000000000000000000ffff) | bytes32((uint(0) << 160) >> 144));
    if (deprovision) {
      offer = (offer & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000) | bytes32((uint(0) << 240) >> 240));
    }
    offers[outbound_tkn][inbound_tkn][offerId] = offer;
  }

  /* ## Stitching the orderbook */

  /* Connect the offers `betterId` and `worseId` through their `next`/`prev` pointers. For more on the book structure, see [`structs.js`](#structs.js). Used after executing an offer (or a segment of offers), after removing an offer, or moving an offer.

  **Warning**: calling with `betterId = 0` will set `worseId` as the best. So with `betterId = 0` and `worseId = 0`, it sets the book to empty and loses track of existing offers.

  **Warning**: may make memory copy of `local.best` stale. Returns new `local`. */
  function stitchOffers(
    address outbound_tkn,
    address inbound_tkn,
    uint betterId,
    uint worseId,
    bytes32 local
  ) internal returns (bytes32) {
    if (betterId != 0) {
      offers[outbound_tkn][inbound_tkn][betterId] = (offers[outbound_tkn][inbound_tkn][betterId] & bytes32(0xffffff000000ffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(worseId) << 232) >> 24));
    } else {
      local = (local & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffff000000ffffff) | bytes32((uint(worseId) << 232) >> 208));
    }

    if (worseId != 0) {
      offers[outbound_tkn][inbound_tkn][worseId] = (offers[outbound_tkn][inbound_tkn][worseId] & bytes32(0x000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(betterId) << 232) >> 0));
    }

    return local;
  }

  /* ## Check offer is live */
  /* Check whether an offer is 'live', that is: inserted in the order book. The Mangrove holds a `outbound_tkn => inbound_tkn => id => bytes32` mapping in storage. Offer ids that are not yet assigned or that point to since-deleted offer will point to an offer with `gives` field at 0. */
  function isLive(bytes32 offer) public pure returns (bool) {
    return uint(uint((offer << 144)) >> 160) > 0;
  }
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
pragma abicoder v2;

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


import {IMaker, HasMgvEvents} from "./MgvLib.sol";
import {MgvHasOffers} from "./MgvHasOffers.sol";

/* `MgvOfferMaking` contains market-making-related functions. */
contract MgvOfferMaking is MgvHasOffers {
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
    bytes32 global;
    bytes32 local;
    // used on update only
    bytes32 oldOffer;
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
  ) external returns (uint) {
    /* In preparation for calling `writeOffer`, we read the `outbound_tkn`,`inbound_tkn` pair configuration, check for reentrancy and market liveness, fill the `OfferPack` struct and increment the `outbound_tkn`,`inbound_tkn` pair's `last`. */
    OfferPack memory ofp;
    (ofp.global, ofp.local) = config(outbound_tkn, inbound_tkn);
    unlockedMarketOnly(ofp.local);
    activeMarketOnly(ofp.global, ofp.local);

    ofp.id = 1 + uint(uint((ofp.local << 232)) >> 232);
    require(uint24(ofp.id) == ofp.id, "mgv/offerIdOverflow");

    ofp.local = (ofp.local & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000) | bytes32((uint(ofp.id) << 232) >> 232));

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
  }

  /* ## Update Offer */
  //+clear+
  /* Very similar to `newOffer`, `updateOffer` prepares an `OfferPack` for `writeOffer`. Makers should use it for updating live offers, but also to save on gas by reusing old, already consumed offers.

     A `pivotId` should still be given to minimise reads in the offer book. It is OK to give the offers' own id as a pivot.


     Gas use is minimal when:
     1. The offer does not move in the book
     2. The offer does not change its `gasreq`
     3. The (`outbound_tkn`,`inbound_tkn`)'s `*_gasbase` has not changed since the offer was last written
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
  ) external {
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
    bytes32 oldLocal = ofp.local;
    /* The second argument indicates that we are updating an existing offer, not creating a new one. */
    writeOffer(ofp, true);
    /* We saved the current pair's configuration before calling `writeOffer`, since that function may update the current `best` offer. We now check for any change to the configuration and update it if needed. */
    if (oldLocal != ofp.local) {
      locals[ofp.outbound_tkn][ofp.inbound_tkn] = ofp.local;
    }
  }

  /* ## Retract Offer */
  //+clear+
  /* `retractOffer` takes the offer `offerId` out of the book. However, `deprovision == true` also refunds the provision associated with the offer. */
  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision
  ) external returns (uint provision) {
    (, bytes32 local) = config(outbound_tkn, inbound_tkn);
    unlockedMarketOnly(local);
    bytes32 offer = offers[outbound_tkn][inbound_tkn][offerId];
    bytes32 offerDetail = offerDetails[outbound_tkn][inbound_tkn][offerId];
    require(
      msg.sender == address(uint((offerDetail << 0)) >> 96),
      "mgv/retractOffer/unauthorized"
    );

    /* Here, we are about to un-live an offer, so we start by taking it out of the book by stitching together its previous and next offers. Note that unconditionally calling `stitchOffers` would break the book since it would connect offers that may have since moved. */
    if (isLive(offer)) {
      bytes32 oldLocal = local;
      local = stitchOffers(
        outbound_tkn,
        inbound_tkn,
        uint(uint((offer << 0)) >> 232),
        uint(uint((offer << 24)) >> 232),
        local
      );
      /* If calling `stitchOffers` has changed the current `best` offer, we update the storage. */
      if (oldLocal != local) {
        locals[outbound_tkn][inbound_tkn] = local;
      }
    }
    /* Set `gives` to 0. Moreover, the last argument depends on whether the user wishes to get their provision back (if true, `gasprice` will be set to 0 as well). */
    dirtyDeleteOffer(outbound_tkn, inbound_tkn, offerId, offer, deprovision);

    /* If the user wants to get their provision back, we compute its provision from the offer's `gasprice`, `*_gasbase` and `gasreq`. */
    if (deprovision) {
      provision =
        10**9 *
        uint(uint((offer << 240)) >> 240) * //gasprice is 0 if offer was deprovisioned
        (uint(uint((offerDetail << 160)) >> 232) +
          uint(uint((offerDetail << 184)) >> 232) +
          uint(uint((offerDetail << 208)) >> 232));
      // credit `balanceOf` and log transfer
      creditWei(msg.sender, provision);
    }
    emit OfferRetract(outbound_tkn, inbound_tkn, offerId);
  }

  /* ## Provisioning
  Market makers must have enough provisions for possible penalties. These provisions are in ETH. Every time a new offer is created or an offer is updated, `balanceOf` is adjusted to provision the offer's maximum possible penalty (`gasprice * (gasreq + overhead_gasbase + offer_gasbase)`).

  For instance, if the current `balanceOf` of a maker is 1 ether and they create an offer that requires a provision of 0.01 ethers, their `balanceOf` will be reduced to 0.99 ethers. No ethers will move; this is just an internal accounting movement to make sure the maker cannot `withdraw` the provisioned amounts.

  */
  //+clear+

  /* Fund should be called with a nonzero value (hence the `payable` modifier). The provision will be given to `maker`, not `msg.sender`. */
  function fund(address maker) public payable {
    (bytes32 _global, ) = config(address(0), address(0));
    liveMgvOnly(_global);
    creditWei(maker, msg.value);
  }

  function fund() external payable {
    fund(msg.sender);
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

  /* # Low-level Maker functions */

  /* ## Write Offer */

  function writeOffer(OfferPack memory ofp, bool update) internal {
    /* `gasprice`'s floor is Mangrove's own gasprice estimate, `ofp.global.gasprice`. We first check that gasprice fits in 16 bits. Otherwise it could be that `uint16(gasprice) < global_gasprice < gasprice`, and the actual value we store is `uint16(gasprice)`. */
    require(
      uint16(ofp.gasprice) == ofp.gasprice,
      "mgv/writeOffer/gasprice/16bits"
    );

    if (ofp.gasprice < uint(uint((ofp.global << 176)) >> 240)) {
      ofp.gasprice = uint(uint((ofp.global << 176)) >> 240);
    }

    /* * Check `gasreq` below limit. Implies `gasreq` at most 24 bits wide, which ensures no overflow in computation of `provision` (see below). */
    require(
      ofp.gasreq <= uint(uint((ofp.global << 192)) >> 232),
      "mgv/writeOffer/gasreq/tooHigh"
    );
    /* * Make sure `gives > 0` -- division by 0 would throw in several places otherwise, and `isLive` relies on it. */
    require(ofp.gives > 0, "mgv/writeOffer/gives/tooLow");
    /* * Make sure that the maker is posting a 'dense enough' offer: the ratio of `outbound_tkn` offered per gas consumed must be high enough. The actual gas cost paid by the taker is overapproximated by adding `offer_gasbase` to `gasreq`. */
    require(
      ofp.gives >=
        (ofp.gasreq + uint(uint((ofp.local << 176)) >> 232)) *
          uint(uint((ofp.local << 24)) >> 128),
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
      bytes32 offerDetail = offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][
        ofp.id
      ];
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

      /* If the offer is new, has a new `gasreq`, or if the Mangrove's `*_gasbase` configuration parameter has changed, we also update `offerDetails`. */
      if (
        !update ||
        uint(uint((offerDetail << 160)) >> 232) != ofp.gasreq ||
        uint(uint((offerDetail << 184)) >> 232) !=
        uint(uint((ofp.local << 152)) >> 232) ||
        uint(uint((offerDetail << 208)) >> 232) !=
        uint(uint((ofp.local << 176)) >> 232)
      ) {
        uint overhead_gasbase = uint(uint((ofp.local << 152)) >> 232);
        uint offer_gasbase = uint(uint((ofp.local << 176)) >> 232);
        offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][ofp.id] = ((((bytes32(0) | bytes32((uint(uint(msg.sender)) << 96) >> 0)) | bytes32((uint(ofp.gasreq) << 232) >> 160)) | bytes32((uint(overhead_gasbase) << 232) >> 184)) | bytes32((uint(offer_gasbase) << 232) >> 208));
      }
    }

    /* With every change to an offer, a maker may deduct provisions from its `balanceOf` balance. It may also get provisions back if the updated offer requires fewer provisions than before. */
    {
      uint provision = (ofp.gasreq +
        uint(uint((ofp.local << 176)) >> 232) +
        uint(uint((ofp.local << 152)) >> 232)) *
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
        offers[ofp.outbound_tkn][ofp.inbound_tkn][prev] = (offers[ofp.outbound_tkn][ofp.inbound_tkn][prev] & bytes32(0xffffff000000ffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(ofp.id) << 232) >> 24));
      } else {
        ofp.local = (ofp.local & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffff000000ffffff) | bytes32((uint(ofp.id) << 232) >> 208));
      }

      /* * If the offer is not the last one, we update its successor. */
      if (next != 0) {
        offers[ofp.outbound_tkn][ofp.inbound_tkn][next] = (offers[ofp.outbound_tkn][ofp.inbound_tkn][next] & bytes32(0x000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | bytes32((uint(ofp.id) << 232) >> 0));
      }

      /* * Recall that in this branch, the offer has changed location, or is not currently in the book. If the offer is not new and already in the book, we must remove it from its previous location by stitching its previous prev/next. */
      if (update && isLive(ofp.oldOffer)) {
        ofp.local = stitchOffers(
          ofp.outbound_tkn,
          ofp.inbound_tkn,
          uint(uint((ofp.oldOffer << 0)) >> 232),
          uint(uint((ofp.oldOffer << 24)) >> 232),
          ofp.local
        );
      }
    }

    /* With the `prev`/`next` in hand, we finally store the offer in the `offers` map. */
    bytes32 ofr = (((((bytes32(0) | bytes32((uint(prev) << 232) >> 0)) | bytes32((uint(next) << 232) >> 24)) | bytes32((uint(ofp.wants) << 160) >> 48)) | bytes32((uint(ofp.gives) << 160) >> 144)) | bytes32((uint(ofp.gasprice) << 240) >> 240));
    offers[ofp.outbound_tkn][ofp.inbound_tkn][ofp.id] = ofr;
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
    bytes32 pivot = pivotId == ofp.id
      ? ofp.oldOffer
      : offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotId];

    /* In case pivotId is not an active offer, it is unusable (since it is out of the book). We default to the current best offer. If the book is empty pivot will be 0. That is handled through a test in the `better` comparison function. */
    if (!isLive(pivot)) {
      pivotId = uint(uint((ofp.local << 208)) >> 232);
      pivot = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotId];
    }

    /* * Pivot is better than `wants/gives`, we follow `next`. */
    if (better(ofp, pivot, pivotId)) {
      bytes32 pivotNext;
      while (uint(uint((pivot << 24)) >> 232) != 0) {
        uint pivotNextId = uint(uint((pivot << 24)) >> 232);
        pivotNext = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotNextId];
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
        pivotPrev = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotPrevId];
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
    uint wants1 = uint(uint((offer1 << 48)) >> 160);
    uint gives1 = uint(uint((offer1 << 144)) >> 160);
    uint wants2 = ofp.wants;
    uint gives2 = ofp.gives;
    uint weight1 = wants1 * gives2;
    uint weight2 = wants2 * gives1;
    if (weight1 == weight2) {
      uint gasreq1 = uint(uint((offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][offerId1] << 160)) >> 232);
      uint gasreq2 = ofp.gasreq;
      return (gives1 * gasreq2 >= gives2 * gasreq1);
    } else {
      return weight1 < weight2;
    }
  }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

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


import {IERC20, HasMgvEvents, IMaker, IMgvMonitor, MgvLib as ML} from "./MgvLib.sol";
import {MgvHasOffers} from "./MgvHasOffers.sol";

abstract contract MgvOfferTaking is MgvHasOffers {
  /* # MultiOrder struct */
  /* The `MultiOrder` struct is used by market orders and snipes. Some of its fields are only used by market orders (`initialWants, initialGives`, `fillWants`), and others only by snipes (`successCount`). We need a common data structure for both since low-level calls are shared between market orders and snipes. The struct is helpful in decreasing stack use. */
  struct MultiOrder {
    uint initialWants;
    uint initialGives;
    uint totalGot;
    uint totalGave;
    uint totalPenalty;
    address taker;
    uint successCount;
    uint failCount;
    bool fillWants;
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
  {
    return
      generalMarketOrder(
        outbound_tkn,
        inbound_tkn,
        takerWants,
        takerGives,
        fillWants,
        msg.sender
      );
  }

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
  {
    /* Since amounts stored in offers are 96 bits wide, checking that `takerWants` and `takerGives` fit in 160 bits prevents overflow during the main market order loop. */
    require(uint160(takerWants) == takerWants, "mgv/mOrder/takerWants/160bits");
    require(uint160(takerGives) == takerGives, "mgv/mOrder/takerGives/160bits");

    /* `SingleOrder` is defined in `MgvLib.sol` and holds information for ordering the execution of one offer. */
    ML.SingleOrder memory sor;
    sor.outbound_tkn = outbound_tkn;
    sor.inbound_tkn = inbound_tkn;
    (sor.global, sor.local) = config(outbound_tkn, inbound_tkn);
    /* Throughout the execution of the market order, the `sor`'s offer id and other parameters will change. We start with the current best offer id (0 if the book is empty). */
    sor.offerId = uint(uint((sor.local << 208)) >> 232);
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
    sor.local = (sor.local & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffff) | bytes32((uint(1) << 248) >> 200));
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
  }

  /* ## Internal market order */
  //+clear+
  /* `internalMarketOrder` works recursively. Going downward, each successive offer is executed until the market order stops (due to: volume exhausted, bad price, or empty book). Then the [reentrancy lock is lifted](#internalMarketOrder/liftReentrancy). Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book.

    The last argument is a boolean named `proceed`. If an offer was not executed, it means the price has become too high. In that case, we notify the next recursive call that the market order should end. In this initial call, no offer has been executed yet so `proceed` is true. */
  function internalMarketOrder(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    bool proceed
  ) internal {
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
      bytes32 offer = sor.offer;
      bytes32 offerDetail = sor.offerDetail;

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
        sor.offerId = uint(uint((sor.offer << 24)) >> 232);
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
      sor.local = (sor.local & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffff) | bytes32((uint(0) << 248) >> 200));
      locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

      /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
      payTakerMinusFees(mor, sor);

      /* In an inverted Mangrove, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in a normal Mangrove. */
      executeEnd(mor, sor);
    }
  }

  /* # Sniping */
  /* ## Snipes */
  //+clear+

  /* `snipes` executes multiple offers. It takes a `uint[4][]` as penultimate argument, with each array element of the form `[offerId,takerWants,takerGives,offerGasreq]`. The return parameters are of the form `(successes,totalGot,totalGave,bounty)`. 
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
  {
    return
      generalSnipes(outbound_tkn, inbound_tkn, targets, fillWants, msg.sender);
  }

  /*
     From an array of _n_ `[offerId, takerWants,takerGives,gasreq]` elements, execute each snipe in sequence. Returns `(successes, takerGot, takerGave, bounty)`. 

     Note that if this function is not internal, anyone can make anyone use Mangrove. */
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
  {
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

    /* We start be enabling the reentrancy lock for this (`outbound_tkn`,`inbound_tkn`) pair. */
    sor.local = (sor.local & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffff) | bytes32((uint(1) << 248) >> 200));
    locals[outbound_tkn][inbound_tkn] = sor.local;

    /* Call recursive `internalSnipes` function. */
    internalSnipes(mor, sor, targets, 0);

    /* Over the course of the snipes order, a penalty reserved for `msg.sender` has accumulated in `mor.totalPenalty`. No actual transfers have occured yet -- all the ethers given by the makers as provision are owned by the Mangrove. `sendPenalty` finally gives the accumulated penalty to `msg.sender`. */
    sendPenalty(mor.totalPenalty);
    //+clear+

    emit OrderComplete(
      outbound_tkn,
      inbound_tkn,
      taker,
      mor.totalGot,
      mor.totalGave
    );

    return (mor.successCount, mor.totalGot, mor.totalGave, mor.totalPenalty);
  }

  /* ## Internal snipes */
  //+clear+
  /* `internalSnipes` works recursively. Going downward, each successive offer is executed until each snipe in the array has been tried. Then the reentrancy lock [is lifted](#internalSnipes/liftReentrancy). Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book.

    The last argument is the array index for the current offer. It is initially 0. */
  function internalSnipes(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    uint[4][] calldata targets,
    uint i
  ) internal {
    /* #### Case 1 : continuation of snipes */
    if (i < targets.length) {
      sor.offerId = targets[i][0];
      sor.offer = offers[sor.outbound_tkn][sor.inbound_tkn][sor.offerId];
      sor.offerDetail = offerDetails[sor.outbound_tkn][sor.inbound_tkn][
        sor.offerId
      ];

      /* If we removed the `isLive` conditional, a single expired or nonexistent offer in `targets` would revert the entire transaction (by the division by `offer.gives` below since `offer.gives` would be 0). We also check that `gasreq` is not worse than specified. A taker who does not care about `gasreq` can specify any amount larger than $2^{24}-1$. A mismatched price will be detected by `execute`. */
      if (
        !isLive(sor.offer) ||
        uint(uint((sor.offerDetail << 160)) >> 232) > targets[i][3]
      ) {
        /* We move on to the next offer in the array. */
        internalSnipes(mor, sor, targets, i + 1);
      } else {
        uint gasused;
        bytes32 makerData;
        bytes32 mgvData;

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

        /* `execute` will adjust `sor.wants`,`sor.gives`, and may attempt to execute the offer if its price is low enough. It is crucial that an error due to `taker` triggers a revert. That way [`mgvData`](#MgvOfferTaking/statusCodes) not in `["mgv/tradeSuccess","mgv/notExecuted"]` means the failure is the maker's fault. */
        /* Post-execution, `sor.wants`/`sor.gives` reflect how much was sent/taken by the offer. We will need it after the recursive call, so we save it in local variables. Same goes for `offerId`, `sor.offer` and `sor.offerDetail`. */
        (gasused, makerData, mgvData) = execute(mor, sor);

        /* In the market order, we were able to avoid stitching back offers after every `execute` since we knew a continuous segment starting at best would be consumed. Here, we cannot do this optimisation since offers in the `targets` array may be anywhere in the book. So we stitch together offers immediately after each `execute`. */
        if (mgvData != "mgv/notExecuted") {
          sor.local = stitchOffers(
            sor.outbound_tkn,
            sor.inbound_tkn,
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
        if (mgvData != "mgv/notExecuted") {
          postExecute(mor, sor, gasused, makerData, mgvData);
        }
      }
      /* #### Case 2 : End of snipes */
    } else {
      /* <a id="internalSnipes/liftReentrancy"></a> Now that the snipes is over, we can lift the lock on the book. In the same operation we
      * lift the reentrancy lock, and
      * update the storage

      so we are free from out of order storage writes.
      */
      sor.local = (sor.local & bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffff) | bytes32((uint(0) << 248) >> 200));
      locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;
      /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
      payTakerMinusFees(mor, sor);
      /* In an inverted Mangrove, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in a normal Mangrove. */
      executeEnd(mor, sor);
    }
  }

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
  {
    /* #### `Price comparison` */
    //+clear+
    /* The current offer has a price `p = offerWants ÷ offerGives` and the taker is ready to accept a price up to `p' = takerGives ÷ takerWants`. Comparing `offerWants * takerWants` and `offerGives * takerGives` tels us whether `p < p'`.
     */
    {
      uint offerWants = uint(uint((sor.offer << 48)) >> 160);
      uint offerGives = uint(uint((sor.offer << 144)) >> 160);
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
      mor.successCount += 1;
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
      if (uint(uint((sor.global << 168)) >> 248) > 0) {
        IMgvMonitor(address(uint((sor.global << 0)) >> 96)).notifySuccess(
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
        mor.failCount += 1;

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
        if (uint(uint((sor.global << 168)) >> 248) > 0) {
          IMgvMonitor(address(uint((sor.global << 0)) >> 96)).notifyFail(
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
      mgvData != "mgv/tradeSuccess"
    );
  }

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
  {
    bytes memory cd = abi.encodeWithSelector(IMaker.makerExecute.selector, sor);

    uint gasreq = uint(uint((sor.offerDetail << 160)) >> 232);
    address maker = address(uint((sor.offerDetail << 0)) >> 96);
    uint oldGas = gasleft();
    /* We let the maker pay for the overhead of checking remaining gas and making the call, as well as handling the return data (constant gas since only the first 32 bytes of return data are read). So the `require` below is just an approximation: if the overhead of (`require` + cost of `CALL`) is $h$, the maker will receive at worst $\textrm{gasreq} - \frac{63h}{64}$ gas. */
    /* Note : as a possible future feature, we could stop an order when there's not enough gas left to continue processing offers. This could be done safely by checking, as soon as we start processing an offer, whether `63/64(gasleft-overhead_gasbase-offer_gasbase) > gasreq`. If no, we could stop and know by induction that there is enough gas left to apply fees, stitch offers, etc for the offers already executed. */
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
  }

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
  ) internal {
    if (mgvData == "mgv/tradeSuccess") {
      beforePosthook(sor);
    }

    uint gasreq = uint(uint((sor.offerDetail << 160)) >> 232);

    /* We are about to call back the maker, giving it its unused gas (`gasreq - gasused`). Since the gas used so far may exceed `gasreq`, we prevent underflow in the subtraction below by bounding `gasused` above with `gasreq`. We could have decided not to call back the maker at all when there is no gas left, but we do it for uniformity. */
    if (gasused > gasreq) {
      gasused = gasreq;
    }

    gasused =
      gasused +
      makerPosthook(sor, gasreq - gasused, makerData, mgvData);

    if (mgvData != "mgv/tradeSuccess") {
      mor.totalPenalty += applyPenalty(sor, gasused, mor.failCount);
    }
  }

  /* ## beforePosthook (abstract) */
  /* Called by `makerPosthook`, this function can run implementation-specific code before calling the maker has been called a second time. In [`InvertedMangrove`](#InvertedMangrove), all makers are called once so the taker gets all of its money in one shot. Then makers are traversed again and the money is sent back to each taker using `beforePosthook`. In [`Mangrove`](#Mangrove), `beforePosthook` does nothing. */

  function beforePosthook(ML.SingleOrder memory sor) internal virtual;

  /* ## Maker Posthook */
  function makerPosthook(
    ML.SingleOrder memory sor,
    uint gasLeft,
    bytes32 makerData,
    bytes32 mgvData
  ) internal returns (uint gasused) {
    /* At this point, mgvData can only be `"mgv/tradeSuccess"`, `"mgv/makerAbort"`, `"mgv/makerRevert"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"` */
    bytes memory cd = abi.encodeWithSelector(
      IMaker.makerPosthook.selector,
      sor,
      ML.OrderResult({makerData: makerData, mgvData: mgvData})
    );

    address maker = address(uint((sor.offerDetail << 0)) >> 96);

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
  }

  /* ## `controlledCall` */
  /* Calls an external function with controlled gas expense. A direct call of the form `(,bytes memory retdata) = maker.call{gas}(selector,...args)` enables a griefing attack: the maker uses half its gas to write in its memory, then reverts with that memory segment as argument. After a low-level call, solidity automaticaly copies `returndatasize` bytes of `returndata` into memory. So the total gas consumed to execute a failing offer could exceed `gasreq + overhead_gasbase/n + offer_gasbase` where `n` is the number of failing offers. This yul call only retrieves the first 32 bytes of the maker's `returndata`. */
  function controlledCall(
    address callee,
    uint gasreq,
    bytes memory cd
  ) internal returns (bool success, bytes32 data) {
    bytes32[1] memory retdata;

    assembly {
      success := call(gasreq, callee, 0, add(cd, 32), mload(cd), retdata, 32)
    }

    data = retdata[0];
  }

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
   * Otherwise, the maker loses the cost of `gasused + overhead_gasbase/n + offer_gasbase` gas, where `n` is the number of failed offers. The gas price is estimated by `gasprice`.
   * To create the offer, the maker had to provision for `gasreq + overhead_gasbase/n + offer_gasbase` gas at a price of `offer.gasprice`.
   * We do not consider the tx.gasprice.
   * `offerDetail.gasbase` and `offer.gasprice` are the values of the Mangrove parameters `config.*_gasbase` and `config.gasprice` when the offer was created. Without caching those values, the provision set aside could end up insufficient to reimburse the maker (or to retribute the taker).
   */
  function applyPenalty(
    ML.SingleOrder memory sor,
    uint gasused,
    uint failCount
  ) internal returns (uint) {
    uint gasreq = uint(uint((sor.offerDetail << 160)) >> 232);

    uint provision = 10**9 *
      uint(uint((sor.offer << 240)) >> 240) *
      (gasreq +
        uint(uint((sor.offerDetail << 184)) >> 232) +
        uint(uint((sor.offerDetail << 208)) >> 232));

    /* We set `gasused = min(gasused,gasreq)` since `gasreq < gasused` is possible e.g. with `gasreq = 0` (all calls consume nonzero gas). */
    if (gasused > gasreq) {
      gasused = gasreq;
    }

    /* As an invariant, `applyPenalty` is only called when `mgvData` is not in `["mgv/notExecuted","mgv/tradeSuccess"]`, and thus when `failCount > 0`. */
    uint penalty = 10**9 *
      uint(uint((sor.global << 176)) >> 240) *
      (gasused +
        uint(uint((sor.local << 152)) >> 232) /
        failCount +
        uint(uint((sor.local << 176)) >> 232));

    if (penalty > provision) {
      penalty = provision;
    }

    /* Here we write to storage the new maker balance. This occurs _after_ possible reentrant calls. How do we know we're not crediting twice the same amounts? Because the `offer`'s provision was set to 0 in storage (through `dirtyDeleteOffer`) before the reentrant calls. In this function, we are working with cached copies of the offer as it was before it was consumed. */
    creditWei(address(uint((sor.offerDetail << 0)) >> 96), provision - penalty);

    return penalty;
  }

  function sendPenalty(uint amount) internal {
    if (amount > 0) {
      (bool noRevert, ) = msg.sender.call{value: amount}("");
      require(noRevert, "mgv/sendPenaltyReverted");
    }
  }

  /* Post-trade, `payTakerMinusFees` sends what's due to the taker and the rest (the fees) to the vault. Routing through the Mangrove like that also deals with blacklisting issues (separates the maker-blacklisted and the taker-blacklisted cases). */
  function payTakerMinusFees(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
  {
    /* Should be statically provable that the 2 transfers below cannot return false under well-behaved ERC20s and a non-blacklisted, non-0 target. */

    uint concreteFee = (mor.totalGot * uint(uint((sor.local << 8)) >> 240)) / 10_000;
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
  }

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
  {
    /* The `data` pointer is of the form `[mgvData,gasused,makerData]` where each array element is contiguous and has size 256 bits. */
    assembly {
      mgvData := mload(add(data, 32))
      gasused := mload(add(data, 64))
      makerData := mload(add(data, 96))
    }
  }

  /* <a id="MgvOfferTaking/innerRevert"></a>`innerRevert` reverts a raw triple of values to be interpreted by `innerDecode`.    */
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
    bytes memory cd = abi.encodeWithSelector(
      IERC20.transferFrom.selector,
      from,
      to,
      value
    );
    (bool noRevert, bytes memory data) = tokenAddress.call(cd);
    return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
  }

  function transferToken(
    address tokenAddress,
    address to,
    uint value
  ) internal returns (bool) {
    bytes memory cd = abi.encodeWithSelector(
      IERC20.transfer.selector,
      to,
      value
    );
    (bool noRevert, bytes memory data) = tokenAddress.call(cd);
    return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
  }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

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

  function approve(
    address outbound_tkn,
    address inbound_tkn,
    address spender,
    uint value
  ) external returns (bool) {
    allowances[outbound_tkn][inbound_tkn][msg.sender][spender] = value;
    emit Approval(outbound_tkn, inbound_tkn, msg.sender, spender, value);
    return true;
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

  /* # Misc. low-level functions */

  /* Used by `*For` functions, its both checks that `msg.sender` was allowed to use the taker's funds, and decreases the former's allowance. */
  function deductSenderAllowance(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    uint amount
  ) internal {
    uint allowed = allowances[outbound_tkn][inbound_tkn][owner][msg.sender];
    require(allowed >= amount, "mgv/lowAllowance");
    allowances[outbound_tkn][inbound_tkn][owner][msg.sender] = allowed - amount;
  }
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

pragma solidity ^0.7.0;
pragma abicoder v2;

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



import {MgvLib as ML, HasMgvEvents, IMgvMonitor} from "./MgvLib.sol";

/* `MgvRoot` contains state variables used everywhere in the operation of the Mangrove and their related function. */
contract MgvRoot is HasMgvEvents {
  /* # State variables */
  //+clear+
  /* The `vault` address. If a pair has fees >0, those fees are sent to the vault. */
  address public vault;

  /* Global mgv configuration, encoded in a 256 bits word. The information encoded is detailed in [`structs.js`](#structs.js). */
  bytes32 internal global;
  /* Configuration mapping for each token pair of the form `outbound_tkn => inbound_tkn => bytes32`. The structure of each `bytes32` value is detailed in [`structs.js`](#structs.js). */
  mapping(address => mapping(address => bytes32)) internal locals;

  /* Checking the size of `density` is necessary to prevent overflow when `density` is used in calculations. */
  function checkDensity(uint density) internal pure returns (bool) {
    return uint128(density) == density;
  }

  /* Checking the size of `gasprice` is necessary to prevent a) data loss when `gasprice` is copied to an `OfferDetail` struct, and b) overflow when `gasprice` is used in calculations. */
  function checkGasprice(uint gasprice) internal pure returns (bool) {
    return uint16(gasprice) == gasprice;
  }

  /* # Configuration Reads */
  /* Reading the configuration for a pair involves reading the config global to all pairs and the local one. In addition, a global parameter (`gasprice`) and a local one (`density`) may be read from the oracle. */
  function config(address outbound_tkn, address inbound_tkn)
    public
    view
    returns (bytes32 _global, bytes32 _local)
  {
    _global = global;
    _local = locals[outbound_tkn][inbound_tkn];
    if (uint(uint((_global << 160)) >> 248) > 0) {
      (uint gasprice, uint density) = IMgvMonitor(address(uint((_global << 0)) >> 96))
        .read(outbound_tkn, inbound_tkn);
      if (checkGasprice(gasprice)) {
        _global = (_global & bytes32(0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff) | bytes32((uint(gasprice) << 240) >> 176));
      }
      if (checkDensity(density)) {
        _local = (_local & bytes32(0xffffff00000000000000000000000000000000ffffffffffffffffffffffffff) | bytes32((uint(density) << 128) >> 24));
      }
    }
  }

  /* Convenience function to check whether given pair is locked */
  function locked(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (bool)
  {
    bytes32 local = locals[outbound_tkn][inbound_tkn];
    return uint(uint((local << 200)) >> 248) > 0;
  }

  /*
  # Gatekeeping

  Gatekeeping functions are safety checks called in various places.
  */

  /* `unlockedMarketOnly` protects modifying the market while an order is in progress. Since external contracts are called during orders, allowing reentrancy would, for instance, let a market maker replace offers currently on the book with worse ones. Note that the external contracts _will_ be called again after the order is complete, this time without any lock on the market.  */
  function unlockedMarketOnly(bytes32 local) internal pure {
    require(uint(uint((local << 200)) >> 248) == 0, "mgv/reentrancyLocked");
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

  /* When the Mangrove is deployed, all pairs are inactive by default (since `locals[outbound_tkn][inbound_tkn]` is 0 by default). Offers on inactive pairs cannot be taken or created. They can be updated and retracted. */
  function activeMarketOnly(bytes32 _global, bytes32 _local) internal pure {
    liveMgvOnly(_global);
    require(uint(uint((_local << 0)) >> 248) > 0, "mgv/inactive");
  }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier:	BSD-2-Clause

// Basic.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



import "../Persistent.sol";

contract Reposting is Persistent {
  constructor(address payable _MGV) MangroveOffer(_MGV) {}

  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    override
  {
    address token0 = order.outbound_tkn;
    address token1 = order.inbound_tkn;
    (, , uint wants, uint gives, uint gasprice) = MP.offer_unpack(order.offer); // amount with token1.decimals() decimals
    uint gasreq = MP.offerDetail_unpack_gasreq(order.offerDetail); // amount with token1.decimals() decimals

    try
      this.updateOffer({
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
    } catch {
      emit PosthookFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        "unexpected"
      );
    }
  }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import "../lib/AccessControlled.sol";
import "../lib/Exponential.sol";
import "../lib/TradeHandler.sol";
import "../lib/consolerr/consolerr.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
contract MangroveOffer is AccessControlled, IMaker, TradeHandler, Exponential {
  Mangrove immutable MGV; // Address of the deployed Mangrove contract

  // default values
  uint public OFR_GASREQ = 1_000_000;

  receive() external payable {}

  // Offer constructor (caller will be admin)
  constructor(address _MGV) {
    (bytes32 global_pack, ) = Mangrove(payable(_MGV)).config(
      address(0),
      address(0)
    );
    uint dead = MP.global_unpack_dead(global_pack);
    require(dead == 0, "Mangrove contract is permanently disabled"); //sanity check
    MGV = Mangrove(payable(_MGV));
  }

  /// transfers token stored in `this` contract to some recipient address
  function transferToken(
    address token,
    address recipient,
    uint amount
  ) external onlyAdmin returns (bool success) {
    success = IERC20(token).transfer(recipient, amount);
  }

  /// trader needs to approve Mangrove to let it perform outbound token transfer at the end of the `makerExecute` function
  function approveMangrove(address outbound_tkn, uint amount)
    external
    onlyAdmin
  {
    require(
      IERC20(outbound_tkn).approve(address(MGV), amount),
      "Failed to approve Mangrove"
    );
  }

  /// withdraws ETH from the bounty vault of the Mangrove.
  /// NB: `Mangrove.fund` function need not be called by `this` so is not included here.
  function withdraw(address receiver, uint amount)
    external
    onlyAdmin
    returns (bool noRevert)
  {
    require(MGV.withdraw(amount));
    require(receiver != address(0), "Cannot transfer WEIs to 0x0 address");
    (noRevert, ) = receiver.call{value: amount}("");
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
  ) external internalOrAdmin returns (uint offerId) {
    if (gasreq == type(uint).max) {
      gasreq = OFR_GASREQ;
    }
    uint missing = __autoRefill__(
      outbound_tkn,
      inbound_tkn,
      gasreq,
      gasprice,
      0
    );
    if (missing > 0) {
      consolerr.errorUint("mgvOffer/new/outOfFunds: ", missing);
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
  //  The `__autoRefill__` hook may be overridden to provide a method to refill offer provision automatically.
  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external internalOrAdmin {
    uint missing = __autoRefill__(
      outbound_tkn,
      inbound_tkn,
      gasreq,
      gasprice,
      offerId
    );
    if (missing > 0) {
      consolerr.errorUint("mgvOffer/update/outOfFunds: ", missing);
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
  ) external internalOrAdmin returns (uint) {
    return MGV.retractOffer(outbound_tkn, inbound_tkn, offerId, deprovision);
  }

  // Returns the amount of WEI necessary to (re)provision the (re)posting of offer `offerID` in the (`outbound_tkn, inbound_tkn`) Offer List.
  // If `OfferId` is not in the Offer List (possibly not live), the returned amount is the amount needed to post a fresh offer.
  function getMissingProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) public view returns (uint) {
    return
      getMissingProvision(
        MGV,
        outbound_tkn,
        inbound_tkn,
        gasreq,
        gasprice,
        offerId
      );
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
      return RENEGED;
    }
    __put__(IERC20(order.inbound_tkn), order.gives); // implements what should be done with the liquidity that is flashswapped by the offer taker to `this` contract
    uint missingGet = __get__(IERC20(order.outbound_tkn), order.wants); // implements how `this` contract should make the outbound tokens available
    if (missingGet > 0) {
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

  // Override this hook to let the offer refill its provision on Mangrove (provided `this` contract has enough ETH).
  // Use this hook to increase outbound token approval for Mangrove when the Offer Maker wishes to keep it tight.
  // return value `missingETH` should be 0 if `offerId` doesn't lack provision.
  function __autoRefill__(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq, // gas required by the offer to be reposted
    uint gasprice, // gas price for the computation of the bounty
    uint offerId // ID of the offer to be updated.
  ) internal virtual returns (uint missingETH) {
    outbound_tkn; //shh
    inbound_tkn;
    gasreq;
    gasprice;
    offerId;
  }

  // Override this hook to describe where the inbound token, which are flashswapped by the Offer Taker, should go during Taker Order's execution.
  // `amount` is the quantity of outbound tokens whose destination is to be resolved.
  // All tokens that are not transfered to a different contract remain listed in the balance of `this` contract
  function __put__(IERC20 inbound_tkn, uint amount) internal virtual {
    /// @notice receive payment is just stored at this address
    inbound_tkn; //shh
    amount;
  }

  // Override this hook to implement fetching `amount` of outbound tokens, possibly from another source than `this` contract during Taker Order's execution.
  // For composability, return value MUST be the remaining quantity (i.e <= `amount`) of tokens remaining to be fetched.
  function __get__(IERC20 outbound_tkn, uint amount)
    internal
    virtual
    returns (uint)
  {
    uint local = outbound_tkn.balanceOf(address(this));
    return (local > amount ? 0 : amount - local);
  }

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
    uint missing = order.wants -
      IERC20(order.outbound_tkn).balanceOf(address(this));
    emit NotEnoughLiquidity(order.outbound_tkn, missing);
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
    emit PosthookFail(
      order.outbound_tkn,
      order.inbound_tkn,
      order.offerId,
      string(bytesOfWord(result.mgvData))
    );
  }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier:	BSD-2-Clause

// Persistent.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import "./MangroveOffer.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract Persistent is MangroveOffer {
  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
  {
    uint new_gives = MP.offer_unpack_gives(order.offer) - order.wants;
    uint new_wants = MP.offer_unpack_wants(order.offer) - order.gives;
    try
      this.updateOffer(
        order.outbound_tkn,
        order.inbound_tkn,
        new_wants,
        new_gives,
        MP.offerDetail_unpack_gasreq(order.offerDetail),
        MP.offer_unpack_gasprice(order.offer),
        MP.offer_unpack_next(order.offer),
        order.offerId
      )
    {} catch Error(string memory message) {
      emit PosthookFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        message
      );
    } catch {
      emit PosthookFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        "Unexpected reason"
      );
    }
  }

  function __autoRefill__(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) internal virtual override returns (uint) {
    uint toAdd = getMissingProvision(
      outbound_tkn,
      inbound_tkn,
      gasreq,
      gasprice,
      offerId
    );
    if (toAdd > 0) {
      try MGV.fund{value: toAdd}() {
        return 0;
      } catch {
        return toAdd;
      }
    }
    return 0;
  }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier:	BSD-2-Clause

// AccessedControlled.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



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

pragma solidity ^0.7.0;

// SPDX-License-Identifier:	BSD-3-Clause

// Copyright 2020 Compound Labs, Inc.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


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
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
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

    uint constant MAXUINT = uint(-1);
    uint constant MAXUINT96 = uint96(-1);
    uint constant MAXUINT24 = uint24(-1);
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier:	BSD-3-Clause

// Copyright 2020 Compound Labs, Inc.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



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
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
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
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
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
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
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
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier:	BSD-3-Clause

// Copyright 2020 Compound Labs, Inc.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



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
    uint constant halfExpScale = expScale/2;
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
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier:	BSD-2-Clause

// TradeHandler.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



import {MgvPack as MP} from "../../MgvPack.sol";
import "../../Mangrove.sol";
import "../../MgvLib.sol";

import "hardhat/console.sol";

contract TradeHandler {
  // internal bytes32 to select appropriate posthook
  bytes32 constant RENEGED = "mgvOffer/reneged";
  bytes32 constant OUTOFLIQUIDITY = "mgvOffer/outOfLiquidity";

  // to wrap potentially reverting calls to mangrove
  event PosthookFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId,
    string message
  );

  event NotEnoughLiquidity(address token, uint amountMissing);
  event PostHookError(address outbound_tkn, address inbound_tkn, uint offerId);

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
    gasreq = MP.offerDetail_unpack_gasreq(order.offerDetail);
    (, , offer_wants, offer_gives, gasprice) = MP.offer_unpack(order.offer);
  }

  function getMissingProvision(
    Mangrove mgv,
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) internal view returns (uint) {
    (bytes32 globalData, bytes32 localData) = mgv.config(
      outbound_tkn,
      inbound_tkn
    );
    bytes32 offerData = mgv.offers(outbound_tkn, inbound_tkn, offerId);
    bytes32 offerDetailData = mgv.offerDetails(
      outbound_tkn,
      inbound_tkn,
      offerId
    );
    uint _gp;
    if (MP.global_unpack_gasprice(globalData) > gasprice) {
      _gp = MP.global_unpack_gasprice(globalData);
    } else {
      _gp = gasprice;
    }
    uint bounty = (gasreq +
      MP.local_unpack_overhead_gasbase(localData) +
      MP.local_unpack_offer_gasbase(localData)) *
      _gp *
      10**9; // in WEI
    uint currentProvisionLocked = (MP.offerDetail_unpack_gasreq(
      offerDetailData
    ) +
      MP.offerDetail_unpack_overhead_gasbase(offerDetailData) +
      MP.offerDetail_unpack_offer_gasbase(offerDetailData)) *
      MP.offer_unpack_gasprice(offerData) *
      10**9;
    uint currentProvision = currentProvisionLocked +
      mgv.balanceOf(address(this));
    return (currentProvision >= bounty ? 0 : bounty - currentProvision);
  }

  //queries the mangrove to get current gasprice (considered to compute bounty)
  function getCurrentGasPrice(Mangrove mgv) internal view returns (uint) {
    (bytes32 global_pack, ) = mgv.config(address(0), address(0));
    return MP.global_unpack_gasprice(global_pack);
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

pragma solidity >=0.6.10 <0.8.0;



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