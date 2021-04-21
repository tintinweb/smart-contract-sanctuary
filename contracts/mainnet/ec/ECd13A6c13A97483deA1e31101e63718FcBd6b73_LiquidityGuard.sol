/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

contract LiquidityGuard {

    mapping (uint32 => uint256) InflationLN;

    function getInflation(uint32 _amount) external view returns (uint256) {
        if (_amount > 103000) {
            return InflationLN[103000];            
        } else if (_amount < 102100) {
            return InflationLN[102100];
        }
        return InflationLN[_amount];
    }

    // 0.006% liquidityRate step increase;
    constructor() {
        InflationLN[102100] =  175623202;
        InflationLN[102106] =  175128000;
        InflationLN[102112] =  174635612;
        InflationLN[102118] =  174146014;
        InflationLN[102124] =  173659181;
        InflationLN[102130] =  173175091;
        InflationLN[102136] =  172693721;
        InflationLN[102142] =  172215047;
        InflationLN[102148] =  171739047;
        InflationLN[102154] =  171265699;
        InflationLN[102160] =  170794981;
        InflationLN[102166] =  170326870;
        InflationLN[102172] =  169861346;
        InflationLN[102178] =  169398386;
        InflationLN[102184] =  168937970;
        InflationLN[102190] =  168480077;
        InflationLN[102196] =  168024686;
        InflationLN[102202] =  167571776;
        InflationLN[102208] =  167121328;
        InflationLN[102214] =  166673321;
        InflationLN[102220] =  166227735;
        InflationLN[102226] =  165784552;
        InflationLN[102232] =  165343751;
        InflationLN[102238] =  164905314;
        InflationLN[102244] =  164469221;
        InflationLN[102250] =  164035454;
        InflationLN[102256] =  163603994;
        InflationLN[102262] =  163174823;
        InflationLN[102268] =  162747922;
        InflationLN[102274] =  162323275;
        InflationLN[102280] =  161900862;
        InflationLN[102286] =  161480666;
        InflationLN[102292] =  161062671;
        InflationLN[102298] =  160646857;
        InflationLN[102304] =  160233210;
        InflationLN[102310] =  159821711;
        InflationLN[102316] =  159412345;
        InflationLN[102322] =  159005093;
        InflationLN[102328] =  158599941;
        InflationLN[102334] =  158196872;
        InflationLN[102340] =  157795870;
        InflationLN[102346] =  157396919;
        InflationLN[102352] =  157000003;
        InflationLN[102358] =  156605107;
        InflationLN[102364] =  156212216;
        InflationLN[102370] =  155821314;
        InflationLN[102376] =  155432386;
        InflationLN[102382] =  155045417;
        InflationLN[102388] =  154660393;
        InflationLN[102394] =  154277298;
        InflationLN[102400] =  153896119;
        InflationLN[102406] =  153516841;
        InflationLN[102412] =  153139450;
        InflationLN[102418] =  152763932;
        InflationLN[102424] =  152390272;
        InflationLN[102430] =  152018458;
        InflationLN[102436] =  151648475;
        InflationLN[102442] =  151280311;
        InflationLN[102448] =  150913950;
        InflationLN[102454] =  150549382;
        InflationLN[102460] =  150186591;
        InflationLN[102466] =  149825566;
        InflationLN[102472] =  149466294;
        InflationLN[102478] =  149108761;
        InflationLN[102484] =  148752955;
        InflationLN[102490] =  148398864;
        InflationLN[102496] =  148046475;
        InflationLN[102502] =  147695776;
        InflationLN[102508] =  147346755;
        InflationLN[102514] =  146999400;
        InflationLN[102520] =  146653699;
        InflationLN[102526] =  146309641;
        InflationLN[102532] =  145967212;
        InflationLN[102538] =  145626403;
        InflationLN[102544] =  145287201;
        InflationLN[102550] =  144949596;
        InflationLN[102556] =  144613575;
        InflationLN[102562] =  144279128;
        InflationLN[102568] =  143946244;
        InflationLN[102574] =  143614911;
        InflationLN[102580] =  143285120;
        InflationLN[102586] =  142956859;
        InflationLN[102592] =  142630117;
        InflationLN[102598] =  142304885;
        InflationLN[102604] =  141981151;
        InflationLN[102610] =  141658906;
        InflationLN[102616] =  141338139;
        InflationLN[102622] =  141018840;
        InflationLN[102628] =  140700998;
        InflationLN[102634] =  140384605;
        InflationLN[102640] =  140069650;
        InflationLN[102646] =  139756123;
        InflationLN[102652] =  139444014;
        InflationLN[102658] =  139133315;
        InflationLN[102664] =  138824015;
        InflationLN[102670] =  138516105;
        InflationLN[102676] =  138209576;
        InflationLN[102682] =  137904418;
        InflationLN[102688] =  137600622;
        InflationLN[102694] =  137298180;
        InflationLN[102700] =  136997081;
        InflationLN[102706] =  136697318;
        InflationLN[102712] =  136398881;
        InflationLN[102718] =  136101762;
        InflationLN[102724] =  135805951;
        InflationLN[102730] =  135511441;
        InflationLN[102736] =  135218222;
        InflationLN[102742] =  134926287;
        InflationLN[102748] =  134635626;
        InflationLN[102754] =  134346231;
        InflationLN[102760] =  134058095;
        InflationLN[102766] =  133771209;
        InflationLN[102772] =  133485565;
        InflationLN[102778] =  133201154;
        InflationLN[102784] =  132917969;
        InflationLN[102790] =  132636002;
        InflationLN[102796] =  132355246;
        InflationLN[102802] =  132075691;
        InflationLN[102808] =  131797331;
        InflationLN[102814] =  131520158;
        InflationLN[102820] =  131244165;
        InflationLN[102826] =  130969343;
        InflationLN[102832] =  130695686;
        InflationLN[102838] =  130423186;
        InflationLN[102844] =  130151836;
        InflationLN[102850] =  129881628;
        InflationLN[102856] =  129612555;
        InflationLN[102862] =  129344610;
        InflationLN[102868] =  129077787;
        InflationLN[102874] =  128812077;
        InflationLN[102880] =  128547475;
        InflationLN[102886] =  128283972;
        InflationLN[102892] =  128021563;
        InflationLN[102898] =  127760241;
        InflationLN[102904] =  127499998;
        InflationLN[102910] =  127240828;
        InflationLN[102916] =  126982725;
        InflationLN[102922] =  126725681;
        InflationLN[102928] =  126469692;
        InflationLN[102934] =  126214749;
        InflationLN[102940] =  125960846;
        InflationLN[102946] =  125707978;
        InflationLN[102952] =  125456137;
        InflationLN[102958] =  125205318;
        InflationLN[102964] =  124955515;
        InflationLN[102970] =  124706720;
        InflationLN[102976] =  124458929;
        InflationLN[102982] =  124212135;
        InflationLN[102988] =  123966332;
        InflationLN[102994] =  123721514;
        InflationLN[103000] =  123477676;
    }
}