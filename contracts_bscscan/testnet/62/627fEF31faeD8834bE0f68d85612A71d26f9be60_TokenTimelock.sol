// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IBEP20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/*****************************************************************************
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time.
 */
contract TokenTimelock is Ownable {
    using SafeMath for uint256;

    struct Beneficiary {
        address wallet;
        uint256 amountLocked;
        uint256 amountClaimed;
        uint256 monthsClaimed;
        uint256 vestDuration; //period in months
        uint256 lockDuration; //period in months
        uint256 startTime;
        bool isActive;
    }
    //variables to store the amount released by disabled beneficiaries to don't need to add more funds when adding another beneficiary.
    uint256 private amountToLock; //amount available to lock to a beneficiary
    uint256 private amountAttributed; //total amount currently attributed to beneficiaries

    // Event raised on each successful withdraw
    event Claim(address beneficiary, uint256 amount, uint256 date);

    // Event raised on each desposit
    event AddBeneficiary(
        address beneficiary,
        uint256 amount,
        uint256 timeVested,
        uint256 timeLocked,
        uint256 date
    );

    event AddFundsToBeneficiary(
        address beneficiary,
        uint256 amountAdded,
        uint256 timeVested,
        uint256 date
    );

    uint256 constant MONTH_PERIOD = 2592000; // 30 days
    address _mekaToken;

    mapping(address => Beneficiary) private beneficiaries;

    constructor(address mekaToken) {
        _mekaToken = mekaToken;
    }

    modifier onlyBeneficiary() {
        require(beneficiaries[msg.sender].isActive, "beneficiary inactive");
        _;
    }

    function setTokenAddress(address _addr) external onlyOwner {
        _mekaToken = _addr;
    }

    /**
     *  @notice Total of tokens in balance, locked and to lock.
     */
    function getBalance() external view returns (uint256) {
        return IBEP20(_mekaToken).balanceOf(address(this));
    }

    /**
     * @notice Beneficiary can release his own tokens.
     */
    function release() external onlyBeneficiary {
        executeRelease(msg.sender);
    }

    function disableBeneficiary(address beneficiary) public onlyOwner {
        Beneficiary storage bf = beneficiaries[beneficiary];
        require(bf.isActive, "beneficiary inactive or dont exist");

        amountToLock = amountToLock.add(amountToRelease(bf));
        amountAttributed = amountAttributed.sub(amountToRelease(bf));
        bf.isActive = false;
        bf.lockDuration = 0;
        bf.startTime = 0;
        bf.vestDuration = 0;
        bf.monthsClaimed = 0;
        bf.amountLocked = 0;
        bf.amountClaimed = 0;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
       @param beneficiaryWallet beneficiary's wallet.
     */
    function releaseTo(address beneficiaryWallet) external onlyOwner {
        require(
            beneficiaries[beneficiaryWallet].isActive,
            "Not a beneficiary or inactive"
        );

        executeRelease(beneficiaryWallet);
    }

    /**
     *  @notice Add a beneficiary to the lock pool or add amount to a existent beneficiary.
        @param beneficiary beneficiary's wallet.
        @param amountLocked total amount locked for this beneficiary
        @param vestDuration total duration of the vesting in months.
        @param lockDuration total duration of the timelock in months.
     */
    function addBeneficiary(
        address beneficiary,
        uint256 amountLocked,
        uint256 vestDuration,
        uint256 lockDuration
    ) external onlyOwner {
        require(beneficiary != address(0), "zero-address");
        require(!beneficiaries[beneficiary].isActive, "wallet is active");

        //check if the contract has allowance to don't need to transfer from owner wallet.
        if (amountToLock >= amountLocked) {
            amountAttributed = amountAttributed.add(amountLocked);
            amountToLock = amountToLock.sub(amountLocked);
        } else {
            // Based on ERC20 standard, to transfer funds to this contract,
            // the owner must first call approve() to allow to transfer token to this contract.
            require(
                IBEP20(_mekaToken).transferFrom(
                    _msgSender(),
                    address(this),
                    amountLocked
                ),
                "cannot-transfer-token-to-this-contract"
            );

            amountAttributed = amountAttributed.add(amountLocked);
        }

        if (beneficiaries[beneficiary].wallet == address(0)) {
            beneficiaries[beneficiary] = Beneficiary(
                beneficiary,
                amountLocked,
                0,
                0,
                vestDuration,
                lockDuration,
                block.timestamp,
                true
            );

            emit AddBeneficiary(
                beneficiary,
                amountLocked,
                vestDuration,
                lockDuration,
                block.timestamp
            );
        } else {
            Beneficiary storage bf = beneficiaries[beneficiary];
            bf.amountLocked = bf.amountLocked.add(amountLocked);
            bf.vestDuration = bf.vestDuration.add(vestDuration);
            bf.isActive = true;

            emit AddFundsToBeneficiary(
                beneficiary,
                amountLocked,
                vestDuration,
                block.timestamp
            );
        }
    }

    /**
     *  @notice Return beneficiary details from the storage.
     *  @param beneficiary beneficiary's wallet.
     */
    function getBeneficiary(address beneficiary)
        external
        view
        returns (Beneficiary memory bf)
    {
        Beneficiary memory _bf = beneficiaries[beneficiary];

        return _bf;
    }

    /**
     *  @notice Return amount available to lock for a beneficiary
     */
    function getAmountToLock() external view returns (uint256) {
        return amountToLock;
    }

    /**
     *  @notice Return amount of months and tokens that beneficiary has unlocked.
     */
    function getAmountToClaim() external view returns (uint256, uint256) {
        return calculateClaimable(msg.sender);
    }

    function executeRelease(address beneficiaryWallet) private {
        Beneficiary storage bf = beneficiaries[beneficiaryWallet];

        require(bf.amountLocked > bf.amountClaimed, "tokens already released");

        (uint256 monthsToRelease, uint256 tokensToRelease) = calculateClaimable(
            bf.wallet
        );

        require(
            IBEP20(_mekaToken).transfer(beneficiaryWallet, tokensToRelease),
            "fail to transfer token"
        );

        bf.monthsClaimed = bf.monthsClaimed.add(monthsToRelease);
        bf.amountClaimed = bf.amountClaimed.add(tokensToRelease);
        amountAttributed = amountAttributed.sub(tokensToRelease);

        if (amountToRelease(bf) <= 0) {
            bf.isActive = false;
        }

        emit Claim(beneficiaryWallet, tokensToRelease, block.timestamp);
    }

    // calculateClaimable calculates the claimable token of the beneficiary
    // claimable token each month is rounded if it is a decimal number
    // So the rest of the token will be claimed on the last month (the duration is over)
    // @param _beneficiary Address of the beneficiary
    function calculateClaimable(address _beneficiary)
        private
        view
        returns (uint256, uint256)
    {
        Beneficiary storage bf = beneficiaries[_beneficiary];
        require(bf.wallet != address(0), "not a beneficiary");
        require(bf.isActive, "not active");
        require(amountToRelease(bf) > 0, "nothing to claim");
        uint256 _now = block.timestamp;
        require(_now > bf.startTime, "not release time");

        uint256 elapsedTime = _now.sub(bf.startTime);
        uint256 elapsedMonths = elapsedTime.div(MONTH_PERIOD);

        elapsedMonths = elapsedMonths <= bf.lockDuration
            ? 0
            : elapsedMonths.sub(bf.lockDuration);

        require(elapsedMonths >= 1, "not release time");

        // If over vesting duration, all tokens vested
        if (elapsedMonths >= bf.vestDuration) {
            uint256 remaining = amountToRelease(bf);
            return (bf.vestDuration, remaining);
        } else {
            uint256 monthsVestable = elapsedMonths.sub(bf.monthsClaimed);
            uint256 tokenVestedPerMonth = bf.amountLocked.div(bf.vestDuration);
            uint256 tokenVestable = monthsVestable.mul(tokenVestedPerMonth);
            return (monthsVestable, tokenVestable);
        }
    }

    //return amount to be released to/from a beneficiary.
    function amountToRelease(Beneficiary memory beneficiary)
        private
        pure
        returns (uint256)
    {
        return beneficiary.amountLocked.sub(beneficiary.amountClaimed);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IBEP20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}