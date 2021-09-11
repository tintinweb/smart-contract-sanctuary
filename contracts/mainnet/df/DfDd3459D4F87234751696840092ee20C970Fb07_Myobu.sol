// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Snapshot.sol";

contract Myobu is ERC20Snapshot {
    address public override DAO; // solhint-disable-line
    address public override myobuSwap;

    bool private antiLiqBot;

    constructor(address payable addr1) MyobuBase(addr1) {
        setFees(Fees(10, 10, 10, 10));
    }

    modifier onlySupportedPair(address pair) {
        require(taxedPair(pair), "Pair is not supported");
        _;
    }

    modifier onlyMyobuswapOnAntiLiq() {
        require(!antiLiqBot || _msgSender() == myobuSwap, "Use MyobuSwap");
        _;
    }

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "Transaction expired");
        _;
    }

    function setDAO(address newDAO) external onlyOwner {
        DAO = newDAO;
        emit DAOChanged(newDAO);
    }

    function setMyobuSwap(address newMyobuSwap) external onlyOwner {
        myobuSwap = newMyobuSwap;
        emit MyobuSwapChanged(newMyobuSwap);
    }

    function snapshot() external returns (uint256) {
        require(_msgSender() == owner() || _msgSender() == DAO);
        return _snapshot();
    }

    function setAntiLiqBot(bool setTo) external virtual onlyOwner {
        antiLiqBot = setTo;
    }

    function noFeeAddLiquidityETH(LiquidityETHParams calldata params)
        external
        payable
        override
        onlySupportedPair(params.pair)
        checkDeadline(params.deadline)
        onlyMyobuswapOnAntiLiq
        lockTheSwap
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        _transfer(_msgSender(), address(this), params.amountTokenOrLP);
        uint256 beforeBalance = address(this).balance - msg.value;
        (amountToken, amountETH, liquidity) = IUniswapV2Router(
            _routerFor[params.pair]
        ).addLiquidityETH{value: msg.value}(
            address(this),
            params.amountTokenOrLP,
            params.amountTokenMin,
            params.amountETHMin,
            params.to,
            block.timestamp
        );
        // router refunds to this address, refund all back to sender
        if (address(this).balance > beforeBalance) {
            payable(_msgSender()).transfer(
                address(this).balance - beforeBalance
            );
        }
        emit LiquidityAddedETH(params.pair, amountToken, amountETH, liquidity);
    }

    function noFeeRemoveLiquidityETH(LiquidityETHParams calldata params)
        external
        override
        onlySupportedPair(params.pair)
        checkDeadline(params.deadline)
        lockTheSwap
        returns (uint256 amountToken, uint256 amountETH)
    {
        MyobuLib.transferTokens(
            params.pair,
            _msgSender(),
            address(this),
            params.amountTokenOrLP
        );
        (amountToken, amountETH) = IUniswapV2Router(_routerFor[params.pair])
            .removeLiquidityETH(
                address(this),
                params.amountTokenOrLP,
                params.amountTokenMin,
                params.amountETHMin,
                params.to,
                block.timestamp
            );
        emit LiquidityRemovedETH(
            params.pair,
            amountToken,
            amountETH,
            params.amountTokenOrLP
        );
    }

    function noFeeAddLiquidity(AddLiquidityParams calldata params)
        external
        override
        onlySupportedPair(params.pair)
        checkDeadline(params.deadline)
        onlyMyobuswapOnAntiLiq
        lockTheSwap
        returns (
            uint256 amountMyobu,
            uint256 amountToken,
            uint256 liquidity
        )
    {
        address token = MyobuLib.tokenFor(params.pair);
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));
        _transfer(_msgSender(), address(this), params.amountToken);
        MyobuLib.transferTokens(
            token,
            _msgSender(),
            address(this),
            params.amountTokenB
        );
        (amountToken, amountMyobu, liquidity) = IUniswapV2Router(
            _routerFor[params.pair]
        ).addLiquidity(
                token,
                address(this),
                params.amountTokenB,
                params.amountToken,
                params.amountTokenBMin,
                params.amountTokenMin,
                params.to,
                block.timestamp
            );
        // router refunds to this address, refund all back to sender
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        if (currentBalance > beforeBalance) {
            IERC20(token).transfer(
                _msgSender(),
                currentBalance - beforeBalance
            );
        }
        emit LiquidityAdded(params.pair, amountMyobu, amountToken, liquidity);
    }

    function noFeeRemoveLiquidity(RemoveLiquidityParams calldata params)
        external
        override
        onlySupportedPair(params.pair)
        checkDeadline(params.deadline)
        lockTheSwap
        returns (uint256 amountMyobu, uint256 amountToken)
    {
        MyobuLib.transferTokens(
            params.pair,
            _msgSender(),
            address(this),
            params.amountLP
        );
        (amountToken, amountMyobu) = IUniswapV2Router(_routerFor[params.pair])
            .removeLiquidity(
                MyobuLib.tokenFor(params.pair),
                address(this),
                params.amountLP,
                params.amountTokenBMin,
                params.amountTokenMin,
                params.to,
                block.timestamp
            );
        emit LiquidityRemoved(
            params.pair,
            amountMyobu,
            amountToken,
            params.amountLP
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Utils/Arrays.sol";
import "./Utils/Counters.sol";
import "./MyobuBase.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is MyobuBase {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function getCurrentSnapshotId() public view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId)
        public
        view
        virtual
        returns (uint256)
    {
        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _accountBalanceSnapshots[account]
        );

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId)
        public
        view
        virtual
        returns (uint256)
    {
        (bool snapshotted, uint256 value) = _valueAt(
            snapshotId,
            _totalSupplySnapshots
        );

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private
        view
        returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(
            snapshotId <= getCurrentSnapshotId(),
            "ERC20Snapshot: nonexistent id"
        );

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue)
        private
    {
        uint256 currentId = getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids)
        private
        view
        returns (uint256)
    {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Utils/MyobuLib.sol";
import "./Utils/Ownable.sol";
import "./Interfaces/IUniswapV2Router.sol";
import "./Interfaces/IUniswapV2Factory.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "./Interfaces/IMyobu.sol";

abstract contract MyobuBase is IMyobu, Ownable, ERC20 {
    uint256 internal constant MAX = type(uint256).max;

    uint256 private constant SUPPLY = 1000000000000 * 10**9;
    string internal constant NAME = unicode"Myōbu";
    string internal constant SYMBOL = "MYOBU";
    uint8 internal constant DECIMALS = 9;

    // pair => router
    mapping(address => address) internal _routerFor;
    mapping(address => bool) private taxedTransfer;

    Fees private fees;

    address payable internal _taxAddress;

    IUniswapV2Router internal uniswapV2Router;
    address internal uniswapV2Pair;

    bool private tradingOpen;
    bool private liquidityAdded;
    bool private inSwap;
    bool private swapEnabled;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address payable addr1) ERC20(NAME, SYMBOL) {
        _taxAddress = addr1;
        _mint(_msgSender(), SUPPLY);
    }

    function decimals() public pure virtual override returns (uint8) {
        return DECIMALS;
    }

    function taxedPair(address pair)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _routerFor[pair] != address(0);
    }

    // Transfer tokens without emmiting events from an address to this address, used for taking fees
    function transferFee(address from, uint256 amount) internal {
        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function takeFee(
        address from,
        uint256 amount,
        uint256 teamFee
    ) internal returns (uint256) {
        if (teamFee == 0) return 0;
        uint256 tTeam = MyobuLib.percentageOf(amount, teamFee);
        transferFee(from, tTeam);
        emit FeesTaken(tTeam);
        return tTeam;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // If no fee, it is 0 which will take no fee
        uint256 _teamFee;
        if (from != owner() && to != owner()) {
            if (swapEnabled && !inSwap) {
                if (taxedPair(from) && !taxedPair(to)) {
                    require(tradingOpen);
                    _teamFee = fees.buyFee;
                } else if (taxedTransfer[from] || taxedTransfer[to]) {
                    _teamFee = fees.transferFee;
                } else if (taxedPair(to)) {
                    require(tradingOpen);
                    require(amount <= (balanceOf(to) * fees.impact) / 100);
                    swapTokensForEth(balanceOf(address(this)));
                    sendETHToFee(address(this).balance);
                    _teamFee = fees.sellFee;
                }
            }
        }

        uint256 fee = takeFee(from, amount, _teamFee);
        super._transfer(from, to, amount - fee);
    }

    function swapTokensForEth(uint256 tokenAmount) internal lockTheSwap {
        MyobuLib.swapForETH(uniswapV2Router, tokenAmount, address(this));
    }

    function sendETHToFee(uint256 amount) internal {
        _taxAddress.transfer(amount);
    }

    function openTrading() external virtual onlyOwner {
        require(liquidityAdded);
        tradingOpen = true;
    }

    function addDEX(address pair, address router) public virtual onlyOwner {
        require(!taxedPair(pair), "DEX already exists");
        address tokenFor = MyobuLib.tokenFor(pair);
        _routerFor[pair] = router;
        _approve(address(this), router, MAX);
        IERC20(tokenFor).approve(router, MAX);
        IERC20(pair).approve(router, MAX);
    }

    function removeDEX(address pair) external virtual onlyOwner {
        require(taxedPair(pair), "DEX does not exist");
        address tokenFor = MyobuLib.tokenFor(pair);
        address router = _routerFor[pair];
        delete _routerFor[pair];
        _approve(address(this), router, 0);
        IERC20(tokenFor).approve(router, 0);
        IERC20(pair).approve(router, 0);
    }

    function addLiquidity() external virtual onlyOwner lockTheSwap {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        addDEX(uniswapV2Pair, address(_uniswapV2Router));
        MyobuLib.addLiquidityETH(
            uniswapV2Router,
            balanceOf(address(this)),
            address(this).balance,
            owner()
        );
        liquidityAdded = true;
    }

    function setTaxAddress(address payable newTaxAddress) external onlyOwner {
        _taxAddress = newTaxAddress;
        emit TaxAddressChanged(newTaxAddress);
    }

    function setTaxedTransferFor(address[] calldata taxedTransfer_)
        external
        virtual
        onlyOwner
    {
        for (uint256 i; i < taxedTransfer_.length; i++) {
            taxedTransfer[taxedTransfer_[i]] = true;
        }
        emit TaxedTransferAddedFor(taxedTransfer_);
    }

    function removeTaxedTransferFor(address[] calldata notTaxed)
        external
        virtual
        onlyOwner
    {
        for (uint256 i; i < notTaxed.length; i++) {
            taxedTransfer[notTaxed[i]] = false;
        }
        emit TaxedTransferRemovedFor(notTaxed);
    }

    function manualswap() external onlyOwner {
        swapTokensForEth(balanceOf(address(this)));
    }

    function manualsend() external onlyOwner {
        sendETHToFee(address(this).balance);
    }

    function setSwapRouter(IUniswapV2Router newRouter) external onlyOwner {
        require(liquidityAdded, "Add liquidity before doing this");

        address weth = uniswapV2Router.WETH();
        address newPair = IUniswapV2Factory(newRouter.factory()).getPair(
            address(this),
            weth
        );
        require(
            newPair != address(0),
            "WETH Pair does not exist for that router"
        );
        require(taxedPair(newPair), "The pair must be a taxed pair");

        (uint256 reservesOld, , ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        (uint256 reservesNew, , ) = IUniswapV2Pair(newPair).getReserves();
        require(
            reservesNew > reservesOld,
            "New pair must have more WETH Reserves"
        );

        uniswapV2Router = newRouter;
        uniswapV2Pair = newPair;
    }

    function setFees(Fees memory newFees) public onlyOwner {
        require(
            newFees.impact != 0 && newFees.impact <= 100,
            "Impact must be greater than 0 and under or equal to 100"
        );
        require(
            newFees.buyFee < 15 &&
                newFees.sellFee < 15 &&
                newFees.transferFee <= newFees.sellFee,
            "Fees for a buy / sell must be under 15"
        );
        fees = newFees;

        if (newFees.buyFee + newFees.sellFee == 0) {
            swapEnabled = false;
        } else {
            swapEnabled = true;
        }

        emit FeesChanged(newFees);
    }

    function currentFees() external view override returns (Fees memory) {
        return fees;
    }

    // solhint-disable-next-line
    receive() external payable virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element)
        internal
        view
        returns (uint256)
    {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IMyobu is IERC20 {
    event DAOChanged(address newDAOContract);
    event MyobuSwapChanged(address newMyobuSwap);

    function DAO() external view returns (address); // solhint-disable-line

    function myobuSwap() external view returns (address);

    event TaxAddressChanged(address newTaxAddress);
    event TaxedTransferAddedFor(address[] addresses);
    event TaxedTransferRemovedFor(address[] addresses);

    event FeesTaken(uint256 teamFee);
    event FeesChanged(Fees newFees);

    struct Fees {
        uint256 impact;
        uint256 buyFee;
        uint256 sellFee;
        uint256 transferFee;
    }

    function currentFees() external view returns (Fees memory);

    struct LiquidityETHParams {
        address pair;
        address to;
        uint256 amountTokenOrLP;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        uint256 deadline;
    }

    event LiquidityAddedETH(
        address pair,
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function noFeeAddLiquidityETH(LiquidityETHParams calldata params)
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    event LiquidityRemovedETH(
        address pair,
        uint256 amountToken,
        uint256 amountETH,
        uint256 amountRemoved
    );

    function noFeeRemoveLiquidityETH(LiquidityETHParams calldata params)
        external
        returns (uint256 amountToken, uint256 amountETH);

    struct AddLiquidityParams {
        address pair;
        address to;
        uint256 amountToken;
        uint256 amountTokenB;
        uint256 amountTokenMin;
        uint256 amountTokenBMin;
        uint256 deadline;
    }

    event LiquidityAdded(
        address pair,
        uint256 amountMyobu,
        uint256 amountToken,
        uint256 liquidity
    );

    function noFeeAddLiquidity(AddLiquidityParams calldata params)
        external
        returns (
            uint256 amountMyobu,
            uint256 amountToken,
            uint256 liquidity
        );

    struct RemoveLiquidityParams {
        address pair;
        address to;
        uint256 amountLP;
        uint256 amountTokenMin;
        uint256 amountTokenBMin;
        uint256 deadline;
    }

    event LiquidityRemoved(
        address pair,
        uint256 amountMyobu,
        uint256 amountToken,
        uint256 liquidity
    );

    function noFeeRemoveLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (uint256 amountMyobu, uint256 amountToken);

    function taxedPair(address pair) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    // solhint-disable-next-line
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../Interfaces/IUniswapV2Router.sol";
import "../Interfaces/IUniswapV2Pair.sol";
import "../Interfaces/IERC20.sol";

library MyobuLib {
    /**
     * @dev Calculates the percentage of a number
     * @param number: The number to calculate the percentage of
     * @param percentage: The percentage of the number to return
     * @return The percentage of a number
     */
    function percentageOf(uint256 number, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (number * percentage) / 100;
    }

    /**
     * @dev Swaps an amount of tokens for ETH
     * @param uniswapV2Router: The uniswap router to trade through
     * @param amount: The amount of tokens to swap
     * @param to: The address to send the recieved tokens to
     * @return The amount of ETH recieved
     */
    function swapForETH(
        IUniswapV2Router uniswapV2Router,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        uint256 startingBalance = to.balance;
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );

        return to.balance - startingBalance;
    }

    /**
     * @dev Adds liquidity for the token in ETH
     * @param uniswapV2Router: The uniswap router to add liquidity through
     * @param amountToken: The amount of tokens to add liquidity with
     * @param amountETH: The amount of ETH to add liquidity with
     * @param to: The address to send the recieved LP tokens to
     */
    function addLiquidityETH(
        IUniswapV2Router uniswapV2Router,
        uint256 amountToken,
        uint256 amountETH,
        address to
    ) internal {
        uniswapV2Router.addLiquidityETH{value: amountETH}(
            address(this),
            amountToken,
            0,
            0,
            to,
            block.timestamp
        );
    }

    /**
     * @param token: The address of the token to transfer
     * @param from: The sender of the tokens
     * @param to: The receiver of the tokens
     * @param amount: The amount of tokens to transfer
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).transferFrom(from, to, amount);
    }

    /**
     * @dev Returns the token for a Uniswap V2 Pair
     */
    function tokenFor(address pair) internal view returns (address) {
        return IUniswapV2Pair(pair).token0();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Interfaces/IERC20Metadata.sol";
import "./Utils/Context.sol";

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
    mapping(address => uint256) internal _balances;

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
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
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
    ) internal virtual {} // solhint-disable-line

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
    ) internal virtual {} // solhint-disable-line
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

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

{
  "optimizer": {
    "enabled": true,
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
  }
}