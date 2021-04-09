/**
 *Submitted for verification at Etherscan.io on 2021-04-08
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

interface IOHMERC20 {
    function burnFrom(address account_, uint256 amount_) external;
}

interface IBondingCalculator {
  function principleValuation( address principleTokenAddress_, uint amountDeposited_ ) external view returns ( uint principleValuation_ );
}

interface ITreasury {
    function depositReserves( uint amount_, address reserveToken_ ) external returns ( bool );
    
    function withdrawReserves( uint amount_, address reserveToken_ ) external returns ( bool );

    function depositPrinciple( uint amount_, address principleToken_ ) external returns ( bool );

    function withdrawPrinciple( uint amountToWithdraw_, address principleToken_ ) external returns ( bool );

    function incurDebt( uint amount_, address reserveToken_ ) external returns ( bool );

    function repayDebt( uint amount_, address reserveToken_ ) external returns ( bool );
}

contract Vault is ITreasury, Ownable {

    using SafeMath for uint;
    using SafeMathInt for int;
    using SafeERC20 for IERC20;

    event TimelockStarted( uint timelockEndBlock );

    bool public isInitialized;

    bool public isTimelockSet;
    uint public timelockDurationInBlocks;
    uint public timelockEndBlock;

    address public OHM;
    address public sOHM;
    address public bondingCalculator;

    address public daoWallet;

    bool public openWithdrawals;

    mapping( address => bool ) public isReserveToken;
    mapping( address => bool ) public isReserveDepositor;
    mapping( address => bool ) public isReserveSpender;

    mapping( address => bool ) public isPrincipleToken;
    mapping( address => bool ) public isPrincipleDepositor;
    mapping( address => bool ) public isPrincipleSpender;

    mapping( address => bool ) public isApprovedDebtor;
    mapping( address => uint ) public debtorBalance;

    modifier isTimelockExpired() {
        require( timelockEndBlock != 0 );
        require( isTimelockSet );
        require( block.number >= timelockEndBlock, "Timelock not expired" );
        _;
    }

    function initialize(
        address newManagedToken_,
        address newStakedToken_,
        address newReserveToken_,
        address newBondingCalculator_
    ) external onlyOwner() returns ( bool ) {
        require( !isInitialized, "Already initialized" );

        OHM = newManagedToken_;
        sOHM = newStakedToken_;
        isReserveToken[newReserveToken_] = true;
        bondingCalculator = newBondingCalculator_;
        openWithdrawals = false;
        isInitialized = true;

        return true;
    }

    function toggleReserveToken( address newReserveToken_ ) external onlyOwner() returns ( bool ) {
        isReserveToken[ newReserveToken_ ] = !isReserveToken[ newReserveToken_ ];
        return true;
    }

    function toggleReserveDepositor( address newDepositor_ ) external onlyOwner() returns ( bool ) {
        isReserveDepositor[ newDepositor_ ] = !isReserveDepositor[ newDepositor_ ];
        return true;
    }

    function toggleReserveSpender( address reserveSpender_ ) external onlyOwner() returns ( bool ) {
        isReserveSpender[ reserveSpender_ ] = !isReserveSpender[ reserveSpender_ ];
        return true;
    }

    function togglePrincipleToken( address newPrincipleToken_ ) external onlyOwner() returns ( bool ) {
        isPrincipleToken[ newPrincipleToken_ ] = !isPrincipleToken[ newPrincipleToken_ ];
        return true;
    }
    
    function togglePrincipleDepositor( address newDepositor_ ) external onlyOwner() returns ( bool ) {
        isPrincipleDepositor[ newDepositor_ ] = !isPrincipleDepositor[ newDepositor_ ];
        return true;
    }

    function togglePrincipleSpender( address principleSpender_ ) external onlyOwner() returns ( bool ) {
        isPrincipleSpender[ principleSpender_ ] = !isPrincipleSpender[ principleSpender_ ];
        return true;
    }

    function toggleApprovedDebtor( address debtor_ ) external onlyOwner() returns ( bool ) {
        isApprovedDebtor[ debtor_ ] = !isApprovedDebtor[ debtor_ ];
        return true;
    }

    function toggleOpenWithdrawals() external onlyOwner() returns ( bool ) {
        openWithdrawals = !openWithdrawals;
        return true;
    }

    function depositReserves( uint amount_, address reserveToken_ ) external override returns ( bool ) {
        require( isReserveDepositor[msg.sender] == true, "Not allowed to deposit" );
        require( isReserveToken[ reserveToken_ ] == true, "Not a reserve token" );

        IERC20( reserveToken_ ).safeTransferFrom( msg.sender, address(this), amount_ );
        IERC20Mintable( OHM ).mint( msg.sender, amount_.div( 10 ** IERC20( OHM ).decimals() ) );

        return true;
    }

    function withdrawReserves( uint amount_, address reserveToken_ ) external override returns ( bool ) {
        require( isReserveToken[ reserveToken_ ] == true, "Not a reserve token" );
        if ( !openWithdrawals ) {
            require( isReserveSpender[msg.sender] == true, "Not allowed to withdraw" );
        }

        IOHMERC20( OHM ).burnFrom( msg.sender, amount_ );
        IERC20( reserveToken_ ).safeTransfer( msg.sender, amount_.mul( 10 ** IERC20( OHM ).decimals() ) );

        return true;
    }

    function depositPrinciple( uint amount_, address principleToken_ ) external override returns ( bool ) {
        require( isPrincipleDepositor[msg.sender] == true, "Not allowed to deposit" );
        require( isPrincipleToken[ principleToken_ ] == true, "Not a principle token" );

        IERC20( principleToken_ ).safeTransferFrom( msg.sender, address(this), amount_ );
        uint value = IBondingCalculator( bondingCalculator ).principleValuation( principleToken_, amount_ ).div( 1e9 );
        IERC20Mintable( OHM ).mint( msg.sender, value );

        return true;
    }

    function withdrawPrinciple( uint amountToWithdraw_, address principleToken_ ) external override returns ( bool ) {
        require( isPrincipleSpender[msg.sender] == true, "Not allowed to withdraw" );
        require( isPrincipleToken[ principleToken_ ] == true, "Not a principle token" );

        uint amount_ = IBondingCalculator( bondingCalculator ).principleValuation( principleToken_, amountToWithdraw_ ).div( 1e9 );
        IOHMERC20( OHM ).burnFrom( msg.sender, amount_ );
        IERC20( principleToken_ ).safeTransfer( msg.sender, amountToWithdraw_ );

        return true;
    }

    function incurDebt( uint amount_, address reserveToken_ ) external override returns ( bool ) {
        require( isApprovedDebtor[ msg.sender ], "Not an approved debtor" );
        require( isReserveToken[ reserveToken_ ], "Not a reserve token" );

        uint maximumDebt = IERC20(sOHM).balanceOf( msg.sender );
        uint availableDebt = maximumDebt.sub( debtorBalance[ msg.sender ] );
        require( availableDebt >= amount_, "Exceeds available debt" );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].add( amount_ );

        IERC20( reserveToken_ ).safeTransfer( msg.sender, amount_.mul( 1e9 ) );
        return true;
    }

    function repayDebt( uint amount_, address reserveToken_ ) external override returns ( bool ) {
        require( isApprovedDebtor[ msg.sender ], "Not an approved debtor" );
        require( isReserveToken[ reserveToken_ ], "Not a reserve token" );

        IERC20( reserveToken_ ).safeTransferFrom( msg.sender, address(this), amount_.mul( 1e9 ) );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( amount_ );
        return true;
    }
    
    function migrateToken( address token_ ) external onlyOwner() isTimelockExpired() returns ( bool ) {
        IERC20( token_ ).safeTransfer( daoWallet, IERC20( token_ ).balanceOf( address( this ) ) );
        return true;
    }

    function rescueNonReserveAsset( address token_ ) external onlyOwner() returns ( bool ) {
        require ( !isReserveToken[ token_ ], "Cannot withdraw reserve tokens" );
        require ( !isPrincipleToken[ token_ ], "Cannot withdraw reserve tokens" );

        IERC20( token_ ).safeTransfer( daoWallet, IERC20( token_ ).balanceOf( address(this) ) );
        return true;
    }

    function setTimelock( uint newTimelockDurationInBlocks_ ) external onlyOwner() returns ( bool ) {
        require( !isTimelockSet, "Timelock already set" );
        timelockDurationInBlocks = newTimelockDurationInBlocks_;
        return true;
    }

    function startTimelock() external onlyOwner() returns ( bool ) {
        timelockEndBlock = block.number.add( timelockDurationInBlocks );
        isTimelockSet = true;
        emit TimelockStarted( timelockEndBlock );
        return true;
    }

    function setDAOWallet( address newDAOWallet_ ) external onlyOwner() returns ( bool ) {
        require( !isTimelockSet, "Cannot change DAO wallet while timelock is set" );
        daoWallet = newDAOWallet_;
        return true;
    }
}