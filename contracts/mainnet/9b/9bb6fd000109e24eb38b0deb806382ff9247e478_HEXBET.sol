//HEXBET.sol
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

//Uniswap factory interface
interface UniswapFactoryInterface {
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}

//Uniswap Interface
interface UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
}

////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////

contract TokenEvents {

    //when a user locks tokens
    event TokenLock(
        address indexed user,
        uint value
    );

    //when a user unlocks tokens
    event TokenUnlock(
        address indexed user,
        uint value
    );

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
//////////HEXBET TOKEN CONTRACT////////
////////////////////////////////////
contract HEXBET is IERC20, TokenEvents {

    using SafeMath for uint256;
    using SafeERC20 for HEXBET;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    //uniswap setup (used in setup only)
    address internal uniFactory = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;
    address internal uniETHHEX = 0x05cDe89cCfa0adA8C88D5A23caaa79Ef129E7883;
    address public uniETHHXB = address(0);
    UniswapExchangeInterface internal uniHEXInterface = UniswapExchangeInterface(uniETHHEX);
    UniswapExchangeInterface internal uniHXBInterface;
    UniswapFactoryInterface internal uniFactoryInterface = UniswapFactoryInterface(uniFactory);
    //hex contract setup
    address internal hexAddress = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    HEX internal hexInterface = HEX(hexAddress);
    //mint / lock
    uint public unlockLvl = 0;
    uint public founderLockStartTimestamp = 0;
    uint public founderLockDayLength = 3650;//10 years (10% released every year)
    uint public founderLockedTokens = 0;
    uint private allFounderLocked = 0;

    bool public mintBlock;//disables any more tokens ever being minted once _totalSupply reaches _maxSupply
    uint public mintRatio = 1000; //inital @ 1000, raises 
    uint public minLockDayLength = 7; // min days to lock
    uint internal daySeconds = 86400; // seconds in a day
    uint public totalLocked = 0;
    mapping (address => uint) public tokenLockedBalances;//balance of HXB locked mapped by user

    //tokenomics
    uint256 public _maxSupply = 50000000000000000000;// max supply @ 500B
    uint256 internal _totalSupply;
    string public constant name = "hex.bet";
    string public constant symbol = "HXB";
    uint public constant decimals = 8;

    //multisig
    address payable internal MULTISIG = 0x35C7a87EbC3E9fBfd2a31579c70f0A2A8D4De4c5;
    //admin
    address payable internal _p1 = 0xD64FF89558Cd0EA20Ae7aA032873d290801865f3;
    address payable internal _p2 = 0xbf1984B12878c6A25f0921535c76C05a60bdEf39;
    bool private sync;
    //minters
    address[] public minterAddresses;// future contracts to enable minting of HXB relative to HEX

    mapping(address => bool) admins;
    mapping(address => bool) minters;
    mapping (address => Locked) public locked;

    struct Locked{
        uint256 lockStartTimestamp;
        uint256 totalEarnedInterest;
    }
    
    modifier onlyMultisig(){
        require(msg.sender == MULTISIG, "not authorized");
        _;
    }

    modifier onlyAdmins(){
        require(admins[msg.sender], "not an admin");
        _;
    }

    modifier onlyMinters(){
        require(minters[msg.sender], "not a minter");
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
        //mint founder tokens
        mintFounderTokens(_maxSupply.mul(20).div(100));//20% of max supply
        //create uni exchange
        uniETHHXB = uniFactoryInterface.createExchange(address(this));
        uniHXBInterface = UniswapExchangeInterface(uniETHHXB);
    }

    //fallback for eth sent to contract - auto distribute as donation
    receive() external payable{
        donate();
    }

    function _initialLiquidity()
        public
        payable
        onlyAdmins
        synchronized
    {
        require(msg.value >= 0.001 ether, "eth value too low");
        //add liquidity
        uint heartsForEth = uniHEXInterface.getEthToTokenInputPrice(msg.value);//price of eth value in hex
        uint hxb = heartsForEth / mintRatio;
        _mint(address(this), hxb);//mint tokens to this contract
        this.safeApprove(uniETHHXB, hxb);//approve uni exchange contract
        uniHXBInterface.addLiquidity{value:msg.value}(0, hxb, (now + 15 minutes)); //send tokens and eth to uni as liquidity*/
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
        if(!mintBlock){
            if(_totalSupply < _maxSupply){
                if(_totalSupply.add(amt) > _maxSupply){
                    amt = _maxSupply.sub(_totalSupply);
                    _totalSupply = _maxSupply;
                    mintBlock = true;
                }
                else{
                    _totalSupply = _totalSupply.add(amt);
                    if(_totalSupply >= _maxSupply.mul(30).div(100)){
                        mintRatio = 2000;
                        if(_totalSupply >= _maxSupply.mul(40).div(100)){
                            mintRatio = 3000;
                            if(_totalSupply >= _maxSupply.mul(50).div(100)){
                                mintRatio = 4000;
                                if(_totalSupply >= _maxSupply.mul(60).div(100)){
                                    mintRatio = 5000;
                                    if(_totalSupply >= _maxSupply.mul(70).div(100)){
                                        mintRatio = 6000;
                                        if(_totalSupply >= _maxSupply.mul(80).div(100)){
                                            mintRatio = 8000;
                                            if(_totalSupply >= _maxSupply.mul(90).div(100)){
                                                mintRatio = 10000;
                                            }
                                        }
                                    }
                                 }
                            }
                        }
                    }
                }
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

    //mint HXB  to founders (only ever called in constructor)
    function mintFounderTokens(uint tokens)
        internal
        synchronized
        returns(bool)
    {
        require(tokens <= _maxSupply.mul(20).div(100), "founder tokens cannot be over 20%");
        _mint(_p1, tokens/4);//mint HXB
        _mint(_p2, tokens/4);//mint HXB
        _mint(address(this), tokens/2);//mint HXB to be locked for 10 years, 10% unlocked every year
        founderLock(tokens/2);
        return true;
    }

    function founderLock(uint tokens)
        internal
    {
        founderLockStartTimestamp = now;
        founderLockedTokens = tokens;
        allFounderLocked = tokens;
        emit FounderLock(tokens, founderLockStartTimestamp);
    }

    function unlock()
        public
        onlyAdmins
        synchronized
    {
        uint sixMonths = founderLockDayLength/10;
        require(unlockLvl < 10, "token unlock complete");
        require(founderLockStartTimestamp.add(sixMonths.mul(daySeconds)) <= now, "tokens cannot be unlocked yet");//must be at least over 6 months
        uint value = allFounderLocked/10;
        if(founderLockStartTimestamp.add((sixMonths).mul(daySeconds)) <= now && unlockLvl == 0){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 2).mul(daySeconds)) <= now && unlockLvl == 1){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 3).mul(daySeconds)) <= now && unlockLvl == 2){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 4).mul(daySeconds)) <= now && unlockLvl == 3){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 5).mul(daySeconds)) <= now && unlockLvl == 4){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 6).mul(daySeconds)) <= now && unlockLvl == 5){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 7).mul(daySeconds)) <= now && unlockLvl == 6){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 8).mul(daySeconds)) <= now && unlockLvl == 7)
        {
            unlockLvl++;     
            founderLockedTokens = founderLockedTokens.sub(value);      
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 9).mul(daySeconds)) <= now && unlockLvl == 8){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 10).mul(daySeconds)) <= now && unlockLvl == 9){
            unlockLvl++;
            if(founderLockedTokens >= value){
                founderLockedTokens = founderLockedTokens.sub(value);
            }
            else{
                value = founderLockedTokens;
                founderLockedTokens = 0;
            }
            transfer(_p1, value.div(2));
            transfer(_p2, value.div(2));
        }
        else{
            revert();
        }
        emit FounderUnlock(value, now);
    }
    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - HXB CONTROL//////////
    //////////////////////////////////////////////////////

    //lock HXB tokens to contract
    function LockTokens(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(tokenBalance() >= amt, "Error: insufficient balance");//ensure user has enough funds
        if(isLockFinished(msg.sender)){
            UnlockTokens();//unlocks all currently locked tokens + profit
        }
        //update balances
        tokenLockedBalances[msg.sender] = tokenLockedBalances[msg.sender].add(amt);
        totalLocked = totalLocked.add(amt);
        locked[msg.sender].lockStartTimestamp = now;
        _transfer(msg.sender, address(this), amt);//make transfer
        emit TokenLock(msg.sender, amt);
    }

    //unlock HXB tokens from contract
    function UnlockTokens()
        public
        synchronized
    {
        require(tokenLockedBalances[msg.sender] > 0,"Error: unsufficient locked balance");//ensure user has enough locked funds
        require(isLockFinished(msg.sender), "tokens cannot be unlocked yet. min 7 day lock");
        uint amt = tokenLockedBalances[msg.sender];
        uint256 interest = calcLockingRewards(msg.sender);
        _mint(msg.sender, interest);//mint HXB - total unlocked / 1000 * (minLockDayLength + days past)
        locked[msg.sender].totalEarnedInterest += interest;
        tokenLockedBalances[msg.sender] = 0;
        locked[msg.sender].lockStartTimestamp = 0;
        totalLocked = totalLocked.sub(amt);
        _transfer(address(this), msg.sender, amt);//make transfer
        emit TokenUnlock(msg.sender, amt);
    }

    //returns locking reward in hxb
    function calcLockingRewards(address _user)
        public
        view
        returns(uint)
    {
        return (tokenLockedBalances[_user].div(2500) * (minLockDayLength + daysPastMinLockTime()));
    }
    
    //returns amount of days locked past min lock time of 7 days
    function daysPastMinLockTime()
        public
        view
        returns(uint)
    {
        uint daysPast = now.sub(locked[msg.sender].lockStartTimestamp).div(daySeconds);
        if(daysPast >= minLockDayLength){
            return daysPast - minLockDayLength;// returns 0 if under 1 day passed
        }
        else{
            return 0;
        }
    }
    
    //mint HXB to address ( for use in external contracts within the ecosystem)
    function mintHXB(uint value, address receiver)
        public
        onlyMinters
        returns(bool)
    {
        uint amt = value.div(mintRatio);
        address minter = receiver;
        _mint(minter, amt);//mint HXB
        return true;
    }

    ///////////////////////////////
    ////////ADMIN ONLY//////////////
    ///////////////////////////////

    //allows addition of contract addresses that can call this contracts mint function.
    function addMinter(address minter)
        public
        onlyMultisig
        returns (bool)
    {        
        minters[minter] = true;
        minterAddresses.push(minter);
        return true;
    }


    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    //total HXB locked in contract
    function totalLockedTokenBalance()
        public
        view
        returns (uint256)
    {
        return totalLocked;
    }

    //HXB balance of caller
    function tokenBalance()
        public
        view
        returns (uint256)
    {
        return balanceOf(msg.sender);
    }

    //
    function isLockFinished(address _user)
        public
        view
        returns(bool)
    {
        if(locked[_user].lockStartTimestamp == 0){
            return false;
        }
        else{
           return locked[_user].lockStartTimestamp.add((minLockDayLength).mul(daySeconds)) <= now;               
        }

    }
    
    
    function donate() public payable {
        require(msg.value > 0);
        bool success = false;
        uint256 balance = msg.value;
        //distribute
        uint256 share = balance.div(2);
        (success, ) =  _p1.call{value:share}{gas:21000}('');
        require(success, "Transfer failed");
        (success, ) =  _p2.call{value:share}{gas:21000}('');
        require(success, "Transfer failed");
    }

}
