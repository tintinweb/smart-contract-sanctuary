// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Address.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './ERC20.sol';
import './StakingPool.sol';

/**
 * @notice ERC20 token with cost basis tracking and restricted loss-taking
 */
contract DogstonksPro is ERC20, StakingPool {
  using Address for address payable;

  enum Phase { PENDING, LIQUIDITY_EVENT, OPEN, CLOSED }

  Phase public _phase;
  uint public _phaseChangedAt;

  string public override name = 'DogstonksPro (dogstonks.com)';
  string public override symbol = 'DOGPRO';

  address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address private constant DOGSTONKS = 0xC9aA1007b1619d04C1911E48A8a7a95770BE21a2;

  uint private constant SUPPLY = 1e12 ether;

  uint private constant TAX_RATE = 1000;
  uint private constant BP_DIVISOR = 10000;

  // V1 token redemption rate
  uint private constant V1_VALUE = 12.659726999081298826 ether;
  uint private constant V1_SUPPLY = 913290958465.509630323815153677 ether;

  address private _owner;
  address private _pair;

  uint private _initialBasis;

  mapping (address => uint) private _basisOf;
  mapping (address => uint) public cooldownOf;

  // credits for ETH LE deposits
  mapping (address => uint) private _lpCredits;
  uint private _lpCreditsTotal;

  // quantity of UNI-V2 tokens corresponding to initial liquidity, shared among token holders
  uint private _holderDistributionUNIV2;
  // quantity of ETH to be distributed to token holders, set after trading close
  uint private _holderDistributionETH;
  // quantity of ETH to be distributed to liquidity providers, set after trading close
  uint private _lpDistributionETH;

  // all time high
  uint private _ath;
  uint private _athTimestamp;

  // values to prevent adding liquidity directly
  address private _lastOrigin;
  uint private _lastBlock;

  bool private _nohook;

  struct Minting {
    address recipient;
    uint amount;
  }

  modifier phase (Phase p) {
    require(_phase == p, 'ERR: invalid phase');
    _;
  }

  modifier nohook () {
    _nohook = true;
    _;
    _nohook = false;
  }

  /**
   * @notice deploy
   * @param mintings structured minting data (recipient, amount)
   */
  constructor (
    Minting[] memory mintings
  ) payable {
    _owner = msg.sender;
    _phaseChangedAt = block.timestamp;

    // setup uniswap pair and store address

    _pair = IUniswapV2Factory(
      IUniswapV2Router02(UNISWAP_ROUTER).factory()
    ).createPair(WETH, address(this));

    // prepare to add/remove liquidity

    _approve(address(this), UNISWAP_ROUTER, type(uint).max);
    IERC20(_pair).approve(UNISWAP_ROUTER, type(uint).max);

    // mint team tokens

    uint mintedSupply;

    for (uint i; i < mintings.length; i++) {
      Minting memory m = mintings[i];
      uint amount = m.amount;
      address recipient = m.recipient;

      mintedSupply += amount;
      _balances[recipient] += amount;
      emit Transfer(address(0), recipient, amount);
    }

    _totalSupply = mintedSupply;
  }

  receive () external payable {}

  /**
   * @inheritdoc ERC20
   * @dev reverts if Uniswap pair holds more WETH than accounted for in reserves (suggesting liquidity is being added)
   */
  function balanceOf (
    address account
  ) override public view returns (uint) {
    if (msg.sender == _pair && tx.origin == _lastOrigin && block.number == _lastBlock) {
      (uint res0, uint res1, ) = IUniswapV2Pair(_pair).getReserves();
      require(
        (address(this) > WETH ? res0 : res1) > IERC20(WETH).balanceOf(_pair),
        'ERR: liquidity add'
      );
    }
    return super.balanceOf(account);
  }

  /**
   * @notice get cost basis for given address
   * @param account address to query
   * @return cost basis
   */
  function basisOf (
    address account
  ) public view returns (uint) {
    uint basis = _basisOf[account];

    if (basis == 0 && balanceOf(account) > 0) {
      basis = _initialBasis;
    }

    return basis;
  }

  /**
   * @notice calculate current cost basis for sale of given quantity of tokens
   * @param amount quantity of tokens sold
   * @return cost basis for sale
   */
  function basisOfSale (
    uint amount
  ) public view returns (uint) {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = WETH;

    uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsOut(
      amount,
      path
    );

    return (1 ether) * amounts[1] / amount;
  }

  /**
   * @notice calculate tax for given cost bases and sale amount
   * @param fromBasis cost basis of seller
   * @param toBasis cost basis for sale
   * @param amount quantity of tokens sold
   * @return tax amount
   */
  function taxFor (
    uint fromBasis,
    uint toBasis,
    uint amount
  ) public pure returns (uint) {
    return amount * (toBasis - fromBasis) / toBasis * TAX_RATE / BP_DIVISOR;
  }

  /**
   * @notice enable liquidity event participation
   */
  function openLiquidityEvent () external phase(Phase.PENDING) {
    require(
      msg.sender == _owner || block.timestamp > _phaseChangedAt + (2 weeks),
      'ERR: sender must be owner'
    );

    _incrementPhase();

    // track lp credits to be used for distribution

    _lpCredits[address(this)] = address(this).balance;
    _lpCreditsTotal += address(this).balance;

    // add liquidity

    _mint(address(this), SUPPLY - totalSupply());

    IUniswapV2Router02(
      UNISWAP_ROUTER
    ).addLiquidityETH{
      value: address(this).balance
    }(
      address(this),
      balanceOf(address(this)),
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  /**
   * @notice buy in to liquidity event using DOGSTONKS V1 tokens
   */
  function contributeV1 () external {
    require(_phase == Phase.LIQUIDITY_EVENT || _phase == Phase.OPEN, 'ERR: invalid phase');

    uint amount = IERC20(DOGSTONKS).balanceOf(msg.sender);
    IERC20(DOGSTONKS).transferFrom(msg.sender, DOGSTONKS, amount);

    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(this);

    uint[] memory amounts = IUniswapV2Router02(
      UNISWAP_ROUTER
    ).getAmountsOut(
      amount * V1_VALUE / V1_SUPPLY,
      path
    );

    // credit sender with deposit

    _mintTaxCredit(msg.sender, amounts[1]);
  }

  /**
   * @notice buy in to liquidity event using ETH
   */
  function contributeETH () external payable phase(Phase.LIQUIDITY_EVENT) nohook {
    if (block.timestamp < _phaseChangedAt + (15 minutes)) {
      // at beginning of LE, only V1 depositors and team token holders may contribute
      require(
        taxCreditsOf(msg.sender) >= 1e6 ether || balanceOf(msg.sender) > 0,
        'ERR: must contribute V1 tokens'
      );
    }

    // add liquidity via purchase to simulate price action by purchasing tokens

    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = address(this);

    uint[] memory amounts = IUniswapV2Router02(
      UNISWAP_ROUTER
    ).swapExactETHForTokens{
      value: msg.value
    }(
      0,
      path,
      msg.sender,
      block.timestamp
    );

    _transfer(msg.sender, _pair, amounts[1]);
    IUniswapV2Pair(_pair).sync();

    // credit sender with deposit

    _mintTaxCredit(msg.sender, amounts[1]);
    _lpCredits[msg.sender] += msg.value;
    _lpCreditsTotal += msg.value;
  }

  /**
   * @notice open trading
   * @dev sender must be owner
   * @dev trading must not yet have been opened
   */
  function open () external phase(Phase.LIQUIDITY_EVENT) {
    require(
      msg.sender == _owner || block.timestamp > _phaseChangedAt + (1 hours),
      'ERR: sender must be owner'
    );

    _incrementPhase();

    // set initial cost basis

    _initialBasis = (1 ether) * IERC20(WETH).balanceOf(_pair) / balanceOf(_pair);

    // calculate proportion of UNI-V2 tokens for distribution

    _holderDistributionUNIV2 = IERC20(_pair).totalSupply() * _lpCredits[address(this)] / _lpCreditsTotal;
  }

  /**
   * @notice add Uniswap liquidity
   * @param amount quantity of DOGPRO to add
   */
  function addLiquidity (
    uint amount
  ) external payable phase(Phase.OPEN) {
    _transfer(msg.sender, address(this), amount);

    uint liquidityETH = IERC20(WETH).balanceOf(_pair);

    (uint amountToken, uint amountETH, ) = IUniswapV2Router02(
      UNISWAP_ROUTER
    ).addLiquidityETH{
      value: msg.value
    }(
      address(this),
      amount,
      0,
      0,
      address(this),
      block.timestamp
    );

    if (amountToken < amount) {
      _transfer(address(this), msg.sender, amount - amountToken);
    }

    if (amountETH < msg.value) {
      payable(msg.sender).sendValue(msg.value - amountETH);
    }

    uint lpCreditsDelta = _lpCreditsTotal * amountETH / liquidityETH;
    _lpCredits[msg.sender] += lpCreditsDelta;
    _lpCreditsTotal += lpCreditsDelta;

    _mintTaxCredit(msg.sender, amountToken);
  }

  /**
   * @notice close trading
   * @dev trading must not yet have been closed
   * @dev minimum time since open must have elapsed
   */
  function close () external phase(Phase.OPEN) {
    require(block.timestamp > _phaseChangedAt + (1 days), 'ERR: too soon');

    _incrementPhase();

    require(
      block.timestamp > _athTimestamp + (1 weeks),
      'ERR: recent ATH'
    );

    uint univ2 = IERC20(_pair).balanceOf(address(this));

    (uint amountToken, ) = IUniswapV2Router02(
      UNISWAP_ROUTER
    ).removeLiquidityETH(
      address(this),
      univ2,
      0,
      0,
      address(this),
      block.timestamp
    );

    _burn(address(this), amountToken);

    // split liquidity between holders and liquidity providers

    _holderDistributionETH = address(this).balance * _holderDistributionUNIV2 / univ2;
    _lpDistributionETH = address(this).balance - _holderDistributionETH;

    // stop tracking LP credit for original deposit

    _lpCreditsTotal -= _lpCredits[address(this)];
    delete _lpCredits[address(this)];
  }

  /**
   * @notice exchange DOGPRO for proportion of ETH in contract
   * @dev trading must have been closed
   */
  function liquidate () external phase(Phase.CLOSED) {
    // claim tax rewards

    if (taxCreditsOf(msg.sender) > 0) {
      _transfer(address(this), msg.sender, taxRewardsOf(msg.sender));
      _burnTaxCredit(msg.sender);
    }

    // calculate share of holder rewards

    uint balance = balanceOf(msg.sender);
    uint holderPayout;

    if (balance > 0) {
      holderPayout = _holderDistributionETH * balance / totalSupply();
      _holderDistributionETH -= holderPayout;
      _burn(msg.sender, balance);
    }

    // calculate share of liquidity

    uint lpCredits = _lpCredits[msg.sender];
    uint lpPayout;

    if (lpCredits > 0) {
      lpPayout = _lpDistributionETH * lpCredits / _lpCreditsTotal;
      _lpDistributionETH -= lpPayout;

      delete _lpCredits[msg.sender];
      _lpCreditsTotal -= lpCredits;
    }

    payable(msg.sender).sendValue(holderPayout + lpPayout);
  }

  /**
   * @notice withdraw remaining ETH from contract
   * @dev trading must have been closed
   * @dev minimum time since close must have elapsed
   */
  function liquidateUnclaimed () external phase(Phase.CLOSED) {
    require(block.timestamp > _phaseChangedAt + (52 weeks), 'ERR: too soon');
    payable(_owner).sendValue(address(this).balance);
  }

  /**
   * @notice update contract phase and track timestamp
   */
  function _incrementPhase () private {
    _phase = Phase(uint8(_phase) + 1);
    _phaseChangedAt = block.timestamp;
  }

  /**
   * @notice ERC20 hook: enforce transfer restrictions and cost basis; collect tax
   * @param from tranfer sender
   * @param to transfer recipient
   * @param amount quantity of tokens transferred
   */
  function _beforeTokenTransfer (
    address from,
    address to,
    uint amount
  ) override internal {
    super._beforeTokenTransfer(from, to, amount);

    if (_nohook) return;

    // ignore minting and burning
    if (from == address(0) || to == address(0)) return;

    // ignore add/remove liquidity
    if (from == address(this) || to == address(this)) return;
    if (from == UNISWAP_ROUTER || to == UNISWAP_ROUTER) return;

    require(uint8(_phase) >= uint8(Phase.OPEN));

    require(
      msg.sender == UNISWAP_ROUTER || msg.sender == _pair,
      'ERR: sender must be uniswap'
    );
    require(amount <= 5e9 ether /* revert message not returned by Uniswap */);

    if (from == _pair) {
      require(cooldownOf[to] < block.timestamp /* revert message not returned by Uniswap */);
      cooldownOf[to] = block.timestamp + (5 minutes);

      address[] memory path = new address[](2);
      path[0] = WETH;
      path[1] = address(this);

      uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsIn(
        amount,
        path
      );

      uint balance = balanceOf(to);
      uint fromBasis = (1 ether) * amounts[0] / amount;
      _basisOf[to] = (fromBasis * amount + basisOf(to) * balance) / (amount + balance);

      if (fromBasis > _ath) {
        _ath = fromBasis;
        _athTimestamp = block.timestamp;
      }
    } else if (to == _pair) {
      _lastOrigin = tx.origin;
      _lastBlock = block.number;

      require(cooldownOf[from] < block.timestamp /* revert message not returned by Uniswap */);
      cooldownOf[from] = block.timestamp + (5 minutes);

      uint fromBasis = basisOf(from);
      uint toBasis = basisOfSale(amount);

      require(fromBasis <= toBasis /* revert message not returned by Uniswap */);

      // collect tax
      uint tax = taxFor(fromBasis, toBasis, amount);
      _transfer(from, address(this), tax);
      _distributeTax(tax);
    }
  }
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

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

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
     * - `account` cannot be the zero address.
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract StakingPool {
  uint private constant SCALE = 1e18;
  uint private _rewardPerToken;
  mapping (address => uint) private _rewardsAccounted;
  mapping (address => uint) private _rewardsSkipped;

  // credits for tax distribution
  mapping (address => uint) private _taxCredits;
  uint private _taxCreditsTotal;

  function taxCreditsOf (
    address account
  ) public view returns (uint) {
    return _taxCredits[account];
  }

  function taxRewardsOf (
    address account
  ) public view returns (uint) {
    return (_taxCredits[account] * _rewardPerToken + _rewardsAccounted[account] - _rewardsSkipped[account]) / SCALE;
  }

  function _distributeTax (
    uint amount
  ) internal {
    _rewardPerToken += amount * SCALE / _taxCreditsTotal;
  }

  function _mintTaxCredit (
    address account,
    uint amount
  ) internal {
    uint skipped = taxCreditsOf(account) * _rewardPerToken;
    _rewardsAccounted[account] += skipped - _rewardsSkipped[account];
    _rewardsSkipped[account] = skipped - amount * _rewardPerToken;

    _taxCredits[account] += amount;
    _taxCreditsTotal += amount;
  }

  function _burnTaxCredit (
    address account
  ) internal {
    _taxCreditsTotal -= _taxCredits[account];
    delete _taxCredits[account];
  }
}

pragma solidity >=0.6.2;

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

