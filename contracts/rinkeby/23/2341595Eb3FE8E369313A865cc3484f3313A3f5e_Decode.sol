/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract Decode{
  //公匙：0x60320b8a71bc314404ef7d194ad8cac0bee1e331
  //公钥是用来算出来后对比看看是否一直一致的
  
  //sha3(msg): 0x4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45 (web3.sha3("abc");)
  //这个是数据的哈希，验证签名时用到
  
  //签名后的数据：0xf4128988cbe7df8315440adde412a8955f7f5ff9a5468a791433727f82717a6753bd71882079522207060b681fbd3f5623ee7ed66e33fc8e581f442acbcf6ab800
  //签名后的数据，包含r,s，v三个内容
  
  //验证签名入口函数
  function decode(bytes memory _signature,string memory _msg) public pure returns (address){
      (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
      return ecrecoverDecode(r,s,v,keccak256(abi.encodePacked(_msg)));
      
  }
  function splitSignature(bytes memory signature)
        public pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
  //切片函数
  function slice(bytes memory data,uint start,uint len) public pure returns(bytes memory){
      bytes memory b=new bytes(len);
      for(uint i=0;i<len;i++){
          b[i]=data[i+start];
      }
      return b;
  }
  //使用ecrecover恢复出公钥，后对比
  function ecrecoverDecode(bytes32 r,bytes32 s, uint8 v1,bytes32 msghash) public pure returns(address addr){
      uint8 v=v1+27;
      addr=ecrecover(msghash, v, r, s);
  }
  //bytes转换为bytes32
  function bytesToBytes32(bytes memory source) public pure returns(bytes32 result){
      assembly{
          result :=mload(add(source,32))
      }
  }
}