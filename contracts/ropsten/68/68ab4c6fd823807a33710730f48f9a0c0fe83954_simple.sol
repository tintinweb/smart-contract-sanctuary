/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity >=0.4.22 <0.6.0;

contract simple {
    mapping(string => int) private
 accounts;

    function open(string memory acc_id, int amount) public {
        accounts[acc_id] = amount;
    }

    function query(string memory acc_id) public view returns (int amount) {
        amount = accounts[acc_id];
    }

    function transfer(string memory acc_from, string memory acc_to, int amount) public {
        accounts[acc_from] -= amount;
        accounts[acc_to] += amount;
    }
}