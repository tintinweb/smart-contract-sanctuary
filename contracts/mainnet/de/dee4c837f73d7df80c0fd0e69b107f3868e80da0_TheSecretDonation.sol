/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

/**
 *     _______  __   __  _______    _______  _______  _______  ______    _______  _______ 
 *    |       ||  | |  ||       |  |       ||       ||       ||    _ |  |       ||       |
 *    |_     _||  |_|  ||    ___|  |  _____||    ___||       ||   | ||  |    ___||_     _|
 *      |   |  |       ||   |___   | |_____ |   |___ |       ||   |_||_ |   |___   |   |  
 *      |   |  |       ||    ___|  |_____  ||    ___||      _||    __  ||    ___|  |   |  
 *      |   |  |   _   ||   |___    _____| ||   |___ |     |_ |   |  | ||   |___   |   |  
 *      |___|  |__| |__||_______|  |_______||_______||_______||___|  |_||_______|  |___|  
 * 
 * 
 * TheSecret.Finance - A game for the knowledgeable
 * This is the donation contract
 * 
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * 
 */

pragma solidity 0.7.4;

contract TheSecretDonation {
    address payable public admin;
   
	
    event Donate(address _donner);

    constructor () public {
        admin = msg.sender;
    }


    function DonateETH() public payable {
        require(msg.value >0);
        emit Donate(msg.sender);
    }

    function endDonation() public {
        require(msg.sender == admin);
        admin.transfer(address(this).balance);
    }
}