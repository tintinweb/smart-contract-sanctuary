/**
 *Submitted for verification at snowtrace.io on 2022-01-02
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add32(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
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

    function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
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


library Address {

  function isContract(address account) internal view returns (bool) {
       

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function functionCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 weiValue, 
        string memory errorMessage
    ) private returns (bytes memory) {
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

    function _verifyCallResult(
        bool success, 
        bytes memory returndata, 
        string memory errorMessage
    ) private pure returns(bytes memory) {
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
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface IERC20Mintable {

  function mint( uint256 amount_ ) external;
  function mint( address account_, uint256 ammount_ ) external;
}


interface ISST {
    function burnFrom(address account_, uint256 amount_) external;
}


interface IBondCalculator {
  function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}


contract SSTTreasury is Ownable {

    using SafeMath for uint;
    using SafeMath for uint32;
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

    enum MANAGING { 
        RESERVEDEPOSITOR, 
        RESERVESPENDER, 
        RESERVETOKEN, 
        RESERVEMANAGER, 
        LIQUIDITYDEPOSITOR, 
        LIQUIDITYTOKEN, 
        LIQUIDITYMANAGER, 
        DEBTOR, 
        REWARDMANAGER, 
        SRS
    }

    address public immutable SST;
    uint32 public immutable secondsNeededForQueue;

    address[] public reserveTokens; 
    mapping( address => bool ) public isReserveToken;
    mapping( address => uint32 ) public reserveTokenQueue; 

    address[] public reserveDepositors; 
    mapping( address => bool ) public isReserveDepositor;
    mapping( address => uint32 ) public reserveDepositorQueue; 

    address[] public reserveSpenders; 
    mapping( address => bool ) public isReserveSpender;
    mapping( address => uint32 ) public reserveSpenderQueue; 

    address[] public liquidityTokens; 
    mapping( address => bool ) public isLiquidityToken;
    mapping( address => uint32 ) public LiquidityTokenQueue; 

    address[] public liquidityDepositors;  
    mapping( address => bool ) public isLiquidityDepositor;
    mapping( address => uint32 ) public LiquidityDepositorQueue; 

    mapping( address => address ) public bondCalculator; 

    address[] public reserveManagers;  
    mapping( address => bool ) public isReserveManager;
    mapping( address => uint32 ) public ReserveManagerQueue; 

    address[] public liquidityManagers;  
    mapping( address => bool ) public isLiquidityManager;
    mapping( address => uint32 ) public LiquidityManagerQueue; 

    address[] public debtors;  
    mapping( address => bool ) public isDebtor;
    mapping( address => uint32 ) public debtorQueue; 
    mapping( address => uint ) public debtorBalance;

    address[] public rewardManagers;  
    mapping( address => bool ) public isRewardManager;
    mapping( address => uint32 ) public rewardManagerQueue; 

    address public SRS;
    uint public SRSQueue;
    
    uint public totalReserves; 
    uint public totalDebt;

    constructor (
        address _SST,
        address _MIM,
        uint32 _secondsNeededForQueue
    ) {
        require( _SST != address(0) );
        SST = _SST;

        isReserveToken[ _MIM ] = true;
        reserveTokens.push( _MIM );


        secondsNeededForQueue = _secondsNeededForQueue;
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
        IERC20Mintable( SST ).mint( msg.sender, send_ );

        totalReserves = totalReserves.add( value );
        emit ReservesUpdated( totalReserves );

        emit Deposit( _token, _amount, value );
    }

    function withdraw( uint _amount, address _token ) external {
        require( isReserveToken[ _token ], "Not accepted" ); 
        require( isReserveSpender[ msg.sender ] == true, "Not approved" );

        uint value = valueOf( _token, _amount );
        ISST( SST ).burnFrom( msg.sender, value );

        totalReserves = totalReserves.sub( value );
        emit ReservesUpdated( totalReserves );

        IERC20( _token ).safeTransfer( msg.sender, _amount );

        emit Withdrawal( _token, _amount, value );
    }

   
    function incurDebt( uint _amount, address _token ) external {
        require( isDebtor[ msg.sender ], "Not approved" );
        require( isReserveToken[ _token ], "Not accepted" );

        uint value = valueOf( _token, _amount );

        uint maximumDebt = IERC20( SRS ).balanceOf( msg.sender ); 
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
    function repayDebtWithSST( uint _amount ) external {
        require( isDebtor[ msg.sender ], "Not approved" );

        ISST( SST ).burnFrom( msg.sender, _amount );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( _amount );
        totalDebt = totalDebt.sub( _amount );

        emit RepayDebt( msg.sender, SST, _amount, _amount );
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

        IERC20Mintable( SST ).mint( _recipient, _amount );

        emit RewardsMinted( msg.sender, _recipient, _amount );
    } 

    function excessReserves() public view returns ( uint ) {
        return totalReserves.sub( IERC20( SST ).totalSupply().sub( totalDebt ) );
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
            
            value_ = _amount.mul( 10 ** IERC20( SST ).decimals() ).div( 10 ** IERC20( _token ).decimals() );
        } else if ( isLiquidityToken[ _token ] ) {
            value_ = IBondCalculator( bondCalculator[ _token ] ).valuation( _token, _amount );
        }
    }

    function queue( MANAGING _managing, address _address ) external onlyManager() returns ( bool ) {
        require( _address != address(0) );
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { 
            reserveDepositorQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.RESERVESPENDER ) { 
            reserveSpenderQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.RESERVETOKEN ) { 
            reserveTokenQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.RESERVEMANAGER ) { 
            ReserveManagerQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue.mul32( 2 ) );
        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) {
            LiquidityDepositorQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) {
            LiquidityTokenQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) {
            LiquidityManagerQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue.mul32( 2 ) );
        } else if ( _managing == MANAGING.DEBTOR ) {
            debtorQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.REWARDMANAGER ) { 
            rewardManagerQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.SRS ) { 
            SRSQueue = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else return false;

        emit ChangeQueued( _managing, _address );
        return true;
    }

   
  
    function toggle(
        MANAGING _managing, 
        address _address, 
        address _calculator 
    ) external onlyManager() returns ( bool ) {
        require( _address != address(0) );
        bool result;
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { 
            if ( requirements( reserveDepositorQueue, isReserveDepositor, _address ) ) {
                reserveDepositorQueue[ _address ] = 0;
                if( !listContains( reserveDepositors, _address ) ) {
                    reserveDepositors.push( _address );
                }
            }
            result = !isReserveDepositor[ _address ];
            isReserveDepositor[ _address ] = result;
            
        } else if ( _managing == MANAGING.RESERVESPENDER ) { 
            if ( requirements( reserveSpenderQueue, isReserveSpender, _address ) ) {
                reserveSpenderQueue[ _address ] = 0;
                if( !listContains( reserveSpenders, _address ) ) {
                    reserveSpenders.push( _address );
                }
            }
            result = !isReserveSpender[ _address ];
            isReserveSpender[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVETOKEN ) { 
            if ( requirements( reserveTokenQueue, isReserveToken, _address ) ) {
                reserveTokenQueue[ _address ] = 0;
                if( !listContains( reserveTokens, _address ) ) {
                    reserveTokens.push( _address );
                }
            }
            result = !isReserveToken[ _address ];
            isReserveToken[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVEMANAGER ) { 
            if ( requirements( ReserveManagerQueue, isReserveManager, _address ) ) {
                reserveManagers.push( _address );
                ReserveManagerQueue[ _address ] = 0;
                if( !listContains( reserveManagers, _address ) ) {
                    reserveManagers.push( _address );
                }
            }
            result = !isReserveManager[ _address ];
            isReserveManager[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { 
            if ( requirements( LiquidityDepositorQueue, isLiquidityDepositor, _address ) ) {
                liquidityDepositors.push( _address );
                LiquidityDepositorQueue[ _address ] = 0;
                if( !listContains( liquidityDepositors, _address ) ) {
                    liquidityDepositors.push( _address );
                }
            }
            result = !isLiquidityDepositor[ _address ];
            isLiquidityDepositor[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { 
            if ( requirements( LiquidityTokenQueue, isLiquidityToken, _address ) ) {
                LiquidityTokenQueue[ _address ] = 0;
                if( !listContains( liquidityTokens, _address ) ) {
                    liquidityTokens.push( _address );
                }
            }
            result = !isLiquidityToken[ _address ];
            isLiquidityToken[ _address ] = result;
            bondCalculator[ _address ] = _calculator;

        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { 
            if ( requirements( LiquidityManagerQueue, isLiquidityManager, _address ) ) {
                LiquidityManagerQueue[ _address ] = 0;
                if( !listContains( liquidityManagers, _address ) ) {
                    liquidityManagers.push( _address );
                }
            }
            result = !isLiquidityManager[ _address ];
            isLiquidityManager[ _address ] = result;

        } else if ( _managing == MANAGING.DEBTOR ) { 
            if ( requirements( debtorQueue, isDebtor, _address ) ) {
                debtorQueue[ _address ] = 0;
                if( !listContains( debtors, _address ) ) {
                    debtors.push( _address );
                }
            }
            result = !isDebtor[ _address ];
            isDebtor[ _address ] = result;

        } else if ( _managing == MANAGING.REWARDMANAGER ) { 
            if ( requirements( rewardManagerQueue, isRewardManager, _address ) ) {
                rewardManagerQueue[ _address ] = 0;
                if( !listContains( rewardManagers, _address ) ) {
                    rewardManagers.push( _address );
                }
            }
            result = !isRewardManager[ _address ];
            isRewardManager[ _address ] = result;

        } else if ( _managing == MANAGING.SRS ) { 
            SRSQueue = 0;
            SRS = _address;
            result = true;

        } else return false;

        emit ChangeActivated( _managing, _address, result );
        return true;
    }

    function requirements( 
        mapping( address => uint32 ) storage queue_, 
        mapping( address => bool ) storage status_, 
        address _address 
    ) internal view returns ( bool ) {
        if ( !status_[ _address ] ) {
            require( queue_[ _address ] != 0, "Must queue" );
            require( queue_[ _address ] <= uint32(block.timestamp), "Queue not expired" );
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