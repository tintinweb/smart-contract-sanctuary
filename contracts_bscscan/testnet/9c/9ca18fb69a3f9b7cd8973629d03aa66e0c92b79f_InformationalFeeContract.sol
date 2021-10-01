// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <=0.8.7;

/*
    You probably got here through a Token or Farm created by our
    platform.
    
    We are the developers of an innovative platform that helps anyone
    create their dream Token or Farm.
    
    This is just the contract which we receive fees and pass on some
    information.
    
    If you are interested in becoming one of our partners, or if you
    already had the dream of developing your Token or Farm, please visit
    our website, it can be found in the "website" reading function in this
    contract.

*/

import "./IERC20.sol";
import "./Owner.sol";
import "./TransferHelper.sol";

contract InformationalFeeContract is Owner {
    string internal _website;

    constructor(string memory website_) {
        _website = website_;
    }

    function website() external view returns (string memory) {
        return _website;
    }

    function set_website(string memory website_) external isOwner {
        _website = website_;
    }

    function WithdrawToken(address Token) external isOwner {
        TransferHelper.safeTransfer(
            Token,
            msg.sender,
            IERC20(Token).balanceOf(address(this))
        );
    }

    function WithdrawETH() external isOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}