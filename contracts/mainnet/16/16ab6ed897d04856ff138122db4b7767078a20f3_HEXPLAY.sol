//HEXPLAY.sol
//
//

pragma solidity 0.6.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./HEX.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Token {
    function symbol()
    external
    view
    returns (string memory);
    
    function totalSupply()
    external
    view
    returns (uint256);
    
    function balanceOf (address account)
    external
    view
    returns (uint256);

    function transfer (address recipient, uint256 amount)
    external
    returns (bool);
}

////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////

contract TokenEvents {

    //when founder tokens are locked
    event FounderLock (
        uint hxbAmt,
        uint timestamp
    );

    //when founder tokens are unlocked
    event FounderUnlock (
        uint hxbAmt,
        uint timestamp
    );
}

//////////////////////////////////////
//////////HEXPLAY TOKEN CONTRACT////////
////////////////////////////////////
contract HEXPLAY is IERC20, TokenEvents {

    using SafeMath for uint256;
    using SafeERC20 for HEXPLAY;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    //hex contract setup
    address internal hexAddress = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    HEX internal hexInterface = HEX(hexAddress);
    
    //founder lock
    uint public unlockLvl = 0;
    uint public founderLockStartTimestamp = 0;
    uint public founderLockDayLength = 1825;//5 years (10% released every sixmonths)
    uint public founderLockedTokens = 0;
    uint private allFounderLocked = 0;

    //tokenomics
    uint256 internal constant _maxSupply = 600000000000000;
    uint256 internal _totalSupply;
    string public constant name = "hexplay";
    string public constant symbol = "HXP";
    uint public constant decimals = 8;
    address payable internal _p1 = 0x6c28dc6529ba78fA3a0FEf408F2c982b074E41A5;
    address payable internal _p2 = 0xcC5dAbe96779EBe121DA246a6cD45FA8fa4Af208;
    address payable internal _p3 = 0xc70DAfC298B5de4DA424EB80DC2743173f944A9f;
    address payable internal _p4 = _p1;
   
    bool private sync;
    
    //protects against potential reentrancy
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    constructor() public {
        //mint tokens
        require(mintFounderTokens(_maxSupply.mul(20).div(100)), "failed to mint");//20% of max supply
        _mint(_p1, _maxSupply.mul(80).div(100));//mint liquid HXP
    }

    //fallback for eth sent to contract - auto distribute as donation
    receive() external payable{
        donate();
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply unless mintBLock is true
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        uint256 amt = amount;
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amt);
        require(_totalSupply <= _maxSupply, "max supply breached");
        _balances[account] = _balances[account].add(amt);
        emit Transfer(address(0), account, amt);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);//from address(0) for minting

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //mint HXP to founders (only ever called in constructor)
    function mintFounderTokens(uint tokens)
        internal
        synchronized
        returns(bool)
    {
        uint256 _liquid = tokens.div(2);
        _mint(_p1, _liquid.div(4));//mint founder HXP
        _mint(_p2, _liquid.div(4));//mint founder HXP
        _mint(_p3, _liquid.div(4));//mint founder HXP
        _mint(_p4, _liquid.div(4));//mint founder HXP
        _mint(address(this), tokens.div(2));//mint HXP to be locked for 5 years, 10% unlocked every sixmonths
        founderLockStartTimestamp = now;
        founderLockedTokens = tokens.div(2);
        allFounderLocked = tokens.div(2);
        emit FounderLock(tokens.div(2), founderLockStartTimestamp);
        return true;
    }

    function unlock()
        public
        synchronized
    {
        uint sixMonths = founderLockDayLength/10;
        uint daySeconds = 86400;
        require(unlockLvl < 10, "token unlock complete");
        require(founderLockStartTimestamp.add(sixMonths.mul(daySeconds)) <= now, "tokens cannot be unlocked yet");//must be at least over 6 months
        uint value = allFounderLocked.div(10);
        uint share =  value.mul(25).div(100);//25%
        if(founderLockStartTimestamp.add((sixMonths).mul(daySeconds)) <= now && unlockLvl == 0){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else if(founderLockStartTimestamp.add((sixMonths.mul(2)).mul(daySeconds)) <= now && unlockLvl == 1){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else if(founderLockStartTimestamp.add((sixMonths.mul(3)).mul(daySeconds)) <= now && unlockLvl == 2){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else if(founderLockStartTimestamp.add((sixMonths.mul(4)).mul(daySeconds)) <= now && unlockLvl == 3){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else if(founderLockStartTimestamp.add((sixMonths.mul(5)).mul(daySeconds)) <= now && unlockLvl == 4){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else if(founderLockStartTimestamp.add((sixMonths.mul(6)).mul(daySeconds)) <= now && unlockLvl == 5){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else if(founderLockStartTimestamp.add((sixMonths.mul(7)).mul(daySeconds)) <= now && unlockLvl == 6){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else if(founderLockStartTimestamp.add((sixMonths.mul(8)).mul(daySeconds)) <= now && unlockLvl == 7)
        {
            unlockLvl++;     
            founderLockedTokens = founderLockedTokens.sub(value);      
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else if(founderLockStartTimestamp.add((sixMonths.mul(9)).mul(daySeconds)) <= now && unlockLvl == 8){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else if(founderLockStartTimestamp.add((sixMonths.mul(10)).mul(daySeconds)) <= now && unlockLvl == 9){
            unlockLvl++;
            if(founderLockedTokens >= value){
                founderLockedTokens = founderLockedTokens.sub(value);
            }
            else{
                value = founderLockedTokens;
                founderLockedTokens = 0;
            }
            transfer(_p1, share);
            transfer(_p2, share);
            transfer(_p3, share);
            transfer(_p4, share);
        }
        else{
            revert();
        }
        emit FounderUnlock(value, now);
    }

    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////
    function donate() public payable {
        require(msg.value > 0);
        bool success = false;
        uint256 balance = msg.value;
        //distribute
        uint256 share = balance.mul(25).div(100);//25%
        (success, ) =  _p1.call{value:share}{gas:21000}('');
        require(success, "Transfer failed");
        (success, ) =  _p2.call{value:share}{gas:21000}('');
        require(success, "Transfer failed");
        (success, ) =  _p3.call{value:share}{gas:21000}('');
        require(success, "Transfer failed");
        (success, ) =  _p4.call{value:share}{gas:21000}('');
        require(success, "Transfer failed");
    }
    
    //distribute any token in contract via address
    function distributeToken(address tokenAddress) public {
        require(tokenAddress != address(this), "invalid token");
        require(tokenAddress != address(0), "address cannot be 0x");
        Token _token = Token(tokenAddress);
        //get balance 
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 99, "value too low to distribute");
        //distribute
        uint256 share = balance.mul(25).div(100);//25%
        require(_token.transfer(_p1, share));
        require(_token.transfer(_p2, share));
        require(_token.transfer(_p3, share));
        require(_token.transfer(_p4, share));
    }

}
