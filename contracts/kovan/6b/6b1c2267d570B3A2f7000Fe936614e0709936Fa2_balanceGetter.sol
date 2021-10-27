/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity 0.8.7;

contract balanceGetter {
    address private adr= 0xb2f55315C465297A5926795d5Bb94f985209398E;

    /** @notice get the address stored in 'adr' */
    function getAddress() public view returns(address){
        return adr;
    }

    /** @notice get the balance value of the address stored in 'adr" 
        @return the ether balance value in wei */
    function getBalance() public view returns(uint){
        return adr.balance;
    }
}