// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

// import {IERC20 as UNIERC20} from "@uniswap/v2-core/contracts/interfaces/IERC20.sol";

contract FleepToken is ERC20 {

    //state of token
    enum State {
        INITIAL,
        ACTIVE
    }

    State public state = State.INITIAL;

    function getState() public view returns (State) {
        return state;
    }

    function enableToken() public {
        state = State.ACTIVE;
    }

    function disableToken() public {
        state = State.INITIAL;
    }

    function setState(uint256 _value) public {
        require(uint256(State.ACTIVE) >= _value);
        require(uint256(State.INITIAL) <= _value);
        state = State(_value);
    }

    function requireActiveState() view internal {
        require(state == State.ACTIVE, 'Require token enable trading');
    }

    address public owner = msg.sender;
    address public devWallet;
    address public rewardWallet;
    uint256 initialTime;
    uint256 initialPrice; // 1.5$ * 10 ** 18
    //price feed uniswap
    //if useFeedPrice == false, don't apply tax for token
    bool public useFeedPrice = false;
    address public pairFeedPrice;
    bool public isToken0;
    // tax control list
    mapping(address => bool) applyTaxList;
    mapping(address => bool) ignoreTaxList;

    //define event
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // modifier control
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    constructor(
        address _devWallet,
        address _rewardWallet,
        // bool _isToken0,
        uint256 _initialTime,
        uint256 _initialPrice
    ) payable ERC20("Fleep Token", "FLEEP") {
        //initital total supply is 1000.000 tokens
        devWallet = _devWallet;
        rewardWallet = _rewardWallet;
        _mint(msg.sender, 600000 * 10**decimals());
        _mint(devWallet, 200000 * 10**decimals());
        _mint(rewardWallet, 200000 * 10**decimals());
        //-- data feed
        pairFeedPrice = address(0);
        isToken0 = false;
        //-- end datafeed
        initialTime = _initialTime;
        // explore
        initialPrice = _initialPrice;
        ignoreTaxList[devWallet] = true;
        ignoreTaxList[rewardWallet] = true;
    }

    // modify transfer function to check tax effect
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        //tax here
        address from = _msgSender();
        uint256 finalAmount = amount;
        if (
            ignoreTaxList[from] == true || ignoreTaxList[recipient] == true
        ) {} else if (
            applyTaxList[from] == true && applyTaxList[recipient] == true
        ) {
            // not apply tax
            // do nothings
        } else if (applyTaxList[from] == true) {
            if (useFeedPrice) {
                int256 deviant = getDeviant();
                // if from Effect => user buy token from LP
                // [to] buy token, so [to] will receive reward
                (uint256 pct, uint256 base) = getBuyerRewardPercent(deviant);
                uint256 rewardForBuyer = (amount * pct) / (base * 100);
                // finalAmount = finalAmount - rewardForBuyer;
                _transfer(rewardWallet, recipient, rewardForBuyer);
            }
        } else if (applyTaxList[recipient] == true) {
            if (useFeedPrice) {
                //check max sell token
                require(finalAmount <= getMaxSellable(), "Final amount over max sellable amount");
                int256 deviant = getDeviant();
                // if [to] effect (example: [to] is LP Pool) => [from] sell token
                (uint256 pct, uint256 base) = getTaxPercent(deviant);
                (uint256 pctReward, uint256 baseReward) = getRewardPercent(
                    deviant
                );
                uint256 tax = (amount * pct) / (base * 100);
                uint256 taxToReward = (amount * pctReward) / (baseReward * 100);
                require(finalAmount > tax, "tax need smaller than amount");
                require(tax > taxToReward, "tax need bigger than taxToReward");
                finalAmount = finalAmount - tax;
                _transfer(_msgSender(), rewardWallet, taxToReward);
                _transfer(_msgSender(), devWallet, tax - taxToReward);
            }
        } else {
            // do nothings
        }
        //end
        //validate state
        if (ignoreTaxList[from] != true && ignoreTaxList[recipient] != true) {
            requireActiveState();
        }
        //end
        _transfer(_msgSender(), recipient, finalAmount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 finalAmount = amount;
        address from = sender;
        if (
            ignoreTaxList[from] == true || ignoreTaxList[recipient] == true
        ) {} else if (
            applyTaxList[from] == true && applyTaxList[recipient] == true
        ) {
            // not apply tax
            // do nothings
        } else if (applyTaxList[from] == true) {
            if (useFeedPrice) {
                int256 deviant = getDeviant();
                // if from Effect => user buy token from LP
                // [to] buy token, so [to] will receive reward
                (uint256 pct, uint256 base) = getBuyerRewardPercent(deviant);
                uint256 rewardForBuyer = (amount * pct) / (base * 100);
                // finalAmount = finalAmount - rewardForBuyer;
                _transfer(rewardWallet, recipient, rewardForBuyer);
            }
        } else if (applyTaxList[recipient] == true) {
            if (useFeedPrice) {
                //check max sell token
                require(finalAmount <= getMaxSellable(), "Final amount over max sellable amount");
                int256 deviant = getDeviant();
                // if [to] effect (example: [to] is LP Pool) => [from] sell token
                (uint256 pct, uint256 base) = getTaxPercent(deviant);
                (uint256 pctReward, uint256 baseReward) = getRewardPercent(
                    deviant
                );
                uint256 tax = (amount * pct) / (base * 100);
                uint256 taxToReward = (amount * pctReward) / (baseReward * 100);
                require(
                    balanceOf(sender) >= (amount + tax),
                    "Out of token becase tax apply"
                );
                // require(finalAmount > tax, "tax need smaller than amount");
                require(tax > taxToReward, "tax need bigger than taxToReward");
                finalAmount = finalAmount - tax;
                _transfer(sender, rewardWallet, taxToReward);
                _transfer(sender, devWallet, tax - taxToReward);
            }
        } else {
            // do nothings
        }
        //validate state
        if (ignoreTaxList[from] != true && ignoreTaxList[recipient] != true) {
            requireActiveState();
        }
        //end
        return super.transferFrom(sender, recipient, amount);
    }

    function changeInitialTimestamp(uint256 _initialTimestamp)
        public
        onlyOwner
        returns (bool)
    {
        initialTime = _initialTimestamp;
        return true;
    }

    function changeInitialPeggedPrice(uint256 _initialPrice)
        public
        onlyOwner
        returns (bool)
    {
        initialPrice = _initialPrice;
        return true;
    }

    function setUseFeedPrice(bool _useFeedPrice) public onlyOwner {
        useFeedPrice = _useFeedPrice;
    }

    function setPairForPrice(address _pairFeedPrice, bool _isToken0)
        public
        onlyOwner
    {
        pairFeedPrice = _pairFeedPrice;
        isToken0 = _isToken0;
    }

    //apply tax list
    function addToApplyTaxList(address _address) public onlyOwner {
        applyTaxList[_address] = true;
    }

    function removeApplyTaxList(address _address) public onlyOwner {
        applyTaxList[_address] = false;
    }

    function isApplyTaxList(address _address) public view returns (bool) {
        return applyTaxList[_address];
    }

    //ignore tax list
    function addToIgnoreTaxList(address _address) public onlyOwner {
        ignoreTaxList[_address] = true;
    }

    function removeIgnoreTaxList(address _address) public onlyOwner {
        ignoreTaxList[_address] = false;
    }

    function isIgnoreTaxList(address _address) public view returns (bool) {
        return ignoreTaxList[_address];
    }

    // calculate price based on pair reserves
    // numberToken0 x price0 = numberToken1 x price1
    function getTokenPrice(
        address _pairAddress,
        bool _isToken0,
        uint256 amount
    ) public view returns (uint256) {
        if (_isToken0) {
            return getToken0Price(_pairAddress, amount);
        } else {
            return getToken1Price(_pairAddress, amount);
        }
    }

    function getTokenPrice() public view returns (uint256) {
        if (isToken0) {
            return getToken0Price(pairFeedPrice, 1);
        } else {
            return getToken1Price(pairFeedPrice, 1);
        }
    }

    function getMaxSellable() public view returns (uint256) {
        if (isToken0) {
            return getMaxSellable0(pairFeedPrice);
        } else {
            return getMaxSellable1(pairFeedPrice);
        }
    }

    function getMaxSellable0(address pairAddress)
        internal
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, , ) = pair.getReserves();
        return Res0 * 10 / 100;
    }

    function getMaxSellable1(address pairAddress)
        internal
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (, uint256 Res1, ) = pair.getReserves();
        return Res1 * 10 / 100;
    }

    function getToken1Price(address pairAddress, uint256 amount)
        internal
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        ERC20 token1 = ERC20(pair.token1());
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        // decimals
        uint256 res0 = Res0 * (10**token1.decimals());
        return ((amount * res0) / Res1);
        // result = (price_1 /price_0) *  (10 ** token0.decimals())
    }

    /**
    return price of token 0 wall calculate by price of token 1 and GWEN of token 1
     */
    function getToken0Price(address pairAddress, uint256 amount)
        internal
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        ERC20 token0 = ERC20(pair.token0());
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        //(Res0 / token0.decimals()) * price0 = (Res1 / token1.decimals()) * price1
        return (amount * Res1 * (10**token0.decimals())) / Res0;
        // result = (price_0 /price_1) *  (10 ** token1.decimals())
    }

    uint256 SECOND_PER_DAY = 86400; //24 * 60 * 60;
    uint256 private A = 0;
    uint256 private perA  = 1;
    uint256 private B  = 0;
    uint256 private perB  = 1;

    function setRate(uint256 _A, uint256 _perA, uint256 _B, uint256 _perB)
        public
        onlyOwner
    {
        //change initial price and time
        initialPrice = getPeggedPrice();
        initialTime = block.timestamp;
        //change rate
        A = _A;
        perA  = _perA;
        B = _B;
        perB = _perB;
    }

    /**
     pegged price increase by day: 0.0002X+0.01 (x is number of day from initialDay)
     ==> pegged_price_n = initial_price + n * (0.01) + (n*(n+1)/2 * 0.0002)

     increase per day:  X * A / perA + B / perB
     */
    //return the price of token * 10 ** 18
    function getPeggedPrice() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime <= initialTime) {
            return initialPrice;
        }
        uint256 daysFromBegin = ceil(
            (currentTime - initialTime) / SECOND_PER_DAY,
            1
        );
        uint256 peggedPrice = uint256(
            initialPrice +
                ((10**decimals()) * daysFromBegin * B) /
                perB +
                ((10**decimals()) * daysFromBegin * (daysFromBegin + 1) * A) /
                (perA * 2)
        );
        return (peggedPrice);
    }

    /**
    return deviant of price - beetween current price and pegged price
     */
    function getDeviant() public view returns (int256) {
        // calculate with the same measurement
        int256 peggedPrice = int256(getPeggedPrice());
        int256 currentPrice = int256(getTokenPrice(pairFeedPrice, isToken0, 1));
        return ((currentPrice - peggedPrice) * 100) / peggedPrice;
    }

    uint256 DEVIDE_STEP = 5;

    function getTaxPercent() public view returns (uint256, uint256){
        int256 deviant = getDeviant();
        return getTaxPercent(deviant);
    }

    function getTaxPercent(int256 deviant)
        public
        view
        returns (uint256, uint256)
    {
        // 0.93674 ^ -5 = 138645146889 / 10 ** 11
        //tax : 0.93674^{x}+3

        if (deviant < 0) {
            uint256 uDeviant = uint256(-deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 138645146889) / 10**11;
            }
            percent = (percent * (100000**resident)) / (93674**resident);
            return (percent / (10**14) + 3 * 10000, 10**4);
        } else {
            //business
            uint256 uDeviant = uint256(deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 93674**5) / (100000**5);
            }
            percent = (percent * (93674**resident)) / (100000**resident);
            return (percent / (10**14) + 3 * 10000, 10**4);
        }
    }

    function getRewardPercent() public view returns (uint256, uint256){
        int256 deviant = getDeviant();
        return getRewardPercent(deviant);
    }

    function getRewardPercent(int256 deviant)
        public
        view
        returns (uint256, uint256)
    {
        //1.0654279291277341544231240477738 = 1/0.93859 ~ 1.0654
        // 0.93859 ^ -10 = 1.8846936700630545738235994788055 ~ 188469367 / 10**8
        // 0.93859 ^ -5 = 137284145846 / 10 ** 11
        // 0.93859 ** x = (1/(0.93859))^ (-x) = (1 + 0.0654279291277341544231240477738) ^ -x ~ = 1 + (-x) *  0.0654279291277341544231240477738
        //reward : 0.93859 ^ -x + 0.2

        if (deviant < 0) {
            uint256 uDeviant = uint256(-deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 137284145846) / 10**11;
            }
            percent = (percent * (100000**resident)) / (93859**resident);
            return (percent / (10**14) + 2000, 10**4);
        } else {
            //business
            uint256 uDeviant = uint256(deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 93859**5) / (100000**5);
            }
            percent = (percent * (93859**resident)) / (100000**resident);
            return (percent / (10**14) + 2 * 10**3, 10**4);
        }
    }

    function getBuyerRewardPercent() public view returns (uint256, uint256){
        int256 deviant = getDeviant();
        return getBuyerRewardPercent(deviant);
    }


    function getBuyerRewardPercent(int256 deviant)
        public
        view
        returns (uint256, uint256)
    {
        // 0.947 ^ -5 = 1.31295579684  / 10 ** 11
        //reward : 0.947^{x}+0.05

        if (deviant < 0) {
            uint256 uDeviant = uint256(-deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 131295579684) / 10**11;
            }
            percent = (percent * (1000**resident)) / (947**resident);
            return (percent / (10**14) + 500, 10**4);
        } else {
            //business
            uint256 uDeviant = uint256(deviant);
            uint256 step = uDeviant / DEVIDE_STEP;
            uint256 resident = uDeviant - step * DEVIDE_STEP;
            uint256 j = 0;
            uint256 percent = 10**18;
            // return 9 ** uDeviant;
            for (j = 0; j < step; j += 1) {
                //for loop example
                percent = (percent * 947**5) / (1000**5);
            }
            percent = (percent * (947**resident)) / (1000**resident);
            return (percent / (10**14) + 500, 10**4);
        }
    }

    // internal function
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        return ((a + m - 1) / m) * m;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}