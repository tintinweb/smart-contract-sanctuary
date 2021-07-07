/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

pragma solidity ^0.8.0;

contract PayPoint {
    address public owner;
    event Terbayar(uint8 invoice, address sender, uint amount);

    constructor(address _owner) payable {
        require(_owner != address(0), "owner = zero address");
        owner = _owner;
    }

    function bayarETH(uint8 _invoice) public payable {
        emit Terbayar(_invoice, msg.sender, msg.value);
    }

    function tarikETH(uint _amount) public {
        require(_amount <= address(this).balance, "You're withdrawing too much");
        require(_amount != uint(0), "Cant withdraw zero balance");

        (bool success,) = owner.call{value: _amount}("");
        require(success, "Process failed");
    }
    
}