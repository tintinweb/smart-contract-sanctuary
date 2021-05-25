/**
 *Submitted for verification at Etherscan.io on 2021-05-24
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

    function totalSupply() external view returns (uint256);

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

contract Vault is Ownable {

    using SafeMath for uint;
    using SafeMathInt for int;
    using SafeERC20 for IERC20;

    enum MANAGING { RESERVEDEPOSITOR, RESERVESPENDER, RESERVETOKEN, RESERVEMANAGER, LIQUIDITYDEPOSITOR, LIQUIDITYTOKEN, LIQUIDITYMANAGER, DEBTOR, REWARDMANAGER }

    address[] public reserveTokens; 
    mapping( address => bool ) public isReserveToken;
    mapping( address => uint ) public reserveTokenQueue; // Delays changes to mapping.

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveDepositor;
    mapping( address => uint ) public reserveDepositorQueue; // Delays changes to mapping.

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveSpender;
    mapping( address => uint ) public reserveSpenderQueue; // Delays changes to mapping.

    address[] public liquidityTokens; 
    mapping( address => bool ) public isLiquidityToken;
    mapping( address => uint ) public LiquidityTokenQueue; // Delays changes to mapping.

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isLiquidityDepositor;
    mapping( address => uint ) public LiquidityDepositorQueue; // Delays changes to mapping.

    mapping( address => address ) public bondCalculator; // bond calculator for liquidity token

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

    uint public immutable blocksNeededForQueue;

    address public immutable OHM;
    address public immutable sOHM;
    
    uint public totalReserves; // Risk-free value of all assets
    uint public totalDebt;

    constructor (
        address _OHM,
        address _sOHM,
        address _DAI,
        uint _blocksNeededForQueue
    ) {
        require( _OHM != address(0) );
        OHM = _OHM;
        require( _sOHM != address(0) );
        sOHM = _sOHM;

        isReserveToken[ _DAI ] = true;
        reserveTokens.push( _DAI );

        blocksNeededForQueue = _blocksNeededForQueue;
    }

    /**
        @notice allow approved address to deposit an asset for OHM
        @param _amount uint
        @param _token address
        @param _profit uint
        @return bool
     */
    function deposit( uint _amount, address _token, uint _profit ) external returns ( bool ) {
        require( isReserveToken[ _token ] || isLiquidityToken[ _token ], "Not accepted token" );
        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        if ( isReserveToken[ _token ] ) {
            require( isReserveDepositor[ msg.sender ], "Not allowed to deposit" );
        } else {
            require( isLiquidityDepositor[ msg.sender ], "Not allowed to deposit" );
        }

        // mint OHM needed and store amount of rewards for distribution
        IERC20Mintable( OHM ).mint( msg.sender, valueOf( _token, _amount ).sub( _profit ) );
        return true;
    }

    /**
        @notice allow approved address to burn OHM for reserves
        @param _amount uint
        @param _token address
        @return bool
     */
    function withdraw( uint _amount, address _token ) external returns ( bool ) {
        require( isReserveToken[ _token ], "Only reserves" ); // Only reserves can be used for redemptions
        require( isReserveSpender[ msg.sender ] == true, "Not allowed to withdraw" );

        IOHMERC20( OHM ).burnFrom( msg.sender, valueOf( _token, _amount ) );
        IERC20( _token ).safeTransfer( msg.sender, _amount );
        return true;
    }

    /**
        @notice allow approved address to borrow reserves
        @param _amount uint
        @param _token address
        @return bool
     */
    function incurDebt( uint _amount, address _token ) external returns ( bool ) {
        require( isDebtor[ msg.sender ], "Not an approved debtor" );
        require( isReserveToken[ _token ], "Not a reserve token" );

        uint value = valueOf( _token, _amount );

        uint maximumDebt = IERC20( sOHM ).balanceOf( msg.sender ); // Can only borrow against sOHM held
        uint availableDebt = maximumDebt.sub( debtorBalance[ msg.sender ] );
        require( availableDebt >= value, "Exceeds available debt" );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].add( value );
        totalDebt = totalDebt.add( value );

        IERC20( _token ).transfer( msg.sender, _amount );
        return true;
    }

    /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param _amount uint
        @param _token address
        @return bool
     */
    function repayDebtWithReserve( uint _amount, address _token ) external returns ( bool ) {
        require( isDebtor[ msg.sender ], "Not an approved debtor" );
        require( isReserveToken[ _token ], "Not a reserve token" );

        uint value = valueOf( _token, _amount );
        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( value );
        totalDebt = totalDebt.sub( value );
        return true;
    }

    /**
        @notice allow approved address to repay borrowed reserves with OHM
        @param _amount uint
        @return bool
     */
    function repayDebtWithOHM( uint _amount ) external returns ( bool ) {
        require( isDebtor[ msg.sender ], "Not an approved debtor" );

        IOHMERC20( OHM ).burnFrom( msg.sender, _amount );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( _amount );
        totalDebt = totalDebt.sub( _amount );
        return true;
    }

    /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
        @return bool
     */
    function manage( address _token, uint _amount ) external returns ( bool ) {
        if( isLiquidityToken[ _token ] ) {
            require( isLiquidityManager[ msg.sender ], "Not liquidity manager" );
        } else {
            require( isReserveManager[ msg.sender ], "Not reserve manager" );
        }
        
        updateTotalReserves();
        require( valueOf( _token, _amount ) < excessReserves(), "Cannot manage backing of circulating tokens" );

        IERC20( _token ).safeTransfer( msg.sender, _amount );
        return true;
    }

    /**
        @notice send epoch reward to staking contract
        @return bool
     */
    function mintRewards( address _recipient, uint _amount ) external returns ( bool ) {
        require( isRewardManager[ msg.sender ], "Only reward manager" );
        
        updateTotalReserves();
        require( _amount <= excessReserves(), "Not enough reserves" );

        IERC20Mintable( OHM ).mint( _recipient, _amount );
        return true;
    } 

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves() public view returns ( uint ) {
        return totalReserves.sub( IERC20( OHM ).totalSupply().sub( totalDebt ) );
    }

    /**
        @notice updates OHM value of reserves
        @return reserves_ uint
     */
    function updateTotalReserves() internal returns ( uint reserves_ ) {
        for( uint i = 0; i < reserveTokens.length; i++ ) {
            reserves_ = reserves_.add ( 
                valueOf( reserveTokens[ i ], IERC20( reserveTokens[ i ] ).balanceOf( address(this) ) )
            );
        }
        for( uint i = 0; i < liquidityTokens.length; i++ ) {
            reserves_ = reserves_.add (
                valueOf( liquidityTokens[ i ], IERC20( liquidityTokens[ i ] ).balanceOf( address(this) ) )
            );
        }
        totalReserves = reserves_;
    }

    /**
        @notice returns OHM valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOf( address _token, uint _amount ) public view returns ( uint value_ ) {
        if ( isReserveToken[ _token ] ) {
            // convert amount to match OHM decimals
            value_ = _amount.mul( 10 ** IERC20( OHM ).decimals() ).div( 10 ** IERC20( _token ).decimals() );
        } else if ( isLiquidityToken[ _token ] ) {
            value_ = IBondCalculator( bondCalculator[ _token ] ).valuation( _token, _amount );
        }
    }

    /**
        @notice queue address to change boolean in mapping
        @param managing_ MANAGING
        @param address_ address
        @return bool
     */
    function queue( MANAGING managing_, address address_ ) external onlyManager() returns ( bool ) {
        require( address_ != address(0) );
        if ( managing_ == MANAGING.RESERVEDEPOSITOR ) { // 0
            reserveDepositorQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.RESERVESPENDER ) { // 1
            reserveSpenderQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.RESERVETOKEN ) { // 2
            reserveTokenQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.RESERVEMANAGER ) { // 3
            ReserveManagerQueue[ address_ ] = block.number.add( blocksNeededForQueue.mul( 2 ) );
        } else if ( managing_ == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            LiquidityDepositorQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.LIQUIDITYTOKEN ) { // 5
            LiquidityTokenQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.LIQUIDITYMANAGER ) { // 6
            LiquidityManagerQueue[ address_ ] = block.number.add( blocksNeededForQueue.mul( 2 ) );
        } else if ( managing_ == MANAGING.DEBTOR ) { // 7
            debtorQueue[ address_ ] = block.number.add( blocksNeededForQueue );
        } else if ( managing_ == MANAGING.REWARDMANAGER ) { // 8
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
    function toggle( MANAGING managing_, address address_, address calculator_ ) external onlyManager() returns ( bool ) {
        if ( managing_ == MANAGING.RESERVEDEPOSITOR ) { // 0
            if ( requirements( reserveDepositorQueue, isReserveDepositor, address_ ) ) {
                reserveDepositors.push( address_ );
                reserveDepositorQueue[ address_ ] = 0;
            }
            isReserveDepositor[ address_ ] = !isReserveDepositor[ address_ ];
            
        } else if ( managing_ == MANAGING.RESERVESPENDER ) { // 1
            if ( requirements( reserveSpenderQueue, isReserveSpender, address_ ) ) {
                reserveSpenders.push( address_ );
                reserveSpenderQueue[ address_ ] = 0;
            }
            isReserveSpender[ address_ ] = !isReserveSpender[ address_ ];

        } else if ( managing_ == MANAGING.RESERVETOKEN ) { // 2
            if ( requirements( reserveTokenQueue, isReserveToken, address_ ) ) {
                reserveTokenQueue[ address_ ] = 0;
                if( !checkList( reserveTokens, address_ ) ) {
                    reserveTokens.push( address_ );
                }
            }
            isReserveToken[ address_ ] = !isReserveToken[ address_ ];

        } else if ( managing_ == MANAGING.RESERVEMANAGER ) { // 3
            if ( requirements( ReserveManagerQueue, isReserveManager, address_ ) ) {
                reserveManagers.push( address_ );
                ReserveManagerQueue[ address_ ] = 0;
            }
            isReserveManager[ address_ ] = !isReserveManager[ address_ ];

        } else if ( managing_ == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            if ( requirements( LiquidityDepositorQueue, isLiquidityDepositor, address_ ) ) {
                liquidityDepositors.push( address_ );
                LiquidityDepositorQueue[ address_ ] = 0;
            }
            isLiquidityDepositor[ address_ ] = !isLiquidityDepositor[ address_ ];

        } else if ( managing_ == MANAGING.LIQUIDITYTOKEN ) { // 5
            if ( requirements( LiquidityTokenQueue, isLiquidityToken, address_ ) ) {
                LiquidityTokenQueue[ address_ ] = 0;
                if( !checkList( liquidityTokens, address_ ) ) {
                    liquidityTokens.push( address_ );
                }
            }
            isLiquidityToken[ address_ ] = !isLiquidityToken[ address_ ];
            bondCalculator[ address_ ] = calculator_;

        } else if ( managing_ == MANAGING.LIQUIDITYMANAGER ) { // 6
            if ( requirements( LiquidityManagerQueue, isLiquidityManager, address_ ) ) {
                liquidityManagers.push( address_ );
                LiquidityManagerQueue[ address_ ] = 0;
            }
            isLiquidityManager[ address_ ] = !isLiquidityManager[ address_ ];

        } else if ( managing_ == MANAGING.DEBTOR ) { // 7
            if ( requirements( debtorQueue, isDebtor, address_ ) ) {
                debtors.push( address_ );
                debtorQueue[ address_ ] = 0;
            }
            isDebtor[ address_ ] = !isDebtor[ address_ ];

        } else if ( managing_ == MANAGING.REWARDMANAGER ) { // 8
            if ( requirements( rewardManagerQueue, isRewardManager, address_ ) ) {
                rewardManagers.push( address_ );
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
            _conditionWasTrue = true;
        }
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function checkList( address[] storage _list, address _token ) internal view returns ( bool ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return true;
            }
        }
        return false;
    }
}