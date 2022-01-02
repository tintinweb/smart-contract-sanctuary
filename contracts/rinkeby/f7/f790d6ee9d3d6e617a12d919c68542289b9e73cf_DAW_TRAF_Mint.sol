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

contract DAW_TRAF_Mint {
    
    ITRAF TRAF;
    
    address private _manager;
    
    uint256 private _price = 550000000000000000;

    mapping(address => uint256) private _balance;//The amount of pure mint passes the user has

    bool private _minting = true; //If minting is on or off

    modifier manager {
        require(msg.sender == _manager);
        _;
    }
    
    receive() external payable {}
    
    constructor(address TRAFcontract) {
        _manager = msg.sender;
        TRAF = ITRAF(TRAFcontract);
    }

    function setClaims(address[] calldata users, uint256[] calldata amount) external manager {
        unchecked {

            uint256 length = amount.length;
            
            for(uint256 t; t < length; ++t) {
                _balance[users[t]] = amount[t];
            }

        }
    }
    
    //Read Functions======================================================================================================================================================
    function owner() external view returns (address) {
        return _manager;
    }

    function claimables(address user) external view returns(uint256) {return _balance[user];}

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

    function claim(uint256 amount) external payable {
        unchecked {
            require(_minting, "Minting Is Off");
            require(msg.value == amount * _price, "Insufficient ETH");
            require(_balance[msg.sender] >= amount, "Insufficient Claims");
            
            _balance[msg.sender] -= amount;
            
            TRAF.adminMint(msg.sender, amount);
        }
    }

}