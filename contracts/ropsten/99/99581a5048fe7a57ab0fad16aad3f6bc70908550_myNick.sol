/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.4.21;

interface CaptureTheEther {
    function setNickname(bytes32 nickname) external;
}

// Challenge contract. You don't need to do anything with this; it just verifies
// that you set a nickname for yourself.
contract myNick {
    CaptureTheEther cte;
    
    constructor(address _cteContract) {
        cte = CaptureTheEther(_cteContract);
    }
    
    function setNickname() public {
        cte.setNickname(0x0000000000000000000000000000000000000000000000000000004e61626c61);
    }
}