/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// File: contracts/intf/IERC20.sol

// This is a file copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}

// File: contracts/lib/SafeMath.sol

/**
 * @title SafeMath
 * @author JGN
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/DecimalMath.sol

/**
 * @title DecimalMath
 * @author JGN
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }
}

// File: contracts/lib/InitializableOwnable.sol

/**
 * @title Ownable
 * @author JGN
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "JGN_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/lib/SafeERC20.sol



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/JGNToken/dJGNToken.sol
interface IGovernance {
    function getLockeddJGN(address account) external view returns (uint256);
}


interface IAirdrop {
    function deposit(address account, uint256 _amount) external;
    function withdraw(address account, uint256 _amount) external; 
}


// import "@nomiclabs/buidler/console.sol";


contract dJGNToken is InitializableOwnable {
    using SafeMath for uint256;

    // ============ Storage(ERC20) ============

    string public name = "dJGN Membership Token";
    string public symbol = "dJGN";
    uint8 public decimals = 18;
    mapping(address => mapping(address => uint256)) internal _ALLOWED_;

    // ============ Storage ============

    address public immutable _JGN_TOKEN_;
    address public immutable _JGN_TEAM_;
    address public _DOOD_GOV_;

    bool public _CAN_TRANSFER_;

    // staking reward parameters
    uint256 public _JGN_PER_BLOCK_;
    uint256 public _SUPERIOR_RATIO_ = 0;
    uint256 public constant _JGN_RATIO_ = 100;
    uint256 public _JGN_FEE_BURN_RATIO_;
    address public _JGN_BURN_ADDRESS_;

    uint256 public _FEE_RATIO = 5 * 10**16;
    uint256 public _MAX_FEE_RATIO = 20 * 10**16;

    // accounting
    uint112 public alpha = 10**18; // 1
    uint112 public _TOTAL_BLOCK_DISTRIBUTION_;
    uint32 public _LAST_REWARD_BLOCK_;

    uint256 public _TOTAL_BLOCK_REWARD_;
    uint256 public _TOTAL_STAKING_POWER_;
    mapping(address => UserInfo) public userInfo;

    uint256 public totalUsers;
    mapping(address => bool) public isUser;

    uint256 public totalWithdrawFee;
    uint256 public totalBurnJGN;

    struct UserInfo {
        uint128 stakingPower;
        uint128 superiorSP;
        address superior;
        uint256 credit;
        uint256 originAmount;
    }

    IAirdrop public airdropController;


    // ============ Events ============

    event MintDJGN(address user, address superior, uint256 mintJGN);
    event RedeemDJGN(address user, uint256 receiveJGN, uint256 burnJGN, uint256 feeJGN);
    event DonateJGN(address user, uint256 donateJGN);
    event SetCantransfer(bool allowed);

    event PreDeposit(uint256 jgnAmount);
    event ChangePerReward(uint256 jgnPerBlock);
    event UpdateJGNFeeBurnRatio(uint256 jgnFeeBurnRatio);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // ============ Modifiers ============

    modifier canTransfer() {
        require(_CAN_TRANSFER_, "dJGNToken: not allowed transfer");
        _;
    }

    modifier balanceEnough(address account, uint256 amount) {
        require(availableBalanceOf(account) >= amount, "dJGNToken: available amount not enough");
        _;
    }

    // ============ Constructor ============

    constructor(
        address jgnGov,
        address jgnToken,
        address jgnTeam
    ) public {
        _DOOD_GOV_ = jgnGov;
        _JGN_TOKEN_ = jgnToken;
        _JGN_TEAM_ = jgnTeam;
    }

    // ============ Ownable Functions ============`

    function setAirdropController(address _controller) public onlyOwner {
        airdropController = IAirdrop(_controller);
    }

    function setCantransfer(bool allowed) public onlyOwner {
        _CAN_TRANSFER_ = allowed;
        emit SetCantransfer(allowed);
    }

    function changePerReward(uint256 jgnPerBlock) public onlyOwner {
        _updateAlpha();
        _JGN_PER_BLOCK_ = jgnPerBlock;
        emit ChangePerReward(jgnPerBlock);
    }

    function updateJGNFeeBurnRatio(uint256 jgnFeeBurnRatio) public onlyOwner {
        _JGN_FEE_BURN_RATIO_ = jgnFeeBurnRatio;
        emit UpdateJGNFeeBurnRatio(_JGN_FEE_BURN_RATIO_);
    }

    function updateJGNFeeBurnAddress(address addr) public onlyOwner{
        _JGN_BURN_ADDRESS_ = addr;
    }

    function updateGovernance(address governance) public onlyOwner {
        _DOOD_GOV_ = governance;
    }

    function updateSuperiorRatio(uint256 superiorRatio) public onlyOwner {
        _SUPERIOR_RATIO_ = superiorRatio;
    }

    function updateFeeRatio(uint256 feeRatio) public onlyOwner {
        require(feeRatio <= _MAX_FEE_RATIO, "_FEE_RATIO exceeded");
        _FEE_RATIO = feeRatio;
    }

    // ============ Mint & Redeem & Donate ============

    function mint(uint256 jgnAmount, address superiorAddress) public {
        require(
            superiorAddress != address(0) && superiorAddress != msg.sender,
            "dJGNToken: Superior INVALID"
        );
        require(jgnAmount > 0, "dJGNToken: must mint greater than 0");

        UserInfo storage user = userInfo[msg.sender];

        if (user.superior == address(0)) {
            require(
                superiorAddress == _JGN_TEAM_ || userInfo[superiorAddress].superior != address(0),
                "dJGNToken: INVALID_SUPERIOR_ADDRESS"
            );
            user.superior = superiorAddress;
        }

        _updateAlpha();

        IERC20(_JGN_TOKEN_).transferFrom(msg.sender, address(this), jgnAmount);

        uint256 newStakingPower = DecimalMath.divFloor(jgnAmount, alpha);

        _mint(user, newStakingPower);

        user.originAmount = user.originAmount.add(jgnAmount);
        
        if(!isUser[msg.sender]){
            isUser[msg.sender] = true;
            totalUsers = totalUsers.add(1);
        }

        if(address(airdropController) != address(0)){
            airdropController.deposit(msg.sender, newStakingPower);
        }


        emit MintDJGN(msg.sender, superiorAddress, jgnAmount);
    }

    function redeem(uint256 ijgnAmount, bool all) public balanceEnough(msg.sender, ijgnAmount) {

        _updateAlpha();
        UserInfo storage user = userInfo[msg.sender];

        uint256 jgnAmount;
        uint256 stakingPower;

        if (all) {
            stakingPower = uint256(user.stakingPower).sub(DecimalMath.divFloor(user.credit, alpha));
            jgnAmount = DecimalMath.mulFloor(stakingPower, alpha);
        } else {
            jgnAmount = ijgnAmount.mul(_JGN_RATIO_);
            stakingPower = DecimalMath.divFloor(jgnAmount, alpha);
        }

        _redeem(user, stakingPower);

        (uint256 jgnReceive, uint256 burnJGNAmount, uint256 withdrawFeeJGNAmount) = getWithdrawResult(jgnAmount);
        
        IERC20(_JGN_TOKEN_).transfer(msg.sender, jgnReceive);
        
        if (burnJGNAmount > 0) {
            IERC20(_JGN_TOKEN_).transfer(_JGN_BURN_ADDRESS_, burnJGNAmount);
        }
        
        if (withdrawFeeJGNAmount > 0) {
            alpha = uint112(
                uint256(alpha).add(
                    DecimalMath.divFloor(withdrawFeeJGNAmount, _TOTAL_STAKING_POWER_)
                )
            );
        }

        if (withdrawFeeJGNAmount > 0) {
            totalWithdrawFee = totalWithdrawFee.add(withdrawFeeJGNAmount); 
        }

        if(burnJGNAmount > 0){
            totalBurnJGN = totalBurnJGN.add(burnJGNAmount);
        }

        if(user.originAmount <= jgnAmount){
            user.originAmount = 0;
        }
        else{
            user.originAmount = user.originAmount.sub(jgnAmount);
        }

        if(all){
            if(isUser[msg.sender]){
                isUser[msg.sender] = false;
                if(totalUsers > 0){
                    totalUsers = totalUsers.sub(1);
                }
            }
        }

        if(address(airdropController) != address(0)){
            airdropController.withdraw(msg.sender, stakingPower);
        }
        
        emit RedeemDJGN(msg.sender, jgnReceive, burnJGNAmount, withdrawFeeJGNAmount);
    }

    function donate(uint256 jgnAmount) public {
        IERC20(_JGN_TOKEN_).transferFrom(msg.sender, address(this), jgnAmount);

        alpha = uint112(
            uint256(alpha).add(DecimalMath.divFloor(jgnAmount, _TOTAL_STAKING_POWER_))
        );
        emit DonateJGN(msg.sender, jgnAmount);
    }

    function preDepositedBlockReward(uint256 jgnAmount) public {
        IERC20(_JGN_TOKEN_).transferFrom(msg.sender, address(this), jgnAmount);
        _TOTAL_BLOCK_REWARD_ = _TOTAL_BLOCK_REWARD_.add(jgnAmount);
        emit PreDeposit(jgnAmount);
    }

    // ============ ERC20 Functions ============

    function totalSupply() public view returns (uint256 dJGNSupply) {
        uint256 totalJGN = IERC20(_JGN_TOKEN_).balanceOf(address(this));
        (,uint256 curDistribution) = getLatestAlpha();
        uint256 actualJGN = totalJGN.sub(_TOTAL_BLOCK_REWARD_.sub(curDistribution.add(_TOTAL_BLOCK_DISTRIBUTION_)));
        dJGNSupply = actualJGN / _JGN_RATIO_;
    }
    
    function balanceOf(address account) public view returns (uint256 dJGNAmount) {
        dJGNAmount = jgnBalanceOf(account) / _JGN_RATIO_;
    }

    function transfer(address to, uint256 dJGNAmount) public returns (bool) {
        _updateAlpha();
        _transfer(msg.sender, to, dJGNAmount);
        return true;
    }

    function approve(address spender, uint256 dJGNAmount) canTransfer public returns (bool) {
        _ALLOWED_[msg.sender][spender] = dJGNAmount;
        emit Approval(msg.sender, spender, dJGNAmount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 dJGNAmount
    ) public returns (bool) {
        require(dJGNAmount <= _ALLOWED_[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");
        _updateAlpha();
        _transfer(from, to, dJGNAmount);
        _ALLOWED_[from][msg.sender] = _ALLOWED_[from][msg.sender].sub(dJGNAmount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _ALLOWED_[owner][spender];
    }

    // ============ Helper Functions ============

    function getLatestAlpha() public view returns (uint256 newAlpha, uint256 curDistribution) {
        if (_LAST_REWARD_BLOCK_ == 0) {
            curDistribution = 0;
        } else {
            // curDistribution = _JGN_PER_BLOCK_ * (block.number - _LAST_REWARD_BLOCK_);
            if(_TOTAL_BLOCK_REWARD_ <= _TOTAL_BLOCK_DISTRIBUTION_){
                curDistribution = 0;
            }
            else{
                uint256 _curDistribution = _JGN_PER_BLOCK_ * (block.number - _LAST_REWARD_BLOCK_);
                uint256 diff = _TOTAL_BLOCK_REWARD_.sub(_TOTAL_BLOCK_DISTRIBUTION_);
                curDistribution = diff < _curDistribution ? diff : _curDistribution;
            }
        }
        if (_TOTAL_STAKING_POWER_ > 0) {
            newAlpha = uint256(alpha).add(DecimalMath.divFloor(curDistribution, _TOTAL_STAKING_POWER_));
        } else {
            newAlpha = alpha;
        }
    }

    function availableBalanceOf(address account) public view returns (uint256 dJGNAmount) {
        if (_DOOD_GOV_ == address(0)) {
            dJGNAmount = balanceOf(account);
        } else {
            uint256 lockeddJGNAmount = IGovernance(_DOOD_GOV_).getLockeddJGN(account);
            dJGNAmount = balanceOf(account).sub(lockeddJGNAmount);
        }
    }

    function jgnBalanceOf(address account) public view returns (uint256 jgnAmount) {
        UserInfo memory user = userInfo[account];
        (uint256 newAlpha,) = getLatestAlpha();
        uint256 nominalJGN =  DecimalMath.mulFloor(uint256(user.stakingPower), newAlpha);
        if(nominalJGN > user.credit) {
            jgnAmount = nominalJGN - user.credit;
        }else {
            jgnAmount = 0;
        }
    }

    function getWithdrawResult(uint256 jgnAmount)
        public
        view
        returns (
            uint256 jgnReceive,
            uint256 burnJGNAmount,
            uint256 withdrawFeeJGNAmount
        )
    {
        uint256 feeRatio = _FEE_RATIO;

        withdrawFeeJGNAmount = DecimalMath.mulFloor(jgnAmount, feeRatio);
        jgnReceive = jgnAmount.sub(withdrawFeeJGNAmount);

        burnJGNAmount = DecimalMath.mulFloor(withdrawFeeJGNAmount, _JGN_FEE_BURN_RATIO_);
        withdrawFeeJGNAmount = withdrawFeeJGNAmount.sub(burnJGNAmount);
    }

    function getJGNWithdrawFeeRatio() public view returns (uint256) {
        return _FEE_RATIO;
    }

    function getSuperior(address account) public view returns (address superior) {
        return userInfo[account].superior;
    }

    function getUserStakingPower(address account) public view returns (uint256){
        return userInfo[account].stakingPower;
    }

    // ============ Internal Functions ============

    function _updateAlpha() internal {
        (uint256 newAlpha, uint256 curDistribution) = getLatestAlpha();
        uint256 newTotalDistribution = curDistribution.add(_TOTAL_BLOCK_DISTRIBUTION_);
        require(newAlpha <= uint112(-1) && newTotalDistribution <= uint112(-1), "OVERFLOW");
        alpha = uint112(newAlpha);
        _TOTAL_BLOCK_DISTRIBUTION_ = uint112(newTotalDistribution);
        _LAST_REWARD_BLOCK_ = uint32(block.number);
    }

    function _mint(UserInfo storage to, uint256 stakingPower) internal {
        require(stakingPower <= uint128(-1), "OVERFLOW");
        UserInfo storage superior = userInfo[to.superior];
        uint256 superiorIncreSP = DecimalMath.mulFloor(stakingPower, _SUPERIOR_RATIO_);
        uint256 superiorIncreCredit = DecimalMath.mulFloor(superiorIncreSP, alpha);

        to.stakingPower = uint128(uint256(to.stakingPower).add(stakingPower));
        to.superiorSP = uint128(uint256(to.superiorSP).add(superiorIncreSP));

        superior.stakingPower = uint128(uint256(superior.stakingPower).add(superiorIncreSP));
        superior.credit = uint128(uint256(superior.credit).add(superiorIncreCredit));

        _TOTAL_STAKING_POWER_ = _TOTAL_STAKING_POWER_.add(stakingPower).add(superiorIncreSP);
    }

    function _redeem(UserInfo storage from, uint256 stakingPower) internal {
        from.stakingPower = uint128(uint256(from.stakingPower).sub(stakingPower));

        // superior decrease sp = min(stakingPower*0.1, from.superiorSP)
        uint256 superiorDecreSP = DecimalMath.mulFloor(stakingPower, _SUPERIOR_RATIO_);
        superiorDecreSP = from.superiorSP <= superiorDecreSP ? from.superiorSP : superiorDecreSP;
        from.superiorSP = uint128(uint256(from.superiorSP).sub(superiorDecreSP));

        UserInfo storage superior = userInfo[from.superior];
        uint256 creditSP = DecimalMath.divFloor(superior.credit, alpha);

        if (superiorDecreSP >= creditSP) {
            superior.credit = 0;
            superior.stakingPower = uint128(uint256(superior.stakingPower).sub(creditSP));
        } else {
            superior.credit = uint128(
                uint256(superior.credit).sub(DecimalMath.mulFloor(superiorDecreSP, alpha))
            );
            superior.stakingPower = uint128(uint256(superior.stakingPower).sub(superiorDecreSP));
        }

        _TOTAL_STAKING_POWER_ = _TOTAL_STAKING_POWER_.sub(stakingPower).sub(superiorDecreSP);
    }

    function _transfer(
        address from,
        address to,
        uint256 dJGNAmount
    ) internal canTransfer balanceEnough(from, dJGNAmount) {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(from != to, "transfer from same with to");

        uint256 stakingPower = DecimalMath.divFloor(dJGNAmount * _JGN_RATIO_, alpha);

        UserInfo storage fromUser = userInfo[from];
        UserInfo storage toUser = userInfo[to];

        _redeem(fromUser, stakingPower);
        _mint(toUser, stakingPower);

        emit Transfer(from, to, dJGNAmount);
    }
}