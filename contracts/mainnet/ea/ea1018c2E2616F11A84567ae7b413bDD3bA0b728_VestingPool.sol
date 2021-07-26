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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IVNFT /* is IERC721 */{
    event PartialTransfer(address indexed from, address indexed to, uint256 indexed tokenId, uint256 targetTokenId,
        uint256 transferUnits);
    event Split(address indexed owner, uint256 indexed tokenId, uint256 newTokenId, uint256 splitUnits);
    event Merge(address indexed owner, uint256 indexed tokenId, uint256 indexed targetTokenId, uint256 mergeUnits);
    event ApprovalUnits(address indexed owner, address indexed approved, uint256 indexed tokenId, uint256 approvalUnits);

    //function decimals() external view returns (uint8);
    function slotOf(uint256 tokenId)  external view returns(uint256 slot);

    function balanceOfSlot(uint256 slot) external view returns (uint256 balance);
    function tokenOfSlotByIndex(uint256 slot, uint256 index) external view returns (uint256 tokenId);
    function unitsInToken(uint256 tokenId) external view returns (uint256 units);

    function approve(address to, uint256 tokenId, uint256 units) external;
    function allowance(uint256 tokenId, address spender) external view returns (uint256 allowed);

    function split(uint256 tokenId, uint256[] calldata units) external returns (uint256[] memory newTokenIds);
    function merge(uint256[] calldata tokenIds, uint256 targetTokenId) external;

    function transferFrom(address from, address to, uint256 tokenId,
        uint256 units) external returns (uint256 newTokenId);

    function safeTransferFrom(address from, address to, uint256 tokenId,
        uint256 units, bytes calldata data) external returns (uint256 newTokenId);

    function transferFrom(address from, address to, uint256 tokenId, uint256 targetTokenId,
        uint256 units) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 targetTokenId,
        uint256 units, bytes calldata data) external;
}

interface IVNFTReceiver {
    function onVNFTReceived(address operator, address from, uint256 tokenId,
        uint256 units, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IVestingPool.sol";
import "./interface/IVNFTErc20Container.sol";
import "./library/VestingLibrary.sol";
import "./library/EthAddressLib.sol";
import "./library/ERC20TransferHelper.sol";

contract VestingPool is IVestingPool {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using VestingLibrary for VestingLibrary.Vesting;
    event NewManager(address oldManager, address newManager);

    address internal _underlying;
    bool internal _initialized;

    address public admin;
    address public pendingAdmin;
    address public manager;
    uint256 internal _totalAmount;

    //tokenId => Vault
    mapping(uint256 => VestingLibrary.Vesting) public vestingById;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "only manager");
        _;
    }

    function initialize(address underlying_) public {
        require(_initialized == false, "already initialized");
        admin = msg.sender;

        if (underlying_ != EthAddressLib.ethAddress()) {
            IERC20(underlying_).totalSupply();
        }

        _underlying = underlying_;
        _initialized = true;
    }

    function isVestingPool() external pure override returns (bool) {
        return true;
    }

    function _setManager(address newManager_) public onlyAdmin {
        address oldManager = manager;
        manager = newManager_;
        emit NewManager(oldManager, newManager_);
    }

    function mint(
        uint8 claimType_,
        address minter_,
        uint256 tokenId_,
        uint64 term_,
        uint256 amount_,
        uint64[] calldata maturities_,
        uint32[] calldata percentages_,
        string memory originalInvestor_
    ) external virtual override onlyManager returns (uint256) {
        return _mint(claimType_, minter_, tokenId_, term_, amount_, maturities_, percentages_, originalInvestor_);
    }

    struct MintLocalVar {
        uint64 term;
        uint256 sumPercentages;
        uint256 mintPrincipal;
        uint256 mintUnits;
    }
    function _mint(
        uint8 claimType_,
        address minter_,
        uint256 tokenId_,
        uint64 term_,
        uint256 amount_,
        uint64[] memory maturities_,
        uint32[] memory percentages_,
        string memory originalInvestor_
    ) internal virtual returns (uint256) {
        MintLocalVar memory vars;
        require(maturities_.length > 0 && maturities_.length == percentages_.length, "maturities or percentages error");

        if (claimType_ == VestingLibrary.CLAIM_TYPE_MULTI) {
            vars.term = _sub(maturities_[maturities_.length - 1], maturities_[0]);
            require(vars.term == term_, "term error");
        }

        for (uint256 i = 0; i < percentages_.length; i++) {
            vars.sumPercentages = vars.sumPercentages.add(percentages_[i]);
        }
        require(vars.sumPercentages == VestingLibrary.FULL_PERCENTAGE, "percentages error");

        ERC20TransferHelper.doTransferIn(_underlying, minter_, amount_);
        VestingLibrary.Vesting storage vesting = vestingById[tokenId_];
        (, vars.mintPrincipal) = vesting.mint(claimType_, term_, amount_, maturities_, percentages_, originalInvestor_);

        vars.mintUnits = amount2units(vars.mintPrincipal);

        emit MintVesting(
            claimType_,
            minter_,
            tokenId_,
            term_,
            maturities_,
            percentages_,
            amount_,
            amount_
        );

        _totalAmount = _totalAmount.add(amount_);

        return vars.mintUnits;
    }

    function claim(address payable payee, uint256 tokenId, uint256 amount)
        external
        virtual
        override
        onlyManager
        returns (uint256)
    {
        return _claim(payee, tokenId, amount);
    }

    function claimableAmount(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        VestingLibrary.Vesting memory vesting = vestingById[tokenId_];

        if (vesting.claimType == VestingLibrary.CLAIM_TYPE_LINEAR 
            || vesting.claimType == VestingLibrary.CLAIM_TYPE_SINGLE) {
            if (block.timestamp >= vesting.maturities[0]) {
                // 到期或过期
                return vesting.principal;
            } 
            uint256 timeRemained = vesting.maturities[0] - block.timestamp;
            // 尚未开始解锁
            if (timeRemained >= vesting.term) {
                return 0;
            }

            uint256 lockedAmount = vesting.vestingAmount.mul(timeRemained).div(vesting.term);
            return vesting.principal.sub(lockedAmount, "claimable amount error");

        } else if (vesting.claimType == VestingLibrary.CLAIM_TYPE_MULTI) {  
            //尚未开始解锁
            if (block.timestamp < vesting.maturities[0]) {
                return 0;
            }

            uint256 lockedPercentage;
            for (uint256 i = vesting.maturities.length - 1; i >= 0; i--) {
                if (vesting.maturities[i] <= block.timestamp) {
                    break;
                }
                lockedPercentage = lockedPercentage.add(vesting.percentages[i]);
            }

            uint256 lockedAmount = 
                    vesting.vestingAmount.mul(lockedPercentage)
                    .div(VestingLibrary.FULL_PERCENTAGE, "locked amount error");
            return vesting.principal.sub(lockedAmount, "claimable amount error");
        } else {
            revert("not support claimType");
        }
    }

    function _claim(
        address payable payee_,
        uint256 tokenId_,
        uint256 claimAmount_
    ) internal virtual returns (uint256) {
        require(claimAmount_ > 0, "only more than 0");
        require(
            claimAmount_ <= claimableAmount(tokenId_),
            "withdraw amount exceeds limit"
        );

        VestingLibrary.Vesting storage v = vestingById[tokenId_];

        require(
            claimAmount_ <= v.principal,
            "withdraw amount too much"
        );

        v.claim(claimAmount_);

        ERC20TransferHelper.doTransferOut(_underlying, payee_, claimAmount_);

        _totalAmount = _totalAmount.sub(claimAmount_);

        emit ClaimVesting(
            payee_,
            tokenId_,
            claimAmount_
        );
        return amount2units(claimAmount_);
    }

    function transferVesting( address from_, uint256 tokenId_,
        address to_,
        uint256 targetTokenId_,
        uint256 transferUnits_) public override virtual onlyManager {
        uint256 transferAmount = units2amount(transferUnits_);
        (uint256 transferVestingAmount, uint256 transferPrincipal) =
            vestingById[tokenId_].transfer(vestingById[targetTokenId_], transferAmount);
        emit TransferVesting(
            from_,
            tokenId_,
            to_,
            targetTokenId_,
            transferVestingAmount,
            transferPrincipal
        );
    }

    function splitVesting(address owner_, uint256 tokenId_, uint256 newTokenId_,
        uint256 splitUnits_) public  virtual override onlyManager {
        uint256 splitAmount = units2amount(splitUnits_);
        (uint256 splitVestingAmount, uint256 splitPrincipal) = vestingById[tokenId_].split(vestingById[newTokenId_], splitAmount);
        emit SplitVesting(owner_, tokenId_, newTokenId_, splitVestingAmount, splitPrincipal);
    }

    function mergeVesting(address owner_, uint256 tokenId_,
        uint256 targetTokenId_) public  virtual override onlyManager {
        (uint256 mergeVestingAmount, uint256 mergePrincipal) = vestingById[tokenId_].merge(vestingById[targetTokenId_]);
        delete vestingById[tokenId_];
        emit MergeVesting(owner_, tokenId_, targetTokenId_, mergeVestingAmount, mergePrincipal);
    }

    function units2amount(uint256 units_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return units_ * 1;
    }

    function amount2units(uint256 amount_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return amount_ / 1;
    }

    function totalAmount() public view override returns(uint256) {
        return _totalAmount;
    }

    struct VestingSnapShot {
        uint256 vestingAmount_;
        uint256 principal_;
        uint64[] maturities_;
        uint32[] percentages_;
        uint64 term_;
        uint8 claimType_;
        uint256 claimableAmount;
        bool isValid_;
        string originalInvestor_;
    }

    function getVestingSnapshot(uint256 tokenId_)
    public
    view
    override
    returns (
        uint8,
        uint64,
        uint256,
        uint256,
        uint64[] memory,
        uint32[] memory,
        uint256,
        string memory,
        bool
    )
    {
        VestingSnapShot memory vars;
        vars.vestingAmount_ = vestingById[tokenId_].vestingAmount;
        vars.principal_ = vestingById[tokenId_].principal;
        vars.maturities_ = vestingById[tokenId_].maturities;
        vars.percentages_ = vestingById[tokenId_].percentages;
        vars.term_ = vestingById[tokenId_].term;
        vars.claimType_ = vestingById[tokenId_].claimType;
        vars.claimableAmount = claimableAmount(tokenId_);
        vars.isValid_ = vestingById[tokenId_].isValid;
        vars.originalInvestor_ = vestingById[tokenId_].originalInvestor;
        return (
            vars.claimType_,
            vars.term_,
            vars.vestingAmount_,
            vars.principal_,
            vars.maturities_,
            vars.percentages_,
            vars.claimableAmount,
            vars.originalInvestor_,
            vars.isValid_
        );
    }

    function underlying() public view override returns (address) {
        return _underlying;
    }

    function _setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "only admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function _acceptAdmin() public {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "only pending admin"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function _add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function _sub(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a, "subtraction overflow");
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IUnderlyingContainer {
    function totalUnderlyingAmount() external view returns (uint256);
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@solv/solv-vnft-core/contracts/interface/IVNFT.sol";
import "./IUnderlyingContainer.sol";

interface IVNFTErc20Container is IVNFT, IUnderlyingContainer {
    function getUnderlyingAmount(uint256 units) external view returns (uint256 underlyingAmount);
    function getUnits(uint256 underlyingAmount) external view returns (uint256 units);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IVestingPool {
   event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event MintVesting(
        uint8 indexed claimType,
        address indexed minter,
        uint256 indexed tokenId,
        uint64 term,
        uint64[] maturities,
        uint32[] percentages,
        uint256 vestingAmount,
        uint256 principal
    );
    event ClaimVesting(
        address indexed payee,
        uint256 indexed tokenId,
        uint256 claimAmount
    );
    event TransferVesting(
        address from,
        uint256 tokenId,
        address to,
        uint256 targetTokenId,
        uint256 transferVestingAmount,
        uint256 transferPrincipal
    );
    event SplitVesting(
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 splitVestingAmount,
        uint256 splitPricipal
    );
    event MergeVesting(
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 mergeVestingAmount,
        uint256 mergePrincipal
    );

    function isVestingPool() external pure returns (bool);

    function mint(
        uint8 claimType_,
        address minter_,
        uint256 tokenId_,
        uint64 term_,
        uint256 amount_,
        uint64[] calldata maturities_,
        uint32[] calldata percentages_,
        string memory originalInvestor_
    ) external returns (uint256 mintUnits);

    function claim(address payable payee, uint256 tokenId,
        uint256 amount) external returns(uint256 claimUnit);

    function claimableAmount(uint256 tokenId_)
        external
        view
        returns (uint256);

    function transferVesting(
        address from_,
        uint256 tokenId_,
        address to_,
        uint256 targetTokenId_,
        uint256 transferUnits_
    ) external;

    function splitVesting(address owner_, uint256 tokenId_, uint256 newTokenId_,
        uint256 splitUnits_) external;

    function mergeVesting(address owner_, uint256 tokenId_,
        uint256 targetTokenId_) external;

    function units2amount(uint256 units_) external view returns (uint256);
    function amount2units(uint256 units_) external view returns (uint256);
    function totalAmount() external view returns(uint256);

    function getVestingSnapshot(uint256 tokenId_)
    external
    view
    returns (
        uint8 claimType_,
        uint64 term_,
        uint256 vestingAmount_,
        uint256 principal_,
        uint64[] memory maturities_,
        uint32[] memory percentages_,
        uint256 availableWithdrawAmount_,
        string memory originalInvestor_,
        bool isValid_
    );

    function underlying() external view returns (address) ;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./EthAddressLib.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library ERC20TransferHelper {
    function doTransferIn(address underlying, address from, uint amount) internal returns (uint) {
        if (underlying == EthAddressLib.ethAddress()) {
            // Sanity checks
            require(tx.origin == from, "sender mismatch");
            require(msg.value == amount, "value mismatch");

            return amount;
        } else {
            require(msg.value == 0, "don't support msg.value");
            IERC20 token = IERC20(underlying);
            uint balanceBefore = IERC20(underlying).balanceOf(address(this));
            token.transferFrom(from, address(this), amount);

            bool success;
            assembly {
                switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
            }
            require(success, "TOKEN_TRANSFER_IN_FAILED");

            // Calculate the amount that was *actually* transferred
            uint balanceAfter = IERC20(underlying).balanceOf(address(this));
            require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
            return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
        }
    }
    function doTransferOut(address underlying, address payable to, uint amount) internal {
        if (underlying == EthAddressLib.ethAddress()) {
            to.transfer(amount);
        } else {
            IERC20 token = IERC20(underlying);
            token.transfer(to, amount);

            bool success;
            assembly {
                switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
            }
            require(success, "TOKEN_TRANSFER_OUT_FAILED");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library EthAddressLib {

    /**
    * @dev returns the address used within the protocol to identify ETH
    * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library VestingLibrary {
    using SafeMath for uint256;

    uint32 constant internal FULL_PERCENTAGE = 10000;  // 释放比例基数，精确到小数点后两位
    uint8 constant internal CLAIM_TYPE_LINEAR = 0;
    uint8 constant internal CLAIM_TYPE_SINGLE = 1;
    uint8 constant internal CLAIM_TYPE_MULTI = 2;

    struct Vesting {
        uint8 claimType; //0: 线性释放, 1: 单点释放, 2: 多点释放
        uint64 term; // 0 : Non-fixed term , 1 - N : fixed term in seconds
        uint64[] maturities; //到期时间（秒）
        uint32[] percentages;  //到期释放比例
        bool isValid; //是否有效
        uint256 vestingAmount;
        uint256 principal;
        string originalInvestor;
    }

     function mint(
        Vesting storage self,
        uint8 claimType,
        uint64 term,
        uint256 amount,
        uint64[] memory maturities,
        uint32[] memory percentages,
        string memory originalInvestor
    ) internal returns (uint256, uint256) {
        require(! self.isValid, "vesting exists");
        self.term = term;
        self.maturities = maturities;
        self.percentages = percentages;
        self.claimType = claimType;
        self.vestingAmount = amount;
        self.principal = amount;
        self.originalInvestor = originalInvestor;
        self.isValid = true;
        return (self.vestingAmount, self.principal);
    }


    function claim(Vesting storage self, uint256 amount) internal {
        require(self.isValid, "Vesting: token invalid");
        self.principal = self.principal.sub(amount, "claim amount exceeds balance");
    }

    function merge(Vesting storage self, Vesting storage target) internal returns (uint256 mergeVestingAmount, uint256 mergePrincipal) {
        require(self.isValid && target.isValid, "Vesting: token invalid");
        mergeVestingAmount = self.vestingAmount;
        mergePrincipal = self.principal;
        require(mergePrincipal <= mergeVestingAmount, "Vesting: merge amount error");
        self.vestingAmount = 0;
        self.principal = 0;
        target.vestingAmount = target.vestingAmount.add(mergeVestingAmount);
        target.principal = target.principal.add(mergePrincipal);
        self.isValid = false;
        return (mergeVestingAmount, mergePrincipal);
    }

    function split(Vesting storage source, Vesting storage create, uint256 amount) internal returns (uint256 splitVestingAmount, uint256 splitPrincipal){
        require(source.isValid, "Vesting: token invalid");
        require(source.principal <= source.vestingAmount, "balance exception");
        splitVestingAmount = source.vestingAmount.mul(amount).div(source.principal);
        source.vestingAmount = source.vestingAmount.sub(splitVestingAmount, "split vesting amount exceeds balance");
        source.principal = source.principal.sub(amount, "split principal exceeds balance");
        mint(create, source.claimType, source.term, 0, source.maturities, source.percentages, source.originalInvestor);
        create.vestingAmount = splitVestingAmount;
        create.principal = amount;
        return (splitVestingAmount, amount);
    }

    function transfer(Vesting storage source, Vesting storage target, uint256 amount ) internal returns (uint256 transferVestingAmount, uint256 transferPrincipal){
        require(source.isValid, "Vesting: token invalid");
        transferPrincipal = amount;
        transferVestingAmount = source.vestingAmount.mul(transferPrincipal).div(source.principal);
        source.principal = source.principal.sub(transferPrincipal, "transfer principal exceeds balance");
        source.vestingAmount = source.vestingAmount.sub(transferVestingAmount, "transfer amount exceeds balance");
        if (! target.isValid) {
            mint(target, source.claimType, source.term, 0, source.maturities, source.percentages, "");
        }
        target.vestingAmount = target.vestingAmount.add(transferVestingAmount);
        target.principal = target.principal.add(transferPrincipal);
        return (transferVestingAmount, transferPrincipal);
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "remappings": [],
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