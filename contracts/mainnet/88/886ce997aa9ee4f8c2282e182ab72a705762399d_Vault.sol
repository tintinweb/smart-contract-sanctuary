/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {

  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
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

library SafeMathInt {

    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
}

interface IBondingCalculator {

  function calcDebtRatio( uint pendingDebtDue_, uint managedTokenTotalSupply_ ) external pure returns ( uint debtRatio_ );

  function calcBondPremium( uint debtRatio_, uint bondScalingFactor ) external pure returns ( uint premium_ );

  function calcPrincipleValuation( uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_ ) external pure returns ( uint principleValuation_ );

  function principleValuation( address principleTokenAddress_, uint amountDeposited_ ) external view returns ( uint principleValuation_ );

  function calculateBondInterest( address treasury_, address principleTokenAddress_, uint amountDeposited_, uint bondScalingFactor ) external returns ( uint interestDue_ );
}
/**
interface IPrincipleDepository {

  function getCurrentBondTerm() external returns ( uint, uint );

  function treasury() external returns ( address );

  function getBondCalculator() external returns ( address );

  function isPrincipleToken( address ) external returns ( bool );

  function getDepositorInfoForDepositor( address ) external returns ( uint, uint, uint );

  function addPrincipleToken( address newPrincipleToken_ ) external returns ( bool );

  function setTreasury( address newTreasury_ ) external returns ( bool );

  function addBondTerm( address bondPrincipleToken_, uint256 bondScalingFactor_, uint256 bondingPeriodInBlocks_ ) external returns ( bool );

  function getDepositorInfo( address depositorAddress_) external view returns ( uint principleAmount_, uint interestDue_, uint bondMaturationBlock_);

  function depositBondPrinciple( address bondPrincipleTokenToDeposit_, uint256 amountToDeposit_ ) external returns ( bool );

  function depositBondPrincipleWithPermit( address bondPrincipleTokenToDeposit_, uint256 amountToDeposit_, uint256 deadline, uint8 v, bytes32 r, bytes32 s ) external returns ( bool );

  function withdrawPrincipleAndForfeitInterest( address bondPrincipleToWithdraw_ ) external returns ( bool );

  function redeemBond(address bondPrincipleToRedeem_ ) external returns ( bool );
}
*/
interface ITreasury {
  function getBondingCalculator() external returns ( address );
  // function payDebt( address depositor_ ) external returns ( bool );
  function getTimelockEndBlock() external returns ( uint );
  function getManagedToken() external returns ( address );
  // function getDebtAmountDue() external returns ( uint );
  // function incurDebt( uint principieTokenAmountDeposited_, uint bondScalingValue_ ) external returns ( bool );
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

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

  function decimals() external view returns (uint8);
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
interface IERC20Mintable {

  function mint( uint256 amount_ ) external;

  function mint( address account_, uint256 ammount_ ) external;
}

contract Vault is ITreasury, Ownable {

  using SafeMath for uint;
  using SafeMathInt for int;
  using SafeERC20 for IERC20;

  event TimelockStarted( uint timelockEndBlock );

  bool public isInitialized;

  uint public timelockDurationInBlocks;
  bool public isTimelockSet;
  uint public override getTimelockEndBlock;

  address public daoWallet;
  address public LPRewardsContract;
  address public stakingContract;

  uint public LPProfitShare;

  uint public getPrincipleTokenBalance;

  address public override getManagedToken;
  address public getReserveToken;
  address public getPrincipleToken;

  address public override getBondingCalculator;

  mapping( address => bool ) public isReserveToken;

  mapping( address => bool ) public isPrincipleToken;
  
  mapping( address => bool ) public isPrincipleDepositor;
  
  mapping( address => bool ) public isReserveDepositor;

  modifier notInitialized() {
    require( !isInitialized );
    _;
  }

  modifier onlyReserveToken( address reserveTokenChallenge_ ) {
    require( isReserveToken[reserveTokenChallenge_] == true, "Vault: reserveTokenChallenge_ is not a reserve Token." );
    _;
  }

  modifier onlyPrincipleToken( address PrincipleTokenChallenge_ ) {
    require( isPrincipleToken[PrincipleTokenChallenge_] == true, "Vault: PrincipleTokenChallenge_ is not a Principle token." );
    _;
  }
  
  modifier notTimelockSet() {
    require( !isTimelockSet );
    _;
  }

  modifier isTimelockExpired() {
    require( getTimelockEndBlock != 0 );
    require( isTimelockSet );
    require( block.number >= getTimelockEndBlock );
    _;
  }

  modifier isTimelockStarted() {
    if( getTimelockEndBlock != 0 ) {
      emit TimelockStarted( getTimelockEndBlock );
    }
    _;
  }

  function setDAOWallet( address newDAOWallet_ ) external onlyOwner() returns ( bool ) {
    daoWallet = newDAOWallet_;
    return true;
  }

  function setStakingContract( address newStakingContract_ ) external onlyOwner() returns ( bool ) {
    stakingContract = newStakingContract_;
    return true;
  }

  function setLPRewardsContract( address newLPRewardsContract_ ) external onlyOwner() returns ( bool ) {
    LPRewardsContract = newLPRewardsContract_;
    return true;
  }

  function setLPProfitShare( uint newDAOProfitShare_ ) external onlyOwner() returns ( bool ) {
    LPProfitShare = newDAOProfitShare_;
    return true;
  }

  function initialize(
    address newManagedToken_,
    address newReserveToken_,
    address newBondingCalculator_,
    address newLPRewardsContract_
  ) external onlyOwner() notInitialized() returns ( bool ) {
    getManagedToken = newManagedToken_;
    getReserveToken = newReserveToken_;
    isReserveToken[newReserveToken_] = true;
    getBondingCalculator = newBondingCalculator_;
    LPRewardsContract = newLPRewardsContract_;
    isInitialized = true;
    return true;
  }

  function setPrincipleToken( address newPrincipleToken_ ) external onlyOwner() returns ( bool ) {
    getPrincipleToken = newPrincipleToken_;
    isPrincipleToken[newPrincipleToken_] = true;
    return true;
  }
  
  function setPrincipleDepositor( address newDepositor_ ) external onlyOwner() returns ( bool ) {
    isPrincipleDepositor[newDepositor_] = true;
    return true;
  }
  
  function setReserveDepositor( address newDepositor_ ) external onlyOwner() returns ( bool ) {
    isReserveDepositor[newDepositor_] = true;
    return true;
  }
  
  function removePrincipleDepositor( address depositor_ ) external onlyOwner() returns ( bool ) {
    isPrincipleDepositor[depositor_] = false;
    return true;
  }
  
  function removeReserveDepositor( address depositor_ ) external onlyOwner() returns ( bool ) {
    isReserveDepositor[depositor_] = false;
    return true;
  }

  function rewardsDepositPrinciple( uint depositAmount_ ) external returns ( bool ) {
    require(isReserveDepositor[msg.sender] == true, "Not allowed to deposit");
    address principleToken = getPrincipleToken;
    IERC20( principleToken ).safeTransferFrom( msg.sender, address(this), depositAmount_ );
    uint value = IBondingCalculator( getBondingCalculator ).principleValuation( principleToken, depositAmount_ ).div( 1e9 );
    uint forLP = value.div( LPProfitShare );
    IERC20Mintable( getManagedToken ).mint( stakingContract, value.sub( forLP ) );
    IERC20Mintable( getManagedToken ).mint( LPRewardsContract, forLP );
    return true;
  }

 function depositReserves( uint amount_ ) external returns ( bool ) {
    require(isReserveDepositor[msg.sender] == true, "Not allowed to deposit");
    IERC20( getReserveToken ).safeTransferFrom( msg.sender, address(this), amount_ );
    address managedToken_ = getManagedToken;
    IERC20Mintable( managedToken_ ).mint( msg.sender, amount_.div( 10 ** IERC20( managedToken_ ).decimals() ) );
    return true;
  }

  function depositPrinciple( uint depositAmount_ ) external returns ( bool ) {
    require(isPrincipleDepositor[msg.sender] == true, "Not allowed to deposit");
    address principleToken = getPrincipleToken;
    IERC20( principleToken ).safeTransferFrom( msg.sender, address(this), depositAmount_ );
    uint value = IBondingCalculator( getBondingCalculator ).principleValuation( principleToken, depositAmount_ ).div( 1e9 );
    IERC20Mintable( getManagedToken ).mint( msg.sender, value );
    return true;
  }
  
  function migrateReserveAndPrinciple() external onlyOwner() isTimelockExpired() returns ( bool saveGas_ ) {
    IERC20( getReserveToken ).safeTransfer( daoWallet, IERC20( getReserveToken ).balanceOf( address( this ) ) );
    IERC20( getPrincipleToken ).safeTransfer( daoWallet, IERC20( getPrincipleToken ).balanceOf( address( this ) ) );
    return true;
  }

  function setTimelock( uint newTimelockDurationInBlocks_ ) external onlyOwner() notTimelockSet() returns ( bool ) {
    timelockDurationInBlocks = newTimelockDurationInBlocks_;
    return true;
  }

  function startTimelock() external onlyOwner() returns ( bool ) {
    getTimelockEndBlock = block.number.add( timelockDurationInBlocks );
    isTimelockSet = true;
    emit TimelockStarted( getTimelockEndBlock );
    return true;
  }
}