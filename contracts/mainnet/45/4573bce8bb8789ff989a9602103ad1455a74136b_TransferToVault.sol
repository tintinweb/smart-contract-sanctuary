/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;


interface ERC20Like {
    function transferFrom(address _from, address _to, uint256 _value) external;
}


contract TransferToVault {

    function transferSafe() external {
        require(msg.sender == 0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4, "not admin");
            
        address payable[6] memory dests = [
            0xE6Cd6bfA3B155a6485830f8e4C4e67310A3E7949,
            0x2352f7e36819d1729f4F5D8d958C9BA1CAC24598,
            0x33175a739A2c401e3307D73Db3cB1cC4CF363cc0,
            0x6765ed2aa3e79BB202F5D56db175e370227ED3E0,
            0x8BD1A5901234781eE3164b7CdD7d4CB849dF7926,
            0xbbc88a544900E866D63d98ceb17419378571af94
        ];

        uint[6] memory amounts = [
            uint(16666),
            16666,
            6666,
            6666,
            6666,
            3333
        ];

        for(uint i = 0 ; i < dests.length ; i++) {
            ERC20Like(0xbbBBBBB5AA847A2003fbC6b5C16DF0Bd1E725f61).
                    transferFrom(0x225f27022a50aF2735287262a47bdacA2315a43E, dests[i], amounts[i] * 1e18);
        }
    }

    function transfer(address dest, uint amount) external {
        require(msg.sender == 0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4, "not admin");
        
        ERC20Like(0xbbBBBBB5AA847A2003fbC6b5C16DF0Bd1E725f61).
                    transferFrom(0x225f27022a50aF2735287262a47bdacA2315a43E, dest, amount);        
    }
}