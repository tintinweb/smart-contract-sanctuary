/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// pragma solidity ^0.4.11;
// contract DataStore {
//     uint256 data;

//     function set(uint256 x) public {
//         data = x;
//     }

//     function get() public view returns (uint256) {
//         return data;
//     }
// }


// pragma solidity ^0.4.11; 
// contract DataStore {
//     function set(uint256 x) public;
// }
 
// contract Caller {
//     function call(address tokenaddr,uint256 x) public {
//         address addr = tokenaddr;//填写第一个合约地址 0xb26b587f5ccfae2b05d0ffa197f79f519ea5bf69
//         DataStore dataStore = DataStore(addr);
//         dataStore.set(x);
//     }
// }
//第二个合约0x10aa20140e52b01e0ca89bff8115fa8fc7f03574


pragma solidity ^0.4.11; 


//https://learnblockchain.cn/question/1577
// interface IToken {
// 	 function transfer(address to, uint value) external returns (bool);
// }
// contract A {
// 	function testTransfer(IToken tokenaddr, address to, uint value) external {
// 		tokenaddr.transfer(to, value);
//        }
// }

interface IToken {
	 function transfer(address to, uint value) public;
}
contract A {
	function Erc20Transfer(IToken tokenaddr, address to, uint value) public {
		tokenaddr.transfer(to, value);
       }
}


//token合约 0x82bbb8326c02a172ba927dff525b60e10dbdcc3a

//写入读取合约
// pragma solidity ^0.4.21;
// contract LuckyNumber {
//   mapping(address => uint) numbers;

//   function setNum(uint _num) public {
//     numbers[msg.sender] = _num;
//   }

//   function getNum(address _myAddress) public view returns (uint) {
//     return numbers[_myAddress];
//   }
// }