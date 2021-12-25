/**
 *Submitted for verification at polygonscan.com on 2021-12-24
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.10;

//safeMath for safe calculations
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

//address lib
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

//basic functions
interface commonFunction {
    function totalSupply() external view returns (uint256);
    // function decimals() external view returns (uint8);
    // function symbol() external view returns (string memory);
    // function name() external view returns (string memory);
    // function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    //basic transfer
    function transfer(address recipient, uint256 amount) external returns (bool);
    //other app check allowance
    function allowance(address _owner, address spender) external view returns (uint256);
    //what we approve
    function approve(address spender, uint256 amount) external returns (bool);
    //other app may transfer
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//multiple ownership system
abstract contract Ownership {
    address internal owner;
    mapping(address => bool) internal authorizations;
    mapping(address => bool) internal blacklist;
    address[] internal authorizedUserlist;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
        authorizedUserlist.push(_owner);
    }

    //modifier to make onlyOwner calls(admin calls)
    modifier onlyOwner() {
        require(isOwner(msg.sender), "You are not OWNER");
        _;
    }

    //  modifier to verify authorized users(sub-admin)
    modifier authorized() {
        require(isAuthorized(msg.sender), "you are not AUTHORIZED");
        _;
    }

    //  modifier to verify phishing addresss'
    modifier blacklisted() {
        require(!isBlacklisted(msg.sender), "you are not AUTHORIZED");
        _;
    }

    //only owner can Authorize address for sub-admins rolls
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
        authorizedUserlist.push(adr);
    }

    //  verify address is owner or not
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    // Return boolean of owner/address authorization status
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    //blacklist fishing contracts
    function blacklistPhisingAddress(address adr) public onlyOwner {
        blacklist[adr] = true;
    }

    // Return boolean of address is blacklisted or not
    function isBlacklisted(address adr) public view returns (bool) {
        return blacklist[adr];
    }

    //only owner can UNAuthorize address for sub-admins rolls
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    //remove from blacklist fishing contracts
    function removefromblacklist(address adr) public onlyOwner {
        blacklist[adr] = false;
    }

    //only owner can UNAuthorize address for sub-admins rolls
    function unauthorizeAllExceptOwner() public onlyOwner {
        for (uint256 index = 0; index < authorizedUserlist.length; index++) {
            if (authorizedUserlist[index] != owner) {
                authorizations[authorizedUserlist[index]] = false;
            }
        }
    }

    //Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        authorizedUserlist.push(adr);
        emit OwnershipTransferred(adr);
    }

    function getCurrentOwner() public view returns(address){
        return owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(address(0));  //need to verify this
        owner = address(0);
    }

    event OwnershipTransferred(address owner);
}

//for autoliquidity
//Below 4 interfaces for auto liquidity
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);//commnted
    function feeToSetter() external view returns (address);//commnted

    function getPair(address tokenA, address tokenB) external view returns (address pair);//commnted
    function allPairs(uint) external view returns (address pair);//commnted
    function allPairsLength() external view returns (uint);//commnted

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external; //commnted
    function setFeeToSetter(address) external;//commnted
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);//commnted
    function PERMIT_TYPEHASH() external pure returns (bytes32);//commnted
    function nonces(address owner) external view returns (uint);//commnted

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;//commnted
    
   event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);//commnted
    event Swap(  
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    ); //commnted
   event Sync(uint112 reserve0, uint112 reserve1); //commnted

   function MINIMUM_LIQUIDITY() external pure returns (uint); //commnted
    function factory() external view returns (address);
   function token0() external view returns (address); //commnted all below
   function token1() external view returns (address);
   function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
   function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

   function initialize(address, address) external;
}

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
    ) external returns (uint amountA, uint amountB); //commnted all below
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
    function removeLiquidityETHSupportingFeeOnTransferTokens( //commnted
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( //commnted
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens( //commnted
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


//for redistributed

//main contract
contract KBC is commonFunction, Ownership {
    using SafeMath for uint256;
    using Address for address;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    // address marketingAdr = 0x4C9f78637e59681fB83F0c7543B5644719F8A684; //edit here
    address payable public marketingAdr = payable(0x4C9f78637e59681fB83F0c7543B5644719F8A684); //owner same for marketing //check this
   // address routerv2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address routerv2 = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //prod quickswap router
    address public marketingWalletToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; //(PoS) Tether USD

    event TokenBurn(address indexed from, uint256 value);
    event SetLiquidityFee(uint256 amount);
    event SetMarketingFee(uint256 amount);
   // event SetBurnFee(uint256 amount); //manual burning 

    string private _name = "KBC";
    string private _symbol = "KBC";
    uint8 private _decimals = 18;

    uint256 _totalSupply = 100000000000 * (10**_decimals); // 100B edit here
   // uint256 public _maxTxAmount = (_totalSupply * 2) / 100;

    //max wallet holding of 2%
    //uint256 public _maxWalletToken = (_totalSupply * 2) / 100;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) _isExcludedFromFees; //no fee
    mapping(address => bool) isTxLimitExempt; //no tax
 //   mapping(address => bool) isTimelockExempt; //no locking prd //check this
    // mapping(address => bool) isDividendExempt; //no reDistribute
    mapping(address => bool) _isExcludedFromMaxBalance; //no reDistribute

    //fee section
    uint256 private _totalFees;
    uint256 private _totalFeesToContract;
    uint256 private _liquidityFee;
   // uint256 private _burnFee;
    uint256 private _marketingFee;

    uint256 private _maxBalance;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair; //lp pair

    //uint256 private _liquifyThreshhold; //check this
    bool inSwapAndLiquify; //default false

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () Ownership(msg.sender) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerv2); //routerv2 address
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true; //check this
        
        _isExcludedFromMaxBalance[msg.sender] = true; //check this
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[uniswapV2Pair] = true;

        _liquidityFee = 3; //need to discuss again
        _marketingFee = 3;
        //_burnFee = 1;
        _totalFees = _liquidityFee.add(_marketingFee);  //6
        _totalFeesToContract = _liquidityFee.add(_marketingFee); //6

       // _liquifyThreshhold = 20 * 10**9 * 10**_decimals; //20000000000 
        _maxBalance = _totalSupply.mul(2).div(100); //2%

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {} // check this

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

    function circulatingSuppy() public view returns (uint256) {
        return _totalSupply.sub(_balances[DEAD]).sub(_balances[ZERO]);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);   //check this
        return true;
    }

    //check below 3
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")); //check this
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

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }    
    
    function setMarketingAddress(address payable newMarketingAddress) external authorized() {
        marketingAdr = newMarketingAddress;
    }

    function setFee(uint256 newLiquidityFee, uint256 newMarketingFee) external onlyOwner(){
        _liquidityFee = newLiquidityFee;
        //_burnFee = newMarketingFee;
        _marketingFee = newMarketingFee;
        _totalFees = _liquidityFee.add(_marketingFee);
        _totalFeesToContract = _liquidityFee.add(_marketingFee);
        emit SetLiquidityFee(_liquidityFee);
        emit SetMarketingFee(_marketingFee);
       // emit SetBurnFee(_burnFee);
    }

    // function setLiquifyThreshhold(uint256 newLiquifyThreshhold) external onlyOwner() {
    //     _liquifyThreshhold = newLiquifyThreshhold;
    // }   

    function setMarketingWalletToken(address _marketingWalletToken) external authorized() {
        marketingWalletToken = _marketingWalletToken;
    }

    function setMaxBalance(uint256 newMaxBalancePercent) external onlyOwner(){
        // Minimum _maxBalance is 0.5% of _totalSupply 
        _maxBalance = _totalSupply.mul(newMaxBalancePercent).div(100);
        //require(newMaxBalance >= _totalSupply.mul(5).div(1000));
        //_maxBalance = newMaxBalance;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }

    function includeInFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function isExcludedFromMaxBalance(address account) public view returns(bool) {
        return _isExcludedFromMaxBalance[account];
    }
    
    function excludeFromMaxBalance(address account) public onlyOwner {
        _isExcludedFromMaxBalance[account] = true;
    }
    
    function includeInMaxBalance(address account) public onlyOwner {
        _isExcludedFromMaxBalance[account] = false;
    }

    function totalFees() public view returns (uint256) {
        return _totalFees;
    }

    function liquidityFee() public view returns (uint256) {
        return _liquidityFee;
    }

    function marketingFee() public view returns (uint256) {
        return _marketingFee;
    }

    // function burnFee() public view returns (uint256) {
    //     return _burnFee;
    // }

    // function liquifyThreshhold() public view returns(uint256){
    //     return _liquifyThreshhold;
    // }

    function maxBalance() public view returns (uint256) {
        return _maxBalance;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(!isBlacklisted(from), 'sender is blacklisted'); //check this
        require(!isBlacklisted(to), 'recipient is blacklisted'); //check this
        require(_balances[from] >= amount, "insufficient funds"); //check this
        require(amount > 0, "Transfer amount must be greater than zero");

        // Make sure that: Balance + Buy Amount <= _maxBalance
        if(!_isExcludedFromMaxBalance[to])  // is excludedFromMaxBalance
        {
            require(balanceOf(to).add(amount) <= _maxBalance, "Max Balance is reached.");
        }
        //check this
        // Swap Fees 
        if(
            to == uniswapV2Pair &&                              // Sell
            !inSwapAndLiquify &&                                // Swap is not locked
        //    balanceOf(address(this)) >= _liquifyThreshhold &&   // liquifyThreshhold is reached
            _totalFeesToContract > 0 &&                         // LiquidityFee + MarketingFee > 0
            _totalFees > 0 &&                                   //total fee more than 0
            !_isExcludedFromFees[from] &&                                  // Not from excludedOne
            !_isExcludedFromFees[to]                                       // Not to excludedOne
        ) {
            uint256 feesToContract = amount.mul(_totalFeesToContract).div(100);
        	amount = amount.sub(feesToContract);
            transferToken(from, to, amount); //first transfer to buyer/seller
            transferToken(from, address(this), feesToContract);
            uint256 liquidityTokensToSell = balanceOf(address(this)).mul(_liquidityFee).div(_totalFeesToContract);
            uint256 marketingTokensToSell = balanceOf(address(this)).mul(_marketingFee).div(_totalFeesToContract);
            // Get collected Liquidity Fees
            swapAndLiquify(liquidityTokensToSell);  
            // Get collected Marketing Fees 
            swapAndSendToFee(marketingTokensToSell);
        }else{
            transferToken(from, to, amount);
        }
    }

    function transferToken(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function swapAndLiquify(uint256 tokens) private {
       
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // current ETH balance
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half); 

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);
    }

    //check this imp
    function swapAndSendToFee(uint256 tokens) private  {

        swapTokensForMarketingToken(tokens);
        // Transfer sold Token to marketingWallet
        // * vv imp function to test */
        commonFunction(marketingWalletToken).transfer(marketingAdr, commonFunction(marketingWalletToken).balanceOf(address(this))); //imp function to test
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForMarketingToken(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = marketingWalletToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            address(0),
            block.timestamp
        );
    }
}