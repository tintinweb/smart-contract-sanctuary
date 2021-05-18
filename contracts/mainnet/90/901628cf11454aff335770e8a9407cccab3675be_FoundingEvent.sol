/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

interface I{
	function getPair(address t, address t1) external view returns(address pair);
	function createPair(address t, address t1) external returns(address pair);
	function init(uint Eth,address pair) external;
	function deposit() external payable;
	function transfer(address to, uint value) external returns(bool);
	function mint(address to) external returns(uint liquidity);
}

pragma solidity >=0.8.4 <0.9.0;

// Author: Sam Porter
// With LGE it's now possible to create fairer distribution and fund promising projects without VC vultures at all.
// Non-upgradeable, not owned, liquidity is being created automatically on first transaction after last block of LGE.
// Founders' liquidity is not locked, instead an incentive to keep it is introduced.
// The Event lasts for ~2 months to ensure fair distribution.
// 0,5% of contributed Eth goes to developer for earliest development expenses including audits and bug bounties.
// Blockchain needs no VCs, no authorities.12600000 40000

contract FoundingEvent {
	mapping(address => uint) public contributions;
	address payable private _deployer;
	uint88 private _phase;
	bool public lgeOngoing;
	uint private _ETHDeposited;

	constructor() {_deployer = payable(msg.sender);lgeOngoing = true;}

	function depositEth() external payable {
		require(lgeOngoing == true);
		uint amount = msg.value;
		if (block.number >= 126e5) {uint phase = _phase; if(block.number >= phase+126e5){_createLiquidity(phase);}}
		uint deployerShare = amount/100; amount -= deployerShare; _deployer.transfer(deployerShare);
		contributions[msg.sender] += amount;
	}

	function _createLiquidity(uint phase) internal {
	    _phase = uint88(phase + 1e4);
		address payable WETH = payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
		address token = 0x1565616E3994353482Eb032f7583469F5e0bcBEC;
		address staking = 0x109533F9e10d4AEEf6d74F1e2D59a9ed11266f27;
		address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
		address tknETHLP = I(factory).getPair(token,WETH);
		if (tknETHLP == address(0)) {tknETHLP=I(factory).createPair(token, WETH);}
		_ETHDeposited += address(this).balance;
		uint ethToDeposit = address(this).balance;
		uint tokenToDeposit = 2e23;
		if (phase == 4e4) {I(staking).init(_ETHDeposited, tknETHLP);delete lgeOngoing; delete _ETHDeposited; delete _phase; delete _deployer;}
		I(WETH).deposit{value: ethToDeposit}();
		I(token).transfer(tknETHLP, tokenToDeposit);
		I(WETH).transfer(tknETHLP, ethToDeposit);
		I(tknETHLP).mint(staking);
	}
}