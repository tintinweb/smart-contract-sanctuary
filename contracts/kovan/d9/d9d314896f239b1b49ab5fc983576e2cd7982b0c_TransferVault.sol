pragma solidity ^0.7.0;

import "SafeMath.sol";
import "Ownable.sol";


contract TransferVault is Ownable {
    using SafeMath for uint256;


    constructor() {
    }

    function send() public payable {
        require(msg.value > 0, "No ETH sent!");
      }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(address payable _to, uint256 _amount)
    public onlyOwner
    {
      require(_amount <= getBalance(), "Amount larger than contract holds!");
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}