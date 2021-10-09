/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface MyIERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IRenPool {
    function exchange(
      int128 i,
      int128 j,
      uint256 dx,
      uint256 min_dy
    ) external;
}


interface ITricrypto {
  function exchange(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy,
    bool use_eth
  ) external;

  function get_dy(uint i, uint j, uint dx) external returns(uint256);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        MyIERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        MyIERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {MyIERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        MyIERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        MyIERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        MyIERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(MyIERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface FeesVault2 {
    function getRenBalance() external view returns(uint balance);
}


contract Manager { 
    using SafeERC20 for MyIERC20;

    IRenPool renPool = IRenPool(0x93054188d876f558f4a66B2EF1d97d16eDf0895B); 
    ITricrypto tricrypto2 = ITricrypto(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);
    MyIERC20 renBTC = MyIERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    MyIERC20 USDT = MyIERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    MyIERC20 WETH = MyIERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    MyIERC20 WBTC = MyIERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint dappFee = 10;
    uint totalVolume = 0;
    FeesVault2 feesVault;

    mapping(address => bool) users;
    mapping(address => uint) pendingWithdrawal;
    mapping(address => uint) usersPayments;

    constructor(address _feesVault) {
        feesVault = FeesVault2(_feesVault);
    }

    function _calculateAfterPercentage(
        uint _amount, 
        uint _basisPoint
    ) public pure returns(uint result) {
        result = _amount - ( (_amount * _basisPoint) / 10000 ); //5 -> 0.05%;
    }

    function _calculateAllocationPercentage(
        uint _amount, 
        address _user
    ) public returns(uint userAllocation) {
        usersPayments[_user] += _amount;
        totalVolume += _amount;
        userAllocation = ( (usersPayments[_user] * 10000) / totalVolume ) * 1 ether;
    }

    function _bytesToAddress(bytes memory bys) public pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        } 
    }

    function _preSending(address _user) private {
        pendingWithdrawal[_user] = address(this).balance;
    }

    function _sendEtherToUser(address _user) public {
        _preSending(_user);
        uint amount = pendingWithdrawal[_user];
        pendingWithdrawal[_user] = 0;
        payable(_user).transfer(amount);
    }

    function _getFee(uint _amount) public returns(uint, bool) {
        uint fee = _amount - _calculateAfterPercentage(_amount, dappFee); //10 -> 0.1%
        uint netAmount = _amount - fee;
        bool isTransferred = renBTC.transfer(address(feesVault), fee);
        return (netAmount, isTransferred);
    }

    function swapsRenForWBTC(uint _netAmount) public returns(uint wbtcToConvert) {
        renBTC.approve(address(renPool), _netAmount); 
        uint slippage = _calculateAfterPercentage(_netAmount, 5);
        renPool.exchange(0, 1, _netAmount, slippage);
        wbtcToConvert = WBTC.balanceOf(address(this));
    }

    function swapsWBTCForUserToken(uint _wbtcToConvert, uint _tokenOut, bool _useEth) public {
        WBTC.approve(address(tricrypto2), _wbtcToConvert);
        uint minOut = tricrypto2.get_dy(1, _tokenOut, _wbtcToConvert);
        uint slippage = _calculateAfterPercentage(minOut, 5);
        tricrypto2.exchange(1, _tokenOut, _wbtcToConvert, slippage, _useEth);
    }

    function exchangeToUserToken(uint _amount, address _user, address _userToken) public {
        uint userAllocation = _calculateAllocationPercentage(_amount, _user);
        (uint netAmount, bool isTransferred) = _getFee(_amount);
        require(isTransferred, 'Fee transfer failed');
        
        uint tokenOut = _userToken == address(USDT) ? 0 : 2;
        bool useEth = _userToken == address(WETH) ? false : true;
        MyIERC20 userToken;
        if (_userToken != ETH) {
            userToken = MyIERC20(_userToken);
        }

        //Swaps renBTC for WBTC
        uint wbtcToConvert = swapsRenForWBTC(netAmount);

        //Swaps WBTC to userToken (USDT, WETH or ETH)  
        swapsWBTCForUserToken(wbtcToConvert, tokenOut, useEth); 

        //Sends userToken to user
        if (_userToken != ETH) {
            uint ToUser = userToken.balanceOf(address(this));
            userToken.safeTransfer(_user, ToUser);
        } else {
            _sendEtherToUser(_user);
        }
    }
}