/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// Copyright (C) 2020 Centrifuge
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
pragma solidity >=0.5.15 <0.6.0;

interface TrancheLike {
    function supplyOrder(address usr, uint currencyAmount) external;
    function redeemOrder(address usr, uint tokenAmount) external;
    function disburse(address usr) external returns (uint payoutCurrencyAmount,
        uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken);
}

contract TrancheWorker {
    mapping (address => uint) public wards;
    function rely(address usr) public auth { wards[usr] = 1; }
    function deny(address usr) public auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    constructor () public {
        wards[msg.sender] = 1;
    }

    function disburse(address tranche, address usr) public auth returns (uint payoutCurrencyAmount,
        uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken) {
        return TrancheLike(tranche).disburse(usr);
    }

    function cancelSupplyOrder(address tranche, address usr) public auth {
        TrancheLike(tranche).supplyOrder(usr, 0);
    }

    function cancelRedeemOrder(address tranche, address usr) public auth {
        TrancheLike(tranche).redeemOrder(usr, 0);
    }
}