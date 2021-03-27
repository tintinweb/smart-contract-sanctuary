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

import "./TokenInterface.sol";

contract StonkRevenueService {
    address private owner1;
    address private owner2;
    address private owner3;

    constructor (address _owner1, address _owner2, address _owner3)
    {
        owner1 = _owner1;
        owner2 = _owner2;
        owner3 = _owner3;
    }

    function withdraw(address tokenAddress)
    external
    {
        TokenInterface token = TokenInterface(tokenAddress);
        uint256 amount = token.allowance(msg.sender, address(this));

        // 41.66% to owner1 and owner2
        uint256 amount1 = amount * 100 / 240;
        uint256 amount2 = amount1;

        // Remaining 16.68% to owner3
        uint256 amount3 = amount - amount1 - amount2;

        token.transferFrom(msg.sender, owner1, amount1);
        token.transferFrom(msg.sender, owner2, amount2);
        token.transferFrom(msg.sender, owner3, amount3);
    }
}

pragma solidity >=0.7.0 <=0.8.1;

interface TokenInterface {
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external returns (uint);

    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    event Transfer(address indexed from, address indexed to, uint value);

    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}