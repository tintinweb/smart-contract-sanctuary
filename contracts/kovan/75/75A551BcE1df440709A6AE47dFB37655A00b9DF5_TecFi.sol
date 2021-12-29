/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity 0.5.1;

contract TecFi {
    mapping(address => uint256) public balances;
    address payable wallet;

    event Transfer(address indexed from, uint256 amount);

    constructor(address payable _address) public {
        wallet = _address;
    }

    function custom() external payable {
        buyToken();
    }

    function buyToken() public payable {
        balances[msg.sender] += 1;
        wallet.transfer(msg.value);
        emit Transfer(msg.sender, 1);
    }
}