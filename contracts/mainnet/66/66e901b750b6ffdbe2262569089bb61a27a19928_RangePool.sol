/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

// NOTICE: Contract begins line 345

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
        return _functionCallWithValue(target, data, value, errorMessage);
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
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
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

/**
 * Range Pool is a RangeSwap ERC20 token that facilitates trades between stablecoins. We execute "optimistic swaps" --
 * essentially, the pool assumes all tokens to be worth the same amount at all times, and executes as such.
 * The caveat is that tokens must remain within a range, determined by Allocation Points (AP). For example,
 * token A with (lowAP = 1e8) and (highAP = 5e8) must make up 10%-50% of the pool at all times.
 * RangeSwap allows for cheaper execution and higher capital efficiency than existing, priced swap protocols.
 */
contract RangePool is ERC20, Ownable {

    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;
    using Address for address;


    /* ========== EVENTS ========== */

    event Swap( address, uint, address );
    event Add( address, uint );
    event Remove( address, uint );

    event TokenAdded( address, uint, uint );
    event BoundsChanged( address, uint, uint );
    event Accepting( address, bool );
    event FeeChanged( uint );


    /* ========== STRUCTS ========== */

    struct PoolToken {
        uint lowAP; // 9 decimals
        uint highAP; // 9 decimals
        bool accepting; // can send in (swap or add)
        bool pushed; // pushed to tokens list
    }


    /* ========== STATE VARIABLES ========== */

    mapping( address => PoolToken ) public tokenInfo;
    address[] public tokens;
    uint public totalTokens;

    uint public fee; // 9 decimals
    
    constructor() ERC20( 'Range Pool Token', 'RPT' ) {
        _mint( msg.sender, 1e18 );
        totalTokens = 1e18;
    }

    /* ========== SWAP ========== */

    // swap amount from firstToken to secondToken
    function swap( address firstToken, uint amount, address secondToken ) external {
        require( amount <= maxCanSwap( firstToken, secondToken ), "Exceeds limit" );

        emit Swap( firstToken, amount, secondToken );

        uint feeToTake = amount.mul(fee).div(1e9);
        totalTokens = totalTokens.add( feeToTake );

        IERC20( firstToken ).safeTransferFrom( msg.sender, address(this), amount ); 
        IERC20( secondToken ).safeTransfer( msg.sender, amount.sub( feeToTake ) ); // take fee on amount
    }

    /* ========== ADD LIQUIDITY ========== */

    // add token to pool as liquidity. returns number of pool tokens minted.
    function add( address token, uint amount ) external returns ( uint amount_ ) {
        amount_ = value( amount ); // do this before changing totalTokens or totalSupply

        totalTokens = totalTokens.add( amount ); // add amount to total first

        require( amount <= maxCanAdd( token ), "Exceeds limit" );

        IERC20( token ).safeTransferFrom( msg.sender, address(this), amount );
        emit Add( token, amount );

        _mint( msg.sender, amount_ );
    }

    // add liquidity evenly across all tokens. returns number of pool tokens minted.
    function addAll( uint amount ) external returns ( uint amount_ ) {
        uint sum;
        for ( uint i = 0; i < tokens.length; i++ ) {
            IERC20 token = IERC20( tokens[i] );
            uint send = amount.mul( token.balanceOf( address(this) ) ).div( totalTokens );
            if (send > 0) {
                token.safeTransferFrom( msg.sender, address(this), send );
                emit Add( tokens[i], send );
                sum = sum.add(send);
            }
        }
        amount_ = value( sum );

        totalTokens = totalTokens.add( sum ); // add amount second (to not skew pool)
        _mint( msg.sender, amount_ );
    }

    /* ========== REMOVE LIQUIDITY ========== */

    // remove token from liquidity, burning pool token
    // pass in amount token to remove, returns amount_ pool tokens burned
    function remove( address token, uint amount ) external returns (uint amount_) {
        amount_ = value( amount ); // token balance => pool token balance
        amount = amount.sub( amount.mul( fee ).div( 1e9 ) ); // take fee

        require( amount <= maxCanRemove( token ), "Exceeds limit" );
        emit Remove( token, amount );

        _burn( msg.sender, amount_ ); // burn pool token
        totalTokens = totalTokens.sub( amount ); // remove amount from pool less fees

        IERC20( token ).safeTransfer( msg.sender, amount ); // send token removed
    }

    // remove liquidity evenly across all tokens 
    // pass in amount tokens to remove, returns amount_ pool tokens burned
    function removeAll( uint amount ) public returns (uint amount_) {
        uint sum;
        for ( uint i = 0; i < tokens.length; i++ ) {
            IERC20 token = IERC20( tokens[i] );
            uint send = amount.mul( token.balanceOf( address(this) ) ).div( totalTokens );

            if ( send > 0 ) {
                uint minusFee = send.sub( send.mul( fee ).div( 1e9 ) );
                token.safeTransfer( msg.sender, minusFee );
                emit Remove( tokens[i], minusFee ); // take fee
                sum = sum.add(send);
            }
        }

        amount_ = value( sum );
        _burn( msg.sender, amount_ );
        totalTokens = totalTokens.sub( sum.sub( sum.mul( fee ).div( 1e9 ) ) ); // remove amount from pool less fees
    }

    /* ========== VIEW FUNCTIONS ========== */

    // number of tokens 1 pool token can be redeemed for
    function redemptionValue() public view returns (uint value_) {
        value_ = totalTokens.mul(1e18).div( totalSupply() );
    } 

    // token value => pool token value
    function value( uint amount ) public view returns ( uint ) {
        return amount.mul( 1e18 ).div( redemptionValue() );
    }

    // maximum number of token that can be added to pool
    function maxCanAdd( address token ) public view returns ( uint ) {
        require( tokenInfo[token].accepting, "Not accepting token" );
        uint maximum = totalTokens.mul( tokenInfo[ token ].highAP ).div( 1e9 );
        uint balance = IERC20( token ).balanceOf( address(this) );
        return maximum.sub( balance );
    }

    // maximum number of token that can be removed from pool
    function maxCanRemove( address token ) public view returns ( uint ) {
        uint minimum = totalTokens.mul( tokenInfo[ token ].lowAP ).div( 1e9 );
        uint balance = IERC20( token ).balanceOf( address(this) );
        return balance.sub( minimum );
    }

    // maximum size of trade from first token to second token
    function maxCanSwap( address firstToken, address secondToken ) public view returns ( uint ) {
        uint canAdd = maxCanAdd( firstToken);
        uint canRemove = maxCanRemove( secondToken );

        if ( canAdd > canRemove ) {
            return canRemove;
        } else {
            return canAdd;
        }
    }

    // amount of secondToken returned by swap
    function amountOut( address firstToken, uint amount, address secondToken ) external view returns ( uint ) {
        if ( amount <= maxCanSwap( firstToken, secondToken ) ) {
            return amount.sub( amount.mul( fee ).div( 1e9 ) );
        } else {
            return 0;
        }
    }

    /* ========== SETTINGS ========== */

    // set fee taken on trades
    function setFee( uint newFee ) external onlyOwner() {
        fee = newFee;
        emit FeeChanged( fee );
    }

    // add new token to pool. allocation points are 9 decimals.
    // must call toggleAccept to activate token
    function addToken( address token, uint lowAP, uint highAP ) external onlyOwner() {
        require( !tokenInfo[ token ].pushed );

        tokenInfo[ token ] = PoolToken({
            lowAP: lowAP,
            highAP: highAP,
            accepting: false,
            pushed: true
        });

        tokens.push( token );
        emit TokenAdded( token, lowAP, highAP );
    }

    // change bounds of tokens in pool
    function changeBound( address token, uint newLow, uint newHigh ) external onlyOwner() {
        tokenInfo[ token ].highAP = newHigh;
        tokenInfo[ token ].lowAP = newLow;

        emit BoundsChanged( token, newLow, newHigh );
    }

    // toggle whether to accept incoming token
    // setting token to false will not allow swaps as incoming token or adds
    function toggleAccept( address token ) external onlyOwner() {
        tokenInfo[ token ].accepting = !tokenInfo[ token ].accepting;
        emit Accepting( token, tokenInfo[ token ].accepting );
    }
}