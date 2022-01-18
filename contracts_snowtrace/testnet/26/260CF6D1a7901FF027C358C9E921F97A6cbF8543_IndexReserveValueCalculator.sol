/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-18
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

contract IndexReserveValueCalculator is Ownable {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint private controlVariable; // Control variable
    mapping( address => ReserveDetails ) public reserveDetails; // Push only

    struct ReserveDetails {
        address lp;
        address stable;
        address principle;
        uint controlVariable;
        bool isStable;
    }

    constructor () {}

    /**
        @notice update or add a reserve token's details
        @param _reserve address
        @param _lp address
        @param _stable address
        @param _principle address
     */
    function updateReserveTokenDetails(
        address _reserve, // The reserve token
        address _lp, // Liquidity pool address
        address _stable, // Stable coin in this liquidity pool
        address _principle, // The principle token in this liquidity pool (principle may be different than the reserve token if the reserve token is a staked DAO token)
        uint _controlVariable, // In tenths (25 == 2.5)
        bool _isStable
    ) external onlyManager() {
       if (_isStable == false){
        require( _reserve != address(0) );
        require( _lp != address(0) );
        require( _stable != address(0) );
        require( _principle != address(0) );
        require( _controlVariable >= 10 );
      }

        ReserveDetails memory newReserveDetails = ReserveDetails({
          lp: _lp,
          stable: _stable,
          principle: _principle,
          controlVariable: _controlVariable,
          isStable: _isStable
        });

        reserveDetails[ _reserve ] = newReserveDetails;
    }

    /**
        @notice update the control variable for a reserve token
        @param _reserve address
        @param _controlVariable uint
     */
    function updateControlVariable(
        address _reserve,
        uint _controlVariable
    ) external onlyManager() {
        require(_controlVariable >= 10, "Control variable must be equal or greater than 10!") ;

        reserveDetails[ _reserve ].controlVariable = _controlVariable;
    }

    /**
        @notice gets the market value of a reserve token
        @param _reserve address
     */
    function valueOfReserveToken( address _reserve ) public view returns ( uint _value ) {
       if (reserveDetails[ _reserve ].isStable == true){
          _value = 100;
       }else{
         uint256 pairStableBalance = (IERC20( reserveDetails[ _reserve ].stable ).balanceOf( reserveDetails[ _reserve ].lp ).mul(reserveDetails[ _reserve ].controlVariable) * 10) / ( 10 ** IERC20( reserveDetails[ _reserve ].stable ).decimals() );
         uint256 pairPrincipleBalance = (IERC20( reserveDetails[ _reserve ].principle ).balanceOf( reserveDetails[ _reserve ].lp ).mul(reserveDetails[ _reserve ].controlVariable) * 10) / ( 10 ** IERC20( reserveDetails[ _reserve ].principle ).decimals() );
         _value = (pairStableBalance / pairPrincipleBalance); 
       }
    }
}