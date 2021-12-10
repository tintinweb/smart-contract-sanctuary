// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./WithLimits.sol";
import "./Timed.sol";
import "./WithWhitelist.sol";
import "./WithLevelsSale.sol";
import "./Withdrawable.sol";
import "./GeneralIDO.sol";

contract LaunchpadIDO is Adminable, ReentrancyGuard, Timed, GeneralIDO, Withdrawable, WithLimits, WithWhitelist, WithLevelsSale {

    using SafeERC20 for IERC20;

    string public id;
    uint256 public tokensSold;
    uint256 public raised;
    uint256 public participants;
    mapping(address => uint256) public balances;
    uint256 public firstPurchaseBlockN;
    uint256 public lastPurchaseBlockN;

    event TokensPurchased(
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor(
        string memory _id,
        uint256 _startTime,
        uint256 _duration,
        uint256 _rate,
        uint256 _tokensForSale,
        address _fundToken
    )
    GeneralIDO(_rate, _tokensForSale)
    Timed(_startTime, _duration)
    Withdrawable(_fundToken)
    {
        id = _id;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    receive() external payable {
        require(
            !fundByTokens,
            "Sale: This presale is funded by tokens, use buyTokens(value)"
        );
        buyTokens();
    }

    fallback() external {
        revert("Sale: Cannot buy, use the 'buyTokens' function");
    }

    function buyTokens() public payable ongoingSale nonReentrant {
        require(
            !fundByTokens,
            "Sale: presale is funded by tokens but value is missing"
        );

        internalBuyTokens(msg.value);
    }

    /**
     * The fund token must be first approved to be transferred by presale contract for the given "value".
     */
    function buyTokens(uint256 value) public ongoingSale nonReentrant {
        require(fundByTokens, "Sale: funding by tokens is not allowed");
        require(
            fundToken.allowance(msg.sender, address(this)) >= value,
            "Sale: fund token not approved"
        );

        internalBuyTokens(value);

        fundToken.safeTransferFrom(msg.sender, address(this), value);
    }

    function internalBuyTokens(uint256 value) private {
        uint256 maxAllocation = checkAccountAllowedToBuy();
        address account = _msgSender();

        require(value > 0, "Sale: value is 0");
        uint256 amount = calculatePurchaseAmount(value);
        require(amount > 0, "Sale: amount is 0");

        tokensSold += amount;
        balances[account] += amount;

        require(value >= minSell, "Sale: amount is too small");
        require(
            maxAllocation == 0 || balances[account] <= maxAllocation,
            "Sale: amount exceeds max allocation"
        );
        require(tokensSold <= tokensForSale, "Sale: cap reached");

        raised = raised + value;
        participants = participants + 1;

        // Store the first and last block numbers to simplify data collection later
        if (firstPurchaseBlockN == 0) {
            firstPurchaseBlockN = block.number;
        }
        lastPurchaseBlockN = block.number;

        emit TokensPurchased(account, value, amount);
    }

    function checkAccountAllowedToBuy() private view returns (uint256) {
        address account = _msgSender();
        uint256 levelAllocation = getUserLevelAllocation(account);
        uint256 maxAllocation = calculatePurchaseAmount(maxSell);

        // Public sale with no whitelist or levels
        if (!whitelistEnabled && !levelsEnabled) {
            return maxAllocation;
        }

        // User whitelisted, consider his level allocation too
        if (whitelistEnabled && whitelisted[msg.sender]) {
            if (levelAllocation > 0 && levelsOpenAll()) {
                (, , uint256 fcfsAllocation, ) = getUserLevelState(account);
                require(
                    fcfsAllocation > 0,
                    "Sale: user does not have FCFS allocation"
                );
                levelAllocation = fcfsAllocation;
            }

            return maxAllocation + levelAllocation;
        }
        if (whitelistEnabled && !levelsEnabled) {
            revert("Sale: not in the whitelist");
        }

        // Check user level if levels enabled and user was not whitelisted
        if (levelsEnabled) {
            require(
                baseAllocation > 0,
                "Sale: levels are enabled but baseAllocation is not set"
            );

            // If opened for all levels, just return the level allocation without checking user weight
            if (levelsOpenAll()) {
                (, , uint256 fcfsAllocation, ) = getUserLevelState(account);
                require(
                    fcfsAllocation > 0,
                    "Sale: user does not have FCFS allocation"
                );

                return fcfsAllocation;
            }

            bytes memory levelBytes = bytes(userLevel[account]);
            require(
                levelBytes.length > 0,
                "Sale: user level is not registered"
            );
            require(
                levelAllocation > 0,
                "Sale: user has no level allocation, not registered, lost lottery or level is too low"
            );

            return levelAllocation;
        }

        revert("Sale: unreachable state");
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Adminable is Ownable, AccessControl {

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyOwnerOrAdmin() {
        require(
            owner() == _msgSender() || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Adminable: caller is not the owner or admin"
        );
        _;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./access/Adminable.sol";

abstract contract Withdrawable is Adminable {

    using SafeERC20 for IERC20;

    bool public fundByTokens = false;
    IERC20 public fundToken;

    event FundTokenChanged(address tokenAddress);

    constructor(address _fundToken) {
        fundByTokens = _fundToken != address(0);
        if (fundByTokens) {
            fundToken = IERC20(_fundToken);
        }
    }

    function setFundToken(address tokenAddress) external onlyOwnerOrAdmin {
        fundByTokens = tokenAddress != address(0);
        fundToken = IERC20(tokenAddress);
        emit FundTokenChanged(tokenAddress);
    }

    /**
     * Withdraw ALL both BNB and the currency token if specified
     */
    function withdrawAll() external onlyOwnerOrAdmin {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }

        if (fundByTokens && fundToken.balanceOf(address(this)) > 0) {
            fundToken.transfer(owner(), fundToken.balanceOf(address(this)));
        }
    }

    /**
     * Withdraw the specified amount of BNB or currency token
     */
    function withdrawBalance(uint256 amount) external onlyOwnerOrAdmin {
        require(amount > 0, "Withdrawable: amount should be greater than zero");
        if (fundByTokens) {
            fundToken.transfer(owner(), amount);
        } else {
            payable(owner()).transfer(amount);
        }
    }

    /**
     * When tokens are sent to the sale by mistake: withdraw the specified token.
     */
    function withdrawToken(address token, uint256 amount) external onlyOwnerOrAdmin {
        require(amount > 0, "Withdrawable: amount should be greater than zero");
        IERC20(token).transfer(owner(), amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/Adminable.sol";
import "./GeneralIDO.sol";
import "./WithLimits.sol";

abstract contract WithWhitelist is Adminable, GeneralIDO, WithLimits {

    bool public whitelistEnabled = true;
    mapping(address => bool) public whitelisted;
    address[] public whitelistedAddresses;
    uint256 internal whitelistedCount;

    event WhitelistEnabled(bool status);

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return whitelistedAddresses;
    }

    // Return tokens amount allocated for whitelist
    function whitelistAllocation() public view returns (uint256) {
        uint256 whitelistAlloc = calculatePurchaseAmount(maxSell);
        return whitelistAlloc * whitelistedCount;
    }

    function toggleWhitelist(bool status) public onlyOwnerOrAdmin {
        whitelistEnabled = status;
        emit WhitelistEnabled(status);
    }

    function batchAddWhitelisted(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (!whitelisted[addresses[i]]) {
                whitelisted[addresses[i]] = true;
                whitelistedAddresses.push(addresses[i]);
                whitelistedCount += 1;
            }
        }
    }

    function batchRemoveWhitelisted(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (whitelisted[addresses[i]]) {
                whitelisted[addresses[i]] = false;
                whitelistedCount -= 1;
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/Adminable.sol";

abstract contract WithLimits is Adminable {

    // Max sell per user in currency
    uint256 public maxSell;
    // Min contribution per TX in currency
    uint256 public minSell;

    event MinChanged(uint256 value);
    event MaxChanged(uint256 value);

    function getMinMaxLimits() external view returns (uint256, uint256) {
        return (minSell, maxSell);
    }

    function setMin(uint256 value) public onlyOwnerOrAdmin {
        require(maxSell == 0 || value <= maxSell, "Must be smaller than max");
        minSell = value;
        emit MinChanged(value);
    }

    function setMax(uint256 value) public onlyOwnerOrAdmin {
        require(minSell == 0 || value >= minSell, "Must be bigger than min");
        maxSell = value;
        emit MaxChanged(value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/Adminable.sol";
import "./Timed.sol";
import "./GeneralIDO.sol";
import "./WithWhitelist.sol";
import "./WithLimits.sol";
import "./ILevelManager.sol";
import "./WithKYC.sol";

abstract contract WithLevelsSale is Adminable, Timed, GeneralIDO, WithLimits, WithWhitelist, WithKYC {

    ILevelManager public levelManager;
    bool public levelsEnabled = true;
    bool public forceLevelsOpenAll = false;
    bool public lockOnRegister = true;
    bool public isVip = false;

    // Sum of weights (lottery losers are subtracted when picking winners) for base allocation calculation
    uint256 public totalWeights;
    // Base allocation is 1x in TOKENS
    uint256 public baseAllocation;
    // 0 - all levels, 6 - starting from "associate", etc
    uint256 public minAllowedLevelMultiplier;
    // Min allocation in TOKENS after registration closes. If 0, then ignored
    uint256 public minBaseAllocation;

    mapping(string => address[]) public levelAddresses;
    // Whether (and how many) winners were picked for a lottery level
    mapping(string => address[]) public levelWinners;
    // Needed for user allocation calculation = baseAllocation * userWeight
    // If user lost lottery, his weight resets to 0 - means user can't participate in sale
    mapping(address => uint8) public userWeight;
    mapping(address => string) public userLevel;

    event BaseAllocationCalculated(uint256 baseAllocation);
    event BaseAllocationChanged(uint256 baseAllocation);
    event MinBaseAllocationChanged(uint256 minBaseAllocation);
    event LevelManagerChanged(address staking);
    event LevelsEnabled(bool status);
    event VipEnabled(bool status);
    event SaleOpenedForAllLevels(bool status);
    event LockOnRegisterEnabled(bool status);
    event WinnersPicked(
        string tierId,
        uint256 totalN,
        uint256 winnersN,
        address[] winners
    );
    event Registered(
        address indexed account,
        string levelId,
        uint256 weight,
        bool tokensLocked
    );
    event MinAllowedLevelMultiplierChanged(uint256 multiplier);

    modifier ongoingRegister() {
        require(!isLive(), "Sale: Cannot register, sale is live");

        require(
            !reachedMinBaseAllocation(),
            "Sale: Min base allocation reached, registration closed"
        );
        require(isRegistering(), "Sale: Not open for registration");
        _;
    }

    function levelsOpenAll() public view returns (bool) {
        return forceLevelsOpenAll || isFcfsTime();
    }

    function isRegisterTime() internal view returns (bool) {
        return block.timestamp > registerTime && block.timestamp < registerTime + registerDuration;
    }

    function isRegistering() public view returns (bool) {
        return isRegisterTime() && !reachedMinBaseAllocation();
    }

    function reachedMinBaseAllocation() public view returns (bool) {
        if (minBaseAllocation == 0) {
            return false;
        }
        uint256 allocation = baseAllocation > 0 ? baseAllocation : getAutoBaseAllocation();
        return allocation < minBaseAllocation;
    }

    /**
     * Return: id, multiplier, allocation, isWinner.
     *
     * User is a winner when:
     * - winners were picked for the level
     * - user has non-zero weight (i.e. registered and not excluded as loser)
     * - the level is a lottery level
     */
    function getUserLevelState(address account) public view returns (string memory, uint256, uint256, bool) {
        bool levelsOpen = levelsOpenAll();

        bytes memory levelBytes = bytes(userLevel[account]);
        ILevelManager.Tier memory tier = levelsOpen ? levelManager.getUserTier(account) : levelManager.getTierById(
            levelBytes.length == 0 ? "none" : userLevel[account]
        );

        // For non-registered in non-FCFS = 0
        uint8 weight = levelsOpen ? tier.multiplier : userWeight[account];
        uint256 allocation = weight * baseAllocation;

        uint16 fcfsMultiplier = getFcfsAllocationMultiplier();
        allocation += (allocation * fcfsMultiplier) / 100;

        bool isWinner = levelBytes.length == 0 ? false : tier.random && levelWinners[tier.id].length > 0 && userWeight[account] > 0;

        return (tier.id, weight, allocation, isWinner);
    }

    /**
     * Returns multiplier for FCFS allocation, with 2 decimals. 1x = 100
     * The result allocation will be = baseAllocation + baseAllocation * fcfsMultiplier
     * When forceLevelsOpenAll is enabled, registered users get 2x allocation, non-registered 1x.
     */
    function getFcfsAllocationMultiplier() public view returns (uint16) {
        if (forceLevelsOpenAll) {
            return 100;
        }
        if (!isFcfsTime()) {
            return 0;
        }

        // Let's imagine the fcfs duration is 60 minutes, then...
        uint256 fcfsStartTime = getEndTime() - fcfsDuration;
        uint256 quarterTime = fcfsDuration / 4;
        // first 15 minutes
        if (block.timestamp < fcfsStartTime + quarterTime) {
            return 35;
        }
        // 15-30 minutes
        if (block.timestamp < fcfsStartTime + quarterTime * 2) {
            return 80;
        }
        // 30-45 minutes
        if (block.timestamp < fcfsStartTime + quarterTime * 3) {
            return 200;
        }
        // last 15 minutes - 100x
        return 10000;
    }

    function getUserLevelAllocation(address account) public view returns (uint256) {
        return userWeight[account] * baseAllocation;
    }

    function getLevelAddresses(string calldata id) external view returns (address[] memory) {
        return levelAddresses[id];
    }

    function getLevelWinners(string calldata id) external view returns (address[] memory) {
        return levelWinners[id];
    }

    function getLevelNumbers() external view returns (string[] memory, uint256[] memory) {
        string[] memory ids = levelManager.getTierIds();
        uint256[] memory counts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            counts[i] = levelAddresses[ids[i]].length;
        }
        return (ids, counts);
    }

    function getLevelNumber(string calldata id) external view returns (uint256) {
        return levelAddresses[id].length;
    }

    function toggleLevels(bool status) external onlyOwnerOrAdmin {
        levelsEnabled = status;
        emit LevelsEnabled(status);
    }

    function toggleVip(bool status) external onlyOwnerOrAdmin {
        isVip = status;
        emit VipEnabled(status);
    }

    function openForAllLevels(bool status) external onlyOwnerOrAdmin {
        forceLevelsOpenAll = status;
        emit SaleOpenedForAllLevels(status);
    }

    function toggleLockOnRegister(bool status) external onlyOwnerOrAdmin {
        lockOnRegister = status;
        emit LockOnRegisterEnabled(status);
    }

    function setBaseAllocation(uint256 _baseAllocation) external onlyOwnerOrAdmin {
        baseAllocation = _baseAllocation;
        emit BaseAllocationChanged(baseAllocation);
    }

    function setMinBaseAllocation(uint256 value) external onlyOwnerOrAdmin {
        minBaseAllocation = value;
        emit MinBaseAllocationChanged(minBaseAllocation);
    }

    function setLevelManager(ILevelManager _levelManager) external onlyOwnerOrAdmin {
        levelManager = _levelManager;
        emit LevelManagerChanged(address(levelManager));
    }

    function setMinAllowedLevelMultiplier(uint256 multiplier) external onlyOwnerOrAdmin {
        minAllowedLevelMultiplier = multiplier;
        emit MinAllowedLevelMultiplierChanged(multiplier);
    }

    function getAutoBaseAllocation() internal view returns (uint256) {
        uint256 weights = totalWeights > 0 ? totalWeights : 1;
        uint256 levelsAlloc = tokensForSale - whitelistAllocation();
        return levelsAlloc / weights;
    }

    /**
     * Find the new base allocation based on total weights of all levels, # of whitelisted accounts and their max buy.
     * Should be called after winners are picked.
     */
    function updateBaseAllocation() external onlyOwnerOrAdmin {
        baseAllocation = getAutoBaseAllocation();
        emit BaseAllocationCalculated(baseAllocation);
    }

    /**
     * Register a user with his current level multiplier.
     * Level multiplier is added to total weights, which later is used to calculate the base allocation.
     * Address is stored, so we can see all registered people.
     *
     * Later, when picking winners, loser weight is removed from total weights for correct base allocation calculation.
     */
    function register() external ongoingRegister {
        require(levelsEnabled, "Sale: Cannot register, levels disabled");
        require(
            address(levelManager) != address(0),
            "Sale: Levels staking address is not specified"
        );

        if (kycEnabled) {
            require(addressKYCStatus(_msgSender()), "Sale: Address is not on KYC list");
        }

        address account = _msgSender();
        ILevelManager.Tier memory tier = levelManager.getUserTier(account);
        require(tier.multiplier > 0, "Sale: Your level is too low to register");

        require(
            userWeight[account] == 0 || tier.multiplier >= userWeight[account],
            "Sale: Already registered with lower level"
        );

        // If user re-registers with higher level...
        if (userWeight[account] > 0) {
            totalWeights -= userWeight[account];
        }

        // Lock the staked tokens based on the current user level.
        if (lockOnRegister) {
            levelManager.lock(account, startTime);
        }

        userLevel[account] = tier.id;
        userWeight[account] = tier.multiplier;
        totalWeights += tier.multiplier;
        levelAddresses[tier.id].push(account);

        // TODO: maybe remove so we allow the allocation to drop lower
        //        require(
        //            !reachedMinBaseAllocation(),
        //            "Sale: Min base allocation reached, registration closed"
        //        );

        emit Registered(account, tier.id, tier.multiplier, lockOnRegister);
    }

    function setWinners(string calldata id, address[] calldata winners) external onlyOwnerOrAdmin {
        uint8 weight = levelManager.getTierById(id).multiplier;

        for (uint256 i = 0; i < levelAddresses[id].length; i++) {
            address addr = levelAddresses[id][i];
            // Skip users who re-registered
            if (!stringsEqual(userLevel[addr], id)) {
                continue;
            }
            totalWeights -= userWeight[addr];
            userWeight[addr] = 0;
        }

        for (uint256 i = 0; i < winners.length; i++) {
            address addr = winners[i];
            // Skip users who re-registered
            if (!stringsEqual(userLevel[addr], id)) {
                continue;
            }
            totalWeights += weight;
            userWeight[addr] = weight;
            userLevel[addr] = id;
        }
        levelWinners[id] = winners;

        emit WinnersPicked(
            id,
            levelAddresses[id].length,
            winners.length,
            winners
        );
    }

    function batchRegisterLevel(string memory tierId, uint256 weight, address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            address account = addresses[i];

            if (userWeight[account] > 0) {
                totalWeights -= userWeight[account];
            }

            userLevel[account] = tierId;
            userWeight[account] = uint8(weight);
            totalWeights += weight;
            levelAddresses[tierId].push(account);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/Adminable.sol";
import "./IKYC.sol";

abstract contract WithKYC is Adminable {

    IKYC public kycContract;

    bool public kycEnabled = true;

    event KYCContractChanged(address _address);

    event KYCStatusChanged(bool _bool);

    function setKYCContract(address _address) external onlyOwnerOrAdmin {
        require(_address != address(0), "KYC address cannot be zero address");
        kycContract = IKYC(_address);
        emit KYCContractChanged(_address);
    }

    function toggleKYCStatus(bool status) external onlyOwnerOrAdmin {
        kycEnabled = status;
        emit KYCStatusChanged(status);
    }

    function addressKYCStatus(address _address) public view returns (bool) {
        if (kycEnabled && address(kycContract) != address(0)) {
            return kycContract.addressStatus(_address);
        }
        return false;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./access/Adminable.sol";

abstract contract Timed is Adminable {

    uint256 public startTime;
    uint256 public duration;
    uint256 public registerTime;
    uint256 public registerDuration;
    // FCFS starts from: end - fcfsDuration
    uint256 public fcfsDuration;

    event StartChanged(uint256 time);
    event DurationChanged(uint256 duration);
    event RegisterTimeChanged(uint256 time);
    event RegisterDurationChanged(uint256 duration);
    event FCFSDurationChanged(uint256 duration);

    constructor(uint256 _startTime, uint256 _saleDuration) {
        startTime = _startTime;
        duration = _saleDuration;
    }

    modifier ongoingSale() {
        require(isLive(), "Sale: Not live");
        _;
    }

    function isLive() public view returns (bool) {
        return block.timestamp > startTime && block.timestamp < getEndTime();
    }

    function isFcfsTime() public view returns (bool) {
        return block.timestamp + fcfsDuration > getEndTime();
    }

    function getEndTime() public view returns (uint256) {
        return startTime + duration;
    }

    function setStartTime(uint256 newTime) public onlyOwnerOrAdmin {
        require(
            newTime > registerTime,
            "Sale: start time must be after the register time"
        );
        startTime = newTime;
        emit StartChanged(startTime);
    }

    function setDuration(uint256 newDuration) public onlyOwnerOrAdmin {
        duration = newDuration;
        emit DurationChanged(duration);
    }

    function setRegisterTime(uint256 newTime) public onlyOwnerOrAdmin {
        require(
            newTime < startTime,
            "Sale: register time must be before the start time"
        );
        registerTime = newTime;
        emit RegisterTimeChanged(registerTime);
    }

    function setRegisterDuration(uint256 newDuration) public onlyOwnerOrAdmin {
        require(
            registerTime + newDuration < startTime,
            "Sale: register end must be before the start time"
        );
        registerDuration = newDuration;
        emit RegisterDurationChanged(registerDuration);
    }

    function setFCFSDuration(uint256 newDuration) public onlyOwnerOrAdmin {
        fcfsDuration = newDuration;
        emit FCFSDurationChanged(duration);
    }

    function setTimeline(
        uint256 _registerTime,
        uint256 _registerDuration,
        uint256 _fcfsDuration
    ) external onlyOwnerOrAdmin {
        setRegisterTime(_registerTime);
        setRegisterDuration(_registerDuration);
        setFCFSDuration(_fcfsDuration);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILevelManager {

    struct Tier {
        string id;
        uint8 multiplier;
        uint256 lockingPeriod; // in seconds
        uint256 minAmount; // tier is applied when userAmount >= minAmount
        bool random;
        uint8 odds; // divider: 2 = 50%, 4 = 25%, 10 = 10%
        bool vip;
    }

    function getAlwaysRegister() external view returns (address[] memory, string[] memory, uint256[] memory);

    function isLocked(address account) external view returns (bool);

    function getTierById(string calldata id) external view returns (Tier memory);

    function getUserTier(address account) external view returns (Tier memory);

    function getUserUnlockTime(address account) external view returns (uint256);

    function getTierIds() external view returns (string[] memory);

    function lock(address account, uint256 idoStart) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKYC {

    event KYCAdded(address _address);

    event KYCRemoved(address _address);

    function addressStatus(address _address) external view returns (bool);

    function add(address _address) external;

    function remove(address _address) external;

    function batchAdd(address[] calldata _addresses) external;

    function batchRemove(address[] calldata _addresses) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Timed.sol";
import "./access/Adminable.sol";

abstract contract GeneralIDO is Adminable, Timed {

    // Actual rate is: rate / 1e6
    // 6.123456 actual rate = 6123456 specified rate
    uint256 public rate;
    uint256 public tokensForSale;

    event RateChanged(uint256 newRate);
    event CapChanged(uint256 newRate);

    constructor(uint256 _rate, uint256 _tokensForSale) {
        rate = _rate;
        tokensForSale = _tokensForSale;
    }

    function setTokensForSale(uint256 _tokensForSale) external onlyOwnerOrAdmin {
        require(
            !isLive() || _tokensForSale > tokensForSale,
            "Sale: Sale is live, cap change only allowed to a higher value"
        );
        tokensForSale = _tokensForSale;
        emit CapChanged(tokensForSale);
    }

    function calculatePurchaseAmount(uint256 purchaseAmountWei) public view returns (uint256) {
        return (purchaseAmountWei * rate) / 1e6;
    }

    function setRate(uint256 newRate) public onlyOwnerOrAdmin {
        require(!isLive(), "Sale: Sale is live, rate change not allowed");
        rate = newRate;
        emit RateChanged(rate);
    }

    function stringsEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

    constructor() {
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
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}