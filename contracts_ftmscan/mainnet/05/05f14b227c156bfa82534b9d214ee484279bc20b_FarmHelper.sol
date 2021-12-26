/**
 *Submitted for verification at FtmScan.com on 2021-12-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}
interface IERC721 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract FarmHelper {

    bytes4 public constant PoolInfoSel = bytes4(keccak256(bytes('poolInfo(uint256)')));
    bytes4 public constant UserInfoSel = bytes4(keccak256(bytes('userInfo(uint256,address)')));
    bytes4 public constant PendingSushiSel = bytes4(keccak256(bytes('pendingSushi(uint256,address)')));
    bytes4 public constant DecimalsSel = bytes4(keccak256(bytes('decimals()')));
    bytes4 public constant SupportsInterfaceSel = bytes4(keccak256(bytes('supportsInterface(bytes4)')));

    struct PoolData {
        uint256 pid;

        bytes data;
        address token;
        bool isErc721;
        uint8 decimals;

        uint256 allocPoint;
        uint256 amount;
        uint256 reserve0;
        uint256 reserve1;
        uint256 reserve2;

        uint256 allowance;
        uint256 balance;

        bytes userData;
        uint256 userData0;
        uint256 userData1;
        uint256 userData2;

        uint256 pending0;
        uint256 pending1;
     }

    // User info.
    // amount: uinit256
    // pid: amount, pending, allowance
    function userInfo(address masterchef_, uint256[] memory pids_, address account_, bool verbose_)
        public view returns (PoolData[] memory)
    {
        return _userInfo(masterchef_, pids_, account_, verbose_, PoolInfoSel, UserInfoSel, PendingSushiSel);
    }

    function _userInfo(address masterchef_, uint256[] memory pids_, address account_, bool verbose_,
        bytes4 poolInfoSel_, bytes4 userInfoSel_, bytes4 pendingSushiSel_)
        public view returns (PoolData[] memory)
    {
	    PoolData [] memory list = new PoolData[](pids_.length);
        for (uint256 i = 0; i < pids_.length; i++) {
            PoolData memory p = _poolInfo(masterchef_, poolInfoSel_, pids_[i], 0, 32, 64, 96, 128, 160);
            (p.userData0, p.userData1, p.userData2, p.userData) = _userInfo(masterchef_, userInfoSel_, pids_[i], account_);
            (p.pending0, p.pending1) = _pendingSushi(masterchef_, pendingSushiSel_, pids_[i], account_);
            p.isErc721 = _isErc721(p.token);
            if (p.isErc721) {
                bool isApproveAll = IERC721(p.token).isApprovedForAll(account_, masterchef_);
                p.allowance = isApproveAll? type(uint256).max: 0;
                p.decimals = 0;
            } else {
                p.allowance = IERC20(p.token).allowance(account_, masterchef_);
            }
            p.balance = IERC20(p.token).balanceOf(account_);
            if (!verbose_) {
                p.data = new bytes(0);
                p.userData = new bytes(0);
            }
            list[i] = p;
        }
        return list;
    }

    function _userInfo(address masterchef_, bytes4 sel_, uint256 pid_, address account_)
        public view returns (uint256 amount,uint256 amount2,uint256 amount3,bytes memory userdata)
    {
        (bool success, bytes memory data) = masterchef_.staticcall(abi.encodeWithSelector(sel_, pid_, account_));
        if (success) {
            amount = toUint256(data, 0);
            amount2 = toUint256(data, 32);
            amount3 = toUint256(data, 64);
            userdata = data;
        }
    }

  // Pool info.
    function poolInfo(address masterchef_, uint256[] memory pids_)
        public view returns (PoolData[] memory)
    {
	    PoolData [] memory p = new PoolData[](pids_.length);
        for (uint256 i = 0; i < pids_.length; i++) {
            p[i] = _poolInfo(masterchef_, pids_[i]);
        }
        return p;
    }
    function _poolInfo(address masterchef_, uint256 pid_) public view returns (PoolData memory) {
        return _poolInfo(masterchef_, PoolInfoSel, pid_, 0, 32, 64, 96, 128, 160);
    }

  // 
  // lpToken : address
  // allocPoint: uint256
  // amount: uint256
      function _poolInfo(address masterchef_, bytes4 sel_, uint256 pid_,
                        uint256 tpos_, uint256 apos_, uint256 amountpos_, uint256 rpos0_, uint256 rpos1_, uint256 rpos2_)
      public view returns (PoolData memory p)
    {
      (bool success, bytes memory data) = masterchef_.staticcall(abi.encodeWithSelector(sel_, pid_));
      p.pid = pid_;
      p.data = data;
      if (success) {
          p.token = toAddress(data, tpos_);
          p.decimals = _decimals(p.token);
          p.allocPoint = toUint256(data, apos_);
          p.amount = toUint256(data, amountpos_);
          p.reserve0 = toUint256(data, rpos0_);
          p.reserve1 = toUint256(data, rpos1_);
          p.reserve2 = toUint256(data, rpos2_);
      }
  }

  // ERC7210 no decimals;
    function _decimals(address token_) public view returns (uint8) {
      (bool success, bytes memory data) = token_.staticcall(abi.encodeWithSelector(DecimalsSel));
      if (success && data.length > 0) return abi.decode(data, (uint8));
      return 0;
    }

    function _pendingSushi(address masterchef_, bytes4 sel_, uint256 pid_, address account_)
        public view returns (uint256 amount0,uint256 amount1)
    {
        (bool success, bytes memory data) = masterchef_.staticcall(abi.encodeWithSelector(sel_, pid_, account_));
        if (success) {
            amount0 = toUint256(data, 0);
            amount1 = toUint256(data, 32);
        }
  }

	function _isErc721(address _token) public view returns (bool) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSelector(SupportsInterfaceSel, bytes4(0x80ac58cd)));
		if (success) {
			return abi.decode(data, (bool));
		}
		return success;
	}

// Helper
    function toAddress(bytes memory _bytes, uint256 _start) public pure returns (address) {
        if (_bytes.length < _start + 20) return address(0);
        address tempAddress;
        assembly {
            tempAddress := mload(add(add(_bytes, 0x20), _start))
        }
        return tempAddress;
    }
    function toUint256(bytes memory _bytes, uint256 _start) public pure returns (uint256) {
        if (_bytes.length < _start + 32) return 0;
        uint256 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }
        return tempUint;
    }
}