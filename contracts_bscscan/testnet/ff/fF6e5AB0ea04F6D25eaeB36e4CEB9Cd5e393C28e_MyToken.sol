/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

pragma solidity ^0.8.3;
// SPDX-License-Identifier: MIT
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode -
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

contract MyToken is Context, IERC20, Ownable { 
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public _exemptFromMaxWallet;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
//SET WALLET ADDRESSES
    address payable private _devWalletAddress = payable(0xE5D4e37B8729371de54AFAB4368FCF6b0DAdb661);
    address payable private _marketingWalletAddress = payable(0x85Eb762eac7Ecc7A1dE3Ed6a2AaE48010A809512);
    address payable private _developmentWalletAddress = payable(0xcCA8410CD82F6e83F770ca533e7A99C9cD0387F4);
    address constant private _burnAddress = 0x000000000000000000000000000000000000dEaD;
   
    uint256 private constant MAX = type(uint256).max;
    uint256 private _tTotal = 100000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "DisToken";
    string private _symbol = "DISSYMB";
    uint8 private _decimals = 9;
    //ADDING SEPERATE BUY AND SELL FEES
    uint256 public _reflectionFee;
    uint256 private _previousReflectionFee = _reflectionFee;
    uint256 public _bdevFee;
    uint256 public _bliquidityFee;
    uint256 public _bmarketingFee;
    uint256 public _bdevelopmentFee;
    uint256 private _btotalBNBFees = _bmarketingFee + _bdevelopmentFee + _bdevFee + _bliquidityFee;
    uint256 public _sdevFee;
    uint256 public _sliquidityFee;
    uint256 public _smarketingFee;
    uint256 public _sdevelopmentFee;
    uint256 private _stotalBNBFees = _smarketingFee + _sdevelopmentFee + _sdevFee + _sliquidityFee;
    uint256 private _totalBNBFees = (_btotalBNBFees + _stotalBNBFees) / 2;
    uint256 private _previousTotalFee = _totalBNBFees;
    uint256 private _advLiquidityFee = (_bliquidityFee + _sliquidityFee) / 2;
    uint256 private _advmarketingFee = (_bmarketingFee + _smarketingFee) / 2;
    uint256 private _advDevelopmentFee = (_bliquidityFee + _sdevelopmentFee) / 2;
    uint256 private _advDevFee = (_bdevFee + _sdevFee) / 2;   
    uint256 private maxTaxRate = 40;
    uint256 private _theseBNBFees;

    uint256 public maxWalletBalance = (totalSupply() * 1) / 100;
     
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingIsEnabled = false;

   
    uint256 public _maxTxAmount = 100000000000 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 400000 * 10**9;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _tOwned[owner()] = _tTotal;
        _rOwned[owner()] = _rTotal;
        
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        _maxTxAmount = _tTotal; // start off transaction limit at 100% of total supply
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        _exemptFromMaxWallet[owner()] = true;
        _exemptFromMaxWallet[address(this)] = true;
        _exemptFromMaxWallet[uniswapV2Pair] = true;
        _exemptFromMaxWallet[_devWalletAddress] = true;
        _exemptFromMaxWallet[_marketingWalletAddress] = true;
        _exemptFromMaxWallet[_developmentWalletAddress] = true;
        _exemptFromMaxWallet[_burnAddress] = true;
        
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));
        _isExcluded[_burnAddress] = true;
        _excluded.push(_burnAddress);
        _isExcluded[msg.sender] = true;
        _excluded.push(msg.sender);
        _isExcluded[uniswapV2Pair] = true;
        _excluded.push(uniswapV2Pair);
       
        emit Transfer(address(0),  _msgSender(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

   
    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
        
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function excludeFromMaxWallet(address account) public onlyOwner {
        _exemptFromMaxWallet[account] = true;
    }
    
    function setPresaleAddress(address _presale) external onlyOwner {
        excludeFromMaxWallet(_presale);
        excludeFromFee(_presale);
        excludeFromReward(_presale);
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function includeFromMaxWallet(address account) public onlyOwner {
        _exemptFromMaxWallet[account] = false;
    }
    
    function setReflectionFeePercent(uint256 taxFee) external onlyOwner() {
        _reflectionFee = taxFee;
    }

    function setBuyFees(uint256 newDevFeePercent, uint256 newMarketingFeePercent, uint256 newDevelopmentFee, uint256 newLiquidityFee) external onlyOwner() {
        uint256 _tempDevFee = newDevFeePercent;
        uint256 _tempMarketingFee = newMarketingFeePercent;
        uint256 _tempDevelopmentFee = newDevelopmentFee;
        uint256 _tempLiquidityFee = newLiquidityFee;
        uint256 tempFees = _tempMarketingFee + _tempDevelopmentFee + _tempDevFee + _tempLiquidityFee + _reflectionFee;
        require(tempFees <= maxTaxRate, "Total Fees Cannot Be Over 40%");
        _bdevFee = newDevFeePercent;
        _bmarketingFee = newMarketingFeePercent;
        _bdevelopmentFee = newDevelopmentFee;
        _bliquidityFee = newLiquidityFee;
        _btotalBNBFees = _bmarketingFee + _bdevelopmentFee + _bdevFee + _bliquidityFee;
        _totalBNBFees = (_btotalBNBFees + _stotalBNBFees) / 2;
    }

        function setSellFees(uint256 newDevFeePercent, uint256 newMarketingFeePercent, uint256 newDevelopmentFee, uint256 newLiquidityFee) external onlyOwner() {
        uint256 _tempDevFee = newDevFeePercent;
        uint256 _tempMarketingFee = newMarketingFeePercent;
        uint256 _tempDevelopmentFee = newDevelopmentFee;
        uint256 _tempLiquidityFee = newLiquidityFee;
        uint256 tempFees = _tempMarketingFee + _tempDevelopmentFee + _tempDevFee + _tempLiquidityFee + _reflectionFee;
        require(tempFees <= maxTaxRate, "Total Fees Cannot Be Over 40%");
        _sdevFee = newDevFeePercent;
        _smarketingFee = newMarketingFeePercent;
        _sdevelopmentFee = newDevelopmentFee;
        _sliquidityFee = newLiquidityFee;
        _stotalBNBFees = _smarketingFee + _sdevelopmentFee + _sdevFee + _sliquidityFee;
        _totalBNBFees = (_btotalBNBFees + _stotalBNBFees) / 2;
    }

       function setTokensToSwap(uint256 _swap) external onlyOwner() {
        numTokensSellToAddToLiquidity = _swap * 10**9;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = (_tTotal * maxTxPercent) / 10**2;
    }
    
     function setTradingIsEnabled(bool _enabled) external onlyOwner {
        tradingIsEnabled = _enabled;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     function updateMarketingWalletAddress(address payable marketingWalletAddress) external onlyOwner() {
        _marketingWalletAddress = marketingWalletAddress;
    }
    
    function updateDevelopmentWalletAddress(address payable developmentWalletAddress) external onlyOwner() {
        _developmentWalletAddress = developmentWalletAddress;
    }
    
     function updateDevWalletAddress(address payable devWalletAddress) external onlyOwner() {
        _devWalletAddress = devWalletAddress;
    }

   	function setWalletBalance(uint256 _maxWalletBalance) external onlyOwner{
  	    maxWalletBalance = _maxWalletBalance;
  	}
 
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    function removeAllFee() private {
        if (_totalBNBFees == 0) return;
        
        _previousTotalFee = _totalBNBFees;
        _previousReflectionFee = _reflectionFee;
        
        _totalBNBFees = 0;
        _reflectionFee = 0;
    }
    
    function restoreAllFee() private {
        _totalBNBFees = _previousTotalFee;
        _reflectionFee = _previousReflectionFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
//FIX TRANSFER FUNCTION TO DO sniper protection and LAUNCH SEQUENCE Then ADD THE LAUNCH SEQUENCE CODE
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!_exemptFromMaxWallet[to]) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(balanceOf(to) + amount <= maxWalletBalance, 'Wallet balance is exceeding maxWalletBalance'); 
        }
        if (!tradingIsEnabled) {
            if (_isExcludedFromFee[from] && to == uniswapV2Pair) {
                tradingIsEnabled = true;
            } else {
                require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Liquidity not launched yet");
            }
        }
        if (from == uniswapV2Pair && !_isExcludedFromFee[from]) {
            _theseBNBFees = _btotalBNBFees;
        } else {
            _theseBNBFees = _stotalBNBFees;
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take taxfees
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 amountToSwap = contractTokenBalance;

        uint256 tokensForLP = ((amountToSwap * _advLiquidityFee) / _totalBNBFees) / 2;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(amountToSwap - tokensForLP);

        uint256 newBalance = address(this).balance - initialBalance;

        uint256 totalBNBFee = _totalBNBFees - _advLiquidityFee / 2;

        uint256 bnbToBeAddedToLiquidity = ((newBalance * _advLiquidityFee) / totalBNBFee) / 2;

        if (bnbToBeAddedToLiquidity > 0)
            addLiquidity(tokensForLP, bnbToBeAddedToLiquidity);
            
        uint256 bnbToBeAddedToDev = (newBalance * _advDevFee) / totalBNBFee;

        if (bnbToBeAddedToDev > 0)
            _devWalletAddress.transfer(bnbToBeAddedToDev);
            
        uint256 bnbToBeAddedToDevelopment = (newBalance * _advDevelopmentFee) / totalBNBFee;

        if (bnbToBeAddedToDevelopment > 0)
            _developmentWalletAddress.transfer(bnbToBeAddedToDevelopment);
            
        uint256 bnbToBeAddedToMarketing = address(this).balance;

        if (bnbToBeAddedToMarketing > 0)
            _marketingWalletAddress.transfer(bnbToBeAddedToMarketing);
        
        emit SwapAndLiquify(amountToSwap, newBalance, tokensForLP);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        _transferStandard(sender, recipient, amount);
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tReflection, uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        if (_isExcluded[sender])
            _tOwned[sender] -= tAmount;
        if (_isExcluded[recipient])
            _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        

        _takeLiquidity(tLiquidity);
        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
 function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tReflection, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValues(tAmount, tReflection, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rReflection, tTransferAmount, tReflection, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tReflection = calculateReflectionFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - (tReflection + tLiquidity);
        return (tTransferAmount, tReflection, tLiquidity);
    }
    
    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _reflectionFee) / 100;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _theseBNBFees) / 100;   
    }

    function _getRValues(uint256 tAmount, uint256 tReflection, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rReflection = tReflection * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - (rReflection + rLiquidity);
        return (rAmount, rTransferAmount, rReflection);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _reflectFee(uint256 rReflection, uint256 tReflection) private {
        _rTotal -= rReflection;
        _tFeeTotal += tReflection;
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] += rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] += tLiquidity;
    }

}