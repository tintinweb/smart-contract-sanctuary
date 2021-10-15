/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.5.0;

contract Counter {

    address ZRX_EXCHANGE_PROXY = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    // Public variable of type unsigned int to keep the number of counts
    uint256 public count = 0;

    // Function that increments our counter
    function increment() public {
        count += 1;
    }
    
    // Function that increments our counter
    function set(uint256 amount) public {
        count = amount;
    }

    // Not necessary getter to get the count value
    function getCount() public view returns (uint256) {
        return count;
    }
    
    function zrxTrade(bytes memory _calldataHexString) public payable {
        //do trade
        address(ZRX_EXCHANGE_PROXY).call.value(msg.value)(_calldataHexString);
    }

}