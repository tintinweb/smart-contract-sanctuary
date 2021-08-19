// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ConvertLib{
	function convert(uint amount,uint conversionRate) public pure returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConvertLib.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract MetaCoin {
	mapping (address => uint) balances;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	
	// constructor funkcija se kliče le pri deploymentu in potem nikoli več
	constructor() public {
		balances[tx.origin] = 10000;
	}

	// funckije, ki spreminjajo stanje je treba podpisat, nekaj stanejo.
	// transakcije imajo opcijo 'msg', npr. msg.sender
	function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
		require(balances[msg.sender] >= amount,"NOT_ENOUGH_FUNDS");

		balances[msg.sender] -= amount;
		balances[receiver] += amount;
		emit Transfer(msg.sender, receiver, amount);
		return true;
	}

	// view funkcije (samo berejo) ne porabljajo nobenih resourcov - so zastonj
	function getBalanceInEth(address addr) public view returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) public view returns(uint) {
		return balances[addr];
	}
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {
    "/contracts/ConvertLib.sol": {
      "ConvertLib": "0xC82d1025b3f0686D8499B4efF3b75aBD432b5A60"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}