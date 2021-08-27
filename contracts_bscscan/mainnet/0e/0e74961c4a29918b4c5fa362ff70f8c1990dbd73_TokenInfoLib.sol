pragma solidity >= 0.5.0 < 0.6.0;


import "./SafeMath.sol";
import "./SignedSafeMath.sol";
library TokenInfoLib {
    using SafeMath for uint256;
	using SignedSafeMath for int256;
    struct TokenInfo {
		int256 balance;
		int256 interest;
		uint256 rate;
		uint256 lastModification;
	}
	uint256 constant BASE = 10**12; 
	int256 constant POSITIVE = 1;
	int256 constant NEGATIVE = -1;

	// returns the sum of balance, interest posted to the account, and any additional intereset accrued up to the given timestamp
	function totalAmount(TokenInfo storage self, uint256 currentTimestamp) public view returns(int256) {
		return self.balance.add(viewInterest(self, currentTimestamp));
		//用户总余额不再取决于出块时间差 
		//return self.balance;
	}
	function totalnumber(TokenInfo storage self)public view returns(int256){
	    return self.balance;
	}
	
	function currentrate(TokenInfo storage self)public view returns(uint256){
	    return self.rate;
	}

	// returns the sum of balance and interest posted to the account
	function getCurrentTotalAmount(TokenInfo storage self) public view returns(int256) {
		return self.balance.add(self.interest);
	}
	
	function getInterest(TokenInfo storage self,uint256 currentTimestamp)public view returns(int256){
	    return viewInterest(self, currentTimestamp);
	}

	function minusAmount(TokenInfo storage self, uint256 amount, uint256 rate, uint256 currentTimestamp) public {
		resetInterest(self, currentTimestamp);
        int256 _amount = int256(amount);
		if (self.balance + self.interest > 0) {
			if (self.interest >= _amount) {
				self.interest = self.interest.sub(_amount);
				_amount = 0;
			} else if (self.balance.add(self.interest) >= _amount){
				self.balance = self.balance.sub(_amount.sub(self.interest));
				self.interest = 0;
				_amount = 0;
			} else {
                _amount = _amount.sub(self.balance.add(self.interest));
				self.balance = 0;
				self.interest = 0;
			}
		}
        if (_amount > 0) {
			require(self.balance.add(self.interest) <= 0, "To minus amount, the total balance must be smaller than 0.");
			self.balance = self.balance.sub(_amount);
		}
		self.rate = rate;
	}

	function addAmount(TokenInfo storage self, uint256 amount, uint256 rate, uint256 currentTimestamp) public returns(int256) {
		resetInterest(self, currentTimestamp);
		int256 _amount = int256(amount);
		if (self.balance.add(self.interest) < 0) {
            if (self.interest.add(_amount) <= 0) {
                self.interest = self.interest.add(_amount);
				_amount = 0;
			} else if (self.balance.add(self.interest).add(_amount) <= 0) {
				self.balance = self.balance.add(_amount.add(self.interest));
				self.interest = 0;
				_amount = 0;
			} else {
                _amount = _amount.add(self.balance.add(self.interest));
				self.balance = 0;
                self.interest = 0;
			}
		}
        if (_amount > 0) {
			require(self.balance.add(self.interest) >= 0, "To add amount, the total balance must be larger than 0.");
			self.balance = self.balance.add(_amount);
		}
		
		self.rate = rate;

		return totalAmount(self, currentTimestamp);
	}

	function mixRate(TokenInfo storage self, int256 amount, uint256 rate) private view returns (uint256){
		//TODO uint256(-self.balance) this will integer underflow - Critical Security risk
		//TODO Why do we need this???
        uint256 _balance = self.balance >= 0 ? uint256(self.balance) : uint256(-self.balance);
		uint256 _amount = amount >= 0 ? uint256(amount) : uint256(-amount);
		return _balance.mul(self.rate).add(_amount.mul(rate)).div(_balance + _amount);
	}

	function resetInterest(TokenInfo storage self, uint256 currentTimestamp) public {
		self.interest = viewInterest(self, currentTimestamp);
		self.lastModification = currentTimestamp;
	}

	function viewInterest(TokenInfo storage self, uint256 currentTimestamp) public view returns(int256) {
        int256 _sign = self.balance < 0 ? NEGATIVE : POSITIVE;
		//TODO uint256(-amount) ???
		uint256 _balance = self.balance >= 0 ? uint256(self.balance) : uint256(-self.balance);
		uint256 _interest = self.balance >= 0 ? uint256(self.interest) : uint256(-self.interest);
		uint256 _difference = currentTimestamp.sub(self.lastModification);

		return int(_interest)
			.add(int256(_balance.mul(self.rate).mul(_difference).div(BASE)))
			.mul(_sign);
	}
}