/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ISupplyController {
	function mintIncentive(address addr) external;
	function mintableIncentive(address addr) external view returns (uint);
	function mint(address token, address owner, uint amount) external;
}

interface IADXToken {
	function transfer(address to, uint256 amount) external returns (bool);
	function transferFrom(address from, address to, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address spender) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function totalSupply() external returns (uint);
	function supplyController() external view returns (ISupplyController);
	function changeSupplyController(address newSupplyController) external;
	function mint(address owner, uint amount) external;
}

contract ADXSupplyController {
	enum GovernanceLevel { None, Mint, All }

	uint public immutable CAP = 150000000 * 1e18;
	IADXToken public immutable ADX = IADXToken(0x6170ea3629a1E49B77EEd0e0A18460ac184CA71e);

	mapping (address => uint8) public governance;
	// Some addresses (eg StakingPools) are incentivized with a certain allowance of ADX per year
	mapping (address => uint) public incentivePerSecond;
	// Keep track of when incentive tokens were last minted for a given addr
	mapping (address => uint) public incentiveLastMint;

	constructor() {
		governance[msg.sender] = uint8(GovernanceLevel.All);
	}

	function changeSupplyController(address newSupplyController) external {
		require(governance[msg.sender] >= uint8(GovernanceLevel.All), 'NOT_GOVERNANCE');
		ADX.changeSupplyController(newSupplyController);
	}

	function setGovernance(address addr, uint8 level) external {
		require(governance[msg.sender] >= uint8(GovernanceLevel.All), 'NOT_GOVERNANCE');
		governance[addr] = level;
	}

	function setIncentive(address addr, uint amountPerSecond) external {
		require(governance[msg.sender] >= uint8(GovernanceLevel.All), 'NOT_GOVERNANCE');
		// no more than 1 ADX per second
		require(amountPerSecond < 1e18, 'AMOUNT_TOO_LARGE');
		incentiveLastMint[addr] = block.timestamp;
		incentivePerSecond[addr] = amountPerSecond;
	}

	function innerMint(IADXToken token, address owner, uint amount) internal {
		uint totalSupplyAfter = token.totalSupply() + amount;
		require(totalSupplyAfter <= CAP, 'MINT_TOO_LARGE');
		token.mint(owner, amount);
	}

	// Kept because it's used for ADXLoyaltyPool
	function mint(IADXToken token, address owner, uint amount) external {
		require(governance[msg.sender] >= uint8(GovernanceLevel.Mint), 'NOT_GOVERNANCE');
		innerMint(token, owner, amount);
	}

	// Incentive mechanism
	function mintableIncentive(address addr) public view returns (uint) {
		return (block.timestamp - incentiveLastMint[addr]) * incentivePerSecond[addr];
	}

	function mintIncentive(address addr) external {
		uint amount = mintableIncentive(addr);
		incentiveLastMint[addr] = block.timestamp;
		innerMint(ADX, addr, amount);
	}
}