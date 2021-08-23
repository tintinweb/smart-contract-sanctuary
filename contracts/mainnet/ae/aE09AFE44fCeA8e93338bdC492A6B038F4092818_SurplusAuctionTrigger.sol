/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

/// SurplusAuctionTrigger.sol

// Copyright (C) 2021 Reflexer Labs, INC
//
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
    function approveSAFEModification(address) virtual external;
    function coinBalance(address) virtual public view returns (uint256);
    function transferInternalCoins(address,address,uint256) virtual external;
}
abstract contract SurplusAuctionHouseLike {
    function startAuction(uint256, uint256) virtual public returns (uint256);
    function contractEnabled() virtual public returns (uint256);
}
abstract contract AccountingEngineLike {
    function contractEnabled() virtual public returns (uint256);
}

contract SurplusAuctionTrigger {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
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
        require(authorizedAccounts[msg.sender] == 1, "SurplusAuctionTrigger/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Amount of surplus stability fees sold in one surplus auction
    uint256                    public surplusAuctionAmountToSell; // [rad]

    // SAFE database
    SAFEEngineLike             public safeEngine;
    // Contract that handles auctions for surplus stability fees
    SurplusAuctionHouseLike    public surplusAuctionHouse;
    // Accounting engine contract
    AccountingEngineLike       public accountingEngine;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event AuctionSurplus(uint256 indexed id, uint256 coinBalance);
    event TransferSurplus(address dst, uint256 surplusAmount);

    constructor(
      address safeEngine_,
      address surplusAuctionHouse_,
      address accountingEngine_,
      uint256 surplusAuctionAmountToSell_
    ) public {
        require(safeEngine_ != address(0), "SurplusAuctionTrigger/null-safe-engine");
        require(surplusAuctionHouse_ != address(0), "SurplusAuctionTrigger/null-surplus-auction-house");
        require(accountingEngine_ != address(0), "SurplusAuctionTrigger/null-accounting-engine");

        authorizedAccounts[msg.sender] = 1;

        safeEngine                 = SAFEEngineLike(safeEngine_);
        surplusAuctionHouse        = SurplusAuctionHouseLike(surplusAuctionHouse_);
        accountingEngine           = AccountingEngineLike(accountingEngine_);
        surplusAuctionAmountToSell = surplusAuctionAmountToSell_;

        safeEngine.approveSAFEModification(surplusAuctionHouse_);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /**
     * @notice Start a new surplus auction
    **/
    function auctionSurplus() external returns (uint256 id) {
        require(
          safeEngine.coinBalance(address(this)) >= surplusAuctionAmountToSell, "SurplusAuctionTrigger/insufficient-surplus"
        );
        id = surplusAuctionHouse.startAuction(surplusAuctionAmountToSell, 0);
        emit AuctionSurplus(id, safeEngine.coinBalance(address(this)));
    }
    /**
    * @notice Transfer surplus out of this contract if you're an authed address
    * @param dst Destination address
    * @param surplusAmount Amount of surplus to transfer
    **/
    function transferSurplus(address dst, uint256 surplusAmount) external isAuthorized {
        require(
          either(accountingEngine.contractEnabled() == 0, surplusAuctionHouse.contractEnabled() == 0),
          "SurplusAuctionTrigger/cannot-transfer-surplus"
        );

        surplusAuctionHouse.contractEnabled() == 0;
        safeEngine.transferInternalCoins(address(this), dst, surplusAmount);
        emit TransferSurplus(dst, surplusAmount);
    }
}