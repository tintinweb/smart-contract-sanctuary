/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// : MIT

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


// File @openzeppelin/contracts/access/[email protected]

// : MIT

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


// File contracts/Escrow.sol

//: MIT
pragma solidity ^0.8.0;


contract Escrow is Ownable {
    event agreementInitialized(uint256 amount);
    event payment(uint256 amount);
    event AgreementDefaulted(uint256 outstandingObligations);

    struct TokenInfo {
        address EYE;
        address USDC; // 6 decimal places!
        uint256 initialUSDCDebt;
        uint256 initialEYEDeposit;
        uint256 monthlyPayment;
    }

    struct UserInfo {
        address Justin;
        address DGVC;
    }

    enum AgreementPhaseEnum {
        dormant,
        initialized,
        defaulted,
        concluded,
        emergencyShutdown
    }

    struct AgreementState {
        AgreementPhaseEnum phase;
        uint256 commencementTimeStamp;
        uint256 accumulatedRepayments;
    }

    TokenInfo tokens;
    UserInfo users;
    AgreementState agreementState;
    uint256 constant ONE_USDC = 1e6;
    uint256 constant ONE_EYE = 1e18;
    uint256 constant ARITHMETIC_FACTOR = 1e12;
    uint8 constant EMERGENCY_SHUTDOWN_JUSTIN_INDEX = 0;
    uint8 constant EMERGENCY_SHUTDOWN_DEGEN_INDEX = 1;
    bool[2] emergencyShutdownMultisig;

    constructor() {
        users.DGVC = 0x8b6e96947349C5eFAbD44Bd8f8901D31951202c6;
        users.Justin = msg.sender;

        tokens.EYE = 0x155ff1A85F440EE0A382eA949f24CE4E0b751c65;
        tokens.USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        tokens.initialEYEDeposit = EYE(614521);
        tokens.initialUSDCDebt = USDC(550000);
        tokens.monthlyPayment = tokens.initialUSDCDebt / 18;

        agreementState.phase = AgreementPhaseEnum.dormant;
    }

    function setAddresses(
        address eye,
        address usdc,
        address dgvc
    ) public onlyOwner {
        uint256 id;
        assembly {
            id := chainid()
        }
        require(id != 1, "ESCROW: addresses hardcoded on mainnet.");
        tokens.EYE = eye;
        tokens.USDC = usdc;
        users.DGVC = dgvc;
    }

    function initializeAgreement(uint256 USDC_units) public {
        require(USDC_units < 550001, "ESCROW: Check your input");
        agreementState.phase = AgreementPhaseEnum.initialized;
        agreementState.commencementTimeStamp = block.timestamp;
        IERC20 eye = IERC20(tokens.EYE);
        uint256 balance = eye.balanceOf(address(this));
        require(
            balance >= tokens.initialEYEDeposit,
            "ESCROW: Degen must deposit EYE in order for agreement to commence."
        );
        emit agreementInitialized(USDC_units);
        payDebtFrom(USDC_units, msg.sender);
    }

    function payDebt(uint256 USDC_units) public {
        payDebtFrom(USDC_units, msg.sender);
    }

    function payDebtFrom(uint256 USDC_units, address payer) internal {
        require(
            agreementState.phase == AgreementPhaseEnum.initialized,
            "ESCROW: cannot pay on inactive escrow."
        );
        uint256 usdc =
            USDC(USDC_units) + IERC20(tokens.USDC).balanceOf(address(this));

        //payments made by debtor
        agreementState.accumulatedRepayments += usdc;

        //end debt binding if all obligations met
        if (agreementState.accumulatedRepayments >= tokens.initialUSDCDebt) {
            agreementState.phase = AgreementPhaseEnum.concluded;
            usdc -=
                agreementState.accumulatedRepayments -
                tokens.initialUSDCDebt;
        }

        require(
            IERC20(tokens.USDC).transferFrom(payer, users.DGVC, usdc),
            "ESCROW: debtor payment failed"
        );

        uint256 proportionalPayment =
            (usdc * ARITHMETIC_FACTOR) / tokens.initialUSDCDebt;
        uint256 eyeToWithdraw =
            (proportionalPayment * tokens.initialEYEDeposit) /
                ARITHMETIC_FACTOR;
        IERC20 eyeToken = IERC20(tokens.EYE);
        uint256 balance = eyeToken.balanceOf(address(this));
        if (
            agreementState.phase == AgreementPhaseEnum.concluded ||
            balance < eyeToWithdraw
        ) {
            eyeToWithdraw = balance;
        }

        require(
            eyeToken.transfer(users.Justin, eyeToWithdraw),
            "ERC20: token transfer failed"
        );

        emit payment(usdc);
    }

    function callEYE() public {
        require(
            msg.sender == users.DGVC,
            "ESCROW: only DGVC can call bad debt."
        );
        require(
            agreementState.phase == AgreementPhaseEnum.initialized,
            "ESCROW: calling bad debt can only be done when agreement is active."
        );

        //only claim if debtor is more than a month behind on repayments

        require(!isDebtorHealthy(), "ESCROW: debtor in healthy position.");
        IERC20 eye = IERC20(tokens.EYE);
        uint256 remainingEye = eye.balanceOf(address(this));
        eye.transfer(users.DGVC, remainingEye);
        agreementState.phase = AgreementPhaseEnum.defaulted;
        emit AgreementDefaulted(
            tokens.initialUSDCDebt - agreementState.accumulatedRepayments
        );
    }

    //if true, degen can't call their debt
    function isDebtorHealthy() public view returns (bool) {
        int256 months = monthsAhead();
        bool moreThanMonthBehind = months <= -1;
        if (months == 0) {
            //accounts for being at least 1 day overdue
            int256 arrears =
                int256(expectedPayments()) -
                    int256(agreementState.accumulatedRepayments);
            moreThanMonthBehind = arrears > 0;
        }
        return !moreThanMonthBehind;
    }

    function degenWithdraw() public {
        require(
            msg.sender == users.DGVC,
            "ESCROW: only DegenVC can call this function"
        );
        require(
            agreementState.phase == AgreementPhaseEnum.dormant,
            "ESCROW: Agreement has commenced."
        );
        uint256 balance = IERC20(tokens.EYE).balanceOf(address(this));
        IERC20(tokens.EYE).transfer(users.DGVC, balance);
    }

    function expectedPayments() public view returns (uint256) {
        uint256 monthsElapsed = getMonthsElapsed();
        return tokens.monthlyPayment * monthsElapsed;
    }

    //positive number means Justin has more than met his requirement. Negative means he's in arrears
    function monthsAhead() public view returns (int256 months) {
        uint256 expected = expectedPayments();
        int256 difference =
            int256(agreementState.accumulatedRepayments) - int256(expected);
        months = difference / int256(tokens.monthlyPayment);
    }

    function getMonthsElapsed() public view returns (uint256 monthsElapsed) {
        monthsElapsed = getDaysElapsed() / 31;

        if (monthsElapsed > 18) {
            monthsElapsed = 18;
        }
    }

    function getDaysElapsed() public view returns (uint256 daysElapsed) {
        daysElapsed =
            (block.timestamp - agreementState.commencementTimeStamp) /
            (1 days);
    }

    function getDaysUntilNextPayDate() public view returns (uint256 daysLeft) {
        uint256 totalDaysElapsed = getDaysElapsed();
        return 31 - (totalDaysElapsed % 31);
    }

    //positive number means Justin has more than met his requirement. Negative means he's in arrears
    function expectedAccumulated() public view returns (uint256, uint256) {
        uint256 expected = expectedPayments();

        if (expected > agreementState.accumulatedRepayments) {
            //Justin is behind

            return (expected, agreementState.accumulatedRepayments);
        } else {
            //Justin is ahead

            return (expected, agreementState.accumulatedRepayments);
        }
    }

    //in the event of a critical bug, shutdown contract and withdraw EYE.
    function voteForEmergencyShutdown(bool vote) public {
        if (msg.sender == users.Justin) {
            emergencyShutdownMultisig[EMERGENCY_SHUTDOWN_JUSTIN_INDEX] = vote;
        } else if (msg.sender == users.DGVC) {
            emergencyShutdownMultisig[EMERGENCY_SHUTDOWN_DEGEN_INDEX] = vote;
        }

        if (emergencyShutdownMultisig[0] && emergencyShutdownMultisig[1]) {
            agreementState.phase = AgreementPhaseEnum.emergencyShutdown;
            IERC20 eye = IERC20(tokens.EYE);
            uint256 balance = eye.balanceOf(address(this));
            eye.transfer(users.DGVC, balance);
        }
    }

    function getTokenInfo()
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            tokens.EYE,
            tokens.USDC,
            tokens.initialUSDCDebt,
            tokens.initialEYEDeposit,
            tokens.monthlyPayment
        );
    }

    function getUserInfo() external view returns (address, address) {
        return (users.Justin, users.DGVC);
    }

    function getAgreementState()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            uint256(agreementState.phase),
            agreementState.commencementTimeStamp,
            agreementState.accumulatedRepayments
        );
    }

    function changeJustin(address newJustin) public {
        require(msg.sender == users.Justin);
        users.Justin = newJustin;
    }

    function changeDGVC(address newDGVC) public {
        require(msg.sender == users.DGVC);
        users.DGVC = newDGVC;
    }

    function USDC(uint256 units) public pure returns (uint256) {
        return units * ONE_USDC;
    }

    function EYE(uint256 units) public pure returns (uint256) {
        return units * ONE_EYE;
    }

    function MathMin(uint256 LHS, uint256 RHS) internal pure returns (uint256) {
        return LHS > RHS ? RHS : LHS;
    }
}