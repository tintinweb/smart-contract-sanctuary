/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

//
// VSDC
// Virtual Stable Denomination Coin: Token Contract V1
// Apr 2021
//

// //////////////////////////////////////////////////////////////////////////////// //
//                                                                                  //
//                               ////   //////   /////                              //
//                              //        //     //                                 //
//                              //        //     /////                              //
//                                                                                  //
//                              Never break the chain.                              //
//                                  http://RTC.wtf                                  //
//                                                                                  //
// //////////////////////////////////////////////////////////////////////////////// //

// SPDX-License-Identifier: MIT
// File: contracts/VSDC.sol

pragma solidity ^0.6.0;

contract VSDC {
    string  public name     = "VSDCoin";
    string  public symbol   = "VSDC";
    uint8   public decimals = 18;
    uint    public supply   = 0;

    bool    public LOCKED   = false;
    uint    public TIMELOCK = 0;

    event  Lock(address indexed src);
    event  Grace(address indexed src);
    event  Unlock(address indexed src);

    event  AddOwner(address indexed src, address indexed guy);
    event  RemoveOwner(address indexed src, address indexed guy);
    event  AddMinter(address indexed src, address indexed guy);
    event  RemoveMinter(address indexed src, address indexed guy);

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);

    mapping (address => bool)                       public  owners;
    mapping (address => bool)                       public  minters;
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor() public {
        owners[msg.sender] = true;
    }

    function totalSupply() public view returns (uint) {
        return supply;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);
        return true;
    }

    function lock() public returns (bool) {
        require(LOCKED == false);
        require(owners[msg.sender] == true);

        LOCKED = true;
        TIMELOCK = 0;

        emit Lock(msg.sender);
        return true;
    }
    
    function grace() public returns (bool) {
        require(LOCKED == true);
        require(owners[msg.sender] == true);

        TIMELOCK = block.timestamp + 7 days;

        emit Grace(msg.sender);
        return true;
    }

    function unlock() public returns (bool) {
        require(LOCKED == true);
        require(owners[msg.sender] == true);
        require(TIMELOCK < block.timestamp);

        LOCKED = false;

        emit Unlock(msg.sender);
        return true;
    }
    

    function addOwner(address guy) public returns (bool) {
        require(LOCKED == false);
        require(owners[msg.sender] == true);

        owners[guy] = true;

        emit AddOwner(msg.sender, guy);
        return true;
    }

    function removeOwner(address guy) public returns (bool) {
        require(LOCKED == false);
        require(owners[msg.sender] == true);

        owners[guy] = false;

        emit RemoveOwner(msg.sender, guy);
        return true;
    }

    function addMinter(address guy) public returns (bool) {
        require(LOCKED == false);
        require(owners[msg.sender] == true);

        minters[guy] = true;

        emit AddMinter(msg.sender, guy);
        return true;
    }

    function removeMinter(address guy) public returns (bool) {
        require(LOCKED == false);
        require(owners[msg.sender] == true);

        minters[guy] = false;

        emit RemoveMinter(msg.sender, guy);
        return true;
    }
    

    function mint(address guy, uint wad) public returns (bool) {
        require(minters[msg.sender] == true);
        require(guy != address(0));

        supply += wad;
        balanceOf[guy] += wad;
        
        emit Transfer(address(0), guy, wad);
        return true;
    }

    function burn(address guy, uint256 wad) public returns (bool) {
        require(minters[msg.sender] == true);
        require(guy != address(0));

        supply -= wad;
        balanceOf[guy] -= wad;
        
        emit Transfer(guy, address(0), wad);
        return true;
    }
}