/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol
pragma solidity =0.6.7;

////// src/spell.sol
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
/* pragma solidity 0.6.7; */

interface TinlakeRootLike {
    function relyContract(address, address) external;
}

interface ReserveLike {
    function payout(uint amount) external;
}

interface ERC20Like {
    function transferFrom(address from, address to, uint amount) external;
}

// Database Finance Reserve transfer spell
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake Mainnet Spell";

    // Database Finance
    address constant public ROOT = 0xfc2950dD337ca8496C18dfc0256Fb905A7E7E5c6;
    address constant public RESERVE = 0x729e12cDc0190A2e4Ab4401bca4C16132d75AdC5;
    address constant public CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant public SENIOR_TRANCHE = 0x68d2e0c8166d746f7Fd3a6Bad5bEF05c9EF69b9F;

    uint constant public payoutAmount = 14653858411942951370300;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRootLike root = TinlakeRootLike(ROOT);
        root.relyContract(RESERVE, address(this));

        ReserveLike(RESERVE).payout(payoutAmount);
        ERC20Like(CURRENCY).transferFrom(address(this), SENIOR_TRANCHE, payoutAmount);
    }
}