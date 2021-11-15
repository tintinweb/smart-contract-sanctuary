pragma solidity >=0.5.17 <0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';



import './../BaseStrategy.sol';
import './../../external/harvest/HarvestVault.sol';
import './../../external/harvest/HarvestStakePool.sol';
import './../../interfaces/ITransfers.sol';
import './../../Transfers.sol';
import './../ICurveEURSDeposit.sol';
import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';
import './../../enums/ProtocolEnum.sol';

/**

 **/
contract HarvestCrvEursStrategy is BaseStrategy, Transfers {
    using SafeERC20 for IERC20;
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    //crvEURS对应的金库
    address public fVault = address(0x6eb941BD065b8a5bd699C5405A928c1f561e2e5a);
    //crvEURS二次抵押对应的池子
    address public fPool = address(0xf4d50f60D53a230abc8268c6697972CB255Cd940);
    //FARM币
    IERC20 public rewardToken = IERC20(0xa0246c9032bC3A600820415aE600c6388619A14D);
    ERC20 public eursToken = ERC20(0xdB25f211AB05b1c97D595516F45794528a807ad8);
    ERC20 public eursCRVToken = ERC20(0x194eBd173F6cDacE046C53eACcE9B953F28411d1);
    // the address of the Curve protocol's pool for EURS and sEUR
    address public curveAddress = address(0x0Ce6a5fF5217e38315f87032CF90686C96627CAA);
    // 8位精度结果。其他汇率兑换：Ethereum Price Feeds https://docs.chain.link/docs/ethereum-addresses/
    address public EUR_USD = address(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);

    constructor(address _vault) public {
        initialize(_vault);
    }

    /**
     * 对应的协议 0表示harvest,1表示yearn
     **/
    function protocol() public pure override returns (uint256) {
        return uint256(ProtocolEnum.Harvest);
    }

    function name() public pure override returns (string memory) {
        return 'HarvestCrvEursStrategy';
    }

    /**
     * lpToken份额
     **/
    function balanceOfLp() internal view override returns (uint256) {
        return HarvestStakePool(fPool).balanceOf(address(this));
    }

    /**
     * lpToken精度
     **/
    function lpDecimals() internal view override returns (uint256) {
        return HarvestVault(fVault).decimals();
    }

    /**
     * 提矿 & 卖出
     * 会产矿的策略需要重写该方法
     * 返回卖矿产生的USDT数
     **/
    function claimAndSellRewards() internal override returns (uint256) {
        //子策略需先提矿
        HarvestStakePool(fPool).getReward();
        //把提到的FARM币换成USDT
        uint256 amount = rewardToken.balanceOf(address(this));
        if (amount > 0) {
            uint256 balanceBefore = want.balanceOf(address(this));
            swap(address(rewardToken), address(want), amount, 0);
            uint256 balanceAfter = want.balanceOf(address(this));
            return balanceAfter - balanceBefore;
        }

        return 0;
    }

    /**
     * 从pool中赎回fToken,再用fToken取回eursCRV
     * @param shares 要提取的最终token的数量，这里是fToken币的数量
     * @return eursCRV币的数量
     **/
    function withdrawSome(uint256 shares) internal override returns (uint256) {
        if (shares > 0) {
            //从挖矿池中赎回
            HarvestStakePool(fPool).withdraw(shares);
            //从fVault中赎回
            HarvestVault(fVault).withdraw(shares);
            uint256 amount = eursCRVToken.balanceOf(address(this));
            return amount;
        } else {
            return 0;
        }
    }

    /**
     * //TODO 尽量按照Harvest和Yearn代码来，别封装后更不可读，例如下面的ITransfers
     * 将中间代币转换成USDT，本处：eursCRV转成USDT
     * step1：通过curve将eursCRV转成EURS
     * step2：通过DEX将EURS换成USDT
     * @param tokenCount 要提取harvest里面转出来的币的数量，这里是eursCRV 的数量
     * return: USDT数量
     **/
    function exchangeToUSDT(uint256 tokenCount) internal override returns (uint256) {

        //eursCRV转成EURS
        //TODO 该方法参数需要明确什么含义，特别是第3个参数
        ICurveEURSDeposit(curveAddress).remove_liquidity_one_coin(tokenCount, 0, 0);

        //EURS转成USDT
        uint256 eursBalance = eursToken.balanceOf(address(this));
        (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
            AggregatorV3Interface(EUR_USD).latestRoundData();
        uint256 percent = 1e4 - vault.maxExchangeRateDeltaThreshold();

        uint256 miniReturn = eursBalance.mul(uint256(price).mul(percent)).div(1e9);
        uint256 returnUSDT = swap(address(eursToken), address(want), eursBalance, miniReturn);
        //返回USDT token数量
        return returnUSDT;
    }

    /**
     * 当前策略投资超额的时候，vault会调用该方法，返回超额部分的USDT给vault
     **/
    function cutOffPosition(uint256 _debtOutstanding) external override onlyVault returns (uint256) {

        //需要返还vault的USDT数量
        if (_debtOutstanding > 0) {
            uint256 _balance = want.balanceOf(address(this));
            if (_debtOutstanding <= _balance) {
                //返回给金库
                want.safeTransfer(address(vault), _debtOutstanding);
                return _debtOutstanding;
            } else {
                //还差的USDT数量
                uint256 missAmount = _debtOutstanding - _balance;
                //还需要LPToken的数量
                uint256 needLpAmount = 0;
                uint256 allAssets = estimatedTotalAssets();
                if (missAmount >= allAssets) {
                    needLpAmount = balanceOfLp();
                } else {
                    //需要解包提取的数量,按百分比提取
                    needLpAmount = missAmount.mul(balanceOfLp()).div(allAssets);
                }

                uint256 eursCRVAmount = withdrawSome(needLpAmount);
                uint256 usdtAmount = exchangeToUSDT(eursCRVAmount);
                //将余额和解包出来的USDT返回金库
                uint256 returnDebt = usdtAmount + _balance;
                want.safeTransfer(address(vault), returnDebt);
                return returnDebt;
            }
        }
        return 0;
    }

    /**
     * 将空置资金进行投资
     **/
    function investInner() internal override {
        uint256 usdtBalance = want.balanceOf(address(this));

        if (usdtBalance > 0) {
            (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
                AggregatorV3Interface(EUR_USD).latestRoundData();
            uint256 expectReturn = usdtBalance.mul(1e8).div(uint256(price));
            uint256 percent = 1e4 - vault.maxExchangeRateDeltaThreshold();

            //最小返回数，price精度为1e8,(usdt / price) * (1e9 - threshold) / (1**(9 - 8 + 4))
            uint256 miniReturn = usdtBalance.mul(percent).div(uint256(price)).div(10);
            uint256 eursAmount = swap(address(want), address(eursToken), usdtBalance, miniReturn);
        }
        uint256 eursBalance = eursToken.balanceOf(address(this));

        if (eursBalance > 0) {
            eursToken.safeApprove(curveAddress, 0);
            eursToken.safeApprove(curveAddress, eursBalance);
            ICurveEURSDeposit(curveAddress).add_liquidity([eursBalance, 0], 0);
        }
        uint256 eursCRVBalance = eursCRVToken.balanceOf(address(this));

        if (eursCRVBalance > 0) {
            eursCRVToken.safeApprove(fVault, 0);
            eursCRVToken.safeApprove(fVault, eursCRVBalance);
            HarvestVault(fVault).deposit(eursCRVBalance);
        }

        //二次抵押
        uint256 fTokenBalance = IERC20(fVault).balanceOf(address(this));

        if (fTokenBalance > 0) {
            IERC20(fVault).safeApprove(fPool, 0);
            IERC20(fVault).safeApprove(fPool, fTokenBalance);
            HarvestStakePool(fPool).stake(fTokenBalance);
        }

    }

    /**
     * 计算第三方池子的当前总资金
     **/
    function getInvestVaultAssets() external view override returns (uint256) {
        uint256 eursCRVBalance = HarvestVault(fVault).underlyingBalanceWithInvestment();
        // eurs的余额：eursCRV的余额/精度*（每个eursCRV的虚拟价格/虚拟价格的精度）*eurs的精度
        // 虚拟价格的精度1e18，curve合约未继承ERC20，但代码中配置了精度1e18
        uint256 eursBalance = eursCRVBalance.div(10 ** eursCRVToken.decimals())
        .mul(ICurveEURSDeposit(curveAddress).get_virtual_price()).div(1e18)
        .mul(10 ** eursToken.decimals());
        (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) = AggregatorV3Interface(EUR_USD).latestRoundData();
        //用预言机的汇率来转换,当前是用现实中的欧元和美元汇率
        uint256 totalAsset = eursBalance.mul(uint256(price)).div(10**4);

        return totalAsset;
    }

    function migrate(address _newStrategy) external override {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity >=0.5.17 <0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';


import './IStrategy.sol';
import '../interfaces/IVault.sol';

abstract contract BaseStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    VaultAPI public vault;

    IERC20 public want;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    uint256 public pricePerShare;
    //    uint256 lastPricePerShare;
    uint256 prevTimestamp;

    uint256 public apy = 0;

    event EmergencyExitEnabled();

    modifier onlyGovernance() {
        require(msg.sender == vault.governance(), '!only governance');
        _;
    }

    modifier onlyVault() {
        require(msg.sender == address(vault), '!only vault');
        _;
    }


    //    modifier onlyKeeper() {
    //        require(vault.isKeeper(msg.sender), '!only keeper');
    //        _;
    //    }

    /**
     * 更新apy
     **/
    function updateApy(uint256 _apy) external onlyVault {
        apy = _apy;
    }



    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyGovernance {
        emergencyExit = true;
        //        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }


    function initialize(address _vault) internal {
        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        //授权Vault可以无限操作策略中的USDT
        want.safeApprove(_vault, type(uint256).max);
    }

    function protocol() public pure virtual returns (uint256);

    function name() public pure virtual returns (string memory);

    /**
     * 评估总资产
     */
    function estimatedTotalAssets() public view virtual returns (uint256) {
        return pricePerShare.mul(balanceOfLp().div(10 ** lpDecimals()));
    }

    /**
     * 提矿 & 卖出
     * 会产矿的策略需要重写该方法
     * 返回卖矿产生的USDT数
     **/
    function claimAndSellRewards() internal virtual returns (uint256) {
        //子策略需先提矿
        //卖矿换成USDT
        return 0;
    }

    /**
     * correspondingShares：待提取xToken数
     * totalShares：总xToken数
     **/
    function withdrawToVault(uint256 correspondingShares, uint256 totalShares) external onlyVault virtual returns (uint256 value, uint256 partialClaimValue, uint256 claimValue)  {
        //根据correspondingShares/totalShares，计算待提取lpToken数量-withdrawLpTokensCount
        uint256 totalLpCount = balanceOfLp();

        //* 1 ** lpDecimals();
        uint256 withdrawLpTokensCount = totalLpCount.mul(correspondingShares).div(totalShares);

        if (withdrawLpTokensCount > 0) {
            uint256 preTotalAssets = estimatedTotalAssets();
            //从3rd Vault(Pool)中赎回-valueOfLpTokens
            uint256 tokenCount = withdrawSome(withdrawLpTokensCount);

            //兑换成USDT
            uint256 valueOfLpTokens = exchangeToUSDT(tokenCount);

            //提矿卖出
            uint256 totalRewards = claimAndSellRewards();
            uint256 partialRewards = totalRewards.mul(correspondingShares).div(totalShares);

            uint256 lastPricePerShare = pricePerShare;
            //算出单个lpToken的价值：singleValueOfLpToken = (valueOfFarms + valueOfLpTokens)/withdrawLpTokensCount
            pricePerShare = valueOfLpTokens.mul(10 ** lpDecimals()).div(withdrawLpTokensCount);
            if (preTotalAssets > 0 && pricePerShare > lastPricePerShare) {
                //                uint256 deltaOfPricePerShare = pricePerShare - lastPricePerShare;
                //目前apy定义为uint，所以只有差值大于0才更新
                uint256 deltaSeconds = block.timestamp - prevTimestamp;
                uint256 oneYear = 31536000;
                uint256 totalAssets = estimatedTotalAssets() + totalRewards + valueOfLpTokens;


                //                apy = deltaOfPricePerShare.mul(oneYear).div(deltaSeconds).div(lastPricePerShare);
                uint256 deltaOfAssets = totalAssets - preTotalAssets;
                apy = deltaOfAssets.mul(oneYear).mul(1e4).div(deltaSeconds).div(preTotalAssets);

            }

            //将用户赎回份额的USDT转给Vault
            want.safeTransfer(address(vault), totalRewards + valueOfLpTokens);
            prevTimestamp = block.timestamp;


            return (valueOfLpTokens, partialRewards, totalRewards);
        }
        return (0, 0, 0);
    }

    /**
     * 无人提取时，通过调用该方法计算策略净值
     **/
    function withdrawOneToken() external onlyVault virtual returns (uint256 value, uint256 partialClaimValue, uint256 claimValue) {
        uint256 totalLpCount = balanceOfLp();
        if (totalLpCount >= 10 ** uint256(lpDecimals())) {
            uint256 tokenCount = withdrawSome(10 ** uint256(lpDecimals()));
            //兑换成USDT
            uint256 valueOfLpTokens = exchangeToUSDT(tokenCount);

            //提矿卖出
            uint256 totalRewards = claimAndSellRewards();


            //算出单个lpToken的价值：singleValueOfLpToken = (valueOfFarms + valueOfLpTokens)/withdrawLpTokensCount
            pricePerShare = valueOfLpTokens;

            want.safeTransfer(address(vault), valueOfLpTokens + totalRewards);
            //按比例从提矿收益中算出一份lpToken对应的价值-partialRewards
            uint256 oneOfRewards = totalRewards.mul(10 ** uint256(lpDecimals())).div(balanceOfLp());

            return (valueOfLpTokens, oneOfRewards, totalRewards);
        }
        return (0, 0, 0);
    }

    /**
     * 退回超出部分金额
     **/
    function cutOffPosition(uint256 _debtOutstanding) external virtual returns (uint256);

    /**
     * 将空置资金进行投资
     **/
    function invest() public onlyVault {
        uint256 beforeInvest = balanceOfLp();
        uint256 wantBalance = want.balanceOf(address(this));
        investInner();
        uint256 afterInvest = balanceOfLp();
        if (beforeInvest == 0 && afterInvest > 0) {
            pricePerShare = wantBalance.mul(10 ** lpDecimals()).div(afterInvest);
            prevTimestamp = block.timestamp;

        }
    }

    function investInner() internal virtual;

    //策略迁移
    function migrate(address _newStrategy) external virtual;

    //查看策略投资池子的总数量（priced in want）
    function getInvestVaultAssets() external view virtual returns (uint256);

    /**
     * lpToken份额
     **/
    function balanceOfLp() internal view virtual returns (uint256);

    /**
     * lpToken精度
     **/
    function lpDecimals() internal view virtual returns (uint256);

    //    /**
    //    * 矿币精度
    //    **/
    //    function rewardDecimals() internal virtual view returns (uint256);

    /**
     * 从Vault(Pool)中赎回部分
     **/
    function withdrawSome(uint256 shares) internal virtual returns (uint256);

    /**
     * 将中间代币转换成USDT，如EURScrv转成USDT
     * step1：通过curve将EURScrv转成EURS
     * step2：通过DEX将EURS换成USDT
     * return: USDT数量
     **/
    function exchangeToUSDT(uint256 tokenCount) internal virtual returns (uint256);
}

pragma solidity ^0.8.0;

interface HarvestVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function withdrawAll() external;

    function doHardWork() external;

    function underlyingBalanceWithInvestment() view external returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function decimals() external view returns (uint256);

    function balance() external view returns (uint256);
}

pragma solidity ^0.8.0;

interface HarvestStakePool {

    function balanceOf(address account) external view returns (uint256);

    function getReward() external;

    function stake(uint256 amount) external;

    function rewardPerToken() external view returns (uint256);

    function withdraw(uint256 amount) external;

    function exit() external;
}

pragma solidity =0.8.0;

interface ITransfers {
    function swap(
        address _fromToken,
        address _destToken,
        uint256 _amount
    ) external returns (uint256 returnAmount);

    function uniSwap(address[] calldata path, uint256 _amount) external returns (uint256 returnAmount);

    function getExpectedAmount(
        address _fromToken,
        address _destToken,
        uint256 _amount
    ) external view returns (uint256);
}

pragma solidity >=0.5.17 <=0.8.0;


import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './external/oneInch/OneSplitAudit.sol';
import './external/uni/Uni.sol';

contract Transfers {
    using SafeERC20 for IERC20;

    address constant onesplit = address(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E);
//    address constant onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    address constant uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /**
     * [
     *   "Uniswap",
     *   "Kyber",
     *   "Bancor",
     *   "Oasis",
     *   "CurveCompound",
     *   "CurveUsdt",
     *   "CurveY",
     *   "Binance",
     *   "Synthetix",
     *   "UniswapCompound",
     *   "UniswapChai",
     *   "UniswapAave"
     * ]
     *   @param _fromToken will be swaped token
     *   @param _destToken you want token
     *   @param _amount will be swaped token amount
     **/
    function swap(
        address _fromToken,
        address _destToken,
        uint256 _amount,
        uint256 _miniReturn
    ) public returns (uint256) {
        if (_amount <= 0) {
            return 0;
        }
        uint256 _parts = 1;
        //拆包，最大拆100个，最小为1个
        uint256 decimals = ERC20(_fromToken).decimals();




        if (_amount / (10**decimals) / 1000 > 0) {
            _parts = 10;
        }

        // IERC20(_fromToken).safeApprove(onesplit, 0);
        // IERC20(_fromToken).safeApprove(onesplit, _amount);
        uint256[] memory _distribution;
        uint256 _expected;

        //setp 1：到交易所查询可兑换目标币的数量
        (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(
            _fromToken,
            _destToken,
            _amount,
            _parts,
            0
        );

        require(_expected >= _miniReturn,"Slippage limit exceeded!");
        if (_expected == 0) {
            return 0;
        }


        // //setp 2：把sender的源代币转入到当前地址
        // IERC20(_fromToken).safeTransferFrom(msg.sender, address(this), _amount);

        IERC20(_fromToken).safeApprove(onesplit, 0);
        IERC20(_fromToken).safeApprove(onesplit, _amount);

        //setp 3：把源代币转换为目标代币
        OneSplitAudit(onesplit).swap(_fromToken, _destToken, _amount, _expected, _distribution, 0);


        //setp 4: 把目标代币转给sender
        // IERC20(_destToken).safeTransfer(msg.sender, _expected);
        return _expected;
    }

    /**
     * @param _path 要兑换币的路由，第一个元素是输入的代币，最后一个元素是输出的代币，该数组长度至少大于等于2，
     *              如果有直接兑换的交易对的话，那就长度为2，如果没有直接兑换的交易对，需要中间代币转换的，
     *              那么长度就是大于2 。中间的元素就是需要转换的到输出代币的路由
     * @param _amount 输入代币的数量
     */
    function uniSwap(address[] calldata _path, uint256 _amount) external returns (uint256 returnAmount) {
        require(_path.length >= 2, 'path.length>=2');
        if (_amount <= 0) {
            return 0;
        }
        IERC20(_path[0]).safeApprove(uni, 0);
        IERC20(_path[0]).safeApprove(uni, _amount);
        Uni(uni).swapExactTokensForTokens(_amount, uint256(0), _path, address(this), block.timestamp + 1800);
        uint256 _wantAmount = IERC20(_path[_path.length - 1]).balanceOf(address(this));


        return _wantAmount;
    }

    /*
     * 获取预期能兑换到目标代币的数量
     */
    function getExpectedAmount(
        address _fromToken,
        address _destToken,
        uint256 _amount
    ) public view returns (uint256) {
        if (_amount <= 0) {
            return 0;
        }
        uint256 _parts = 1;
        //拆包，最大拆100个，最小为1个
        if (_amount / 100 > 0) {
            _parts = 100;
        } else if (_amount / 10 > 0) {
            _parts = 10;
        }
        uint256[] memory _distribution;
        uint256 _expected;
        (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(
            _fromToken,
            _destToken,
            _amount,
            _parts,
            0
        );
        return _expected;
    }
}

pragma solidity 0.8.0;

interface ICurveEURSDeposit {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
    external
    returns (uint256);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] calldata _min_amounts
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.8.0;

enum ProtocolEnum {
    Yearn,
    Harvest
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.5.17 <0.8.4;

interface IStrategy {

    //该策略属于的协议类型
    function protocol() external view returns (uint256);

    //该策略需要的token地址
    function want() external view returns (address);

    function name() external view returns (string memory);
    // 获取该策略对应池的apy
    function apy() external view returns (uint256);
    // 更新该策略对应池apy，留给keeper调用
    function updateApy(uint256 _apy) external;
    //该策略的vault地址
    function vault() external view returns (address);

    //    function deposit(uint256 mount) external;

    //需要提取指定数量的token,返回提取导致的loss数量token
    function withdraw(uint256 _amount) external returns (uint256);

    //计算策略的APY
    function calAPY() external returns (uint256);

    //该策略所有的资产（priced in want）
    function estimatedTotalAssets() external view returns (uint256);

    //策略迁移
    function migrate(address _newStrategy) external;

    //查看策略投资池子的总数量（priced in want）
    function getInvestVaultAssets() external view returns (uint256);

    /**
    * correspondingShares：待提取xToken数
    * totalShares：总xToken数
    **/
    function withdrawToVault(uint256 correspondingShares, uint256 totalShares) external returns  (uint256 value, uint256 partialClaimValue, uint256 claimValue) ;

    /**
    * 无人提取时，通过调用该方法计算策略净值
    **/
    function withdrawOneToken() external returns  (uint256 value, uint256 partialClaimValue, uint256 claimValue);



    /**
    * 退回超出部分金额
    **/
    function cutOffPosition(uint256 _debtOutstanding) external returns (uint256);

    /**
    * 将空置资金进行投资
    **/
    function invest() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    function isKeeper(address caller) external view returns (bool);

    function maxExchangeRateDeltaThreshold() external view returns (uint256);
}

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface OneSplitAudit {
    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags
    ) external payable;

    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) external view returns (uint256 returnAmount, uint256[] memory distribution);

    function getExpectedReturnWithGas(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        external
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}

pragma solidity =0.8.0;

interface Uni {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

