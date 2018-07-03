pragma solidity ^0.4.9;

 /*
 * Contract that is working with ERC223 tokens
 */
 
 contract ContractReceiver2 {
     
     
     
    event TokenFallback (address _sender, address _origin, uint _value, bytes _data);
    function tokenFallback(address _sender, address _origin, uint _value, bytes _data) returns (bool ok) {
         TokenFallback(_sender, _origin, _value, _data);
        return true;
    }
     
    // struct TKN {
    //     address sender;
    //     uint value;
    //     bytes data;
    //     bytes4 sig;
    // }
    
    
    // //function tokenFallback(address _from, uint _value, bytes _data) public pure {
    // function tokenFallback(address _sender, address _origin, uint _value, bytes _data) public {
    //   TKN memory tkn;
    //   tkn.sender = _sender;
    //   tkn.value = _value;
    //   tkn.data = _data;
    //   uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
    //   tkn.sig = bytes4(u);
      
    //   TokenFallback(_sender, _origin, _value, _data);
      

      
    //   /* tkn variable is analogue of msg variable of Ether transaction
    //   *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
    //   *  tkn.value the number of tokens that were sent   (analogue of msg.value)
    //   *  tkn.data is data of token transaction   (analogue of msg.data)
    //   *  tkn.sig is 4 bytes signature of function
    //   *  if data of token transaction is a function execution
    //   */
    // }
}