/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

pragma solidity >=0.6.12;

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
/* pragma solidity >=0.6.12; */

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface NAVFeedLike {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) external;
    function discountRate() external returns(uint);
}

// This spell makes changes to the tinlake mainnet FF1 deployment:
// adds new risk groups 
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake CF4 Mainnet Spell - 3";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address constant public ROOT = 0x4B6CA198d257D755A5275648D471FE09931b764A;
    address constant public NAV_FEED = 0xcAB9ed8e5EF4607A97f4e22Ad1D984ADB93ce890;
                                                             
    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        TinlakeRootLike root = TinlakeRootLike(address(ROOT));
        NAVFeedLike navFeed = NAVFeedLike(address(NAV_FEED));
        self = address(this);
        // NavFeed 
        root.relyContract(NAV_FEED, self); // required to file riskGroups & change discountRate

        // risk group: 6 - PP A, APR: 5.35%, APY: 5.50%
        navFeed.file("riskGroup", 6, ONE, ONE, uint(1000000001696470000000000000), 99.5*10**25);
        // risk group: 7 - PP BBB, APR: 5.83%, APY: 6.00%
        navFeed.file("riskGroup", 7, ONE, ONE, uint(1000000001848680000000000000), 99.5*10**25);
        // risk group: 8 - PP BB, APR: 6.3%, , APY: 6.50%
        navFeed.file("riskGroup", 8, ONE, ONE, uint(1000000001997720000000000000), 99.5*10**25);
        // risk group: 9 - PP B, APR: 6.77%, APY: 7.00%
        navFeed.file("riskGroup", 9, ONE, ONE, uint(1000000002146750000000000000), 99.5*10**25);
        // risk group: 10 - CRL, APR: 13.98%, APY: 15.00%
        navFeed.file("riskGroup", 10, ONE, ONE, uint(1000000004433030000000000000), 98.5*10**25);
     }   
}