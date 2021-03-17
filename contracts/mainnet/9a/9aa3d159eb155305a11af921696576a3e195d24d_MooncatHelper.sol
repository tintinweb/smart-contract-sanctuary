/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

interface MooncatContract {

    function catOwners(bytes5 catId) external view returns (address);

    function remainingGenesisCats() external view returns (uint);

    function makeAdoptionOffer(bytes5 catId, uint price) external;

    function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) external;

    function acceptAdoptionOffer(bytes5 catId) external payable;

}

interface WrappedMooncatContract {

    function wrap(bytes5 catId) external;

    function unwrap(uint256 tokenID) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function _catIDToTokenID(bytes5 catId) external view returns (uint);

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract MooncatHelper {

    address mc = 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6;
    address wmc = 0x7C40c393DC0f283F318791d746d894DdD3693572;
    uint256 fee = 10000000000000000;
    address payable public dev;

    constructor() public payable {
        dev = payable(msg.sender);
    }

    function buyAndWrap(bytes5 catId) public payable {
        require(msg.value > fee, "Please include 0.01 eth fee");
        MooncatContract(mc).acceptAdoptionOffer{value:msg.value-fee}(catId);
        MooncatContract(mc).makeAdoptionOfferToAddress(catId, 0, wmc);
        WrappedMooncatContract(wmc).wrap(catId);
        uint tokenId = WrappedMooncatContract(wmc)._catIDToTokenID(catId);
        WrappedMooncatContract(wmc).transferFrom(address(this), msg.sender, tokenId);
    }

    function withdraw() public {
        uint amount = address(this).balance;
        (bool success,) = dev.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

}