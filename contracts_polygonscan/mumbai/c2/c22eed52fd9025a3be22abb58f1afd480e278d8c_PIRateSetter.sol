/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// Verified using https://dapp.tools

// hevm: flattened sources of /nix/store/bna431n14gaiilbd4nj2wsgpa08vq265-geb-rrfm-rate-setter/dapp/geb-rrfm-rate-setter/src/PIRateSetter.sol

pragma solidity =0.6.7;

////// /nix/store/npsy3mivgrrb261vicfv9nqb6dza0y3c-geb-treasury-reimbursement/dapp/geb-treasury-reimbursement/src/math/GebMath.sol
/* pragma solidity 0.6.7; */

contract GebMath {
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant WAD = 10 ** 18;

    function ray(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 9);
    }
    function rad(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 27);
    }
    function minimum(uint x, uint y) public pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function addition(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function rmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rpower(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

////// /nix/store/bna431n14gaiilbd4nj2wsgpa08vq265-geb-rrfm-rate-setter/dapp/geb-rrfm-rate-setter/src/PIRateSetter.sol
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC, Reflexer Labs, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

/* import "geb-treasury-reimbursement/math/GebMath.sol"; */

abstract contract OracleLike_2 {
    function getResultWithValidity() virtual external view returns (uint256, bool);
}
abstract contract OracleRelayerLike_2 {
    function redemptionPrice() virtual external returns (uint256);
}
abstract contract SetterRelayer_2 {
    function relayRate(uint256, address) virtual external;
}
abstract contract PIDCalculator_1 {
    function computeRate(uint256, uint256, uint256) virtual external returns (uint256);
    function rt(uint256, uint256, uint256) virtual external view returns (uint256);
    function pscl() virtual external view returns (uint256);
    function tlv() virtual external view returns (uint256);
}

contract PIRateSetter is GebMath {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "PIRateSetter/account-not-authorized");
        _;
    }

    // --- Variables ---
    // When the price feed was last updated
    uint256 public lastUpdateTime;                  // [timestamp]
    // Enforced gap between calls
    uint256 public updateRateDelay;                 // [seconds]
    // Whether the leak is set to zero by default
    uint256 public defaultLeak;                     // [0 or 1]

    // --- System Dependencies ---
    // OSM or medianizer for the system coin
    OracleLike_2                public orcl;
    // OracleRelayer where the redemption price is stored
    OracleRelayerLike_2         public oracleRelayer;
    // The contract that will pass the new redemption rate to the oracle relayer
    SetterRelayer_2             public setterRelayer;
    // Calculator for the redemption rate
    PIDCalculator_1             public pidCalculator;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    event ModifyParameters(
      bytes32 parameter,
      uint256 val
    );
    event UpdateRedemptionRate(
        uint marketPrice,
        uint redemptionPrice,
        uint redemptionRate
    );
    event FailUpdateRedemptionRate(
        uint marketPrice,
        uint redemptionPrice,
        uint redemptionRate,
        bytes reason
    );

    constructor(
      address oracleRelayer_,
      address setterRelayer_,
      address orcl_,
      address pidCalculator_,
      uint256 updateRateDelay_
    ) public {
        require(oracleRelayer_ != address(0), "PIRateSetter/null-oracle-relayer");
        require(setterRelayer_ != address(0), "PIRateSetter/null-setter-relayer");
        require(orcl_ != address(0), "PIRateSetter/null-orcl");
        require(pidCalculator_ != address(0), "PIRateSetter/null-calculator");

        authorizedAccounts[msg.sender] = 1;
        defaultLeak                    = 1;

        oracleRelayer    = OracleRelayerLike_2(oracleRelayer_);
        setterRelayer    = SetterRelayer_2(setterRelayer_);
        orcl             = OracleLike_2(orcl_);
        pidCalculator    = PIDCalculator_1(pidCalculator_);

        updateRateDelay  = updateRateDelay_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("orcl", orcl_);
        emit ModifyParameters("oracleRelayer", oracleRelayer_);
        emit ModifyParameters("setterRelayer", setterRelayer_);
        emit ModifyParameters("pidCalculator", pidCalculator_);
        emit ModifyParameters("updateRateDelay", updateRateDelay_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Management ---
    /*
    * @notify Modify the address of a contract that the setter is connected to
    * @param parameter Contract name
    * @param addr The new contract address
    */
    function modifyParameters(bytes32 parameter, address addr) external isAuthorized {
        require(addr != address(0), "PIRateSetter/null-addr");
        if (parameter == "orcl") orcl = OracleLike_2(addr);
        else if (parameter == "oracleRelayer") oracleRelayer = OracleRelayerLike_2(addr);
        else if (parameter == "setterRelayer") setterRelayer = SetterRelayer_2(addr);
        else if (parameter == "pidCalculator") {
          pidCalculator = PIDCalculator_1(addr);
        }
        else revert("PIRateSetter/modify-unrecognized-param");
        emit ModifyParameters(
          parameter,
          addr
        );
    }
    /*
    * @notify Modify a uint256 parameter
    * @param parameter The parameter name
    * @param val The new parameter value
    */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "updateRateDelay") {
          require(val > 0, "PIRateSetter/null-update-delay");
          updateRateDelay = val;
        }
        else if (parameter == "defaultLeak") {
          require(val <= 1, "PIRateSetter/invalid-default-leak");
          defaultLeak = val;
        }
        else revert("PIRateSetter/modify-unrecognized-param");
        emit ModifyParameters(
          parameter,
          val
        );
    }

    // --- Feedback Mechanism ---
    /**
    * @notice Compute and set a new redemption rate
    * @param feeReceiver The proposed address that should receive the reward for calling this function
    *        (unless it's address(0) in which case msg.sender will get it)
    **/
    function updateRate(address feeReceiver) external {
        // The fee receiver must not be null
        require(feeReceiver != address(0), "PIRateSetter/null-fee-receiver");
        // Check delay between calls
        require(either(subtract(now, lastUpdateTime) >= updateRateDelay, lastUpdateTime == 0), "PIRateSetter/wait-more");
        // Get price feed updates
        (uint256 marketPrice, bool hasValidValue) = orcl.getResultWithValidity();
        // If the oracle has a value
        require(hasValidValue, "PIRateSetter/invalid-oracle-value");
        // If the price is non-zero
        require(marketPrice > 0, "PIRateSetter/null-price");
        // Get the latest redemption price
        uint redemptionPrice = oracleRelayer.redemptionPrice();
        // Calculate the rate
        uint256 iapcr      = (defaultLeak == 1) ? RAY : rpower(pidCalculator.pscl(), pidCalculator.tlv(), RAY);
        uint256 calculated = pidCalculator.computeRate(
            marketPrice,
            redemptionPrice,
            iapcr
        );
        // Store the timestamp of the update
        lastUpdateTime = now;
        // Update the rate using the setter relayer
        try setterRelayer.relayRate(calculated, feeReceiver) {
          // Emit success event
          emit UpdateRedemptionRate(
            ray(marketPrice),
            redemptionPrice,
            calculated
          );
        }
        catch(bytes memory revertReason) {
          emit FailUpdateRedemptionRate(
            ray(marketPrice),
            redemptionPrice,
            calculated,
            revertReason
          );
        }
    }

    // --- Getters ---
    /**
    * @notice Get the market price from the system coin oracle
    **/
    function getMarketPrice() external view returns (uint256) {
        (uint256 marketPrice, ) = orcl.getResultWithValidity();
        return marketPrice;
    }
    /**
    * @notice Get the redemption and the market prices for the system coin
    **/
    function getRedemptionAndMarketPrices() external returns (uint256 marketPrice, uint256 redemptionPrice) {
        (marketPrice, ) = orcl.getResultWithValidity();
        redemptionPrice = oracleRelayer.redemptionPrice();
    }
}