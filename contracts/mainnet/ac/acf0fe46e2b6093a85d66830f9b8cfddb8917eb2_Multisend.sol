/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: MIT
// The following contract is a simplified version of https://github.com/rstormsf/multisender.
pragma solidity >=0.6.0 <0.7.0;


contract Multisend {
    event Multisended(address indexed _from, address[] _to, uint256[] _value);
    event FeeChanged(uint256 _fee);
    event AuthorizedAddrChanged(address _newAuthorizedAddr);
    event Withdrawn(address indexed receiver, uint256 amount);

    uint256 internal contractFee = 0 ether; // A contract-caller has to pay this fee to get service
    address internal authorizedAddr;

    constructor() public {
        authorizedAddr = msg.sender;
    }

    function changeFee(uint256 fee) public {
        require(msg.sender == authorizedAddr, "You are not authorized.");
        contractFee = fee;
        emit FeeChanged(fee);
    }

    function changeAuthorizedAddr(address newAuthorizedAddr) public {
        require(msg.sender == authorizedAddr, "You are not authorized.");
        authorizedAddr = newAuthorizedAddr;
        emit AuthorizedAddrChanged(newAuthorizedAddr);
    }

    function withdraw(address payable receiver) public {
        require(msg.sender == authorizedAddr, "You are not authorized.");
        uint256 amount = address(this).balance;
        emit Withdrawn(receiver, amount);
        receiver.transfer(amount);
    }

    function multisendEther(address[] memory receivers, uint256[] memory amounts) public payable {
        uint256 total = msg.value;
        require(total >= contractFee, "Do not have enough tokens to pay the contract fee.");
        total = total - contractFee;
        uint256 i = 0;

        for (i; i < receivers.length; i++) {
            require(total >= amounts[i], "Do not have enough tokens to send.");
            total = total - amounts[i];
            address payable receiver = address(uint160(receivers[i]));
            receiver.transfer(amounts[i]);
        }
        emit Multisended(msg.sender, receivers, amounts);
    }

    function checkContractFee() public view returns(uint){
        return contractFee;
    }

    function checkAuthorizedAddr() public view returns(address){
        return authorizedAddr;
    }
}