/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IBondingCalculator {
  function calcDebtRatio( uint pendingDebtDue_, uint managedTokenTotalSupply_ ) external returns ( uint debtRatio_ );
  function principleValuation( address principleTokenAddress_, uint amountDeposited_ ) external returns ( uint principleValuation_ );
}

interface IERC20Burnable {

  function burn(uint256 amount) external;

  function burnFrom( address account_, uint256 ammount_ ) external;
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

interface ITreasury {
    function isReserveToken(address reserveToken_) external view returns (bool);

    function isPrincipleToken(address principleToken_) external view returns (bool);

    function isTellerContract(address tellerContract_) external view returns (bool);

    function isPaymentContract(address paymentContract_) external view returns (bool);

    function getManagedTokenForReserveToken(address reserveToken_) external view returns (address);

    function getPaymentAddressForReserveToken(address reserveToken_) external view returns (address);

    function getBondingDepositoryForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (address);
    
    function getDebtAmountDueForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (uint);

    function getPrincipleTokenBalanceForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (uint);

    function getBondingCalculatorForPrincipleTokenForReserveToken(address reserveToken_, address principleToken_) external view returns (address);

    function getIntrinsicValueOfReserveToken(address reserveToken_) external view returns (uint);

    function setManagedTokenForReserveToken( address newManagedToken_, address reserveToken_ ) external returns ( bool );

    function addReserveToken( address newReserveToken_ ) external returns ( bool );

    function addPrincipleToken( address newLPToken_ ) external returns ( bool );

    function addTellerContract( address newTellerContract_ ) external returns ( bool );

    function addBondingDepositoryForPrincipleTokenForReserveToken( address newBondingDepository_, address PrincipleToken_, address reserveToken_ ) external returns ( bool );

    function setBondingCalculatorForPrincipleTokenForReserveToken( address resesrveToken_, address principleToken_, address newPrincipleTokenValueCalculator_ ) external returns ( bool );

    function addPaymentContract( address newPaymentContract_ ) external returns ( bool );

    function payDebt( address depositor_, address principleTokenBeingCollected_, address reserveToken_ ) external returns ( bool );

    function incurDebt( address reserveToken_, address principleToken_, uint principieTokenAmountDeposited_ ) external returns ( bool );

  function epochPeriod() external view returns (uint256);
  function epochTWAPTimestamp() external view returns (uint32);
  function previousEpochTWAPTimestamp() external view returns (uint32);

  function getTWAPOracleForReserveToken( address ) external returns ( address );
  
  function lastEpochIntrinsicValue() external returns ( uint );
  function lastEpochManagedTokenTotalSupply() external returns ( uint );

  function setTWAPOracleForPrincipleToken( address newTWAPOracleForReserveToken_, address reserveToken_ ) external returns ( bool );

  function updateProfits( address paymetAddress, address reserveToken_, address managedToken_ ) external returns ( bool );

}

interface IStaking {

    function initialize(
        address olyTokenAddress_,
        address sOLY_,
        address dai_,
        address olympusTreasuryAddress_
    ) external;

    function stakeOLY(
        uint256 amountToStake_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    function unstakeOLY(
        uint256 amountToWithdraw_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    function distributeOLYProfits() external;
}

interface ITWAPOracle {

  function uniV2CompPairAddressForLastEpochUpdateBlockTimstamp( address ) external returns ( uint32 );

  function priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp( address tokenToPrice_, address tokenForPriceComparison_, uint epochPeriod_ ) external returns ( uint32 );

  function pricedTokenForPricingTokenForEpochPeriodForPrice( address, address, uint ) external returns ( uint );

  function pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice( address, address, uint ) external returns ( uint );

  function updateTWAP( address uniV2CompatPairAddressToUpdate_, uint eopchPeriodToUpdate_ ) external returns ( bool );
}

interface IPrincipleDepository {

  function getDepositorInfo( address depositorAddress_, address principleToken_, address debtToken_ ) external returns ( uint principleAmount_, uint interestDue_, uint bondMaturationBlock_, uint bondScalingFactor );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20Mintable {

  function mint( uint256 amount_ ) external;

  function mint( address account_, uint256 ammount_ ) external;
}

contract Vault is ITreasury, Ownable {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  event EpochPeriodChanged( uint previousEpochPeriod, uint newEpochPeriod );
  event ReserveTokenAdded( address indexed newReserveCurrency );
  event ManagedTokenAdded( address indexed newManafedToken, address newRserveToken );
  event PrincipleTokenAdded( address indexed newPrincipleToken );

  mapping( address => bool ) public override isReserveToken;

  mapping( address => bool ) public override isPrincipleToken;

  mapping( address => bool ) public override isTellerContract;

  mapping( address => bool ) public override isPaymentContract;

  mapping( address => address ) public override getManagedTokenForReserveToken;

  mapping( address => address ) public override getPaymentAddressForReserveToken;

  mapping( address => mapping( address => address ) ) public override getBondingDepositoryForPrincipleTokenForReserveToken;

  mapping( address => mapping( address => uint ) ) public override getDebtAmountDueForPrincipleTokenForReserveToken;

  mapping( address => mapping( address => uint ) ) public override getPrincipleTokenBalanceForPrincipleTokenForReserveToken;

  mapping( address => mapping( address => address ) ) public override getBondingCalculatorForPrincipleTokenForReserveToken;

  mapping( address => uint ) public override getIntrinsicValueOfReserveToken;

  modifier onlyReserveToken( address reserveTokenChallenge_ ) {
    require( isReserveToken[reserveTokenChallenge_] == true, "Vault: reserveTokenChallenge_ is not a reserve Token." );
    _;
  }

  modifier onlyPrincipleToken( address PrincipleTokenChallenge_ ) {
    require( isPrincipleToken[PrincipleTokenChallenge_] == true, "Vault: PrincipleTokenChallenge_ is not a Principle token." );
    _;
  }

  modifier onlyTeller() {
    require( isTellerContract[msg.sender] == true, "Vault: msg.sender is not a teller." );
    _;
  }

  modifier onlyPayment() {
    require( isPaymentContract[msg.sender] == true, "Vault:: msg.sender is not a registered payment contract." );
    _;
  }

  function setEpochPeriod( uint newEpochPeriod_ ) external onlyOwner() returns ( bool ) {
    emit EpochPeriodChanged( epochPeriod, newEpochPeriod_ );
    epochPeriod = newEpochPeriod_;
    return true;
  }

  function setManagedTokenForReserveToken( address newManagedToken_, address reserveToken_ ) external override onlyOwner() returns ( bool ) {
    emit ManagedTokenAdded( newManagedToken_, reserveToken_ );
    getManagedTokenForReserveToken[reserveToken_] = newManagedToken_;
    return true;
  }

  function addReserveToken( address newReserveToken_ ) external override onlyOwner() returns ( bool ) {
    emit ReserveTokenAdded( newReserveToken_);
    isReserveToken[newReserveToken_] = true;
    return true;
  }

  function addPrincipleToken( address newLPToken_ ) external override onlyOwner() returns ( bool ) {
    isPrincipleToken[newLPToken_] = true;
    emit PrincipleTokenAdded( newLPToken_ );
    return true;
  }

  function addTellerContract( address newTellerContract_ ) external override onlyOwner() returns ( bool ) {
    isTellerContract[newTellerContract_] = true;
    return true;
  }

  function addBondingDepositoryForPrincipleTokenForReserveToken( address newBondingDepository_, address PrincipleToken_, address reserveToken_ ) external override onlyOwner() onlyReserveToken( reserveToken_ ) onlyPrincipleToken( PrincipleToken_ ) returns ( bool ) {
    require( getBondingDepositoryForPrincipleTokenForReserveToken[reserveToken_][PrincipleToken_] == address(0) );
    getBondingDepositoryForPrincipleTokenForReserveToken[reserveToken_][PrincipleToken_] = newBondingDepository_;
    return true;
  }

  function setBondingCalculatorForPrincipleTokenForReserveToken( address resesrveToken_, address principleToken_, address newPrincipleTokenValueCalculator_ ) external override onlyOwner() returns ( bool ) {
    getBondingCalculatorForPrincipleTokenForReserveToken[resesrveToken_][principleToken_] = newPrincipleTokenValueCalculator_;
    return true;
  }

  function addPaymentContract( address newPaymentContract_) external override onlyOwner() returns ( bool ) {
    isPaymentContract[newPaymentContract_] = true;
    //getPaymentAddressForReserveToken[reserveToken_] = newPaymentContract_;
    return true;
  }

  function ownerDepositReserveToken( address reserveToken_, uint amount_ ) external onlyOwner() onlyReserveToken( reserveToken_ ) returns ( bool ) {
    IERC20( reserveToken_ ).safeTransferFrom( msg.sender, address(this), amount_ ); 
    _updateIntrinsicValueFromReserveDeposit( reserveToken_, amount_);
    return true;
  } 
  
  function _updateIntrinsicValueFromReserveDeposit( address reserveToken_, uint amount_ ) internal {
    getIntrinsicValueOfReserveToken[reserveToken_] = getIntrinsicValueOfReserveToken[reserveToken_].add(amount_);
  }

  function payDebt( 
    address depositor_,
    address principleTokenBeingCollected_,
    address reserveToken_
  ) external override
    onlyReserveToken( reserveToken_ )
    onlyPrincipleToken( principleTokenBeingCollected_ )
    onlyTeller( )
    returns ( bool )
  {
    ( 
      uint principleAmount_, 
      uint interestDue_,
      uint bondMaturationBlock_,
      uint bondingScaleFactor_
    ) =
      IPrincipleDepository( getBondingDepositoryForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_] )
        .getDepositorInfo( depositor_, principleTokenBeingCollected_, reserveToken_ );

    require( block.timestamp >= bondMaturationBlock_, "Vault: Bond has not yet matured." );

    uint outstandingDebtAmount_ =  getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_];

    require( outstandingDebtAmount_ >= interestDue_, "Vault: msg.sender is trying to collect more interest then there is outstanding debt." );

    getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_] = outstandingDebtAmount_.sub( outstandingDebtAmount_ );

    IERC20(principleTokenBeingCollected_).safeTransferFrom(msg.sender, address(this), principleAmount_);

    uint currentBalanceOfReserveToken_ = IERC20(principleTokenBeingCollected_).balanceOf( address(this) );

    uint currentRegisteredBalanceOfReserveTokenPlusPrincipleAmount_ =  getPrincipleTokenBalanceForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_].add( principleAmount_ );
    
    require( currentBalanceOfReserveToken_ >= currentRegisteredBalanceOfReserveTokenPlusPrincipleAmount_, "Vault: Not enough debt tokens has been deposited." );

    getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_] = currentRegisteredBalanceOfReserveTokenPlusPrincipleAmount_;

    IERC20Mintable( reserveToken_ ).mint( depositor_, interestDue_ );

    uint additionalIntrinsicValue_ = IBondingCalculator( getBondingCalculatorForPrincipleTokenForReserveToken[reserveToken_][principleTokenBeingCollected_] ).principleValuation( principleTokenBeingCollected_, principleAmount_ );
    
    getIntrinsicValueOfReserveToken[reserveToken_] = getIntrinsicValueOfReserveToken[reserveToken_].add( additionalIntrinsicValue_ );

    return true;
 }

  function incurDebt( address reserveToken_, address principleToken_, uint principieTokenAmountDeposited_ ) external override onlyPayment( ) onlyReserveToken( reserveToken_ ) onlyPrincipleToken( principleToken_ ) returns ( bool ) {
    getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleToken_] = getDebtAmountDueForPrincipleTokenForReserveToken[reserveToken_][principleToken_].add(
        IBondingCalculator( getBondingCalculatorForPrincipleTokenForReserveToken[reserveToken_][principleToken_] )
          .principleValuation( principleToken_, principieTokenAmountDeposited_)
      );
    return true;
  }
  
  uint public override epochPeriod;
  uint32 public override epochTWAPTimestamp;
  uint32 public override previousEpochTWAPTimestamp;

  mapping( address => address ) public override getTWAPOracleForReserveToken;
  
  uint public override lastEpochIntrinsicValue;
  uint public override lastEpochManagedTokenTotalSupply;

  function setTWAPOracleForPrincipleToken( address newTWAPOracleForReserveToken_, address reserveToken_ ) external override onlyOwner() returns ( bool ) {
    getTWAPOracleForReserveToken[reserveToken_] = newTWAPOracleForReserveToken_;
    return true;
  }

  function _updateEpoch( address reserveToken_, address managedToken_, address paymentAddress ) internal returns ( bool ) {
    if( epochPeriod >= _calculateElapsedTimeSinceLastUpdate( epochTWAPTimestamp, previousEpochTWAPTimestamp ) ) {
      previousEpochTWAPTimestamp = epochTWAPTimestamp;
      epochTWAPTimestamp = ITWAPOracle( getTWAPOracleForReserveToken[reserveToken_] )
        .priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp( managedToken_, reserveToken_, epochPeriod );

      lastEpochIntrinsicValue = getIntrinsicValueOfReserveToken[reserveToken_];
      lastEpochManagedTokenTotalSupply = IERC20( managedToken_ ).totalSupply();

      uint amountToMint_ = _calculateProfits();
      IERC20Mintable( managedToken_ ).mint( paymentAddress, amountToMint_ );
      IStaking( paymentAddress ).distributeOLYProfits();
    }
    return true;
  }

  function _calculateElapsedTimeSinceLastUpdate( uint32 epochTWAPTimestamp_, uint32 previousEpochTWAPTimestamp_ ) internal pure returns (uint32) {
    return epochTWAPTimestamp_ - previousEpochTWAPTimestamp_; // overflow is desired
  }

  function updateProfits( address paymentAddress, address reserveToken_, address managedToken_ ) external override onlyPayment( ) returns ( bool ) {
    _updateEpoch( reserveToken_, managedToken_, paymentAddress );
    return true;
  }

  function _calculateProfits() internal view returns ( uint ) {
    return lastEpochIntrinsicValue.sub( lastEpochManagedTokenTotalSupply );
  }
}