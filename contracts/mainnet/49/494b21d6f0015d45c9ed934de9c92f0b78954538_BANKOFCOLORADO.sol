/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface THUGNFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract BANKOFCOLORADO {
    address private CHEF_DEV = 0xe8BFfCf21dc505310987b8a90A966Bb94224C43e;
    address private MR_HANKY = 0xB00e37C5C022eD328Bf4A75cf28DE19EfF8F53E9;
    address private THUG_NFTS = 0x70bB7adc0B31f1D9a97a275404C466df6A78FAE9;
    
    receive() external payable {}
    
    function rob() external {
        require(msg.sender == Blood() || msg.sender == Crip() || msg.sender == CHEF_DEV || msg.sender == MR_HANKY, "Only Thugs can rob banks!");
        disperseEth();
    }
    function Blood() public view returns (address) {
        return THUGNFT(THUG_NFTS).ownerOf(0);
    }
    function Crip() public view returns (address) {
        return THUGNFT(THUG_NFTS).ownerOf(1);
    }
    function disperseEth() private {
         uint256 TOTAL_BALANCE = address(this).balance;
         uint256 QUARTER = TOTAL_BALANCE / 4;
         payable(Blood()).transfer(QUARTER);
         payable(Crip()).transfer(QUARTER);
         payable(CHEF_DEV).transfer(QUARTER);
         payable(MR_HANKY).transfer(QUARTER);
    }
}