/**
 *Submitted for verification at polygonscan.com on 2021-11-05
*/

/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint value);

    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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


contract ETHPool is Ownable{
    
    using SafeERC20 for IERC20;
    
    mapping(address=>bool) public supportedTokens;
    uint256 supportedTokensCount = 0;
    address[] public tokenAddresses;
    address public walletAddress;
    
    constructor () {
        walletAddress = msg.sender;
    }
    
    event Deposit(address indexed from, address indexed to, address token_address, uint256 value);
    event Withdraw(address indexed from, address indexed to, address token_address, uint256 value);

    function updateWalletAddress(address addr) public onlyOwner {
        walletAddress = addr;
    }

    function checkTokenAddressExists(address token_address) internal view returns (bool) {
        for (uint i = 0 ; i < tokenAddresses.length ; i ++ ) {
            if (tokenAddresses[i] == token_address ) {
                return true;
            }
        }
        return false;
    }
    
    function setToken(address token) public onlyOwner {
        require(checkTokenAddressExists(token) == false, "Token already set");
        supportedTokens[token] = true;
        tokenAddresses.push(token);
        supportedTokensCount = supportedTokensCount + 1;
    }
    
    function enableToken(address token) public onlyOwner {
        require(checkTokenAddressExists(token) == true, "Token not yet exists");
        require(supportedTokens[token] == false, "Token is already enabled");
        supportedTokens[token] = true;
        if ( ! checkTokenAddressExists(token) ) {
            tokenAddresses.push(token);
        }
        supportedTokensCount = supportedTokensCount + 1;
    }

    function disableToken(address token) public onlyOwner {
        (checkTokenAddressExists(token) == true, "Token not yet exists");
        require(supportedTokens[token] == true, "Token is already disabled");
        supportedTokens[token] = false;
        supportedTokensCount = supportedTokensCount - 1;
    }
    
    // get the tokens that we supports
    function getSupportedTokenAddresses() public view returns (address[] memory){
        address[] memory supportedTokenAddresses = new address[](supportedTokensCount);
        uint16 count = 0;
        for ( uint256 i = 0 ; i < tokenAddresses.length ; i ++ ){
            if (supportedTokens[tokenAddresses[i]]) {
                supportedTokenAddresses[count] = tokenAddresses[i];
                count = count + 1;
            }
        }
        return supportedTokenAddresses;
    }

    function deposit(address token, uint256 amount) public {
        require(supportedTokens[token], "TOKEN ADDRESS IS NOT SUPPORTED");
        
        uint256 balance = IERC20(token).balanceOf(address(msg.sender));
        require(balance >= amount, "Pool: INSUFFICIENT_INPUT_AMOUNT");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, address(this), token, amount);
    }

    function depositNative() public payable {
        require(supportedTokens[address(0)], "NATIVE TOKEN IS NOT SUPPORTED");
        emit Deposit(msg.sender, address(this), address(0), msg.value);
    }
    
    function withdrawToken(address token) public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));  
        IERC20(token).transfer(walletAddress, balance);
        emit Withdraw(address(this), walletAddress, token, balance);
    }

    function withdrawNativeToken() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(walletAddress).transfer(balance);
        emit Withdraw(address(this), walletAddress, address(0), balance);
    }
    
    function balanceOfToken(address token) public view onlyOwner returns (uint256 amount) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        return balance;
    }

    function balanceOfNativeToken() public view onlyOwner returns (uint256 amount) {
        uint256 balance = address(this).balance;
        return balance;
    }
}