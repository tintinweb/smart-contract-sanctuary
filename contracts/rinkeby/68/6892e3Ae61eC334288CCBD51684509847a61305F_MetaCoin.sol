// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;  // definira za kateri kompailer je contract spisan, ne deluje če ni kompatibilna verzija. (^0.8.0; definira use od 0.8.0 - 0.8.9)

library ConvertLib{
	function convert(uint amount,uint conversionRate) public pure returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;  // definira za kateri kompailer je contract spisan, ne deluje če ni kompatibilna verzija. (^0.8.0; definira use od 0.8.0 - 0.8.9)



import "./ConvertLib.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract MetaCoin {
	mapping (address => uint) balances;

	event Transfer(address indexed _from, address indexed _to, uint256 _value); // Listen to events... catching events true socket

	constructor() public {
		balances[tx.origin] = 10000;  // kliče se jo samo ob deploymentu in nikoli kasneje ni mozno dostopati do nje 
		// tx.origin --> ne uporabljati, ker je lahko nevarno za attacke.
	}

	function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
		require(balances[msg.sender] >= amount,"NOT_ENOUGH_FUNDS");

		balances[msg.sender] -= amount; //msg senderju se odbije od stanja
		balances[receiver] += amount; // pristeje ista vsota reciverju
		emit Transfer(msg.sender, receiver, amount);
		return true;
	}

	function getBalanceInEth(address addr) public view returns(uint){
		return ConvertLib.convert(getBalance(addr),2);
	}

	function getBalance(address addr) public view returns(uint) {
		return balances[addr];  // reading from chain (funkcija ne spreminja ničesar in so FREE)
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
      "ConvertLib": "0x462aB0D8936B443dDa33fB939326d72b0336fAc6"
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