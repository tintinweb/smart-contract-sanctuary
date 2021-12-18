//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IREBLNFT.sol";

interface IPancakeSwap {
    function WETH() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IREBLStaking {
    struct UserStakingInfo {
        uint256 rewardUnblockTimestamp;
        uint256 usdtAmountForReward;
        uint256 tokenAmount;
        uint256 periodInWeeks;
    }

    function stake(uint256 amount, uint256 periodInWeeks) external;

    function unstakeWithReward() external;

    function unstakeWithoutReward() external;

    function getPotentialNftReward(uint256 tokenAmount, uint256 periodInWeeks) view external returns (uint256[] memory);

    function changeMultiplier(uint256 periodInWeeks, uint256 value) external;

    function getMinAmountToStake() external view returns (uint256);

    function getActualNftReward(uint256 calculatedUsdtAmountForReward) view external returns (uint256[] memory);
}

contract REBLStaking is IREBLStaking, Ownable {
    IREBLNFT nftContract;

    IPancakeSwap public router;
    IPancakePair bnbTokenPair;
    IPancakePair bnbUsdtPair;
    //    address usdtAddress = 0x55d398326f99059fF775485246999027B3197955; //mainnet
    //    address reblAddress = 0xbB8b7E9A870FbC22ce4b543fc3A43445Fbf9097f; //mainnet
    address usdtAddress = 0x40D7c8F55C25f448204a140b5a6B0bD8C1E48b13; //testnet
    address reblAddress = 0x2ea8c131b84a11f8CCC7bfdC6abE6A96341b8673;   //testnet
    address wbnbAddress = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;   //testnet

    mapping(uint256 => uint256) multiplierByWeekAmount;
    mapping(address => UserStakingInfo) public usersStaking;
    uint256 constant MULTIPLIER_DENOMINATOR = 100;
    //    uint256 constant SECONDS_IN_WEEK = 1 weeks; //main
    //todo don't forget to change
    uint256 constant SECONDS_IN_WEEK = 60; //for test

    constructor(
        address _nftContractAddress,
        address _bnbTokenPairAddress
    ) {
        //        initDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //mainnet
        initDEXRouter(0x14e9203E14EF89AB284b8e9EecC787B1743AD285);
        //testnet

        bnbTokenPair = IPancakePair(_bnbTokenPairAddress);
//        bnbUsdtPair = IPancakePair(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE); //mainnet
        bnbUsdtPair = IPancakePair(0x804710fb401e9A4c11cF13A8399c49bDf14A49B8); //testnet
        // mainnet bsc
        nftContract = IREBLNFT(_nftContractAddress);
        multiplierByWeekAmount[2] = 100;
        multiplierByWeekAmount[4] = 120;
        multiplierByWeekAmount[6] = 130;
        multiplierByWeekAmount[8] = 140;
        multiplierByWeekAmount[10] = 150;
        multiplierByWeekAmount[12] = 160;
        multiplierByWeekAmount[14] = 170;
        multiplierByWeekAmount[16] = 180;
        multiplierByWeekAmount[18] = 190;
        multiplierByWeekAmount[20] = 200;
    }

    function stake(uint256 amount, uint256 periodInWeeks) public override {
        require(periodInWeeks >= 2, "Min period for staking is 2 weeks");
        require(isEvenNumber(periodInWeeks), "Period in weeks should be even number");

        uint256 calculatedUsdtAmountForReward = calculateUsdtAmountForReward(amount, periodInWeeks);
        uint256 calculatedUSDT = usersStaking[msg.sender].usdtAmountForReward + calculatedUsdtAmountForReward;
        uint256 tokenAmount = usersStaking[msg.sender].tokenAmount + amount;
        uint256 unstakeTimestamp = calculateUnstakeTimestamp(periodInWeeks);
        IERC20(reblAddress).transferFrom(msg.sender, address(this), amount);
        usersStaking[msg.sender] = UserStakingInfo(unstakeTimestamp, calculatedUSDT, tokenAmount, periodInWeeks);
    }

    function unstakeWithReward() public override {
        require(block.timestamp >= usersStaking[msg.sender].rewardUnblockTimestamp, "Reward is not available yet");
        nftContract.mintToByAmount(msg.sender, usersStaking[msg.sender].usdtAmountForReward);
        IERC20(reblAddress).transfer(msg.sender, usersStaking[msg.sender].tokenAmount);
        clearUserStaking(msg.sender);
    }

    function unstakeWithoutReward() public override {
        IERC20(reblAddress).transfer(msg.sender, usersStaking[msg.sender].tokenAmount);
        clearUserStaking(msg.sender);
    }

    function getPotentialNftReward(uint256 tokenAmount, uint256 periodInWeeks) view public override returns (uint256[] memory) {
        uint256 calculatedUsdtAmountForReward = calculateUsdtAmountForReward(tokenAmount, periodInWeeks);
        return getNftReward(calculatedUsdtAmountForReward);
    }

    function getActualNftReward(uint256 calculatedUsdtAmountForReward) view public override returns (uint256[] memory) {
        uint256[] memory nftReward = getNftReward(calculatedUsdtAmountForReward);
        return nftReward;
    }

    function getNftReward(uint256 calculatedUsdtAmountForReward) view internal returns (uint256[] memory) {
        uint256[] memory levelsUsdtValues = nftContract.getLevelsUsdtValues();
        uint256 lowestNftUsdtValue = nftContract.getLowestLevelUsdtValue();
        uint256[] memory levelsCount = new uint256[](levelsUsdtValues.length);
        while (calculatedUsdtAmountForReward >= lowestNftUsdtValue) {
            for (uint256 i = levelsUsdtValues.length; i > 0; i--) {
                if (calculatedUsdtAmountForReward >= levelsUsdtValues[i - 1]) {
                    levelsCount[i - 1]++;
                    calculatedUsdtAmountForReward -= levelsUsdtValues[i - 1];
                    break;
                }
            }
        }
        return levelsCount;
    }

    function changeMultiplier(uint256 periodInWeeks, uint256 value) public override onlyOwner {
        multiplierByWeekAmount[periodInWeeks] = value;
    }

    function clearUserStaking(address userAddress) internal {
        usersStaking[userAddress].usdtAmountForReward = 0;
        usersStaking[userAddress].tokenAmount = 0;
        usersStaking[userAddress].rewardUnblockTimestamp = 0;
    }

    function calculateMultiplier(uint256 periodInWeeks) view internal returns (uint256) {
        if (periodInWeeks > 18) {
            return multiplierByWeekAmount[20];
        }
        return multiplierByWeekAmount[periodInWeeks];
    }

    function isEvenNumber(uint256 number) internal pure returns (bool) {
        uint256 div = number / 2;
        return div * 2 == number;
    }

    function calculateUnstakeTimestamp(uint256 periodInWeeks) internal view returns (uint256) {
        return block.timestamp + periodInWeeks * SECONDS_IN_WEEK;
    }

    function calculateUsdtAmountForReward(uint256 amount, uint256 periodInWeeks) public view returns (uint256) {
        uint256 multiplier = calculateMultiplier(periodInWeeks);
        return calculateTokensPriceInUSDT(amount) * multiplier * (periodInWeeks / 2) / MULTIPLIER_DENOMINATOR;
    }
// (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    //todo check order of tokens in pair
//    function calculateTokensPriceInUSDT(uint256 tokenAmount) public view returns (uint256) {
//        (uint256 tokenReserveForBnbPair, uint256 bnbReserve, ) = bnbTokenPair.getReserves();
//        (uint256 usdtReserve, uint256 bnbReserveForUsdtPair, ) = bnbUsdtPair.getReserves();
//        return tokenAmount * bnbReserve * usdtReserve / bnbReserveForUsdtPair / tokenReserveForBnbPair;
//    }

    function calculateTokensPriceInUSDT(uint256 tokenAmount) public view returns (uint256) {
        (uint256 token1Amount, uint256 token2Amount, ) = bnbTokenPair.getReserves();
        (uint256 tokenReserveForBnbPair, uint256 bnbReserve) = reblAddress < wbnbAddress ? (token1Amount, token2Amount) : (token2Amount, token1Amount);
        (uint256 token3Amount, uint256 token4Amount, ) = bnbUsdtPair.getReserves();
        (uint256 usdtReserve, uint256 bnbReserveForUsdtPair) = usdtAddress < wbnbAddress ? (token3Amount, token4Amount) : (token4Amount, token3Amount);
        return tokenAmount * bnbReserve / bnbReserveForUsdtPair * usdtReserve / tokenReserveForBnbPair;
    }

    //todo check order of tokens in pair
//    function calculateTokensAmountForUsdt(uint256 usdtAmount) public view returns (uint256) {
//        ( uint256 usdtReserve, uint256 bnbReserveForUsdtPair, ) = bnbUsdtPair.getReserves();
//        (uint256 tokenReserveForBnbPair, uint256 bnbReserve, ) = bnbTokenPair.getReserves();
//        return usdtAmount * bnbReserveForUsdtPair * tokenReserveForBnbPair / usdtReserve / bnbReserve;
//    }

    function calculateTokensAmountForUsdt(uint256 usdtAmount) public view returns (uint256) {
        (uint256 token1Amount, uint256 token2Amount, ) = bnbUsdtPair.getReserves();
        (uint256 usdtReserve, uint256 bnbReserveForUsdtPair) = usdtAddress < wbnbAddress ? (token1Amount, token2Amount) : (token2Amount, token1Amount);
        (uint256 token3Amount, uint256 token4Amount, ) = bnbTokenPair.getReserves();
        (uint256 tokenReserveForBnbPair, uint256 bnbReserve) = reblAddress < wbnbAddress ? (token3Amount, token4Amount) : (token4Amount, token3Amount);
        return usdtAmount * bnbReserveForUsdtPair / usdtReserve * tokenReserveForBnbPair / bnbReserve;
    }

    function initDEXRouter(address _router) public onlyOwner {
        IPancakeSwap _pancakeV2Router = IPancakeSwap(_router);
        router = _pancakeV2Router;
    }

    function getMinAmountToStake() public view override returns (uint256) {
        return calculateTokensAmountForUsdt(nftContract.getLowestLevelUsdtValue());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

pragma solidity ^0.8.0;

interface IREBLNFT {
    function mintToByAmount(address to, uint256 usdtAmount) external;
    function getLevelsUsdtValues() external view returns (uint256[] memory);
    function getLowestLevelUsdtValue() external view returns (uint256);
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