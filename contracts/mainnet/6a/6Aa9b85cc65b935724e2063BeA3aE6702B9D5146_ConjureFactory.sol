// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./lib/FixedPoint.sol";

contract Conjure is IERC20, ReentrancyGuard {

    /// @notice using Openzeppelin contracts for SafeMath and Address
    using SafeMath for uint256;
    using Address for address;
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    /// @notice presenting the total supply
    uint256 private _totalSupply;

    /// @notice representing the name of the token
    string private _name;

    /// @notice representing the symbol of the token
    string private _symbol;

    /// @notice representing the decimals of the token
    uint8 private immutable _decimals = 18;

    /// @notice a record of balance of a specific account by address
    mapping(address => uint256) private _balances;

    /// @notice a record of allowances for a specific address by address to address mapping
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice the owner and creator of the contract
    address payable public _owner;

    /// @notice the owner of the CONJURE factory
    address public _factoryaddress;

    /// @notice the type of the arb asset (single asset, arb asset) (0... single, 1... arb, 2... index mcap, 3 ... sqrt mcap)
    uint8 public _assetType;

    /// @notice the address of the collateral contract factory
    address public _collateralFactory;

    /// @notice the address of the collateral contract
    address public _collateralContract;

    /// @notice shows the init state of the contract
    bool public _inited;

    /// @notice struct for oracles
    struct _oracleStruct {
        address oracleaddress;
        /// 0... chainlink, 1... uniswap twap, 2... custom
        uint oracleType;
        string signature;
        bytes calldatas;
        uint256 weight;
        uint256 decimals;
        uint256 values;
    }

    /// @notice array for oracles
    _oracleStruct[] public _oracleData;

    /// @notice number of aracles
    uint256 public _numoracles;

    /// @notice deployed uniswap v2 oracle instance
    UniswapV2OracleInterface public _uniswapv2oracle;

    /// @notice the latest observed price
    uint256 public _latestobservedprice;

    /// @notice the latest observed price timestamp
    uint256 public _latestobservedtime;

    /// @notice the divisor for the index
    uint256 public _indexdivisor = 1;

    /// @notice constant for hourly observation
    uint256 HOUR = 3600;

    /// @notice maximum decimal size for the used prices
    uint256 public _maximumDecimals = 18;

    /* The number representing 1.0. */
    uint public  UNIT = 10**uint(_maximumDecimals);

    /// @notice the eth usd price feed chainlink oracle address
    //chainlink eth/usd mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    //chainlink eth/usd rinkeby: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    AggregatorV3Interface public ethusdchainlinkoracle = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    constructor (
        string memory name_,
        string memory symbol_,
        address payable owner_,
        address factoryaddress_,
        address uniswapv2oracle,
        address collateralfactory_
    )
    public {
        _owner = owner_;
        _factoryaddress = factoryaddress_;
        _totalSupply = 0;
        _name = name_;
        _symbol = symbol_;

        _uniswapv2oracle = UniswapV2OracleInterface(uniswapv2oracle);
        _collateralFactory = collateralfactory_;

        _balances[_owner] = _totalSupply;
        _inited = false;

        emit Transfer(address(0), _owner, _totalSupply);
    }

    /**
    * @dev Public init function to set up the contract with pricing sources
    *
    */
    function init(
        uint256 mintingFee_,
        uint8 assetType_,
        uint256 indexdivisor_,
        address[] memory oracleAddresses_,
        uint8[] memory oracleTypes_,
        string[] memory signatures_,
        bytes[] memory calldata_,
        uint256[] memory values_,
        uint256[] memory weights_,
        uint256[] memory decimals_
    ) public
    {
        require(msg.sender == _owner);
        require(_inited == false);
        require(indexdivisor_ != 0);

        _collateralContract = IEtherCollateralFactory(_collateralFactory).EtherCollateralMint(payable(address(this)), _owner, _factoryaddress, mintingFee_);
        _assetType = assetType_;
        _numoracles = oracleAddresses_.length;
        _indexdivisor = indexdivisor_;

        // push the values into the oracle struct for further processing
        for (uint i = 0; i < oracleAddresses_.length; i++) {
            _oracleStruct memory temp_struct;
            temp_struct.oracleaddress = oracleAddresses_[i];
            temp_struct.oracleType = oracleTypes_[i];
            temp_struct.signature = signatures_[i];
            temp_struct.calldatas = calldata_[i];
            temp_struct.weight = weights_[i];
            temp_struct.values = values_[i];
            temp_struct.decimals = decimals_[i];
            _oracleData.push(temp_struct);

            require(decimals_[i] <= 18);
        }

        getPrice();
        _inited = true;
    }

    function setEthUsdChainlinkOracle(address neworacle) public
    {
        require (msg.sender == _owner);
        AggregatorV3Interface newagg = AggregatorV3Interface(neworacle);
        ethusdchainlinkoracle = newagg;
    }

    function setUniswapOracle(address newunioracle) public
    {
        require (msg.sender == _owner);
        UniswapV2OracleInterface newagg = UniswapV2OracleInterface(newunioracle);
        _uniswapv2oracle = newagg;
    }

    /**
    * @dev Public burn function can only be called from the collateral contract
    *
    */
    function burn(address account, uint amount) public
    {
        require(msg.sender == _collateralContract);
        _internalBurn(account, amount);
    }

    /**
    * @dev Public mint function can only be called from the collateral contract
    *
    */
    function mint(address account, uint amount) public
    {
        require(msg.sender == _collateralContract);
        _internalIssue(account, amount);
    }

    /**
    * @dev internal mint function issues tokens to the given account
    *
    */
    function _internalIssue(address account, uint amount) internal {
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
        emit Issued(account, amount);
    }

    /**
    * @dev internal burn function burns tokens from the given account
    *
    */
    function _internalBurn(address account, uint amount) internal {
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
        emit Burned(account, amount);
    }

    /**
     * @dev lets the owner change the owner
     */
    function changeOwner(address payable _newOwner) public {
        require(msg.sender == _owner);
        address oldOwner = _owner;
        _owner = _newOwner;
        emit NewOwner(oldOwner, _owner);
    }

    /**
     * @dev lets the owner collect the collected fees
     */
    function collectFees() public {
        require(msg.sender == _owner);
        uint256 contractBalalance = address(this).balance;

        _owner.transfer(contractBalalance);
    }

    /**
    * Returns the latest price of an oracle asset
    */
    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (int) {
        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * Gets the ETH USD price from chainlink oracle
    */
    function getLatestETHUSDPrice() public view returns (int) {

        AggregatorV3Interface priceFeed = ethusdchainlinkoracle;

        (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        uint decimals = priceFeed.decimals();
        uint tempprice = uint(price) * 10 ** (_maximumDecimals - decimals);

        return int(tempprice);
    }

    /**
    * quicksort implementation
    */
    function quickSort(uint[] memory arr, int left, int right) public pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

    /**
    * Avg implementation
    */
    function getAverage(uint[] memory arr) internal view returns (uint) {
        uint sum = 0;

        for (uint i = 0; i < arr.length; i++) {
            sum += arr[i];
        }

        // if we dont have any weights
        if (_assetType == 0)
        {
            return (sum / arr.length);
        }

        // index pricing
        if (_assetType == 2)
        {
            return sum / _indexdivisor;
        }
        if (_assetType == 3)
        {
            return sum / _indexdivisor;
        }

        // divide by total weight
        return ((sum / 100) / _indexdivisor);
    }

    /**
    * Sort Function
    */
    function sort(uint[] memory data) public pure returns (uint[] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    // sqrt function
    function sqrt(uint256 y) internal view returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = (y + 1) / 2;
            while (x < z) {
                z = x;
                x = (y.mul(UNIT).div(x) + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }

    function getLatestPrice() public view returns (uint) {
        return _latestobservedprice;
    }

    /**
    * Returns the price for the arb asset (median price of the 5 assets)
    */
    function getPrice() public returns (uint) {

        // storing all in an array for further processing
        uint[] memory prices = new uint[](_oracleData.length);

        for (uint i = 0; i < _oracleData.length; i++) {

            // chainlink oracle
            if (_oracleData[i].oracleType == 0)
            {
                AggregatorV3Interface pricefeed = AggregatorV3Interface(_oracleData[i].oracleaddress);
                uint price = uint(getLatestPrice(pricefeed));
                prices[i] = price;

                // norming price
                if (_maximumDecimals != _oracleData[i].decimals)
                {
                    prices[i] = prices[i] * 10 ** (_maximumDecimals - _oracleData[i].decimals);
                }

                if (_assetType == 1)
                {
                    prices[i] = prices[i] * _oracleData[i].weight;
                }
            }

            // uniswap TWAP
            if (_oracleData[i].oracleType == 1)
            {
                // check if update price needed
                if (_uniswapv2oracle.canUpdatePrice(_oracleData[i].oracleaddress) == true)
                {
                    // update price
                    _uniswapv2oracle.updatePrice(_oracleData[i].oracleaddress);
                }

                // since this oracle is using token / eth prices we have to norm it to usd prices
                uint currentethtusdprice = uint(getLatestETHUSDPrice());

                // grab latest price after update decode
                FixedPoint.uq112x112 memory price = _uniswapv2oracle.computeAverageTokenPrice(_oracleData[i].oracleaddress,0, HOUR * 24 * 10);
                prices[i] = price.mul(currentethtusdprice).decode144();

                // get total supply for indexes
                uint totalsupply = IERC20(_oracleData[i].oracleaddress).totalSupply();

                // norming price
                if (_maximumDecimals != _oracleData[i].decimals)
                {
                    prices[i] = prices[i] * 10 ** (_maximumDecimals - _oracleData[i].decimals);
                    totalsupply = totalsupply * 10 ** (_maximumDecimals - _oracleData[i].decimals);
                }

                if (_assetType == 1)
                {
                    prices[i] = prices[i] * _oracleData[i].weight;
                }

                // index
                if (_assetType == 2)
                {
                    prices[i] = (prices[i].mul(totalsupply) / UNIT);
                }

                // sqrt mcap
                if (_assetType == 3)
                {
                    // mcap
                    prices[i] =prices[i].mul(totalsupply) / UNIT;
                    // sqrt mcap
                    uint256 sqrt_mcap = sqrt(prices[i]);
                    prices[i] = sqrt_mcap;
                }
            }

            // custom oracle
            if (_oracleData[i].oracleType == 2)
            {
                address contractaddress = _oracleData[i].oracleaddress;
                string memory signature = _oracleData[i].signature;
                bytes memory calldatas = _oracleData[i].calldatas;
                uint256 callvalue = _oracleData[i].values;

                bytes memory callData;

                if (bytes(signature).length == 0) {
                    callData = calldatas;
                } else {
                    callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), calldatas);
                }

                (bool success, bytes memory data) = contractaddress.call{value:callvalue}(callData);
                require(success);

                uint  price = abi.decode(data, (uint));
                prices[i] = price;

                // norming price
                if (_maximumDecimals != _oracleData[i].decimals)
                {
                    prices[i] = prices[i] * 10 ** (_maximumDecimals - _oracleData[i].decimals);
                }

                if (_assetType == 1)
                {
                    prices[i] = prices[i] * _oracleData[i].weight;
                }
            }
        }

        uint[] memory sorted = sort(prices);

        /// for single assets return median
        if (_assetType == 0)
        {
            uint modulo = sorted.length % 2;

            // uneven so we can take the middle
            if (modulo == 1)
            {
                uint sizer = (sorted.length + 1) / 2;

                _latestobservedprice = sorted[sizer-1];
                _latestobservedtime = block.timestamp;
                return sorted[sizer-1];
            }
            // take average of the 2 most inner numbers
            else
            {
                uint size1 = (sorted.length) / 2;
                uint size2 = size1 + 1;

                uint arrsize1 = sorted[size1-1];
                uint arrsize2 = sorted[size2-1];

                uint[] memory sortedmin = new uint[](2);
                sortedmin[0] = arrsize1;
                sortedmin[1] = arrsize2;

                _latestobservedprice = getAverage(sortedmin);
                _latestobservedtime = block.timestamp;
                return getAverage(sortedmin);
            }
        }

        /// else return avarage for arb assets
        _latestobservedprice = getAverage(sorted);
        _latestobservedtime = block.timestamp;

        return getAverage(sorted);
    }

    ///
    /// ERC20 specific functions
    ///

    /**
    * fallback function for collection funds
    */
    fallback() external payable {

    }

    receive() external payable {

    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
    * @dev See {IERC20-totalSupply}.
    */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See {IERC20-balanceOf}. Uses burn abstraction for balance updates without gas and universally.
    */
    function balanceOf(address account) public override view returns (uint256) {
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
    function transfer(address dst, uint256 rawAmount) external override returns (bool) {
        uint256 amount = rawAmount;
        _transfer(msg.sender, dst, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    override
    view
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
    {
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
     * - `sender` and `recipient` cannot be the zero ress.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address src, address dst, uint256 rawAmount) external override returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = _allowances[src][spender];
        uint256 amount = rawAmount;

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(amount, "CONJURE::transferFrom: transfer amount exceeds spender allowance");
            _allowances[src][spender] = newAllowance;
        }

        _transfer(src, dst, amount);
        return true;
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    // ========== EVENTS ==========
    event NewOwner(address oldOwner, address newOwner);
    event FeeChanged(uint8 oldFee, uint8 newFee);
    event Issued(address indexed account, uint value);
    event Burned(address indexed account, uint value);
}

contract ConjureFactory {
    event NewConjureContract(address deployed);
    event FactoryOwnerChanged(address newowner);
    address payable public factoryOwner;

    constructor() public {
        factoryOwner = msg.sender;
    }

    function getFactoryOwner() public view returns (address payable)
    {
        return factoryOwner;
    }

    /**
     * @dev lets anyone mint a new CONJURE contract
     */
    function ConjureMint(
        string memory name_,
        string memory symbol_,
        address payable owner_,
        address uniswapv2oracle_,
        address collateralfactory_
    ) public returns(address) {
        Conjure newContract = new Conjure(
            name_,
            symbol_,
            owner_,
            address(this),
            uniswapv2oracle_,
            collateralfactory_
        );
        emit NewConjureContract(address(newContract));
        return address(newContract);
    }

    /**
     * @dev Lets the Factory Owner change the current owner
     */
    function newFactoryOwner(address payable newOwner) public {
        require(msg.sender == factoryOwner);
        factoryOwner = newOwner;
        emit FactoryOwnerChanged(factoryOwner);
    }
}

interface UniswapV2OracleInterface {
    function computeAverageTokenPrice(
        address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
    ) external view returns (FixedPoint.uq112x112 memory);

    function computeAverageEthPrice(
        address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
    ) external view returns (FixedPoint.uq112x112 memory);

    function updatePrice(address token) external returns (bool);

    function canUpdatePrice(address token) external returns (bool);
}

interface IEtherCollateralFactory {
    function EtherCollateralMint(address payable asset_, address owner_, address factoryaddress_, uint256 mintingfeerate_) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


/************************************************************************************************
From https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/FixedPoint.sol

Copied from the github repository at commit hash 9642a0705fdaf36b477354a4167a8cd765250860.

Modifications:
- Removed `sqrt` function

Subject to the GPL-3.0 license
*************************************************************************************************/


// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(
            y == 0 || (z = uint(self._x) * y) / y == uint(self._x),
            "FixedPoint: MULTIPLICATION_OVERFLOW"
        );
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }
}