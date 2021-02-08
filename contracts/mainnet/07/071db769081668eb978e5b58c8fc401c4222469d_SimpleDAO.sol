/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ETHPoly {
	function balanceOf(address) external view returns (uint256);
	function dividendsOf(address) external view returns (uint256);
	function liquidate(uint256) external returns (uint256);
	function withdraw() external returns (uint256);
}

contract SimpleDAO {

	uint256 constant private MIN_VOTES = 4;
	uint256 constant private LIQUIDATION_PERCENT = 20;

	address payable private splitter = 0xF287d505377Ef7D39DfEC6e28c7EF62BD056AAD6;
	address payable[] private targets;
	mapping(address => bool) private votes;

	address private deployer;
	ETHPoly private ethPoly;

	constructor() public {
		deployer = msg.sender;
		targets.push(0xACE5BeedDDc24dec659eeEcb21A3C21F5576e3C9);
		targets.push(0xba5e44BCa8FB64BFF682E1F774850B1CA598fF11);
		targets.push(0xB01D1EcadB6b24D809386af88551c35Bd12e82dA);
		targets.push(0xCafe59428b2946FBc128fd6C36cb1Ec1443AeD6C);
		targets.push(0xD1CEbD1Ad772c8A6dD05eCdFA0ae776a9266032c);
		targets.push(0xea5e37c75383331a1de5b7f7f1a93Ef080b319Be);
		targets.push(0xFADE7bB65A1e06D11B3F099b225ddC7C8Ae65967);
		targets.push(0xFEED4873Ab0D642dD4b694EdA6FF90cD732fE4C9);
		targets.push(0xce1179C2e69edBaCaB52485a75C0Ae4a979b0919);
		targets.push(0xC0DE642aEfD2c8fbEaB09bbA9474461080b715f9);
		targets.push(0xface14522b18BE412e9DB0E1570Be94Cb9af0A88);
		targets.push(0xC0015CfE8C0e00423E2D84853E5A9052EdcdF8b2);
	}

	receive() external payable {}

	function setETHPoly(ETHPoly _ethPoly) external {
		require(msg.sender == deployer);
		ethPoly = _ethPoly;
	}

	function process() public {
		if (ethPoly.dividendsOf(address(this)) > 0) {
			ethPoly.withdraw();
		}
		uint256 _balance = address(this).balance;
		if (_balance > 0) {
			splitter.transfer(_balance);
		}
	}

	function vote() external {
		require(!voted(msg.sender));
		votes[msg.sender] = true;
		if (totalVotes() >= MIN_VOTES) {
			ethPoly.liquidate(ethPoly.balanceOf(address(this)) * LIQUIDATION_PERCENT / 100);
			process();
			_resetVotes();
		}
	}

	function unvote() external {
		require(voted(msg.sender));
		votes[msg.sender] = false;
	}


	function totalVotes() public view returns (uint256) {
		uint256 _count = 0;
		for (uint256 i = 0; i < targets.length; i++) {
			if (voted(targets[i])) {
				_count++;
			}
		}
		return _count;
	}
	
	function voted(address _user) public view returns (bool) {
		return votes[_user];
	}


	function _resetVotes() internal {
		for (uint256 i = 0; i < targets.length; i++) {
			votes[targets[i]] = false;
		}
	}
}