/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: GLABattle.sol



pragma solidity ^0.8.0;



contract GLABattle is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeMath for uint112;
    address public gameManager;
    address public glaMinter;
    uint256 constant MIN_CLAIM = 1000 * 10**18; // Need to fight at least 10 battles, refund 100 GLA each => 1000 GLA
    uint256 constant REFUND_THRESHOLD = 125000; // 1 GLA = 0.000008 BNB
    address GLA_BNB_LP;
    uint256 rateReward = 80; // actual reward received = rateReward * maxReward
    uint256 heroLvBaseRate = 60; // reward rate to Hero LV1
    uint256 evilLvBaseRate = 60; // reward rate to fight evil LV1
    uint256 baseTokenReward = 160;
    uint256 baseExpReward = 10;
    mapping(uint8 => uint256) weightOfEvilLv;
    mapping(uint8 => uint256) minuteCoolDownForRarity;
    mapping(uint8 => uint8) winRateAgainstEvilLevel;
    mapping(address => uint256) claimableBattleFee; // address => battle fee

    modifier onlyHeroOwner(uint256 heroId) {
        address heroContractAddr = IGameManager(gameManager).getContract(
            "GLAHeroNFT"
        );
        require(IGLAHeroNFT(heroContractAddr).getOwnerOf(heroId) == msg.sender);
        _;
    }
    modifier onlyGameManager() {
        require(gameManager == msg.sender, "Authorization failed!");
        _;
    }
    event BattleResult(
        uint256 indexed heroId,
        bool result,
        uint256 tokenReward,
        uint256 expReward
    );

    constructor(address _gameManager, address _glaMinter, bool isMainnet) Ownable() {
        gameManager = _gameManager;
        glaMinter =_glaMinter;
        if (isMainnet) {
            GLA_BNB_LP = 0xb07fe60e59e635e37512C03372301365C97f5E54;
        } else {
            GLA_BNB_LP = 0xAd769f38CDcDD73f2acBc3b412b688E3643bC802;
        }

        minuteCoolDownForRarity[1] = 360;
        minuteCoolDownForRarity[2] = 330;
        minuteCoolDownForRarity[3] = 300;
        minuteCoolDownForRarity[4] = 270;
        minuteCoolDownForRarity[5] = 240;
        minuteCoolDownForRarity[6] = 210;

        winRateAgainstEvilLevel[1] = 80;
        winRateAgainstEvilLevel[2] = 60;
        winRateAgainstEvilLevel[3] = 40;
        winRateAgainstEvilLevel[4] = 20;

        weightOfEvilLv[1] = 1;
        weightOfEvilLv[2] = 2;
        weightOfEvilLv[3] = 3;
        weightOfEvilLv[4] = 5;
    }

    function battle(uint256 heroId, uint8 evilLevel)
        external
        onlyHeroOwner(heroId)
    {
        require(tx.origin == msg.sender, "Hello bots, not glad to see ya!");
        require(evilLevel >= 1 && evilLevel <= 4, "Invalid level!");
        address heroContractAddr = IGameManager(gameManager).getContract(
            "GLAHeroNFT"
        );
        address heroOwner = IGLAHeroNFT(heroContractAddr).getOwnerOf(heroId);
        uint8 heroRarity = IGLAHeroNFT(heroContractAddr).getHeroRarity(heroId);
        uint256 lastBattleTime = IGLAHeroNFT(heroContractAddr)
            .getLastBattleTime(heroId);
        uint256 coolDownTime = minuteCoolDownForRarity[heroRarity];
        require(
            block.timestamp >= lastBattleTime + coolDownTime * 1 minutes,
            "Your Hero needs some rest util the next battle!"
        );
        uint256 tokenReward = 0;
        uint256 expReward = 5;
        uint8 heroLevel = IGLAHeroNFT(heroContractAddr).getHeroLevel(heroId);
        bool result = _win(evilLevel);

        if (result) {
            expReward = _getExpReward(evilLevel, heroRarity, heroLevel);
            tokenReward = _getTokenReward(evilLevel, heroRarity, heroLevel);
            _transferGLA(heroOwner, tokenReward);
        }

        IGLAHeroNFT(heroContractAddr).gainExp(heroId, expReward);
        IGLAHeroNFT(heroContractAddr).setLastBattleTime(heroId);
        emit BattleResult(heroId, result, tokenReward.div(10**18), expReward);
        if (isRefundable()) {
            claimableBattleFee[msg.sender] += 100 * 10**18;
        }
    }

    function _win(uint8 evilLevel) internal view returns (bool) {
        uint256 rnd = _random(100);
        if (rnd < winRateAgainstEvilLevel[evilLevel]) {
            return true;
        }
        return false;
    }

    function _getTokenReward(
        uint8 evilLevel,
        uint8 heroRarity,
        uint8 heroLevel
    ) internal view returns (uint256) {
        uint256 evilLevelRate = 100;
        uint256 heroLevelRate = 100;
        if (evilLevel > 1) {
            evilLevelRate = weightOfEvilLv[evilLevel].mul(evilLvBaseRate);
        }
        if (heroLevel > 1) {
            heroLevelRate = heroLevel.mul(heroLvBaseRate);
        }
        uint256 maxReward = baseTokenReward
            .mul(10**18)
            .mul(heroRarity)
            .mul(heroLevelRate)
            .div(100)
            .mul(evilLevelRate)
            .div(100);
        return maxReward.mul(rateReward).div(100);
    }

    function _getExpReward(
        uint8 evilLevel,
        uint8 heroRarity,
        uint8 heroLevel
    ) internal view returns (uint256) {
        uint256 evilLevelRate = 100;
        uint256 heroLevelRate = 100;
        if (evilLevel > 1) {
            evilLevelRate = weightOfEvilLv[evilLevel].mul(evilLvBaseRate);
        }
        if (heroLevel > 1) {
            heroLevelRate = heroLevel.mul(heroLvBaseRate);
        }
        return
            baseExpReward
                .mul(heroRarity)
                .mul(heroLevelRate)
                .div(100)
                .mul(evilLevelRate)
                .div(100);
    }

    function _random(uint256 range) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        blockhash(block.number - 1),
                        block.gaslimit,
                        block.coinbase,
                        block.timestamp,
                        gasleft()
                    )
                )
            ) % range;
    }

    function setGameManager(address gameManager_) public onlyOwner {
        gameManager = gameManager_;
    }

    function setBaseTokenReward(uint8 _baseTokenReward) public onlyGameManager {
        baseTokenReward = _baseTokenReward;
    }

    function setBaseExpReward(uint256 _baseExpReward) public onlyGameManager {
        baseExpReward = _baseExpReward;
    }

    function setWinRate(uint8 evilLevel, uint8 value) public onlyGameManager {
        require(
            evilLevel >= 1 && evilLevel <= 4 && value <= 100,
            "Invalid input!"
        );
        winRateAgainstEvilLevel[evilLevel] = value;
    }

    function setCoolDown(uint8 rarity, uint256 minute) public onlyGameManager {
        require(rarity >= 1 && rarity <= 6);
        minuteCoolDownForRarity[rarity] = minute;
    }

    function setWeightOfEvilLv(uint8 _evilLevel, uint256 _weightOfEvilLv)
        public
        onlyGameManager
    {
        require(_evilLevel >= 1 && _evilLevel <= 4, "Invalid input!");
        weightOfEvilLv[_evilLevel] = _weightOfEvilLv;
    }
    
    function setGLAMinter(address _glaMinter) public onlyOwner{
        glaMinter =_glaMinter;
    }

    function getClaimableFee(address user) public view returns (uint256) {
        return claimableBattleFee[user];
    }

    function getPriceBNBGLA() public view returns (uint256) {
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IPancakePair(GLA_BNB_LP).getReserves();
        if (reserve0 > reserve1) {
            return reserve0.div(reserve1);
        } else {
            return reserve1.div(reserve0);
        }
    }

    function claimBattleFee() public {
        uint256 claimAmount = getClaimableFee(msg.sender);
        require(claimAmount >= MIN_CLAIM, "Not battle enough to claim!");
        claimableBattleFee[msg.sender] = 0;
        _transferGLA(msg.sender, claimAmount);
    }

    function isRefundable() internal view returns (bool) {
        return getPriceBNBGLA() >= REFUND_THRESHOLD;
    }

    function _transferGLA(address to_, uint256 amount_) internal {
        IGLAMinter(glaMinter).mint(to_, amount_);
    }
}

interface IGameManager {
    function getContract(string memory contract_)
        external
        view
        returns (address);

    function getDevWallet() external view returns (address);
}

interface IGLAHeroNFT {
    function gainExp(uint256 tokenId_, uint256 amount) external;

    function getHeroLevel(uint256 tokenId_) external view returns (uint8);

    function getHeroRarity(uint256 tokenId_) external view returns (uint8);

    function getLastBattleTime(uint256 tokenId_)
        external
        view
        returns (uint256);

    function getOwnerOf(uint256 tokenId_) external view returns (address);

    function setLastBattleTime(uint256 tokenId_) external;
}


interface IGLAMinter{
    function mint(address to, uint256 amount) external;
}

interface IPancakePair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}