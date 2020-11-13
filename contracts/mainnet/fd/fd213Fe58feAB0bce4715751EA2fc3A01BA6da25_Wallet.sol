// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.6.99 <0.8.0;

contract Wallet {

	address public architect;
	address public owner;
	address public relayer;
	uint public unlockStartDate;
	uint public unlockEndDate;
	uint createdAt;
	uint iterations;
	uint latestETHClaim = 0;
	uint latestTokenClaim = 0;

	event Received(address from, uint amount);
	event ClaimedETH(address to, uint amount);
	event ClaimedToken(address tokenContract, address to, uint amount);

	modifier onlyAllowed {
		require(msg.sender == owner || msg.sender == relayer, "Not allowed.");
		_;
	}

	constructor(
		address _architect,
		address _owner,
		address _relayer,
		uint _iterations,
		uint _unlockStartDate,
		uint _unlockEndDate
	)
		payable
  {
		require(_iterations > 0 && _unlockStartDate >= block.timestamp && _unlockEndDate >= _unlockStartDate, "Wrong parameters.");
		architect = _architect;
		owner = _owner;
		relayer = _relayer;
		iterations = _iterations;
		unlockStartDate = _unlockStartDate;
		unlockEndDate = _unlockEndDate;
		createdAt = block.timestamp;
	}

	receive ()
		external
		payable
	{
    emit Received(msg.sender, msg.value);
  }

	function info()
		public
		view
		returns(address, address, uint, uint, uint, uint, uint, uint, uint, uint)
	{
	  return (architect, owner, createdAt, unlockStartDate, unlockEndDate, iterations, currentIteration(), latestTokenClaim, latestETHClaim, address(this).balance);
	}

	function currentIteration()
		private
		view
		returns (uint)
	{
		if(block.timestamp >= unlockEndDate) {
			return iterations;
		} else if(block.timestamp >= unlockStartDate) {
			uint i = iterations * (block.timestamp - unlockStartDate) / (unlockEndDate - unlockStartDate) + 1;
			if(i > iterations) {
				return iterations;
			} else {
				return i;
			}
		} else {
			return 0;
		}
	}

	function claim(address _tokenContract) onlyAllowed public {
		require(block.timestamp >= unlockStartDate, "Asset cannot be unlocked yet.");
		if(address(0) == _tokenContract) {
			claimETH();
		} else {
			claimToken(_tokenContract);
		}
	}

	function claimETH() private {
		require(latestETHClaim >= iterations || latestETHClaim < currentIteration(), "ETH cannot be unlocked yet.");
		uint amount = address(this).balance;
		if(block.timestamp < unlockEndDate && latestETHClaim < iterations) {
			amount = amount / (iterations - latestETHClaim);
			latestETHClaim++;
		}
		payable(owner).transfer(amount);
    emit ClaimedETH(owner, amount);
  }

  function claimToken(address _tokenContract) private {
		require(latestTokenClaim >= iterations || latestTokenClaim < currentIteration(), "Token cannot be unlocked yet.");
		IERC20 token = IERC20(_tokenContract);
		uint amount = token.balanceOf(address(this));
		if(block.timestamp < unlockEndDate && latestTokenClaim < iterations) {
			amount = amount / (iterations - latestTokenClaim);
			latestTokenClaim++;
		}
    token.transfer(owner, amount);
    emit ClaimedToken(_tokenContract, owner, amount);
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
