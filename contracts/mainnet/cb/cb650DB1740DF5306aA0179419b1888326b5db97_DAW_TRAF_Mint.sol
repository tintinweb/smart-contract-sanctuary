/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ITRAF {

    function adminMint(address account, uint256 amount) external;

    function changeOwner1(address payable owner) external;
    
    function changeOwner2(address payable owner) external;
}

interface IDAW {

    function balanceOf(address owner) external returns (uint256);

}

contract DAW_TRAF_Mint {
    
    ITRAF TRAF;
    IDAW DAW;
    
    address private _manager;
    
    uint256 private _price = 550000000000000000;

    bool private _minting = true; //If minting is on or off

    modifier manager {
        require(msg.sender == _manager);
        _;
    }
    
    receive() external payable {}
    
    constructor(address TRAFcontract, address DAWcontract) {
        _manager = msg.sender;
        TRAF = ITRAF(TRAFcontract);
        DAW = IDAW(DAWcontract);
    }

    //Read Functions======================================================================================================================================================
    function owner() external view returns (address) {
        return _manager;
    }

    function price() external view returns(uint256) {
        return _price;
    }

    function minting() external view returns(bool) {return _minting;}
    
    //Moderator Functions======================================================================================================================================================
    function changeManager(address Manager) external manager {
        _manager = Manager;
    }

    function toggleMinting() external manager {
        _minting = !_minting;
    }

    function changeOwner1(address payable owner) external manager {
        TRAF.changeOwner1(owner);
    }
    
    function changeOwner2(address payable owner) external manager {
        TRAF.changeOwner2(owner);
    }

    function changePrice(uint256 newPrice) external manager {
        unchecked{_price = newPrice;}
    }

    function managerWithdraw(address payable to, uint256 amount) external manager {
        to.transfer(amount);
    }

    //User functions==============================================================================================================================

    function mint(uint256 amount) external payable {
        require(_minting, "Minting Is Off");
        require(DAW.balanceOf(msg.sender) > 0, "No DAW token found");
        require(msg.value == amount * _price, "Insufficient ETH");
            
        TRAF.adminMint(msg.sender, amount);
    }

}