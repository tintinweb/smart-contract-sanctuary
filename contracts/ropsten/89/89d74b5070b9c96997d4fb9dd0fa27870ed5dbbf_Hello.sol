pragma solidity ^0.4.23;

contract Hello {
	address admin;
	mapping (address => uint256) signedMap;

	modifier onlyAdmin() {
		require(msg.sender == admin);
		_;
	}

	constructor() public {
		admin = msg.sender;
	}

	//返回当前时间
	function nowInSeconds() internal view returns (uint256) {
		return now;
	}

	//签到
	function signed() public {
		signedMap[msg.sender] = nowInSeconds();
	}

	//获取上次签到时间
	function getLastSignedTime() public view returns (uint256) {
		return signedMap[msg.sender];
	}

	//取消签到
	function unsigned() public {
		delete signedMap[msg.sender];
	}

	//管理员删除用户签到
	function adminUnsigned(address addr) onlyAdmin public {
		delete signedMap[addr];
	}

	//管理员获取用户签到时间
	function adminGetLastSignedTime(address addr) onlyAdmin public view returns (uint256) {
		return signedMap[addr];
	}
}