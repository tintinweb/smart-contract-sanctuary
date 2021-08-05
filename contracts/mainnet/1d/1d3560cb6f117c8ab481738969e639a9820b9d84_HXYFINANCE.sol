//HXYF.sol
//
//

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

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////

contract TokenEvents {

    //when a user freezes tokens
    event LpFreeze(
        address indexed user,
        uint value,
        address indexed lpToken
    );

    //when a user unfreezes tokens
    event LpUnfreeze(
        address indexed user,
        uint value,
        address indexed lpToken
    );
    

    
}

//////////////////////////////////////
//////////HXYFINANCE TOKEN CONTRACT////////
////////////////////////////////////
contract HXYFINANCE is IERC20, TokenEvents {

    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint32;
    using SafeMath for uint16;
    using SafeMath for uint8;

    using SafeERC20 for HXYFINANCE;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    //uniswap setup
    address public uniETHHXYF = address(0);
    address public uniETHHXY = address(0x8349fBbd8F229b0B6298e7c14b3778eaDf4426DD);
    address public uniHEXHXB = address(0x938Af9DE4Fe7Fd683F9eDf29E12457181E01Ca46);
    address public uniETHHXP = address(0x55dB1Ca87CB8f0e6AaEa44BeE5E6DcE5B72DA9c0);
    IUniswapV2Pair internal uniETHHXYFInterface = IUniswapV2Pair(uniETHHXYF);
    IUniswapV2Pair internal uniETHHXYInterface = IUniswapV2Pair(uniETHHXY);
    IUniswapV2Pair internal uniHEXHXBInterface = IUniswapV2Pair(uniHEXHXB);
    IUniswapV2Pair internal uniETHHXPInterface = IUniswapV2Pair(uniETHHXP);

    //apy setup
    uint32 public hxyfApy = 100;
    uint32 public hxyApy = 333;
    uint32 public hxbApy = 500;
    uint32 public hxpApy = 1000;
    uint32 public globalApy = 100;
    uint16 public halvening = 1;
    
    //lp freeze setup
    uint constant internal MINUTESECONDS = 60;
    uint256 public totalHxyfLpFrozen = 0;
    uint256 public totalHxyLpFrozen = 0;
    uint256 public totalHxbLpFrozen = 0;
    uint256 public totalHxpLpFrozen = 0;
    
    mapping (address => uint) public hxyfLpFrozenBalances;//balance of ETHHXYF LP frozen mapped by user
    mapping (address => uint) public hxyLpFrozenBalances;//balance of ETHHXY LP frozen mapped by user
    mapping (address => uint) public hxbLpFrozenBalances;//balance of HEXHXB LP frozen mapped by user
    mapping (address => uint) public hxpLpFrozenBalances;//balance of HXPETH LP frozen mapped by user

    //tokenomics
    uint256 internal _totalSupply;
    string public constant name = "hxy.finance";
    string public constant symbol = "HXYF";
    uint8 public constant decimals = 18;
    
    //airdrop contract
    address payable public airdropContract = address(0);

    //admin
    address payable internal _p1 = 0x55db05F51b31F45EBEDefdD4467ebEc2D026a820;
    address payable internal _p2 = 0x993e189a1b8B9D0D8259E09479ADD07c084b8e75;
    
    bool private sync;
    
    mapping(address => bool) admins;
    
    mapping (address => Farmer) public farmer;
    struct Farmer{
        uint256 hxyfFreezeStartTimestamp;
        uint256 hxyFreezeStartTimestamp;
        uint256 hxbFreezeStartTimestamp;
        uint256 hxpFreezeStartTimestamp;
        uint256 totalFarmedHxyf;
    }
    
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

    constructor(uint256 initialTokens) public {
        admins[_p1] = true;
        admins[_p2] = true;
        admins[msg.sender] = true;
        //mint initial tokens
        mintInitialTokens(initialTokens);
    }


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

    //mint HXYF initial tokens (only ever called in constructor)
    function mintInitialTokens(uint amount)
        internal
        synchronized
    {
        _mint(_p1, amount.div(4).mul(3));//mint HXYF to p1
        _mint(_p2, amount.div(4));//mint HXYF to p2
    }

    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - HXYF CONTROL//////////
    //////////////////////////////////////////////////////
    
    //freeze ETHHXYF LP tokens to contract, approval needed
    function FreezeEthHxyfLP(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(lpBalance(uniETHHXYF) >= amt, "Error: insufficient balance");//ensure user has enough funds
        if(isHarvestable(msg.sender, uniETHHXYF)){
            uint256 interest = calcHarvestRewards(msg.sender, uniETHHXYF);
            if(interest > 0){
                harvest(interest);
            }
        }
        //update balances
        hxyfLpFrozenBalances[msg.sender] = hxyfLpFrozenBalances[msg.sender].add(amt);
        totalHxyfLpFrozen = totalHxyfLpFrozen.add(amt);
        farmer[msg.sender].hxyfFreezeStartTimestamp = now;
        uniETHHXYFInterface.transferFrom(msg.sender, address(this), amt);//make transfer
        emit LpFreeze(msg.sender, amt, uniETHHXYF);
    }
    
    //unfreeze ETHHXYF LP tokens from contract
    function UnfreezeEthHxyfLP()
        public
        synchronized
    {
        require(hxyfLpFrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
        uint amt = hxyfLpFrozenBalances[msg.sender];
        if(isHarvestable(msg.sender, uniETHHXYF)){
            uint256 interest = calcHarvestRewards(msg.sender, uniETHHXYF);
            if(interest > 0){
                harvest(interest);
            }
        }
        hxyfLpFrozenBalances[msg.sender] = 0;
        farmer[msg.sender].hxyfFreezeStartTimestamp = 0;
        totalHxyfLpFrozen = totalHxyfLpFrozen.sub(amt);
        uniETHHXYFInterface.transfer(msg.sender, amt);//make transfer
        emit LpUnfreeze(msg.sender, amt, uniETHHXYF);
    }
    
    //freeze ETHHXY LP tokens to contract, approval needed
    function FreezeEthHxyLP(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(lpBalance(uniETHHXY) >= amt, "Error: insufficient balance");//ensure user has enough funds
        if(isHarvestable(msg.sender, uniETHHXY)){
            uint256 interest = calcHarvestRewards(msg.sender, uniETHHXY);
            if(interest > 0){
                harvest(interest);
            }
        }
        //update balances
        hxyLpFrozenBalances[msg.sender] = hxyLpFrozenBalances[msg.sender].add(amt);
        totalHxyLpFrozen = totalHxyLpFrozen.add(amt);
        farmer[msg.sender].hxyFreezeStartTimestamp = now;
        uniETHHXYInterface.transferFrom(msg.sender, address(this), amt);//make transfer
        emit LpFreeze(msg.sender, amt, uniETHHXY);
    }
    
    //unfreeze ETHHXY LP tokens from contract
    function UnfreezeEthHxyLP()
        public
        synchronized
    {
        require(hxyLpFrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
        uint amt = hxyLpFrozenBalances[msg.sender];
        if(isHarvestable(msg.sender, uniETHHXY)){
            uint256 interest = calcHarvestRewards(msg.sender, uniETHHXY);
            if(interest > 0){
                harvest(interest);
            }
        }
        hxyLpFrozenBalances[msg.sender] = 0;
        farmer[msg.sender].hxyFreezeStartTimestamp = 0;
        totalHxyLpFrozen = totalHxyLpFrozen.sub(amt);
        uniETHHXYInterface.transfer(msg.sender, amt);//make transfer
        emit LpUnfreeze(msg.sender, amt, uniETHHXY);
    }
    
    //freeze HEXHXB LP tokens to contract, approval needed
    function FreezeHexHxbLP(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(lpBalance(uniHEXHXB) >= amt, "Error: insufficient balance");//ensure user has enough funds
        if(isHarvestable(msg.sender, uniHEXHXB)){
            uint256 interest = calcHarvestRewards(msg.sender, uniHEXHXB);
            if(interest > 0){
                harvest(interest);
            }
        }
        //update balances
        hxbLpFrozenBalances[msg.sender] = hxbLpFrozenBalances[msg.sender].add(amt);
        totalHxbLpFrozen = totalHxbLpFrozen.add(amt);
        farmer[msg.sender].hxbFreezeStartTimestamp = now;
        uniHEXHXBInterface.transferFrom(msg.sender, address(this), amt);//make transfer
        emit LpFreeze(msg.sender, amt, uniHEXHXB);
    }
    
    //unfreeze HEXHXB LP tokens from contract
    function UnfreezeHexHxbLP()
        public
        synchronized
    {
        require(hxbLpFrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
        uint amt = hxbLpFrozenBalances[msg.sender];
        if(isHarvestable(msg.sender, uniHEXHXB)){
            uint256 interest = calcHarvestRewards(msg.sender, uniHEXHXB);
            if(interest > 0){
                harvest(interest);
            }
        }
        hxbLpFrozenBalances[msg.sender] = 0;
        farmer[msg.sender].hxbFreezeStartTimestamp = 0;
        totalHxbLpFrozen = totalHxbLpFrozen.sub(amt);
        uniHEXHXBInterface.transfer(msg.sender, amt);//make transfer
        emit LpUnfreeze(msg.sender, amt, uniHEXHXB);
    }
    
    //freeze HXPETH LP tokens to contract, approval needed
    function FreezeEthHxpLP(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(lpBalance(uniETHHXP) >= amt, "Error: insufficient balance");//ensure user has enough funds
        if(isHarvestable(msg.sender, uniETHHXP)){
            uint256 interest = calcHarvestRewards(msg.sender, uniETHHXP);
            if(interest > 0){
                harvest(interest);
            }
        }
        //update balances
        hxpLpFrozenBalances[msg.sender] = hxpLpFrozenBalances[msg.sender].add(amt);
        totalHxpLpFrozen = totalHxpLpFrozen.add(amt);
        farmer[msg.sender].hxpFreezeStartTimestamp = now;
        uniETHHXPInterface.transferFrom(msg.sender, address(this), amt);//make transfer
        emit LpFreeze(msg.sender, amt, uniETHHXP);
    }
    
    //unfreeze HXPETH LP tokens from contract
    function UnfreezeEthHxpLP()
        public
        synchronized
    {
        require(hxpLpFrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
        uint amt = hxpLpFrozenBalances[msg.sender];
        if(isHarvestable(msg.sender, uniETHHXP)){
            uint256 interest = calcHarvestRewards(msg.sender, uniETHHXP);
            if(interest > 0){
                harvest(interest);
            }
        }
        hxpLpFrozenBalances[msg.sender] = 0;
        farmer[msg.sender].hxpFreezeStartTimestamp = 0;
        totalHxpLpFrozen = totalHxpLpFrozen.sub(amt);
        uniETHHXPInterface.transfer(msg.sender, amt);//make transfer
        emit LpUnfreeze(msg.sender, amt, uniETHHXP);
    }

    function harvest(uint rewards)
        internal
    {
        _mint(msg.sender, rewards);
        _mint(airdropContract, rewards);
        _mint(_p1, rewards.div(2));
        _mint(_p2, rewards.div(2));
    }

    //harvest HXYF from ETHHXYF lp
    function HarvestHxyfLp()
        public
    {
        require(hxyfLpFrozenBalances[msg.sender] > 0,"Error: unsufficient lp balance");//ensure user has enough lp frozen 
        uint256 interest = calcHarvestRewards(msg.sender, uniETHHXYF);
        if(interest > 0){
            harvest(interest);
            farmer[msg.sender].hxyfFreezeStartTimestamp = now;
            farmer[msg.sender].totalFarmedHxyf += interest;
        }
    }
    
    //harvest HXYF from ETHHXY lp
    function HarvestHxyLp()
        public
    {
        require(hxyLpFrozenBalances[msg.sender] > 0,"Error: unsufficient lp balance");//ensure user has enough lp frozen 
        uint256 interest = calcHarvestRewards(msg.sender, uniETHHXY);
        if(interest > 0){
            harvest(interest);
            farmer[msg.sender].hxyFreezeStartTimestamp = now;
            farmer[msg.sender].totalFarmedHxyf += interest;
        }
    }

    //harvest HXYF from HEXHXB lp
    function HarvestHxbLp()
        public
    {
        require(hxbLpFrozenBalances[msg.sender] > 0,"Error: unsufficient lp balance");//ensure user has enough lp frozen 
        uint256 interest = calcHarvestRewards(msg.sender, uniHEXHXB);
        if(interest > 0){
            harvest(interest);
            farmer[msg.sender].hxbFreezeStartTimestamp = now;
            farmer[msg.sender].totalFarmedHxyf += interest;
        }
    }

    //harvest HXYF from HEXHXP lp
    function HarvestHxpLp()
        public
    {
        require(hxpLpFrozenBalances[msg.sender] > 0,"Error: unsufficient lp balance");//ensure user has enough lp frozen 
        uint256 interest = calcHarvestRewards(msg.sender, uniETHHXP);
        if(interest > 0){
            harvest(interest);
            farmer[msg.sender].hxpFreezeStartTimestamp = now;
            farmer[msg.sender].totalFarmedHxyf += interest;
        }
    }

    //returns freezing reward in HXY
    function calcHarvestRewards(address _user, address _lp)
        public
        view
        returns(uint)
    {   
        if(_lp == uniETHHXYF){
            return ((hxyfLpFrozenBalances[_user].mul(globalApy.div(halvening)).div(hxyfApy)).mul(minsPastFreezeTime(_user, _lp)));
        }
        else if(_lp == uniETHHXY){
            return ((hxyLpFrozenBalances[_user].mul(globalApy.div(halvening)).div(hxyApy)).mul(minsPastFreezeTime(_user, _lp))); 
        }
        else if(_lp == uniHEXHXB){
            return ((hxbLpFrozenBalances[_user].mul(globalApy.div(halvening)).div(hxbApy)).mul(minsPastFreezeTime(_user, _lp)));
        }
        else if(_lp == uniETHHXP){
            return ((hxpLpFrozenBalances[_user].mul(globalApy.div(halvening)).div(hxpApy)).mul(minsPastFreezeTime(_user, _lp)));
        }
        else{
            revert();
        }
    }
    
    
    //returns amount of minutes past since lp freeze start - min 1 minute
    function minsPastFreezeTime(address _user, address _lp)
        public
        view
        returns(uint)
    {
        if(_lp == uniETHHXYF){
            if(farmer[_user].hxyfFreezeStartTimestamp == 0){
                return 0;
            }
            uint minsPast = now.sub(farmer[_user].hxyfFreezeStartTimestamp).div(MINUTESECONDS);
            if(minsPast >= 1){
                return minsPast;// returns 0 if under 1 min passed
            }
            else{
                return 0;
            }
        }
        else if(_lp == uniETHHXY){
            if(farmer[_user].hxyFreezeStartTimestamp == 0){
                return 0;
            }
            uint minsPast = now.sub(farmer[_user].hxyFreezeStartTimestamp).div(MINUTESECONDS);
            if(minsPast >= 1){
                return minsPast;// returns 0 if under 1 min passed
            }
            else{
                return 0;
            }
        }
        else if(_lp == uniHEXHXB){
            if(farmer[_user].hxbFreezeStartTimestamp == 0){
                return 0;
            }
            uint minsPast = now.sub(farmer[_user].hxbFreezeStartTimestamp).div(MINUTESECONDS);
            if(minsPast >= 1){
                return minsPast;// returns 0 if under 1 min passed
            }
            else{
                return 0;
            }
        }
        else if(_lp == uniETHHXP){
            if(farmer[_user].hxpFreezeStartTimestamp == 0){
                return 0;
            }
            uint minsPast = now.sub(farmer[_user].hxpFreezeStartTimestamp).div(MINUTESECONDS);
            if(minsPast >= 1){
                return minsPast;// returns 0 if under 1 min passed
            }
            else{
                return 0;
            }
        }
        else{
            revert();
        }
    }
    
    function burnHxyf(uint amt)
        public
    {
        require(amt > 0, "value must be greater than 0");
        _burn(msg.sender, amt);
    }
    
    ///////////////////////////////
    ////////ADMIN ONLY//////////////
    ///////////////////////////////
    
    function newHalvening()
        public
        onlyAdmins
    {   
        halvening = halvening * 2;
    }

    function setGlobalApy(uint32 _apy)
        public
        onlyAdmins
    {   
          globalApy = _apy;
    }
    
    function setApy(uint32 _apy, address _lp)
        public
        onlyAdmins
    {
        if(_lp == uniETHHXYF){
            hxyfApy = _apy;
        }
        else if(_lp == uniETHHXY){
            hxyApy = _apy;
        }
        else if(_lp == uniHEXHXB){
            hxbApy = _apy;
        }
        else if(_lp == uniETHHXP){
            hxpApy = _apy;
        }
        else{
            revert();
        }
    }
    
    //set airdropcontract for can only be set once
    function setAirdropContract(address payable _airdropContract)
        public
        onlyAdmins
    {
        require(_airdropContract != address(0), "cannot be null address");
        airdropContract = _airdropContract;
    }

    function setHXYFExchange(address exchange)
        public
        onlyAdmins
    {
        uniETHHXYF = exchange;
        uniETHHXYFInterface = IUniswapV2Pair(uniETHHXYF);
    }
        function setHXYExchange(address exchange)
        public
        onlyAdmins
    {
        uniETHHXY = exchange;
        uniETHHXYInterface = IUniswapV2Pair(uniETHHXY);
    }
        function setHXBExchange(address exchange)
        public
        onlyAdmins
    {
        uniHEXHXB = exchange;
        uniHEXHXBInterface = IUniswapV2Pair(uniHEXHXB);
    }
        function setHXPExchange(address exchange)
        public
        onlyAdmins
    {
        uniETHHXP = exchange;
        uniETHHXPInterface = IUniswapV2Pair(uniETHHXP);
    }
    
    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    //total HXY frozen in contract
    function totalFrozenLpBalance(address _lp)
        public
        view
        returns (uint256)
    {
        if(_lp == uniETHHXYF){
            return totalHxyfLpFrozen;
        }
        else if(_lp == uniETHHXY){
            return totalHxyLpFrozen;
        }
        else if(_lp == uniHEXHXB){
            return totalHxbLpFrozen;
        }
        else if(_lp == uniETHHXP){
            return totalHxpLpFrozen;
        }
        else{
            revert();
        }
    }

    //HXYF balance of caller
    function hxyfBalance()
        public
        view
        returns (uint256)
    {
        return balanceOf(msg.sender);
    }
    
    //LP balance of caller
    function lpBalance(address _lp)
        public
        view
        returns (uint256)
    {
        if(_lp == uniETHHXYF){
            return uniETHHXYFInterface.balanceOf(msg.sender);
        }
        else if(_lp == uniETHHXY){
            return uniETHHXYInterface.balanceOf(msg.sender);

        }
        else if(_lp == uniHEXHXB){
            return uniHEXHXBInterface.balanceOf(msg.sender);
        }
        else if(_lp == uniETHHXP){
            return uniETHHXPInterface.balanceOf(msg.sender);
        }
        else{
            revert();
        }

    }

    //check if user can harvest HXYF yet
    function isHarvestable(address _user, address _lp)
        public
        view
        returns(bool)
    {
        if(_lp == uniETHHXYF){
            if(farmer[_user].hxyfFreezeStartTimestamp == 0){
                return false;
            }
            else{
               return farmer[_user].hxyfFreezeStartTimestamp.add((MINUTESECONDS.div(24))) <= now; 
            }
        }
        else if(_lp == uniETHHXY){
            if(farmer[_user].hxyFreezeStartTimestamp == 0){
                return false;
            }
            else{
               return farmer[_user].hxyFreezeStartTimestamp.add((MINUTESECONDS.div(24))) <= now; 
            }
        }
        else if(_lp == uniHEXHXB){
            if(farmer[_user].hxbFreezeStartTimestamp == 0){
                return false;
            }
            else{
               return farmer[_user].hxbFreezeStartTimestamp.add((MINUTESECONDS.div(24))) <= now; 
            }
        }
        else if(_lp == uniETHHXP){
            if(farmer[_user].hxpFreezeStartTimestamp == 0){
                return false;
            }
            else{
               return farmer[_user].hxpFreezeStartTimestamp.add((MINUTESECONDS.div(24))) <= now; 
            }
        }
        else{
            revert();
        }
    }
    
    function donate() public payable {
        require(msg.value > 0);
        bool success = false;
        uint256 balance = msg.value;
        //distribute
        (success, ) =  _p1.call{value:balance.mul(50).div(100)}{gas:21000}('');
        require(success, "Transfer failed");
        (success, ) =  _p2.call{value:balance.mul(50).div(100)}{gas:21000}('');
        require(success, "Transfer failed");
    }

}
