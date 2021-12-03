// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "Ownable.sol";
import "AggregatorV3Interface.sol";
import "ILendingPoolAddressesProvider.sol";
import "ILendingPool.sol";
import "IWeth.sol";
import "IERC20.sol";

contract EscrowFarm is Ownable {
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => mapping(address => uint256)) public startTime;
    mapping(address => mapping(address => uint256)) public stakingValue;
    mapping(address => mapping(address => uint256)) public stakingRaw;
    mapping(address => mapping(address => bool)) public isStaking;
    mapping(address => uint256) public usdInPool;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    mapping(address => address) public aaveatoken;
    mapping(address => uint256) private check;
    address[] public Stakers;
    address[] public allowedTokens;
    address wethaddress = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address poolAddress;
    IWeth iweth;
    ILendingPoolAddressesProvider provider;
    ILendingPool lendingPool;
    IERC20 nadavToken;
    address private higherstaker;
    uint256 public higheststaker;
    uint256 public creationtime;

    constructor(address _nadavTokenAddress) {
        nadavToken = IERC20(_nadavTokenAddress);
        provider = ILendingPoolAddressesProvider(
            address(0x88757f2f99175387aB4C6a4b3067c77A695b0349)
        );
        iweth = IWeth(wethaddress);
        creationtime = block.timestamp;
        higheststaker = 0;
        higherstaker = msg.sender;
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function stakenAdavTokens(uint256 _amount) public {
        require(
            block.timestamp < creationtime + 100 days,
            "end time passed no more bids"
        );
        require(_amount > 0, "Amount must be more than 0");
        nadavToken.transferFrom(msg.sender, address(this), _amount);
        if (_amount > higheststaker) {
            higheststaker = _amount;
            higherstaker = msg.sender;
        }
    }

    function calculateYieldTime(address _token, address _user)
        public
        view
        returns (uint256)
    {
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[_token][_user];
        return totalTime;
    }

    function calculateLastYieldUser(address _token, address _user)
        public
        view
        returns (uint256)
    {
        uint256 time = calculateYieldTime(_token, _user) * 10**18;
        uint256 rate = 86400;
        uint256 timeRate = time / rate;
        uint256 rawYield = (stakingValue[_token][_user] * timeRate) / 10**18;
        return rawYield;
    }

    function getUserTotalRaw(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (isStaking[_token][_user] == false) {
            return 0;
        }
        uint256 totalValue = calculateLastYieldUser(_token, msg.sender);
        totalValue = totalValue + stakingRaw[_token][_user];
        return totalValue;
    }

    function getAllUsersRaw(address _token) public view returns (uint256) {
        uint256 AlltotalValue = 0;
        for (
            uint256 stakersIndex = 0;
            stakersIndex < Stakers.length;
            stakersIndex++
        ) {
            address recipient = Stakers[stakersIndex];
            AlltotalValue += getUserTotalRaw(recipient, _token);
        }
        return AlltotalValue;
    }

    function getUserBalance(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (isStaking[_token][_user] == false) {
            return 0;
        }
        return stakingBalance[_token][_user];
    }

    function getAllUsersBalance(address _token) public view returns (uint256) {
        uint256 AlltotalValue = 0;
        for (
            uint256 stakersIndex = 0;
            stakersIndex < Stakers.length;
            stakersIndex++
        ) {
            address recipient = Stakers[stakersIndex];
            AlltotalValue += getUserBalance(recipient, _token);
        }
        return AlltotalValue;
    }

    function updateUniqueTokensStaked(address _user) internal {
        uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
    }

    function getTokenValue(address _token, uint256 _amount)
        public
        view
        returns (uint256)
    {
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        uint256 aprice = uint256(price);
        return ((_amount * aprice) / (10**decimals));
    }

    function addAllowedTokens(address _token, address _atoken)
        public
        onlyOwner
    {
        allowedTokens.push(_token);
        aaveatoken[_token] = _atoken;
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(tokenIsAllowed(_token), "Token is currently not allowed");
        if (isStaking[_token][msg.sender] == true) {
            uint256 toTransfer = calculateLastYieldUser(_token, msg.sender);
            stakingRaw[_token][msg.sender] =
                stakingRaw[_token][msg.sender] +
                toTransfer;
        }
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        uint256 toUSD = getTokenValue(_token, _amount);
        stakingValue[_token][msg.sender] = toUSD;
        usdInPool[_token] = usdInPool[_token] + toUSD;
        startTime[_token][msg.sender] = block.timestamp;
        isStaking[_token][msg.sender] = true;
        if (uniqueTokensStaked[msg.sender] == 1) {
            Stakers.push(msg.sender);
            nadavToken.transfer(msg.sender, 2 * toUSD);
        } else {
            nadavToken.transfer(msg.sender, toUSD);
        }
        poolAddress = provider.getLendingPool();
        lendingPool = ILendingPool(poolAddress);
        IERC20(_token).approve(poolAddress, _amount);
        IERC20(_token).approve(address(this), _amount);
        lendingPool.deposit(_token, _amount, address(this), 0);
    }

    function stakeEath() external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        uint256 _amount = msg.value;
        if (isStaking[wethaddress][msg.sender] == true) {
            uint256 toTransfer = calculateLastYieldUser(
                wethaddress,
                msg.sender
            );
            stakingRaw[wethaddress][msg.sender] =
                stakingRaw[wethaddress][msg.sender] +
                toTransfer;
        }
        updateUniqueTokensStaked(msg.sender);
        stakingBalance[wethaddress][msg.sender] =
            stakingBalance[wethaddress][msg.sender] +
            _amount;
        uint256 toUSD = getTokenValue(wethaddress, _amount);
        stakingValue[wethaddress][msg.sender] = toUSD;
        usdInPool[wethaddress] = usdInPool[wethaddress] + toUSD;
        startTime[wethaddress][msg.sender] = block.timestamp;
        isStaking[wethaddress][msg.sender] = true;
        if (uniqueTokensStaked[msg.sender] == 1) {
            Stakers.push(msg.sender);
            nadavToken.transfer(msg.sender, 2 * toUSD);
        } else {
            nadavToken.transfer(msg.sender, toUSD);
        }
        poolAddress = provider.getLendingPool();
        lendingPool = ILendingPool(poolAddress);
        IERC20(wethaddress).approve(poolAddress, _amount);
        IERC20(wethaddress).approve(address(this), _amount);
        iweth.deposit{value: msg.value}();
        lendingPool.deposit(wethaddress, _amount, address(this), 0);
    }

    function unstakeTokens(address _token) public {
        require(
            stakingBalance[_token][msg.sender] > 0,
            "Staking balance cannot be 0"
        );
        require(
            calculateYieldTime(_token, msg.sender) > 60,
            "Less than 24 houres from deposit"
        );
        poolAddress = provider.getLendingPool();
        lendingPool = ILendingPool(poolAddress);
        uint256 deposited = getAllUsersBalance(_token);
        uint256 profit = IERC20(aaveatoken[_token]).balanceOf(address(this)) -
            deposited;
        uint256 userraw = getUserTotalRaw(_token, msg.sender);
        uint256 totalraw = getAllUsersRaw(_token);
        uint256 totransfer = (((userraw * profit) / 2) * totalraw) +
            stakingBalance[_token][msg.sender];
        if (
            msg.sender == higherstaker &&
            block.timestamp > creationtime + 90 days &&
            block.timestamp < creationtime + 100 days &&
            check[_token] <= 0
        ) {
            check[_token] = check[_token] + 1;
            totransfer = profit + stakingBalance[_token][msg.sender];
        }
        startTime[_token][msg.sender] = block.timestamp;
        stakingBalance[_token][msg.sender] = 0;
        stakingRaw[_token][msg.sender] = 0;
        usdInPool[_token] -= stakingValue[_token][msg.sender];
        stakingValue[_token][msg.sender] = 0;
        isStaking[_token][msg.sender] = false;
        IERC20(aaveatoken[_token]).approve(poolAddress, totransfer);
        IERC20(aaveatoken[_token]).approve(address(this), totransfer);
        lendingPool.withdraw(_token, totransfer, msg.sender);
    }

    function unstakeAsETH() public {
        address _token = wethaddress;
        require(
            stakingBalance[_token][msg.sender] > 0,
            "Staking balance cannot be 0"
        );
        require(
            calculateYieldTime(_token, msg.sender) > 60,
            "Less than 24 houres from deposit"
        );
        poolAddress = provider.getLendingPool();
        lendingPool = ILendingPool(poolAddress);
        uint256 deposited = getAllUsersBalance(_token);
        uint256 profit = IERC20(aaveatoken[_token]).balanceOf(address(this)) -
            deposited;
        uint256 userraw = getUserTotalRaw(_token, msg.sender);
        uint256 totalraw = getAllUsersRaw(_token);
        uint256 totransfer = ((userraw * profit) / totalraw) +
            stakingBalance[_token][msg.sender];
        if (
            msg.sender == higherstaker &&
            block.timestamp > creationtime + 90 days &&
            block.timestamp < creationtime + 100 days &&
            check[_token] <= 0
        ) {
            check[_token] = check[_token] + 1;
            totransfer = profit + stakingBalance[_token][msg.sender];
        }
        startTime[_token][msg.sender] = block.timestamp;
        stakingBalance[_token][msg.sender] = 0;
        stakingRaw[_token][msg.sender] = 0;
        usdInPool[_token] -= stakingValue[_token][msg.sender];
        stakingValue[_token][msg.sender] = 0;
        isStaking[_token][msg.sender] = false;
        IERC20(aaveatoken[_token]).approve(poolAddress, totransfer);
        IERC20(aaveatoken[_token]).approve(address(this), totransfer);
        lendingPool.withdraw(_token, totransfer, address(this));
        iweth.withdraw(totransfer);
        payable(msg.sender).transfer(totransfer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
pragma solidity >=0.6.0 <0.9.0;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.0 <0.9.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "ILendingPoolAddressesProvider.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function getAddressesProvider()
        external
        view
        returns (ILendingPoolAddressesProvider);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19 <0.9.0;

interface IWeth {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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