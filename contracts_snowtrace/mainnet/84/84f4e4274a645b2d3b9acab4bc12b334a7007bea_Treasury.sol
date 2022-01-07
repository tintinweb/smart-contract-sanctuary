/**
 *Submitted for verification at snowtrace.io on 2022-01-07
*/

pragma solidity ^0.8.6;

interface I{
	function transfer(address to, uint value) external returns(bool);
	function balanceOf(address) external view returns(uint);
	function genesisBlock() external view returns(uint);
	function invested(address a) external view returns(uint);
	function claimed(address a) external view returns(bool);
	function getNodeNumberOf(address a) external view returns(uint);
	function getRewardAmountOf(address a) external view returns(uint,uint);
}

contract Treasury {
	address private _governance;
	address private _oracle;
	address private _letToken;
	address private _snowToken;
	address private _snowPresale;
	uint public totalAirdrops;
	uint public epochBlock;

	struct AirdropRecepient {
		uint128 amount;
		uint128 lastClaim;
	}

	mapping (address => AirdropRecepient) public airdrops;
	mapping (address => bool) public snowCheck;
	

	function init() public {
		_governance=msg.sender;
		_letToken = 0x017fe17065B6F973F1bad851ED8c9461c0169c31;////
		_snowPresale = 0x60BA9aAA57Aa638a60c524a3ac24Da91e04cFA5C;
		_snowToken = 0x539cB40D3670fE03Dbe67857C4d8da307a70B305;
	}

	function _getRate() internal view returns(uint){
		uint rate = 62e14;
		return rate;
	}

    function invested(address a)public view returns(uint){
        return I(_snowPresale).invested(a);
    }

    function claimed(address a)public view returns(bool){
        return I(_snowPresale).claimed(a);
    }

    function getNodeNumberOf(address a)public view returns(uint){
        return I(_snowToken).getNodeNumberOf(a);
    }

    function getRewardAmountOf(address a)public view returns(uint){
        (uint rew,) = I(_snowToken).getRewardAmountOf(a);
        return rew;
    }
}