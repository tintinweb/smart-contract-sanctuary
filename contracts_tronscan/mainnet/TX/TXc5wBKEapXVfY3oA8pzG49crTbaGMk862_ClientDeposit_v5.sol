//SourceUnit: ClientDeposit_v5.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.18;

import "./trc20.sol";

contract ClientDeposit_v5 {
    
    address constant public MASTER_WALLET = 0x175EE9BC350237e847eE3603aaB05D446164CE8d;
	address constant public USDT_CONTRACT = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C; // USDT Contract
    address public ownerAddress;
    
    constructor() public {
        ownerAddress = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only owner");
        _;
    }
	
    function getBalance_TRX() public view returns(uint) {
        return address(this).balance;
    }
	
	function getBalance_USDT() public view returns(uint) {
		TRC20 token = TRC20(USDT_CONTRACT);
        return token.balanceOf(address(this));
    }
    
    function withdrawToMaster_TRX() public onlyOwner returns (bool) {
        address payable to = address(uint160(MASTER_WALLET));
        uint balAmt = address(this).balance;
        if (balAmt > 0) 
        {
            to.transfer(balAmt);
            return true;
        }
        else
        {
            return false;
        }
    }
    
    function withdrawToMaster_USDT() public onlyOwner returns (bool) {
		TRC20 token = TRC20(USDT_CONTRACT);
		address payable to = address(uint160(MASTER_WALLET));
		uint balAmt = token.balanceOf(address(this));
		if (balAmt > 0) 
        {
            return token.transfer(to, balAmt);
        }
        else
        {
            return false;
        }
    }
}


//SourceUnit: trc20.sol

/// TRC20.sol -- API for the TRC20 token standard

// See <https://github.com/tronprotocol/tips/blob/master/tip-20.md>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

pragma solidity ^0.5.18;

contract TRC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract TRC20 is TRC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}