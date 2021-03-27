/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

//
//                 -/oyhhhhhdddddhys+/:`
//              -sddyo+//////++ossssyyhdho-
//            -yds/:-------:::/+oo++++++oydh/`
//          `sms/-----....---::/+++++++++/+ohd+`
//         -dh+--------...----://++++++//////+yd+`
//        /my:-..------..-----::/++++++/////:::+hh-
//       /my:...---:::..-----:::/+++++///:::::---sm:
//      `md+:-..--:::---::::::::/oo++//:::------..om:
//      /Nhhys/---:+syysso/::::/+oo++//:-..........sm-
//     -mysy++o:-:+o+o+//+o/-::/+oo++//:-..`````...-dh`
//     yd:+s+:/::::--:+ho::/-:/+ooo+++/::-...````...oN-
//    .Ny:::-::/:---..-::...-:+osooo++///:---.......+N-
//    -Ny/:--::/-----.....---+osoooo++++//::::::---.+N-
//    .Nh+/:::::--::---:::::/osssooo+++++//////:::--/N:
//    `Ndo+/::::-:::::::////+ossssooo+++++///////::-/N/
//     ymoo/:::-://////////+ossssssoooooo++++++++//:/N/
//     smsoosyyso+////////+oosssssssoooooo++++++++//+N:
//     sNs+//syyy+///////++ossssssssssssooooooooo+++yN-
//     +Nyo+/:+so+///////+oossssyyssssssssoooooooooomy
//     `mdossssossss+///+oossssyyyysssssssssssssooodm-
//      /Ns::+syso+///++oossssyyyyyyyyyyssssssssssym+
//      `dd/-.-::::/+++ossssyyyyyyyyyyyyyssssssssyms
//       smo----::/++ossssyyyyyhhhhyyyyyyssssssssmh`
//       :Ny:/::/+oossyyyyyyhhhhhhyyhyyysssooossdh.
//       `smso++ossyyyhhhdddddhhyyyyyyysssoooosdm.
//         /dddhhhhhddmmmmmdhhyyyyyyyssoooooooym:
//          `-//+yNdmddhhhhyyyyssyyyssooo+++o++d.
//               :Nmdhhyyyysssssssssooo+++++/:-oh+.
//            `-ohNmhhyyyssssssssssoo+++///:----hmmy-
//         ./ymNNNs+oyyysssssooossoo++//::-....ommmmms.
//     `:ohmNNNNN+:/++sssssooooooo+//:--......-ydddmmmms.
//  ./ymNmmmmmmNo---:/+ooooo++++/:--..........oddddmdddmmdyo:.
// dmmmmmmmmmmNh-....-/oso:--....````........oddddddddddmddhddd
// mddddmmmmmmN:..-/yhhhyyys+-```````````...odddddddddddmmddhhh
//            __  __            __              __
//      ___  / /_/ /_     _____/ /_____  ____  / /_______
//     / _ \/ __/ __ \   / ___/ __/ __ \/ __ \/ //_/ ___/
//    /  __/ /_/ / / /  (__  ) /_/ /_/ / / / / ,< (__  )
//    \___/\__/_/ /_/  /____/\__/\____/_/ /_/_/|_/____/
//
//                   created by Mr F
//            HTML/CSS and Graphics by Karl
//             Advanced Solidity by ToCsIcK
//
//             https://ethstonks.finance/
//            https://discord.gg/mDMyTksceR
//               https://t.me/ethstonks
//

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

contract StonkReader {
    StonkInterface private stonk;
    uint public version;

    constructor(address _stonkAddress, uint _version)
    public
    {
        stonk = StonkInterface(_stonkAddress);
        version = _version;
    }

    function highPriority(address addr, uint buyAmount)
    public view
    returns(uint[12] memory n)
    {
        (n[0], n[1], n[2], n[3], n[4], n[5], n[6]) = stonk.gameData();              // main game data
        (n[7], n[8], n[9], n[10], n[11]) = stonk.stonkNumbers(addr, buyAmount);     // user data
    }

    function lowPriority(address addr)
    public view
    returns(string[6] memory s, uint[7] memory n)
    {
        (s[0], s[1], s[2], s[3], s[4], s[5]) = stonk.stonkNames(addr);              // user name + leader names
        (n[0], n[1], n[2], n[3], n[4], n[5], n[6]) = stonk.leaderNumbers();         // leader numbers
    }

    function buyerNames()
    public view
    returns (string memory b1, string memory b2, string memory b3, string memory b4, string memory b5)
    {
        uint r = stonk.r();
        int8 lastBuyIndex = stonk.getRoundLastBuyIndex(r);

        b1 = stonk.addressToName(stonk.lastBuy(r, (5 + lastBuyIndex - 1) % 5));
        b2 = stonk.addressToName(stonk.lastBuy(r, (5 + lastBuyIndex - 2) % 5));
        b3 = stonk.addressToName(stonk.lastBuy(r, (5 + lastBuyIndex - 3) % 5));
        b4 = stonk.addressToName(stonk.lastBuy(r, (5 + lastBuyIndex - 4) % 5));
        b5 = stonk.addressToName(stonk.lastBuy(r, (5 + lastBuyIndex - 5) % 5));
    }

    function buyerAddresses()
    public view
    returns (address b1, address b2, address b3, address b4, address b5)
    {
        uint r = stonk.r();
        int8 lastBuyIndex = stonk.getRoundLastBuyIndex(r);

        b1 = stonk.lastBuy(r, (5 + lastBuyIndex - 1) % 5);
        b2 = stonk.lastBuy(r, (5 + lastBuyIndex - 2) % 5);
        b3 = stonk.lastBuy(r, (5 + lastBuyIndex - 3) % 5);
        b4 = stonk.lastBuy(r, (5 + lastBuyIndex - 4) % 5);
        b5 = stonk.lastBuy(r, (5 + lastBuyIndex - 5) % 5);
    }
}

interface StonkInterface {
    function stonkNames(address addr) external view returns (string memory, string memory, string memory, string memory, string memory, string memory);
    function stonkNumbers(address addr, uint buyAmount) external view returns (uint, uint, uint, uint, uint);
    function gameData() external view returns (uint, uint, uint, uint, uint, uint, uint);
    function buyerNames() external view returns (string memory, string memory, string memory, string memory, string memory);
    function userRoundStats(address addr, uint rnd) external view returns (uint, uint, uint, uint, uint, uint, uint, uint);
    function getHistoricalMetric(uint rnd, uint key, uint index) external view returns (uint);
    function getPlayerMetric(address addr, uint rnd, uint key) external view returns (uint);
    function getRoundMetric(uint rnd, uint key) external view returns (uint);
    function getRoundIndex(uint rnd) external view returns (uint);
    function getPlayerByIndex(uint rnd, uint ind) external view returns (address);
    function leaderNumbers() external view returns (uint, uint, uint, uint, uint, uint, uint);
    function nameToAddr(string memory name) external view returns (address);
    function addressToName(address addr) external view returns (string memory);
    function lastBuy(uint rnd, int8 index) external view returns (address);
    function getRoundLastBuyIndex(uint rnd) external view returns (int8);
    function bailoutPool(uint rnd, uint cb) external view returns (uint);
    function bailoutRecipient(uint rnd, uint cb, uint idx) external view returns (address);
    function r() external view returns (uint);
}