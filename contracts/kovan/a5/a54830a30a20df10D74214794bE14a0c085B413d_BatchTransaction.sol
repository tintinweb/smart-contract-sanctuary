/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: MIT
// The following contract is a simplified version of https://github.com/rstormsf/multisender.
pragma solidity >=0.6.0 <0.7.0;


contract BatchTransaction {
	event MultiSended(address indexed _from, address[] _to, uint256[] _value);
	event FeeChanged(uint256 _fee);
	event ArrayLimitChanged(uint256 _len);
	event Withdrawn(address indexed receiver, uint256 amount);

	uint256 internal contractFee = 0.0005 ether; // A contract-caller has to pay this fee to get service
	uint256 internal arrayLimit = 10;
	address internal authorizedAddr;

	constructor() public {
		authorizedAddr = msg.sender;
	}

	function changeFee(uint256 fee) public {
		require(msg.sender == authorizedAddr, "You are not authorized.");
		contractFee = fee;
		emit FeeChanged(fee);
	}

	function changeArrayLimit(uint256 len) public {
		require(msg.sender == authorizedAddr, "You are not authorized.");
		arrayLimit = len;
		emit ArrayLimitChanged(len);
	}

	function withdraw(address payable receiver) public {
		require(msg.sender == authorizedAddr, "You are not authorized.");
		uint256 amount = address(this).balance;
        emit Withdrawn(receiver, amount);
        receiver.transfer(amount);
	}

	function multisendEther(address[] memory _toAddrs, uint256[] memory _values) public payable {
        uint256 total = msg.value;
        require(total >= contractFee, "Do not have enough value to pay the fee.");
        require(_toAddrs.length <= arrayLimit, "Too long array.");
        total = total - contractFee;
        uint256 i = 0;

        for (i; i < _toAddrs.length; i++) {
            require(total >= _values[i], "Do not have enough value to pay.");
            total = total - _values[i];
            address payable addr_ = address(uint160(_toAddrs[i]));
            addr_.transfer(_values[i]);
        }
        emit MultiSended(msg.sender, _toAddrs, _values);
    }

	function checkContractFee() public view returns(uint){
		return contractFee;
	}

	function checkArrayLimit() public view returns(uint){
		return arrayLimit;
	}
}