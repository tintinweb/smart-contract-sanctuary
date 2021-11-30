/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.10;

interface AutoBurn {
    function PoolBurnAndSync() external returns (bool);
    function countdownPoolBurnDue() external view returns (uint256);
}

contract poolBurnAndSyncRepeat{
    address public token;
    uint256 public ch;

    function getChainId() public view  returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
   
    constructor() {
        token = address(0);
        ch = getChainId();
        if (ch == 1) token=0xf3a561E0F83814149992BcDC2aD375aCba84754e; //ETH mainnet
        if (ch == 56) token=0x147Fb3D817107f13ee8E1d7feC0f71D54838656B; //BSC mainnet, v2
    }

    receive() external payable { revert();  }
    
    function poolBurnAndSync(uint256 m) public {
        require(msg.sender == tx.origin); //no automated runs
        require(m <= 1000); //3 years max
        if (m == 0) m = 30;
        m++;
       uint256 c = AutoBurn(token).countdownPoolBurnDue();
       while (--m > 0 && c == 0)
      {
        AutoBurn(token).PoolBurnAndSync();
        c = AutoBurn(token).countdownPoolBurnDue();
      }
    }
}