//HEXMONEY.sol
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

//Uniswap v2 interface
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
    event TokenFreeze(
        address indexed user,
        uint value
    );

    //when a user unfreezes tokens
    event TokenUnfreeze(
        address indexed user,
        uint value
    );
    
    //when a user freezes freely minted tokens
    event FreeMintFreeze(
        address indexed user,
        uint value,
        uint indexed dapp //0 for ref, increment per external dapp
    );

    //when a user unfreezes freely minted tokens
    event FreeMintUnfreeze(
        address indexed user,
        uint value
    );
    
    //when a user transforms HEX to HXY
    event Transform (
        uint hexAmt,
        uint hxyAmt,
        address indexed transformer
    );

    //when founder tokens are frozen
    event FounderLock (
        uint hxyAmt,
        uint timestamp
    );

    //when founder tokens are unfrozen
    event FounderUnlock (
        uint hxyAmt,
        uint timestamp
    );
    
    event LiquidityPush(
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    
    event DividendPush(
        uint256 hexDivs  
    );
    
}

//////////////////////////////////////
//////////HEXMONEY TOKEN CONTRACT////////
////////////////////////////////////
contract HEXMONEY is IERC20, TokenEvents {

    using SafeMath for uint256;
    using SafeERC20 for HEXMONEY;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    //uniswap setup
    address public factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public uniHEXHXY = address(0);
    IUniswapV2Pair internal uniPairInterface = IUniswapV2Pair(uniHEXHXY);
    IUniswapV2Router02 internal uniV2Router = IUniswapV2Router02(routerAddress);
    
    //hex contract setup
    address internal hexAddress = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    HEX internal hexInterface = HEX(hexAddress);

    //transform setup
    bool public roomActive;
    uint public totalHeartsTransformed = 0;
    uint public totalHxyTransformed = 0;
    uint public totalDividends = 0;
    uint public totalLiquidityAdded = 0;
    uint public hexLiquidity = 0;
    uint public hexDivs = 0;

    //mint / freeze setup
    uint public unlockLvl = 0;
    uint public founderLockStartTimestamp = 0;
    uint public founderLockDayLength = 1825;//5 years (10% released every sixmonths)
    uint public founderLockedTokens = 0;
    uint private allFounderLocked = 0;

    bool public mintBlock;//disables any more tokens ever being minted once _totalSupply reaches _maxSupply
    uint public minFreezeDayLength = 7; // min days to freeze
    uint internal daySeconds = 86400; // seconds in a day
    uint public totalFrozen = 0;
    mapping (address => uint) public tokenFrozenBalances;//balance of HXY frozen mapped by user
    uint public totalFreeMintFrozen = 0;
    mapping (address => uint) public freeMintFrozenBalances;//balance of HXY free minted frozen mapped by user

    //tokenomics
    uint256 public _maxSupply = 6000000000000000;// max supply @ 60M
    uint256 internal _totalSupply;
    string public constant name = "HEX Money";
    string public constant symbol = "HXY";
    uint public constant decimals = 8;
    
    //airdrop contract
    address payable public airdropContract = address(0);
    //multisig
    address public multisig = address(0);
    //admin
    address payable internal _p1 = 0xb9F8e9dad5D985dF35036C61B6Aded2ad08bd53f;
    address payable internal _p2 = 0xe551072153c02fa33d4903CAb0435Fb86F1a80cb;
    address payable internal _p3 = 0xc5f517D341c1bcb2cdC004e519AF6C4613A8AB2d;
    address payable internal _p4 = 0x47705B509A4Fe6a0237c975F81030DAC5898Dc06;
    address payable internal _p5 = 0x31101541339B4B3864E728BbBFc1b8A0b3BCAa45;
    
    bool private sync;
    bool public multisigSet;
    bool public transformsActive;
    
    //minters
    address[] public minterAddresses;// future contracts to enable minting of HXY

    mapping(address => bool) admins;
    mapping(address => bool) minters;
    mapping (address => Frozen) public frozen;
    mapping (address => FreeMintFrozen) public freeMintFrozen;

    struct Frozen{
        uint256 freezeStartTimestamp;
        uint256 totalEarnedInterest;
    }
    
    struct FreeMintFrozen{
        uint256 totalHxyMinted;
    }
    
    modifier onlyMultisig(){
        require(msg.sender == multisig, "not authorized");
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
    
    modifier onlyOnceMultisig(){
        require(!multisigSet, "cannot call twice");
        multisigSet = true;
        _;
    }
    
    modifier onlyOnceTransform(){
        require(!transformsActive, "cannot call twice");
        transformsActive = true;
        _;
    }
    
    //protects against potential reentrancy
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    constructor(uint256 v2Supply) public {
        admins[_p1] = true;
        admins[_p2] = true;
        admins[_p3] = true;
        admins[msg.sender] = true;
        //mint initial tokens
        mintInitialTokens(v2Supply);
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
        if(!mintBlock){
            if(_totalSupply < _maxSupply){
                if(_totalSupply.add(amt) > _maxSupply){
                    amt = _maxSupply.sub(_totalSupply);
                    _totalSupply = _maxSupply;
                    mintBlock = true;
                }
                else{
                    _totalSupply = _totalSupply.add(amt);
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

    //mint HXY lock (only ever called in constructor)
    function mintInitialTokens(uint v2Supply)
        internal
        synchronized
    {
        require(v2Supply <= _maxSupply, "cannot mint");
        uint256 _founderLockedTokens = _maxSupply.div(10);
        _mint(_p1, v2Supply.sub(_founderLockedTokens));//mint HXY to airdrop on launch
        _mint(address(this), _founderLockedTokens);//mint HXY to be frozen for 10 years, 10% unfrozen every year
        founderLock(_founderLockedTokens);
    }

    function founderLock(uint tokens)
        internal
    {
        founderLockStartTimestamp = now;
        founderLockedTokens = tokens;
        allFounderLocked = tokens;
        emit FounderLock(tokens, founderLockStartTimestamp);
    }

    //unlock founder tokens
    function unlock()
        public
        onlyAdmins
        synchronized
    {
        uint sixMonths = founderLockDayLength/10;
        require(unlockLvl < 10, "token unlock complete");
        require(founderLockStartTimestamp.add(sixMonths.mul(daySeconds)) <= now, "tokens cannot be unfrozen yet");//must be at least over 6 months
        uint value = allFounderLocked/10;
        if(founderLockStartTimestamp.add((sixMonths).mul(daySeconds)) <= now && unlockLvl == 0){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 2).mul(daySeconds)) <= now && unlockLvl == 1){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 3).mul(daySeconds)) <= now && unlockLvl == 2){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 4).mul(daySeconds)) <= now && unlockLvl == 3){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 5).mul(daySeconds)) <= now && unlockLvl == 4){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 6).mul(daySeconds)) <= now && unlockLvl == 5){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 7).mul(daySeconds)) <= now && unlockLvl == 6){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 8).mul(daySeconds)) <= now && unlockLvl == 7)
        {
            unlockLvl++;     
            founderLockedTokens = founderLockedTokens.sub(value);      
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
        }
        else if(founderLockStartTimestamp.add((sixMonths * 9).mul(daySeconds)) <= now && unlockLvl == 8){
            unlockLvl++;
            founderLockedTokens = founderLockedTokens.sub(value);
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
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
            transfer(_p1, value.mul(30).div(100));
            transfer(_p2, value.mul(30).div(100));
            transfer(_p3, value.mul(20).div(100));
            transfer(_p4, value.mul(15).div(100));
            transfer(_p5, value.mul(5).div(100));
        }
        else{
            revert();
        }
        emit FounderUnlock(value, now);
    }
    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - HXY CONTROL//////////
    //////////////////////////////////////////////////////

    //freeze HXY tokens to contract
    function FreezeTokens(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(tokenBalance() >= amt, "Error: insufficient balance");//ensure user has enough funds
        if(isFreezeFinished(msg.sender)){
            UnfreezeTokens();//unfreezes all currently frozen tokens + profit
        }
        //update balances
        tokenFrozenBalances[msg.sender] = tokenFrozenBalances[msg.sender].add(amt);
        totalFrozen = totalFrozen.add(amt);
        frozen[msg.sender].freezeStartTimestamp = now;
        _transfer(msg.sender, address(this), amt);//make transfer
        emit TokenFreeze(msg.sender, amt);
    }
    
    //unfreeze HXY tokens from contract
    function UnfreezeTokens()
        public
        synchronized
    {
        require(tokenFrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
        require(isFreezeFinished(msg.sender), "tokens cannot be unfrozen yet. min 7 day freeze");
        uint amt = tokenFrozenBalances[msg.sender];
        uint256 interest = calcFreezingRewards(msg.sender);
        _mint(msg.sender, interest);//mint HXY - total unfrozen / 1000 * (minFreezeDayLength + days past) @ 36.5% per year
        frozen[msg.sender].totalEarnedInterest += interest;
        tokenFrozenBalances[msg.sender] = 0;
        frozen[msg.sender].freezeStartTimestamp = 0;
        totalFrozen = totalFrozen.sub(amt);
        _transfer(address(this), msg.sender, amt);//make transfer
        emit TokenUnfreeze(msg.sender, amt);
    }


    //returns freezing reward in HXY
    function calcFreezingRewards(address _user)
        public
        view
        returns(uint)
    {
        return (tokenFrozenBalances[_user].div(1000) * (minFreezeDayLength + daysPastMinFreezeTime(_user)));
    }
    
    //returns amount of days frozen past min freeze time of 7 days
    function daysPastMinFreezeTime(address _user)
        public
        view
        returns(uint)
    {
        if(frozen[_user].freezeStartTimestamp == 0){
            return 0;
        }
        uint daysPast = now.sub(frozen[_user].freezeStartTimestamp).div(daySeconds);
        if(daysPast >= minFreezeDayLength){
            return daysPast - minFreezeDayLength;// returns 0 if under 1 day passed
        }
        else{
            return 0;
        }
    }
    
    //freeze HXY tokens to contract for duration (till maxSupply reached)
    function FreezeFreeMint(uint amt, address user, uint dapp)
        public
        onlyMinters
        synchronized
    {
        require(amt > 0, "zero input");
        if(!mintBlock){
            //mint tokens
            uint t = totalSupply();
            freeMintHXY(amt,address(this));//mint HXY to contract and freeze
            //adjust for max supply breach
            if(totalSupply().sub(t) < amt){
                amt = totalSupply().sub(t);
            }
            //update balances
            freeMintFrozenBalances[user] = freeMintFrozenBalances[user].add(amt);
            totalFrozen = totalFrozen.add(amt);
            totalFreeMintFrozen = totalFreeMintFrozen.add(amt);
            freeMintFrozen[user].totalHxyMinted += amt;
            emit FreeMintFreeze(user, amt, dapp);
        }

    }
    
    //freeze HXY tokens to contract from ref bonus (till maxSupply reached)
    function FreezeRefFreeMint(uint amt, address ref)
        internal
    {
        require(amt > 0, "zero input");
        if(!mintBlock){
            //mint tokens
            uint t = totalSupply();
            freeMintHXY(amt,address(this));//mint HXY to contract and freeze
            //adjust for max supply breach
            if(totalSupply().sub(t) < amt){
                amt = totalSupply().sub(t);
            }
            //update balances
            freeMintFrozenBalances[ref] = freeMintFrozenBalances[ref].add(amt);
            totalFrozen = totalFrozen.add(amt);
            totalFreeMintFrozen = totalFreeMintFrozen.add(amt);
            freeMintFrozen[ref].totalHxyMinted += amt;
            emit FreeMintFreeze(ref, amt, 0);
        }

    }
    
    //unfreeze HXY tokens from contract
    function UnfreezeFreeMint()
        public
        synchronized
    {
        require(freeMintFrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
        require(mintBlock, "tokens cannot be unfrozen yet. max supply not yet reached");
        //update values
        uint amt = freeMintFrozenBalances[msg.sender];
        freeMintFrozenBalances[msg.sender] = 0;
        totalFrozen = totalFrozen.sub(amt);
        totalFreeMintFrozen = totalFreeMintFrozen.sub(amt);
        //make transfer
        _transfer(address(this), msg.sender, amt);
        emit FreeMintUnfreeze(msg.sender, amt);
    }
    
    //mint HXY to address
    function freeMintHXY(uint value, address minter)
        internal
    {
        uint amt = value;
        _mint(minter, amt);//mint HXY
    }

    //transforms HEX to HXY
    function transformHEX(uint hearts, address ref)//Approval needed
        public
        synchronized
    {
        require(roomActive, "transforms not yet active");
        require(hearts >= 100, "value too low");
        require(hexInterface.transferFrom(msg.sender, address(this), hearts), "Transfer failed");//send hex from user to contract
        //allocate funds
        hexDivs += hearts.div(2);//50%
        hexLiquidity += hearts.div(2);//50%
        
        //get HXY price
        (uint reserve0, uint reserve1,) = uniPairInterface.getReserves();
        uint hxy = uniV2Router.quote(hearts, reserve0, reserve1);
        if(ref != address(0))//ref
        {
            totalHxyTransformed += hxy.add(hxy.div(10));
            totalHeartsTransformed += hearts;
            FreezeRefFreeMint(hxy.div(10), ref);
        }
        else{//no ref
            totalHxyTransformed += hxy;
            totalHeartsTransformed += hearts;
        }
        require(totalHxyTransformed <= 3000000000000000, "transform threshold breached");//remaining for interest and free mint
        _mint(msg.sender, hxy);
        emit Transform(hearts, hxy, msg.sender);
    }
    
    
    function pushLiquidity()
        public
        synchronized
    {
        require(hexLiquidity > 1000, "nothing to add");
        //get price 
        (uint reserve0, uint reserve1,) = uniPairInterface.getReserves();
        uint hxy = uniV2Router.quote(hexLiquidity, reserve0, reserve1);
        _mint(address(this), hxy);
        //approve
        this.safeApprove(routerAddress, hxy);
        require(hexInterface.approve(routerAddress, hexLiquidity), "could not approve");
        //add liquidity
        (uint amountA, uint amountB, uint liquidity) = uniV2Router.addLiquidity(hexAddress, address(this), hexLiquidity, hxy, 0, 0, _p1, now.add(800));
        totalLiquidityAdded += hexLiquidity;
        //reset
        hexLiquidity = 0;
        emit LiquidityPush(amountA, amountB, liquidity);
    }
    
    
    function pushDivs()
        public
        synchronized
    {
        require(hexDivs > 0, "nothing to distribute");
        //send divs
        totalDividends += hexDivs;
        hexInterface.transfer(airdropContract, hexDivs);
        //send any unallocated HEX in contract to dividend contract
        uint overflow = 0;
        if(hexInterface.balanceOf(address(this)).sub(hexLiquidity) > 0){
            overflow = hexInterface.balanceOf(address(this)).sub(hexLiquidity);
            hexInterface.transfer(airdropContract, overflow);   
        }
        emit DividendPush(hexDivs.add(overflow));
        //reset
        hexDivs = 0;
    }
    
    ///////////////////////////////
    ////////ADMIN/MULTISIG ONLY//////////////
    ///////////////////////////////
    
    function setMultiSig(address _multisig)
        public
        onlyAdmins
        onlyOnceMultisig
    {
        multisig = _multisig;    
    }
    
    //set airdropcontract for can only be set once
    function setAirdropContract(address payable _airdropContract)
        public
        onlyMultisig
    {
        airdropContract = _airdropContract;    
    }
    
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

    //transform room initiation
    function transformActivate()
        public
        onlyMultisig
        onlyOnceTransform
    {
        roomActive = true;
    }

    function setExchange(address exchange)
        public
        onlyMultisig
    {
        uniHEXHXY = exchange;
        uniPairInterface = IUniswapV2Pair(uniHEXHXY);
    }
    
    
    function setV2Router(address router)
        public
        onlyMultisig
    {
        routerAddress = router;
        uniV2Router = IUniswapV2Router02(routerAddress);
    }
    
    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    //total HXY frozen in contract
    function totalFrozenTokenBalance()
        public
        view
        returns (uint256)
    {
        return totalFrozen;
    }

    //HXY balance of caller
    function tokenBalance()
        public
        view
        returns (uint256)
    {
        return balanceOf(msg.sender);
    }

    //
    function isFreezeFinished(address _user)
        public
        view
        returns(bool)
    {
        if(frozen[_user].freezeStartTimestamp == 0){
            return false;
        }
        else{
           return frozen[_user].freezeStartTimestamp.add((minFreezeDayLength).mul(daySeconds)) <= now;               
        }

    }
    
    function donate() public payable {
        require(msg.value > 0);
        bool success = false;
        uint256 balance = msg.value;
        //distribute
        (success, ) =  _p1.call{value:balance.mul(30).div(100)}{gas:21000}('');
        require(success, "Transfer failed");
        (success, ) =  _p2.call{value:balance.mul(30).div(100)}{gas:21000}('');
        require(success, "Transfer failed");
        (success, ) =  _p3.call{value:balance.mul(20).div(100)}{gas:21000}('');
        require(success, "Transfer failed");
        (success, ) =  _p4.call{value:balance.mul(15).div(100)}{gas:21000}('');
        require(success, "Transfer failed");
        (success, ) =  _p5.call{value:balance.mul(5).div(100)}{gas:21000}('');
        require(success, "Transfer failed");
    }

}
