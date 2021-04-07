/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity 0.8.3;

contract MinerPayment {
    mapping (address => address) private _minerReceivingAddresses;
    
    event FlashbotsPayment(address coinbase, address receivingAddress, address msgSender, uint256 amount);
    event RecipientUpdate(address coinbase, address receivingAddress);
    
    receive() external payable {
        _payMiner();
    }
    
    function setMinerReceivingAddress(address _newReceivingAddress) external {
        _minerReceivingAddresses[msg.sender] = _newReceivingAddress;
        emit RecipientUpdate(msg.sender, _newReceivingAddress);
    }
    
    function _getMinerReceivingAddress(address _who) private view returns (address) {
        address receivingAddress = _minerReceivingAddresses[_who];
        return (receivingAddress == address(0)) ? _who : receivingAddress;
    }
    
    function getMinerReceivingAddress(address _who) external view returns (address) {
        return _getMinerReceivingAddress(_who);
    }
    
    function _payMiner() private {
        address receivingAddress = _getMinerReceivingAddress(block.coinbase);
        uint256 amount = address(this).balance;
        payable(receivingAddress).transfer(amount);
        emit FlashbotsPayment(block.coinbase, receivingAddress, msg.sender, amount);
    }
    
    function payMiner() external payable {
        _payMiner();
    }
    
    function queueEther() external payable { }
}