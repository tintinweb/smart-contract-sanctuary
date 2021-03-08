/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

pragma solidity ^0.8.0;

// @kelvinfichter
contract Game1 {
    // Cmon, I'm not rich.
    uint256 constant prize = 0.05 ether;
    address[] public friends;
    
    constructor() payable {
        // Now you know I actually funded this contract.
        require(msg.value >= prize);
    }

    // Let's start easy.
    function winPrizeAndFeelGoodAboutSelf() public {
        // :-)
        friends.push(msg.sender);

        // No robots. Reel humans only.
        require(msg.sender == tx.origin, "no robots");
        
        // This will only work once :-(. Sorry if some nerd bot frontruns you.
        payable(msg.sender).transfer(address(this).balance);
    }
}