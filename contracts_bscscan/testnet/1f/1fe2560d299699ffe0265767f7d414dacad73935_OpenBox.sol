// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";


// Box interface for all mystery box contract
interface IBox {
    
    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

}

interface IDracooMaster {
    
    function safeMint(address to) external returns (uint256);

}

// must be assigned as a MinterRole of "DracooMaster" contract
contract OpenBox is Context, Ownable {
    using SafeMath for uint256;

    IDracooMaster public dracoo;

    mapping(address => bool) private _isBoxAvailable;

    event OpenBoxForDracoo(address indexed owner, address indexed boxAddress, uint256 indexed dracooTokenId, uint256 boxTokenId);

    constructor (address dracooAddress) public {
        dracoo = IDracooMaster(dracooAddress);
    }

    // set this box contract can be used to open a mystery box 
    function setBoxAvailable(address boxAddress, bool newState) public onlyOwner {
        _isBoxAvailable[boxAddress] = newState;
    }

    function checkBoxAvailable(address boxAddress) public view returns (bool) {
        return _isBoxAvailable[boxAddress];
    }

    // use this function by any user to open his box and earn a Dracoo
    // must call box contract's "setApproveForAll" for the first time open boxes
    function openBoxForDracoo(address boxAddress, uint256 boxTokenId) public returns(uint256) {
        require(_isBoxAvailable[boxAddress], "can not open this box address");
        address boxOwner = IBox(boxAddress).ownerOf(boxTokenId);
        require(_msgSender() == boxOwner, "only box owner can open it");

        IBox(boxAddress).burn(boxTokenId);

        uint256 dracooTokenId = dracoo.safeMint(boxOwner);

        emit OpenBoxForDracoo(boxOwner, boxAddress, dracooTokenId, boxTokenId);
        return dracooTokenId;
    }

}