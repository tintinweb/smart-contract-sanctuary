/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


contract Swapable {
   
    struct AddressBalance {
        string oldAddress;
        uint256 balance;
    }
    mapping(string => uint256) internal map;

    function add(AddressBalance[] memory addressBalance) public {
        for (uint i=0; i< addressBalance.length; i++) {
          map[addressBalance[i].oldAddress] = addressBalance[i].balance;
        }
    }
    
    function check(string memory oldAddress) public view returns (uint256) {
        return map[oldAddress];
    }
}