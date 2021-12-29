/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity 0.5.1;

contract TecFi {
    mapping(address => uint256) public balances;
    // address payable wallet;

    event Transfer(address indexed from, uint256 amount);

    // constructor(address payable _address) public {
    //     wallet = _address;
    // }

    function buyToken(address payable tokenAddress, uint256 amount) public payable {
        balances[tokenAddress] += amount;
        // tokenAddress.transfer(amount);
        emit Transfer(msg.sender, amount);
    }
}