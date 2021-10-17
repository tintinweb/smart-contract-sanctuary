/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

pragma solidity ^0.8.8;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

interface IPancakeFactory {
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

/**
 * @dev Collection of functions related to the address type
 */
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

interface IAntiSnipe {
  function setTokenOwner(address owner) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external;
}

contract SafeBurnMoon is Context, Ownable {
    using Address for address;
    
    string private _name = "SafeBurnMoon";
    string private _symbol = "SBM";
    uint8 private _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    address[] private _excluded;
    mapping(address => bool) private _isExcludedFromRewards;

    mapping(address => bool) private _taxWhitelist;
    mapping(address => bool) private _liqProvWhitelist;

    address public marketingWallet;
    address public liquidityWallet;
    uint256 gnosisGas = 30000;

    uint256 private constant MAX = type(uint256).max;
    uint256 private _tTotal = 100_000_000_000 * (10 ** _decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping (address => bool) public liquidityPools;
    mapping (address => IPancakeRouter02) public markets;

    bool public swapAndLiquifyEnabled = true;
    bool public inSwap = false;

    uint256 public _taxFee = 30;
    uint256 private _previousTaxFee = _taxFee;
    uint256 public totalFeesToLP = 30;
    uint256 public totalFeesToMarketing = 25;
    uint256 public totalFeesToBurn = 10;
    uint256 public sellBias = 5;
    uint256 public previousSellBias = sellBias;

    uint256 public _liquidityFee = 65;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public minTokenNumberToSell = _tTotal / 10000;
    
    mapping (address => bool) teamMember;
    
    IAntiSnipe public antisnipe;
    uint256 public protectedFrom;
    bool public protectionEnabled = true;
    bool public liquidityLaunched = false;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier swapping() { inSwap = true; _; inSwap = false; }
    
    modifier onlyTeam() {
        require(teamMember[msg.sender] || msg.sender == owner(), "Caller is not a team member");
        _;
    }

    constructor(address _marketing, address _liquidity) {
        _tOwned[msg.sender] = _tTotal;
        _rOwned[msg.sender] = _rTotal;

        //address routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        address pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );
        liquidityPools[pancakePair] = true;
        markets[pancakePair] = pancakeRouter;

        marketingWallet = _marketing;
        liquidityWallet = _liquidity;

        _taxWhitelist[msg.sender] = true;
        _liqProvWhitelist[msg.sender] = true;
        _taxWhitelist[_marketing] = true;
        _taxWhitelist[address(this)] = true;
        
        _isExcludedFromRewards[address(this)] = true;
        _excluded.push(address(this));
        _isExcludedFromRewards[burnAddress] = true;
        _excluded.push(burnAddress);
        _isExcludedFromRewards[msg.sender] = true;
        _excluded.push(msg.sender);
        _isExcludedFromRewards[pancakePair] = true;
        _excluded.push(pancakePair);
        
        _approve(address(this), routerAddress, _tTotal);
        _approve(msg.sender, routerAddress, _tTotal);
        
        antisnipe = IAntiSnipe(0x8EFDb3b642eb2a20607ffe0A56CFefF6a95Df002);
        //antisnipe = IAntiSnipe(0xbb06F5C7689eA93d9DeACCf4aF8546C4Fe0Bf1E5);
        antisnipe.setTokenOwner(msg.sender);
        
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (_isExcludedFromRewards[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function setTeamMember(address _team, bool _enabled) external onlyOwner {
        teamMember[_team] = _enabled;
    }
    
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    function excludeFromReward(address account) public onlyTeam {
        require(
            !_isExcludedFromRewards[account],
            "Account is already excluded"
        );
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) public onlyTeam {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }


    function allowance(address _owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(rAmount <= _rTotal, "Amount must < total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function setAccountWhitelisted(address account, bool whitelisted) public onlyTeam
    {
        _taxWhitelist[account] = whitelisted;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyTeam {
        
        _taxFee = taxFee;
        _previousTaxFee = _taxFee;
    }

    function setBNBFeePercent(uint256 totalBNBFee, uint256 _marketingFee, uint256 _lpFee, uint256 _burnFee, uint256 _sellbias) external onlyTeam {
        _liquidityFee = totalBNBFee;
        _previousLiquidityFee = _liquidityFee;
        
        totalFeesToLP = _lpFee;
        totalFeesToMarketing = _marketingFee;
        totalFeesToBurn = _burnFee;
        
        sellBias = _sellbias;
        previousSellBias = sellBias;
        
        require(totalFeesToLP + totalFeesToMarketing + totalFeesToBurn <= _liquidityFee);
    }
    
    function setAmountToSell(uint256 _divisor) external onlyTeam {
        minTokenNumberToSell = _tTotal / _divisor;
    }

    function setMarketingWallet(address _newAddress) external onlyTeam {
        marketingWallet = _newAddress;
    }
    
    function setLiquidityWallet(address _newAddress) external onlyTeam {
        liquidityWallet = _newAddress;
    }

    function setLiqidityProviderWhitelisted(address _address, bool _whitelisted) external onlyTeam {
        _liqProvWhitelist[_address] = _whitelisted;
        _taxWhitelist[_address] = _whitelisted; // tax whitelists LPs to avoid tax on initial LP
        if (_whitelisted)
            excludeFromReward(_address);
        else
            includeInReward(_address);
    }

    // view function for LP whitelist address values as set above
    function getLPWhitelisted(address _account) external view returns (bool) {
        return _liqProvWhitelist[_account];
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyTeam {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function addLiquidityPool(address lp, bool isPool) external onlyTeam {
        liquidityPools[lp] = isPool;
        excludeFromReward(lp);
    }
    
    function addMarket(address _market) external onlyTeam {
        IPancakeRouter02 router = IPancakeRouter02(_market);
        address pair = IPancakeFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        liquidityPools[pair] = true;
        markets[pair] = router;
        excludeFromReward(pair);
    }

    //to receive BNB
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount, bool selling)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount, selling);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount, bool selling)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount, selling);
        uint256 tLiquidity = calculateLiquidityFee(tAmount, selling);
        uint256 tTransferAmount = tAmount - (tFee + tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - (rFee + rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() public view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }


        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 tBurn = (tLiquidity * totalFeesToBurn) / _liquidityFee;
        uint256 rBurn = tBurn * currentRate;
        tLiquidity -= tBurn;
        rLiquidity -= rBurn;
        _rOwned[address(this)] += rLiquidity;
        if (_isExcludedFromRewards[address(this)])
            _tOwned[address(this)] += tLiquidity;
        
        if (tBurn > 0) {
            _rOwned[burnAddress] += rBurn;
            if (_isExcludedFromRewards[burnAddress])
                _tOwned[burnAddress] += tBurn;
            
            emit Transfer(address(this), burnAddress, tBurn);
        }
    }

    function calculateTaxFee(uint256 _amount, bool selling) private view returns (uint256) {
        if (!selling) return 0;
        return (_amount * _taxFee) / 1000;
    }

    function calculateLiquidityFee(uint256 _amount, bool selling)
        private
        view
        returns (uint256)
    {
        return (_amount * (selling ? _liquidityFee + sellBias : _liquidityFee - sellBias )) / 1000;
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        previousSellBias = sellBias;

        _taxFee = 0;
        _liquidityFee = 0;
        sellBias = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        sellBias = previousSellBias;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _taxWhitelist[account];
    }
    
    function activateLP(bool _enabled) external onlyOwner {
    	require(protectionEnabled);
        liquidityLaunched = _enabled;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0), "BEP20: approve from zero address");
        require(spender != address(0), "BEP20: approve to zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function setProtection(IAntiSnipe _protection) external onlyTeam {
        antisnipe = _protection;
    }
    
    function setProtection(bool _enable) external onlyTeam {
        protectionEnabled = _enable;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from 0x0");
        require(to != address(0), "BEP20: transfer to 0x0");
        require(amount > 0, "Amount must be > zero");
        
        if (!liquidityLaunched) {
            if (_liqProvWhitelist[from] && liquidityPools[to]) {
                liquidityLaunched = true;
            } else {
                require(_liqProvWhitelist[from] || _liqProvWhitelist[to], "Liquidity not launched yet");
            }
        }
        
        if (shouldSwap(to)) swapAndLiquify(to);

        bool takeFee = true;

        if (_taxWhitelist[from] || _taxWhitelist[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        
        if(protectionEnabled){
            antisnipe.onPreTransferCheck(from, to, amount);
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        _transferStandard(sender, recipient, amount);

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount, liquidityPools[recipient]);
        _rOwned[sender] -= rAmount;
        if (_isExcludedFromRewards[sender])
            _tOwned[sender] -= tAmount;
        if (_isExcludedFromRewards[recipient])
            _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        if(tLiquidity > 0)
            _takeLiquidity(tLiquidity);
        if(rFee > 0 || tFee > 0)
            _reflectFee(rFee, tFee);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function shouldSwap(address to) internal view returns(bool) {
        return 
            !inSwap &&
            swapAndLiquifyEnabled &&
            balanceOf(address(this)) >= minTokenNumberToSell &&
            !liquidityPools[msg.sender] &&
            liquidityPools[to] && 
            _liquidityFee > 0;
    }
    
    function updateGnosisGas(uint256 _amount) external onlyTeam {
        gnosisGas = _amount;
    }

    function swapAndLiquify(address to) internal swapping {
        uint256 amountToSwap = minTokenNumberToSell;
        uint256 swapFees = _liquidityFee - totalFeesToBurn;

        uint256 tokensForLP = ((amountToSwap * totalFeesToLP) / swapFees) / 2;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(
            to,
            amountToSwap - tokensForLP
        );

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 totalBNBFee = swapFees - totalFeesToLP / 2;

        uint256 bnbToBeAddedToLiquidity = ((deltaBalance * totalFeesToLP) / totalBNBFee) / 2;

        if (bnbToBeAddedToLiquidity > 0)
            addLiquidity(to, liquidityWallet, tokensForLP, bnbToBeAddedToLiquidity);

        uint256 bnbToBeAddedToMarketing = address(this).balance;
        
        if (bnbToBeAddedToMarketing > 0) {
            (bool sent, bytes memory data) = marketingWallet.call{value: bnbToBeAddedToMarketing, gas: gnosisGas}("");
            require(sent, "Failed to send to marketing");
        }
        
        emit SwapAndLiquify(amountToSwap, deltaBalance, tokensForLP);
    }

    function swapTokensForEth(
        address pair,
        uint256 tokenAmount
    ) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = markets[pair].WETH();

        markets[pair].swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(
        address pair,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        markets[pair].addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner,
            block.timestamp + 360
        );
    }
	
    function airdrop(address[] calldata _addresses, uint256[] calldata _amount) external onlyTeam
    {
        require(_addresses.length == _amount.length);
        bool previousSwap = swapAndLiquifyEnabled;
        bool previousProtection = protectionEnabled;
        swapAndLiquifyEnabled = false;
        protectionEnabled = false;
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!liquidityPools[_addresses[i]]);
            _transfer(msg.sender, _addresses[i], _amount[i] * (10 ** _decimals));
        }
        swapAndLiquifyEnabled = previousSwap;
        protectionEnabled = previousProtection;
    }
}