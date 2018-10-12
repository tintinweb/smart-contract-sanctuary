pragma solidity ^0.4.25;
contract HelloEthereum {
	// 註解範例（範例1）
	string public msg1;

	string private msg2; // 註解範例（範例2）
	/* 註解範例（範例3） */
	address public owner;
	uint8 public counter;
	/// Constructor（建構子）
	constructor (string _msg1) public {
		// 將msg1設為_msg1
		msg1 = _msg1;
		// 將owner設定成此合約（Contract）所產生的位址（address）
		owner = msg.sender;
		//作為起始，將 counter設為0
		counter = 0;
	}
	/// msg2的setter
	function setMsg2(string _msg2) public {
		// if句的範例
		if(owner != msg.sender) {
			revert();
		} else {
			msg2 = _msg2;
		}
	}
	// msg2的getter
	function getMsg2() constant public returns(string) {
		return msg2;
	}
	function setCounter() public {
		// for句的範例
		for(uint8 i = 0; i < 3; i++) {
			counter++;
		}
	}
}