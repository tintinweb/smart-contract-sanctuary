//SourceUnit: trontrust.sol

pragma solidity >=0.4.23 <0.6.0;

contract trontrust {

event SentDividends(address referrerAddress , uint value);
    
function buyNewLevel(address[] userAddress, uint[] value) external payable {

         uint8 i = 0;
         uint totalbal = 0 ;
        for (i; i < userAddress.length; i++) {
        if (!address(uint160(userAddress[i])).send(value[i])) {
            totalbal = (totalbal + value[i]);
            return address(uint160(userAddress[i])).transfer(value[i]);
            }
        }
        emit SentDividends(msg.sender,totalbal);
    }
}