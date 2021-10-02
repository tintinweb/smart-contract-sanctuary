/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

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

    function mint( address to, uint amount ) external;

    function burn( address from, uint amount ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract StablePool {

    using SafeMath for uint;
    using SafeERC20 for IERC20;



    /* ========== STRUCTS ========== */

    struct PoolToken {
        uint lowAP; // 5 decimals
        uint highAP; // 5 decimals
        bool accepting; // can send in (swap or add)
        bool pushed; // pushed to poolTokens
    }

    struct Fee {
        uint fee;
        uint collected;
        address collector;
    }



    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable shareToken; // represents 1 token in the pool

    address[] public poolTokens; // tokens in pool
    mapping( address => PoolToken ) public tokenInfo; // info for tokens in pool

    uint public totalTokens; // total tokens in pool

    Fee public fees;
    
    
    
    /* ========== CONSTRUCTOR ========== */
    
    constructor( address token ) {
        require( token != address(0) );
        shareToken = IERC20( token );
    }



    /* ========== EXCHANGE FUNCTIONS ========== */

    // swap tokens and send outbound token to sender
    function swap( address firstToken, uint amount, address secondToken ) external {
        IERC20( firstToken ).safeTransferFrom( msg.sender, address(this), amount );

        IERC20( secondToken ).safeTransfer( msg.sender, _swap( firstToken, amount, secondToken ) );
    }

    // swap tokens, specifying sender and receiver
    // used by router for chain swaps
    function swapThrough( 
        address from, 
        address to, 
        address firstToken, 
        uint amount, 
        address secondToken
    ) external returns ( uint amount_ ) {
        IERC20( firstToken ).safeTransferFrom( from, address(this), amount );

        amount_ = _swap( firstToken, amount, secondToken );

        IERC20( secondToken ).approve( to, amount_ );
    }

    // add token to pool as liquidity, returning share token
    // rejects if token added will exit bounds
    function add( address token, uint amount ) external {
        totalTokens = totalTokens.add( amount ); // add amount to pool

        require( amount <= maxCanAdd( token ), "Exceeds limit in" );

        IERC20( token ).safeTransferFrom( msg.sender, address(this), amount ); // send token added

        shareToken.mint( msg.sender, amount ); // mint pool token
    }

    // remove token from liquidity, burning share token
    // rejects if token removed will exit bounds
    function remove( address token, uint amount ) external {
        shareToken.burn( msg.sender, amount ); // burn pool token

        uint fee = amount.mul( fees.fee ).div( 1e4 ); // trading fee collected

        require( amount.sub( fee ) <= maxCanRemove( token ), "Exceeds limit out" );

        fees.collected = fees.collected.add( fee ); // add to total fees
        totalTokens = totalTokens.sub( amount.sub( fee ) ); // remove amount from pool less fees

        IERC20( token ).safeTransfer( msg.sender, amount.sub( fee ) ); // send token removed
    }

    // remove liquidity evenly across all tokens 
    function removeAll( uint amount ) external {
        shareToken.burn( msg.sender, amount );

        uint fee = amount.mul( fees.fee ).div( 1e4 ); // trading fee collected
        fees.collected = fees.collected.add( fee ); // add to total fees

        amount = amount.sub( fee );

        for ( uint i = 0; i < poolTokens.length; i++ ) {
            IERC20 token = IERC20( poolTokens[ i ] );

            uint send = amount.mul( token.balanceOf( address(this) ) ).div( totalTokens );
            token.safeTransfer( msg.sender, send );
        }
        totalTokens = totalTokens.sub( amount ); // remove amount from pool less fees
    }

    // send collected fees to collector
    function collectFees( address token ) public {
        if ( fees.collected > 0 ) {
            totalTokens = totalTokens.sub( fees.collected );

            IERC20( token ).safeTransfer( fees.collector, fees.collected );

            fees.collected = 0;
        }
    }



    /* ========== INTERNAL FUNCTIONS ========== */

    // token swap logic
    function _swap( address firstToken, uint amount, address secondToken ) internal returns ( uint ) {
        require( amount <= maxCanAdd( firstToken ), "Exceeds limit in" );
        require( amount <= maxCanRemove( secondToken ), "Exceeds limit out" );

        uint fee = amount.mul( fees.fee ).div( 1e9 );

        fees.collected = fees.collected.add( fee );
        return amount.sub( fee );
    }



    /* ========== VIEW FUNCTIONS ========== */

    // maximum number of token that can be added to pool
    function maxCanAdd( address token ) public view returns ( uint ) {
        uint maximum = totalTokens.mul( tokenInfo[ token ].highAP ).div( 1e5 );
        uint balance = IERC20( token ).balanceOf( address(this) );
        return maximum.sub( balance );
    }

    // maximum number of token that can be removed from pool
    function maxCanRemove( address token ) public view returns ( uint ) {
        uint minimum = totalTokens.mul( tokenInfo[ token ].lowAP ).div( 1e5 );
        uint balance = IERC20( token ).balanceOf( address(this) );
        return balance.sub( minimum );
    }

    // maximum size of trade from first token to second token
    function maxSize( address firstToken, address secondToken ) public view returns ( uint ) {
        return maxCanAdd( firstToken ).add( maxCanRemove( secondToken ) );
    }



     /* ========== POLICY FUNCTIONS ========== */

    // change bounds of tokens in pool
    function changeBound( address token, uint newHigh, uint newLow ) external {
        tokenInfo[ token ].highAP = newHigh;
        tokenInfo[ token ].lowAP = newLow;
    }

    // add new token to pool
    // must call toggleAccept to activate token
    function addToken( address token, uint lowAP, uint highAP ) external {
        if ( !tokenInfo[ token ].pushed ) {
            poolTokens.push( token );
        }

        tokenInfo[ token ] = PoolToken({
            lowAP: lowAP,
            highAP: highAP,
            accepting: false,
            pushed: true
        });
    }

    // toggle whether to accept incoming token
    // setting token to false will not allow swaps as incoming token or adds
    function toggleAccept( address token ) external {
        tokenInfo[ token ].accepting = !tokenInfo[ token ].accepting;
    }
     
    // set fee taken on trades and fee collector
    function setFee( uint newFee, address collector, address collectToken ) external {
        require( collector != address(0) );

        collectFees( collectToken ); // clear cache before changes

        fees.fee = newFee;
        fees.collector = collector;
    }
}