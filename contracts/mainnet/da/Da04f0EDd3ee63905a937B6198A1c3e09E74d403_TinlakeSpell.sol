/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

pragma solidity >=0.5.15;

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
/* pragma solidity >=0.5.15; */

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

// This spell makes multiple rate changes
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake Rate Update June 4 2021";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address constant public NS2_ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public NS2_ASSESSOR = 0x83E2369A33104120746B589Cc90180ed776fFb91;
    address constant public NS2_NAV_FEED = 0x41fAD1Eb242De19dA0206B0468763333BB6C2B3D;

    // change dropAPR to 6%               
    uint constant public ns2_seniorInterestRate = uint(1000000001268391679350583460);
    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        TinlakeRootLike ns2_root = TinlakeRootLike(address(NS2_ROOT));
        NAVFeedLike ns2_navFeed = NAVFeedLike(address(NS2_NAV_FEED));
        self = address(this);
        // add permissions  
        // Assessor
        ns2_root.relyContract(NS2_ASSESSOR, self);
        // NavFeed 
        ns2_root.relyContract(NS2_NAV_FEED, self); // required to file riskGroups & change discountRate

        // file drop interest rate
        FileLike(NS2_ASSESSOR).file("seniorInterestRate", ns2_seniorInterestRate);

        // risk group: 41 - 0.06, APR: 3.44%
        ns2_navFeed.file("riskGroup", 41, ONE, 85*10**25, uint(1000000001090820000000000000), 99.96*10**25);
        // risk group: 42 - 0.06125, APR: 3.56%
        ns2_navFeed.file("riskGroup", 42, ONE, 85*10**25, uint(1000000001128870000000000000), 99.95*10**25);
        // risk group: 43 - 0.0625, APR: 3.68%
        ns2_navFeed.file("riskGroup", 43, ONE, 85*10**25, uint(1000000001166920000000000000), 99.95*10**25);
        // risk group: 44 - 0.06375, APR: 3.8%
        ns2_navFeed.file("riskGroup", 44, ONE, 85*10**25, uint(1000000001204970000000000000), 99.94*10**25);
        // risk group: 45 - 0.065, APR: 3.92%
        ns2_navFeed.file("riskGroup", 45, ONE, 85*10**25, uint(1000000001243020000000000000), 99.93*10**25);
        // risk group: 46 - 0.06625, APR: 4.04%
        ns2_navFeed.file("riskGroup", 46, ONE, 85*10**25, uint(1000000001281080000000000000), 99.93*10**25);
        // risk group: 47 - 0.0675, APR: 4.16%
        ns2_navFeed.file("riskGroup", 47, ONE, 85*10**25, uint(1000000001319130000000000000), 99.92*10**25);
        // risk group: 48 - 0.06875, APR: 4.28%
        ns2_navFeed.file("riskGroup", 48, ONE, 85*10**25, uint(1000000001357180000000000000), 99.92*10**25);
        // risk group: 49 - 0.07, APR: 4.4%
        ns2_navFeed.file("riskGroup", 49, ONE, 85*10**25, uint(1000000001395230000000000000), 99.91*10**25);
        // risk group: 50 - 0.07125, APR: 4.52%
        ns2_navFeed.file("riskGroup", 50, ONE, 85*10**25, uint(1000000001433280000000000000), 99.9*10**25);
        // risk group: 51 - 0.0725, APR: 4.64%
        ns2_navFeed.file("riskGroup", 51, ONE, 85*10**25, uint(1000000001471330000000000000), 99.9*10**25);
        // risk group: 52 - 0.07375, APR: 4.76%
        ns2_navFeed.file("riskGroup", 52, ONE, 85*10**25, uint(1000000001509390000000000000), 99.89*10**25);
        // risk group: 53 - 0.075, APR: 4.88%
        ns2_navFeed.file("riskGroup", 53, ONE, 85*10**25, uint(1000000001547440000000000000), 99.88*10**25);
        // risk group: 54 - 0.07625, APR: 5%
        ns2_navFeed.file("riskGroup", 54, ONE, 85*10**25, uint(1000000001585490000000000000), 99.88*10**25);
        // risk group: 55 - 0.0775, APR: 5.12%
        ns2_navFeed.file("riskGroup", 55, ONE, 85*10**25, uint(1000000001623540000000000000), 99.87*10**25);
        // risk group: 56 - 0.07875, APR: 5.24%
        ns2_navFeed.file("riskGroup", 56, ONE, 85*10**25, uint(1000000001661590000000000000), 99.86*10**25);
        // risk group: 57 - 0.08, APR: 5.35%
        ns2_navFeed.file("riskGroup", 57, ONE, 85*10**25, uint(1000000001696470000000000000), 99.86*10**25);
        // risk group: 58 - 0.08125, APR: 5.47%
        ns2_navFeed.file("riskGroup", 58, ONE, 85*10**25, uint(1000000001734530000000000000), 99.85*10**25);
        // risk group: 59 - 0.0825, APR: 5.59%
        ns2_navFeed.file("riskGroup", 59, ONE, 85*10**25, uint(1000000001772580000000000000), 99.84*10**25);
        // risk group: 60 - 0.08375, APR: 5.71%
        ns2_navFeed.file("riskGroup", 60, ONE, 85*10**25, uint(1000000001810630000000000000), 99.84*10**25);
        // risk group: 61 - 0.085, APR: 5.83%
        ns2_navFeed.file("riskGroup", 61, ONE, 85*10**25, uint(1000000001847729578893962455), 99.83*10**25);
        // risk group: 62 - 0.08625, APR: 5.94%
        ns2_navFeed.file("riskGroup", 62, ONE, 85*10**25, uint(1000000001885147133434804667), 99.83*10**25);
        // risk group: 63 - 0.0875, APR: 6.06%
        ns2_navFeed.file("riskGroup", 63, ONE, 85*10**25, uint(1000000001922247590055809233), 99.82*10**25);
        // risk group: 64 - 0.08875, APR: 6.18%
        ns2_navFeed.file("riskGroup", 64, ONE, 85*10**25, uint(1000000001959665144596651445), 99.81*10**25);
        // risk group: 65 - 0.09, APR: 6.3%
        ns2_navFeed.file("riskGroup", 65, ONE, 85*10**25, uint(1000000001996765601217656012), 99.81*10**25);
        // risk group: 66 - 0.09125, APR: 6.41%
        ns2_navFeed.file("riskGroup", 66, ONE, 85*10**25, uint(1000000002034183155758498224), 99.8*10**25);
        // risk group: 67 - 0.0925, APR: 6.53%
        ns2_navFeed.file("riskGroup", 67, ONE, 85*10**25, uint(1000000002071283612379502790), 99.79*10**25);
        // risk group: 68 - 0.09375, APR: 6.65%
        ns2_navFeed.file("riskGroup", 68, ONE, 85*10**25, uint(1000000002108384069000507356), 99.79*10**25);
        // risk group: 69 - 0.095, APR: 6.77%
        ns2_navFeed.file("riskGroup", 69, ONE, 85*10**25, uint(1000000002145484525621511922), 99.78*10**25);
        // risk group: 70 - 0.09625, APR: 6.88%
        ns2_navFeed.file("riskGroup", 70, ONE, 85*10**25, uint(1000000002182584982242516489), 99.77*10**25);
        // risk group: 71 - 0.0975, APR: 7%
        ns2_navFeed.file("riskGroup", 71, ONE, 85*10**25, uint(1000000002219368340943683409), 99.77*10**25);
        // risk group: 72 - 0.09875, APR: 7.12%
        ns2_navFeed.file("riskGroup", 72, ONE, 85*10**25, uint(1000000002256468797564687975), 99.76*10**25);
        // risk group: 73 - 0.1, APR: 7.23%
        ns2_navFeed.file("riskGroup", 73, ONE, 85*10**25, uint(1000000002293252156265854895), 99.75*10**25);
        // risk group: 74 - 0.10125, APR: 7.35%
        ns2_navFeed.file("riskGroup", 74, ONE, 85*10**25, uint(1000000002330035514967021816), 99.75*10**25);
        // risk group: 75 - 0.1025, APR: 7.46%
        ns2_navFeed.file("riskGroup", 75, ONE, 85*10**25, uint(1000000002366818873668188736), 99.74*10**25);
        // risk group: 76 - 0.10375, APR: 7.58%
        ns2_navFeed.file("riskGroup", 76, ONE, 85*10**25, uint(1000000002403602232369355657), 99.74*10**25);
        // risk group: 77 - 0.105, APR: 7.7%
        ns2_navFeed.file("riskGroup", 77, ONE, 85*10**25, uint(1000000002440385591070522577), 99.73*10**25);
        // risk group: 78 - 0.10625, APR: 7.81%
        ns2_navFeed.file("riskGroup", 78, ONE, 85*10**25, uint(1000000002477168949771689497), 99.72*10**25);
        // risk group: 79 - 0.1075, APR: 7.93%
        ns2_navFeed.file("riskGroup", 79, ONE, 85*10**25, uint(1000000002513635210553018772), 99.72*10**25);
        // risk group: 80 - 0.10875, APR: 8.04%
        ns2_navFeed.file("riskGroup", 80, ONE, 85*10**25, uint(1000000002550418569254185692), 99.71*10**25);
        // risk group: 81 - 0.11, APR: 8.16%
        ns2_navFeed.file("riskGroup", 81, ONE, 85*10**25, uint(1000000002586884830035514967), 99.7*10**25);
        // risk group: 82 - 0.11125, APR: 8.27%
        ns2_navFeed.file("riskGroup", 82, ONE, 85*10**25, uint(1000000002623351090816844241), 99.7*10**25);
        // risk group: 83 - 0.1125, APR: 8.39%
        ns2_navFeed.file("riskGroup", 83, ONE, 85*10**25, uint(1000000002659817351598173515), 99.69*10**25);
        // risk group: 84 - 0.11375, APR: 8.5%
        ns2_navFeed.file("riskGroup", 84, ONE, 85*10**25, uint(1000000002696283612379502790), 99.68*10**25);
        // risk group: 85 - 0.115, APR: 8.62%
        ns2_navFeed.file("riskGroup", 85, ONE, 85*10**25, uint(1000000002732749873160832064), 99.68*10**25);
        // risk group: 86 - 0.11625, APR: 8.73%
        ns2_navFeed.file("riskGroup", 86, ONE, 85*10**25, uint(1000000002768899036022323693), 99.67*10**25);
        // risk group: 87 - 0.1175, APR: 8.85%
        ns2_navFeed.file("riskGroup", 87, ONE, 85*10**25, uint(1000000002805365296803652968), 99.66*10**25);
        // risk group: 88 - 0.11875, APR: 8.96%
        ns2_navFeed.file("riskGroup", 88, ONE, 85*10**25, uint(1000000002841514459665144596), 99.66*10**25);
        // risk group: 89 - 0.12, APR: 9.08%
        ns2_navFeed.file("riskGroup", 89, ONE, 85*10**25, uint(1000000002877663622526636225), 99.65*10**25);
        // risk group: 90 - 0.12125, APR: 9.19%
        ns2_navFeed.file("riskGroup", 90, ONE, 85*10**25, uint(1000000002914129883307965499), 99.65*10**25);
        // risk group: 91 - 0.1225, APR: 9.3%
        ns2_navFeed.file("riskGroup", 91, ONE, 85*10**25, uint(1000000002949961948249619482), 99.64*10**25);
        // risk group: 92 - 0.12375, APR: 9.42%
        ns2_navFeed.file("riskGroup", 92, ONE, 85*10**25, uint(1000000002986111111111111111), 99.63*10**25);
        // risk group: 93 - 0.125, APR: 9.53%
        ns2_navFeed.file("riskGroup", 93, ONE, 85*10**25, uint(1000000003022260273972602739), 99.63*10**25);
        // risk group: 94 - 0.12625, APR: 9.64%
        ns2_navFeed.file("riskGroup", 94, ONE, 85*10**25, uint(1000000003058409436834094368), 99.62*10**25);
        // risk group: 95 - 0.1275, APR: 9.76%
        ns2_navFeed.file("riskGroup", 95, ONE, 85*10**25, uint(1000000003094241501775748351), 99.61*10**25);
        // risk group: 96 - 0.12875, APR: 9.87%
        ns2_navFeed.file("riskGroup", 96, ONE, 85*10**25, uint(1000000003130073566717402333), 99.61*10**25);
        // risk group: 97 - 0.13, APR: 9.98%
        ns2_navFeed.file("riskGroup", 97, ONE, 85*10**25, uint(1000000003166222729578893962), 99.6*10**25);
    }
}