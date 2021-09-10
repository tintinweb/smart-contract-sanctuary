/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.4;


abstract contract OwnableStatic {

    mapping( address => bool ) private _isOwner;

    constructor() {
        _setOwner(msg.sender, true);
    }

    modifier onlyOwner() {
    require( _isOwner[msg.sender] );
    _;
  }

    function _setOwner(address newOwner, bool makeOwner) private {
        _isOwner[newOwner] = makeOwner;
        // _owner = newOwner;
        // emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setOwnerShip( address newOwner, bool makeOOwner ) external onlyOwner() returns ( bool success ) {
    _isOwner[newOwner] = makeOOwner;
    success = true;
  }
}

library AddressUtils {
  function toString (address account) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(account)));
    bytes memory alphabet = '0123456789abcdef';
    bytes memory chars = new bytes(42);

    chars[0] = '0';
    chars[1] = 'x';

    for (uint256 i = 0; i < 20; i++) {
      chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
      chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }

    return string(chars);
  }

  function isContract (address account) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  function sendValue (address payable account, uint amount) internal {
    (bool success, ) = account.call{ value: amount }('');
    require(success, 'AddressUtils: failed to send value');
  }

  function functionCall (address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'AddressUtils: failed low-level call');
  }

  function functionCall (address target, bytes memory data, string memory error) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, error);
  }

  function functionCallWithValue (address target, bytes memory data, uint value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'AddressUtils: failed low-level call with value');
  }

  function functionCallWithValue (address target, bytes memory data, uint value, string memory error) internal returns (bytes memory) {
    require(address(this).balance >= value, 'AddressUtils: insufficient balance for call');
    return _functionCallWithValue(target, data, value, error);
  }

  function _functionCallWithValue (address target, bytes memory data, uint value, string memory error) private returns (bytes memory) {
    require(isContract(target), 'AddressUtils: function call to non-contract');

    (bool success, bytes memory returnData) = target.call{ value: value }(data);

    if (success) {
      return returnData;
    } else if (returnData.length > 0) {
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert(error);
    }
  }
}

interface IERC20 {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function totalSupply () external view returns (uint256);

  function balanceOf (
    address account
  ) external view returns (uint256);

  function transfer (
    address recipient,
    uint256 amount
  ) external returns (bool);

  function allowance (
    address owner,
    address spender
  ) external view returns (uint256);

  function approve (
    address spender,
    uint256 amount
  ) external returns (bool);

  function transferFrom (
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

library SafeERC20 {
    using AddressUtils for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ILPLeverageLaunch {

  function isTokenApprovedForLending( address lentToken ) external view returns ( bool );
  
  function amountLoanedForLoanedTokenForLender( address holder, address lentTToken ) external view returns ( uint256 );

  function totalLoanedForToken( address lentToken ) external view returns ( uint256 );

  function launchTokenDueForHolder( address holder ) external view returns ( uint256 );

  function setPreviousDepositSource( address newPreviousDepositSource ) external returns ( bool success );

  function priceForLentToken( address lentToken ) external view returns ( uint256 );

  function _weth9() external view returns ( address );
  
  function fundManager() external view returns ( address );

  function isActive() external view returns ( bool );

  function changeActive( bool makeActive ) external returns ( bool success );

  function setFundManager( address newFundManager ) external returns ( bool success );

  function setWETH9( address weth9 ) external returns ( bool success );

  function setPrice( address lentToken, uint256 price ) external returns ( bool success );

  function dispenseToFundManager( address token ) external returns ( bool success );

  function changeTokenLendingApproval( address newToken, bool isApproved ) external returns ( bool success );

  function getTotalLoaned(address token ) external view returns (uint256 totalLoaned);

  function lendLiquidity( address loanedToken, uint amount ) external returns ( bool success );

  function getAmountDueToLender( address lender ) external view returns ( uint256 amountDue );

  function lendETHLiquidity() external payable returns ( bool success );

  function dispenseToFundManager() external returns ( bool success );

  function setTotalEthLent( uint256 newValidEthBalance ) external returns ( bool success );

  function getAmountLoaned( address lender, address lentToken ) external view returns ( uint256 amountLoaned );

}

contract LPLeverageLaunch is OwnableStatic, ILPLeverageLaunch {

  using AddressUtils for address;
  using SafeERC20 for IERC20;

  mapping( address => bool ) public override isTokenApprovedForLending;

  mapping( address => mapping( address => uint256 ) ) private _amountLoanedForLoanedTokenForLender;
  
  mapping( address => uint256 ) private _totalLoanedForToken;

  mapping( address => uint256 ) private _launchTokenDueForHolder;

  mapping( address => uint256 ) public override priceForLentToken;

  address public override _weth9;

  address public override fundManager;

  bool public override isActive;

  address public previousDepoistSource;

  modifier onlyActive() {
    require( isActive == true, "Launch: Lending is not active." );
    _;
  }

  constructor() {}


  function amountLoanedForLoanedTokenForLender( address holder, address lentToken ) external override view returns ( uint256 ) {
    return _amountLoanedForLoanedTokenForLender[holder][lentToken] + ILPLeverageLaunch(previousDepoistSource).amountLoanedForLoanedTokenForLender( holder, lentToken );
  }

  function totalLoanedForToken( address lentToken ) external override view returns ( uint256 ) {
    return _totalLoanedForToken[lentToken] + ILPLeverageLaunch(previousDepoistSource).totalLoanedForToken(lentToken);
  }

  function launchTokenDueForHolder( address holder ) external override view returns ( uint256 ) {
    return _launchTokenDueForHolder[holder] + ILPLeverageLaunch(previousDepoistSource).launchTokenDueForHolder(holder);
  }

  function setPreviousDepositSource( address newPreviousDepositSource ) external override onlyOwner() returns ( bool success ) {
    previousDepoistSource = newPreviousDepositSource;
    success = true;
  }

  function changeActive( bool makeActive ) external override onlyOwner() returns ( bool success ) {
    isActive = makeActive;
    success = true;
  }

  function setFundManager( address newFundManager ) external override onlyOwner() returns ( bool success ) {
    fundManager = newFundManager;
    success = true;
  }

  function setWETH9( address weth9 ) external override onlyOwner() returns ( bool success ) {
    _weth9 = weth9;
    success = true;
  }

  function setPrice( address lentToken, uint256 price ) external override onlyOwner() returns ( bool success ) {
    priceForLentToken[lentToken] = price;
    success = true;
  }

  function dispenseToFundManager( address token ) external override onlyOwner() returns ( bool success ) {
    _dispenseToFundManager( token );
    success = true;
  }

  function _dispenseToFundManager( address token ) internal {
    require( fundManager != address(0) );
    IERC20(token).safeTransfer( fundManager, IERC20(token).balanceOf( address(this) ) );
  }

  function changeTokenLendingApproval( address newToken, bool isApproved ) external override onlyOwner() returns ( bool success ) {
    isTokenApprovedForLending[newToken] = isApproved;
    success = true;
  }

  function getTotalLoaned(address token ) external override view returns (uint256 totalLoaned) {
    totalLoaned = _totalLoanedForToken[token];
  }

  /**
   * @param loanedToken The address fo the token being paid. Ethereum is indicated with _weth9.
   */
  function lendLiquidity( address loanedToken, uint amount ) external override onlyActive() returns ( bool success ) {
    require( fundManager != address(0) );
    require( isTokenApprovedForLending[loanedToken] );

    IERC20(loanedToken).safeTransferFrom( msg.sender, fundManager, amount );
    _amountLoanedForLoanedTokenForLender[msg.sender][loanedToken] += amount;
    _totalLoanedForToken[loanedToken] += amount;

    _launchTokenDueForHolder[msg.sender] += (amount / priceForLentToken[loanedToken]);

    success = true;
  }

  function getAmountDueToLender( address lender ) external override view returns ( uint256 amountDue ) {
    amountDue = _launchTokenDueForHolder[lender];
  }

  function lendETHLiquidity() external override payable onlyActive() returns ( bool success ) {
    _lendETHLiquidity();

    success = true;
  }

  function _lendETHLiquidity() internal {
    require( fundManager != address(0), "Launch: fundManager is address(0)." );
    _amountLoanedForLoanedTokenForLender[msg.sender][address(_weth9)] += msg.value;
    _totalLoanedForToken[address(_weth9)] += msg.value;

    payable(fundManager).transfer( msg.value );

    _launchTokenDueForHolder[msg.sender] += msg.value;
  }

  function dispenseToFundManager() external override onlyOwner() returns ( bool success ) {
    payable(fundManager).transfer( _totalLoanedForToken[address(_weth9)] );
    delete _totalLoanedForToken[address(_weth9)];
    success = true;
  }

  function setTotalEthLent( uint256 newValidEthBalance ) external override onlyOwner() returns ( bool success ) {
    _totalLoanedForToken[address(_weth9)] = newValidEthBalance;
    success = true;
  }

  function getAmountLoaned( address lender, address lentToken ) external override view returns ( uint256 amountLoaned ) {
    amountLoaned = _amountLoanedForLoanedTokenForLender[lender][lentToken];
  }

}