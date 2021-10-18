// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author Redefi Team
/// @title Closed End Fund 

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract ClosedEndFund is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Mintable;

    
    /// @dev Info of each user.
    struct UserInfo {
        uint256 amount;             // How many USDC tokens the user has provided.
        uint256 RERewardDebt;       // RE Reward debt.
        uint256 USDCRewardDebt;     // USDC Reward debt.
    }

    
    /// @dev Info of each project.
    struct ProjectInfo {
        uint256 USDCRewardPerBlock; // USDC to distribute per block.
        uint256 RERewardPerBlock;   // RE to distrubute per block. 1% of USDCRewardPerBlock.
        uint256 lastRewardBlock;    // Last block number in which reward distribution occurs.
        uint256 accUSDCPerShare;    // Accumulated USDC per share, times 1e36.
        uint256 accREPerShare;      // Accumulated RE per share, times 1e36.
        uint256 investEnd;          // Block number when investment period ends
        uint256 withdrawAt;         // Block number of maturity
        uint256 targetAmount;       // Target Amount to be Raised
        uint256 investAmount;       // Avaliable Invested Amount
        uint256 availAmount;        // Available USDC amount to give back as reward 
        uint256 paidOut;            // Paid USDC as reward
        uint256 claimCycle;         // Claim cycle
        uint256 rewardStartTime;    // Timestamp when yield starts  
    }

    uint256 issuanceFee = 100;      // Investment fees from issuer (Payable in USDC or (50% Discount on RE)
    uint256 tradingFee = 2;         // Trading fees on PT (Payable in USDC or (50% Discount on RE)
    uint256 claimFee = 100;         // Claim fees (Paid from Asset Yield)
    uint256 withdrawFee = 100;      // Withdraw fees (Paid from Asset Yield)
    uint256 assetManFee = 100;      // Asset Management Fee (Paid from Asset Yield)


    
    /// @dev Info of project owner.
    struct OwnerInfo {
        address owner;              // Project owner
        uint256 depositedAmount;    // Total USDC amount deposited by project owner for reward 
        uint256 withdrawnAmount;    // Total Amount project owner has withdrawn from invested amount
    }

    address public devCo;           // Dev Team Address
    address public treasury;        // Treasury Address



    /// @dev Addresses of ERC20 Token contracts
    IERC20Mintable public immutable ProjectToken;
    IERC20 public immutable REToken;
    IERC20 public immutable USDCToken;

    /// @dev The total amount of RE token that's paid out as reward.
    uint256 public REpaidOut = 0;

    /// @dev Info of each project.
    ProjectInfo[] public projectInfo;

    /// @dev Info of each user that invest USDC tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    /// @dev Info of each project owner.
    mapping (uint256 => OwnerInfo) public ownerInfo;

    event Add(uint256 indexed pid, address indexed projectOwner, uint256 targetAmount, uint256 USDCRewardPerBlock);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event USDCRewardClaim(address indexed user, uint256 indexed pid, uint256 amount);
    event RERewardClaim(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawRaisedUSDC(address indexed owner, uint256 indexed pid, uint256 amount);
    event DepositRewardUSDC(address indexed owner, uint256 indexed pid, uint256 amount);
    event WithdrawRewardUSDC(address indexed owner, uint256 indexed pid, uint256 amount);

    /**
     * @dev Sets addresses of required ERC20 tokens, devCo and treasury
     * @param _USDCtoken : USDC Token Address
     * @param _REtoken : RE Token Address
     * @param _Projecttoken : Project Token Address
     * @param _devCo : Dev Team Wallet Address
     * @param _treasury : Treasure Wallet Address
     */
    constructor(  
        address _USDCtoken,
        address _REtoken,
        address _Projecttoken,
        address _devCo,
        address _treasury
    ) {
        USDCToken = IERC20(_USDCtoken);
        REToken = IERC20Mintable(_REtoken);
        ProjectToken = IERC20Mintable(_Projecttoken);
        devCo = _devCo;
        treasury = _treasury;
    }

    /**
     * @dev Function to fund the contract for rewards (RE Token)
     * @param _amount: Amount to fund in contract
     */
    function fund(uint256 _amount) public {
        REToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    }

    /**
     * @dev Function returns number of projects
     */
    function projectLength() public view returns (uint256) {
        return projectInfo.length;
    }

    /**
     * @dev Update reward variables for all projects. Be careful of gas spending!
     */
    function massUpdateProjects() public {
        uint256 length = projectInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updateProject(pid);
        }
    }

    /**
     * @dev Update reward variables of the given project to be up-to-date.
     * @param _pid: Project ID
     */
    function updateProject(uint256 _pid) public {
        ProjectInfo storage project = projectInfo[_pid];

        uint256 lastBlock = (block.number < project.withdrawAt || project.withdrawAt == 0) ? block.number : 
            project.withdrawAt;

        if (lastBlock <= project.lastRewardBlock || project.investEnd == 0) {
            return;
        }

        if (project.investAmount == 0) {
            project.lastRewardBlock = lastBlock;
            return;
        }

        uint256 nrOfBlocks = lastBlock.sub(project.lastRewardBlock);
        uint256 USDCReward = nrOfBlocks.mul(project.USDCRewardPerBlock);
        uint256 REReward = nrOfBlocks.mul(project.RERewardPerBlock);

        project.accUSDCPerShare = project.accUSDCPerShare.add(USDCReward.mul(1e36).div(project.investAmount));
        project.accREPerShare = project.accREPerShare.add(REReward.mul(1e36).div(project.investAmount));

        project.lastRewardBlock = block.number;
    }

    /**
     * @dev Add a new project. Can be called by Contract Owner.
     * @dev DO NOT add the same Project more than once.
     * @param _projectOwner : Project Owner Address
     * @param _targetAmount : Target Amount to Raise  (As per 6 decimals)
     * @param _USDCRewardPerBlock : USDC Reward Per Block for the Project (As per 6 decimals)
     * @param _feeInRE : Flag to check fee is paid in RE or USDC
     * @param _withUpdate : Flag to update all projects
     */
    function add(
            address _projectOwner,
            uint256 _targetAmount, 
            uint256 _USDCRewardPerBlock,
            bool _feeInRE,
            bool _withUpdate
        ) public onlyOwner {

        require(_USDCRewardPerBlock > 0, "USDC reward per block 0");

        uint256 feeAmount = percent(_targetAmount, issuanceFee);

        if (_feeInRE) {
            REToken.safeTransferFrom(_projectOwner, devCo, feeAmount.mul(10**12).div(2));
        } else {
            USDCToken.safeTransferFrom(_projectOwner, devCo, feeAmount);
        }

        if (_withUpdate) {
            massUpdateProjects();
        }

        ownerInfo[projectLength()] = OwnerInfo({
            owner: _projectOwner,
            depositedAmount: 0,
            withdrawnAmount: 0
        });

        projectInfo.push(ProjectInfo({
            rewardStartTime: 0,
            USDCRewardPerBlock: _USDCRewardPerBlock,
            RERewardPerBlock: _USDCRewardPerBlock.mul(10 ** 10),
            lastRewardBlock: block.number,
            accUSDCPerShare: 0,
            accREPerShare: 0,
            investEnd: 0,
            withdrawAt: 0,
            targetAmount: _targetAmount,
            investAmount: 0,
            availAmount: 0,
            paidOut: 0,
            claimCycle: 0
        }));

        emit Add(projectInfo.length.sub(1), _projectOwner, _targetAmount, _USDCRewardPerBlock);
    }

    /**
     * @dev Deposit USDC tokens to Project.
     * @param _pid: Project ID
     * @param _amount: USDC Amount Invested by Investor (As per 6 decimals)
     */
    function deposit(uint256 _pid, uint256 _amount) public {
        ProjectInfo storage project = projectInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(project.investEnd == 0, "deposit ended for pid");

        updateProject(_pid);

        project.investAmount = project.investAmount.add(_amount);
        user.amount = user.amount.add(_amount);

        user.USDCRewardDebt = user.amount.mul(project.accUSDCPerShare).div(1e36);
        user.RERewardDebt = user.amount.mul(project.accREPerShare).div(1e36);

        USDCToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        ProjectToken.mint(msg.sender, _amount);

        uint256 REReward = percent(_amount.mul(10**12), 100);
        REToken.safeTransfer(address(msg.sender), REReward);
        REpaidOut = REpaidOut.add(REReward);

        emit Deposit(msg.sender, _pid, _amount);
        emit RERewardClaim(msg.sender, _pid, REReward);
    }

    /**
     * @dev View function to see deposited USDC for a user.
     * @param _pid: Project ID
     * @param _user: Address of User
     */
    function deposited(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    /**
     * @dev Function to end investment and start rewards
     * Claimable as per claim cycle
     * @param _pid: Project ID
     * @param _withdrawAt: Maturity Block Number
     * @param _claimCycle: Claim Period in Seconds
     */
    function endInvest(uint256 _pid, uint256 _withdrawAt, uint256 _claimCycle) public {
        ProjectInfo storage project = projectInfo[_pid];

        require(msg.sender == ownerInfo[_pid].owner, "Only project owner can call");

        project.investEnd = block.number;
        project.withdrawAt = _withdrawAt;
        project.claimCycle = _claimCycle;
        project.lastRewardBlock = block.number;
        project.rewardStartTime = block.timestamp;
    }

    /**
     * @dev View function to see pending rewards for a user.
     * @param _pid: Project ID
     * @param _user: Address of User
     */
    function pending(uint256 _pid, address _user) external view returns (uint256 USDCPending, uint256 REPending) {
        ProjectInfo storage project = projectInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        if (project.investEnd > 0) {
            uint256 _accUSDCPerShare = project.accUSDCPerShare;
            uint256 _accREPerShare = project.accREPerShare;

            if (block.number > project.lastRewardBlock) {
                uint256 lastBlock = (block.number < project.withdrawAt || project.withdrawAt == 0) ? block.number : 
                    project.withdrawAt;
                uint256 nrOfBlocks = lastBlock.sub(project.lastRewardBlock);
                uint256 USDCReward = nrOfBlocks.mul(project.USDCRewardPerBlock);
                uint256 REReward = nrOfBlocks.mul(project.RERewardPerBlock);
                _accUSDCPerShare = _accUSDCPerShare.add(USDCReward.mul(1e36).div(project.investAmount));
                _accREPerShare = _accREPerShare.add(REReward.mul(1e36).div(project.investAmount));
            }

            USDCPending = user.amount.mul(_accUSDCPerShare).div(1e36).sub(user.USDCRewardDebt);
            REPending = user.amount.mul(_accREPerShare).div(1e36).sub(user.RERewardDebt);
        }
    }

    /**
     * @dev View function for total reward the contract has yet to pay out.
     * @param _pid: Project ID
     */
    function totalPending(uint256 _pid) external view returns (uint256 USDCPending, uint256 REPending) {
        ProjectInfo storage project = projectInfo[_pid];

        if (project.investEnd > 0) {
            USDCPending = project.USDCRewardPerBlock.mul(block.number - project.investEnd).sub(project.paidOut);
            REPending = project.RERewardPerBlock.mul(block.number - project.investEnd).sub(project.paidOut);

            return (USDCPending, REPending);
        }
    }

    /**
     * @dev Withdraw deposited USDC tokens from contract after project maturity.
     * @dev Pending rewards are transferred during withdraw.
     * @param _pid: Project ID
     */ 
    function withdraw(uint256 _pid) public {
        ProjectInfo storage project = projectInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount > 0, "Deposited amount 0");
        require(block.number >= project.withdrawAt, "can't withdraw before maturity");
        
        updateProject(_pid);

        uint256 pendingUSDC = user.amount.mul(project.accUSDCPerShare).div(1e36).sub(user.USDCRewardDebt);
        uint256 pendingRE = user.amount.mul(project.accREPerShare).div(1e36).sub(user.RERewardDebt);

        require(project.availAmount >= user.amount.add(pendingUSDC), "project doesn't have enough fund");


        ProjectToken.burn(msg.sender, user.amount);
        uint256 amount = user.amount;
        
        project.investAmount = project.investAmount.sub(user.amount); // needs testing else go with burn == invested
        project.availAmount = project.availAmount.sub(user.amount.add(pendingUSDC));

        user.amount = 0;
        user.USDCRewardDebt = user.amount.mul(project.accUSDCPerShare).div(1e36);
        USDCToken.safeTransfer(address(msg.sender), amount.add(pendingUSDC));
        project.paidOut = project.paidOut.add(pendingUSDC);

        uint256 REBalance = REToken.balanceOf(address(this));

        if (REBalance >= pendingRE) {
            uint256 feeAmount = percent(pendingRE, withdrawFee);
            REToken.safeTransfer(treasury, feeAmount);

            user.RERewardDebt = user.amount.mul(project.accREPerShare).div(1e36);
            REToken.safeTransfer(msg.sender, pendingRE.sub(feeAmount));
            REpaidOut = REpaidOut.add(pendingRE);

            emit RERewardClaim(msg.sender, _pid, pendingRE);
        }

        emit Withdraw(msg.sender, _pid, amount);
        emit USDCRewardClaim(msg.sender, _pid, pendingUSDC);
    }

    /**
     * @dev Claim Yield
     * @param _pid: Project ID
     */
    function claim(uint256 _pid) public {
        ProjectInfo storage project = projectInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount > 0, "Deposited amount 0");
        require(ProjectToken.balanceOf(msg.sender) >= user.amount, "Not holding Project Token");
        require((block.timestamp.sub(project.rewardStartTime)) % project.claimCycle < 3 days, "Claim in claim period");

        updateProject(_pid);

        uint256 pendingUSDC = user.amount.mul(project.accUSDCPerShare).div(1e36).sub(user.USDCRewardDebt);
        uint256 pendingRE = user.amount.mul(project.accREPerShare).div(1e36).sub(user.RERewardDebt);
        
        if (project.availAmount >= pendingUSDC) {
            project.availAmount = project.availAmount.sub(pendingUSDC);
            user.USDCRewardDebt = user.amount.mul(project.accUSDCPerShare).div(1e36);
            project.paidOut = project.paidOut.add(pendingUSDC);
            USDCToken.safeTransfer(address(msg.sender), pendingUSDC);
            
            emit USDCRewardClaim(msg.sender, _pid, pendingUSDC);
        }

        uint256 REBalance = REToken.balanceOf(address(this));

        if (REBalance >= pendingRE) {
            uint256 claimFeeAmount = percent(pendingRE, claimFee);
            uint256 assetManFeeAmount = percent(pendingRE, assetManFee);

            REToken.safeTransfer(treasury, claimFeeAmount);
            REToken.safeTransfer(treasury, assetManFeeAmount);

            user.RERewardDebt = user.amount.mul(project.accREPerShare).div(1e36);
            REToken.safeTransfer(msg.sender, pendingRE.sub(claimFeeAmount).sub(assetManFeeAmount));
            REpaidOut = REpaidOut.add(pendingRE);
            
            emit RERewardClaim(msg.sender, _pid, pendingRE);
        }
    }

    /**
     * @dev Withdraw USDC after project invest period completes
     * @dev Only Project owner can user this function
     * @param _pid: Project ID
     * @param _amount: Amount to Withdraw (As per 6 decimals)
     */
    function withdrawRaisedUSDC(uint256 _pid, uint256 _amount) public {
        ProjectInfo storage project = projectInfo[_pid];

        require(msg.sender == ownerInfo[_pid].owner, "Only project owner can withdraw");
        require(ownerInfo[_pid].withdrawnAmount.add(_amount) <= project.investAmount, "Can't withdraw above raised");

        ownerInfo[_pid].withdrawnAmount = ownerInfo[_pid].withdrawnAmount.add(_amount);
        USDCToken.safeTransfer(address(msg.sender), _amount);

        emit WithdrawRaisedUSDC(msg.sender, _pid, _amount);
    }

    /**
     * @dev Deposit USDC for Yield and after project matures
     * @dev Only Project owner can user this function
     * @param _pid: Project ID
     * @param _amount: Amount to Deposit (As per 6 decimals)
     */
    function depositRewardUSDC(uint256 _pid, uint256 _amount) public {
        ProjectInfo storage project = projectInfo[_pid];
        require(msg.sender == ownerInfo[_pid].owner, "Only project owner can deposit");

        project.availAmount = project.availAmount.add(_amount);
        ownerInfo[_pid].depositedAmount = ownerInfo[_pid].depositedAmount.add(_amount);
        USDCToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        emit DepositRewardUSDC(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw deposited USDC
     * @dev Only Project owner can user this function
     * @param _pid: Project ID
     * @param _amount: Amount to Withdraw (As per 6 decimals)
     */
    function withdrawRewardUSDC(uint256 _pid, uint256 _amount) public {
        ProjectInfo storage project = projectInfo[_pid];

        require(msg.sender == ownerInfo[_pid].owner, "Only project owner can withdraw");
        require(project.availAmount >= _amount, "Can't withdraw above available");

        project.availAmount = project.availAmount.sub(_amount);
        USDCToken.safeTransfer(address(msg.sender), _amount);

        emit WithdrawRewardUSDC(msg.sender, _pid, _amount);
    }

    /**
     * @dev Transfer Project Token
     * @param _pid: Project ID
     * @param _to: To address
     * @param _amount: Amount to transfer (As per 6 decimals)
     * @param _feeInRE: Flag for Tranfer fee in RE or USDC
     */
    function transferProjectToken(uint256 _pid, address _to, uint256 _amount, bool _feeInRE) public {
        ProjectInfo storage project = projectInfo[_pid];
        UserInfo storage from = userInfo[_pid][msg.sender];
        UserInfo storage to = userInfo[_pid][_to];

        require(from.amount >= _amount, "Not have enough amount");

        uint256 feeAmount = percent(_amount, tradingFee);

        if (_feeInRE) {
            REToken.safeTransferFrom(msg.sender, devCo, feeAmount.mul(10**12).div(2));
        } else {
            USDCToken.safeTransferFrom(msg.sender, devCo, feeAmount);
        }

        ProjectToken.safeTransferFrom(msg.sender, _to, _amount);

        from.amount = from.amount.sub(_amount);
        to.amount = to.amount.add(_amount);

        from.USDCRewardDebt = from.amount.mul(project.accUSDCPerShare).div(1e36);
        from.RERewardDebt = from.amount.mul(project.accREPerShare).div(1e36);

        to.USDCRewardDebt = to.amount.mul(project.accUSDCPerShare).div(1e36);
        to.RERewardDebt = to.amount.mul(project.accREPerShare).div(1e36);
    }

    /**
     * @dev Function to Calculate Percentage
     * @param _amount: Input Amount
     * @param _fraction: Fraction multiplied with 100
     */    
    function percent(uint256 _amount, uint256 _fraction) public virtual pure returns(uint256) {
        return ((_amount).mul(_fraction)).div(10000);
    }
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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