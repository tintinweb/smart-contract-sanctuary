/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

pragma solidity ^0.8;

interface Itestint{
        function leaveMessage(string memory text) external;        
    }

/*contract MyContract {
  address NumberInterfaceAddress = 0xab38... 
  // ^ The address of the FavoriteNumber contract on Ethereum
  NumberInterface numberContract = NumberInterface(NumberInterfaceAddress);
  // Now `numberContract` is pointing to the other contract

  function someFunction() public {
    // Now we can call `getNum` from that contract:
    uint num = numberContract.getNum(msg.sender);
    // ...and do something with `num` here
  }
}*/

contract tryi {
    //address testint=0x8a5aa349e8ec265bf8e74d205967d25868c2d438;
    Itestint pointer=Itestint(0x8A5aa349e8Ec265bF8e74d205967D25868c2D438);

    function setmsg(string memory text) public {
        pointer.leaveMessage(text);
    }
}