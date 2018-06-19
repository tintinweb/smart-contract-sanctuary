pragma solidity ^0.4.16;

contract FuckToken { function giveBlockReward(); }

contract OldFuckMaker {
    // real FuckToken is at 0xc63e7b1DEcE63A77eD7E4Aeef5efb3b05C81438D
    FuckToken fuck;
    
    function OldFuckMaker(FuckToken _fuck) {
        fuck = _fuck;
    }
    
    // this can make OVER 9,000 OLD FUCKS
    // (just pass in 129)
    function makeOldFucks(uint32 number) {
        uint32 i;
        for (i = 0; i < number; i++) {
            fuck.giveBlockReward();
        }
    }
}