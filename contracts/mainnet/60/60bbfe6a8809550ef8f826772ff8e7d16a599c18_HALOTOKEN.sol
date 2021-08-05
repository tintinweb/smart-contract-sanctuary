pragma solidity 0.6.4;

import "./SafeMath.sol";
import "./IERC20.sol";
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

////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////

contract TokenEvents {

    //when a user unlocks tokens
    event TokenUnlock(
        address indexed user,
        uint value
    );

    event Transform (
        uint ethAmt,
        uint hloAmt,
        address indexed transformer
    );
    
}

//////////////////////////////////////
//////////HALOTOKEN TOKEN CONTRACT////////
////////////////////////////////////
contract HALOTOKEN is IERC20, TokenEvents {

    using SafeMath for uint256;
    using SafeERC20 for HALOTOKEN;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    //transform setup
    bool public roundActive;
    uint public totalEthTransformed = 0;
    uint public totalDividends = 0;
    uint public totalBuyback = 0;
    
    bool public mintBlock;//disables any more tokens ever being minted once _totalSupply reaches _maxSupply
    uint public totalLocked = 0;
    mapping (address => uint) public tokenLockedBalances;
    mapping (address => uint) public totalEthOwed;
    mapping (address => uint) public reffered;
    mapping (address => bool) public isInfluencer;
    
    //tokenomics
    uint256 public _maxSupply = 100000000;// max supply @ 20k
    uint256 internal _totalSupply;
    string public constant name = "HaloToken";
    string public constant symbol = "HLO";
    uint public constant decimals = 8;
    //admin
    address payable internal _divsWallet = 0xb07631ab3c202457B8e09Fe79a86CDD0dE04E444;
    address payable internal _buybackWallet = 0xdA50B0F10395EBB58ea6c6D5bA7E12298eCD2A37;
    address payable internal _p1 = 0x8EDEc6C74bC83A3F588ee5237002441b5Ba6fE8f;
    address payable internal _p2 = 0xFE6E2dF13d9a4D95e7772E4C8173C45D58075922;

    
    bool private sync;

    mapping(address => bool) admins;

    modifier onlyAdmins(){
        require(admins[msg.sender], "not an admin");
        _;
    }
    
    //protects against potential reentrancy
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    constructor() public {
        admins[_p1] = true;
        admins[_p2] = true;
        admins[msg.sender] = true;
        //mint initial tokens
        mintInitialTokens();
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
    function _mint(address account, uint256 amount, address user) internal {
        uint256 amt = amount;
        require(account != address(0), "ERC20: mint to the zero address");
        if(!mintBlock){
            if(_totalSupply <= _maxSupply){
                if(_totalSupply.add(amt) >= _maxSupply){
                    amt = _maxSupply.sub(_totalSupply);
                    _totalSupply = _maxSupply;
                    mintBlock = true;
                }
                else{
                    _totalSupply = _totalSupply.add(amt);
                }
                tokenLockedBalances[user] = tokenLockedBalances[user].add(amt);
                totalLocked = totalLocked.add(amt);
                _balances[account] = _balances[account].add(amt);
                emit Transfer(address(0), account, amt);
            }
        }
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

    function mintInitialTokens()
        internal
        synchronized
    {
        LockTokens(_maxSupply.mul(8).div(100), _p1, true);
        LockTokens(_maxSupply.mul(2).div(100), _p2, true);
    }

    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - HALO CONTROL//////////
    //////////////////////////////////////////////////////
    
    function UnlockTokens()
        public
        synchronized
    {
        require(tokenLockedBalances[msg.sender] > 0,"Error: unsufficient locked balance");//ensure user has enough locked funds
        uint amt;
        if(isLockFinished()){
            amt = tokenLockedBalances[msg.sender];
            tokenLockedBalances[msg.sender] = 0;
            totalLocked = totalLocked.sub(amt);
            if(totalEthOwed[msg.sender] > 0){
                _divsWallet.transfer(totalEthOwed[msg.sender]);
                totalEthOwed[msg.sender] = 0;
            }
            _transfer(address(this), msg.sender, amt);//make HLO transfer
            emit TokenUnlock(msg.sender, amt);
        }
        else{
            require(msg.sender != _p1 && msg.sender != _p2, "founder mint cannot unlock early");
            amt = tokenLockedBalances[msg.sender];
            tokenLockedBalances[msg.sender] = 0;
            totalLocked = totalLocked.sub(amt);
            // make ETH transfer back to user
            msg.sender.transfer(totalEthOwed[msg.sender]);
            totalEthOwed[msg.sender] = 0;
            //user loses HLO for exiting early, reallocate to founders
            LockTokens(amt.mul(80).div(100), _p1, false);
            LockTokens(amt.mul(20).div(100), _p2, false);
        }
    }
 
    receive()
    external
    payable
    {
        EthTransform(address(0));
    }
    
    //transforms ETH to HALO , 10% fee
    function EthTransform(address _ref)//Approval needed
        public
        payable
        synchronized
    {
        require(roundActive, "transforms not active");
        require(msg.value >= 0.01 ether && msg.value <= 4000 ether, "invalid value");
        require(!mintBlock, "minting ceased");
        //allocate funds
        uint divs = msg.value.mul(20).div(100);
        uint split = divs.div(2);
        totalDividends += split;
        uint buyback = split.mul(80).div(100);
        totalBuyback += buyback;
        uint _e = split.mul(10).div(100);
        _p1.transfer(_e);
        _p2.transfer(_e);
        _divsWallet.transfer(split);
        _buybackWallet.transfer(buyback);
        totalEthTransformed += msg.value;
        totalEthOwed[msg.sender] += msg.value.sub(divs);
        //calc HLO share
        uint share = (msg.value / 2) / 10 ** 8;
        uint hlo = share.div(10);
        //mint and lock
        LockTokens(hlo, msg.sender, true);
        if(_ref != address(0) && !mintBlock){
            if(isInfluencer[_ref]){
                uint bonus = hlo.mul(10).div(100);
                LockTokens(bonus, _ref, true);
                reffered[msg.sender] += bonus;
            }
            else{
                uint bonus = hlo.mul(5).div(100);
                LockTokens(bonus, _ref, true);
                reffered[msg.sender] += bonus;
            }
        }
        emit Transform(msg.value, hlo, msg.sender);
    }
    
    //lock HALO tokens to contract
    function LockTokens(uint amt, address user, bool mint)
        internal
    {
        require(amt > 0, "zero input");

        if(mint){
            //mint HLO to contract
            _mint(address(this), amt, user);   
        }
        else{
            //update balances
            tokenLockedBalances[user] = tokenLockedBalances[user].add(amt);
            totalLocked = totalLocked.add(amt);
        }
    }
    
    ///////////////////////////////
    ////////ADMIN ONLY//////////////
    ///////////////////////////////

    //transform room initiation
    function transformActivate(bool _isActive)
        public
        onlyAdmins
    {
        roundActive = _isActive;
    }


    function newInfluencer(address _address, bool _active)
        public
        onlyAdmins
    {
        require(_address != address(0), "invalid address");
        isInfluencer[_address] = _active;
    }

    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    //unlocked on maxsupply
    function isLockFinished()
        public
        view
        returns(bool)
    {
        return mintBlock;
    }

}
