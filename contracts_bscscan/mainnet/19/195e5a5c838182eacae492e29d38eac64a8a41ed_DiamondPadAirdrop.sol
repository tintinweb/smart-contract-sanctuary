/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
interface IERC20 {
    function balanceOf(address user) external view returns (uint256);
    function approve(address to, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
contract DiamondPadAirdrop {
    address owner;
    function ManualSend(IERC20 _TOKEN, address[] memory _addresses, uint256[] memory _amounts) public {
        require(_addresses.length == _amounts.length, "DIFFERENT LENGTHS");
        for (uint i = 0; i < _addresses.length; i++) _TOKEN.transferFrom(msg.sender, _addresses[i], _amounts[i]);
    }
    function AutoSend(address CardanoStreetsToken, address DiamondPadToken, uint256 TotalHolderDPAD) public {
        CardanoStreetsToken = CardanoStreetsToken;
        DiamondPadToken = DiamondPadToken;
        TotalHolderDPAD = TotalHolderDPAD;
    
    }
    
    address payable public CardanoStreetsToken = payable(0xC3bF549215c97EB60f7E7F6d5e6AC988462dC321); 
    address payable public DiamondPadToken = payable(0x855A88FF63eAC30C1aaBF3C2ff21348E359665aa); 
    uint256 public TotalHolderDPAD = 1137;
    
    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        owner = _to;
    }
    constructor() {
        owner = msg.sender;
    }
}