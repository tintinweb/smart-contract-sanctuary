pragma solidity 0.4.25;

contract gas_estimation {
    address[100] receivers;
    uint256[100] distribute_amounts;
    uint256[100] distribute_ratio;
    
    function setReceiver() public {
        distribute_ratio[0] = 10;
    }
    function setReceiver1() public {
        distribute_ratio[1] = 10;
    }
    function setReceiver2() public {
        distribute_ratio[2] = 10;
    }
    function setReceiver3() public {
        distribute_ratio[3] = 10;
    }
    function setReceiver4() public {
        distribute_ratio[4] = 10;
    }
    function setReceiver5() public {
        distribute_ratio[5] = 10;
    }
    function setReceiver6() public {
        distribute_ratio[6] = 10;
    }
    
    function setReceivers() public {
        distribute_ratio[0] = 10;
        distribute_ratio[1] = 10;
        distribute_ratio[2] = 10;
        distribute_ratio[3] = 10;
        distribute_ratio[4] = 10;
        distribute_ratio[5] = 10;
        distribute_ratio[6] = 10;
    }
    
    function setLedgers(uint256 pMax) {
        for (uint256 i=0; i < pMax; i++) {
            receivers[i] = 0x282E08c0fFE4e73E5fCd84844Ce7de4883f2487E;
            distribute_amounts[i] = i;
            distribute_ratio[i] =  i;
        }
    }

    function setLedger(uint256 i) {
        receivers[i] = 0x282E08c0fFE4e73E5fCd84844Ce7de4883f2487E;
        distribute_amounts[i] = 1;
        distribute_ratio[i] =  1;
    }    
    
}