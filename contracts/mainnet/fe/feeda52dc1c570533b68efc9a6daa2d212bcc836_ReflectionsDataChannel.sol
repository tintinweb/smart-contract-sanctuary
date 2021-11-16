// SPDX-License-Identifier: Unlicense

/*
    8|8888888888888888888|888|88888
    8.|.......|............|......8
    8.....................|.......8
    8....|.......RRRRR.|..........8
    8..........RREEEEER|......|.|.8
    8........RREEFFFFFEER|........8
    8....|..R.EFFLL|LLFFE.R.......8
    8...|..R.EFLLEEEEELLFE.R.....|8
    8..|..R.EF|.ECCCCCE.LFE.R.....8
    8....R.EFL.EC.TTT.CE.LFE.R....8
    8....REFL.ECTTII|TTCE.LFER....8
    8...REFL.ECT.IOOOI.|CE.LFER...8
    8|..REFLECT.IONNNO|.TCELFER...8
    8..REFLEC.TION.|.NOIT.C|LFER..8
    8..RE||E|TIO|.....NOITCEL||R..8
    8..R|FLECTION.....NOITCELF|R..8
    8..REF|ECTI|N.....NOI|CELFER..8
    8..REFLEC.TION|..NOIT.CELFER..8
    |...REFLECT.IONNNOI.TCELFE|...8
    8...R|FL.ECT.IOOOI.TCE.LFER...8
    8....R|FL.ECTTIIITTCE.LFER....8
    8.|..R||F|.EC.TTT.CE.LFE.R....8
    8.....R.EFL.ECCCCCE.LFE.|.....8
    8.....|R.EFLLEEEEELLFE.R|.....8
    8.......R.EF|LLLLLFFE.R.......8
    8........|REEF|FFFEERR........8
    8..........RREEEEERR..........8
    8............RRRRR............8
    8...................|.........8
    8....|.....................|..8
    8888888888888888888888888888888

*/

pragma solidity^0.8.7;

interface ICorruptions {
    function balanceOf(address owner) external returns (uint256);
}

contract ReflectionsDataChannel {
    event Message(string indexed message);
    event SignerAdded(address indexed signer);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function postMessage(string memory message) public {
        require(msg.sender == owner, "not owner");
        emit Message(message);
    }
    
    function updateOwner(address newOwner) public {
        require(msg.sender == owner, "not owner");
        owner = newOwner;
    }
    
    function signMessages() public {
        require(ICorruptions(0x5BDf397bB2912859Dbd8011F320a222f79A28d2E).balanceOf(msg.sender) > 0, "not owner");
        emit SignerAdded(msg.sender);
    }
}