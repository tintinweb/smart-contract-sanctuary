/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
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

interface sOHMInterface {
    function index() external view returns (uint);
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
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

interface IUniswapV2Router01 {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
} 

interface ITreasury {
    function incurDebt( uint amount_, address token_ ) external;
    function repayDebtWithReserve( uint amount_, address token_ ) external;
    function deposit( uint amount_, address token_, uint profit_ ) external returns ( uint send_ );
}

interface IFacilitatorContract {
    function retriveUnderlying( address _asset, uint _amount ) external returns ( bool );
}

contract ComposableStaking is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public immutable OHM;
    address public immutable sOHM;
    address public immutable treasury;
    address public immutable facilitatorContract;
    address public immutable staking;

    struct StakeInfo {
        mapping( address => uint) amountOfAsset;
        uint agnosticStake;
        uint debtTakenOn;
    }
    mapping( address => StakeInfo ) public stakeInfo;

    mapping( address => bool ) public approvedAsset;

    uint public profitFee;

    constructor( address _ohm, address _sOHM, address _treasury, address _facilitatorContract, address _staking ) {
        OHM = _ohm;
        sOHM = _sOHM;
        treasury = _treasury;
        facilitatorContract = _facilitatorContract;
        staking = _staking;
    }

    function toggleToken(address _token) external onlyManager() {
        approvedAsset[_token] = !approvedAsset[_token];
    }

    function toAgnostic( uint amount_ ) public view returns ( uint ) {
        return amount_.mul( 10 ** IERC20( sOHM ).decimals() ).div( sOHMInterface( sOHM ).index() );
    }

    function fromAgnostic( uint amount_ ) public view returns ( uint ) {
        return amount_.mul( sOHMInterface( sOHM ).index() ).div( 10 ** IERC20( sOHM ).decimals() );
    }

    function addExposureTo( address _asset, uint _amountSOHM, uint _minimumToReceive, address _reserveToUse, address _router ) external returns ( bool ) {
        require( approvedAsset[ _asset ], "Asset not approved as underlying" );

        uint _amountReserve = _amountSOHM.mul( 10 ** IERC20( _reserveToUse ).decimals() ).div( 10 ** IERC20( sOHM ).decimals());

        IERC20( sOHM ).transferFrom( msg.sender, address(this), _amountSOHM ); // transfers in sOHM

        ITreasury( treasury ).incurDebt( _amountReserve, _reserveToUse ); // receives reserves of staked OHM

        IERC20( _reserveToUse ).approve( _router, _amountReserve ); 

        uint[] memory _amounts = IUniswapV2Router01( _router ).swapExactTokensForTokens( // Swaps reserves for new asset
            _amountReserve, 
            _minimumToReceive,
            getPath( _reserveToUse, _asset ), 
            address(this), 
            10000000000000000
        );

        uint _amountOut = _amounts[ _amounts.length.sub(1) ];

        IERC20( _asset ).transfer( facilitatorContract, _amountOut );

        _updateStakeInfo( _asset, _amountSOHM, _amountOut, true );
        

        return true;
    }
 
    function removeExposureFrom( address _asset, uint _amountOfAsset, uint _minimumToReceive, address _reserveToUse, address _router ) external returns ( bool ) {
        require( approvedAsset[ _asset ], "Asset not approved as underlying" );
        require( stakeInfo[ msg.sender ].amountOfAsset[ _asset ] >= _amountOfAsset, "Not enough of asset");

        uint _userDebt = stakeInfo[ msg.sender ].debtTakenOn;

        IFacilitatorContract( facilitatorContract ).retriveUnderlying( _asset, _amountOfAsset );

        IERC20( _asset ).approve( _router, _amountOfAsset ); 

        uint[] memory _amounts = IUniswapV2Router01( _router ).swapExactTokensForTokens( // Swaps asset for reserve
            _amountOfAsset, 
            _minimumToReceive,
            getPath( _asset, _reserveToUse ), 
            address(this), 
            10000000000000000
        );

        uint _amountOut = _amounts[ _amounts.length.sub(1) ];
        uint _amountOutInSOHM = _amountOut.mul( 10 ** IERC20( sOHM ).decimals() ).div( 10 ** IERC20( _reserveToUse ).decimals());

        if( _amountOutInSOHM <= _userDebt ) {
            _updateStakeInfo( _asset, _amountOutInSOHM, _amountOfAsset, false );
            IERC20( _reserveToUse ).approve( treasury, _amountOut ); 
            ITreasury( treasury ).repayDebtWithReserve( _amountOut, _reserveToUse );
            IERC20( sOHM ).transfer( msg.sender, _amountOutInSOHM ); // transfers out sOHM
        } else if ( _amountOutInSOHM > _userDebt && _userDebt != 0 ) {
            _updateStakeInfo( _asset, _userDebt, _amountOfAsset, false );
            uint _userDebtInDAI = _userDebt.mul( 10 ** IERC20( _reserveToUse ).decimals() ).div( 10 ** IERC20( sOHM ).decimals());
            uint _daiProfits = _amountOut.sub( _userDebtInDAI );

            IERC20( _reserveToUse ).approve( treasury, _amountOut ); 

            ITreasury( treasury ).repayDebtWithReserve( _userDebtInDAI, _reserveToUse );
            ITreasury( treasury ).deposit( _daiProfits, _reserveToUse, 0 );

            IERC20( sOHM ).transfer( msg.sender, _userDebt );
            IERC20( OHM ).transfer( msg.sender, _amountOutInSOHM.sub(_userDebt) );
        } else {
            IERC20( _reserveToUse ).approve( treasury, _amountOut ); 
            ITreasury( treasury ).deposit( _amountOut, _reserveToUse, 0 );
            IERC20( OHM ).transfer( msg.sender, _amountOutInSOHM );
        }

        return true;
    }

    function removeUndebtedSOHM( uint _amountToRemove ) external returns( bool ) {

        _updateStakeInfo ( address(0), _amountToRemove, 0, false );
        uint _undebtedSOHM = getUndebtedSOHM( msg.sender );

        require( _undebtedSOHM >= _amountToRemove, "Not enough undebtedSOHM");
        IERC20( sOHM ).transfer( msg.sender, _amountToRemove );

        return true;
    }

    function getPath( address _token0, address _token1 ) private pure returns ( address[] memory ) {
        address[] memory path = new address[](2);
        path[0] = _token0;
        path[1] = _token1;
        return path;
    }

    function getUndebtedSOHM( address _address ) public view returns ( uint ) {
        uint _userDebt = stakeInfo[ _address ].debtTakenOn;
        uint _amount = fromAgnostic( stakeInfo[ _address ].agnosticStake );
        
        return _amount.sub( _userDebt );
    }

    function _updateStakeInfo( address _asset, uint _amountSOHM, uint _amount, bool _staking ) internal returns ( bool ) {
        StakeInfo storage info = stakeInfo[ msg.sender ];

        uint _agnostic = toAgnostic( _amountSOHM );

        if( _staking ) {
            info.amountOfAsset[ _asset ] = info.amountOfAsset[ _asset ].add( _amount );
            info.agnosticStake = info.agnosticStake.add( _agnostic );
            info.debtTakenOn = info.debtTakenOn.add( _amountSOHM );
        } else {
            if( _asset == address(0) ) {
                info.agnosticStake = info.agnosticStake.sub( _agnostic );           
            } else {
                info.amountOfAsset[ _asset ] = info.amountOfAsset[ _asset ].sub( _amount );
                info.agnosticStake = info.agnosticStake.sub( _agnostic );
                info.debtTakenOn = info.debtTakenOn.sub( _amountSOHM );
            }
        }

        return true;
    }


}