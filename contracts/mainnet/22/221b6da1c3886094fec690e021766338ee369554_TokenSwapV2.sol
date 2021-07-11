/**
 *Submitted for verification at Etherscan.io on 2021-07-11
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



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
    constructor () {
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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol



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

// File: @chainlink\contracts\src\v0.8\interfaces\AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// File: contracts\TokenSwapV2.sol


pragma solidity ^0.8.0;




contract TokenSwapV2 is Ownable {

    event PriceFeedUpdated(address addr);
    event AdminWalletUpdated(address addr);
    event TokenWithdrawed(uint256 amount);

    event PhaseCreated(uint256 phaseId, uint256 lockPercentage, uint256 lockReleaseTime, uint256 minDeposit, uint256 totalSupply, uint256 pricePerToken, uint256 startTime, uint256 endTime);
    event PhaseTimeUpdated(uint256 phaseId, uint256 startTime, uint256 endTime);
    event LockInfoUpdated(uint256 phaseId, uint256 lockPercentage, uint256 lockReleaseTime);
    event SaleInfoUpdated(uint256 phaseId, uint256 minDeposit, uint256 totalSupply, uint256 pricePerToken);

    event Swapped(uint256 phaseId, address account, uint256 ethDeposited, uint256 ethRefunded, uint256 tokenSold, uint256 tokenLocked, int ethPrice);

    event TokenClaimed(uint256 phaseId, address account, uint256 amount);

    uint256 private constant ONE_HUNDRED_PERCENT = 10000; // 100%

    IERC20 private _token;

    AggregatorV3Interface private _priceFeed;

    address private _adminWallet;

    struct ReferralCodeInfo {
        uint128 amount; // ETH
        uint128 numSwap;
    }

    // Mapping referral code to statistics information
    mapping(string => ReferralCodeInfo) private _referralCodes;

    struct PhaseInfo {
        uint128 lockPercentage;
        uint128 lockReleaseTime;
        uint128 minDeposit;
        uint128 pricePerToken; // 100000000 <=> 1 USD
        uint128 startTime;
        uint128 endTime;
        uint128 totalLocked;
        uint128 totalSold;
        uint128 totalSupply;
    }

    uint256 private _totalPhases;

    // Mapping phase id to phase information
    mapping(uint256 => PhaseInfo) private _phases;

    uint256 private _totalLockBalance;

    // Mapping phase id to user address and locked balance information
    mapping(uint256 => mapping(address => uint256)) private _lockBalances;

    /**
     * @dev Throws if phase doesn't exist
     */
    modifier phaseExist(uint256 phaseId) {
        require(_phases[phaseId].totalSupply > 0, "TokenSwapV2: phase doesn't exist");
        _;
    }

    /**
     * @dev Sets initial values
     */
    constructor(address token, address priceFeed, address adminWallet)
    {
        _token = IERC20(token);

        _priceFeed = AggregatorV3Interface(priceFeed);

        _adminWallet = adminWallet;
    }

    /**
     * @dev Returns smart contract information
     */
    function getContractInfo()
        external
        view
        returns (address, address, uint256, uint256, uint256)
    {
        return (
            _adminWallet, address(_token),
            _token.balanceOf(address(this)), _totalPhases, _totalLockBalance
        );
    }

    /**
     * @dev Updates price feed
     */
    function updatePriceFeed(address priceFeed)
        external
        onlyOwner
    {
        require(priceFeed != address(0), "TokenSwapV2: address is invalid");

        _priceFeed = AggregatorV3Interface(priceFeed);

        emit PriceFeedUpdated(priceFeed);
    }

    /**
     * @dev Updates admin wallet address where contains ETH user deposited
     * to smart contract for swapping
     */
    function updateAdminWallet(address adminWallet)
        external
        onlyOwner
    {
        require(adminWallet != address(0), "TokenSwapV2: address is invalid");

        _adminWallet = adminWallet;

        emit AdminWalletUpdated(adminWallet);
    }

    /**
     * @dev Withdraws token out of this smart contract and transfer to 
     * admin wallet
     *
     * Admin can withdraw all tokens that includes locked token of user in case emergency
     */
    function withdrawAllFund(uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "TokenSwapV2: amount is invalid");

        _token.transfer(_adminWallet, amount);

        emit TokenWithdrawed(amount);
    }

    /**
     * @dev Creates new phase
     */
    function createPhase(uint128 lockPercentage, uint128 lockReleaseTime, uint128 minDeposit, uint128 totalSupply, uint128 pricePerToken, uint128 startTime, uint128 endTime)
        external
        onlyOwner
    {
        require(lockPercentage <= ONE_HUNDRED_PERCENT, "TokenSwapV2: percentage is invalid");

        require(minDeposit > 0 && totalSupply > 0 && pricePerToken > 0, "TokenSwapV2: value must be greater than zero");

        require(startTime > block.timestamp && startTime < endTime, "TokenSwapV2: time is invalid");

        uint256 id = ++_totalPhases;

        PhaseInfo storage phase = _phases[id];
        phase.lockPercentage = lockPercentage;
        phase.lockReleaseTime = lockReleaseTime;
        phase.minDeposit = minDeposit;
        phase.pricePerToken = pricePerToken;
        phase.startTime = startTime;
        phase.endTime = endTime;
        phase.totalSupply = totalSupply;

        emit PhaseCreated(id, lockPercentage, lockReleaseTime, minDeposit, totalSupply, pricePerToken, startTime, endTime);
    }

    /**
     * @dev Updates lock information
     */
    function updateLockInfo(uint256 phaseId, uint128 lockPercentage, uint128 lockReleaseTime)
        external
        onlyOwner
        phaseExist(phaseId)
    {
        require(lockPercentage <= ONE_HUNDRED_PERCENT, "TokenSwapV2: percentage is invalid");

        PhaseInfo storage phase = _phases[phaseId];

        require(phase.totalSold == 0, "TokenSwapV2: can't update");

        phase.lockPercentage = lockPercentage;
        phase.lockReleaseTime = lockReleaseTime;

        emit LockInfoUpdated(phaseId, lockPercentage, lockReleaseTime);
    }

    /**
     * @dev Updates sale information
     */
    function updateSaleInfo(uint256 phaseId, uint128 minDeposit, uint128 totalSupply, uint128 pricePerToken)
        external
        onlyOwner
        phaseExist(phaseId)
    {
        PhaseInfo storage phase = _phases[phaseId];

        if (minDeposit != 0) {
            phase.minDeposit = minDeposit;
        }

        if (totalSupply != 0) {
            phase.totalSupply = totalSupply;
        }

        if (pricePerToken != 0) {
            phase.pricePerToken = pricePerToken;
        }

        if (totalSupply != 0 || pricePerToken != 0) {
            require(phase.totalSold == 0, "TokenSwapV2: can't update");
        }

        emit SaleInfoUpdated(phaseId, minDeposit, totalSupply, pricePerToken);
    }

    /**
     * @dev Updates phase time
     */
    function updatePhaseTime(uint256 phaseId, uint128 startTime, uint128 endTime)
        external
        onlyOwner
        phaseExist(phaseId)
    {
        PhaseInfo storage phase = _phases[phaseId];

        if (startTime != 0) {
            phase.startTime = startTime;
        }

        if (endTime != 0) {
            phase.endTime = endTime;
        }

        require((startTime == 0 || startTime > block.timestamp) && phase.startTime < phase.endTime, "TokenSwapV2: time is invalid");

        emit PhaseTimeUpdated(phaseId, startTime, endTime);
    }

    /**
     * @dev Returns phase information
     */
    function getPhase(uint256 phaseId)
        external
        view
        returns (PhaseInfo memory)
    {
        return _phases[phaseId];
    }

    /**
     * @dev Returns phases information
     * @param filter 1: active, 2: ended, 3: all
     */
    function getPhases(uint256 phaseFrom, uint256 phaseTo, uint256 filter)
        external
        view
        returns (uint256[] memory, PhaseInfo[] memory)
    {
        uint256 cnt = 0;
        uint256 size = phaseTo - phaseFrom + 1;
        uint256 currentTime = block.timestamp;

        uint256[] memory tmpIds = new uint256[](size);

        PhaseInfo[] memory tmpPhases = new PhaseInfo[](size);

        for (uint256 i = phaseFrom; i <= phaseTo; i++) {
            PhaseInfo memory phase = _phases[i];

            if (phase.totalSupply == 0 || (filter == 1 && currentTime >= phase.endTime) || (filter == 2 && currentTime < phase.endTime)) {
                continue;
            }

            tmpIds[cnt] = i;
            tmpPhases[cnt] = phase;
            cnt++;
        }

        uint256[] memory ids = new uint256[](cnt);

        PhaseInfo[] memory phases = new PhaseInfo[](cnt);

        for (uint256 i = 0; i < cnt; i++) {
            ids[i] = tmpIds[i];
            phases[i] = tmpPhases[i];
        }

        return (ids, phases);
    }

    /**
     * @dev Swaps ETH to token
     */
    function swap(uint256 phaseId, string memory referralCode)
        external
        payable
    {
        PhaseInfo storage phase = _phases[phaseId];

        require(block.timestamp >= phase.startTime && block.timestamp < phase.endTime, "TokenSwapV2: not in swapping time");

        require(msg.value >= phase.minDeposit, "TokenSwapV2: deposit amount isn't enough");

        uint256 remain = phase.totalSupply - phase.totalSold;

        require(remain > 0, "TokenSwapV2: total supply isn't enough");

        (, int ethPrice,,,) = _priceFeed.latestRoundData();

        uint256 amount = msg.value * uint256(ethPrice) / phase.pricePerToken;

        uint refund;

        // Calculates redundant money
        if (amount > remain) {
            refund = (amount - remain) * phase.pricePerToken / uint256(ethPrice);
            amount = remain;
        }

        require(amount <= (_token.balanceOf(address(this)) - _totalLockBalance), "TokenSwapV2: balance isn't enough");

        // Refunds redundant money for user
        if (refund > 0) {
            payable(_msgSender()).transfer(refund);
        }

        // Transfers money to admin wallet
        payable(_adminWallet).transfer(msg.value - refund);

        // Calculates number of tokens that will be locked
        uint256 locked = amount * phase.lockPercentage / ONE_HUNDRED_PERCENT;

        // Transfers token for user
        _token.transfer(_msgSender(), amount - locked);

        if (locked > 0) {
            _totalLockBalance += locked;

            _lockBalances[phaseId][_msgSender()] += locked;

            phase.totalLocked += uint128(locked);
        }

        phase.totalSold += uint128(amount);

        // Manages referral codes
        ReferralCodeInfo storage referral = _referralCodes[referralCode];
        referral.amount += uint128(msg.value - refund);
        referral.numSwap++;

        emit Swapped(phaseId, _msgSender(), msg.value, refund, amount, locked, ethPrice);
    }

    /**
     * @dev Returns token balance of user in smart contract that includes
     * claimable and unclaimable
     */
    function getUserBalance(address account, uint256 phaseFrom, uint256 phaseTo)
        external
        view
        returns (uint256, uint256)
    {
        uint256 currentTime = block.timestamp;
        uint256 balance;
        uint256 lockBalance;

        for (uint256 i = phaseFrom; i <= phaseTo; i++) {
            uint256 amount = _lockBalances[i][account];

            if (amount == 0) {
                continue;
            }

            if (_phases[i].lockReleaseTime <= currentTime) {
                balance += amount;

            } else {
                lockBalance += amount;
            }
        }

        return (balance, lockBalance);
    }

    /**
     * @dev Claims the remainning token after lock time end
     */
    function claimToken(uint256 phaseFrom, uint256 phaseTo)
        external
    {
        address msgSender = _msgSender();
        uint256 currentTime = block.timestamp;
        uint256 balance;

        for (uint256 i = phaseFrom; i <= phaseTo; i++) {
            uint256 amount = _lockBalances[i][msgSender];

            if (amount == 0) {
                continue;
            }

            if (_phases[i].lockReleaseTime <= currentTime) {
                balance += amount;

                _phases[i].totalLocked -= uint128(amount);

                emit TokenClaimed(i, msgSender, amount);

                delete _lockBalances[i][msgSender];
            }
        }

        require(balance > 0, "TokenSwapV2: amount must be greater than zero");

        _totalLockBalance -= balance;

        _token.transfer(msgSender, balance);
    }

    /**
     * @dev Returns referral code information
     */
    function getReferralCodeInfo(string memory referralCode)
        external
        view
        returns (ReferralCodeInfo memory)
    {
        return _referralCodes[referralCode];
    }

    /**
     * @dev Returns ETH/USD price
     */
    function getEtherPrice()
        external
        view
        returns (int)
    {
        (, int price,,,) = _priceFeed.latestRoundData();

        return price;
    }

}