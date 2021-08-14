// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;
// pragma experimental SMTChecker;

import {IvETH2} from "./interfaces/IvETH2.sol";
import {ISharedDeposit} from "./interfaces/ISharedDeposit.sol";
import {ITokenManager} from "./interfaces/ITokenManager.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {IBlocklist} from "./interfaces/IBlocklist.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import {OwnershipRolesTemplate} from "./util/OwnershipRolesTemplate.sol";
import {Eth2DepositHelperUpgradeable} from "./util/Eth2DepositHelperUpgradeable.sol";
import {VaultWithSharesAndCapUpgradeable} from "./util/VaultWithSharesAndCapUpgradeable.sol";
import {WithdrawQueueUpgradeable} from "./util/WithdrawQueueUpgradeable.sol";

contract SharedDepositV2 is
    OwnershipRolesTemplate,
    Eth2DepositHelperUpgradeable,
    VaultWithSharesAndCapUpgradeable,
    WithdrawQueueUpgradeable
{
    using SafeMath for uint256;
    /* ========== STATE VARIABLES ========== */

    uint256 public adminFee;
    uint256 public numValidators;
    uint256 public costPerValidator;

    // The validator shares created by this shared stake contract. 1 share costs >= 1 eth
    uint256 public curValidatorShares; //initialized to 0

    // The number of times the deposit to eth2 contract has been called to create validators
    // uint256 public validatorsCreated; //initialized to 0
    // Now inherited and managed in Eth2DepositHelperUpgradeable

    // Total accrued admin fee
    uint256 public adminFeeTotal; //initialized to 0

    // Its hard to exactly hit the max deposit amount with small shares. this allows a small bit of overflow room
    // Eth in the buffer cannot be withdrawn by an admin, only by burning the underlying token via a user withdraw
    // uint256 public buffer;
    // now inherited from VaultWithSharesAndCapUpgradeable

    // Flash loan tokenomic protection in case of changes in admin fee with future lots
    bool public disableWithdrawRefund; //initialized to false

    bool public minterTransferPetrified;
    bool public depositsEnabled;

    // address public BETHTokenAddress;
    IvETH2 public _BETHToken;

    uint256 public performanceFeePrct;

    uint256 public constant BIPS_DENOM = 10000;

    address public priceOracleAddress;
    IPriceOracle private _priceOracle;
    address public tokenManagerAddress;
    ITokenManager private _tokenManager;
    address public blocklistAddress;
    IBlocklist private _blocklist;
    /* ========== STATE VARIABLES ========== */

    // =============== EVENTS =================
    event Withdraw(address indexed _from, uint256 _value);
    event RecievedEther(address indexed _from, uint256 _value);

    // =============== EVENTS =================

    // ================ Fall back functions to recieve ether ================
    receive() external payable {
        emit RecievedEther(_msgSender(), msg.value);
    }

    fallback() external payable {
        emit RecievedEther(_msgSender(), msg.value);
    }

    // ================ Fall back functions to recieve ether ================

    function initialize(
        uint256 _numValidators,
        uint256 _adminFee,
        uint256 _performanceFeePercent,
        uint256 _validatorsCreated,
        uint256 _epochLengthInDays,
        address _BETHTokenAddress,
        address _depositContractAddress,
        address _priceOracleAddress,
        address _tokenManagerAddress,
        address _blocklistAddress
    ) external initializer {
        uint256 epochLength = _epochLengthInDays * 1 days;
        __OwnershipRolesTemplate_init_unchained();
        __DepositHelper_init_unchained(_depositContractAddress);
        __VaultWithSharesAndCapUpgradeable_init_unchained(1); // overwritten by updateCostPerShare in setupState
        __WithdrawQueue_init_unchained(epochLength);
        // _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // _setupRole(GOVERNANCE_ROLE, _msgSender());
        // _setupRole(BENEFICIARY_ROLE, _msgSender());

        numValidators = _numValidators; // The number of validators to create in this lot. Sets a max limit on deposits
        adminFee = _adminFee; // Admin and infra fees
        setPerformancePercent(_performanceFeePercent);

        // BETHTokenAddress = _BETHTokenAddress;
        _BETHToken = IvETH2(_BETHTokenAddress);

        costPerValidator = uint256(32).mul(1e18).add(adminFee);

        // Eth in the buffer cannot be withdrawn by an admin, only by burning the underlying token
        _setBuffer(uint256(10).mul(1e18)); // roughly equal to 10 eth.

        // After init setup requirements:
        // setupState() : previous contract state will need to be copied over
        // populateBlocklist() : blocklist will need to be populated with known mailicious/linked addresses to attackers
        setupState(_validatorsCreated, _priceOracleAddress, _tokenManagerAddress, _blocklistAddress);
    }

    // USER INTERACTIONS
    /*
    Shares minted = Z
    Principal deposit input = P
    AdminFee = a
    costPerValidator = 32 + a
    AdminFee as percent in 1e18 = a% =  (a / costPerValidator) * 1e18
    AdminFee on tx in 1e18 = (P * a% / 1e18)

    on deposit:
    P - (P * a%) = Z

    on withdraw with admin fee refund:
    P = Z / (1 - a%)
    P = Z - Z*a%
    */

    function deposit() external payable nonReentrant whenNotPaused {
        require(depositsEnabled, "Deposits are not enabled at this time");
        // input is whole, not / 1e18 , i.e. in 1 = 1 eth send when from etherscan
        uint256 value = msg.value;

        uint256 myAdminFee = value.mul(adminFee).div(costPerValidator);
        uint256 valMinusAdmin = value.sub(myAdminFee);
        uint256 newShareTotal = curValidatorShares.add(valMinusAdmin);

        require(
            newShareTotal <= buffer.add(maxValidatorShares()),
            "Eth2Staker:deposit:Amount too large, not enough validators left"
        );
        curValidatorShares = newShareTotal;
        adminFeeTotal = adminFeeTotal.add(myAdminFee);
        _tokenManager.mint(msg.sender, valMinusAdmin);
    }

    function stakeForWithdraw(uint256 amount) external nonReentrant whenNotPaused noContractAllowed {
        require(amount > 0, "Eth2Staker:: You need to sell at least some tokens");
        uint256 allowance = _BETHToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Eth2Staker:: Check the token allowance");
        require(_BETHToken.balanceOf(_msgSender()) >= amount, "Eth2Staker: Sender balance not enough");

        uint256 amountToReturn = getAmountGivenShares(amount);
        require(address(this).balance.sub(amountToReturn) >= 0, "Eth2Staker:withdraw:Not enough balance in contract");

        _BETHToken.transferFrom(_msgSender(), address(this), amount);

        _stakeForWithdrawal(_msgSender(), amount);
    }

    function withdrawETHRewardsWithQueue() external nonReentrant whenNotPaused noContractAllowed {
        uint256 amount = userEntries[_msgSender()].amount;
        _checkWithdraw(_msgSender(), _BETHToken.balanceOf(address(this)), amount);

        _BETHToken.approve(tokenManagerAddress, amount);
        userEntries[_msgSender()].amount = 0;
        _tokenManager.burn(address(this), amount);
        _withdrawEthRewards(amount);
    }

    function _withdrawEthRewards(uint256 amount) internal {
        uint256 amountToReturn = getAmountGivenShares(amount);
        require(address(this).balance.sub(amountToReturn) >= 0, "Eth2Staker:withdraw:Not enough balance in contract");

        _decrementShares(amount);

        emit Withdraw(_msgSender(), amountToReturn);
        // Re-route any eth from blocklisted addresses to
        // multisig for community redistribution to prevent
        // rugpullers and malicious actors from profiting any more
        // from protocol
        if (_blocklist.inBlockList(_msgSender())) {
            address payable sender;
            sender = payable(getRoleMember(GOVERNANCE_ROLE, 0));
            AddressUpgradeable.sendValue(sender, amountToReturn);
        } else {
            _sendEth(amountToReturn);
        }
    }

    function withdraw(uint256 amount) external nonReentrant whenNotPaused noContractAllowed {
        require(_BETHToken.balanceOf(_msgSender()) >= amount, "Eth2Staker: Sender balance not enough");

        _decrementShares(amount);
        _tokenManager.burn(_msgSender(), amount);
        _withdrawEthRewards(amount);
    }

    // Updates price per share using price oracle
    function updateCostPerShare() public {
        setCostPerShare(_priceOracle.getCostPerShare());
    }

    // migration function to accept old monies and copy over state
    // users should not use this as it just donates the money without minting veth or tracking donations
    // Edit: Was found to be a vulnerability in audits/immunefi bug bounties so it doesnt do anything but is reqd to pass minter control
    function donate(uint256 shares) external payable nonReentrant {}

    // ======= Beneficiary only function =============
    function getBeneficiaryRewards() external onlyBeneficiary whenNotPaused {
        _sendEth(getTotalBeneficiaryGains());
    }

    // ======= END Beneficiary only function =============

    // ================ OWNER/ Gov ONLY FUNCTIONS ===================================

    function toggleDepositsEnabled() external onlyAdminOrGovernance {
        depositsEnabled = !depositsEnabled;
    }

    // Used to set the performance percent. e.g. 5% of profits in bips = 500
    function setPerformancePercent(uint256 percentAsBips) public onlyAdminOrGovernance {
        performanceFeePrct = percentAsBips;
    }

    // Set the virtual price in the oracle
    function setCostPerShare(uint256 _costPerShare) public onlyAdminOrGovernance {
        _setCostPerShare(_getActualCostPerShare(_costPerShare));
    }

    // This needs to be called once per validator
    function depositToEth2(
        bytes calldata pubkey,
        bytes calldata withdrawalCredentials,
        bytes calldata signature,
        bytes32 depositDataRoot
    ) external onlyAdminOrGovernance nonReentrant {
        _depositToEth2(pubkey, withdrawalCredentials, signature, depositDataRoot);
    }

    function setNumValidators(uint256 _numValidators) external onlyAdminOrGovernance {
        require(_numValidators != 0, "Minimum 1 validator");
        numValidators = _numValidators;
        _setCap(numValidators.mul(costPerValidator));
    }

    function toggleWithdrawAdminFeeRefund() external onlyAdminOrGovernance {
        // in case the pool of tokens gets too large it will attract flash loans if the price of the pool token dips below x-admin fee
        // in that case or if the admin fee changes in cases of 1k+ validators
        // we may need to disable the withdraw refund

        // We also need to toggle this on if post migration we want to allow users to withdraw funds
        disableWithdrawRefund = !disableWithdrawRefund;
    }

    function petrifyMinterTransfer() external onlyAdminOrGovernance {
        minterTransferPetrified = true;
    }

    // Recover ownership of token supply and mint for upgrading the contract
    // When we want to upgrade this contract the plan is to:
    // - Limit the num validators. This disables deposits when the limit is reached
    // - Create the set of validators trasfering contract value to eth2
    // - Migrate the minter to a new contract
    // - migrate dust in the buffer to the new contract

    // Addition: Allow gov to freeze the minter in place to prevent any further transfer
    // function setMinter(address payable minter_)
    //     external
    //     onlyAdminOrGovernance
    //     nonReentrant
    //     onlyIfMinterTransferAllowed
    // {
    //     require(minter_ != address(0), "Minter cannot be zero address");
    //     _BETHToken.setMinter(minter_);

    //     uint256 amount = address(this).balance;
    //     ISharedDeposit newContract = ISharedDeposit(minter_);
    //     if (amount > 0) {
    //         newContract.donate{value: amount}(curValidatorShares);
    //     }
    // }

    function setAdminFee(uint256 amount) external onlyAdminOrGovernance {
        adminFee = amount;
        costPerValidator = uint256(32).mul(1e18).add(adminFee);
    }

    function withdrawAdminFee(uint256 amount) external onlyRole(BENEFICIARY_ROLE) nonReentrant {
        if (amount == 0) {
            amount = adminFeeTotal;
        }
        require(amount <= adminFeeTotal, "Eth2Staker:withdrawAdminFee: >adminFeeTotal cant be withdrawn");
        adminFeeTotal = adminFeeTotal.sub(amount);
        _sendEth(amount);
    }

    // Used to copy over state from previous contract
    function setupState(
        uint256 _validatorsCreated,
        address _priceOracleAddress,
        address _tokenManagerAddress,
        address _blocklistAddress
    ) public onlyAdminOrGovernance {
        // Bit confusing but we inherit and use a different curShares variable for tracking shares
        // Left the following bit of legacy code in to be refactored later
        curValidatorShares = _BETHToken.totalSupply();
        _setCurrentShares(curValidatorShares);

        _setValidatorsCreated(_validatorsCreated);
        priceOracleAddress = _priceOracleAddress;
        _priceOracle = IPriceOracle(priceOracleAddress);
        tokenManagerAddress = _tokenManagerAddress;
        _tokenManager = ITokenManager(tokenManagerAddress);
        blocklistAddress = _blocklistAddress;
        _blocklist = IBlocklist(blocklistAddress);
        updateCostPerShare();
    }

    // ================ END OWNER/ Gov ONLY FUNCTIONS ===================================

    // ========= PUBLIC VIEW FUNCTIONS ===============

    function mintingAllowedAfter() public view returns (uint256) {
        return _BETHToken.mintingAllowedAfter();
    }

    function maxValidatorShares() public view returns (uint256) {
        return uint256(32).mul(1e18).mul(numValidators);
    }

    function remainingSpaceInEpoch() public view returns (uint256) {
        // Helpful view function to gauge how much the user can send to the contract when it is near full
        uint256 remainingShares = (maxValidatorShares()).sub(curValidatorShares);
        uint256 valBeforeAdmin = remainingShares.mul(1e18).div(
            uint256(1).mul(1e18).sub(adminFee.mul(1e18).div(costPerValidator))
        );
        return valBeforeAdmin;
    }

    function getTotalBeneficiaryGains() public view returns (uint256 totalGains) {
        uint256 total = address(this).balance;
        // cost per share is calculated when we setCostPerShare() based on the oracle
        // to be the provided oracle rate minus performanceFeePrct of the profits
        // total - (customer shares * share price) => remainder is profit
        return total.sub(validatorsCreated.mul(32).mul(costPerShare));
    }

    // ========= PUBLIC VIEW FUNCTIONS ===============

    // ====== Internal helper functions =======
    function _sendEth(uint256 amount) internal {
        address payable sender = payable(_msgSender());
        AddressUpgradeable.sendValue(sender, amount);
    }

    function _getBeneficiaryCut(uint256 _costPerShare) internal view returns (uint256) {
        // assuming the virtual price is 1.03 * 1e18, this represents a 3% gain.
        // performanceFeePrct / Bips denom will be deducted from it
        // if the perf fee is e.g. 5%, .03*5% * 1e18 will be returned
        return _costPerShare.sub(1e18).mul(performanceFeePrct.mul(1e18).div(BIPS_DENOM)).div(1e18);
    }

    function _getActualCostPerShare(uint256 _costPerShare) internal view returns (uint256 actualCostPerShare) {
        return _costPerShare.sub(_getBeneficiaryCut(_costPerShare));
    }

    // ====== END Internal helper functions =======
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IvETH2 {
    function setMinter(address minter_) external;

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to be minted
     */
    function mint(address dst, uint256 rawAmount) external;

    function burn(address src, uint256 rawAmount) external;

    function mintingAllowedAfter() external view returns (uint256);

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint256);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount) external returns (bool);

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address owner,
        address spender,
        uint256 rawAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISharedDeposit {
    function donate(uint256 shares) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITokenManager {
    function donate(uint256 shares) external payable;

    function setTokenAddress(address _address) external;

    function mint(address recv, uint256 amt) external;

    function burn(address recv, uint256 amt) external;

    function petrifyMinterTransfer() external;

    function transferTokenMinterRights(address payable minter_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceOracle {
    function setCostPerShare(uint256 shares) external;

    function getCostPerShare() external returns (uint256 _costPerShare);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBlocklist {
    function inBlockList(address _user) external returns (bool _isInBlocklist);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import {UpgradeableSafeContractBase} from "./UpgradeableSafeContractBase.sol";

// A contract to make it DRY'er to recreate safe ownership roles
contract OwnershipRolesTemplate is UpgradeableSafeContractBase {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");

    // ====== Modifiers for syntactic sugar =======
    modifier onlyAdminOrGovernance() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(GOVERNANCE_ROLE, _msgSender()),
            "OwnershipRolesTemplate :: onlyAdminOrGovernance"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            hasRole(PAUSER_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                hasRole(GOVERNANCE_ROLE, _msgSender()),
            "OwnershipRolesTemplate :: onlyPauser"
        );
        _;
    }

    modifier onlyBeneficiary() {
        require(hasRole(BENEFICIARY_ROLE, _msgSender()), "OwnershipRolesTemplate :: onlyBeneficiary");
        _;
    }

    // ====== END Modifiers for syntactic sugar =====================================

    // ================ OWNER/ Gov ONLY FUNCTIONS ===================================
    // Hand the contract over to a multisig gov wallet
    // Will revoke self roles that are overpriviledged
    function grantGovernanceRoles(address _governance) external onlyAdminOrGovernance {
        grantRole(PAUSER_ROLE, _governance);
        grantRole(GOVERNANCE_ROLE, _governance);
        grantRole(DEFAULT_ADMIN_ROLE, _governance);

        // Allow adding other sentinels/watchers to pause
        _setRoleAdmin(PAUSER_ROLE, GOVERNANCE_ROLE);
        // Allow adding/changing the benefactor address
        _setRoleAdmin(BENEFICIARY_ROLE, GOVERNANCE_ROLE);
    }

    function renounceOwnership() external onlyAdminOrGovernance {
        // Revoke current admin rights except as
        // Benefactor and sentinel with permission to pause contract
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function togglePause() external onlyAdminOrGovernance {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    //  Initializers
    function __OwnershipRolesTemplate_init() internal initializer {
        __OwnershipRolesTemplate_init_unchained();
    }

    function __OwnershipRolesTemplate_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(GOVERNANCE_ROLE, _msgSender());
        _setupRole(BENEFICIARY_ROLE, _msgSender());
    }

    uint256[50] private ______gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import {IDepositContract} from "../interfaces/IDepositContract.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract Eth2DepositHelperUpgradeable is Initializable {
    using SafeMathUpgradeable for uint256;

    // The number of times the deposit to eth2 contract has been called to create validators
    uint256 public validatorsCreated; //initialized to 0
    uint256 public constant depositAmount = 32 ether;
    address public constant mainnetDepositContractAddress = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
    IDepositContract public depositContract;

    function __DepositHelper_init(address _depositContractAddress) internal initializer {
        __DepositHelper_init_unchained(_depositContractAddress);
    }

    function __DepositHelper_init_unchained(address _depositContractAddress) internal initializer {
        depositContract = IDepositContract(_depositContractAddress);
    }

    /// @notice Submit index-matching arrays that form Phase 0 DepositData objects.
    ///         Will create a deposit transaction per index of the arrays submitted.
    ///
    /// @param pubkeys - An array of BLS12-381 public keys.
    /// @param withdrawalCredentials - An array of commitment to public key for withdrawals.
    /// @param signatures - An array of BLS12-381 signatures.
    /// @param depositDataRoots - An array of the SHA-256 hash of the SSZ-encoded DepositData object.
    function _batchDeposit(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawalCredentials,
        bytes[] calldata signatures,
        bytes32[] calldata depositDataRoots
    ) internal {
        require(
            pubkeys.length == withdrawalCredentials.length &&
                pubkeys.length == signatures.length &&
                pubkeys.length == depositDataRoots.length,
            "DepositHelper::_batchDeposit: All fn param array's must be same length"
        );
        require(pubkeys.length > 0, "DepositHelper::_batchDeposit: Need >0 pubkeys");
        require(
            address(this).balance >= depositAmount.mul(pubkeys.length),
            "DepositHelper::_batchDeposit: Ether deposited must be >= 32 * (`pubkeys[]`.length)"
        );

        uint256 deposited;
        // Loop through DepositData arrays submitting deposits
        for (uint256 i = 0; i < pubkeys.length; i++) {
            _depositToEth2(pubkeys[i], withdrawalCredentials[i], signatures[i], depositDataRoots[i]);
            deposited = deposited.add(depositAmount);
        }
        assert(deposited == depositAmount.mul(pubkeys.length));
    }

    function _depositToEth2(
        bytes calldata pubkey,
        bytes calldata withdrawalCredential,
        bytes calldata signature,
        bytes32 depositDataRoot
    ) internal {
        require(address(this).balance >= depositAmount, "Eth2Staker:_depositToEth2: Not enough balance"); //need at least 32 ETH

        validatorsCreated = validatorsCreated.add(1);

        depositContract.deposit{value: depositAmount}(pubkey, withdrawalCredential, signature, depositDataRoot);
    }

    function _setValidatorsCreated(uint256 count) internal {
        validatorsCreated = count;
    }

    uint256[50] private ______gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {PriceOracleUpgradeable} from "./PriceOracleUpgradeable.sol";

contract VaultWithSharesAndCapUpgradeable is Initializable, PriceOracleUpgradeable {
    using SafeMathUpgradeable for uint256;
    uint256 public curShares; //initialized to 0
    uint256 public maxShares;
    // Its hard to exactly hit the max deposit amount with small shares. this allows a small bit of overflow room
    // Tokens in the buffer cannot be withdrawn by an admin, only by burning the underlying token via a user withdraw
    uint256 public buffer;

    function __VaultWithSharesAndCapUpgradeable_init(uint256 _sharePrice) internal initializer {
        __VaultWithSharesAndCapUpgradeable_init_unchained(_sharePrice);
    }

    function __VaultWithSharesAndCapUpgradeable_init_unchained(uint256 _sharePrice) internal initializer {
        __PriceOracleUpgradeable_init_unchained(_sharePrice);
    }

    function getSharesGivenAmount(uint256 amount) public view returns (uint256) {
        return amount.div(costPerShare).mul(1e18);
    }

    function getAmountGivenShares(uint256 shares) public view returns (uint256) {
        return shares.mul(costPerShare).div(1e18);
    }

    function _setCap(uint256 amount) internal {
        require(amount > 0, "Cap cannot be 0");
        maxShares = amount;
    }

    function _setBuffer(uint256 amount) internal {
        require(amount > 0, "Buffer cannot be 0");
        buffer = amount;
    }

    function _setCurrentShares(uint256 amount) internal {
        curShares = amount;
    }

    function _incrementShares(uint256 amount) internal underCap(amount) {
        _setCurrentShares(curShares.add(amount));
    }

    function _decrementShares(uint256 amount) internal aboveOrEqualToZero(amount) {
        _setCurrentShares(curShares.sub(amount));
    }

    modifier underCap(uint256 amount) {
        if (maxShares > 0) {
            require(
                curShares.add(amount) <= buffer.add(maxShares),
                "VaultWithSharesAndCapUpgradeable:: Amount too large; Exceeds Cap"
            );
        }
        _;
    }

    modifier aboveOrEqualToZero(uint256 amount) {
        require(curShares.sub(amount) >= 0, "VaultWithSharesAndCapUpgradeable:: newShareTotal cant be -ve");
        _;
    }

    function _depositAndAccountShares(uint256 amount) internal returns (uint256) {
        uint256 newShares = getSharesGivenAmount(amount);
        _incrementShares(newShares);
        return newShares;
    }

    function _withdrawAndAccountShares(uint256 amount) internal returns (uint256) {
        uint256 newShares = getAmountGivenShares(amount);
        _decrementShares(amount);
        return newShares;
    }

    uint256[50] private ______gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract WithdrawQueueUpgradeable is Initializable {
    using SafeMathUpgradeable for uint256;
    struct UserEntry {
        address user;
        uint256 amount;
        uint256 timestamp;
    }
    mapping(address => UserEntry) public userEntries;
    uint256 public epochLength;

    function __WithdrawQueue_init(uint256 len) internal initializer {
        __WithdrawQueue_init_unchained(len);
    }

    function __WithdrawQueue_init_unchained(uint256 len) internal initializer {
        _setEpochLength(len);
    }

    // should be admin only or used in a constructor upstream
    function _setEpochLength(uint256 len) internal {
        epochLength = len;
    }

    // if you just use the 2 foll func you open yourself up to flash loan attacks
    // remember to move funds from the user
    function _checkWithdraw(
        address sender,
        uint256 balanceOfSelf,
        uint256 amountToWithdraw
    ) internal view {
        UserEntry memory userEntry = userEntries[sender];
        require(
            uint256(epochLength.add(userEntry.timestamp)) > uint256(block.timestamp),
            "WithdrawQueueUpgradeable:: Too soon!"
        );
        require(amountToWithdraw >= balanceOfSelf, "WithdrawQueueUpgradeable:: Not enough funds");
        require(userEntry.amount >= amountToWithdraw, "WithdrawQueueUpgradeable:: Amount mismatch! Not enough staked.");
    }

    function _stakeForWithdrawal(address sender, uint256 amount) internal {
        if (userEntries[sender].amount >= 0) {
            amount = userEntries[sender].amount.add(amount);
        }
        userEntries[sender] = UserEntry(sender, amount, block.timestamp);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract UpgradeableSafeContractBase is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;

    function __UpgradeableSafeContractBase_init() internal initializer {
        __UpgradeableSafeContractBase_init_unchained();
    }

    function __UpgradeableSafeContractBase_init_unchained() internal initializer {
        __Context_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /* solhint-disable */
    // Inspired by alchemix smart contract gaurd at https://github.com/alchemix-finance/alchemix-protocol/blob/master/contracts/Alchemist.sol#L680
    /// @dev Checks that caller is a EOA.
    ///
    /// This is used to prevent contracts from interacting.
    modifier noContractAllowed() {
        require(!address(_msgSender()).isContract() && _msgSender() == tx.origin, "Sorry we do not accept contracts!");
        uint256 size;
        address addr = _msgSender();
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "only humans allowed! (code present at caller address)");
        _;
    }

    uint256[50] private ______gap;
    /* solhint-enable */
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

pragma solidity ^0.8.0;

// ┏━━━┓━┏┓━┏┓━━┏━━━┓━━┏━━━┓━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━┏┓━━━━━┏━━━┓━━━━━━━━━┏┓━━━━━━━━━━━━━━┏┓━
// ┃┏━━┛┏┛┗┓┃┃━━┃┏━┓┃━━┃┏━┓┃━━━━┗┓┏┓┃━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━┃┏━┓┃━━━━━━━━┏┛┗┓━━━━━━━━━━━━┏┛┗┓
// ┃┗━━┓┗┓┏┛┃┗━┓┗┛┏┛┃━━┃┃━┃┃━━━━━┃┃┃┃┏━━┓┏━━┓┏━━┓┏━━┓┏┓┗┓┏┛━━━━┃┃━┗┛┏━━┓┏━┓━┗┓┏┛┏━┓┏━━┓━┏━━┓┗┓┏┛
// ┃┏━━┛━┃┃━┃┏┓┃┏━┛┏┛━━┃┃━┃┃━━━━━┃┃┃┃┃┏┓┃┃┏┓┃┃┏┓┃┃━━┫┣┫━┃┃━━━━━┃┃━┏┓┃┏┓┃┃┏┓┓━┃┃━┃┏┛┗━┓┃━┃┏━┛━┃┃━
// ┃┗━━┓━┃┗┓┃┃┃┃┃┃┗━┓┏┓┃┗━┛┃━━━━┏┛┗┛┃┃┃━┫┃┗┛┃┃┗┛┃┣━━┃┃┃━┃┗┓━━━━┃┗━┛┃┃┗┛┃┃┃┃┃━┃┗┓┃┃━┃┗┛┗┓┃┗━┓━┃┗┓
// ┗━━━┛━┗━┛┗┛┗┛┗━━━┛┗┛┗━━━┛━━━━┗━━━┛┗━━┛┃┏━┛┗━━┛┗━━┛┗┛━┗━┛━━━━┗━━━┛┗━━┛┗┛┗┛━┗━┛┗┛━┗━━━┛┗━━┛━┗━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// SPDX-License-Identifier: CC0-1.0

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index);

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

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
library SafeMathUpgradeable {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract PriceOracleUpgradeable is Initializable {
    uint256 public costPerShare; // cost per share in 1e18
    uint256 public lastCostPerShare;
    event SharePriceChanged(uint256 lastPrice, uint256 newPrice);

    function getCostPerShare() public view returns (uint256 _costPerShare) {
        return costPerShare;
    }

    function __PriceOracleUpgradeable_init(uint256 _costPerShare) internal initializer {
        __PriceOracleUpgradeable_init_unchained(_costPerShare);
    }

    function __PriceOracleUpgradeable_init_unchained(uint256 _costPerShare) internal initializer {
        _setCostPerShare(_costPerShare);
    }

    function _setCostPerShare(uint256 amount) internal {
        require(amount > 0, "Cost per share cannot be 0");
        lastCostPerShare = costPerShare;
        costPerShare = amount;
        emit SharePriceChanged(lastCostPerShare, costPerShare);
    }

    uint256[50] private ______gap;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 500000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}