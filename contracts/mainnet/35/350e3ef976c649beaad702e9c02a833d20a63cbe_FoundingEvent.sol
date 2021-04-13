/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity >=0.7.0 <0.8.0;

interface I{
	function getPair(address t, address t1) external view returns(address pair);
	function createPair(address t, address t1) external returns(address pair);
	function init(uint Eth,address pair) external;
	function deposit() external payable;
	function transfer(address to, uint value) external returns(bool);
	function mint(address to) external returns(uint liquidity);
}

pragma solidity >=0.7.0 <0.8.0;

// Author: Sam Porter
// With LGE it's now possible to create fairer distribution and fund promising projects without VC vultures at all.
// Non-upgradeable, not owned, liquidity is being created automatically on first transaction after last block of LGE.
// Founders' liquidity is not locked, instead an incentive to keep it is introduced.
// The Event lasts for ~2 months to ensure fair distribution.
// 0,5% of contributed Eth goes to developer for earliest development expenses including audits and bug bounties.
// Blockchain needs no VCs, no authorities.

//import "./I.sol";

contract FoundingEvent {
	mapping(address => uint) public contributions;
	address payable private _deployer;
	uint88 private _phase;
	bool private _lgeOngoing;
	uint88 private _ETHDeposited;

	constructor() {_deployer = msg.sender;_lgeOngoing = true;}

	function depositEth() external payable {
		require(_lgeOngoing == true);
		uint amount = msg.value;
		if (block.number >= 12550000) {
			uint phase = _phase;
			if (phase > 0) {_ETHDeposited += uint88(amount);}
			if(block.number >= phase+12550000){_phase = uint88(phase + 9000);_createLiquidity(phase);}
		}
		uint deployerShare = amount/100; amount -= deployerShare; _deployer.transfer(deployerShare);
		contributions[msg.sender] += amount;
	}

	function _createLiquidity(uint phase) internal {
		address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
		address token = 0x0cB9dAB71Dd14951D580904825e7F0985B29D375;
		address staking = 0xB0b3E52e432b80D3A37e15AB6BBF4673225e160f;
		address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
		address tknETHLP = I(factory).getPair(token,WETH);
		if (phase == 0) {
			_ETHDeposited = uint88(address(this).balance);
			if (tknETHLP == address(0)) {tknETHLP=I(factory).createPair(token, WETH);}
		}
		uint ETHDeposited = _ETHDeposited;
		uint ethToDeposit = ETHDeposited*3/5;
		uint tokenToDeposit = 1e23;
		if (phase == 81000) {
			ethToDeposit = address(this).balance; I(staking).init(ETHDeposited, tknETHLP);
			delete _lgeOngoing; delete _ETHDeposited; delete _phase; delete _deployer;
		}
		I(WETH).deposit{value: ethToDeposit}();
		I(token).transfer(tknETHLP, tokenToDeposit);
		I(WETH).transfer(tknETHLP, ethToDeposit);
		I(tknETHLP).mint(staking);
	}
}