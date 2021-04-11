/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity >=0.7.0 <0.8.0;

interface I{
	function getPair(address t, address t1) external view returns(address);
	function createPair(address t, address t1) external returns(address);
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
	bool private _lgeOngoing;
	address private _staking;
	uint88 private _ETHDeposited;
	bool private _notInit;

	constructor() {_deployer = msg.sender;_notInit = true;_lgeOngoing = true;}
	function init(address c) public {require(msg.sender == _deployer && _notInit == true);delete _notInit; _staking = c;}

	function depositEth() external payable {
		require(_lgeOngoing == true);
		uint amount = msg.value;
		uint deployerShare = amount/200; amount -= deployerShare; _deployer.transfer(deployerShare);
		contributions[msg.sender] += amount;
		if (block.number >= 12638999) {_createLiquidity();}
	}

	function _createLiquidity() internal {
		address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
		address token = 0xdff92dCc99150Df99D54BC3291bD7e5522bB1Edd;// hardcoded token address after erc20 will be deployed
		address staking = _staking;
		address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
		address tknETHLP = I(factory).getPair(token,WETH);
		if (tknETHLP == address(0)) {tknETHLP=I(factory).createPair(token, WETH);}
		uint ETHDeposited = address(this).balance;
		I(WETH).deposit{value: ETHDeposited}();
		I(token).transfer(tknETHLP, 1e24);
		I(WETH).transfer(tknETHLP, ETHDeposited);
		I(tknETHLP).mint(staking);
		I(staking).init(ETHDeposited, tknETHLP);
		delete _staking; delete _lgeOngoing; delete _deployer;
	}
}