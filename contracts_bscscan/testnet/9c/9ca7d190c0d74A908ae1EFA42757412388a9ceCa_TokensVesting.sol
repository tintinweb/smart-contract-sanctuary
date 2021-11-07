/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

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

/**
 * @dev Interface of the TokensVesting contract.
 */
interface ITokensVesting {
    /**
     * @dev Returns the total amount of tokens in vesting plan.
     */
    function total() external view returns (uint256);

    /**
     * @dev Returns the total amount of private sale tokens in vesting plan.
     */
    function privateSale() external view returns (uint256);

    /**
     * @dev Returns the total amount of public sale tokens in vesting plan.
     */
    function publicSale() external view returns (uint256);

    /**
     * @dev Returns the total amount of team tokens in vesting plan.
     */
    function team() external view returns (uint256);

    /**
     * @dev Returns the total amount of advisor tokens in vesting plan.
     */
    function advisor() external view returns (uint256);

    /**
     * @dev Returns the total amount of liquidity tokens in vesting plan.
     */
    function liquidity() external view returns (uint256);

    /**
     * @dev Returns the total amount of incentives tokens in vesting plan.
     */
    function incentives() external view returns (uint256);

    /**
     * @dev Returns the total amount of marketing tokens in vesting plan.
     */
    function marketing() external view returns (uint256);

    /**
     * @dev Returns the total amount of reserve tokens in vesting plan.
     */
    function reserve() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of tokens.
     */
    function releasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of private sale tokens.
     */
    function privateSaleReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of public sale tokens.
     */
    function publicSaleReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of team tokens.
     */
    function teamReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of advisor tokens.
     */
    function advisorReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of liquidity tokens.
     */
    function liquidityReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of incentives tokens.
     */
    function incentivesReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of marketing tokens.
     */
    function marketingReleasable() external view returns (uint256);

    /**
     * @dev Returns the total releasable amount of reserve tokens.
     */
    function reserveReleasable() external view returns (uint256);

    /**
     * @dev Returns the total released amount of tokens.
     */
    function released() external view returns (uint256);

    /**
     * @dev Returns the total released amount of private sale tokens.
     */
    function privateSaleReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of public sale tokens.
     */
    function publicSaleReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of team tokens
     */
    function teamReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of advisor tokens.
     */
    function advisorReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of liquidity tokens.
     */
    function liquidityReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of incentives tokens.
     */
    function incentivesReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of marketing tokens.
     */
    function marketingReleased() external view returns (uint256);

    /**
     * @dev Returns the total released amount of reserve tokens.
     */
    function reserveReleased() external view returns (uint256);

    /**
     * @dev Unlocks all releasable amount of tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseAll() external;

    /**
     * @dev Unlocks all releasable amount of private sale tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releasePrivateSale() external;

    /**
     * @dev Unlocks all releasable amount of public sale tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releasePublicSale() external;

    /**
     * @dev Unlocks all releasable amount of team tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseTeam() external;

    /**
     * @dev Unlocks all releasable amount of advisor tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseAdvisor() external;

    /**
     * @dev Unlocks all releasable amount of liquidity tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseLiquidity() external;

    /**
     * @dev Unlocks all releasable amount of incentives tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseIncentives() external;

    /**
     * @dev Unlocks all releasable amount of marketing tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseMarketing() external;

    /**
     * @dev Unlocks all releasable amount of reserve tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function releaseReserve() external;

    /**
     * @dev Emitted when having amount of tokens are released.
     */
    event TokensReleased(address indexed beneficiary, uint256 amount);
}

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

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}

/**
 * @dev Implementation of the {ITokenVesting} interface.
 */
contract TokensVesting is Ownable, ITokensVesting {
    IERC20Mintable public immutable token;
    uint256 private constant DEFAULT_BASIS = 30 days;

    uint256 public revokedAmount = 0;
    uint256 public revokedAmountWithdrawn = 0;

    enum Participant {
        Unknown,
        PrivateSale,
        PublicSale,
        Team,
        Advisor,
        Liquidity,
        Incentives,
        Marketing,
        Reserve,
        OutOfRange
    }

    enum Status {
        Inactive,
        Active,
        Revoked
    }

    struct VestingInfo {
        uint256 genesisTimestamp;
        uint256 totalAmount;
        uint256 tgeAmount;
        uint256 cliff;
        uint256 duration;
        uint256 releasedAmount;
        uint256 basis;
        address beneficiary;
        Participant participant;
        Status status;
    }

    VestingInfo[] public _beneficiaries;

    event BeneficiaryAdded(address indexed beneficiary, uint256 amount);
    event BeneficiaryActivated(uint256 index, address indexed beneficiary);
    event BeneficiaryRevoked(
        uint256 index,
        address indexed beneficiary,
        uint256 amount
    );

    event Withdraw(address indexed receiver, uint256 amount);
    event EmergencyWithdraw(address indexed receiver, uint256 amount);

    /**
     * @dev Sets the value for {token}.
     *
     * This value are immutable: it can only be set once during
     * construction.
     */
    constructor(address token_) {
        require(
            token_ != address(0),
            "TokensVesting::constructor: token_ is the zero address!"
        );

        token = IERC20Mintable(token_);
    }

    /**
     * @dev Get beneficiary by index_.
     */
    function getBeneficiary(uint256 index_)
        public
        view
        returns (VestingInfo memory)
    {
        return _beneficiaries[index_];
    }

    /**
     * @dev Add beneficiary to vesting plan using default basis.
     * @param beneficiary_ recipient address.
     * @param genesisTimestamp_ genesis timestamp
     * @param totalAmount_ total amount of tokens will be vested.
     * @param tgeAmount_ an amount of tokens will be vested at tge.
     * @param cliff_ cliff duration.
     * @param duration_ linear vesting duration.
     * @param participant_ specific type of {Participant}.
     * Waring: Convert vesting monthly to duration carefully
     * eg: vesting in 9 months => duration = 8 months = 8 * 30 * 24 * 60 * 60
     */
    function addBeneficiary(
        address beneficiary_,
        uint256 genesisTimestamp_,
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 cliff_,
        uint256 duration_,
        uint8 participant_
    ) public {
        addBeneficiaryWithBasis(
            beneficiary_,
            genesisTimestamp_,
            totalAmount_,
            tgeAmount_,
            cliff_,
            duration_,
            participant_,
            DEFAULT_BASIS
        );
    }

    /**
     * @dev Add beneficiary to vesting plan.
     * @param beneficiary_ recipient address.
     * @param genesisTimestamp_ genesis timestamp
     * @param totalAmount_ total amount of tokens will be vested.
     * @param tgeAmount_ an amount of tokens will be vested at tge.
     * @param cliff_ cliff duration.
     * @param duration_ linear vesting duration.
     * @param participant_ specific type of {Participant}.
     * @param basis_ basis duration for linear vesting.
     * Waring: Convert vesting monthly to duration carefully
     * eg: vesting in 9 months => duration = 8 months = 8 * 30 * 24 * 60 * 60
     */
    function addBeneficiaryWithBasis(
        address beneficiary_,
        uint256 genesisTimestamp_,
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 cliff_,
        uint256 duration_,
        uint8 participant_,
        uint256 basis_
    ) public onlyOwner {
        require(
            genesisTimestamp_ >= block.timestamp,
            "TokensVesting::addBeneficiary: genesis too soon!"
        );
        require(
            beneficiary_ != address(0),
            "TokensVesting::addBeneficiary: beneficiary_ is the zero address!"
        );
        require(
            totalAmount_ >= tgeAmount_,
            "TokensVesting::addBeneficiary: totalAmount_ must be greater than or equal to tgeAmount_!"
        );
        require(
            Participant(participant_) > Participant.Unknown &&
                Participant(participant_) < Participant.OutOfRange,
            "TokensVesting::addBeneficiary: participant_ out of range!"
        );
        require(
            genesisTimestamp_ + cliff_ + duration_ <= type(uint256).max,
            "TokensVesting::addBeneficiary: out of uint256 range!"
        );
        require(
            basis_ > 0,
            "TokensVesting::addBeneficiary: basis_ must be greater than 0!"
        );

        VestingInfo storage info = _beneficiaries.push();
        info.beneficiary = beneficiary_;
        info.genesisTimestamp = genesisTimestamp_;
        info.totalAmount = totalAmount_;
        info.tgeAmount = tgeAmount_;
        info.cliff = cliff_;
        info.duration = duration_;
        info.participant = Participant(participant_);
        info.status = Status.Inactive;
        info.basis = basis_;

        emit BeneficiaryAdded(beneficiary_, totalAmount_);
    }

    /**
     * @dev See {ITokensVesting-total}.
     */
    function total() public view returns (uint256) {
        return _getTotalAmount();
    }

    /**
     * @dev See {ITokensVesting-privateSale}.
     */
    function privateSale() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.PrivateSale);
    }

    /**
     * @dev See {ITokensVesting-publicSale}.
     */
    function publicSale() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.PublicSale);
    }

    /**
     * @dev See {ITokensVesting-team}.
     */
    function team() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Team);
    }

    /**
     * @dev See {ITokensVesting-advisor}.
     */
    function advisor() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Advisor);
    }

    /**
     * @dev See {ITokensVesting-liquidity}.
     */
    function liquidity() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Liquidity);
    }

    /**
     * @dev See {ITokensVesting-incentives}.
     */
    function incentives() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Incentives);
    }

    /**
     * @dev See {ITokensVesting-marketing}.
     */
    function marketing() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Marketing);
    }

    /**
     * @dev See {ITokensVesting-reserve}.
     */
    function reserve() public view returns (uint256) {
        return _getTotalAmountByParticipant(Participant.Reserve);
    }

    /**
     * @dev Activate specific beneficiary by index_.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activate(uint256 index_) public onlyOwner {
        require(
            index_ >= 0 && index_ < _beneficiaries.length,
            "TokensVesting::activate: index_ out of range!"
        );

        _activate(index_);
    }

    /**
     * @dev Activate all of beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateAll() public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _activate(i);
        }
    }

    /**
     * @dev Activate all of private sale beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activatePrivateSale() public onlyOwner {
        return _activateParticipant(Participant.PrivateSale);
    }

    /**
     * @dev Activate all of public sale beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activatePublicSale() public onlyOwner {
        return _activateParticipant(Participant.PublicSale);
    }

    /**
     * @dev Activate all of team beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateTeam() public onlyOwner {
        return _activateParticipant(Participant.Team);
    }

    /**
     * @dev Activate all of advisor beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateAdvisor() public onlyOwner {
        return _activateParticipant(Participant.Advisor);
    }

    /**
     * @dev Activate all of liquidity beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateLiquidity() public onlyOwner {
        return _activateParticipant(Participant.Liquidity);
    }

    /**
     * @dev Activate all of incentives beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateIncentives() public onlyOwner {
        return _activateParticipant(Participant.Incentives);
    }

    /**
     * @dev Activate all of marketing beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateMarketing() public onlyOwner {
        return _activateParticipant(Participant.Marketing);
    }

    /**
     * @dev Activate all of reserve beneficiaries.
     *
     * Only active beneficiaries can claim tokens.
     */
    function activateReserve() public onlyOwner {
        return _activateParticipant(Participant.Reserve);
    }

    /**
     * @dev Revoke specific beneficiary by index_.
     *
     * Revoked beneficiaries cannot vest tokens anymore.
     */
    function revoke(uint256 index_) public onlyOwner {
        require(
            index_ >= 0 && index_ < _beneficiaries.length,
            "TokensVesting::revoke: index_ out of range!"
        );

        _revoke(index_);
    }

    /**
     * @dev See {ITokensVesting-releasable}.
     */
    function releasable() public view returns (uint256) {
        uint256 _releasable = 0;

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            VestingInfo storage info = _beneficiaries[i];
            _releasable =
                _releasable +
                _releasableAmount(
                    info.genesisTimestamp,
                    info.totalAmount,
                    info.tgeAmount,
                    info.cliff,
                    info.duration,
                    info.releasedAmount,
                    info.status,
                    info.basis
                );
        }

        return _releasable;
    }

    /**
     * @dev Returns the total releasable amount of tokens for the specific beneficiary by index.
     */
    function releasable(uint256 index_) public view returns (uint256) {
        require(
            index_ >= 0 && index_ < _beneficiaries.length,
            "TokensVesting::release: index_ out of range!"
        );

        VestingInfo storage info = _beneficiaries[index_];
        uint256 _releasable = _releasableAmount(
            info.genesisTimestamp,
            info.totalAmount,
            info.tgeAmount,
            info.cliff,
            info.duration,
            info.releasedAmount,
            info.status,
            info.basis
        );

        return _releasable;
    }

    /**
     * @dev See {ITokensVesting-privateSaleReleasable}.
     */
    function privateSaleReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.PrivateSale);
    }

    /**
     * @dev See {ITokensVesting-publicSaleReleasable}.
     */
    function publicSaleReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.PublicSale);
    }

    /**
     * @dev See {ITokensVesting-teamReleasable}.
     */
    function teamReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Team);
    }

    /**
     * @dev See {ITokensVesting-advisorReleasable}.
     */
    function advisorReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Advisor);
    }

    /**
     * @dev See {ITokensVesting-liquidityReleasable}.
     */
    function liquidityReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Liquidity);
    }

    /**
     * @dev See {ITokensVesting-incentivesReleasable}.
     */
    function incentivesReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Incentives);
    }

    /**
     * @dev See {ITokensVesting-marketingReleasable}.
     */
    function marketingReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Marketing);
    }

    /**
     * @dev See {ITokensVesting-reserveReleasable}.
     */
    function reserveReleasable() public view returns (uint256) {
        return _getReleasableByParticipant(Participant.Reserve);
    }

    /**
     * @dev See {ITokensVesting-released}.
     */
    function released() public view returns (uint256) {
        return _getReleasedAmount();
    }

    /**
     * @dev See {ITokensVesting-privateSaleReleased}.
     */
    function privateSaleReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.PrivateSale);
    }

    /**
     * @dev See {ITokensVesting-publicSaleReleased}.
     */
    function publicSaleReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.PublicSale);
    }

    /**
     * @dev See {ITokensVesting-teamReleased}.
     */
    function teamReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Team);
    }

    /**
     * @dev See {ITokensVesting-advisorReleased}.
     */
    function advisorReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Advisor);
    }

    /**
     * @dev See {ITokensVesting-liquidityReleased}.
     */
    function liquidityReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Liquidity);
    }

    /**
     * @dev See {ITokensVesting-incentivesReleased}.
     */
    function incentivesReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Incentives);
    }

    /**
     * @dev See {ITokensVesting-marketingReleased}.
     */
    function marketingReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Marketing);
    }

    /**
     * @dev See {ITokensVesting-reserveReleased}.
     */
    function reserveReleased() public view returns (uint256) {
        return _getReleasedAmountByParticipant(Participant.Reserve);
    }

    /**
     * @dev See {ITokensVesting-releaseAll}.
     */
    function releaseAll() public onlyOwner {
        uint256 _releasable = releasable();
        require(
            _releasable > 0,
            "TokensVesting::releaseAll: no tokens are due!"
        );

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _release(i);
        }
    }

    /**
     * @dev See {ITokensVesting-releasePrivateSale}.
     */
    function releasePrivateSale() public onlyOwner {
        return _releaseParticipant(Participant.PrivateSale);
    }

    /**
     * @dev See {ITokensVesting-releasePublicSale}.
     */
    function releasePublicSale() public onlyOwner {
        return _releaseParticipant(Participant.PublicSale);
    }

    /**
     * @dev See {ITokensVesting-releaseTeam}.
     */
    function releaseTeam() public onlyOwner {
        return _releaseParticipant(Participant.Team);
    }

    /**
     * @dev See {ITokensVesting-releaseAdvisor}.
     */
    function releaseAdvisor() public onlyOwner {
        return _releaseParticipant(Participant.Advisor);
    }

    /**
     * @dev See {ITokensVesting-releaseLiquidity}.
     */
    function releaseLiquidity() public onlyOwner {
        return _releaseParticipant(Participant.Liquidity);
    }

    /**
     * @dev See {ITokensVesting-releaseIncentives}.
     */
    function releaseIncentives() public onlyOwner {
        return _releaseParticipant(Participant.Incentives);
    }

    /**
     * @dev See {ITokensVesting-releaseMarketing}.
     */
    function releaseMarketing() public onlyOwner {
        return _releaseParticipant(Participant.Marketing);
    }

    /**
     * @dev See {ITokensVesting-releaseReserve}.
     */
    function releaseReserve() public onlyOwner {
        return _releaseParticipant(Participant.Reserve);
    }

    /**
     * @dev Release all releasable amount of tokens for the sepecific beneficiary by index.
     *
     * Emits a {TokensReleased} event.
     */
    function release(uint256 index_) public {
        require(
            index_ >= 0 && index_ < _beneficiaries.length,
            "TokensVesting::release: index_ out of range!"
        );

        VestingInfo storage info = _beneficiaries[index_];
        require(
            _msgSender() == owner() || _msgSender() == info.beneficiary,
            "TokensVesting::release: unauthorised sender!"
        );

        uint256 unreleased = _releasableAmount(
            info.genesisTimestamp,
            info.totalAmount,
            info.tgeAmount,
            info.cliff,
            info.duration,
            info.releasedAmount,
            info.status,
            info.basis
        );

        require(unreleased > 0, "TokensVesting::release: no tokens are due!");

        info.releasedAmount = info.releasedAmount + unreleased;
        token.mint(info.beneficiary, unreleased);
        emit TokensReleased(info.beneficiary, unreleased);
    }

    /**
     * @dev Withdraw revoked tokens out of contract.
     *
     * Withdraw amount of tokens upto revoked amount.
     */
    function withdraw(uint256 amount_) public onlyOwner {
        require(amount_ > 0, "TokensVesting::withdraw: Bad params!");
        require(
            amount_ <= revokedAmount - revokedAmountWithdrawn,
            "TokensVesting::withdraw: Amount exceeded revoked amount withdrawable!"
        );

        revokedAmountWithdrawn = revokedAmountWithdrawn + amount_;
        token.mint(_msgSender(), amount_);
        emit Withdraw(_msgSender(), amount_);
    }

    // /**
    //  * @dev EMERGENCY ONLY.
    //  *
    //  * Withdraw all amount of tokens in contract.
    //  */
    // function emergencyWithdraw() public onlyOwner {
    //     uint256 currentBalance = token.balanceOf(address(this));
    //     require(
    //         currentBalance > 0,
    //         "TokensVesting::emergencyWithdraw: No tokens are in contract!"
    //     );

    //     token.safeTransfer(_msgSender(), currentBalance);
    //     emit EmergencyWithdraw(_msgSender(), currentBalance);
    // }

    /**
     * @dev Release all releasable amount of tokens for the sepecific beneficiary by index.
     *
     * Emits a {TokensReleased} event.
     */
    function _release(uint256 index_) private {
        VestingInfo storage info = _beneficiaries[index_];
        uint256 unreleased = _releasableAmount(
            info.genesisTimestamp,
            info.totalAmount,
            info.tgeAmount,
            info.cliff,
            info.duration,
            info.releasedAmount,
            info.status,
            info.basis
        );

        if (unreleased > 0) {
            info.releasedAmount = info.releasedAmount + unreleased;
            token.mint(info.beneficiary, unreleased);
            emit TokensReleased(info.beneficiary, unreleased);
        }
    }

    function _getTotalAmount() private view returns (uint256) {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            totalAmount = totalAmount + _beneficiaries[i].totalAmount;
        }
        return totalAmount;
    }

    function _getTotalAmountByParticipant(Participant participant_)
        private
        view
        returns (uint256)
    {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            if (_beneficiaries[i].participant == participant_) {
                totalAmount = totalAmount + _beneficiaries[i].totalAmount;
            }
        }
        return totalAmount;
    }

    function _getReleasedAmount() private view returns (uint256) {
        uint256 releasedAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            releasedAmount = releasedAmount + _beneficiaries[i].releasedAmount;
        }
        return releasedAmount;
    }

    function _getReleasedAmountByParticipant(Participant participant_)
        private
        view
        returns (uint256)
    {
        require(
            Participant(participant_) > Participant.Unknown &&
                Participant(participant_) < Participant.OutOfRange,
            "TokensVesting::_getReleasedAmountByParticipant: participant_ out of range!"
        );

        uint256 releasedAmount = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            if (_beneficiaries[i].participant == participant_)
                releasedAmount =
                    releasedAmount +
                    _beneficiaries[i].releasedAmount;
        }
        return releasedAmount;
    }

    function _releasableAmount(
        uint256 genesisTimestamp_,
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 cliff_,
        uint256 duration_,
        uint256 releasedAmount_,
        Status status_,
        uint256 basis_
    ) private view returns (uint256) {
        if (status_ == Status.Inactive) {
            return 0;
        }

        if (status_ == Status.Revoked) {
            return totalAmount_ - releasedAmount_;
        }

        return
            _vestedAmount(genesisTimestamp_, totalAmount_, tgeAmount_, cliff_, duration_, basis_) -
            releasedAmount_;
    }

    function _vestedAmount(
        uint256 genesisTimestamp_,
        uint256 totalAmount_,
        uint256 tgeAmount_,
        uint256 cliff_,
        uint256 duration_,
        uint256 basis_
    ) private view returns (uint256) {
        require(
            totalAmount_ >= tgeAmount_,
            "TokensVesting::_vestedAmount: Bad params!"
        );

        if (block.timestamp < genesisTimestamp_) {
            return 0;
        }

        uint256 timeLeftAfterStart = block.timestamp - genesisTimestamp_;

        if (timeLeftAfterStart < cliff_) {
            return tgeAmount_;
        }

        uint256 linearVestingAmount = totalAmount_ - tgeAmount_;
        if (timeLeftAfterStart >= cliff_ + duration_) {
            return linearVestingAmount + tgeAmount_;
        }

        uint256 releaseMilestones = (timeLeftAfterStart - cliff_) / basis_ + 1;
        uint256 totalReleaseMilestones = (duration_ + basis_ - 1) / basis_ + 1;
        return
            (linearVestingAmount / totalReleaseMilestones) *
            releaseMilestones +
            tgeAmount_;
    }

    function _activate(uint256 index_) private {
        VestingInfo storage info = _beneficiaries[index_];
        if (info.status == Status.Inactive) {
            info.status = Status.Active;
            emit BeneficiaryActivated(index_, info.beneficiary);
        }
    }

    function _activateParticipant(Participant participant_) private {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            VestingInfo storage info = _beneficiaries[i];
            if (info.participant == participant_) {
                _activate(i);
            }
        }
    }

    function _revoke(uint256 index_) private {
        VestingInfo storage info = _beneficiaries[index_];
        if (info.status == Status.Revoked) {
            return;
        }

        uint256 _releasable = _releasableAmount(
            info.genesisTimestamp,
            info.totalAmount,
            info.tgeAmount,
            info.cliff,
            info.duration,
            info.releasedAmount,
            info.status,
            info.basis
        );

        uint256 oldTotalAmount = info.totalAmount;
        info.totalAmount = info.releasedAmount + _releasable;

        uint256 revokingAmount = oldTotalAmount - info.totalAmount;
        if (revokingAmount > 0) {
            info.status = Status.Revoked;
            revokedAmount = revokedAmount + revokingAmount;
            emit BeneficiaryRevoked(index_, info.beneficiary, revokingAmount);
        }
    }

    function _getReleasableByParticipant(Participant participant_)
        private
        view
        returns (uint256)
    {
        uint256 _releasable = 0;

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            VestingInfo storage info = _beneficiaries[i];
            if (info.participant == participant_) {
                _releasable =
                    _releasable +
                    _releasableAmount(
                        info.genesisTimestamp,
                        info.totalAmount,
                        info.tgeAmount,
                        info.cliff,
                        info.duration,
                        info.releasedAmount,
                        info.status,
                        info.basis
                    );
            }
        }

        return _releasable;
    }

    function _releaseParticipant(Participant participant_) private {
        uint256 _releasable = _getReleasableByParticipant(participant_);
        require(
            _releasable > 0,
            "TokensVesting::_releaseParticipant: no tokens are due!"
        );

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            if (_beneficiaries[i].participant == participant_) {
                _release(i);
            }
        }
    }
}