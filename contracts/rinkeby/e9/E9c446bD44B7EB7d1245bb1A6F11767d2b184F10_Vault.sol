/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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

interface IOwnable {
  function manager() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyManager() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

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

interface IBondCalculator {
  function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}

interface ICirculatingOHM {
    function OHMCirculatingSupply() external view returns ( uint );
}

interface IStaking {
    function rebase() external returns ( bool );
}

interface ITreasury {
    function deposit( uint amount_, address token_, uint profit_ ) external returns ( bool );
    
    function withdraw( uint amount_, address token_ ) external returns ( bool );

    function incurDebt( uint amount_, address token_ ) external returns ( bool );

    function repayDebtWithReserve( uint amount_, address token_ ) external returns ( bool );
    
    function repayDebtWithOHM( uint amount_ ) external returns ( bool );

    function manageReserves( uint amount_, address token_ ) external returns ( bool );

    function manageLiquidity( uint amount_, address token_ ) external returns ( bool );

    function mintRewards( address recipient_, uint amount_ ) external returns ( bool );
}

contract Vault is ITreasury, Ownable {

    using SafeMath for uint;
    using SafeMathInt for int;
    using SafeERC20 for IERC20;

    enum MANAGING { RESERVEDEPOSITOR, RESERVESPENDER, RESERVETOKEN, RESERVEMANAGER, LIQUIDITYDEPOSITOR, LIQUIDITYSPENDER, LIQUIDITYTOKEN, LIQUIDITYMANAGER, DEBTOR, REWARDMANAGER }

    address[] public reserveTokens; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveToken;
    mapping( address => uint ) public reserveTokenQueue; // Delays changes to mapping.

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveDepositor;
    mapping( address => uint ) public reserveDepositorQueue; // Delays changes to mapping.

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveSpender;
    mapping( address => uint ) public reserveSpenderQueue; // Delays changes to mapping.

    address[] public liquidityTokens; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isLiquidityToken;
    mapping( address => uint ) public LiquidityTokenQueue; // Delays changes to mapping.

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isLiquidityDepositor;
    mapping( address => uint ) public LiquidityDepositorQueue; // Delays changes to mapping.

    address[] public liquiditySpenders; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isLiquiditySpender;
    mapping( address => uint ) public LiquiditySpenderQueue; // Delays changes to mapping.

    address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveManager;
    mapping( address => uint ) public ReserveManagerQueue; // Delays changes to mapping.

    address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isLiquidityManager;
    mapping( address => uint ) public LiquidityManagerQueue; // Delays changes to mapping.

    address[] public debtors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isDebtor;
    mapping( address => uint ) public debtorQueue; // Delays changes to mapping.
    mapping( address => uint ) public debtorBalance;

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isRewardManager;
    mapping( address => uint ) public rewardManagerQueue; // Delays changes to mapping.

    uint public lockLiquidityUntil; // Delays removal of liquidity 
    uint public immutable maxLiquidityManagement; // maximum liquidity withdrawn in period ( 9 decimals )
    uint public immutable liquidityManagementTimelock; // maximum frequency of liquidity withdrawals

    uint public blocksNeededForQueue;

    address public immutable OHM;
    address public immutable sOHM;
    address public immutable bondCalculator;
    
    uint public totalRewards;

    constructor (
        address OHM_,
        address sOHM_,
        address DAI_,
        address LP_,
        address bondCalculator_,
        uint blocksNeededForQueue_,
        uint maxLiquidityManagement_,
        uint liquidityManagementTimelock_
    ) {
        require( OHM_ != address(0) );
        OHM = OHM_;
        require( sOHM_ != address(0) );
        sOHM = sOHM_;
        require( bondCalculator_ != address(0) );
        bondCalculator = bondCalculator_;

        isReserveToken[ DAI_ ] = true;
        isLiquidityToken[ LP_ ] = true;
        blocksNeededForQueue = blocksNeededForQueue_;
        maxLiquidityManagement = maxLiquidityManagement_;
        liquidityManagementTimelock = liquidityManagementTimelock_;
    }

    /**
        @notice allow approved address to deposit an asset for OHM
        @param amount_ uint
        @param token_ address
        @return bool
     */
    function deposit( uint amount_, address token_, uint profit_ ) external override returns ( bool ) {
        uint value;
        IERC20( token_ ).safeTransferFrom( msg.sender, address(this), amount_ );

        if ( isReserveToken[ token_ ] ) { // Require reserve depositor and adjust decimals
            require( isReserveDepositor[ msg.sender ], "Not allowed to deposit" );
            // convert amount to match OHM decimals
            value = amount_.mul( 10 ** IERC20( OHM ).decimals() ).div( 10 ** IERC20( token_ ).decimals() );
        } else if ( isLiquidityToken[ token_ ] ) { // Require liquidity depositor and get valuation
            require( isLiquidityDepositor[ msg.sender ], "Not allowed to deposit" );
            value = IBondCalculator( bondCalculator ).valuation( token_, amount_ );
        } else return false;

        // mint OHM needed and store amount of rewards for distribution
        IERC20Mintable( OHM ).mint( msg.sender, value.sub( profit_ ) );
        totalRewards.add( profit_ );
        return true;
    }

    /**
        @notice allow approved address to burn OHM for reserves
        @param amount_ uint
        @param token_ address
        @return bool
     */
    function withdraw( uint amount_, address token_ ) external override returns ( bool ) {
        require( isReserveToken[ token_ ], "Only reserves" ); // Only reserves can be used for redemptions
        require( isReserveSpender[ msg.sender ] == true, "Not allowed to withdraw" );

        uint reserveAmount = amount_.mul( 10 ** IERC20( token_ ).decimals() ).div( 10 ** IERC20( OHM ).decimals() );

        IOHMERC20( OHM ).burnFrom( msg.sender, amount_ );
        IERC20( token_ ).safeTransfer( msg.sender, reserveAmount );
        return true;
    }

    /**
        @notice allow approved address to borrow reserves
        @param amount_ uint
        @param token_ address
        @return bool
     */
    function incurDebt( uint amount_, address token_ ) external override returns ( bool ) {
        require( isDebtor[ msg.sender ], "Not an approved debtor" );
        require( isReserveToken[ token_ ], "Not a reserve token" );

        uint maximumDebt = IERC20( sOHM ).balanceOf( msg.sender ); // Can only borrow against sOHM held
        uint availableDebt = maximumDebt.sub( debtorBalance[ msg.sender ] );
        require( availableDebt >= amount_, "Exceeds available debt" );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].add( amount_ );

        IERC20( token_ ).safeTransferFrom( 
            msg.sender, 
            address(this), 
            amount_.mul( 10 ** IERC20( token_ ).decimals() ).div( 10 ** IERC20( OHM ).decimals() ) 
        );
        return true;
    }

    /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param amount_ uint
        @param token_ address
        @return bool
     */
    function repayDebtWithReserve( uint amount_, address token_ ) external override returns ( bool ) {
        require( isDebtor[ msg.sender ], "Not an approved debtor" );
        require( isReserveToken[ token_ ], "Not a reserve token" );

        IERC20( token_ ).safeTransferFrom( 
            msg.sender, 
            address(this), 
            amount_.mul( 10 ** IERC20( token_ ).decimals() ).div( 10 ** IERC20( OHM ).decimals() ) 
        );
        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( amount_ );
        return true;
    }

    /**
        @notice allow approved address to repay borrowed reserves with OHM
        @param amount_ uint
        @return bool
     */
    function repayDebtWithOHM( uint amount_ ) external override returns ( bool ) {
        require( isDebtor[ msg.sender ], "Not an approved debtor" );

        IOHMERC20( OHM ).burnFrom( msg.sender, amount_ );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( amount_ );
        return true;
    }

    /**
        @notice allow approved address to withdraw reserves for yield deployment
        @param amount_ uint
        @param token_ uint
        @return bool
     */
    function manageReserves( uint amount_, address token_ ) external override returns ( bool ) {
        require( isReserveManager[ msg.sender ], "Not reserve manager" );
        require( !isLiquidityToken[ token_ ], "Cannot manage liquidity" );

        IERC20( token_ ).safeTransfer( msg.sender, amount_ );
        return true;
    }

    /**
        @notice allow approved address to manage liquidity
        @param amount_ uint
        @param token_ uint
        @return bool
     */
    function manageLiquidity( uint amount_, address token_ ) external override returns ( bool ) {
        require( isLiquidityManager[ msg.sender ], "Not liquidity manager" );
        require( isLiquidityToken[ token_ ], "Can only manage liquidity" );
        require( lockLiquidityUntil <= block.number, "Liquidity locked" );

        uint manageable = IERC20( token_ ).balanceOf( address(this) ).mul( maxLiquidityManagement ).div( 1e9 );
        require( amount_ <= manageable, "More than max liquidity management" );

        lockLiquidityUntil = block.number.add( liquidityManagementTimelock );
        IERC20( token_ ).safeTransfer( msg.sender, amount_ );
        return true;
    }

    /**
        @notice burn OHM and add it to reward distribution balance
        @param amount_ uint
        @return bool
     */
    function donate( uint amount_ ) external returns ( bool ) {
        IOHMERC20( OHM ).burnFrom( msg.sender, amount_ );
        totalRewards.add( amount_ );
        return true;
    }

    /**
        @notice send epoch reward to staking contract
        @return bool
     */
    function mintRewards( address recipient_, uint amount_ ) external override returns ( bool ) {
        require( isRewardManager[ msg.sender ], "Only reward manager" );
        require( amount_ <= totalRewards, "Not enough rewards" );

        totalRewards.sub( amount_ );
        IERC20Mintable( OHM ).mint( recipient_, amount_ );
        return true;
    } 

    /**
        @notice queue address to change boolean in mapping
        @param managing_ MANAGING
        @param address_ address
        @return bool
     */
    function queue( MANAGING managing_, address address_ ) external onlyManager() returns ( bool ) {
        require( address_ != address(0) );
        if ( managing_ == MANAGING.RESERVEDEPOSITOR ) { // Reserve Depositor
            reserveDepositorQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.RESERVESPENDER ) { // Reserve Spender
            reserveSpenderQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.RESERVETOKEN ) { // Reserve Token
            reserveTokenQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.RESERVEMANAGER ) { // Reserve Manager
            ReserveManagerQueue[ address_ ] = block.number.add( blocksNeededForQueue.mul( 2 ) );
        } else if ( managing_ == MANAGING.LIQUIDITYDEPOSITOR ) { // Liquidity Depositor
            LiquidityDepositorQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.LIQUIDITYSPENDER ) { // Liquidity Spender
            LiquiditySpenderQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.LIQUIDITYTOKEN ) { // Liquidity Token
            LiquidityTokenQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.LIQUIDITYMANAGER ) { // Liquidity Manager
            LiquidityManagerQueue[ address_ ] = block.number.add( blocksNeededForQueue.mul( 2 ) );
        } else if ( managing_ == MANAGING.DEBTOR ) { // Debtor
            debtorQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.REWARDMANAGER ) { // Reward Manager
            rewardManagerQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else return false;

        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param managing_ MANAGING
        @param address_ address
        @return bool
     */
    function toggle( MANAGING managing_, address address_ ) external onlyManager() returns ( bool ) {
        if ( managing_ == MANAGING.RESERVEDEPOSITOR ) { // Reserve Depositor
            if ( requirements( reserveDepositorQueue, isReserveDepositor, address_ ) ) {
                reserveDepositors[ reserveDepositors.length ] = address_;
                reserveDepositorQueue[ address_ ] = 0;
            }
            isReserveDepositor[ address_ ] = !isReserveDepositor[ address_ ];
            
        } else if ( managing_ == MANAGING.RESERVESPENDER ) { // Reserve Spender
            if ( requirements( reserveSpenderQueue, isReserveSpender, address_ ) ) {
                reserveSpenders[ reserveSpenders.length ] = address_;
                reserveSpenderQueue[ address_ ] = 0;
            }
            isReserveSpender[ address_ ] = !isReserveSpender[ address_ ];

        } else if ( managing_ == MANAGING.RESERVETOKEN ) { // Reserve Token
            if ( requirements( reserveTokenQueue, isReserveToken, address_ ) ) {
                reserveTokens[ reserveTokens.length ] = address_;
                reserveTokenQueue[ address_ ] = 0;
            }
            isReserveToken[ address_ ] = !isReserveToken[ address_ ];

        } else if ( managing_ == MANAGING.RESERVEMANAGER ) { // Reserve Manager
            if ( requirements( ReserveManagerQueue, isReserveManager, address_ ) ) {
                reserveManagers[ reserveManagers.length ] = address_;
                ReserveManagerQueue[ address_ ] = 0;
            }
            isReserveManager[ address_ ] = !isReserveManager[ address_ ];

        } else if ( managing_ == MANAGING.LIQUIDITYDEPOSITOR ) { // Liquidity Depositor
            if ( requirements( LiquidityDepositorQueue, isLiquidityDepositor, address_ ) ) {
                liquidityDepositors[ liquidityDepositors.length ] = address_;
                LiquidityDepositorQueue[ address_ ] = 0;
            }
            isLiquidityDepositor[ address_ ] = !isLiquidityDepositor[ address_ ];

        } else if ( managing_ == MANAGING.LIQUIDITYSPENDER ) { // Liquidity Spender
            if ( requirements( LiquiditySpenderQueue, isLiquiditySpender, address_ ) ) {
                liquiditySpenders[ liquiditySpenders.length ] = address_;
                LiquiditySpenderQueue[ address_ ] = 0;
            }
            isLiquiditySpender[ address_ ] = !isLiquiditySpender[ address_ ];

        } else if ( managing_ == MANAGING.LIQUIDITYTOKEN ) { // Liquidity Token
            if ( requirements( LiquidityTokenQueue, isLiquidityToken, address_ ) ) {
                liquidityTokens[ liquidityTokens.length ] = address_;
                LiquidityTokenQueue[ address_ ] = 0;
            }
            isLiquidityToken[ address_ ] = !isLiquidityToken[ address_ ];

        } else if ( managing_ == MANAGING.LIQUIDITYMANAGER ) { // Liquidity Manager
            if ( requirements( LiquidityManagerQueue, isLiquidityManager, address_ ) ) {
                liquidityManagers[ liquidityManagers.length ] = address_;
                LiquidityManagerQueue[ address_ ] = 0;
            }
            isLiquidityManager[ address_ ] = !isLiquidityManager[ address_ ];

        } else if ( managing_ == MANAGING.DEBTOR ) { // Debtor
            if ( requirements( debtorQueue, isDebtor, address_ ) ) {
                debtors[ debtors.length ] = address_;
                debtorQueue[ address_ ] = 0;
            }
            isDebtor[ address_ ] = !isDebtor[ address_ ];

        } else if ( managing_ == MANAGING.REWARDMANAGER ) { // Reward manager
            if ( requirements( rewardManagerQueue, isRewardManager, address_ ) ) {
                rewardManagers[ rewardManagers.length ] = address_;
                rewardManagerQueue[ address_ ] = 0;
            }
            isRewardManager[ address_ ] = !isRewardManager[ address_ ];

        } else return false;
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param address_ address
        @return _conditionWasTrue bool 
     */
    function requirements( 
        mapping( address => uint ) storage queue_, 
        mapping( address => bool ) storage status_, 
        address address_ 
    ) internal view returns (
        bool _conditionWasTrue
    ) {
        if ( !status_[ address_ ] ) {
            require( queue_[ address_ ] != 0, "Must queue" );
            require( queue_[ address_ ] <= block.number, "Queue not expired" );
            _conditionWasTrue = false;
        }
    }
}