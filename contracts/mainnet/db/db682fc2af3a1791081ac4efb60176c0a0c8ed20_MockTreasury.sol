/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
  function policy() external view returns (address);

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

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
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

interface IOHMERC20 {
    function burnFrom(address account_, uint256 amount_) external;
}

interface IBondCalculator {
  function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}

contract MockTreasury is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Deposit( address indexed token, uint amount, uint value, uint send );
    event Withdrawal( address indexed token, uint amount, uint value );

    address public immutable OHM;

    mapping( address => bool ) public isReserveToken;
    mapping( address => bool ) public isReserveDepositor;
    mapping( address => bool ) public isReserveSpender;
    mapping( address => bool ) public isReserveManager;

    mapping( address => bool ) public isLiquidityToken;
    mapping( address => bool ) public isLiquidityDepositor;
    mapping( address => bool ) public isLiquidityManager;

    mapping( address => address ) public bondCalculator; // bond calculator for liquidity token

    uint public totalReserves; // Risk-free value of all assets

    constructor( address _ohm ) {
        OHM = _ohm;
    }

    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ ) {
        require( isReserveToken[ _token ] || isLiquidityToken[ _token ], "Not accepted" );
        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        if ( isReserveToken[ _token ] ) {
            require( isReserveDepositor[ msg.sender ], "Not approved" );
        } else {
            require( isLiquidityDepositor[ msg.sender ], "Not approved" );
        }

        uint value = valueOf( _token, _amount );
        send_ = value.sub( _profit );

        totalReserves = totalReserves.add( value );

        emit Deposit( _token, _amount, value, send_ );
    }

    function withdraw( uint _amount, address _token ) external {
        require( isReserveToken[ _token ], "Not accepted" ); // Only reserves can be used for redemptions
        require( isReserveSpender[ msg.sender ] == true, "Not approved" );

        uint value = valueOf( _token, _amount );
        IOHMERC20( OHM ).burnFrom( msg.sender, value );

        totalReserves = totalReserves.sub( value );

        IERC20( _token ).safeTransfer( msg.sender, _amount );

        emit Withdrawal( _token, _amount, value );
    }

    function manage( address _token, uint _amount ) external {
        if( isLiquidityToken[ _token ] ) {
            require( isLiquidityManager[ msg.sender ], "Not approved" );
        } else {
            require( isReserveManager[ msg.sender ], "Not approved" );
        }

        uint value = valueOf( _token, _amount );
        totalReserves = totalReserves.sub( value );

        IERC20( _token ).safeTransfer( msg.sender, _amount );
    }

    function valueOf( address _token, uint _amount ) public view returns ( uint value_ ) {
        if ( isReserveToken[ _token ] ) {
            // convert amount to match OHM decimals
            value_ = _amount.mul( 10 ** IERC20( OHM ).decimals() ).div( 10 ** IERC20( _token ).decimals() );
        } else if ( isLiquidityToken[ _token ] ) {
            value_ = IBondCalculator( bondCalculator[ _token ] ).valuation( _token, _amount );
        }
    }

    enum MANAGING { RESERVEDEPOSITOR, RESERVESPENDER, RESERVETOKEN, RESERVEMANAGER, LIQUIDITYDEPOSITOR, LIQUIDITYTOKEN, LIQUIDITYMANAGER }

    function toggle( MANAGING _managing, address _address, address _calculator ) external onlyPolicy() {
        require( _address != address(0) );

        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            isReserveDepositor[ _address ] = !isReserveDepositor[ _address ];
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            isReserveSpender[ _address ] = !isReserveSpender[ _address ];
        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            isReserveToken[ _address ] = !isReserveToken[ _address ];
        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            isReserveManager[ _address ] = !isReserveManager[ _address ];
        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            isLiquidityDepositor[ _address ] = !isLiquidityDepositor[ _address ];
        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 5
            isLiquidityToken[ _address ] = !isLiquidityToken[ _address ];
            bondCalculator[ _address ] = _calculator;
        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { // 6
            isLiquidityManager[ _address ] = !isLiquidityManager[ _address ];
        }
    }
}