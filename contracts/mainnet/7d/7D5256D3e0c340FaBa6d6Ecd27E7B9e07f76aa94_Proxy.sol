/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library AddressUtils {
	function isContract(address addr) internal view returns (bool) {
		uint256 size;
		// solium-disable-next-line security/no-inline-assembly
		assembly { size := extcodesize(addr) }
		return size > 0;
	}
}

contract Proxy {
	using AddressUtils for address;

	bytes32 private constant ADMIN_SLOT = 0xde50c0ef4724e938441b7d87888451dee5481c5f4cdb090e8051ee74ce71c31c;
	bytes32 private constant IMPLEMENTATION_SLOT = 0x454e447e72dbaa44ab6e98057df04d15461fc11a64ce58e5e1472346dea4223f;

	constructor (address _i) {
		require(_i.isContract());

		_setImplementation(_i);
		_setAdmin(msg.sender);
	}

	event AdminChanged (address admin);
	event Upgraded (address implementation);

	modifier onlyAdmin () {
		require(msg.sender == _admin());
		_;
	}

	 /// @dev 更换Proxy合约的管理者
	 /// @param _newAdmin 新的管理者地址
	function proxyChangeAdmin(address _newAdmin) external onlyAdmin {
		require(_newAdmin != address(0));
		_setAdmin(_newAdmin);
		emit AdminChanged(_newAdmin);
	}

	/// @dev 升级使用的Bounty合约
	/// @param _newImplementation 新的合约地址
	function proxyUpgradeTo(address _newImplementation) public onlyAdmin {
		require(_newImplementation.isContract());
		_setImplementation(_newImplementation);
		emit Upgraded(_newImplementation);
	}

	 /// @dev 升级使用的Bounty合约并且直接执行调用
	 /// @param _newImplementation 新的合约地址
	 /// @param _data 需要在新合约上调用的方法编码
	function proxyUpgradeToAndCall(
		address _newImplementation,
		bytes calldata _data
	) external payable onlyAdmin returns (bytes memory) {
		proxyUpgradeTo(_newImplementation);
		(bool success, bytes memory data) = address(this).call{value:msg.value}(_data);
		require(success);
		return data;
	}

	function _admin () internal view returns (address a) {
		bytes32 slot = ADMIN_SLOT;
		assembly {
			a := sload(slot)
		}
	}

	function _implementation () internal view returns (address i) {
		bytes32 slot = IMPLEMENTATION_SLOT;
		assembly {
			i := sload(slot)
		}
	}

	function admin() external view onlyAdmin returns (address) {
		return _admin();
	}

	function implementation() external view onlyAdmin returns (address) {
		return _implementation();
	}

	function _setAdmin (address newAdmin) internal {
		bytes32 slot = ADMIN_SLOT;
		assembly {
			sstore(slot, newAdmin)
		}
	}

	function _setImplementation (address newImplementation) internal {
		bytes32 slot = IMPLEMENTATION_SLOT;
		assembly {
			sstore(slot, newImplementation)
		}
	}

	 /// @dev fallback函数，除了proxyChangeAdmin和proxyUpgradeTo方法以外的所有
	 /// 对合约的调用均会最终会被执行该方法。函数会将所有调用的data直接转发至Bounty合
	 /// 约，并返回对应的结果。
	fallback () external payable {
		address i = _implementation();
		// solium-disable-next-line security/no-inline-assembly
		assembly {
			calldatacopy(0, 0, calldatasize())

			let result := delegatecall(gas(), i, 0, calldatasize(), 0, 0)

			returndatacopy(0, 0, returndatasize())

			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}

	receive () external payable {
    revert();
  }
}