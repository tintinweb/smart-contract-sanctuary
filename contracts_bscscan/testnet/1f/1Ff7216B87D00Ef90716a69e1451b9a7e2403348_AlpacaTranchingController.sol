// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IVault.sol";

contract AlpacaTranchingController is Ownable {
    using SafeERC20 for IERC20;

    // Our fund accepts superior and inferior investors.
    enum InvestorType {
        SUPERIOR,
        INFERIOR
    }

    // User has one wallet per investor type.
    struct UserWallet {
        // Tranching investment.
        InvestorType investorType;
        uint256 pendingInvestmentAmount;
        uint256 investmentAmount;
        uint256 pendingDivestmentAmount;
        uint256 freeBalance;
        // Tranching farming.
        uint256 farmingReward;
    }

    address public externalEquityAddress;
    address public externalEquityWorkerAddress;
    IERC20 public principalToken;
    IERC20 public loanToken;

    UserWallet[] public userWallets;
    mapping(address => uint256) public superiorWalletIds; // Actually it stores index + 1 because we cannot differentiate default zero value or the first element.
    mapping(address => uint256) public inferiorWalletIds; // Actually it stores index + 1 because we cannot differentiate default zero value or the first element.

    // Total investment amount of this fund. 0 if the fund is not actively investing.
    uint256 totalSuperiorInvestmentAmount;
    uint256 totalInferiorInvestmentAmount;

    // This will impact the distribution weight for profit.
    uint256 public superiorMultiplier = 1;
    uint256 public inferiorMultiplier = 9;

    // Our funds provide farming rewards.
    IERC20 public tgtToken;
    // Last block number that TGT farming rewards distribution occurs.
    uint256 public lastFarmingRewardBlock;
    uint256 public farmingRewardPerBlock;

    AggregatorV3Interface internal priceFeed;

    // contract constructor
    constructor(
        IERC20 _principalToken,
        IERC20 _loanToken,
        IERC20 _tgtToken,
        address _externalEquityAddress,
        address _externalEquityWorkerAddress,
        uint256 _farmingStartBlock,
        uint256 _farmingRewardPerBlock,
        address _priceFeedAddress
    ) {
        principalToken = _principalToken;
        loanToken = _loanToken;
        tgtToken = _tgtToken;
        externalEquityAddress = _externalEquityAddress;
        externalEquityWorkerAddress = _externalEquityWorkerAddress;
        lastFarmingRewardBlock = _farmingStartBlock == 0
            ? block.number
            : _farmingStartBlock;
        farmingRewardPerBlock = _farmingRewardPerBlock;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // ------------------------------------------------------------------------
    // External or public ABIs.

    // Deposit to free balance.
    function deposit(InvestorType _investorType, uint256 _amount) external {
        principalToken.transferFrom(msg.sender, address(this), _amount);

        UserWallet storage userWallet;
        if (!userWalletExists(msg.sender, _investorType)) {
            // Create user wallet if not exists when deposit.
            userWallet = addUserWallet(msg.sender, _investorType);
        } else {
            userWallet = getUserWallet(msg.sender, _investorType);
        }

        userWallet.freeBalance += _amount;

        invest(_investorType, _amount);
    }

    // Invest partial free balance.
    function invest(InvestorType _investorType, uint256 _amount) public {
        UserWallet storage userWallet = getUserWallet(
            msg.sender,
            _investorType
        );

        require(
            _amount <= userWallet.freeBalance,
            "The free balance is not enough to invest."
        );

        userWallet.pendingInvestmentAmount += _amount;
        userWallet.freeBalance -= _amount;
    }

    // Divest, if _amount is larger than the investment amount,
    function divest(InvestorType _investorType, uint256 _amount) public {
        UserWallet storage userWallet = getUserWallet(
            msg.sender,
            _investorType
        );

        // Cancel previous pending investment.
        userWallet.freeBalance += userWallet.pendingInvestmentAmount;
        userWallet.pendingInvestmentAmount = 0;

        // Consider overflow problem. When divest all, the _amount is the maximum of uint256.
        if (userWallet.pendingDivestmentAmount > type(uint256).max - _amount) {
            userWallet.pendingDivestmentAmount = type(uint256).max;
        } else {
            userWallet.pendingDivestmentAmount += _amount;
        }
    }

    function withdrawAll(InvestorType _investorType) external {
        UserWallet storage userWallet = getUserWallet(
            msg.sender,
            _investorType
        );

        withdraw(_investorType, userWallet.freeBalance);
    }

    // Withdraw all free balance and farming reward.
    function withdraw(InvestorType _investorType, uint256 _amount) public {
        UserWallet storage userWallet = getUserWallet(
            msg.sender,
            _investorType
        );

        require(
            userWallet.freeBalance > 0,
            "You do not have balance to withdraw."
        );

        require(
            userWallet.freeBalance >= _amount,
            "You do not have enough balance to withdraw."
        );

        // Transfer the amount from current contract to this investor.
        principalToken.transfer(msg.sender, _amount);
        userWallet.freeBalance -= _amount;

        if (userWallet.farmingReward > 0) {
            // Transfer TGT rewards from current contract to this investor.
            tgtToken.transfer(msg.sender, userWallet.farmingReward);

            // Reset farming reward.
            userWallet.farmingReward = 0;
        }
    }

    // We will close / open position on daily basis by owner only.
    function closePosition() external onlyOwner {
        if (getTotalInvestmentAmount() == 0) {
            // Position is already closed.
            return;
        }

        distributeFarmingReward();

        closeInvestmentPosition();
        settleInvestmentInterest();

        // Update total investment amount.
        totalSuperiorInvestmentAmount = 0;
        totalInferiorInvestmentAmount = 0;
    }

    function openPosition() external onlyOwner {
        if (getTotalInvestmentAmount() > 0) {
            // Position is already opened.
            return;
        }

        // For all user wallets, move pendingInvestmentAmount to investmentAmount.
        // Also update total investment amount.
        for (uint256 wid = 0; wid < userWallets.length; ++wid) {
            UserWallet storage userWallet = userWallets[wid];
            userWallet.investmentAmount += userWallet.pendingInvestmentAmount;
            userWallet.pendingInvestmentAmount = 0;

            if (userWallet.investorType == InvestorType.SUPERIOR) {
                totalSuperiorInvestmentAmount += userWallet.investmentAmount;
            } else {
                totalInferiorInvestmentAmount += userWallet.investmentAmount;
            }
        }

        openInvestmentPosition();
    }

    // Get total investment amount by investor type
    function getTotalInvestmentAmountByInvestorType(InvestorType _investorType)
        external
        view
        returns (uint256)
    {
        uint256 result = 0;
        for (uint256 wid = 0; wid < userWallets.length; ++wid) {
            UserWallet storage userWallet = userWallets[wid];

            if (userWallet.investorType == _investorType) {
                result += userWallet.investmentAmount;
            }
        }

        return result;
    }

    // Get single account details
    function getAccountDetails(address _investor, InvestorType _investorType)
        external
        view
        returns (UserWallet memory userWallet)
    {
        if (!userWalletExists(_investor, _investorType)) {
            // Return empty user wallet;
            UserWallet memory userWallet;
            return userWallet;
        }

        return getUserWallet(_investor, _investorType);
    }

    // ------------------------------------------------------------------------
    // Private ABIs.

    // Distribute farming rewards to each investor's wallets.
    function distributeFarmingReward() private {
        uint256 totalFarmingRewards = getTotalPendingFarmingReward();

        if (totalFarmingRewards == 0) {
            return;
        }

        uint256 totalInvestmentAmount = getTotalInvestmentAmount();

        for (uint256 wid = 0; wid < userWallets.length; ++wid) {
            UserWallet storage userWallet = userWallets[wid];
            if (userWallet.investmentAmount > 0) {
                userWallet.farmingReward +=
                    (userWallet.investmentAmount * totalFarmingRewards) /
                    totalInvestmentAmount;
            }
        }

        lastFarmingRewardBlock = block.number;
    }

    // Distribute investment interests to each investor's wallets.
    function settleInvestmentInterest() private {
        int256 newTotalInterest = getTotalPendingInvestmentInterest();

        // If newTotalInterest is non-negative, we will distribute the profit according to pre-defined multipliers.
        // Otherwise we will let inferior investors to pay the loss.
        uint256 effectiveSuperiorMultiplier = superiorMultiplier;
        uint256 effectiveInferiorMultiplier = inferiorMultiplier;
        if (newTotalInterest < 0) {
            effectiveSuperiorMultiplier = 0;
            effectiveInferiorMultiplier = 1;
        }

        uint256 totalWeights = totalSuperiorInvestmentAmount *
            effectiveSuperiorMultiplier +
            totalInferiorInvestmentAmount *
            effectiveInferiorMultiplier;

        if (totalWeights == 0) {
            // There is no investment.
            return;
        }

        // Distribute new total interest to all wallets according to superior and inferior multiplier.
        for (uint256 wid = 0; wid < userWallets.length; ++wid) {
            UserWallet storage userWallet = userWallets[wid];
            uint256 effectiveMultiplier = userWallet.investorType ==
                InvestorType.SUPERIOR
                ? effectiveSuperiorMultiplier
                : effectiveInferiorMultiplier;
            int256 newInterest = (int256(userWallet.investmentAmount) *
                int256(effectiveMultiplier) *
                newTotalInterest) / int256(totalWeights);

            // Add interest (might be negative) to investment amount.
            userWallet.investmentAmount = uint256(
                int256(userWallet.investmentAmount) + newInterest
            );

            // Handle divestment request.
            if (
                userWallet.pendingDivestmentAmount > userWallet.investmentAmount
            ) {
                // The investor can divest at most the total investment amount.
                userWallet.pendingDivestmentAmount = userWallet
                    .investmentAmount;
            }

            userWallet.investmentAmount -= userWallet.pendingDivestmentAmount;
            userWallet.freeBalance += userWallet.pendingDivestmentAmount;
            userWallet.pendingDivestmentAmount = 0;

            // Handle investment request.
            userWallet.investmentAmount += userWallet.pendingInvestmentAmount;
            userWallet.pendingInvestmentAmount = 0;
        }
    }

    function userWalletExists(address _signer, InvestorType _investorType)
        private
        view
        returns (bool)
    {
        if (_investorType == InvestorType.SUPERIOR) {
            return superiorWalletIds[_signer] > 0;
        } else {
            return inferiorWalletIds[_signer] > 0;
        }
    }

    function getUserWallet(address _signer, InvestorType _investorType)
        private
        view
        returns (UserWallet storage)
    {
        require(
            userWalletExists(_signer, _investorType),
            "You have no wallet in this fund."
        );

        uint256 walletId;
        if (_investorType == InvestorType.SUPERIOR) {
            walletId = superiorWalletIds[_signer] - 1;
        } else {
            walletId = inferiorWalletIds[_signer] - 1;
        }

        return userWallets[walletId];
    }

    function addUserWallet(address _signer, InvestorType _investorType)
        private
        returns (UserWallet storage)
    {
        require(
            !userWalletExists(_signer, _investorType),
            "You already have a wallet in this fund."
        );

        UserWallet memory userWallet = UserWallet({
            investorType: _investorType,
            pendingInvestmentAmount: 0,
            investmentAmount: 0,
            pendingDivestmentAmount: 0,
            freeBalance: 0,
            farmingReward: 0
        });
        userWallets.push(userWallet);

        if (_investorType == InvestorType.SUPERIOR) {
            superiorWalletIds[_signer] = userWallets.length;
        } else {
            inferiorWalletIds[_signer] = userWallets.length;
        }

        return userWallets[userWallets.length - 1];
    }

    function getTotalInvestmentAmount() private view returns (uint256) {
        return totalSuperiorInvestmentAmount + totalInferiorInvestmentAmount;
    }

    function getTotalPendingFarmingReward() private view returns (uint256) {
        if (block.number <= lastFarmingRewardBlock) {
            return 0;
        }

        uint256 tgtBalance = tgtToken.balanceOf(address(this));

        if (tgtBalance == 0) {
            // There is no TGT for reward distribution.
            return 0;
        }

        if (getTotalInvestmentAmount() == 0) {
            // There is no investment for farming reward distribution.
            return 0;
        }

        uint256 totalFarmingRewards = farmingRewardPerBlock *
            (block.number - lastFarmingRewardBlock);
        if (totalFarmingRewards > tgtBalance) {
            totalFarmingRewards = tgtBalance;
        }

        return totalFarmingRewards;
    }

    // -------------------------------------------------------------------------------------
    // Alpaca related ABIs.

    function openInvestmentPosition() private {
        uint256 totalInvestmentAmount = getTotalInvestmentAmount();

        // TODO: open an Alpaca position with total investment amount.
    }

    function closeInvestmentPosition() private {
        // TODO: close the Alpaca position.
    }

    function getExternalInvestmentAmount() private view returns (int256) {
        // TODO: get all equity from Alpaca.
        // For testing purpose it's always 100k more than current total investment amount which means every open / close position we should have 100k investment gains.
        int256 totalAmount = int256(getTotalInvestmentAmount()) + 100000;
        return totalAmount;
    }

    function getTotalPendingInvestmentInterest() private view returns (int256) {
        return
            getExternalInvestmentAmount() - int256(getTotalInvestmentAmount());
    }

    /**
     * Convert the principal token to loan token.
     * Reference: https://docs.chain.link/docs/get-the-latest-price/
     */
    function convertPrincipalAmountToLoanAmount(int256 _amount)
        private
        view
        returns (int256)
    {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return price;
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

// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩
  ξ ･×･ ξ
  ξ　~　ξ
  ξ　　 ξ
  ξ　　 “~～~～〇
  ξ　　　　　　 ξ
  ξ ξ ξ~～~ξ ξ ξ
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity >= 0.6.6;

interface IVault {

  /// @dev Return the total ERC20 entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);

  /// @dev Add more ERC20 to the bank. Hope to get some good returns.
  function deposit(uint256 amountToken) external payable;

  /// @dev Withdraw ERC20 from the bank by burning the share tokens.
  function withdraw(uint256 share) external;

  /// @dev Request funds from user through Vault
  function requestFunds(address targetedToken, uint amount) external;

  function token() external view returns (address);

  /// @dev Create a new farming position to unlock your yield farming potential.
  /// @param id The ID of the position to unlock the earning. Use ZERO for new position.
  /// @param worker The address of the authorized worker to work for this position.
  /// @param principalAmount The anout of Token to supply by user.
  /// @param borrowAmount The amount of Token to borrow from the pool.
  /// @param maxReturn The max amount of Token to return to the pool.
  /// @param data The calldata to pass along to the worker for more working context.
  function work(
    uint256 id,
    address worker,
    uint256 principalAmount,
    uint256 borrowAmount,
    uint256 maxReturn,
    bytes calldata data
  ) external payable;
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