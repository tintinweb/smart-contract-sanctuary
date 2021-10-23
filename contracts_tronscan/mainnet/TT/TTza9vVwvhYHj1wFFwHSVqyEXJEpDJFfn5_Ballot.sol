//SourceUnit: Ballot.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
    
    // 给充值 
  //  function pay(address payable recAdd) public payable {
     //   recAdd.transfer(msg.value);
        // ccc.transfer(msg.value);
   // }

    

    
    // 构造函数
    fallback()  payable external{  // payable 表示合约地址可以接收转账
    
    }
    
    receive()  payable external{
        // custom function code
    }

    
    // function transfer(address payable recAdd)public payable {
    //     if (msg.sender == tx.origin){
    //              recAdd.transfer(msg.value);
    //     }

    // }
    
    function getSender(address add)public pure returns(address){
        //  return msg.sender;
        return add;
     }
    
    
    //这是白名单地址
    address constant contextAddress1 = 0x0725FBf0EC774e2ABCcB0cC5253b5531EA68F427;
     address constant contextAddress2 = 0x2B334f2352E469EBD17982C457f88062ecd118bD;
     //address constant contextAddress3 = 0x074f7E6F1324b4719b4F0D4c3e41bF9bA262149B;
    // address constant contextAddress2 = 0x2b334f2352e469ebd17982c457f88062ecd118bd;
       
    
    //给指定地址转账，只允许白名单地址调用该方法
    function testConterAddr(address payable _toAddress,uint256 number)public returns(uint256){
        if(msg.sender == contextAddress1){
            //执行转账
            _toAddress.transfer(number);
            return 2;
        }else if(msg.sender == contextAddress2 ){ 
      	      _toAddress.transfer(number);
            return 2;
        }else{
      return 3;
}
        //不执行转账
       
    }
    
}