// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IERC20DecimalsUpgradeable.sol";
import "./interfaces/ICspDaoUpgradeable.sol";
import "./utils/SetUpgradeable.sol";
import "./utils/ModelsUpgradeable.sol";
import "./utils/EnumsUpgradeable.sol";

contract CspDaoUpgradeable is Initializable, OwnableUpgradeable, ICspDaoUpgradeable {
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using SetUpgradeable for SetUpgradeable.AddressSet;

    uint256 private constant MIN_ASSOCIATE_NEBO_BALANCE = 1000 ether;
    uint256 private constant MIN_PRINCIPAL_NEBO_BALANCE = 2500 ether;
    uint256 private constant MIN_PARTNER_NEBO_BALANCE = 5000 ether;
    uint256 private constant MIN_SENIOR_PARTNER_NEBO_BALANCE = 10000 ether;

    address private neboToken;
    SetUpgradeable.AddressSet private topTen;
    ModelsUpgradeable.Pool[] private pools;
    mapping(uint256 => mapping(address => uint256)) tokenMultipliers;
    mapping(uint256 => uint256) private contributions;
    mapping(uint256 => uint256) private ethContributions;
    mapping(uint256 => uint256) private closedEthContributions;
    mapping(uint256 => mapping(address => uint256)) private tokenContributions;
    mapping(uint256 => mapping(address => uint256)) private closedTokenContributions;
    mapping(uint256 => mapping(address => uint256)) private memberContributions;
    mapping(uint256 => mapping(address => uint256)) private memberEthContributions;
    mapping(uint256 => mapping(address => mapping(address => uint256))) private memberTokenContributions;
    mapping(uint256 => mapping(EnumsUpgradeable.Tier => uint256)) private tierMaxAllocations;
    mapping(uint256 => mapping(address => EnumsUpgradeable.Tier)) private memberContributionTiers;
    mapping(uint256 => ModelsUpgradeable.Distribution) private distributions;
    mapping(uint256 => mapping(address => uint256)) private claims;

    function initialize(address _neboToken) public initializer {
        __CspDao_init(_neboToken);
    }

    function __CspDao_init(address _neboToken) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __CspDao_init_unchained(_neboToken);
    }

    function __CspDao_init_unchained(address _neboToken) internal initializer {
        neboToken = _neboToken;
    }

    modifier sufficientEth(uint256 _amount) {
        require(address(this).balance >= _amount, "Insufficient eth amount.");
        _;
    }

    modifier sufficientToken(address _token, uint256 _amount) {
        require(IERC20Upgradeable(_token).balanceOf(address(this)) >= _amount, "Insufficient token amount.");
        _;
    }

    modifier matchingTokensMultipliersCount(uint256 _tokensCount, uint256 _multipliersCount) {
        require(_tokensCount == _multipliersCount, "Tokens/multipliers count missmatch.");
        _;
    }

    modifier poolExists(uint256 _poolId) {
        require(_poolId >= 0 && _poolId < pools.length, "No such pool.");
        _;
    }

    modifier validClosingPool(uint256 _poolId) {
        require(pools[_poolId].status == EnumsUpgradeable.Status.OPENED, "Non opened pool cannot be closed.");
        _;
    }

    modifier validContributionPool(uint256 _poolId) {
        require(pools[_poolId].status == EnumsUpgradeable.Status.OPENED, "Pool not opened for contributions.");
        require(pools[_poolId].maxAllocation > contributions[_poolId], "Max allocation reached.");
        _;
    }

    modifier validDistributionPool(uint256 _poolId) {
        require(
            pools[_poolId].status == EnumsUpgradeable.Status.CLOSED ||
                pools[_poolId].status == EnumsUpgradeable.Status.DISTRIBUTING,
            "Pool not opened for distributions."
        );
        _;
    }

    modifier ethContributionPool(uint256 _poolId) {
        require(pools[_poolId].ethMultiplier > 0, "ETH not allowed.");
        _;
    }

    modifier tokenContributionPool(uint256 _poolId, address _token) {
        require(tokenMultipliers[_poolId][_token] > 0, "Token not allowed.");
        _;
    }

    modifier contributionAllowed(address _sender, uint256 _poolId) {
        EnumsUpgradeable.Tier tier = getTier(_sender);
        require(tier != EnumsUpgradeable.Tier.NONE, "No tier assigned.");
        require(tierMaxAllocations[_poolId][tier] > 0, "Tier not allowed.");
        require(
            tierMaxAllocations[_poolId][tier] > memberContributions[_poolId][_sender],
            "Tier max allocation reached."
        );
        _;
    }

    modifier claimingAllowed(address _sender, uint256 _poolId) {
        EnumsUpgradeable.Tier contributionTier = memberContributionTiers[_poolId][_sender];
        EnumsUpgradeable.Tier currentTier = getTier(_sender);
        bool isTierOk =
            currentTier >= contributionTier ||
                (contributionTier == EnumsUpgradeable.Tier.TOP_TEN &&
                    currentTier == EnumsUpgradeable.Tier.SENIOR_PARTNER);
        require(isTierOk, "Tier lower than required.");
        _;
    }

    function setNeboToken(address _token) external override onlyOwner {
        neboToken = _token;
    }

    function getNeboToken() external view override returns (address) {
        return address(neboToken);
    }

    function transferEth(address payable _recipient, uint256 _amount)
        external
        override
        onlyOwner
        sufficientEth(_amount)
    {
        _recipient.transfer(_amount);
    }

    function transferToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) external override onlyOwner sufficientToken(_token, _amount) {
        require(IERC20Upgradeable(_token).transfer(_recipient, _amount), "Token transfer failed.");
    }

    function setTopTen(address[] memory _topTen) external override onlyOwner {
        topTen.setAddresses(_topTen);
    }

    function getTopTen() external view override returns (address[] memory) {
        return topTen.getAddresses();
    }

    function getTier(address _member) public view override returns (EnumsUpgradeable.Tier) {
        if (topTen.contains(_member)) {
            return EnumsUpgradeable.Tier.TOP_TEN;
        }

        uint256 memberNeboBalance = IERC20Upgradeable(neboToken).balanceOf(_member);

        if (memberNeboBalance >= MIN_SENIOR_PARTNER_NEBO_BALANCE) {
            return EnumsUpgradeable.Tier.SENIOR_PARTNER;
        }
        if (memberNeboBalance >= MIN_PARTNER_NEBO_BALANCE) {
            return EnumsUpgradeable.Tier.PARTNER;
        }
        if (memberNeboBalance >= MIN_PRINCIPAL_NEBO_BALANCE) {
            return EnumsUpgradeable.Tier.PRINCIPAL;
        }
        if (memberNeboBalance >= MIN_ASSOCIATE_NEBO_BALANCE) {
            return EnumsUpgradeable.Tier.ASSOCIATE;
        }
        return EnumsUpgradeable.Tier.NONE;
    }

    function getMemberContributions(address _member) external view override returns (uint256[] memory) {
        uint256 poolsCount = pools.length;
        uint256[] memory singleMemberContributions = new uint256[](poolsCount);
        for (uint256 i; i < poolsCount; i++) {
            singleMemberContributions[i] = memberContributions[i][_member];
        }
        return singleMemberContributions;
    }

    function createPool(ModelsUpgradeable.Pool memory _pool)
        external
        override
        onlyOwner
        matchingTokensMultipliersCount(_pool.contributionTokens.length, _pool.contributionMultipliers.length)
    {
        uint256 poolId = pools.length;
        pools.push(_pool);

        tierMaxAllocations[poolId][EnumsUpgradeable.Tier.ASSOCIATE] = _pool.maxAssociateAllocation;
        tierMaxAllocations[poolId][EnumsUpgradeable.Tier.PRINCIPAL] = _pool.maxPrincipalAllocation;
        tierMaxAllocations[poolId][EnumsUpgradeable.Tier.PARTNER] = _pool.maxPartnerAllocation;
        tierMaxAllocations[poolId][EnumsUpgradeable.Tier.SENIOR_PARTNER] = _pool.maxSeniorPartnerAllocation;
        tierMaxAllocations[poolId][EnumsUpgradeable.Tier.TOP_TEN] = _pool.maxTopTenAllocation;

        uint256 contributionTokensCount = _pool.contributionTokens.length;
        for (uint256 i; i < contributionTokensCount; i++) {
            tokenMultipliers[poolId][_pool.contributionTokens[i]] = _pool.contributionMultipliers[i];
        }
    }

    function updatePool(uint256 _poolId, ModelsUpgradeable.AllocationUpdate memory _allocationUpdate)
        external
        override
        onlyOwner
    {
        pools[_poolId].maxAllocation = _allocationUpdate.maxAllocation;
        pools[_poolId].maxAssociateAllocation = _allocationUpdate.maxAssociateAllocation;
        pools[_poolId].maxPrincipalAllocation = _allocationUpdate.maxPrincipalAllocation;
        pools[_poolId].maxPartnerAllocation = _allocationUpdate.maxPartnerAllocation;
        pools[_poolId].maxSeniorPartnerAllocation = _allocationUpdate.maxSeniorPartnerAllocation;
        pools[_poolId].maxTopTenAllocation = _allocationUpdate.maxTopTenAllocation;
    }

    function closePool(
        uint256 _poolId,
        address payable _fundsRecipient,
        address payable _feeRecipient
    ) external override onlyOwner poolExists(_poolId) validClosingPool(_poolId) {
        uint256 ethContribution = ethContributions[_poolId].sub(closedEthContributions[_poolId]);
        if (ethContribution > 0) {
            uint256 feeEthContribution = ethContribution.mul(pools[_poolId].feePercent).div(10**18);
            uint256 fundsEthContribution = ethContribution.sub(feeEthContribution);
            _feeRecipient.transfer(feeEthContribution);
            _fundsRecipient.transfer(fundsEthContribution);
            closedEthContributions[_poolId] = closedEthContributions[_poolId].add(ethContribution);
        }

        address token;
        uint256 tokenContribution;
        uint256 tokensCount = pools[_poolId].contributionTokens.length;
        for (uint256 i; i < tokensCount; i++) {
            token = pools[_poolId].contributionTokens[i];
            tokenContribution = tokenContributions[_poolId][token].sub(closedTokenContributions[_poolId][token]);
            if (tokenContribution > 0) {
                uint256 feeTokenContribution = tokenContribution.mul(pools[_poolId].feePercent).div(10**18);
                uint256 fundsTokenContribution = tokenContribution.sub(feeTokenContribution);
                require(IERC20Upgradeable(token).transfer(_feeRecipient, feeTokenContribution));
                require(IERC20Upgradeable(token).transfer(_fundsRecipient, fundsTokenContribution));
                closedTokenContributions[_poolId][token] = closedTokenContributions[_poolId][token].add(
                    tokenContribution
                );
            }
        }

        pools[_poolId].status = EnumsUpgradeable.Status.CLOSED;
    }

    function distributePool(
        uint256 _poolId,
        address _token,
        address _sender,
        uint256 _amount,
        uint256 _batchPercent
    ) external override onlyOwner poolExists(_poolId) validDistributionPool(_poolId) {
        tryReceivingToken(_token, _sender, _amount);
        distributions[_poolId].batchesCount++;
        distributions[_poolId].percent = MathUpgradeable.min(distributions[_poolId].percent.add(_batchPercent), 100);
        distributions[_poolId].tokens.push(_token);
        distributions[_poolId].amounts.push(_amount);
        pools[_poolId].status = distributions[_poolId].percent < 100
            ? EnumsUpgradeable.Status.DISTRIBUTING
            : EnumsUpgradeable.Status.FINISHED;
    }

    function getPools() external view override returns (ModelsUpgradeable.Pool[] memory) {
        return pools;
    }

    function contributeEth(uint256 _poolId)
        external
        payable
        override
        poolExists(_poolId)
        validContributionPool(_poolId)
        ethContributionPool(_poolId)
        contributionAllowed(msg.sender, _poolId)
    {
        ModelsUpgradeable.ContributionDataQuery memory query =
            ModelsUpgradeable.ContributionDataQuery(msg.sender, msg.value, getPoolEthMultiplier(_poolId), 18, _poolId);
        (uint256 contribution, uint256 ethContribution) = getContributionData(query);
        addPoolContribution(_poolId, contribution, msg.sender);
        addPoolEthContribution(_poolId, ethContribution, msg.sender);
        setMemberContributionTier(_poolId, msg.sender);

        if (msg.value > ethContribution) {
            uint256 excessEth = msg.value.sub(ethContribution);
            msg.sender.transfer(excessEth);
        }
    }

    function contributeToken(
        uint256 _poolId,
        address _token,
        uint256 _amount
    )
        external
        override
        poolExists(_poolId)
        validContributionPool(_poolId)
        tokenContributionPool(_poolId, _token)
        contributionAllowed(msg.sender, _poolId)
    {
        ModelsUpgradeable.ContributionDataQuery memory query =
            ModelsUpgradeable.ContributionDataQuery(
                msg.sender,
                _amount,
                getPoolTokenMultiplier(_poolId, _token),
                IERC20DecimalsUpgradeable(_token).decimals(),
                _poolId
            );
        (uint256 contribution, uint256 tokenContribution) = getContributionData(query);
        tryReceivingToken(_token, msg.sender, tokenContribution);
        addPoolContribution(_poolId, contribution, msg.sender);
        addPoolTokenContribution(_poolId, tokenContribution, _token, msg.sender);
        setMemberContributionTier(_poolId, msg.sender);
    }

    function claim(uint256 _poolId) external override poolExists(_poolId) claimingAllowed(msg.sender, _poolId) {
        uint256 claimAmount;
        uint256 claimsCount = claims[_poolId][msg.sender];
        uint256 batchesCount = distributions[_poolId].batchesCount;
        for (claimsCount; claimsCount < batchesCount; claimsCount++) {
            claimAmount = getClaimAmount(_poolId, msg.sender, claimsCount);
            require(
                IERC20Upgradeable(distributions[_poolId].tokens[claimsCount]).transfer(msg.sender, claimAmount),
                "Claim transfer failed."
            );
        }
        claims[_poolId][msg.sender] = claimsCount;
    }

    receive() external payable {}

    function getContributionData(ModelsUpgradeable.ContributionDataQuery memory query)
        private
        view
        returns (uint256, uint256)
    {
        EnumsUpgradeable.Tier tier = getTier(query.sender);
        uint256 memberLeftover =
            tierMaxAllocations[query.poolId][tier].sub(memberContributions[query.poolId][query.sender]);
        uint256 totalLeftover = pools[query.poolId].maxAllocation.sub(contributions[query.poolId]);
        uint256 leftover = MathUpgradeable.min(memberLeftover, totalLeftover);
        uint256 multipliedValue = query.amount.mul(query.multiplier).div(query.decimals);
        uint256 leftoverCurrency = leftover.mul(query.decimals).div(query.multiplier);
        uint256 contribution = MathUpgradeable.min(leftover, multipliedValue);
        uint256 contributionCurrency = MathUpgradeable.min(leftoverCurrency, query.amount);
        return (contribution, contributionCurrency);
    }

    function getPoolEthMultiplier(uint256 _poolId) private view returns (uint256) {
        return pools[_poolId].ethMultiplier;
    }

    function getPoolTokenMultiplier(uint256 _poolId, address _token) private view returns (uint256) {
        return tokenMultipliers[_poolId][_token];
    }

    function setMemberContributionTier(uint256 _poolId, address _member) private {
        memberContributionTiers[_poolId][_member] = getTier(_member);
    }

    function addPoolContribution(
        uint256 _poolId,
        uint256 _contribution,
        address _member
    ) private {
        contributions[_poolId] = contributions[_poolId].add(_contribution);
        memberContributions[_poolId][_member] = memberContributions[_poolId][_member].add(_contribution);
    }

    function addPoolEthContribution(
        uint256 _poolId,
        uint256 _contributionEth,
        address _member
    ) private {
        ethContributions[_poolId] = ethContributions[_poolId].add(_contributionEth);
        memberEthContributions[_poolId][_member] = memberEthContributions[_poolId][_member].add(_contributionEth);
    }

    function addPoolTokenContribution(
        uint256 _poolId,
        uint256 _contributionToken,
        address _token,
        address _member
    ) private {
        tokenContributions[_poolId][_token] = tokenContributions[_poolId][_token].add(_contributionToken);
        memberTokenContributions[_poolId][_member][_token] = memberTokenContributions[_poolId][_member][_token];
    }

    function tryReceivingToken(
        address _token,
        address _sender,
        uint256 _amount
    ) private {
        require(IERC20Upgradeable(_token).allowance(_sender, address(this)) >= _amount, "Amount not allowed.");
        require(IERC20Upgradeable(_token).balanceOf(_sender) >= _amount, "Insufficient balance.");
        require(IERC20Upgradeable(_token).transferFrom(_sender, address(this), _amount), "Token transfer failed.");
    }

    function getClaimAmount(
        uint256 _poolId,
        address _sender,
        uint256 _claimIndex
    ) private view returns (uint256) {
        return
            memberContributions[_poolId][_sender].mul(distributions[_poolId].amounts[_claimIndex]).div(
                contributions[_poolId]
            );
    }

    uint256[34] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "../utils/EnumsUpgradeable.sol";
import "../utils/ModelsUpgradeable.sol";

interface ICspDaoUpgradeable {
    // nebo
    function setNeboToken(address _token) external;

    function getNeboToken() external view returns (address);

    function transferEth(address payable _recipient, uint256 _amount) external;

    function transferToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) external;

    // members
    function setTopTen(address[] memory _topTen) external;

    function getTopTen() external view returns (address[] memory);

    function getTier(address _member) external view returns (EnumsUpgradeable.Tier);

    function getMemberContributions(address _member) external view returns (uint256[] memory);

    // pools
    function createPool(ModelsUpgradeable.Pool memory _pool) external;

    function updatePool(uint256 _poolId, ModelsUpgradeable.AllocationUpdate memory _allocationUpdate) external;

    function closePool(
        uint256 _poolId,
        address payable _fundsRecipient,
        address payable _feeRecipient
    ) external;

    function distributePool(
        uint256 _poolId,
        address _token,
        address _sender,
        uint256 _amount,
        uint256 _batchPercent
    ) external;

    function getPools() external view returns (ModelsUpgradeable.Pool[] memory);

    /*

    function refundPool(uint256 _poolId, uint256 _percent) external;
    */

    // users
    function contributeEth(uint256 _poolId) external payable;

    function contributeToken(
        uint256 _poolId,
        address _token,
        uint256 _amount
    ) external;

    function claim(uint256 _poolId) external;

    /*

    function refund(uint256 _poolId) external;
    */
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20DecimalsUpgradeable {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library EnumsUpgradeable {
    enum Status { OPENED, CLOSED, DISTRIBUTING, FINISHED }
    enum Tier { NONE, ASSOCIATE, PRINCIPAL, PARTNER, SENIOR_PARTNER, TOP_TEN }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./EnumsUpgradeable.sol";

library ModelsUpgradeable {
    struct Pool {
        EnumsUpgradeable.Status status;
        string name;
        string iconUrl;
        bool isTopTen;
        uint256 minAllocation; // example: 100 should be sent as 100 * 10^18
        uint256 maxAllocation; // example: 30000 should be sent as 30000 * 10^18
        uint256 feePercent; // example 1% should be sent as 1
        uint256 maxAssociateAllocation; // same as min/maxAllocation
        uint256 maxPrincipalAllocation; // same as min/maxAllocation
        uint256 maxPartnerAllocation; // same as min/maxAllocation
        uint256 maxSeniorPartnerAllocation; // same as min/maxAllocation
        uint256 maxTopTenAllocation; // same as min/maxAllocation
        address[] contributionTokens;
        uint256[] contributionMultipliers; // example: 1.4 should be sent as 1.4 * 10^18
        uint256 ethMultiplier; // example: 1830.34 should be sent as 1830.34 * 10^18
    }

    struct AllocationUpdate {
        uint256 maxAllocation; // example: 30000 should be sent as 30000 * 10^18
        uint256 maxAssociateAllocation; // same as maxAllocation
        uint256 maxPrincipalAllocation; // same as maxAllocation
        uint256 maxPartnerAllocation; // same as maxAllocation
        uint256 maxSeniorPartnerAllocation; // same as maxAllocation
        uint256 maxTopTenAllocation; // same as maxAllocation
    }

    struct Distribution {
        uint256 batchesCount;
        uint256 percent;
        address[] tokens;
        uint256[] amounts;
    }

    struct ContributionDataQuery {
        address sender;
        uint256 amount;
        uint256 multiplier;
        uint256 decimals;
        uint256 poolId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library SetUpgradeable {
    struct AddressSet {
        mapping(address => bool) isAddressInSet;
        address[] addresses;
    }

    function setAddresses(AddressSet storage set, address[] memory _addresses) internal {
        // reset
        uint256 addressesCount = set.addresses.length;
        for (uint256 i; i < addressesCount; i++) {
            set.isAddressInSet[set.addresses[i]] = false;
        }

        // set new
        uint256 newAddressesCount = _addresses.length;
        for (uint256 i; i < newAddressesCount; i++) {
            set.isAddressInSet[_addresses[i]] = true;
        }
        set.addresses = _addresses;
    }

    function getAddresses(AddressSet storage set) internal view returns (address[] memory) {
        return set.addresses;
    }

    function contains(AddressSet storage set, address _address) internal view returns (bool) {
        return set.isAddressInSet[_address];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
library SafeMathUpgradeable {
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

