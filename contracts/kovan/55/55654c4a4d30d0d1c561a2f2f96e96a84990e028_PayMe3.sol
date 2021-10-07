/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;


interface Vault {
    function _bytesToAddress(bytes memory bys) external pure returns (address addr);
    function _calculateAfterPercentage(
        uint _amount, 
        uint _basisPoint
    ) external pure returns(uint result);
    function _sendEtherToUser(address _user) external;
    function _calculateFeeAllocationPercentage(
        uint _amount, 
        address _user
    ) external returns(uint userAllocation);
    function _sendsFeeToVault(uint _amount, address _payme) external returns(uint, bool);
}

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

interface IGateway {
    function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function burn(bytes calldata _to, uint256 _amount) external returns (uint256);
}

interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol) external view returns (IGateway);
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (MyIERC20);
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


contract PayMe3 {

    using SafeERC20 for MyIERC20;

    IGatewayRegistry registry;
    Vault vault; 
    IRenPool renPool = IRenPool(0x93054188d876f558f4a66B2EF1d97d16eDf0895B); 
    ITricrypto tricrypto2 = ITricrypto(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46); 
    MyIERC20 renBTC = MyIERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D); 
    MyIERC20 WBTC = MyIERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    MyIERC20 USDT = MyIERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    MyIERC20 WETH = MyIERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _registry, address _vault) {
        registry = IGatewayRegistry(_registry);
        vault = Vault(_vault);
    }


    function deposit(
        bytes calldata _user, 
        bytes calldata _userToken,
        uint _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external {
        bytes32 pHash = keccak256(abi.encode(_user, _userToken));
        IGateway BTCGateway = registry.getGatewayBySymbol('BTC');
        BTCGateway.mint(pHash, _amount, _nHash, _sig);

        address user = vault._bytesToAddress(_user);
        address userToken = vault._bytesToAddress(_userToken);
    
        exchangeToUserToken(_amount, user, userToken);
    }

    receive() external payable {}

    function exchangeToUserToken(uint _amount, address _user, address _userToken) public {
        uint userAllocation = vault._calculateFeeAllocationPercentage(_amount, _user);

        // Sends fee to Vault contract
        renBTC.approve(address(vault), type(uint).max);
        (uint netAmount, bool isTransferred) = vault._sendsFeeToVault(_amount, address(this));
        require(isTransferred, 'Fee transfer failed');
        
        uint tokenOut = _userToken == address(USDT) ? 0 : 2;
        bool useEth = _userToken == address(WETH) ? false : true;
        MyIERC20 userToken;
        uint slippage;
        if (_userToken != ETH) {
            userToken = MyIERC20(_userToken);
        }

        //Swaps renBTC for WBTC
        renBTC.approve(address(renPool), netAmount); 
        slippage = vault._calculateAfterPercentage(netAmount, 5);
        renPool.exchange(0, 1, netAmount, slippage);
        uint wbtcToConvert = WBTC.balanceOf(address(this));

        //Swaps WBTC to userToken (USDT, WETH or ETH)
        WBTC.approve(address(tricrypto2), wbtcToConvert);
        uint minOut = tricrypto2.get_dy(1, tokenOut, wbtcToConvert);
        slippage = vault._calculateAfterPercentage(minOut, 5);
        tricrypto2.exchange(1, tokenOut, wbtcToConvert, slippage, useEth);    

        //Sends userToken to user
        if (_userToken != ETH) {
            uint ToUser = userToken.balanceOf(address(this));
            userToken.safeTransfer(_user, ToUser);
        } else {
            vault._sendEtherToUser(_user);
        }
    } 
}