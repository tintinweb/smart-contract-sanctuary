/**
 *Submitted for verification at Etherscan.io on 2021-09-24
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

interface ITreasury {
    function deposit( address token, uint amount, uint profit ) external returns ( uint );
    function valueOf( address token, uint amount ) external view returns ( uint );
}

interface IMintableERC20 is IERC20 {
    function mint( address to, uint amount ) external;
    function burn( address from, uint amount ) external;
}

contract StablePool {

    using SafeMath for *;
    using SafeERC20 for IERC20;



    /* ========== STRUCTS ========== */

    struct PoolToken {
        uint lowAP; // 9 decimals
        uint highAP; // 9 decimals
        bool accepting; // can send in (swap or add)
    }



    /* ========== STATE VARIABLES ========== */

    IMintableERC20 public shareToken; // represents 1 token in the pool

    address[] public poolTokens; // tokens in pool
    mapping( address => PoolToken ) public tokenInfo; // info for tokens in pool

    uint public totalTokens; // total tokens in pool
    uint public totalAP; // sum of high weights

    uint public swapFee; // taken on every trade
    uint public feesCollected; // share tokens not minted yet. payable to treasury.
    
    //ITreasury immutable treasury;


    
    /* ========== CONSTRUCTOR ========== */
    
    constructor( address _shareToken ) {
        require( _shareToken != address(0) );
        shareToken = IMintableERC20( _shareToken );
        
        //require( _treasury != address(0) );
        //treasury = ITreasury( _treasury );
    }



    /* ========== EXCHANGE FUNCTIONS ========== */

    /**
     *  @notice swap stables 1:1 while pool balance is within range
     *  @param _firstToken address
     *  @param _amount uint
     *  @param _secondToken address
     */
    function swap( address _firstToken, uint _amount, address _secondToken ) external {
        canExecute( _firstToken, _amount, _secondToken ); // ensure pool remains balanced
        
        IERC20( _firstToken ).safeTransferFrom( msg.sender, address(this), _amount );

        uint fee = _amount.mul( swapFee ).div( 1e4 );
        feesCollected = feesCollected.add( fee );

        IERC20( _secondToken ).safeTransfer( msg.sender, _amount.sub( fee ) );
    }

    /**
     *  @notice add single sided liquidity to pool unless token range upper bound will be exceeded
     *  @param _token address
     *  @param _amount uint
     */
    function add( address _token, uint _amount ) external {
        totalTokens = totalTokens.add( _amount );

        canAdd( _token, _amount ); // ensure pool remains balanced

        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount ); // send token added

        shareToken.mint( msg.sender, _amount ); // mint pool token
    }

    /**
     *  @notice remove single sided liquidity from pool unless token range lower bound will be exceeded
     *  @param _token address
     *  @param _amount uint
     */
    function remove( address _token, uint _amount ) external {
        totalTokens = totalTokens.sub( _amount );

        canRemove( _token, _amount ); // ensure pool remains balanced

        shareToken.burn( msg.sender, _amount ); // burn pool token

        IERC20( _token ).safeTransfer( msg.sender, _amount ); // send token removed
    }

    /**
     *  @notice deposit fees collected into treasury
     */
    function collectFees() external {
        require( feesCollected > 0, "No fees" ); // ensure fees to collect

        shareToken.mint( msg.sender, feesCollected ); // mint pool token

        /* approve and deposit pool token to treasury
        shareToken.approve( address(treasury), feesCollected );
        treasury.deposit( 
            address( shareToken ), 
            feesCollected, 
            treasury.valueOf( address( shareToken ), feesCollected )
        );*/

        feesCollected = 0; // reset collection counter
    }



    /* ========== VIEW FUNCTIONS ========== */

    /**
     *  @notice ensure pool remains in range after swap
     *  @param _firstToken address
     *  @param _amount uint
     *  @param _secondToken address
     *  @return bool
     */
    function canExecute( address _firstToken, uint _amount, address _secondToken ) public view returns ( bool ) {
        require( tokenInfo[ _firstToken ].accepting, "Not accepting token" ); 
        
        require( check( true, _firstToken, _amount ), "First token exits bounds" );

        require( check( false, _secondToken, _amount ), "Second token exits bounds" );
        
        return true;
    }

    /**
     *  @notice ensure pool remains in range after add
     *  @param _token address
     *  @param _amount uint
     *  @return bool
     */
    function canAdd( address _token, uint _amount ) public view returns ( bool ) {
        require( tokenInfo[ _token ].accepting, "Not accepting token" );

        require( check( true, _token, _amount ), "Added token exits bounds" );
        
        return true;
    }

    /**
     *  @notice ensure pool remains in range after remove
     *  @param _token address
     *  @param _amount uint
     *  @return bool
     */
    function canRemove( address _token, uint _amount ) public view returns ( bool ) {
        require( check( false, _token, _amount ), "Removed token exits bounds" );
        
        return true;
    }

    /**
     *  @notice check if remains in range
     *  @param _add bool
     *  @param _token address
     *  @param _amount uint
     *  @return bool
     */
    function check( bool _add, address _token, uint _amount ) public view returns ( bool ) {

        if( _add ) { // use upper bound

            uint maximum = totalTokens.mul( tokenInfo[ _token ].highAP ).div( totalAP ); // maximum balance of token
            uint balance = IERC20( _token ).balanceOf( address(this) ); // current balance of token

            return ( balance.add( _amount ) <= maximum ); // check if remains in bounds
        } else { // use lower bound

            uint minimum = totalTokens.mul( tokenInfo[ _token ].lowAP ).div( totalAP ); // minimum balance of token
            uint balance = IERC20( _token ).balanceOf( address(this) ); // current balance of token

            return ( balance.sub( _amount ) >= minimum ); // check if remains in bounds
        }
    }



     /* ========== POLICY FUNCTIONS ========== */

    /**
     *  @notice change bounds of tokens in pool
     *  @param _token address
     *  @param _newHigh uint
     *  @param _newLow uint
     */
     function changeBound( address _token, uint _newHigh, uint _newLow ) external {
        totalAP = totalAP.add( _newHigh ).sub( tokenInfo[ _token ].highAP );
        tokenInfo[ _token ].highAP = _newHigh;
        tokenInfo[ _token ].lowAP = _newLow;
     }

    /**
     *  @notice add new token to pool
     *  @notice must call toggleAccept to activate token
     *  @param _token address
     *  @param _lowAP uint
     *  @param _highAP uint
     */
     function addToken( address _token, uint _lowAP, uint _highAP ) external {

         tokenInfo[ _token ] = PoolToken({
             lowAP: _lowAP,
             highAP: _highAP,
             accepting: false
         });

         totalAP = totalAP.add( _highAP );

         poolTokens.push( _token );
     }
     
     /**
      *  @notice set fee taken on trades
      *  @param _newFee uint
      */
     function setFee( uint _newFee ) external {
         swapFee = _newFee;
     }

    /**
     *  @notice toggle whether to accept incoming token
     *  @notice setting token to false will not allow swaps as incoming token or adds
     *  @param _token address
     */
     function toggleAccept( address _token ) external {
         tokenInfo[ _token ].accepting = !tokenInfo[ _token ].accepting;
     }
}