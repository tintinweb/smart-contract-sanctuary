/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

pragma solidity ^0.4.6;

// --------------------------
//  R Split Contract
// --------------------------
contract RSPLT_I {
    	event StatEvent(string msg);
    	event StatEventI(string msg, uint val);

	enum SettingStateValue  {debug, locked}

	struct partnerAccount {
		uint credited;  // total funds credited to this account
		uint balance;   // current balance = credited - amount withdrawn
		uint pctx10;     // percent allocation times ten
		address addr;   // payout addr of this acct
		bool evenStart; // even split up to evenDistThresh
	}

// -----------------------------
//  data storage
// ----------------------------------------
	address public owner;                                // deployer executor
	mapping (uint => partnerAccount) partnerAccounts;    // accounts by index
	uint public numAccounts;                             // how many accounts exist
	uint public holdoverBalance; 		             // amount yet to be distributed
        uint public totalFundsReceived;                      // amount received since begin of time	
        uint public totalFundsDistributed;                   // amount distributed since begin of time	
        uint public totalFundsWithdrawn;                     // amount withdrawn since begin of time	
	uint public evenDistThresh;                          // distribute evenly until this amount (total)
	uint public withdrawGas = 35000;                     // gas for withdrawals
	uint constant TENHUNDWEI = 1000;                     // need gt. 1000 wei to do payout
	uint constant MAX_ACCOUNTS = 5;                      // max accounts this contract can handle
	SettingStateValue public settingsState = SettingStateValue.debug; 


	// --------------------
	// contract constructor
	// --------------------
	function RSPLT_I() {
		owner = msg.sender;
	}


	// -----------------------------------
	// lock
	// lock the contract. after calling this you will not be able to modify accounts.
	// make sure everyhting is right!
	// -----------------------------------
	function lock() {
		if (msg.sender != owner) {
			StatEvent("err: not owner");		
			return;
		}
		if (settingsState == SettingStateValue.locked) {
			StatEvent("err: locked");		
			return;
		}
		settingsState = SettingStateValue.locked;
		StatEvent("ok: contract locked");
	}


	// -----------------------------------
	// reset
	// reset all accounts
	// in case we have any funds that have not been withdrawn, they become
	// newly received and undistributed.
	// -----------------------------------
	function reset() {
		if (msg.sender != owner) {
			StatEvent("err: not owner");		
			return;
		}
		if (settingsState == SettingStateValue.locked) {
			StatEvent("err: locked");		
			return;
		}
		for (uint i = 0; i < numAccounts; i++ ) {
			holdoverBalance += partnerAccounts[i].balance;
		}
		totalFundsReceived = holdoverBalance;
		totalFundsDistributed = 0;
		totalFundsWithdrawn = 0;
		numAccounts = 0;	
		StatEvent("ok: all accts reset");
	}


	// -----------------------------------
	// set even distribution threshold
	// -----------------------------------
	function setEvenDistThresh(uint256 _thresh) {
		if (msg.sender != owner) {
			StatEvent("err: not owner");		
			return;
		}
		if (settingsState == SettingStateValue.locked) {
			StatEvent("err: locked");		
			return;
		}
		evenDistThresh = (_thresh / TENHUNDWEI) * TENHUNDWEI;
		StatEventI("ok: threshold set", evenDistThresh);
	}


	// -----------------------------------
	// set even distribution threshold
	// -----------------------------------
	function setWitdrawGas(uint256 _withdrawGas) {
		if (msg.sender != owner) {
			StatEvent("err: not owner");		
			return;
		}
		withdrawGas = _withdrawGas;
		StatEventI("ok: withdraw gas set", withdrawGas);
	}
	

	// ---------------------------------------------------
	// add a new account
	// ---------------------------------------------------
	function addAccount(address _addr, uint256 _pctx10, bool _evenStart) {
		if (msg.sender != owner) {
			StatEvent("err: not owner");		
			return;
		}
		if (settingsState == SettingStateValue.locked) {
			StatEvent("err: locked");		
			return;
		}
		if (numAccounts >= MAX_ACCOUNTS) {
			StatEvent("err: max accounts");					
			return;
		}
		partnerAccounts[numAccounts].addr = _addr;
		partnerAccounts[numAccounts].pctx10 = _pctx10;
		partnerAccounts[numAccounts].evenStart = _evenStart;
		partnerAccounts[numAccounts].credited = 0;
		partnerAccounts[numAccounts].balance = 0;
		++numAccounts;
		StatEvent("ok: acct added");		
	}


	// ----------------------------
	// get acct info
	// ----------------------------
	function getAccountInfo(address _addr) constant returns(uint _idx, uint _pctx10, bool _evenStart, uint _credited, uint _balance) {
		for (uint i = 0; i < numAccounts; i++ ) {
			address addr = partnerAccounts[i].addr;			
			if (addr == _addr) {
				_idx = i;
				_pctx10 = partnerAccounts[i].pctx10;
				_evenStart = partnerAccounts[i].evenStart;
				_credited = partnerAccounts[i].credited;
				_balance = partnerAccounts[i].balance;
				StatEvent("ok: found acct");						
				return;
			}
		}
		StatEvent("err: acct not found");		
	}


	// ----------------------------
	// get total percentages x10
	// ----------------------------
	function getTotalPctx10() constant returns(uint _totalPctx10) {
		_totalPctx10 = 0;
		for (uint i = 0; i < numAccounts; i++ ) {
			_totalPctx10 += partnerAccounts[i].pctx10;
		}
		StatEventI("ok: total pctx10", _totalPctx10);						
	}


	// ----------------------------
	// get no. accts that are set for even split
	// ----------------------------
	function getNumEvenSplits() constant returns(uint _numEvenSplits) {
		_numEvenSplits = 0;
		for (uint i = 0; i < numAccounts; i++ ) {
			if (partnerAccounts[i].evenStart) {
				++_numEvenSplits;
			}
		}
		StatEventI("ok: even splits", _numEvenSplits);						
	}

	
	// -------------------------------------------
	// default payable function.
	// call us with plenty of gas, or catastrophe will ensue
	// note: you can call this fcn with amount of zero to force distribution
	// -------------------------------------------
	function () payable {
		totalFundsReceived += msg.value;
		holdoverBalance += msg.value;
		StatEventI("ok: incoming", msg.value);
	}
	

	// ----------------------------
	// distribute funds to all partners
	// ----------------------------
	function distribute() {
		//only payout if we have more than 1000 wei
		if (holdoverBalance < TENHUNDWEI) {
			return;
		}
		//first pay accounts that are not constrained by even distribution
		//each account gets their prescribed percentage of this holdover.
		uint i;
		uint pctx10;
		uint acctDist;
		uint maxAcctDist;
		uint numEvenSplits = 0;
		for (i = 0; i < numAccounts; i++ ) {
			if (partnerAccounts[i].evenStart) {
				++numEvenSplits;
			} else {
				pctx10 = partnerAccounts[i].pctx10;
				acctDist = holdoverBalance * pctx10 / TENHUNDWEI;
				//we also double check to ensure that the amount awarded cannot exceed the
				//total amount due to this acct. note: this check is necessary, cuz here we
				//might not distribute the full holdover amount during each pass.
				maxAcctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
				if (partnerAccounts[i].credited >= maxAcctDist) {
					acctDist = 0;
				} else if (partnerAccounts[i].credited + acctDist > maxAcctDist) {
					acctDist = maxAcctDist - partnerAccounts[i].credited;
				}
				partnerAccounts[i].credited += acctDist;
				partnerAccounts[i].balance += acctDist;
				totalFundsDistributed += acctDist;
				holdoverBalance -= acctDist;
			}
		}
		//now pay accounts that are constrained by even distribution. we split whatever is
		//left of the holdover evenly.
		uint distAmount = holdoverBalance;
		if (totalFundsDistributed < evenDistThresh) {
			for (i = 0; i < numAccounts; i++ ) {			
				if (partnerAccounts[i].evenStart) {
					acctDist = distAmount / numEvenSplits;
					//we also double check to ensure that the amount awarded cannot exceed the
					//total amount due to this acct. note: this check is necessary, cuz here we
					//might not distribute the full holdover amount during each pass.
					uint fundLimit = totalFundsReceived;
					if (fundLimit > evenDistThresh)
						fundLimit = evenDistThresh;
					maxAcctDist = fundLimit / numEvenSplits;
					if (partnerAccounts[i].credited >= maxAcctDist) {
						acctDist = 0;
					} else if (partnerAccounts[i].credited + acctDist > maxAcctDist) {
						acctDist = maxAcctDist - partnerAccounts[i].credited;
					}
					partnerAccounts[i].credited += acctDist;
					partnerAccounts[i].balance += acctDist;
					totalFundsDistributed += acctDist;
					holdoverBalance -= acctDist;
				}
			}
		}
		//now, if there are any funds left then it means that we have either exceeded the even distribution threshold,
		//or there is a remainder in the even split. in that case distribute all the remmaing funds to partners who have
		//not yet exceeded their allotment, according to their "effective" percentages. note that this must be done here,
		//even if we haven't passed the even distribution threshold, to ensure that we don't get stuck with a remainder
		//amount that cannot be distributed.
		distAmount = holdoverBalance;
		if (distAmount > 0) {
			uint totalDistPctx10 = 0;
			for (i = 0; i < numAccounts; i++ ) {
				pctx10 = partnerAccounts[i].pctx10;
				maxAcctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
				if (partnerAccounts[i].credited < maxAcctDist) {
					totalDistPctx10 += pctx10;
				}
			}
			for (i = 0; i < numAccounts; i++ ) {
				pctx10 = partnerAccounts[i].pctx10;
				acctDist = distAmount * pctx10 / totalDistPctx10;
				//we also double check to ensure that the amount awarded cannot exceed the
				//total amount due to this acct. note: this check is necessary, cuz here we
				//might not distribute the full holdover amount during each pass.					
				maxAcctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
				if (partnerAccounts[i].credited >= maxAcctDist) {
					acctDist = 0;
				} else if (partnerAccounts[i].credited + acctDist > maxAcctDist) {
					acctDist = maxAcctDist - partnerAccounts[i].credited;
				}
				partnerAccounts[i].credited += acctDist;
				partnerAccounts[i].balance += acctDist;
				totalFundsDistributed += acctDist;
				holdoverBalance -= acctDist;
			}
		}
		StatEvent("ok: distributed funds");
	}


 	// ----------------------------
	// withdraw account balance
	// ----------------------------
	function withdraw() {
		for (uint i = 0; i < numAccounts; i++ ) {
			address addr = partnerAccounts[i].addr;			
			if (addr == msg.sender || msg.sender == owner) {
				uint amount = partnerAccounts[i].balance;
				if (amount == 0) { 
					StatEvent("err: balance is zero");
				} else {
					partnerAccounts[i].balance = 0;
					totalFundsWithdrawn += amount;
					if (!addr.call.gas(withdrawGas).value(amount)()) {
					        partnerAccounts[i].balance = amount;
						totalFundsWithdrawn -= amount;
						StatEvent("err: error sending funds");
						return;
					}
					StatEventI("ok: rewards paid", amount);
				}
			}
		}
	}


 	// ----------------------------
	// suicide
	// ----------------------------
        function hariKari() {
		if (msg.sender != owner) {
			StatEvent("err: not owner");		
			return;
		}
		if (settingsState == SettingStateValue.locked) {
			StatEvent("err: locked");		
			return;
		}
		suicide(owner);
	}

}