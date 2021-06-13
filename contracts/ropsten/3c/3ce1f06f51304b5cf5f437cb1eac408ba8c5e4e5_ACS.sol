/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.8.4;

contract ACS {
    address payable wallet;
    mapping(address => uint256) public balances;
    event Purchase(
        address indexed _buyer,
        uint256 _amount
    );

    constructor(address payable _wallet) public {
        wallet = _wallet;
    }

    fallback() external payable {
        buyToken();
    }

    function buyToken() public payable {
        balances[msg.sender] += 1;
        wallet.transfer(msg.value);
        emit Purchase(msg.sender, 1);
    }
}