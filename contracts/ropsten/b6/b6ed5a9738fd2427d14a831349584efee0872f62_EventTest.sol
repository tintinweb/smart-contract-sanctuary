/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EventTest { 
    // These would be easier to track ifff I'd indexed them. Oh well, next time.
    event BuyoutOccurred(address _who);
    event FundsWithdrawn(string _str, uint256 _p1, uint256 _p2);
    event NftReceived();
    event TransferNFTToClaimer(address _keyHolder);
    event ValueReceived(address _from, uint256 _amount);
    
    function bo() public { 
        emit BuyoutOccurred(msg.sender);
    }
    
    function fw() public { 
        emit FundsWithdrawn("hello", 1, 2);
    }
    
    function nr() public { 
        emit NftReceived();
    }
    
    function tn() public {
        emit TransferNFTToClaimer(msg.sender);
    }
    
    function vr() public {
        emit ValueReceived(msg.sender, 1);
    }
    
}