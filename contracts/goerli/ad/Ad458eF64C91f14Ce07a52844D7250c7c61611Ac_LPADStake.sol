// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IVerify {
    function isValidSigner(uint _amount1, uint _amount2, address _caller, bytes memory _signature) external pure returns(bool);
}

contract LPADStake is Ownable {
    using SafeMath for uint256;

    uint256 private _stakingDays = 10;
    uint256 private _unStakingChargePercentage = 1000;
    address private _tokenAddress;
    address private _verifyAddress;

    address[] private _stakeHolders;
    mapping(address => uint256) private _stakes;
    mapping(address => uint256) private _stakeTime;

    event Stake(address stakerAddress, uint256 amount);
    event Unstake(address stakerAddress, uint256 amount);
    event ClaimReward(address _receiver, uint256 amount);
    event PurchaseTokens(uint256 _tokens, uint256 _bnbs, address _receiver);

    constructor(address tokenAddress_, address verifyAddress_) Ownable() {
        _tokenAddress = tokenAddress_;
        _verifyAddress = verifyAddress_;
    }

    /// @notice Structure for the tiers
    struct TierLimitConfigurations {
        uint16 fineDays;
        uint16 finePercentage;
        uint256 limit;
        string tierName;
    }

    /// @notice mapping from tier Id to TierLimitConfigurations
    mapping(string => TierLimitConfigurations)
        public allTierLimitConfigurations;

    /// @notice mapping from user address to tier Id
    mapping(address => string) public userTiers;

    mapping(string => bool) private isUniqueTierName;

    /// @notice array of tier Id's
    string[] public tierIDs;

    // BNB Receive function
    fallback() external {}

    receive() external payable {}

    function addTier(
        string calldata _tierID,
        string calldata _tierName,
        uint256 _limit,
        uint16 _fineDays,
        uint16 _finePercentage
    ) external onlyOwner {
        require(
            bytes(_tierID).length != 0,
            "LPADStake: Tier ID cannot be empty!"
        );
        require(
            bytes(_tierName).length != 0,
            "LPADStake: Tier name cannot be empty"
        );
        require(
            bytes(allTierLimitConfigurations[_tierID].tierName).length == 0,
            "LPADStake: _tierID already exist!"
        );
        require(
            isUniqueTierName[_tierName] == false,
            "LPADStake: Tier name already exist!"
        );
        require(
            _finePercentage <= 10000,
            "LPADStake: Invalid _finePercentage !"
        );

        TierLimitConfigurations memory newTier;
        newTier.fineDays = _fineDays;
        newTier.finePercentage = _finePercentage;
        newTier.limit = _limit;
        newTier.tierName = _tierName;
        allTierLimitConfigurations[_tierID] = newTier;

        isUniqueTierName[_tierName] = true;
        tierIDs.push(_tierID);
    }

    function removeTierID(string calldata _tierID) external onlyOwner {
        require(
            bytes(_tierID).length != 0,
            "LPADStake: Tier ID cannot be empty!"
        );
        require(
            bytes(allTierLimitConfigurations[_tierID].tierName).length != 0,
            "LPADStake: Tier ID Does Not Exist!"
        );

        delete allTierLimitConfigurations[_tierID];

        for (uint256 i = 0; i < tierIDs.length; i++) {
            if (keccak256(abi.encodePacked((tierIDs[i]))) == keccak256(abi.encodePacked((_tierID)))) {
                tierIDs[i] = tierIDs[tierIDs.length - 1];
                tierIDs.pop();
                break;
            }
        }
    }

    function updateTiersConfigurations(
        string[] memory _tierIDs,
        string[] memory _tierNames,
        uint16[] memory _fineDays,
        uint16[] memory _finePercentages,
        uint256[] memory _limits
    ) external onlyOwner {
        require(
            _tierIDs.length <= tierIDs.length,
            "LPADStake: Invalid _tierIDs array length!"
        );
        for (uint16 index = 0; index < _tierIDs.length; index++) {
            require(
                bytes(allTierLimitConfigurations[_tierIDs[index]].tierName)
                    .length != 0,
                "LPADStake: Invalid tier ID!"
            );
            allTierLimitConfigurations[
                _tierIDs[index]
            ] = TierLimitConfigurations(
                _fineDays[index],
                _finePercentages[index],
                _limits[index],
                _tierNames[index]
            );
        }
    }

    /// @notice finds the tier slot for the stack Amount
    function getTierForUser(uint256 _amount, address _user)
        private
        returns (TierLimitConfigurations memory _tier)
    {
        if (tierIDs.length == 1) {
            userTiers[_user] = tierIDs[0];
            return allTierLimitConfigurations[tierIDs[0]];
        }

        string memory _tierID;
        string memory _highestLimitTierID = tierIDs[0];
        string memory _lowestLimitTierID = tierIDs[0];

        for (uint16 index = 0; index < tierIDs.length; index++) {
            if (
                allTierLimitConfigurations[tierIDs[index]].limit >
                allTierLimitConfigurations[_highestLimitTierID].limit
            ) {
                _highestLimitTierID = tierIDs[index];
            }
            if (
                allTierLimitConfigurations[tierIDs[index]].limit <
                allTierLimitConfigurations[_lowestLimitTierID].limit
            ) {
                _lowestLimitTierID = tierIDs[index];
            }

            if (allTierLimitConfigurations[tierIDs[index]].limit <= _amount) {
                if (
                    allTierLimitConfigurations[_tierID].limit == 0 ||
                    allTierLimitConfigurations[_tierID].limit <
                    allTierLimitConfigurations[tierIDs[index]].limit
                ) _tierID = tierIDs[index];
            }
        }

        if (bytes(_tierID).length == 0) {
            if (
                _amount >= allTierLimitConfigurations[_highestLimitTierID].limit
            ) {
                _tierID = _highestLimitTierID;
            } else {
                _tierID = _lowestLimitTierID;
            }
        }

        userTiers[_user] = _tierID;
        return allTierLimitConfigurations[_tierID];
    }

    /**
     * @notice With this method users can stake their tokens
     * @param _amount Amount of tokens to stake
     */
    function stakeCoins(uint256 _amount) external {
        require(_amount != 0, "LPADStake: _amount should non-zero!");
        require(
            IERC20(_tokenAddress).balanceOf(msg.sender) >= _amount,
            "LPADStake: Insufficient Funds!"
        );
        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            )
        );
        uint256 _finalAmount = _amount.sub(_amount.mul(9).div(100)); // 9% fees of stake amount
        if (_stakes[msg.sender] == 0) {
            _stakeHolders.push(msg.sender);
        }
        _stakes[msg.sender] = _stakes[msg.sender].add(_finalAmount);
        TierLimitConfigurations memory userTier = getTierForUser(
            _stakes[msg.sender],
            msg.sender
        );
        uint256 _days = userTier.fineDays;
        _stakeTime[msg.sender] = block.timestamp.add(_days.mul(1 days));
        emit Stake(msg.sender, _finalAmount);
    }

    /**
     * @notice With this method users can redeem their staked tokens
     * @param _amount Amount of tokens to redeem
     */
    function unstakeCoins(uint256 _amount) external {
        require(_amount != 0, "LPADStake: _amount should non-zero!");
        require(isStakeHolder(msg.sender), "LPADStake: Not a stakeholder!");
        require(
            _stakes[msg.sender] >= _amount,
            "LPADStake: Holder have insufficient stakes!"
        );
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,
            "LPADStake: Insufficient funds in the Treasury!"
        );
        uint256 _amountToUnstake = _amount;
        address _user = msg.sender;
        TierLimitConfigurations memory userTier = allTierLimitConfigurations[
            userTiers[_user]
        ];
        if (block.timestamp <= _stakeTime[_user]) {
            uint16 _finePercentage = userTier.finePercentage;
            _amountToUnstake = _amount.sub(
                _amount.mul(_finePercentage).div(10000)
            );
        }
        require(IERC20(_tokenAddress).transfer(_user, _amountToUnstake));
        _stakes[_user] = _stakes[msg.sender].sub(_amount);
        userTier = getTierForUser(_stakes[_user], _user);
        if (_stakes[_user] == 0) {
            removeStakeHolder(_user);
            delete _stakeTime[_user];
            delete userTiers[_user];
        }
        emit Unstake(_user, _amount);
    }

    /**
     * @notice It returns the amount of stakes of the stakeholder
     * @param _stakeHolder Adress of stakeholder to check
     * @return Amount of stake
     */
    function stakeOf(address _stakeHolder) external view returns (uint256) {
        return _stakes[_stakeHolder];
    }

    /**
     * @notice Removes a stakeholder address from the _stakeHolders array
     * @param _stakeHolder Address to remove
     */
    function removeStakeHolder(address _stakeHolder) private {
        for (uint256 index = 0; index < _stakeHolders.length; index++) {
            if (_stakeHolder == _stakeHolders[index]) {
                _stakeHolders[index] = _stakeHolders[_stakeHolders.length - 1];
                _stakeHolders.pop();
                break;
            }
        }
    }

    /**
     * @notice It shows weather the address is a valid stakeholder or not
     * @param _stakeHolder Address to check
     * @return 'true' and 'index' if valid or 'false' and '0' if not
     */
    function isStakeHolder(address _stakeHolder) private view returns (bool) {
        for (uint256 index = 0; index < _stakeHolders.length; index++) {
            if (_stakeHolder == _stakeHolders[index]) return true;
        }
        return false;
    }

    /**
     * @notice Verify user signature and give the reward to the user
     * @param _amount Amount of claim to redeem
     * @param _signature Signature signed by the user
     */
    function claimReward(uint256 _amount, bytes memory _signature) external {
        require(_amount != 0, "LPADStake: _amount should non-zero!");
        require(isStakeHolder(msg.sender), "LPADStake: Not a stakeholder!");
        require(
            _amount <= IERC20(_tokenAddress).balanceOf(address(this)),
            "LPADStake: Insufficient funds in the Treasury!"
        );
        require(
            IVerify(_verifyAddress).isValidSigner(
                _amount,
                0,
                msg.sender,
                _signature
            ),
            "LPADStake: Invalid Signature!"
        );
        require(IERC20(_tokenAddress).transfer(msg.sender, _amount));
        emit ClaimReward(msg.sender, _amount);
    }

    function getPathFundTokens(uint256 _pathFundAmount, bytes memory _signature)
        external
        payable
    {
        require(
            _pathFundAmount > 0,
            "LPADStake: PathFund token amount should non-zero!"
        );
        require(msg.value > 0, "LPADStake: BNB amount should non-zero!");
        require(
            _pathFundAmount <= IERC20(_tokenAddress).balanceOf(address(this)),
            "LPADStake: Insufficient funds in the Treasury!"
        );
        require(
            IVerify(_verifyAddress).isValidSigner(
                _pathFundAmount,
                msg.value,
                msg.sender,
                _signature
            ),
            "LPADStake: Invalid Signature!"
        );
        require(IERC20(_tokenAddress).transfer(msg.sender, _pathFundAmount));
        address _owner = owner();
        payable(_owner).transfer(msg.value);
        emit PurchaseTokens(_pathFundAmount, msg.value, msg.sender);
    }
}