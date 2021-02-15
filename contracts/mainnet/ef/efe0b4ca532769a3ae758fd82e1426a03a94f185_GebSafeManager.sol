/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

abstract contract SAFEEngineLike {
    function safes(bytes32, address) virtual public view returns (uint, uint);
    function approveSAFEModification(address) virtual public;
    function transferCollateral(bytes32, address, address, uint) virtual public;
    function transferInternalCoins(address, address, uint) virtual public;
    function modifySAFECollateralization(bytes32, address, address, address, int, int) virtual public;
    function transferSAFECollateralAndDebt(bytes32, address, address, int, int) virtual public;
}

abstract contract LiquidationEngineLike {
    function protectSAFE(bytes32, address, address) virtual external;
}

contract SAFEHandler {
    constructor(address safeEngine) public {
        SAFEEngineLike(safeEngine).approveSAFEModification(msg.sender);
    }
}

contract GebSafeManager {
    address                   public safeEngine;
    uint                      public safei;               // Auto incremental
    mapping (uint => address) public safes;               // SAFEId => SAFEHandler
    mapping (uint => List)    public safeList;            // SAFEId => Prev & Next SAFEIds (double linked list)
    mapping (uint => address) public ownsSAFE;            // SAFEId => Owner
    mapping (uint => bytes32) public collateralTypes;     // SAFEId => CollateralType

    mapping (address => uint) public firstSAFEID;         // Owner => First SAFEId
    mapping (address => uint) public lastSAFEID;          // Owner => Last SAFEId
    mapping (address => uint) public safeCount;           // Owner => Amount of SAFEs

    mapping (
        address => mapping (
            uint => mapping (
                address => uint
            )
        )
    ) public safeCan;                            // Owner => SAFEId => Allowed Addr => True/False

    mapping (
        address => mapping (
            address => uint
        )
    ) public handlerCan;                        // SAFE handler => Allowed Addr => True/False

    struct List {
        uint prev;
        uint next;
    }

    // --- Events ---
    event AllowSAFE(
        address sender,
        uint safe,
        address usr,
        uint ok
    );
    event AllowHandler(
        address sender,
        address usr,
        uint ok
    );
    event TransferSAFEOwnership(
        address sender,
        uint safe,
        address dst
    );
    event OpenSAFE(address indexed sender, address indexed own, uint indexed safe);
    event ModifySAFECollateralization(
        address sender,
        uint safe,
        int deltaCollateral,
        int deltaDebt
    );
    event TransferCollateral(
        address sender,
        uint safe,
        address dst,
        uint wad
    );
    event TransferCollateral(
        address sender,
        bytes32 collateralType,
        uint safe,
        address dst,
        uint wad
    );
    event TransferInternalCoins(
        address sender,
        uint safe,
        address dst,
        uint rad
    );
    event QuitSystem(
        address sender,
        uint safe,
        address dst
    );
    event EnterSystem(
        address sender,
        address src,
        uint safe
    );
    event MoveSAFE(
        address sender,
        uint safeSrc,
        uint safeDst
    );
    event ProtectSAFE(
        address sender,
        uint safe,
        address liquidationEngine,
        address saviour
    );

    modifier safeAllowed(
        uint safe
    ) {
        require(msg.sender == ownsSAFE[safe] || safeCan[ownsSAFE[safe]][safe][msg.sender] == 1, "safe-not-allowed");
        _;
    }

    modifier handlerAllowed(
        address handler
    ) {
        require(
          msg.sender == handler ||
          handlerCan[handler][msg.sender] == 1,
          "internal-system-safe-not-allowed"
        );
        _;
    }

    constructor(address safeEngine_) public {
        safeEngine = safeEngine_;
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0);
    }

    // --- SAFE Manipulation ---

    // Allow/disallow a usr address to manage the safe
    function allowSAFE(
        uint safe,
        address usr,
        uint ok
    ) public safeAllowed(safe) {
        safeCan[ownsSAFE[safe]][safe][usr] = ok;
        emit AllowSAFE(
            msg.sender,
            safe,
            usr,
            ok
        );
    }

    // Allow/disallow a usr address to quit to the sender handler
    function allowHandler(
        address usr,
        uint ok
    ) public {
        handlerCan[msg.sender][usr] = ok;
        emit AllowHandler(
            msg.sender,
            usr,
            ok
        );
    }

    // Open a new safe for a given usr address.
    function openSAFE(
        bytes32 collateralType,
        address usr
    ) public returns (uint) {
        require(usr != address(0), "usr-address-0");

        safei = add(safei, 1);
        safes[safei] = address(new SAFEHandler(safeEngine));
        ownsSAFE[safei] = usr;
        collateralTypes[safei] = collateralType;

        // Add new SAFE to double linked list and pointers
        if (firstSAFEID[usr] == 0) {
            firstSAFEID[usr] = safei;
        }
        if (lastSAFEID[usr] != 0) {
            safeList[safei].prev = lastSAFEID[usr];
            safeList[lastSAFEID[usr]].next = safei;
        }
        lastSAFEID[usr] = safei;
        safeCount[usr] = add(safeCount[usr], 1);

        emit OpenSAFE(msg.sender, usr, safei);
        return safei;
    }

    // Give the safe ownership to a dst address.
    function transferSAFEOwnership(
        uint safe,
        address dst
    ) public safeAllowed(safe) {
        require(dst != address(0), "dst-address-0");
        require(dst != ownsSAFE[safe], "dst-already-owner");

        // Remove transferred SAFE from double linked list of origin user and pointers
        if (safeList[safe].prev != 0) {
            safeList[safeList[safe].prev].next = safeList[safe].next;    // Set the next pointer of the prev safe (if exists) to the next of the transferred one
        }
        if (safeList[safe].next != 0) {                               // If wasn't the last one
            safeList[safeList[safe].next].prev = safeList[safe].prev;    // Set the prev pointer of the next safe to the prev of the transferred one
        } else {                                                    // If was the last one
            lastSAFEID[ownsSAFE[safe]] = safeList[safe].prev;            // Update last pointer of the owner
        }
        if (firstSAFEID[ownsSAFE[safe]] == safe) {                      // If was the first one
            firstSAFEID[ownsSAFE[safe]] = safeList[safe].next;           // Update first pointer of the owner
        }
        safeCount[ownsSAFE[safe]] = sub(safeCount[ownsSAFE[safe]], 1);

        // Transfer ownership
        ownsSAFE[safe] = dst;

        // Add transferred SAFE to double linked list of destiny user and pointers
        safeList[safe].prev = lastSAFEID[dst];
        safeList[safe].next = 0;
        if (lastSAFEID[dst] != 0) {
            safeList[lastSAFEID[dst]].next = safe;
        }
        if (firstSAFEID[dst] == 0) {
            firstSAFEID[dst] = safe;
        }
        lastSAFEID[dst] = safe;
        safeCount[dst] = add(safeCount[dst], 1);

        emit TransferSAFEOwnership(
            msg.sender,
            safe,
            dst
        );
    }

    // Modify a SAFE's collateralization ratio while keeping the generated COIN or collateral freed in the SAFE handler address.
    function modifySAFECollateralization(
        uint safe,
        int deltaCollateral,
        int deltaDebt
    ) public safeAllowed(safe) {
        address safeHandler = safes[safe];
        SAFEEngineLike(safeEngine).modifySAFECollateralization(
            collateralTypes[safe],
            safeHandler,
            safeHandler,
            safeHandler,
            deltaCollateral,
            deltaDebt
        );
        emit ModifySAFECollateralization(
            msg.sender,
            safe,
            deltaCollateral,
            deltaDebt
        );
    }

    // Transfer wad amount of safe collateral from the safe address to a dst address.
    function transferCollateral(
        uint safe,
        address dst,
        uint wad
    ) public safeAllowed(safe) {
        SAFEEngineLike(safeEngine).transferCollateral(collateralTypes[safe], safes[safe], dst, wad);
        emit TransferCollateral(
            msg.sender,
            safe,
            dst,
            wad
        );
    }

    // Transfer wad amount of any type of collateral (collateralType) from the safe address to a dst address.
    // This function has the purpose to take away collateral from the system that doesn't correspond to the safe but was sent there wrongly.
    function transferCollateral(
        bytes32 collateralType,
        uint safe,
        address dst,
        uint wad
    ) public safeAllowed(safe) {
        SAFEEngineLike(safeEngine).transferCollateral(collateralType, safes[safe], dst, wad);
        emit TransferCollateral(
            msg.sender,
            collateralType,
            safe,
            dst,
            wad
        );
    }

    // Transfer rad amount of COIN from the safe address to a dst address.
    function transferInternalCoins(
        uint safe,
        address dst,
        uint rad
    ) public safeAllowed(safe) {
        SAFEEngineLike(safeEngine).transferInternalCoins(safes[safe], dst, rad);
        emit TransferInternalCoins(
            msg.sender,
            safe,
            dst,
            rad
        );
    }

    // Quit the system, migrating the safe (lockedCollateral, generatedDebt) to a different dst handler
    function quitSystem(
        uint safe,
        address dst
    ) public safeAllowed(safe) handlerAllowed(dst) {
        (uint lockedCollateral, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralTypes[safe], safes[safe]);
        int deltaCollateral = toInt(lockedCollateral);
        int deltaDebt = toInt(generatedDebt);
        SAFEEngineLike(safeEngine).transferSAFECollateralAndDebt(
            collateralTypes[safe],
            safes[safe],
            dst,
            deltaCollateral,
            deltaDebt
        );
        emit QuitSystem(
            msg.sender,
            safe,
            dst
        );
    }

    // Import a position from src handler to the handler owned by safe
    function enterSystem(
        address src,
        uint safe
    ) public handlerAllowed(src) safeAllowed(safe) {
        (uint lockedCollateral, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralTypes[safe], src);
        int deltaCollateral = toInt(lockedCollateral);
        int deltaDebt = toInt(generatedDebt);
        SAFEEngineLike(safeEngine).transferSAFECollateralAndDebt(
            collateralTypes[safe],
            src,
            safes[safe],
            deltaCollateral,
            deltaDebt
        );
        emit EnterSystem(
            msg.sender,
            src,
            safe
        );
    }

    // Move a position from safeSrc handler to the safeDst handler
    function moveSAFE(
        uint safeSrc,
        uint safeDst
    ) public safeAllowed(safeSrc) safeAllowed(safeDst) {
        require(collateralTypes[safeSrc] == collateralTypes[safeDst], "non-matching-safes");
        (uint lockedCollateral, uint generatedDebt) = SAFEEngineLike(safeEngine).safes(collateralTypes[safeSrc], safes[safeSrc]);
        int deltaCollateral = toInt(lockedCollateral);
        int deltaDebt = toInt(generatedDebt);
        SAFEEngineLike(safeEngine).transferSAFECollateralAndDebt(
            collateralTypes[safeSrc],
            safes[safeSrc],
            safes[safeDst],
            deltaCollateral,
            deltaDebt
        );
        emit MoveSAFE(
            msg.sender,
            safeSrc,
            safeDst
        );
    }

    // Choose a SAFE saviour inside LiquidationEngine for the SAFE with id 'safe'
    function protectSAFE(
        uint safe,
        address liquidationEngine,
        address saviour
    ) public safeAllowed(safe) {
        LiquidationEngineLike(liquidationEngine).protectSAFE(
            collateralTypes[safe],
            safes[safe],
            saviour
        );
        emit ProtectSAFE(
            msg.sender,
            safe,
            liquidationEngine,
            saviour
        );
    }
}