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

contract LPLeverageLaunch is OwnableStatic {

  using AddressUtils for address;
  using SafeERC20 for IERC20;

  mapping( address => bool ) public isTokenApprovedForLending;

  mapping( address => mapping( address => uint256 ) ) public amountLoanedForLoanedTokenForLender;
  
  mapping( address => uint256 ) public totalLoanedForToken;

  mapping( address => address ) public lentTokenForUniV2PriceSource;

  mapping( address => uint256 ) public launchTokenDueForHolder;

  mapping( address => uint256 ) public priceForLentToken;

  address public _weth9;

  address public fundManager;

  bool public isActive;

  modifier onlyActive() {
    require( isActive == true, "Launch: Lending is not active." );
    _;
  }

  constructor() {}

  function changeActive( bool makeActive ) external onlyOwner() returns ( bool success ) {
    isActive = makeActive;
    success = true;
  }

  function setFundManager( address newFundManager ) external onlyOwner() returns ( bool success ) {
    fundManager = newFundManager;
    success = true;
  }

  function setWETH9( address weth9 ) external onlyOwner() returns ( bool success ) {
    _weth9 = weth9;
    success = true;
  }

  function setPrice( address lentToken, uint256 price ) external onlyOwner() returns ( bool success ) {
    priceForLentToken[lentToken] = price;
    success = true;
  }

  function dispenseToFundManager( address token ) external onlyOwner() returns ( bool success ) {
    _dispenseToFundManager( token );
    success = true;
  }

  function _dispenseToFundManager( address token ) internal {
    require( fundManager != address(0) );
    IERC20(token).safeTransfer( fundManager, IERC20(token).balanceOf( address(this) ) );
  }

  function changeTokenLendingApproval( address newToken, bool isApproved ) external onlyOwner() returns ( bool success ) {
    isTokenApprovedForLending[newToken] = isApproved;
    success = true;
  }

  function getTotalLoaned(address token ) external view returns (uint256 totalLoaned) {
    totalLoaned = totalLoanedForToken[token];
  }

  /**
   * @param loanedToken The address fo the token being paid. Ethereum is indicated with _weth9.
   */
  function lendLiquidity( address loanedToken, uint amount ) external onlyActive() returns ( bool success ) {
    require( fundManager != address(0) );
    require( isTokenApprovedForLending[loanedToken] );

    IERC20(loanedToken).safeTransferFrom( msg.sender, fundManager, amount );
    amountLoanedForLoanedTokenForLender[msg.sender][loanedToken] += amount;
    totalLoanedForToken[loanedToken] += amount;

    launchTokenDueForHolder[msg.sender] += (amount / priceForLentToken[loanedToken]);

    success = true;
  }

  function getAmountDueToLender( address lender ) external view returns ( uint256 amountDue ) {
    amountDue = launchTokenDueForHolder[lender];
  }

  function lendETHLiquidity() external payable onlyActive() returns ( bool success ) {
    _lendETHLiquidity();

    success = true;
  }

  function _lendETHLiquidity() internal {
    require( fundManager != address(0), "Launch: fundManager is address(0)." );
    amountLoanedForLoanedTokenForLender[msg.sender][address(_weth9)] = amountLoanedForLoanedTokenForLender[msg.sender][address(_weth9)] + msg.value;
    totalLoanedForToken[address(_weth9)] += msg.value;

    payable(fundManager).transfer( msg.value );

    launchTokenDueForHolder[msg.sender] += msg.value;
  }

  function dispenseToFundManager() external onlyOwner() returns ( bool success ) {
    payable(fundManager).transfer( totalLoanedForToken[address(_weth9)] );
    delete totalLoanedForToken[address(_weth9)];
    success = true;
  }

  function setTotalEthLent( uint256 newValidEthBalance ) external onlyOwner() returns ( bool success ) {
    totalLoanedForToken[address(_weth9)] = newValidEthBalance;
    success = true;
  }

  function getAmountLoaned( address lender, address lentToken ) external view returns ( uint256 amountLoaned ) {
    amountLoaned = amountLoanedForLoanedTokenForLender[lender][lentToken];
  }

}