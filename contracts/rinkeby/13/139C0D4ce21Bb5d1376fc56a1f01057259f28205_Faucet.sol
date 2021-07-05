/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: GPL-3.0
// rinkeby: 0x139C0D4ce21Bb5d1376fc56a1f01057259f28205

interface Stable {
    function mint (address account, uint256 amount) external;
}

interface Wows {
  function distribute2(address recipient, uint256 amount, uint32 fee) external;
}

contract Faucet {
  mapping(address => bool) _minted;
  
  function mint() external {
    require (_minted[msg.sender] == false, 'Already minted');
    _minted[msg.sender] = true;
  
    // Rinkeby
    // DAI
    Stable(0x1bD2aC567a033f224dB9bD1f7708200c0B9B2CcB).mint(msg.sender, 100*1E18);
    // USDC
    Stable(0x5B1b4D138526E12eadEaA9D2DD8Eb0Fb04b56865).mint(msg.sender, 100*1E6);
    // USDT
    Stable(0x8ca07b973FA8c75DBCb97ED206c12C22a25d4953).mint(msg.sender, 100*1E6);
    // TUSD
    Stable(0xC2FB0364A768d00AC22b8B44DD797ae232EdfddF).mint(msg.sender, 100*1E18);
    // Wows
    Wows(0x4c2c0a612c71c7DaA487dF2Ed5Dbf6348e15438B).distribute2(msg.sender, 10*1E18, 0);
  }
}