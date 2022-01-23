// SPDX-License-Identifier: MIT
// Studyum Labs Contracts

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";

/**
 * @dev STUDStake contract which enables depositing and claiming
 * of STUD tokens for staking purposes.
 */
contract STUDStake is Pausable {

    using SafeMath for uint256;

    struct Stake {
        uint256 stakeStart;
        uint256 stakeEnd;
        bool active; //not claimed
        uint256 months;
        uint256 percentage;
        uint256 baseAmount;
        uint256 totalAmount;
    }

    struct Option {
        uint256 months;
        uint256 percentage;
    }

    mapping(address => Stake) private _stakes;

    Option[] public stakingOptions;

    uint256 public minAmount;
    uint256 public maxAmount;

    uint256 public totalClaimableAmount;

    IBEP20 public token;

    /**
     * @dev Emitted when the claim is executed by `account`.
     */
    event Claim(address account, uint256 totalAmount);

    /**
     * @dev Emitted when the deposit is executed by `account`.
     */
    event Deposit(address account, uint256 baseAmount, uint256 totalAmount, uint256 months, uint256 percentage);

    /**
     * @dev Emitted when the mistakenly sent tokens are extracted.
     */
    event ExtractedTokens(address _token, address _owner, uint256 _amount);


    /**
     * @dev Initializes the contract
     */
    constructor(address _token, Option[] memory _stakingOptions, uint256 _minAmount, uint256 _maxAmount) {
        require(_token != address(0), "STUDStake: Token address can't be zero address");
        token = IBEP20(_token);
        _updateStakingOptions(_stakingOptions);
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        totalClaimableAmount = 0;
    }

    /**
     * @dev Claims staked STUD tokens along with interest.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - Staking period should be expired.
     */
    function claim() external whenNotPaused returns (bool) {
        Stake storage stake = _stakes[_msgSender()];
        require(stake.active, "STUDStake: No active stake");
        require(block.timestamp > stake.stakeEnd, "STUDStake: Stake not yet claimable");

        stake.active = false;

        totalClaimableAmount = SafeMath.sub(totalClaimableAmount, stake.totalAmount);

        require(token.transfer(_msgSender(), stake.totalAmount));

        emit Claim(_msgSender(), stake.totalAmount);

        return true;
    }

    /**
     * @dev Deposits arbitrary amount of STUD tokens to contract using preferred staking option.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - Sender should not have an active stake.
     * - Amount should be between the bounds and allowed by sender.
     */
    function deposit(uint256 amount, uint256 stakingOptionIndex) external whenNotPaused returns (bool) {
        Stake storage stake = _stakes[_msgSender()];
        require(!stake.active, "STUDStake: There is an active stake");

        require(stakingOptionIndex < stakingOptions.length, "STUDStake: Index out of bounds");

        require(amount >= minAmount, "STUDStake: Amount lower than minimum amount");
        require(amount <= maxAmount, "STUDStake: Amount higher than maximum amount");

        uint256 allowanceBalance = token.allowance(_msgSender(), address(this));
        require(allowanceBalance >= amount, "STUDStake: Insufficient allowance balance");

        Option memory option = stakingOptions[stakingOptionIndex];
        uint256 stakeEnd = getStakeEnd(option.months);
        uint256 totalAmount = getTotalAmount(amount, option.percentage);
        _stakes[_msgSender()] = Stake(block.timestamp, stakeEnd, true, option.months, option.percentage, amount, totalAmount);

        totalClaimableAmount = SafeMath.add(totalClaimableAmount, totalAmount);

        require(token.transferFrom(_msgSender(), address(this), amount));

        emit Deposit(_msgSender(), amount, totalAmount, option.months, option.percentage);

        return true;
    }

    /**
     * @dev Returns information about stake per account.
     */
    function getStake(address _account) external view returns (Stake memory) {
        return _stakes[_account];
    }

    /**
     * @dev Returns count of staking options.
     */
    function getStakingOptionCount() external view returns (uint256) {
        return stakingOptions.length;
    }

    /**
     * @dev Owner can change minimum and maximum deposit amount.
     */
    function changeMinMaxAmount(uint256 _minAmount, uint256 _maxAmount) external onlyOwner {
        require(_minAmount < _maxAmount, "STUDStake: Minimum should be lower than maximum");
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    /**
     * @dev Owner can change staking options.
     */
    function changeStakingOptions(Option[] memory _stakingOptions) external onlyOwner {
        _updateStakingOptions(_stakingOptions);
    }

    /**
     * @dev Calculates timestamp of the end of staking period.
     */
    function getStakeEnd(uint256 _months) internal view returns (uint256) {
        uint256 temp = SafeMath.mul(_months, 30 days);
        return SafeMath.add(block.timestamp, temp);
    }

    /**
     * @dev Updates staking options.
     */
    function _updateStakingOptions(Option[] memory _stakingOptions) internal {
        delete stakingOptions;
        uint256 length = _stakingOptions.length;
        for (uint256 i=0; i < length; i++) {
            Option memory option = _stakingOptions[i];
            stakingOptions.push(Option(option.months, option.percentage));
        }
    }

    /**
     * @dev Calculates total amount based on base amount and yield percentage.
     */
    function getTotalAmount(uint256 baseAmount, uint256 _percentage) internal pure returns (uint256) {
        uint256 temp = SafeMath.mul(baseAmount, _percentage);
        uint256 interest = SafeMath.div(temp, 10000);
        return SafeMath.add(baseAmount, interest);
    }

    /**
     * @dev Extract mistakenly sent tokens to the contract.
     */
    function extractMistakenlySentTokens(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IBEP20 bep20Token = IBEP20(_tokenAddress);
        uint256 balance = bep20Token.balanceOf(address(this));
        require(token.transfer(owner(), balance));
        emit ExtractedTokens(_tokenAddress, owner(), balance);
    }

}