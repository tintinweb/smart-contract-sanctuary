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

interface ITreasury {
  function getBondingCalculator() external returns ( address );
  function payDebt( address depositor_ ) external returns ( bool );
  function getTimelockEndBlock() external returns ( uint );
  function getManagedToken() external returns ( address );
  function getDebtAmountDue() external returns ( uint );
  function incurDebt( address principleToken_, uint principieTokenAmountDeposited_ ) external returns ( bool );
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

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

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

  struct POLYVestingTerm {
    uint depositorFullyVestedSupplyOfOhm;
    uint maxpOLYCanRedeem;
    uint amountOfpOLYHasBeenRedeemed;
  }

  mapping( address => POLYVestingTerm ) public getPOLYVestingTermForHolder;

  bool public isInitialized;

  uint public timelockDurationInBlocks;
  bool public isTimelockSet;
  uint public override getTimelockEndBlock;

  address public daoWallet;
  address public stakingContract;

  uint public daoProfitShare;

  uint public override getDebtAmountDue;
  uint public getPrincipleTokenBalance;

  address public override getManagedToken;
  address public getReserveToken;
  address public getPrincipleToken;
  address public pOLYToken;

  address public override getBondingCalculator;

  mapping( address => bool ) public isReserveToken;

  mapping( address => bool ) public isPrincipleToken;

  mapping( address => bool ) public isPaymentContract;

  address public getPrincipleDepository;

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

  modifier onlyPayment() {
    require( isPaymentContract[msg.sender] == true, "Vault:: msg.sender is not a registered payment contract." );
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

  function setDAOProfitShare( uint newDAOProfitShare_ ) external onlyOwner() returns ( bool ) {
    daoProfitShare = newDAOProfitShare_;
    return true;
  }

  function initialize( address newManagedToken_, address newReserveToken_, address newPrincipleToken_, address newpOLYToken_, address newBondingCalculator_, address newPrincipleDepository_ ) external onlyOwner() notInitialized() returns ( bool ) {
    getManagedToken = newManagedToken_;
    getReserveToken = newReserveToken_;
    isReserveToken[newReserveToken_] = true;
    getPrincipleToken = newPrincipleToken_;
    isPrincipleToken[newPrincipleToken_] = true;
    pOLYToken = newpOLYToken_;
    getBondingCalculator = newBondingCalculator_;
    getPrincipleDepository = newPrincipleDepository_;
    return true;
  }

  function addPaymentContract( address newPaymentContract_ ) external onlyOwner() returns ( bool ) {
    isPaymentContract[newPaymentContract_] = true;
    return true;
  }

  function incurDebt( address principleToken_, uint principieTokenAmountDeposited_ ) external override onlyPayment() onlyPrincipleToken( principleToken_ ) returns ( bool ) {
    getDebtAmountDue = getDebtAmountDue.add(
        IBondingCalculator( getBondingCalculator )
          .principleValuation( principleToken_, principieTokenAmountDeposited_)
      );
    return true;
  }

  function payDebt( 
    address depositor_
  ) external override
    onlyPayment()
    isTimelockStarted()
    returns ( bool )
  {
    ( 
      uint principleAmount_, 
      uint interestDue_,
    ) =
      IPrincipleDepository( getPrincipleDepository )
        .getDepositorInfoForDepositor( depositor_ );

    uint outstandingDebtAmount_ =  getDebtAmountDue;

    require( outstandingDebtAmount_ >= interestDue_, "Vault: msg.sender is trying to collect more interest then there is outstanding debt." );

    IERC20(getPrincipleToken).safeTransferFrom(msg.sender, address(this), principleAmount_);

    getDebtAmountDue = outstandingDebtAmount_.sub( interestDue_ );

    uint currentBalanceOfPrincipleToken_ = IERC20(getPrincipleToken).balanceOf( address(this) );

    uint currentPrincipleAmountPlusDeposit_ =  getPrincipleTokenBalance.add( principleAmount_ );
    
    require( currentBalanceOfPrincipleToken_ >= currentPrincipleAmountPlusDeposit_, "Vault: Not enough debt tokens has been deposited." );

    getDebtAmountDue = getDebtAmountDue.sub( interestDue_ );

    IERC20Mintable( getManagedToken ).mint( depositor_, interestDue_ );

    uint riskFreeValue_ = IBondingCalculator( getBondingCalculator ).principleValuation( getPrincipleToken, principleAmount_ );

    uint profit = riskFreeValue_.sub( interestDue_ );

    uint daoProfit_ = profit.div( daoProfitShare );

    IERC20Mintable( getManagedToken ).mint( daoWallet, daoProfit_ );

    IERC20Mintable( getManagedToken ).mint( stakingContract, profit.sub( daoProfit_ ) );

    return true;
 }

 function ownerDepositReserveToken( address reserveToken_, uint amount_ ) external onlyOwner() onlyReserveToken( reserveToken_ ) returns ( bool ) {
    IERC20( reserveToken_ ).safeTransferFrom( msg.sender, address(this), amount_ ); 
    IERC20Mintable( getManagedToken ).mint( daoWallet, amount_ );
    return true;
  }

  function depositPrinciple( address principleTokenAddress_, uint depositAmount_ ) external onlyOwner() onlyPrincipleToken( principleTokenAddress_ ) returns ( bool ) {
    IERC20( principleTokenAddress_ ).safeTransferFrom( msg.sender, address(this), depositAmount_ );
    IERC20Mintable( getManagedToken ).mint( stakingContract, IBondingCalculator( getBondingCalculator ).principleValuation( principleTokenAddress_, depositAmount_ ) );
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
    emit TimelockStarted( getTimelockEndBlock );
    return true;
  }

  function redeempOLY( uint amountToRedeem_ ) external returns ( bool ) {
    POLYVestingTerm memory holderPOLYVestingTerm = getPOLYVestingTermForHolder[msg.sender];
    int maxRedeemableAmount_ = int( IERC20( getManagedToken ).totalSupply().div( holderPOLYVestingTerm.depositorFullyVestedSupplyOfOhm ).mul( holderPOLYVestingTerm.maxpOLYCanRedeem ) );
    int redeemableAmount = maxRedeemableAmount_.sub( int( holderPOLYVestingTerm.amountOfpOLYHasBeenRedeemed ) );
    require( holderPOLYVestingTerm.amountOfpOLYHasBeenRedeemed < holderPOLYVestingTerm.maxpOLYCanRedeem );
    require( redeemableAmount >= int( amountToRedeem_ ) );
    getPOLYVestingTermForHolder[msg.sender].amountOfpOLYHasBeenRedeemed = holderPOLYVestingTerm.amountOfpOLYHasBeenRedeemed.add( amountToRedeem_ );
    IERC20( getReserveToken ).safeTransferFrom( msg.sender, address( this ), amountToRedeem_ );
    IERC20( pOLYToken ).safeTransferFrom( msg.sender, daoWallet, amountToRedeem_ );
    IERC20Mintable( getManagedToken ).mint( msg.sender, amountToRedeem_ );
    return true;
  }

  function _addPOLYHolder( address holder_, uint depositorFullyVestedSupplyOfOhm_, uint pOLYCanRedeemToAdd_ ) internal onlyOwner() returns ( bool ) {
    POLYVestingTerm memory holderPOLYVestingTerm = getPOLYVestingTermForHolder[holder_];
    getPOLYVestingTermForHolder[holder_] = POLYVestingTerm(
      {
        depositorFullyVestedSupplyOfOhm: holderPOLYVestingTerm.depositorFullyVestedSupplyOfOhm.add(depositorFullyVestedSupplyOfOhm_),
        maxpOLYCanRedeem: holderPOLYVestingTerm.maxpOLYCanRedeem.add( pOLYCanRedeemToAdd_ ),
        amountOfpOLYHasBeenRedeemed: holderPOLYVestingTerm.amountOfpOLYHasBeenRedeemed
      }
    );
    return true;
  }

  function addPOLYHolder( address holder_, uint depositorFullyVestedSupplyOfOhm_, uint pOLYCanRedeemToAdd_ ) external returns ( bool ) {
    _addPOLYHolder( holder_, depositorFullyVestedSupplyOfOhm_, pOLYCanRedeemToAdd_ );
    return true;
  }

  function addPOLYHolder( address[] calldata holder_, uint[] calldata depositorFullyVestedSupplyOfOhm_, uint[] calldata pOLYCanRedeemToAdd_ ) external returns ( bool ) {
    require( holder_.length == depositorFullyVestedSupplyOfOhm_.length && holder_.length == pOLYCanRedeemToAdd_.length );
    for( uint iteration_ = 0; holder_.length > iteration_; iteration_++ ) {
      _addPOLYHolder( holder_[iteration_], depositorFullyVestedSupplyOfOhm_[iteration_], pOLYCanRedeemToAdd_[iteration_] );
    }
    return true;
  }
}