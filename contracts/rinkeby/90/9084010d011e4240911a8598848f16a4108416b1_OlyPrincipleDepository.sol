/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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


interface IBondingCalculator {
    function principleValuation( address principleTokenAddress_, uint amountDeposited_ ) external returns ( uint principleValuation_ );
    function calculateBondInterest( address treasury_, address reserveToken_, address principleTokenAddress_, uint amountDeposited_, uint bondConstantValue_ ) external returns ( uint interestDue_ );
}

interface IPrincipleDepository {

  function getDepositorInfo( address depositorAddress_, address principleToken_, address debtToken_ ) external returns ( uint principleAmount_, uint interestDue_, uint bondMaturationBlock_, uint bondScalingFactor );
}

interface ITreasury {
  function isReserveToken(address reserveToken_) external view returns (bool);
  function isPrincipleToken(address principleToken_) external view returns (bool);
  function getBondingCalculatorForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (address);
  function addReserveToken( address newReserveToken_ ) external returns ( bool );
  function addPrincipleToken( address newLPToken_ ) external returns ( bool );
  function payDebt( address depositor_, address principleTokenBeingCollected_, address reserveToken_ ) external returns ( bool );
  function incurDebt( address reserveToken_, address principleToken_, uint principieTokenAmountDeposited_ ) external returns ( bool );
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

}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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
}

interface IOwnable {

  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

interface IERC2612Permit {

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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
        // solhint-disable-next-line max-line-length
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract OlyPrincipleDepository is IPrincipleDepository, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  struct BondTerm {
    uint256 bondScalingFactor;
    uint256 bondingPeriodInBlocks;
  }

  struct DepositInfo {
    uint256 principleAmount;
    uint256 interestDue;
    uint256 bondMaturationBlock;
    uint256 bondScalingFactor;
  }

  ITreasury public treasury;

  mapping( address => bool ) public isReserveToken;
  mapping( address => bool ) public isPrincipleToken;
  mapping( address => bool ) public isERC1612;
  mapping( address => mapping( address => address ) ) public getBondingCalculatorForPrincipleTokenForReserveToken;

  mapping( address => mapping( address => BondTerm ) ) public getBondTermForPrincipleTokenForReserveToken;

  mapping( address => mapping( address => mapping( address => DepositInfo ) ) ) public getDepositorInfoForReserveTokenForPrincipleTokenForDepositor;

  modifier onlyReserveToken( address reserveTokenChallenge_ ) {
    require( isReserveToken[reserveTokenChallenge_], "OlyPrincipleDepository:: Not a registered principle token" );
    _;
  }

  modifier onlyPrincipleToken( address principleTokenChallenge_ ) {
    require( isPrincipleToken[principleTokenChallenge_], "OlyPrincipleDepository:: Not a registered principle token" );
    _;
  }

  function setTreasury( address newTrasury_ ) external onlyOwner() returns ( bool ) {
    require( address(treasury) == address(0), "OlyPrincipleDepository:: Treasury already set." );
    treasury = ITreasury(newTrasury_);
    return true;
  }

  function addReserveToken( address newReserveToken_, bool isERC1612_ ) external onlyOwner() returns ( bool ) {
    require( treasury.isReserveToken( newReserveToken_ ), "OlyPrincipleDepository:: Not a registered reserve token" );
    isReserveToken[newReserveToken_] = true;
    _setERC2612ForToken( newReserveToken_, isERC1612_ );
    return true;
  }

  function addPrincipleToken( address newPrincipleToken_, bool isERC1612_ ) external onlyOwner() returns ( bool ) {
    require( treasury.isPrincipleToken( newPrincipleToken_ ), "OlyPrincipleDepository:: Not a registered principle token" );
    isPrincipleToken[newPrincipleToken_] = true;
    _setERC2612ForToken( newPrincipleToken_, isERC1612_ );
    return true;
  }

  function removePrincipleToken( address oldPrincipleToken_ ) external onlyOwner() returns ( bool ) {
    delete isPrincipleToken[oldPrincipleToken_];
    delete isERC1612[oldPrincipleToken_];
    return true;
  }

  function _setERC2612ForToken( address newReserveToken_, bool isERC1612_ ) internal {
    isERC1612[newReserveToken_] = isERC1612_;
  }

  function removeBondingCalculatorForPrincipleToken(
    address reserveToken_,
    address principleToken_
  )
    external
    onlyOwner()
    onlyReserveToken( reserveToken_ )
    onlyPrincipleToken( principleToken_ )
    returns ( bool )
  {
    delete getBondingCalculatorForPrincipleTokenForReserveToken[reserveToken_][principleToken_];
    return true;
  }

  function addBondTerm(
    address reserveToken_,
    address bondPrincipleToken_,
    uint256 bondSaclingFactor_,
    uint256 bondingPeriodInBlocks_
  )
    external
    onlyOwner()
    onlyReserveToken( reserveToken_ )
    onlyPrincipleToken( bondPrincipleToken_ )
    returns ( bool )
  {
    getBondingCalculatorForPrincipleTokenForReserveToken[reserveToken_][bondPrincipleToken_] = treasury.getBondingCalculatorForPrincipleTokenForReserveToken( reserveToken_, bondPrincipleToken_ );
    getBondTermForPrincipleTokenForReserveToken[reserveToken_][bondPrincipleToken_] = BondTerm(
      {
        bondScalingFactor: bondSaclingFactor_,
        bondingPeriodInBlocks: bondingPeriodInBlocks_
      }
    );
    return true;
  }

  function removeBondTerm( address reserveToken_, address bondPrincipleToRemove_) external onlyOwner() {
    isPrincipleToken[bondPrincipleToRemove_] = false;
    delete getBondTermForPrincipleTokenForReserveToken[reserveToken_][bondPrincipleToRemove_];
    delete getBondingCalculatorForPrincipleTokenForReserveToken[reserveToken_][bondPrincipleToRemove_];
  }

  function _depositBondPrinciple(
    address bondPrincipleTokenToDeposit_,
    uint256 amountToDeposit_,
    address reserveToken_
  ) 
    internal
  {
    //console.log("Before Transfer %s", IERC20(bondPrincipleTokenToDeposit_).balanceOf(address(this)));
    IERC20(bondPrincipleTokenToDeposit_).safeTransferFrom(
      msg.sender,
      address(this),
      amountToDeposit_
    );

    //console.log("After Transfer: %s", IERC20(bondPrincipleTokenToDeposit_).balanceOf(address(this)));

    BondTerm memory currentBondTerm_ = getBondTermForPrincipleTokenForReserveToken[reserveToken_][bondPrincipleTokenToDeposit_];
    //console.log(getBondingCalculatorForPrincipleTokenForReserveToken[reserveToken_][bondPrincipleTokenToDeposit_]);

    getDepositorInfoForReserveTokenForPrincipleTokenForDepositor[msg.sender][bondPrincipleTokenToDeposit_][reserveToken_] = DepositInfo(
      {
        principleAmount: getDepositorInfoForReserveTokenForPrincipleTokenForDepositor[msg.sender][bondPrincipleTokenToDeposit_][reserveToken_]
                .principleAmount
                  .add(amountToDeposit_),
        interestDue: IBondingCalculator( getBondingCalculatorForPrincipleTokenForReserveToken[reserveToken_][bondPrincipleTokenToDeposit_] )
          .calculateBondInterest(
            address( treasury ),
            reserveToken_,
            bondPrincipleTokenToDeposit_,
            amountToDeposit_,
            currentBondTerm_.bondScalingFactor
          ),
        bondMaturationBlock: block.number.add( currentBondTerm_.bondingPeriodInBlocks ),
        bondScalingFactor: currentBondTerm_.bondScalingFactor
      }
    );

    treasury.incurDebt( reserveToken_, bondPrincipleTokenToDeposit_, amountToDeposit_);
  }

  function depositBondPrinciple(
    address bondPrincipleTokenToDeposit_,
    uint256 amountToDeposit_,
    address reserveToken_
  ) 
    external
    onlyReserveToken( reserveToken_ )
    onlyPrincipleToken( bondPrincipleTokenToDeposit_ )
    returns ( bool )
  {
    _depositBondPrinciple( bondPrincipleTokenToDeposit_, amountToDeposit_, reserveToken_ ) ;
    return true;
  }

  function depositBondPrincipleWithPermit(
    address bondPrincipleTokenToDeposit_,
    uint256 amountToDeposit_,
    address reserveToken_,
    uint256 deadline, uint8 v, bytes32 r, bytes32 s 
  ) 
    external
    onlyReserveToken( reserveToken_ )
    onlyPrincipleToken( bondPrincipleTokenToDeposit_ )
    returns ( bool )
  {
    IERC2612Permit( bondPrincipleTokenToDeposit_ ).permit( msg.sender, address(this), amountToDeposit_, deadline, v, r, s );
    _depositBondPrinciple( bondPrincipleTokenToDeposit_, amountToDeposit_, reserveToken_ ) ;
    return true;
  }

  function getDepositorInfo( address depositorAddress_, address principleToken_, address reserveToken_ ) external view override returns ( uint principleAmount_, uint interestDue_, uint bondMaturationBlock_, uint bondScalingFactor ) {
    DepositInfo memory depositorInfoToReturn = getDepositorInfoForReserveTokenForPrincipleTokenForDepositor[depositorAddress_][principleToken_][reserveToken_];

    principleAmount_ = depositorInfoToReturn.principleAmount;
    interestDue_ = depositorInfoToReturn.interestDue;
    bondMaturationBlock_ = depositorInfoToReturn.bondMaturationBlock;
    bondScalingFactor = depositorInfoToReturn.bondScalingFactor;
    //console.log(block.number);
  }

  function withdrawPrincipleAndForfeitInterest( address bondPrincipleToWithdraw_, address reserveToken_ ) external returns ( bool ) {
    uint256 principleAmountToWithdraw_ =
    getDepositorInfoForReserveTokenForPrincipleTokenForDepositor[msg.sender][bondPrincipleToWithdraw_][reserveToken_].principleAmount;
    require( principleAmountToWithdraw_ > 0, "user has no principle amount to withdraw" );

    delete getDepositorInfoForReserveTokenForPrincipleTokenForDepositor[msg.sender][bondPrincipleToWithdraw_][reserveToken_];

    IERC20(bondPrincipleToWithdraw_).safeTransfer( msg.sender, principleAmountToWithdraw_ );
    return true;
  }

  function redeemBond(address bondPrincipleToRedeem_, address reserveToken_ ) external onlyReserveToken( reserveToken_ ) onlyPrincipleToken( bondPrincipleToRedeem_ ) returns ( bool ) {
    DepositInfo storage depositInfoToRedeem_ = getDepositorInfoForReserveTokenForPrincipleTokenForDepositor[msg.sender][bondPrincipleToRedeem_][reserveToken_];

    uint256 pendingInterestDue_ = depositInfoToRedeem_.interestDue;
    uint256 pendingBondkMaturationBlock_ = depositInfoToRedeem_.bondMaturationBlock;
    uint256 pendingPrincipleAmount_ = depositInfoToRedeem_.principleAmount;

    require( pendingInterestDue_ > 0, "OlyUniV2CompatiableLPTokenBonding: Message Sender is not due any interest." );
    require( pendingBondkMaturationBlock_ < block.number, "OlyUniV2CompatiableLPTokenBonding: Bond has not matured." );

    IUniswapV2ERC20(bondPrincipleToRedeem_).approve( address( treasury ), pendingPrincipleAmount_ );

    treasury.payDebt( msg.sender, bondPrincipleToRedeem_, reserveToken_ );

    delete getDepositorInfoForReserveTokenForPrincipleTokenForDepositor[msg.sender][bondPrincipleToRedeem_][reserveToken_];
    return true;
    
  }

}