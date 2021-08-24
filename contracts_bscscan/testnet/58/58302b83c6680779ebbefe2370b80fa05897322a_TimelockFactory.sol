// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";

contract TokenTimelock {
    IERC20 private _token;
    address private _beneficiary;
    uint256 private _nextReleaseTime;
    uint256 private _releaseAmount;
    uint256 private _releasePeriod;

    TimelockFactory private _factory;

    event Released(address indexed beneficiary, uint256 amount);
    event BeneficiaryTransferred(address indexed previousBeneficiary, address indexed newBeneficiary);

	constructor(){
		_token = IERC20(address(1));
	}

	function init(IERC20 token_, address beneficiary_, uint256 releaseStart_, uint256 releaseAmount_, uint256 releasePeriod_) external {
		require(_token == IERC20(address(0)), "TokenTimelock: already initialized");
		require(token_ != IERC20(address(0)), "TokenTimelock: erc20 token address is zero");
        require(beneficiary_ != address(0), "TokenTimelock: beneficiary address is zero");
        require(releasePeriod_ == 0 || releaseAmount_ != 0, "TokenTimelock: release amount is zero");

        emit BeneficiaryTransferred(address(0), beneficiary_);

        _token = token_;
        _beneficiary = beneficiary_;
        _nextReleaseTime = releaseStart_;
        _releaseAmount = releaseAmount_;
        _releasePeriod = releasePeriod_;

        _factory = TimelockFactory(msg.sender);
	}

    function token() public view virtual returns (IERC20) {
        return _token;
    }

    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    function nextReleaseTime() public view virtual returns (uint256) {
        return _nextReleaseTime;
    }

    function releaseAmount() public view virtual returns (uint256) {
        return _releaseAmount;
    }

    function balance() public view virtual returns (uint256) {
        return token().balanceOf(address(this));
    }

    function releasableAmount() public view virtual returns (uint256) {
        if (block.timestamp < _nextReleaseTime) return 0;

        uint256 amount = balance();
        if (amount == 0) return 0;
        if (_releasePeriod == 0) return amount;

        uint256 passedPeriods = (block.timestamp - _nextReleaseTime) / _releasePeriod;
        uint256 maxReleasableAmount = (passedPeriods + 1) * _releaseAmount;
        
        if (amount <= maxReleasableAmount) return amount;
        return maxReleasableAmount;
    }

    function releasePeriod() public view virtual returns (uint256) {
        return _releasePeriod;
    }

    function release() public virtual returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= nextReleaseTime(), "TokenTimelock: current time is before release time");

        uint256 _releasableAmount = releasableAmount();
        require(_releasableAmount > 0, "TokenTimelock: no releasable tokens");

        emit Released(beneficiary(), _releasableAmount);
        require(token().transfer(beneficiary(), _releasableAmount));

        if (_releasePeriod != 0) {
            uint256 passedPeriods = (block.timestamp - _nextReleaseTime) / _releasePeriod;
            _nextReleaseTime += (passedPeriods + 1) * _releasePeriod;
        }

        return true;
    }

    function transferBeneficiary(address newBeneficiary) public virtual returns (bool) {
		require(msg.sender == beneficiary(), "TokenTimelock: caller is not the beneficiary");
		require(newBeneficiary != address(0), "TokenTimelock: the new beneficiary is zero address");
		
        emit BeneficiaryTransferred(beneficiary(), newBeneficiary);
		_beneficiary = newBeneficiary;
		return true;
	}

    function split(address splitBeneficiary, uint256 splitAmount) public virtual returns (bool) {
        uint256 _amount = balance();
		require(msg.sender == beneficiary(), "TokenTimelock: caller is not the beneficiary");
		require(splitBeneficiary != address(0), "TokenTimelock: beneficiary address is zero");
        require(splitAmount > 0, "TokenTimelock: amount is zero");
        require(splitAmount <= _amount, "TokenTimelock: amount exceeds balance");

        uint256 splitReleaseAmount;
        if (_releasePeriod > 0) {
            splitReleaseAmount = _releaseAmount * splitAmount / _amount;
        }

        address newTimelock = _factory.createTimelock(token(), splitBeneficiary, _nextReleaseTime, splitReleaseAmount, _releasePeriod);

        require(token().transfer(newTimelock, splitAmount));
        _releaseAmount -= splitReleaseAmount;
		return true;
	}
}

contract CloneFactory {
  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }
}

contract TimelockFactory is CloneFactory {
	address private _tokenTimelockImpl;
	event Timelock(address timelockContract);
	constructor() {
		_tokenTimelockImpl = address(new TokenTimelock());
	}
	function createTimelock(IERC20 token, address to, uint256 releaseTime, uint256 releaseAmount, uint256 period) public returns (address) {
		address clone = createClone(_tokenTimelockImpl);
		TokenTimelock(clone).init(token, to, releaseTime, releaseAmount, period);

		emit Timelock(clone);
		return clone;
	}
}