/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

pragma solidity ^0.8.0;

contract TestPayable{
    
    uint private nonce;

    function random() public returns (uint) {
      uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) ;
      randomnumber = randomnumber + 1;
      nonce++;        
      return randomnumber;
    }
    
    function testSlippage(uint maxSlippage,uint amountOut) public returns (uint minAmountOut){
    
        minAmountOut = amountOut - ((amountOut * maxSlippage) / 10**18/ 100);
    }
     uint256 public betnum;
    event received(uint msg);
    mapping (address => uint256) public balances;
    address payable owner;
  //  address payable withdrawAddr;
     
     modifier onlyOwner() {
        require (msg.sender == owner);
        _;

    }
    
      fallback()  external payable {
         betnum=msg.value;
        
    }
    
    //constructor(address payable _withdrawAddr) payable public {
    //   withdrawAddr = _withdrawAddr;
  //  }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
     function withdraw() public payable onlyOwner returns(bool) {
       payable(msg.sender).transfer(address(this).balance);
       //payable(address(this)).transfer(msg.value);
        return true;

    }
}