// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IOpenOracleFramework} from "./interfaces/IOpenOracleFramework.sol";
import "./lib/FixedPoint.sol";
import "./interfaces/IEtherCollateral.sol";

/// @author Conjure Finance Team
/// @title Conjure
/// @notice Contract to define and track the price of an arbitrary synth
contract Conjure is IERC20, ReentrancyGuard {

    // using Openzeppelin contracts for SafeMath and Address
    using SafeMath for uint256;
    using Address for address;
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    // presenting the total supply
    uint256 internal _totalSupply;

    // representing the name of the token
    string internal _name;

    // representing the symbol of the token
    string internal _symbol;

    // representing the decimals of the token
    uint8 internal constant DECIMALS = 18;

    // a record of balance of a specific account by address
    mapping(address => uint256) private _balances;

    // a record of allowances for a specific address by address to address mapping
    mapping(address => mapping(address => uint256)) private _allowances;

    // the owner of the contract
    address payable public _owner;

    // the type of the arb asset (single asset, arb asset)
    // 0... single asset     (uses median price)
    // 1... basket asset     (uses weighted average price)
    // 2... index asset      (uses token address and oracle to get supply and price and calculates supply * price / divisor)
    // 3 .. sqrt index asset (uses token address and oracle to get supply and price and calculates sqrt(supply * price) / divisor)
    uint256 public _assetType;

    // the address of the collateral contract factory
    address public _factoryContract;

    // the address of the collateral contract
    address public _collateralContract;

    // struct for oracles
    struct _oracleStruct {
        address oracleaddress;
        address tokenaddress;
        // 0... chainLink, 1... UniSwap T-wap, 2... custom
        uint256 oracleType;
        string signature;
        bytes calldatas;
        uint256 weight;
        uint256 decimals;
        uint256 values;
    }

    // array for oracles
    _oracleStruct[] public _oracleData;

    // number of oracles
    uint256 public _numoracles;

    // the latest observed price
    uint256 internal _latestobservedprice;

    // the latest observed price timestamp
    uint256 internal _latestobservedtime;

    // the divisor for the index
    uint256 public _indexdivisor;

    // the modifier if the asset type is an inverse type
    bool public _inverse;

    // shows the init state of the contract
    bool public _inited;

    // the modifier if the asset type is an inverse type
    uint256 public _deploymentPrice;

    // maximum decimal size for the used prices
    uint256 private constant MAXIMUM_DECIMALS = 18;

    // The number representing 1.0
    uint256 private constant UNIT = 10**18;

    // the eth usd price feed oracle address
    address public ethUsdOracle;

    // lower boundary for inverse assets (10% of deployment price)
    uint256 public inverseLowerCap;

    // ========== EVENTS ==========
    event NewOwner(address newOwner);
    event Issued(address indexed account, uint256 value);
    event Burned(address indexed account, uint256 value);
    event AssetTypeSet(uint256 value);
    event IndexDivisorSet(uint256 value);
    event PriceUpdated(uint256 value);
    event InverseSet(bool value);
    event NumOraclesSet(uint256 value);

    // only owner modifier
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view
    function _onlyOwner() private view {
        require(msg.sender == _owner, "Only the contract owner may perform this action");
    }

    constructor() {
        // Don't allow implementation to be initialized.
        _factoryContract = address(1);
    }

    /**
     * @dev initializes the clone implementation and the Conjure contract
     *
     * @param nameSymbol array holding the name and the symbol of the asset
     * @param conjureAddresses array holding the owner, indexed UniSwap oracle and ethUsdOracle address
     * @param factoryAddress_ the address of the factory
     * @param collateralContract the EtherCollateral contract of the asset
    */
    function initialize(
        string[2] memory nameSymbol,
        address[] memory conjureAddresses,
        address factoryAddress_,
        address collateralContract
    ) external
    {
        require(_factoryContract == address(0), "already initialized");
        require(factoryAddress_ != address(0), "factory can not be null");
        require(collateralContract != address(0), "collateralContract can not be null");

        _owner = payable(conjureAddresses[0]);
        _name = nameSymbol[0];
        _symbol = nameSymbol[1];

        ethUsdOracle = conjureAddresses[1];
        _factoryContract = factoryAddress_;

        // mint new EtherCollateral contract
        _collateralContract = collateralContract;

        emit NewOwner(_owner);
    }

    /**
     * @dev inits the conjure asset can only be called by the factory address
     *
     * @param inverse_ indicated it the asset is an inverse asset or not
     * @param divisorAssetType array containing the divisor and the asset type
     * @param oracleAddresses_ the array holding the oracle addresses 1. address to call,
     *        2. address of the token for supply if needed
     * @param oracleTypesValuesWeightsDecimals array holding the oracle types,values,weights and decimals
     * @param signatures_ array holding the oracle signatures
     * @param callData_ array holding the oracle callData
    */
    function init(
        bool inverse_,
        uint256[2] memory divisorAssetType,
        address[][2] memory oracleAddresses_,
        uint256[][4] memory oracleTypesValuesWeightsDecimals,
        string[] memory signatures_,
        bytes[] memory callData_
    ) external {
        require(msg.sender == _factoryContract, "can only be called by factory contract");
        require(!_inited, "Contract already inited");
        require(divisorAssetType[0] != 0, "Divisor should not be 0");

        _assetType = divisorAssetType[1];
        _numoracles = oracleAddresses_[0].length;
        _indexdivisor = divisorAssetType[0];
        _inverse = inverse_;
        
        emit AssetTypeSet(_assetType);
        emit IndexDivisorSet(_indexdivisor);
        emit InverseSet(_inverse);
        emit NumOraclesSet(_numoracles);

        uint256 weightCheck;

        // push the values into the oracle struct for further processing
        for (uint i = 0; i < oracleAddresses_[0].length; i++) {
            require(oracleTypesValuesWeightsDecimals[3][i] <= 18, "Decimals too high");
            _oracleData.push(_oracleStruct({
                oracleaddress: oracleAddresses_[0][i],
                tokenaddress: oracleAddresses_[1][i],
                oracleType: oracleTypesValuesWeightsDecimals[0][i],
                signature: signatures_[i],
                calldatas: callData_[i],
                weight: oracleTypesValuesWeightsDecimals[2][i],
                values: oracleTypesValuesWeightsDecimals[1][i],
                decimals: oracleTypesValuesWeightsDecimals[3][i]
            }));

            weightCheck += oracleTypesValuesWeightsDecimals[2][i];
        }

        // for basket assets weights must add up to 100
        if (_assetType == 1) {
            require(weightCheck == 100, "Weights not 100");
        }

        updatePrice();
        _deploymentPrice = getLatestPrice();

        // for inverse assets set boundaries
        if (_inverse) {
            inverseLowerCap = _deploymentPrice.div(10);
        }

        _inited = true;
    }

    /**
     * @dev lets the EtherCollateral contract instance burn synths
     *
     * @param account the account address where the synths should be burned to
     * @param amount the amount to be burned
    */
    function burn(address account, uint amount) external {
        require(msg.sender == _collateralContract, "Only Collateral Contract");
        _internalBurn(account, amount);
    }

    /**
     * @dev lets the EtherCollateral contract instance mint new synths
     *
     * @param account the account address where the synths should be minted to
     * @param amount the amount to be minted
    */
    function mint(address account, uint amount) external {
        require(msg.sender == _collateralContract, "Only Collateral Contract");
        _internalIssue(account, amount);
    }

    /**
     * @dev Internal function to mint new synths
     *
     * @param account the account address where the synths should be minted to
     * @param amount the amount to be minted
    */
    function _internalIssue(address account, uint amount) internal {
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
        emit Issued(account, amount);
    }

    /**
     * @dev Internal function to burn synths
     *
     * @param account the account address where the synths should be burned to
     * @param amount the amount to be burned
    */
    function _internalBurn(address account, uint amount) internal {
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
        emit Burned(account, amount);
    }

    /**
     * @dev lets the owner change the contract owner
     *
     * @param _newOwner the new owner address of the contract
    */
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "_newOwner can not be null");
    
        _owner = _newOwner;
        emit NewOwner(_newOwner);
    }

    /**
     * @dev lets the owner collect the fees accrued
    */
    function collectFees() external onlyOwner {
        _owner.transfer(address(this).balance);
    }

    /**
     * @dev gets the latest price of an oracle asset
     * uses chainLink oracles to get the price
     *
     * @return the current asset price
    */
    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint) {
        (
        ,
        int price,
        ,
        ,
        ) = priceFeed.latestRoundData();

        return uint(price);
    }

    /**
     * @dev gets the latest ETH USD Price from the given oracle OOF contract
     * getFeed 0 signals the ETH/USD feed
     *
     * @return the current eth usd price
    */
    function getLatestETHUSDPrice() public view returns (uint) {
        (
        uint price,
        ,
        ) = IOpenOracleFramework(ethUsdOracle).getFeed(0);

        return price;
    }

    /**
    * @dev implementation of a quicksort algorithm
    *
    * @param arr the array to be sorted
    * @param left the left outer bound element to start the sort
    * @param right the right outer bound element to stop the sort
    */
    function quickSort(uint[] memory arr, int left, int right) internal pure {
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
    * @dev implementation to get the average value of an array
    *
    * @param arr the array to be averaged
    * @return the (weighted) average price of an asset
    */
    function getAverage(uint[] memory arr) internal view returns (uint) {
        uint sum = 0;

        // do the sum of all array values
        for (uint i = 0; i < arr.length; i++) {
            sum += arr[i];
        }
        // if we dont have any weights (single asset with even array members)
        if (_assetType == 0) {
            return (sum / arr.length);
        }
        // index pricing we do division by divisor
        if ((_assetType == 2) || (_assetType == 3)) {
            return sum / _indexdivisor;
        }
        // divide by 100 cause the weights sum up to 100 and divide by the divisor if set (defaults to 1)
        return ((sum / 100) / _indexdivisor);
    }

    /**
    * @dev sort implementation which calls the quickSort function
    *
    * @param data the array to be sorted
    * @return the sorted array
    */
    function sort(uint[] memory data) internal pure returns (uint[] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    /**
    * @dev implementation of a square rooting algorithm
    * babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    *
    * @param y the value to be square rooted
    * @return z the square rooted value
    */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = (y + 1) / 2;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        else {
            z = 0;
        }
    }

    /**
     * @dev gets the latest recorded price of the synth in USD
     *
     * @return the last recorded synths price
    */
    function getLatestPrice() public view returns (uint) {
        return _latestobservedprice;
    }

    /**
     * @dev gets the latest recorded price time
     *
     * @return the last recorded time of a synths price
    */
    function getLatestPriceTime() external view returns (uint) {
        return _latestobservedtime;
    }

    /**
     * @dev gets the latest price of the synth in USD by calculation and write the checkpoints for view functions
    */
    function updatePrice() public {
        uint256 returnPrice = updateInternalPrice();
        bool priceLimited;

        // if it is an inverse asset we do price = _deploymentPrice - (current price - _deploymentPrice)
        // --> 2 * deployment price - current price
        // but only if the asset is inited otherwise we return the normal price calculation
        if (_inverse && _inited) {
            if (_deploymentPrice.mul(2) <= returnPrice) {
                returnPrice = 0;
            } else {
                returnPrice = _deploymentPrice.mul(2).sub(returnPrice);

                // limit to lower cap
                if (returnPrice <= inverseLowerCap) {
                    priceLimited = true;
                }
            }
        }

        _latestobservedprice = returnPrice;
        _latestobservedtime = block.timestamp;

        emit PriceUpdated(_latestobservedprice);

        // if price reaches 0 we close the collateral contract and no more loans can be opened
        if ((returnPrice <= 0) || (priceLimited)) {
            IEtherCollateral(_collateralContract).setAssetClosed(true);
        } else {
            // if the asset was set closed we open it again for loans
            if (IEtherCollateral(_collateralContract).getAssetClosed()) {
                IEtherCollateral(_collateralContract).setAssetClosed(false);
            }
        }
    }

    /**
     * @dev gets the latest price of the synth in USD by calculation --> internal calculation
     *
     * @return the current synths price
    */
    function updateInternalPrice() internal returns (uint) {
        require(_oracleData.length > 0, "No oracle feeds supplied");
        // storing all in an array for further processing
        uint[] memory prices = new uint[](_oracleData.length);

        for (uint i = 0; i < _oracleData.length; i++) {

            // chainLink oracle
            if (_oracleData[i].oracleType == 0) {
                AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracleData[i].oracleaddress);
                prices[i] = getLatestPrice(priceFeed);

                // norming price
                if (MAXIMUM_DECIMALS != _oracleData[i].decimals) {
                    prices[i] = prices[i] * 10 ** (MAXIMUM_DECIMALS - _oracleData[i].decimals);
                }
            }

            // custom oracle and UniSwap
            else {
                string memory signature = _oracleData[i].signature;
                bytes memory callDatas = _oracleData[i].calldatas;

                bytes memory callData;

                if (bytes(signature).length == 0) {
                    callData = callDatas;
                } else {
                    callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), callDatas);
                }

                (bool success, bytes memory data) = _oracleData[i].oracleaddress.call{value:_oracleData[i].values}(callData);
                require(success, "Call unsuccessful");

                // UniSwap V2 use NDX Custom Oracle call
                if (_oracleData[i].oracleType == 1) {
                    FixedPoint.uq112x112 memory price = abi.decode(data, (FixedPoint.uq112x112));

                    // since this oracle is using token / eth prices we have to norm it to usd prices
                    prices[i] = price.mul(getLatestETHUSDPrice()).decode144();
                }
                else {
                    prices[i] = abi.decode(data, (uint));

                    // norming price
                    if (MAXIMUM_DECIMALS != _oracleData[i].decimals) {
                        prices[i] = prices[i] * 10 ** (MAXIMUM_DECIMALS - _oracleData[i].decimals);
                    }
                }
            }

            // for market cap and sqrt market cap asset types
            if (_assetType == 2 || _assetType == 3) {
                // get total supply for indexes
                uint tokenTotalSupply = IERC20(_oracleData[i].tokenaddress).totalSupply();
                uint tokenDecimals = IERC20(_oracleData[i].tokenaddress).decimals();

                // norm total supply
                if (MAXIMUM_DECIMALS != tokenDecimals) {
                    require(tokenDecimals <= 18, "Decimals too high");
                    tokenTotalSupply = tokenTotalSupply * 10 ** (MAXIMUM_DECIMALS - tokenDecimals);
                }

                // index use market cap
                if (_assetType == 2) {
                    prices[i] = (prices[i].mul(tokenTotalSupply) / UNIT);
                }

                // sqrt market cap
                if (_assetType == 3) {
                    // market cap
                    prices[i] =prices[i].mul(tokenTotalSupply) / UNIT;
                    // sqrt market cap
                    prices[i] = sqrt(prices[i]);
                }
            }

            // if we have a basket asset we use weights provided
            if (_assetType == 1) {
                prices[i] = prices[i] * _oracleData[i].weight;
            }
        }

        uint[] memory sorted = sort(prices);

        /// for single assets return median
        if (_assetType == 0) {

            // uneven so we can take the middle
            if (sorted.length % 2 == 1) {
                uint sizer = (sorted.length + 1) / 2;

                return sorted[sizer-1];
            // take average of the 2 most inner numbers
            } else {
                uint size1 = (sorted.length) / 2;
                uint[] memory sortedMin = new uint[](2);

                sortedMin[0] = sorted[size1-1];
                sortedMin[1] = sorted[size1];

                return getAverage(sortedMin);
            }
        }

        // else return average for arb assets
        return getAverage(sorted);
    }

    /**
     * ERC 20 Specific Functions
    */

    /**
    * receive function to receive funds
    */
    receive() external payable {}

    /**
     * @dev Returns the name of the token.
     */
    function name() external override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external override view returns (string memory) {
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
    function decimals() external override pure returns (uint8) {
        return DECIMALS;
    }

    /**
    * @dev See {IERC20-totalSupply}.
    */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See {IERC20-balanceOf}. Uses burn abstraction for balance updates without gas and universally.
    */
    function balanceOf(address account) external override view returns (uint256) {
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
    external
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
    external
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
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address src, address dst, uint256 rawAmount) external override returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = _allowances[src][spender];
        uint256 amount = rawAmount;

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(
                amount,
                    "CONJURE::transferFrom: transfer amount exceeds spender allowance"
            );

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
    )
        internal
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * @dev Interface of the OpenOracleFramework contract
 */
interface IOpenOracleFramework {
    /**
    * @dev initialize function lets the factory init the cloned contract and set it up
    *
    * @param signers_ array of signer addresses
    * @param signerThreshold_ the threshold which has to be met for consensus
    * @param payoutAddress_ the address where all fees will be sent to. 0 address for an even split across signers
    * @param subscriptionPassPrice_ the price for an oracle subscription pass
    * @param factoryContract_ the address of the factory contract
    */
    function initialize(
        address[] memory signers_,
        uint256 signerThreshold_,
        address payable payoutAddress_,
        uint256 subscriptionPassPrice_,
        address factoryContract_
    ) external;

    /**
    * @dev getHistoricalFeeds function lets the caller receive historical values for a given timestamp
    *
    * @param feedIDs the array of feedIds
    * @param timestamps the array of timestamps
    */
    function getHistoricalFeeds(uint256[] memory feedIDs, uint256[] memory timestamps) external view returns (uint256[] memory);

    /**
    * @dev getFeeds function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedIDs the array of feedIds
    */
    function getFeeds(uint256[] memory feedIDs) external view returns (uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    * @dev getFeed function lets anyone call the oracle to receive data (maybe pay an optional fee)
    *
    * @param feedID the array of feedId
    */
    function getFeed(uint256 feedID) external view returns (uint256, uint256, uint256);

    /**
    * @dev getFeedList function returns the metadata of a feed
    *
    * @param feedIDs the array of feedId
    */
    function getFeedList(uint256[] memory feedIDs) external view returns(string[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    * @dev withdrawFunds function sends the collected fees to the given address
    */
    function withdrawFunds() external;

    /**
    * @dev creates new oracle data feeds
    *
    * @param names the names of the new feeds
    * @param descriptions the description of the new feeds
    * @param decimals the decimals of the new feeds
    * @param timeslots the timeslots of the new feeds
    * @param feedCosts the costs of the new feeds
    * @param revenueModes the revenue modes of the new feeds
    */
    function createNewFeeds(string[] memory names, string[] memory descriptions, uint256[] memory decimals, uint256[] memory timeslots, uint256[] memory feedCosts, uint256[] memory revenueModes) external;

    /**
    * @dev submits multiple feed values
    *
    * @param feedIDs the array of feedId
    * @param values the values to submit
    */
    function submitFeed(uint256[] memory feedIDs, uint256[] memory values) external;

    /**
    * @dev signs a given proposal
    *
    * @param proposalId the id of the proposal
    */
    function signProposal(uint256 proposalId) external;

    /**
    * @dev creates a new proposal
    *
    * @param uintValue value in uint representation
    * @param addressValue value in address representation
    * @param proposalType type of the proposal
    * @param feedId the feed id if needed
    */
    function createProposal(uint256 uintValue, address addressValue, uint256 proposalType, uint256 feedId) external;

    /**
    * @dev buys a subscription to a feed
    *
    * @param feedIDs the feeds to subscribe to
    * @param durations the durations to subscribe
    * @param buyer the address which should be subscribed to the feeds
    */
    function subscribeToFeed(uint256[] memory feedIDs, uint256[] memory durations, address buyer) payable external;

    /**
    * @dev buys a subscription pass for the oracle
    *
    * @param buyer the address which owns the pass
    * @param duration the duration to subscribe
    */
    function buyPass(address buyer, uint256 duration) payable external;

    /**
    * @dev supports given Feeds
    *
    * @param feedIds the array of feeds to support
    * @param values the array of amounts of ETH to send to support
    */
    function supportFeeds(uint256[] memory feedIds, uint256[] memory values) payable external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IEtherCollateral
/// @notice Interface for interacting with the EtherCollateral Contract
interface IEtherCollateral {

    /**
     * @dev Sets the assetClosed indicator if loan opening is allowed or not
     * Called by the Conjure contract if the asset price reaches 0.
    */
    function setAssetClosed(bool) external;

    /**
     * @dev Gets the assetClosed indicator
    */
    function getAssetClosed() external view returns (bool);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}