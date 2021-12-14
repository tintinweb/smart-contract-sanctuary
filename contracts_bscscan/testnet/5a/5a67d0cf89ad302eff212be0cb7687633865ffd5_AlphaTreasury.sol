/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

pragma solidity ^0.8.10;

// ----------------------------------------------------------------------------
// --- Name   : AlphaDAO - [https://www.alphadao.financial/]
// --- Symbol : Format - {OX}
// --- Supply : Generated from DAO
// --- @title : the Beginning and the End 
// --- 01000110 01101111 01110010 00100000 01110100 01101000 01100101 00100000 01101100 
// --- 01101111 01110110 01100101 00100000 01101111 01100110 00100000 01101101 01111001 
// --- 00100000 01100011 01101000 01101001 01101100 01100100 01110010 01100101 01101110
// --- AlphaDAO.financial - EJS32 - 2021
// --- @dev pragma solidity version:0.8.10+commit.fc410830
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Library SafeMath 
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// --- Library Address 
// ----------------------------------------------------------------------------

library Address {

  function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// ----------------------------------------------------------------------------
// --- Interface IOwnable 
// ----------------------------------------------------------------------------

interface IOwnable {
  function manager() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

// ----------------------------------------------------------------------------
// --- Contract Ownable 
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// --- Interface IERC20 
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// --- Library SafeERC20 
// ----------------------------------------------------------------------------

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
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// ----------------------------------------------------------------------------
// --- Interface IERC20Mintable
// ----------------------------------------------------------------------------

interface IERC20Mintable {
  function mint( uint256 amount_ ) external;

  function mint( address account_, uint256 ammount_ ) external;
}

// ----------------------------------------------------------------------------
// --- Interface IOXERC20 
// ----------------------------------------------------------------------------

interface IOXERC20 {
    function burnFrom(address account_, uint256 amount_) external;
}

// ----------------------------------------------------------------------------
// --- Interface IBondCalculator 
// ----------------------------------------------------------------------------

interface IBondCalculator {
  function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}

// ----------------------------------------------------------------------------
// --- Contract AlphaTreasury 
// ----------------------------------------------------------------------------

contract AlphaTreasury is Ownable {

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    event Deposit( address indexed token, uint amount, uint value );
    event Withdrawal( address indexed token, uint amount, uint value );
    event CreateDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event RepayDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event ReservesManaged( address indexed token, uint amount );
    event ReservesUpdated( uint indexed totalReserves );
    event ReservesAudited( uint indexed totalReserves );
    event RewardsMinted( address indexed caller, address indexed recipient, uint amount );
    event ChangeQueued( MANAGING indexed managing, address queued );
    event ChangeActivated( MANAGING indexed managing, address activated, bool result );
    enum MANAGING { RESERVEDEPOSITOR, RESERVESPENDER, RESERVETOKEN, RESERVEMANAGER, LIQUIDITYDEPOSITOR, LIQUIDITYTOKEN, LIQUIDITYMANAGER, DEBTOR, REWARDMANAGER, SOX }

    address public immutable OX;
    uint public immutable blocksNeededForQueue;

    address[] public reserveTokens;
    mapping( address => bool ) public isReserveToken;
    mapping( address => uint ) public reserveTokenQueue;

    address[] public reserveDepositors;
    mapping( address => bool ) public isReserveDepositor;
    mapping( address => uint ) public reserveDepositorQueue;

    address[] public reserveSpenders; 
    mapping( address => bool ) public isReserveSpender;
    mapping( address => uint ) public reserveSpenderQueue;

    address[] public liquidityTokens; 
    mapping( address => bool ) public isLiquidityToken;
    mapping( address => uint ) public LiquidityTokenQueue;

    address[] public liquidityDepositors; 
    mapping( address => bool ) public isLiquidityDepositor;
    mapping( address => uint ) public LiquidityDepositorQueue; 

    mapping( address => address ) public bondCalculator;

    address[] public reserveManagers; 
    mapping( address => bool ) public isReserveManager;
    mapping( address => uint ) public ReserveManagerQueue; 

    address[] public liquidityManagers; 
    mapping( address => bool ) public isLiquidityManager;
    mapping( address => uint ) public LiquidityManagerQueue; 

    address[] public debtors; 
    mapping( address => bool ) public isDebtor;
    mapping( address => uint ) public debtorQueue; 
    mapping( address => uint ) public debtorBalance;

    address[] public rewardManagers; 
    mapping( address => bool ) public isRewardManager;
    mapping( address => uint ) public rewardManagerQueue; 

    address public xOX;
    uint public xOXQueue;
    
    uint public totalReserves; 
    uint public totalDebt;

    constructor (
        address _OX,
        address _DAI,
        address _Frax,
        address _OXDAI,
        uint _blocksNeededForQueue
    ) {
        require( _OX != address(0) );
        OX = _OX;

        isReserveToken[ _DAI ] = true;
        reserveTokens.push( _DAI );

        isReserveToken[ _Frax] = true;
        reserveTokens.push( _Frax );

       isLiquidityToken[ _OXDAI ] = true;
       liquidityTokens.push( _OXDAI );

        blocksNeededForQueue = _blocksNeededForQueue;
    }

    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ ) {
        require( isReserveToken[ _token ] || isLiquidityToken[ _token ], "Not accepted" );
        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        if ( isReserveToken[ _token ] ) {
            require( isReserveDepositor[ msg.sender ], "Not approved" );
        } else {
            require( isLiquidityDepositor[ msg.sender ], "Not approved" );
        }

        uint value = valueOf(_token, _amount);
        send_ = value.sub( _profit );
        IERC20Mintable( OX ).mint( msg.sender, send_ );

        totalReserves = totalReserves.add( value );
        emit ReservesUpdated( totalReserves );

        emit Deposit( _token, _amount, value );
    }

    function withdraw( uint _amount, address _token ) external {
        require( isReserveToken[ _token ], "Not accepted" ); 
        require( isReserveSpender[ msg.sender ] == true, "Not approved" );

        uint value = valueOf( _token, _amount );
        IOXERC20( OX ).burnFrom( msg.sender, value );

        totalReserves = totalReserves.sub( value );
        emit ReservesUpdated( totalReserves );

        IERC20( _token ).safeTransfer( msg.sender, _amount );

        emit Withdrawal( _token, _amount, value );
    }

    function incurDebt( uint _amount, address _token ) external {
        require( isDebtor[ msg.sender ], "Not approved" );
        require( isReserveToken[ _token ], "Not accepted" );

        uint value = valueOf( _token, _amount );

        uint maximumDebt = IERC20( xOX ).balanceOf( msg.sender ); 
        uint availableDebt = maximumDebt.sub( debtorBalance[ msg.sender ] );
        require( value <= availableDebt, "Exceeds debt limit" );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].add( value );
        totalDebt = totalDebt.add( value );

        totalReserves = totalReserves.sub( value );
        emit ReservesUpdated( totalReserves );

        IERC20( _token ).transfer( msg.sender, _amount );
        
        emit CreateDebt( msg.sender, _token, _amount, value );
    }

    function repayDebtWithReserve( uint _amount, address _token ) external {
        require( isDebtor[ msg.sender ], "Not approved" );
        require( isReserveToken[ _token ], "Not accepted" );

        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        uint value = valueOf( _token, _amount );
        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( value );
        totalDebt = totalDebt.sub( value );

        totalReserves = totalReserves.add( value );
        emit ReservesUpdated( totalReserves );

        emit RepayDebt( msg.sender, _token, _amount, value );
    }

    function repayDebtWithOX( uint _amount ) external {
        require( isDebtor[ msg.sender ], "Not approved" );

        IOXERC20( OX ).burnFrom( msg.sender, _amount );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( _amount );
        totalDebt = totalDebt.sub( _amount );

        emit RepayDebt( msg.sender, OX, _amount, _amount );
    }

    function manage( address _token, uint _amount ) external {
        if( isLiquidityToken[ _token ] ) {
            require( isLiquidityManager[ msg.sender ], "Not approved" );
        } else {
            require( isReserveManager[ msg.sender ], "Not approved" );
        }

        uint value = valueOf(_token, _amount);
        require( value <= excessReserves(), "Insufficient reserves" );

        totalReserves = totalReserves.sub( value );
        emit ReservesUpdated( totalReserves );

        IERC20( _token ).safeTransfer( msg.sender, _amount );

        emit ReservesManaged( _token, _amount );
    }

    function mintRewards( address _recipient, uint _amount ) external {
        require( isRewardManager[ msg.sender ], "Not approved" );
        require( _amount <= excessReserves(), "Insufficient reserves" );

        IERC20Mintable( OX ).mint( _recipient, _amount );

        emit RewardsMinted( msg.sender, _recipient, _amount );
    } 

    function excessReserves() public view returns ( uint ) {
        return totalReserves.sub( IERC20( OX ).totalSupply().sub( totalDebt ) );
    }

    function auditReserves() external onlyManager() {
        uint reserves;
        for( uint i = 0; i < reserveTokens.length; i++ ) {
            reserves = reserves.add ( 
                valueOf( reserveTokens[ i ], IERC20( reserveTokens[ i ] ).balanceOf( address(this) ) )
            );
        }
        for( uint i = 0; i < liquidityTokens.length; i++ ) {
            reserves = reserves.add (
                valueOf( liquidityTokens[ i ], IERC20( liquidityTokens[ i ] ).balanceOf( address(this) ) )
            );
        }
        totalReserves = reserves;
        emit ReservesUpdated( reserves );
        emit ReservesAudited( reserves );
    }

    function valueOf( address _token, uint _amount ) public view returns ( uint value_ ) {
        if ( isReserveToken[ _token ] ) {
            value_ = _amount.mul( 10 ** IERC20( OX ).decimals() ).div( 10 ** IERC20( _token ).decimals() );
        } else if ( isLiquidityToken[ _token ] ) {
            value_ = IBondCalculator( bondCalculator[ _token ] ).valuation( _token, _amount );
        }
    }

    function queue( MANAGING _managing, address _address ) external onlyManager() returns ( bool ) {
        require( _address != address(0) );
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            reserveDepositorQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            reserveSpenderQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            reserveTokenQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            ReserveManagerQueue[ _address ] = block.number.add( blocksNeededForQueue.mul( 2 ) );
        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            LiquidityDepositorQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 5
            LiquidityTokenQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { // 6
            LiquidityManagerQueue[ _address ] = block.number.add( blocksNeededForQueue.mul( 2 ) );
        } else if ( _managing == MANAGING.DEBTOR ) { // 7
            debtorQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 8
            rewardManagerQueue[ _address ] = block.number.add( blocksNeededForQueue );
        } else if ( _managing == MANAGING.SOX ) { // 9
            xOXQueue = block.number.add( blocksNeededForQueue );
        } else return false;

        emit ChangeQueued( _managing, _address );
        return true;
    }

    function toggle( MANAGING _managing, address _address, address _calculator ) external onlyManager() returns ( bool ) {
        require( _address != address(0) );
        bool result;
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            if ( requirements( reserveDepositorQueue, isReserveDepositor, _address ) ) {
                reserveDepositorQueue[ _address ] = 0;
                if( !listContains( reserveDepositors, _address ) ) {
                    reserveDepositors.push( _address );
                }
            }
            result = !isReserveDepositor[ _address ];
            isReserveDepositor[ _address ] = result;
            
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            if ( requirements( reserveSpenderQueue, isReserveSpender, _address ) ) {
                reserveSpenderQueue[ _address ] = 0;
                if( !listContains( reserveSpenders, _address ) ) {
                    reserveSpenders.push( _address );
                }
            }
            result = !isReserveSpender[ _address ];
            isReserveSpender[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            if ( requirements( reserveTokenQueue, isReserveToken, _address ) ) {
                reserveTokenQueue[ _address ] = 0;
                if( !listContains( reserveTokens, _address ) ) {
                    reserveTokens.push( _address );
                }
            }
            result = !isReserveToken[ _address ];
            isReserveToken[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            if ( requirements( ReserveManagerQueue, isReserveManager, _address ) ) {
                reserveManagers.push( _address );
                ReserveManagerQueue[ _address ] = 0;
                if( !listContains( reserveManagers, _address ) ) {
                    reserveManagers.push( _address );
                }
            }
            result = !isReserveManager[ _address ];
            isReserveManager[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            if ( requirements( LiquidityDepositorQueue, isLiquidityDepositor, _address ) ) {
                liquidityDepositors.push( _address );
                LiquidityDepositorQueue[ _address ] = 0;
                if( !listContains( liquidityDepositors, _address ) ) {
                    liquidityDepositors.push( _address );
                }
            }
            result = !isLiquidityDepositor[ _address ];
            isLiquidityDepositor[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 5
            if ( requirements( LiquidityTokenQueue, isLiquidityToken, _address ) ) {
                LiquidityTokenQueue[ _address ] = 0;
                if( !listContains( liquidityTokens, _address ) ) {
                    liquidityTokens.push( _address );
                }
            }
            result = !isLiquidityToken[ _address ];
            isLiquidityToken[ _address ] = result;
            bondCalculator[ _address ] = _calculator;

        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { // 6
            if ( requirements( LiquidityManagerQueue, isLiquidityManager, _address ) ) {
                LiquidityManagerQueue[ _address ] = 0;
                if( !listContains( liquidityManagers, _address ) ) {
                    liquidityManagers.push( _address );
                }
            }
            result = !isLiquidityManager[ _address ];
            isLiquidityManager[ _address ] = result;

        } else if ( _managing == MANAGING.DEBTOR ) { // 7
            if ( requirements( debtorQueue, isDebtor, _address ) ) {
                debtorQueue[ _address ] = 0;
                if( !listContains( debtors, _address ) ) {
                    debtors.push( _address );
                }
            }
            result = !isDebtor[ _address ];
            isDebtor[ _address ] = result;

        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 8
            if ( requirements( rewardManagerQueue, isRewardManager, _address ) ) {
                rewardManagerQueue[ _address ] = 0;
                if( !listContains( rewardManagers, _address ) ) {
                    rewardManagers.push( _address );
                }
            }
            result = !isRewardManager[ _address ];
            isRewardManager[ _address ] = result;

        } else if ( _managing == MANAGING.SOX ) { // 9
            xOXQueue = 0;
            xOX = _address;
            result = true;

        } else return false;

        emit ChangeActivated( _managing, _address, result );
        return true;
    }

    function requirements( 
        mapping( address => uint ) storage queue_, 
        mapping( address => bool ) storage status_, 
        address _address 
    ) internal view returns ( bool ) {
        if ( !status_[ _address ] ) {
            require( queue_[ _address ] != 0, "Must queue" );
            require( queue_[ _address ] <= block.number, "Queue not expired" );
            return true;
        } return false;
    }

    function listContains( address[] storage _list, address _token ) internal view returns ( bool ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return true;
            }
        }
        return false;
    }
}