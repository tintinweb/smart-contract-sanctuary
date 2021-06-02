/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

pragma solidity ^0.4.21;
// compiles with v0.4.25

contract DiaOracle {
	address owner;

	struct CoinInfo {
		uint256 price;
		uint256 supply;
		uint256 lastUpdateTimestamp;
		string symbol;
		string lastSignedData;
	}

	mapping(string => CoinInfo) diaOracles;
	
	event newCoinInfo(
		string name,
		string symbol,
		uint256 price,
		uint256 supply,
		uint256 lastUpdateTimestamp,
		string  lastSignedData
	);
    
	constructor() public {
		owner = msg.sender;
	}

	function changeOwner(address newOwner) public {
		require(msg.sender == owner);
		owner = newOwner;
	}
    
	function updateCoinInfo(string name, string symbol, uint256 newPrice, uint256 newSupply, uint256 newTimestamp,string lastSignedData) public {
		require(msg.sender == owner);
		diaOracles[name] = (CoinInfo(newPrice, newSupply, newTimestamp, symbol, lastSignedData));
		emit newCoinInfo(name, symbol, newPrice, newSupply, newTimestamp, lastSignedData);
	}
    
	function getCoinInfo(string name) public view returns (uint256, uint256, uint256, string,string) {
		return (
			diaOracles[name].price,
			diaOracles[name].supply,
			diaOracles[name].lastUpdateTimestamp,
			diaOracles[name].symbol,
			diaOracles[name].lastSignedData
		);
	}
}