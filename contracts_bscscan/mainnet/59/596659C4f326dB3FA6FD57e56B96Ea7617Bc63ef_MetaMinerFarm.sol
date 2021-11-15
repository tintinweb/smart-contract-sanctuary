// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IMetaStarNFT.sol";
import "./IMetaMinerNFT.sol";

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function burn(uint256 amount) external returns (bool);
}

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

contract MetaMinerFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct MineField {
        uint256 id;
        uint256 starId;
        address renter;
        uint8 status; // 1=request 2=approve 3=reject
        uint256 starttime;
        uint256 leasetime;
        uint256 stake;
        uint256 sellMinerCountPerMonth;
        uint256 sellMinerCountTotal;
    }

    IERC20 public META;
    IERC20 public USDT;
    IMetaStarNFT public STAR;
    IMetaMinerNFT public MINER;

    address public constant USDT_BNB_PAIR =
        0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE;
    address public constant META_BNB_PAIR =
        0x0aC338E60B22d2d485a4513d0f07B643E74da955;
    address public BUY_BACK_BURN_ADDR;
    address public LIQUID_ADDR;
    address public FUND_ADDR;

    uint256 constant MINE_FIELD_RENT_FEE = 10 * 1e18;
    uint256 constant MINE_FIELD_COUNT = 20;
    uint256 constant MINER_CLASS_COUNT = 5;
    uint256 immutable START_TIME;
    uint256[35] MINER_CLASS_PROBABILITY = [
        32,
        36,
        40,
        44,
        48,
        48,
        52,
        10,
        10,
        12,
        14,
        16,
        18,
        20,
        32,
        36,
        40,
        44,
        48,
        48,
        52,
        10,
        10,
        12,
        14,
        16,
        18,
        20,
        20,
        22,
        24,
        28,
        32,
        36,
        38
    ];
    uint256[] strengthMin = [10, 16, 8, 24, 12];
    uint256[] energyMin = [50, 106, 42, 180, 72];
    uint256[] strengthRange = [4, 8, 4, 12, 6];
    uint256[] energyRange = [20, 28, 16, 40, 16];

    uint256[] INIT_OUTPUT_PER_WEEKLY = [500, 600, 700, 800, 1000];
    uint256[] OUTPUT_PER_WEEKLY = [100, 150, 200, 300, 500];

    uint256 public generation;
    uint256 private nonce;
    uint256 priceCounter;

    uint256 public minerPriceForUSDT = 15 * 1e17; // META
    uint256 public minerPrice = 5 * 1e17;
    uint256 public totalPrice = 16 * 1e18;

    mapping(uint256 => mapping(uint256 => MineField)) mineFields;

    mapping(uint256 => mapping(uint256 => uint256)) soldPerWeek;

    mapping(uint256 => uint256) priceHistory;

    event BuyMiner(
        address indexed user,
        uint256 starId,
        uint256 areaId,
        uint256 amount,
        uint256 metaAmount
    );
    // action: 1=request 2=acceptRent 3=reject 4=reletMineField 5=terminationOfLease 6=cancelTheLease
    event Rent(
        address indexed user,
        uint256 action,
        uint256 starId,
        uint256 areaId
    );
    event OwnerSharedRevenue(
        uint256 starId,
        address indexed owner,
        uint256 fee
    );

    constructor(
        address _META,
        address _USDT,
        address _STAR,
        address _MINER,
        address _BUY_BACK_BURN_ADD,
        address _LIQUID_ADDR,
        address _FUND_ADDR
    ) public {
        META = IERC20(_META);
        USDT = IERC20(_USDT);
        STAR = IMetaStarNFT(_STAR);
        MINER = IMetaMinerNFT(_MINER);

        BUY_BACK_BURN_ADDR = _BUY_BACK_BURN_ADD;
        LIQUID_ADDR = _LIQUID_ADDR;
        FUND_ADDR = _FUND_ADDR;

        generation = 1;
        START_TIME = block.timestamp;
    }

    function setMinerPriceForUSDT(uint256 _minerPriceForUSDT) public onlyOwner {
        minerPriceForUSDT = _minerPriceForUSDT;
    }

    function setMinerPrice(uint256 _minerPrice) public onlyOwner {
        minerPrice = _minerPrice;
    }

    function setTotalPrice(uint256 _totalPrice) public onlyOwner {
        totalPrice = _totalPrice;
    }

    function setGeneration(uint256 _generation) public onlyOwner {
        generation = _generation;
    }

    function batchBuy(
        uint256 starId,
        uint256 areaId,
        uint256 amount,
        uint256 metaAmount,
        uint256 count
    ) external nonReentrant {
        require(msg.sender == tx.origin, "Sender invalid.");
        require(amount == minerPriceForUSDT, "Amount invalid.");
        require(metaAmount == minerPrice, "metaAmount invalid.");
        require(areaId <= 20, "areaId invalid.");
        require(count > 0 && count <= 10, "Max 10");

        for (uint256 i = 0; i < count; i++) {
            _buyMiner(starId, areaId, amount, metaAmount);
        }
    }

    // buy miner by usdt and meta
    function _buyMiner(
        uint256 starId,
        uint256 areaId,
        uint256 amount,
        uint256 metaAmount
    ) internal {
        uint256 totalOutputPerWeek = getTotalOutputWeekly(starId);
        uint256 weekIndex = getWeekIndex(starId);
        uint256 soldWeekly = getSoldWeekly(starId);

        require(soldWeekly < totalOutputPerWeek, "Over maximum supply");

        soldPerWeek[starId][weekIndex] = soldPerWeek[starId][weekIndex].add(1);

        _updateMineFieldForBuyMiner(starId, areaId);

        uint256 price = _sharedRevenue(starId, areaId);
        uint256 mAmount = totalPrice.div(price).sub(minerPriceForUSDT);

        metaAmount = metaAmount > mAmount ? metaAmount : mAmount;

        META.transferFrom(_msgSender(), FUND_ADDR, metaAmount);

        _mint(starId);

        emit BuyMiner(_msgSender(), starId, areaId, amount, metaAmount);
    }

    function _mint(uint256 starId) internal {
        nonce++;
        uint256 rand = importSeedFromThird(nonce, 1000);
        uint256 totalProbability = 0;
        uint256 class = 0;
        for (uint256 i = 0; i < MINER_CLASS_PROBABILITY.length; i++) {
            totalProbability = totalProbability.add(MINER_CLASS_PROBABILITY[i]);
            if (rand < totalProbability) {
                class = i;
                break;
            }
        }
        nonce++;
        uint256 sRand = importSeedFromThird(
            nonce,
            strengthRange[class.div(7)].add(1)
        );
        uint256 strength = strengthMin[class.div(7)].add(sRand);
        nonce++;
        uint256 eRand = importSeedFromThird(
            nonce,
            energyRange[class.div(7)].add(1)
        );
        uint256 energy = energyMin[class.div(7)].add(eRand);
        MINER.mint(
            _msgSender(),
            starId,
            generation,
            class.add(1),
            strength,
            energy
        );
    }

    function _sharedRevenue(uint256 starId, uint256 areaId)
        internal
        returns (uint256)
    {
        uint256 ownerRate = 10;
        uint256 rentRate = 10;
        uint256 buyBackRate = 5;
        uint256 price = price();

        address starOwner = STAR.ownerOf(starId);
        uint256 averagePrice = getAveragePrice();
        uint256 payment = averagePrice == 0 ? price : averagePrice;

        uint256 rentFee = 0;
        MineField memory mf = mineFields[starId][areaId];
        if (mf.renter != address(0) && mf.status == 2) {
            rentFee = payment.div(rentRate);
            USDT.transferFrom(_msgSender(), mf.renter, rentFee);
        } else {
            ownerRate = 5;
        }

        uint256 ownerFee = payment.div(ownerRate);
        uint256 buyBackFee = payment.div(buyBackRate);

        USDT.transferFrom(_msgSender(), starOwner, ownerFee);
        USDT.transferFrom(_msgSender(), LIQUID_ADDR, buyBackFee);
        USDT.transferFrom(
            _msgSender(),
            BUY_BACK_BURN_ADDR,
            payment.sub(ownerFee).sub(buyBackFee).sub(rentFee)
        );
        priceCounter++;
        priceHistory[priceCounter] = price;

        emit OwnerSharedRevenue(starId, starOwner, ownerFee);

        return price.div(minerPriceForUSDT);
    }

    function getEstimatedAmount() public view returns (uint256, uint256) {
        uint256 price = price();
        uint256 averagePrice = getAveragePrice();
        uint256 payment = averagePrice == 0 ? price : averagePrice;

        price = price.div(minerPriceForUSDT);
        uint256 mAmount = totalPrice.div(price).sub(minerPriceForUSDT);

        uint256 metaAmount = minerPrice > mAmount ? minerPrice : mAmount;
        return (payment, metaAmount);
    }

    /**
     * @notice Generates a random number between 0 - (count - 1)
     * @param seed The seed to generate different number if block.timestamp is same
     * for two or more numbers.
     * @param count The number count
     */
    function importSeedFromThird(uint256 seed, uint256 count)
        internal
        view
        returns (uint256)
    {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, seed))
        ) % count;
        return randomNumber;
    }

    function requestRent(
        uint256 starId,
        uint256 areaId,
        uint256 amount
    ) external {
        require(
            STAR.ownerOf(starId) != _msgSender(),
            "can't rent yourself area"
        );
        require(areaId > 0 && areaId <= 20, "areaId invalid.");
        require(amount == MINE_FIELD_RENT_FEE, "META insufficient");
        MineField memory mf = mineFields[starId][areaId];
        require(mf.status == 0, "Can't apply for");
        mf = MineField(areaId, starId, _msgSender(), 1, 0, 0, amount, 0, 0);

        mineFields[starId][areaId] = mf;
        META.transferFrom(_msgSender(), address(this), amount);

        emit Rent(_msgSender(), 1, starId, areaId);
    }

    function acceptRent(uint256 starId, uint256 areaId) external {
        require(
            STAR.ownerOf(starId) == _msgSender(),
            "You don't own this token."
        );
        require(areaId > 0 && areaId <= 20, "areaId invalid.");
        MineField storage mf = mineFields[starId][areaId];
        require(mf.status == 1, "Status invalid");
        mf.status = 2;
        mf.starttime = block.timestamp;
        mf.leasetime = block.timestamp;

        emit Rent(_msgSender(), 2, starId, areaId);
    }

    function rejectRent(uint256 starId, uint256 areaId) external {
        require(
            STAR.ownerOf(starId) == _msgSender(),
            "You don't own this token."
        );
        require(areaId > 0 && areaId <= 20, "areaId invalid.");
        MineField storage mf = mineFields[starId][areaId];
        require(mf.status == 1, "Status invalid");

        META.transfer(mf.renter, mf.stake);
        mf.status = 0;
        mf.stake = 0;

        emit Rent(_msgSender(), 3, starId, areaId);
    }

    function getMineField(uint256 starId, uint256 areaId)
        public
        view
        returns (
            address,
            uint8,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(areaId > 0 && areaId <= 20, "areaId invalid.");
        MineField memory mf = mineFields[starId][areaId];

        return (
            mf.renter,
            mf.status,
            mf.starttime,
            mf.leasetime,
            mf.stake,
            mf.sellMinerCountPerMonth,
            mf.sellMinerCountTotal
        );
    }

    function getAllMineField(uint256 starId)
        external
        view
        returns (MineField[] memory)
    {
        MineField[] memory mfs = new MineField[](20);
        for (uint256 i = 0; i < MINE_FIELD_COUNT; i++) {
            MineField memory mf = mineFields[starId][i + 1];
            mfs[i] = mf;
        }
        return mfs;
    }

    function isOverdueMineField(uint256 starId, uint256 areaId)
        public
        view
        returns (bool)
    {
        require(areaId > 0 && areaId <= 20, "areaId invalid.");
        MineField memory mf = mineFields[starId][areaId];
        return
            mf.status == 2 &&
            mf.starttime > 0 &&
            (block.timestamp - mf.starttime) > 30 days;
    }

    function isOverdueLeasetime(uint256 starId, uint256 areaId)
        public
        view
        returns (bool)
    {
        require(areaId > 0 && areaId <= 20, "areaId invalid.");
        MineField memory mf = mineFields[starId][areaId];
        return
            mf.status == 2 &&
            mf.leasetime > 0 &&
            (block.timestamp - mf.leasetime) > 30 days;
    }

    function reletMineField(uint256 starId, uint256 areaId) public {
        require(areaId > 0 && areaId <= 20, "areaId invalid.");
        require(isOverdueLeasetime(starId, areaId), "Not over due");
        MineField storage mf = mineFields[starId][areaId];
        address starOwner = STAR.ownerOf(starId);

        if (mf.sellMinerCountPerMonth < 5) {
            META.transfer(starOwner, mf.stake);
            mf.status = 0;
            mf.renter = address(0);
            mf.starttime = 0;
            mf.leasetime = 0;
            mf.sellMinerCountPerMonth = 0;
            mf.sellMinerCountTotal = 0;
        } else {
            mf.sellMinerCountPerMonth = 0;
            mf.leasetime = block.timestamp;
        }
        emit Rent(_msgSender(), 4, starId, areaId);
    }

    function terminationOfLease(uint256 starId, uint256 areaId) public {
        require(areaId > 0 && areaId <= 20, "areaId invalid.");
        require(isOverdueMineField(starId, areaId), "Not over due");
        require(
            STAR.ownerOf(starId) == _msgSender(),
            "You don't own this token."
        );
        MineField storage mf = mineFields[starId][areaId];
        require(mf.status == 2, "Not rent");

        if (mf.sellMinerCountTotal >= 30) {
            META.transferFrom(_msgSender(), mf.renter, 15 * 1e18);
        }
        META.transfer(mf.renter, mf.stake);
        mf.status = 0;
        mf.renter = address(0);
        mf.starttime = 0;
        mf.leasetime = 0;
        mf.sellMinerCountPerMonth = 0;
        mf.sellMinerCountTotal = 0;

        emit Rent(_msgSender(), 5, starId, areaId);
    }

    function cancelTheLease(uint256 starId, uint256 areaId) public {
        require(areaId > 0 && areaId <= 20, "areaId invalid.");
        MineField storage mf = mineFields[starId][areaId];
        require(mf.renter == _msgSender(), "You don't own this area");
        address starOwner = STAR.ownerOf(starId);
        if (mf.sellMinerCountPerMonth < 30) {
            META.transfer(starOwner, mf.stake);
        } else {
            META.transfer(mf.renter, mf.stake);
        }
        mf.status = 0;
        mf.renter = address(0);
        mf.starttime = 0;
        mf.leasetime = 0;
        mf.sellMinerCountPerMonth = 0;
        mf.sellMinerCountTotal = 0;
        emit Rent(_msgSender(), 6, starId, areaId);
    }

    function getTotalOutputWeekly(uint256 starId)
        public
        view
        returns (uint256)
    {
        (, uint256 level, ) = STAR.getStar(starId);
        if (getWeekIndex(starId) == 1) {
            return INIT_OUTPUT_PER_WEEKLY[level];
        }
        return OUTPUT_PER_WEEKLY[level];
    }

    function getWeekIndex(uint256 starId) public view returns (uint256) {
        (, , uint256 createtime) = STAR.getStar(starId);
        if (createtime < START_TIME) {
            createtime = START_TIME;
        }
        return (block.timestamp.sub(createtime)).div(604800).add(1);
    }

    function getSoldWeekly(uint256 starId) public view returns (uint256) {
        return soldPerWeek[starId][getWeekIndex(starId)];
    }

    function _updateMineFieldForBuyMiner(uint256 starId, uint256 areaId)
        internal
    {
        MineField storage mf = mineFields[starId][areaId];
        if (mf.renter != address(0) && mf.status == 2) {
            mf.sellMinerCountPerMonth = mf.sellMinerCountPerMonth.add(1);
            mf.sellMinerCountTotal = mf.sellMinerCountTotal.add(1);
        }
    }

    /**
     * get payment usdt for the miner
     */
    function price() public view returns (uint256) {
        uint256 amountBNB = calculateToken0Price(
            META_BNB_PAIR,
            minerPriceForUSDT
        );
        return calculateToken1Price(USDT_BNB_PAIR, amountBNB);
    }

    function calculateToken0Price(address pairAddress, uint256 amount)
        public
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        return (amount * reserve1) / reserve0;
    }

    function calculateToken1Price(address pairAddress, uint256 amount)
        public
        view
        returns (uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        return (amount * reserve0) / reserve1;
    }

    function getAveragePrice() public view returns (uint256) {
        uint256 total = 0;
        uint256 len = 0;
        if (priceCounter == 0) {
            return 0;
        }
        for (uint256 i = priceCounter; i > 0; i--) {
            total = total.add(priceHistory[i]);
            len++;
            if (len >= 20) {
                break;
            }
        }
        return total.div(len);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
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
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMetaStarNFT is IERC721 {
    function mint(address to, string memory name) external;

    function getStar(uint256 tokenId)
        external
        view
        returns (
            string memory,
            uint256,
            uint256
        );

    function levelUp(uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface IMetaMinerNFT is IERC721Enumerable {
    function mint(address to, uint256 starId, uint256  generation, uint256 class, uint256 strength, uint256 energy) external;

    function getMiner(uint256 tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

