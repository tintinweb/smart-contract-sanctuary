/**
 *Submitted for verification at snowtrace.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a, "SafeMath: addition overflow");

      return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b <= a, errorMessage);
      uint256 c = a - b;

      return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

      if (a == 0) {
          return 0;
      }

      uint256 c = a * b;
      require(c / a == b, "SafeMath: multiplication overflow");

      return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b > 0, errorMessage);
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold

      return c;
  }

  function sqrrt(uint256 a) internal pure returns (uint c) {
      if (a > 3) {
          c = a;
          uint b = add( div( a, 2), 1 );
          while (b < c) {
              c = b;
              b = div( add( div( a, b ), b), 2 );
          }
      } else if (a != 0) {
          c = 1;
      }
  }
}


library Address {

  function isContract(address account) internal view returns (bool) {
      // This method relies in extcodesize, which returns 0 for contracts in
      // construction, since the code is only stored at the end of the
      // constructor execution.

      uint256 size;
      // solhint-disable-next-line no-inline-assembly
      assembly { size := extcodesize(account) }
      return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
      require(address(this).balance >= amount, "Address: insufficient balance");

      // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
      (bool success, ) = recipient.call{ value: amount }("");
      require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
      return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
      return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
      require(address(this).balance >= value, "Address: insufficient balance for call");
      require(isContract(target), "Address: call to non-contract");

      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory returndata) = target.call{ value: value }(data);
      return _verifyCallResult(success, returndata, errorMessage);
  }

  function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
      require(isContract(target), "Address: call to non-contract");

      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
      if (success) {
          return returndata;
      } else {
          // Look for revert reason and bubble it up if present
          if (returndata.length > 0) {
              // The easiest way to bubble the revert reason is using memory via assembly

              // solhint-disable-next-line no-inline-assembly
              assembly {
                  let returndata_size := mload(returndata)
                  revert(add(32, returndata), returndata_size)
              }
          } else {
              revert(errorMessage);
          }
      }
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
      return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
      require(isContract(target), "Address: static call to non-contract");

      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory returndata) = target.staticcall(data);
      return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
      require(isContract(target), "Address: delegate call to non-contract");
      (bool success, bytes memory returndata) = target.delegatecall(data);
      return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
      if (success) {
          return returndata;
      } else {
          if (returndata.length > 0) {
              assembly {
                  let returndata_size := mload(returndata)
                  revert(add(32, returndata), returndata_size)
              }
          } else {
              revert(errorMessage);
          }
      }
  }

  function addressToString(address _address) internal pure returns(string memory) {
      bytes32 _bytes = bytes32(uint256(_address));
      bytes memory HEX = "0123456789abcdef";
      bytes memory _addr = new bytes(42);

      _addr[0] = '0';
      _addr[1] = 'x';

      for(uint256 i = 0; i < 20; i++) {
          _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
          _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
      }

      return string(_addr);

  }
}

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
      _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
      _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
      bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
      if (returndata.length > 0) { // Return data is optional
          // solhint-disable-next-line max-line-length
          require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
      }
  }
}

contract CrowdsaleMigration {
  using SafeERC20 for IERC20;

  address public oldRgk;
  address public newRgk;

  address public presaleContract;

  constructor(address _oldRgk, address _newRgk, address _presaleContract) {
    oldRgk = _oldRgk;
    newRgk = _newRgk;

    presaleContract = _presaleContract;
  }

  function migrateRGK(uint _value) public {
    IERC20(oldRgk).safeTransferFrom(msg.sender, address(this), _value);
    IERC20(newRgk).safeTransfer(msg.sender, _value);
  }
}