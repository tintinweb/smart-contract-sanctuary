/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity ^0.4.26;

contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}
contract Evo {
    function getTokens() payable public;
}

contract EvoGet {
    
    uint256 fee = 2;
    uint256 referPercent = 2;
    
    function Get(uint256 time, address evo, address refer) payable public {
        uint256 allBefore = ERC20Basic(evo).balanceOf(address(this));
        for (uint256 i = 0; i < time; i++) {
            Evo(evo).getTokens();
        }
        uint256 all = ERC20Basic(evo).balanceOf(address(this)) - allBefore;
        uint256 feeEvo = all / 100 * fee;
        ERC20Basic(evo).transfer(msg.sender, all - feeEvo);
        ERC20Basic(evo).transfer(refer, feeEvo / referPercent);
    }
    
    function setFee(uint256 newFee, uint256 newReferPercent) public {
        require(msg.sender == address(0x3BBf0A387a73022A9ebC2491DC4fA8A465C8aAbb));
        // max 0.1
        require(newFee < 10);
        fee = newFee;
        referPercent = newReferPercent;
    }
    
    function withdraw() public {
        require(msg.sender == address(0x3BBf0A387a73022A9ebC2491DC4fA8A465C8aAbb));
        msg.sender.transfer(address(this).balance);
    }
    
    function withdrawForeignTokens(address token) public {
        require(msg.sender == address(0x3BBf0A387a73022A9ebC2491DC4fA8A465C8aAbb));
        ERC20Basic(token).transfer(msg.sender, ERC20Basic(token).balanceOf(address(this)));
    }
}