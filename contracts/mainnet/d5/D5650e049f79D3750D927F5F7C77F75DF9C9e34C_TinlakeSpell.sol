/**
 *Submitted for verification at Etherscan.io on 2021-03-30
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

interface ShelfLike {
    function depend(bytes32 contractName, address addr) external;
}

interface RootLike {
    function relyContract(address, address) external;
    function deploy() external;
}

// This spell fixes the wiring of the shelf of the PZ1 pool
contract TinlakeSpell {

    bool public done;
    string constant public description = "Fix for the PZ1 shelf wiring";

    // PZ1 contracts
    address constant public ROOT = 0x92332a9831AC04275bC0f22b9140b21c72984EB8;
    address constant public SHELF = 0xBd9F2C1B2983e7923b3029c11BA485496F938564;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address wCUSD = 0xad3E3Fc59dff318BecEaAb7D00EB4F68b1EcF195;

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        ShelfLike(SHELF).depend("token", DAI);
        ShelfLike(SHELF).depend("lender", ROOT);
        ShelfLike(SHELF).depend("token", wCUSD);
    }   
}