/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.5.16;

contract ERC20Like {
    function transferFrom(address _from, address _to, uint256 _value) external;
}


contract TransferToReward {
    function transfer(uint amount) external {
        require(msg.sender == 0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4, "not admin");
        
        ERC20Like(0xbbBBBBB5AA847A2003fbC6b5C16DF0Bd1E725f61).
                transferFrom(0x11B20aEF260837Cd82D3d8099aF46a2B6D66e20C, 0x3fEf090ED8C8b1Ad29C9F745464dFeCE47053345, amount);
        
    }
}