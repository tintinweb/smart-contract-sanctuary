// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Ownable} from "./roles/Ownable.sol";


interface IFeed
{
  function latestAnswer() external view returns (int256);
}

interface IOracle
{
  function getRate(address from, address to) external view returns (uint256);

  function convertFromUSD(address to, uint256 amount) external view returns (uint256);

  function convertToUSD(address from, uint256 amount) external view returns (uint256);

  function convert(address from, address to, uint256 amount) external view returns (uint256);
}

contract Oracle is IOracle, Ownable
{
  using SafeMath for uint256;


  address private constant _DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address private constant _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  uint256 private constant _DECIMALS = 1e18;

  mapping(address => address) private _ETHFeeds;
  mapping(address => address) private _USDFeeds;


  constructor()
  {
    // address INCH = 0x111111111117dC0aa78b770fA6A738034120C302;
    // address AMPL = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;
    // address BNT = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;
    // address AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    // address ANT = 0xa117000000f279D81A1D3cc75430fAA017FA5A2e;
    // address BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    // address BAND = 0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55;
    // address BAT = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
    // address COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    // address CREAM = 0x2ba592F78dB6436527729929AAf6c908497cB200;
    // address CRO = 0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b;
    // address CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    // address ENJ = 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c;
    // address GRT = 0xc944E90C64B2c07662A292be6244BDf05Cda44a7;
    // address KNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    // address KEEPER = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
    // address LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    // address LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    // address MANA = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
    // address MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    // address REN = 0x408e41876cCCDC0F92210600ef50372656052a38;
    // address SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    // address SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    // address SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    // address TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
    // address UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    // address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // address WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    // address YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    // address ZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

    _ETHFeeds[_DAI] = address(0x773616E4d11A78F511299002da57A0a94577F1f4);
    _ETHFeeds[0x111111111117dC0aa78b770fA6A738034120C302] = address(0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8);
    _ETHFeeds[0xD46bA6D942050d489DBd938a2C909A5d5039A161] = address(0x492575FDD11a0fCf2C6C719867890a7648d526eB);
    _ETHFeeds[0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C] = address(0xCf61d1841B178fe82C8895fe60c2EDDa08314416);
    _ETHFeeds[0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9] = address(0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012);
    _ETHFeeds[0xa117000000f279D81A1D3cc75430fAA017FA5A2e] = address(0x8f83670260F8f7708143b836a2a6F11eF0aBac01);
    _ETHFeeds[0xba100000625a3754423978a60c9317c58a424e3D] = address(0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b);
    _ETHFeeds[0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55] = address(0x0BDb051e10c9718d1C29efbad442E88D38958274);
    _ETHFeeds[0x0D8775F648430679A709E98d2b0Cb6250d2887EF] = address(0x0d16d4528239e9ee52fa531af613AcdB23D88c94);
    _ETHFeeds[0xc00e94Cb662C3520282E6f5717214004A7f26888] = address(0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699);
    _ETHFeeds[0x2ba592F78dB6436527729929AAf6c908497cB200] = address(0x82597CFE6af8baad7c0d441AA82cbC3b51759607);
    _ETHFeeds[0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b] = address(0xcA696a9Eb93b81ADFE6435759A29aB4cf2991A96);
    _ETHFeeds[0xD533a949740bb3306d119CC777fa900bA034cd52] = address(0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e);
    _ETHFeeds[0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c] = address(0x24D9aB51950F3d62E9144fdC2f3135DAA6Ce8D1B);
    _ETHFeeds[0xc944E90C64B2c07662A292be6244BDf05Cda44a7] = address(0x17D054eCac33D91F7340645341eFB5DE9009F1C1);
    _ETHFeeds[0xdd974D5C2e2928deA5F71b9825b8b646686BD200] = address(0x656c0544eF4C98A6a98491833A89204Abb045d6b);
    _ETHFeeds[0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44] = address(0xe7015CCb7E5F788B8c1010FC22343473EaaC3741);
    _ETHFeeds[0x514910771AF9Ca656af840dff83E8264EcF986CA] = address(0xDC530D9457755926550b59e8ECcdaE7624181557);
    _ETHFeeds[0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD] = address(0x160AC928A16C93eD4895C2De6f81ECcE9a7eB7b4);
    _ETHFeeds[0x0F5D2fB29fb7d3CFeE444a200298f468908cC942] = address(0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9);
    _ETHFeeds[0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2] = address(0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2);
    _ETHFeeds[0x408e41876cCCDC0F92210600ef50372656052a38] = address(0x3147D7203354Dc06D9fd350c7a2437bcA92387a4);
    _ETHFeeds[0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F] = address(0x79291A9d692Df95334B1a0B3B4AE6bC606782f8c);
    _ETHFeeds[0x57Ab1ec28D129707052df4dF418D58a2D46d5f51] = address(0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757);
    _ETHFeeds[0x6B3595068778DD592e39A122f4f5a5cF09C90fE2] = address(0xe572CeF69f43c2E488b33924AF04BDacE19079cf);
    _ETHFeeds[0x0000000000085d4780B73119b644AE5ecd22b376] = address(0x3886BA987236181D98F2401c507Fb8BeA7871dF2);
    _ETHFeeds[0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984] = address(0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e);
    _ETHFeeds[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = address(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
    _ETHFeeds[0xdAC17F958D2ee523a2206206994597C13D831ec7] = address(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46);
    _ETHFeeds[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = address(0xdeb288F737066589598e9214E782fa5A8eD689e8);
    _ETHFeeds[0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e] = address(0x7c5d4F8345e66f68099581Db340cd65B078C41f4);
    _ETHFeeds[0xE41d2489571d322189246DaFA5ebDe1F4699F498] = address(0x2Da4983a622a8498bb1a21FaE9D8F6C664939962);

    _USDFeeds[_WETH] = address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
  }

  function getFeeds(address token) external view returns (address, address)
  {
    return (_ETHFeeds[token], _USDFeeds[token]);
  }

  function setFeeds(address[] calldata tokens, address[] calldata feeds, bool is_USDFeeds) external onlyOwner
  {
    require(tokens.length == feeds.length, "!=");

    if (is_USDFeeds)
    {
      for (uint256 i = 0; i < tokens.length; i++)
      {
        address token = tokens[i];

        _USDFeeds[token] = feeds[i];
      }
    }
    else
    {
      for (uint256 i = 0; i < tokens.length; i++)
      {
        address token = tokens[i];

        _ETHFeeds[token] = feeds[i];
      }
    }
  }


  function uintify(int256 val) private pure returns (uint256)
  {
    require(val > 0, "Feed err");

    return uint256(val);
  }

  function getTokenETHRate(address token) private view returns (uint256)
  {
    if (_ETHFeeds[token] != address(0))
    {
      return uintify(IFeed(_ETHFeeds[token]).latestAnswer());
    }
    else if (_USDFeeds[token] != address(0))
    {
      return uintify(IFeed(_USDFeeds[token]).latestAnswer()).mul(_DECIMALS).div(uintify(IFeed(_USDFeeds[_WETH]).latestAnswer()));
    }
    else
    {
      return 0;
    }
  }

  function getRate(address from, address to) public view override returns (uint256)
  {
    if (from == to && to == _DAI)
    {
      return _DECIMALS;
    }

    uint256 srcRate = from == _WETH ? _DECIMALS : getTokenETHRate(from);
    uint256 destRate = to == _WETH ? _DECIMALS : getTokenETHRate(to);

    require(srcRate > 0 && destRate > 0 && srcRate < type(uint256).max && destRate < type(uint256).max, "No oracle");

    return srcRate.mul(_DECIMALS).div(destRate);
  }

  function calcDestQty(uint256 srcQty, address from, address to, uint256 rate) private view returns (uint256)
  {
    uint256 srcDecimals = ERC20(from).decimals();
    uint256 destDecimals = ERC20(to).decimals();

    uint256 difference;

    if (destDecimals >= srcDecimals)
    {
      difference = 10 ** destDecimals.sub(srcDecimals);

      return srcQty.mul(rate).mul(difference).div(_DECIMALS);
    }
    else
    {
      difference = 10 ** srcDecimals.sub(destDecimals);

      return srcQty.mul(rate).div(_DECIMALS.mul(difference));
    }
  }

  function convertFromUSD(address to, uint256 amount) external view override returns (uint256)
  {
    return calcDestQty(amount, _DAI, to, getRate(_DAI, to));
  }

  function convertToUSD(address from, uint256 amount) external view override returns (uint256)
  {
    return calcDestQty(amount, from, _DAI, getRate(from, _DAI));
  }

  function convert(address from, address to, uint256 amount) external view override returns (uint256)
  {
    return calcDestQty(amount, from, to, getRate(from, to));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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
pragma solidity 0.7.6;


contract Ownable
{
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner()
  {
    require(isOwner(), "!owner");
    _;
  }

  constructor()
  {
    _owner = msg.sender;

    emit OwnershipTransferred(address(0), msg.sender);
  }

  function owner() public view returns (address)
  {
    return _owner;
  }

  function isOwner() public view returns (bool)
  {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner
  {
    emit OwnershipTransferred(_owner, address(0));

    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner
  {
    require(newOwner != address(0), "0 addy");

    emit OwnershipTransferred(_owner, newOwner);

    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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