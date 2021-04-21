/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier: MIT
// The following contract is a simplified version of https://github.com/rstormsf/multisender.
pragma solidity >=0.6.0 <0.7.0;


contract BatchTransaction {
	event MultiSended(address indexed _from, address[] _to, uint256[] _value);
	event FeeChanged(uint256 _fee);
	event ArrayLimitChanged(uint256 _len);

	uint256 internal contractFee = 0.0005 ether; // A contract-caller has to pay this fee to get service
	uint256 internal arrayLimit = 10;
	address internal authorizedAddr;

	constructor() public {
		authorizedAddr = msg.sender;
	}

	function changeFee(uint256 fee) public {
		require(msg.sender == authorizedAddr);
		contractFee = fee;
		emit FeeChanged(fee);
	}

	function changeArrayLimit(uint256 len) public {
		require(msg.sender == authorizedAddr);
		arrayLimit = len;
		emit ArrayLimitChanged(len);
	}

	function multisendEther(address[] memory _toAddrs, uint256[] memory _values) public payable {
        uint256 total = msg.value;
        require(total >= contractFee);
        require(_toAddrs.length <= arrayLimit);
        total = total - contractFee;
        uint256 i = 0;

        for (i; i < _toAddrs.length; i++) {
            require(total >= _values[i]);
            total = total - _values[i];
            address payable addr_ = address(uint160(_toAddrs[i]));
            addr_.transfer(_values[i]);
        }
        emit MultiSended(msg.sender, _toAddrs, _values);
    }
}