/**
 *Submitted for verification at snowtrace.io on 2021-11-19
*/

// SPDX-License-Identifier: Blah

pragma solidity ^0.7.2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

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

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
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

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;


        _status = _NOT_ENTERED;
    }
}

contract Escapable is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  function escapeHatch(address _token, address payable _escapeHatchDestination) external onlyOwner nonReentrant {
    require(_escapeHatchDestination != address(0x0));

    uint256 balance;

    /// Logic for Avax
    if (_token == address(0x0)) {
      balance = address(this).balance;
      _escapeHatchDestination.transfer(balance);
      EscapeHatchCalled(_token, balance);
      return;
    }
    // Logic for tokens
    IERC20 token = IERC20(_token);
    balance = token.balanceOf(address(this));
    token.safeTransfer(_escapeHatchDestination, balance);
    emit EscapeHatchCalled(_token, balance);
  }

  event EscapeHatchCalled(address token, uint256 amount);
}

contract MultiTransfer is Pausable {
  using SafeMath for uint256;

  function multiTransfer_OST(address payable[] calldata _addresses, uint256[] calldata _amounts)
  payable external whenNotPaused returns(bool)
  {
    uint256 _value = msg.value;
    for (uint8 i; i < _addresses.length; i++) {
      _value = _value.sub(_amounts[i]);

      _addresses[i].call{ value: _amounts[i] }("");
    }
    return true;
  }

  function transfer2(address payable _address1, uint256 _amount1, address payable _address2, uint256 _amount2)
  payable external whenNotPaused returns(bool)
  {
    uint256 _value = msg.value;
    _value = _value.sub(_amount1);
    _value = _value.sub(_amount2);

    _address1.call{ value: _amount1 }("");

    _address2.call{ value: _amount2 }("");

    return true;
  }
}

contract MultiTransferEqual is Pausable {

  function multiTransferEqual_L1R(address payable[] calldata _addresses, uint256 _amount)
  payable external whenNotPaused returns(bool)
  {
    require(_amount <= msg.value / _addresses.length);
    for (uint8 i; i < _addresses.length; i++) {
      _addresses[i].call{ value: _amount }("");
    }
    return true;
  }
}

contract MultiTransferToken is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function multiTransferToken_a4A(
    address _token,
    address[] calldata _addresses,
    uint256[] calldata _amounts,
    uint256 _amountSum
  ) payable external whenNotPaused
  {
    IERC20 token = IERC20(_token);
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      _amountSum = _amountSum.sub(_amounts[i]);
      token.transfer(_addresses[i], _amounts[i]);
    }
  }
}

contract MultiTransferTokenEqual is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function multiTransferTokenEqual_71p(
    address _token,
    address[] calldata _addresses,
    uint256 _amount
  ) payable external whenNotPaused
  {
    uint256 _amountSum = _amount.mul(_addresses.length);
    IERC20 token = IERC20(_token);
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      token.transfer(_addresses[i], _amount);
    }
  }
}

contract MultiTransferTokenAvax is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function multiTransferTokenAvax(
    address _token,
    address payable[] calldata _addresses,
    uint256[] calldata _amounts,
    uint256 _amountSum,
    uint256[] calldata _amountsAvax
  ) payable external whenNotPaused
  {
    uint256 _value = msg.value;
    IERC20 token = IERC20(_token);
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      _amountSum = _amountSum.sub(_amounts[i]);
      _value = _value.sub(_amountsAvax[i]);
      token.transfer(_addresses[i], _amounts[i]);
      _addresses[i].call{ value: _amountsAvax[i] }("");
    }
  }
}

contract MultiTransferTokenAvaxEqual is Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function multiTransferTokenAvaxEqual(
    address _token,
    address payable[] calldata _addresses,
    uint256 _amount,
    uint256 _amountAvax
  ) payable external whenNotPaused
  {
    require(_amountAvax <= msg.value / _addresses.length);

    uint256 _amountSum = _amount.mul(_addresses.length);
    IERC20 token = IERC20(_token);
    token.safeTransferFrom(msg.sender, address(this), _amountSum);
    for (uint8 i; i < _addresses.length; i++) {
      token.transfer(_addresses[i], _amount);

      _addresses[i].call{ value: _amountAvax }("");
    }
  }
}

contract FundzMultiSend is Pausable, Escapable,
  MultiTransfer,
  MultiTransferEqual,
  MultiTransferToken,
  MultiTransferTokenEqual,
  MultiTransferTokenAvax,
  MultiTransferTokenAvaxEqual
{
  function emergencyStop() external onlyOwner {
      _pause();
  }

  receive() external payable {
    revert("Cannot accept AVAX directly.");
  }

  fallback() external payable { require(msg.data.length == 0); }
}