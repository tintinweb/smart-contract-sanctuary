/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/claim.sol

pragma solidity >=0.5.15;

////// src/claim.sol
/* pragma solidity >=0.5.15; */

contract TinlakeClaimRAD {
    mapping (address => bytes32) public accounts;
    event Claimed(address claimer, bytes32 account);

    function update(bytes32 account) public {
        require(account != 0);
        accounts[msg.sender] = account;
        emit Claimed(msg.sender, account);
    }
}