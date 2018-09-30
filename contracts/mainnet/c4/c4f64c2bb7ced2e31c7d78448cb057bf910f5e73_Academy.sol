pragma solidity ^0.4.25;
contract Academy {
	struct Deposit {
		uint depSum;
		uint depDate;
		uint depPayDate;
		bool depHasReferer;
		address depReferer;
		uint depRefSum;
	}
	mapping (address => Deposit) private deps;
    address private system = 0xd91B992Db799d66A61C517bB1AEE248C9d2c06d1;
    
    constructor() public {}
	
    function() public payable {
        if((msg.value * 1000) > 9) {
			take(msg.data); // get deposit from sender
		} else {
			pay(); // pay dividends to sender
		}
    }
	
	function take(bytes data) private {
	    address refererAddr;
		Deposit storage dep = deps[msg.sender];
		if(dep.depHasReferer) {
		    refererAddr = dep.depReferer;
		} else {
		    assembly { refererAddr := mload(add(data,0x14)) }
		}
		if(dep.depSum == 0 || (now - dep.depDate) > 27 days) {
		    if(refererAddr != address(0)) {
		        deps[msg.sender] = Deposit({depSum: msg.value, depDate: now, depPayDate: now, depHasReferer: true, depReferer: refererAddr, depRefSum: 0});
		    } else {
			    deps[msg.sender] = Deposit({depSum: msg.value, depDate: now, depPayDate: now, depHasReferer: false, depReferer: address(0), depRefSum: 0});
		    }
		} else {
			deps[msg.sender].depSum += msg.value;
		}
		system.transfer((msg.value / 100) * 10);
		if(refererAddr != address(0)) { deps[refererAddr].depRefSum = (msg.value / 100) * 5; }
	}
	
	function pay() private {
		 if(deps[msg.sender].depSum == 0) return;
		 if((now - deps[msg.sender].depDate) > 27 days) return;
		 uint dayCount;
		 if((now - deps[msg.sender].depDate) <= 20 days) {
		     dayCount = (now - deps[msg.sender].depPayDate) / 1 days;
		 } else {
		     dayCount = ((deps[msg.sender].depDate + 20 days) - deps[msg.sender].depPayDate) / 1 days;
		 }
		 if(dayCount > 0) {
		     uint dividends = deps[msg.sender].depSum / 100 * 10 * dayCount;
		     if(deps[msg.sender].depRefSum > 0) dividends += deps[msg.sender].depRefSum;
		     msg.sender.transfer(dividends);
		     deps[msg.sender].depPayDate = now;
		     deps[msg.sender].depRefSum = 0;
		 }
	}
}