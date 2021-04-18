/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Scam {
    event event_addAcc(address addr, uint256 amount, uint256 total);
    event event_accuInt(address addr, uint256 duration, uint256 accuint);
    event event_distInt(address addr, uint256 diff, uint256 distint);

    struct Account {
        uint256 startdate_;
        uint256 amount_;
        uint256 accuint_;
        uint256 distint_;
    }

    address payable creator_;
    address[] alladdr_;
    mapping(address=>Account) acctbl_;

    constructor() {
    	creator_ = payable(msg.sender);
    }

    function addAcc(address addr, uint256 amount) public {
        acctbl_[addr].startdate_ = block.timestamp;
        acctbl_[addr].amount_ += amount;
        acctbl_[addr].accuint_ = 0;
        acctbl_[addr].distint_ = 0;
        if (acctbl_[addr].amount_ == amount) {
            alladdr_.push(addr);
        }
        emit event_addAcc(addr, amount, acctbl_[addr].amount_);
    }

    function accuInt() internal {
        uint256 timestamp = block.timestamp;
        for(uint i=0; i<alladdr_.length; i++){
            address addr = alladdr_[i];
            uint256 duration = (timestamp - acctbl_[addr].startdate_) / 60 / 60 / 24;
        	if (duration >= 1) {
                acctbl_[addr].accuint_ = acctbl_[addr].amount_ * duration * 10 / 100;
                emit event_accuInt(addr, duration, acctbl_[addr].accuint_);
        	}
        }
    }

    function distInt() internal returns (bool) {
        bool okay = true;
        uint256 bal = address(this).balance;
        for(uint i=0; i<alladdr_.length; i++) {
            address addr = alladdr_[i];
            uint256 diff = acctbl_[addr].accuint_ - acctbl_[addr].distint_;
        	if (diff > 0) {
                address payable recv = payable(addr);
        	    if (bal > diff) {
        	        recv.transfer(diff);
                    acctbl_[addr].distint_ = acctbl_[addr].accuint_;
                    emit event_distInt(addr, diff, acctbl_[addr].distint_);
        	        bal -= diff;
        	    }
        	    else {
        	        recv.transfer(bal);
                    okay = false;
                    break;
        	    }
        	}
        }
        return okay;
    }

    fallback() external payable {
    }

    receive() external payable {
        accuInt();
        if (distInt()) {
            addAcc(msg.sender, msg.value);
        }
        else {
            bankrupt();
        }
    }

    modifier IsZeroBalance(){
        require(address(this).balance == 0, "Balance is not zero!");
        _;
    }

    function bankrupt() internal IsZeroBalance {
        selfdestruct(creator_);
    }

}