// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
//Contract deployed by LK Tech Club Incubator 2021 dba Lift.Kitchen - 4/24/2021

// --------------------------------------------------------------------------------------
// At expansion Stakers (LIFT & CTRL) collect 20% (variable below) in CTRL
// CTRL is distributed as a % of value staked
//      LIFT Value = LIFT Amount * LIFT Price
//      CTRL Value = CTRL Amount * CTRL Price

// Staking LIFT is timelocked 60 days; removal prior to end of timelock = 60 - days staked reduction as a percent
// abandoned LIFT is migrated to IdeaFund

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import './utils/Operator.sol';
import './utils/ContractGuard.sol';
import './utils/ShareWrapper.sol';

//import './interfaces/IBasisAsset.sol';
import './interfaces/IOracle.sol';

//import 'hardhat/console.sol';

contract Boardroom is ShareWrapper, ContractGuard, Operator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */

    //uint256[2][] is an array of [amount][timestamp]
    //used to handle the timelock of LIFT tokens
    struct StakingSeatShare {        
        uint256 lastSnapshotIndex;
        uint256 rewardEarned; 
        uint256[2][] stakingWhenQuatity;
        bool isEntity;
    }

    //used to handle the staking of CTRL tokens
    struct StakingSeatControl {        
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        bool isEntity;
    }

    struct BoardSnapshotShare {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    struct BoardSnapshotControl {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerControl;
    }

    /* ========== STATE VARIABLES ========== */

    mapping(address => StakingSeatShare) private stakersShare;
    mapping(address => StakingSeatControl) private stakersControl;

    BoardSnapshotShare[] private boardShareHistory;
    BoardSnapshotControl[] private boardControlHistory;

    uint daysRequiredStaked = 90; // staking less than X days = X - Y reduction in withdrawl, Y = days staked
    address ideaFund; //Where the forfeited shares end up
    address theOracle;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _share, address _control, address _ideafund, address _theOracle) {
        share = _share;
        control = _control;
        ideaFund = _ideafund;
        theOracle = _theOracle;

        BoardSnapshotShare memory genesisSSnapshot = BoardSnapshotShare({
            time: block.number,
            rewardReceived: 0,
            rewardPerShare: 0
        });
        boardShareHistory.push(genesisSSnapshot);

        BoardSnapshotControl memory genesisCSnapshot = BoardSnapshotControl({
            time: block.number,
            rewardReceived: 0,
            rewardPerControl: 0
        });
        boardControlHistory.push(genesisCSnapshot);
    }

    /* ========== Modifiers =============== */
    modifier stakerExists {
        require(
            getbalanceOfControl(msg.sender) > 0 ||
            getbalanceOfShare(msg.sender) > 0,
            'Boardroom: The director does not exist'
        );
        _;
    }

    modifier updateRewardShare(address staker, uint256 amount) {
        if (staker != address(0)) {
            StakingSeatShare storage seatS = stakersShare[staker];
            (seatS.rewardEarned, ) = earned(staker);
            seatS.lastSnapshotIndex = latestShareSnapshotIndex();
            seatS.isEntity = true;
            
            //validate this is getting stored in the struct correctly
            if(amount > 0) {
                seatS.stakingWhenQuatity.push([amount, block.timestamp]);
            }      
            stakersShare[staker] = seatS;
        }
        _;
    }

    modifier updateRewardControl(address staker, uint256 amount) {
        if (staker != address(0)) {
            StakingSeatControl memory seatC = stakersControl[staker];
            (, seatC.rewardEarned) = earned(staker);
            seatC.lastSnapshotIndex= latestControlSnapshotIndex();
            seatC.isEntity = true;            
            stakersControl[staker] = seatC;
        }
        _;
    }

    modifier updateRewardWithdraw(address staker) {
        if (staker != address(0)) {
            StakingSeatShare memory seatS = stakersShare[staker];
            StakingSeatControl memory seatC = stakersControl[staker];
            (seatS.rewardEarned, seatC.rewardEarned) = earned(staker);
            seatS.lastSnapshotIndex = latestShareSnapshotIndex();
            seatC.lastSnapshotIndex= latestControlSnapshotIndex();
            seatS.isEntity = true;
            seatC.isEntity = true;
            stakersShare[staker] = seatS;
            stakersControl[staker] = seatC;
        }
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // =========== Snapshot getters

    function latestShareSnapshotIndex() public view returns (uint256) {
        return boardShareHistory.length.sub(1);
    }

    function getLatestShareSnapshot() internal view returns (BoardSnapshotShare memory) {
        return boardShareHistory[latestShareSnapshotIndex()];
    }

    function getLastShareSnapshotIndexOf(address staker)
        public
        view
        returns (uint256)
    {
        return stakersShare[staker].lastSnapshotIndex;
    }

    function getLastShareSnapshotOf(address staker)
        internal
        view
        returns (BoardSnapshotShare memory)
    {
        return boardShareHistory[getLastShareSnapshotIndexOf(staker)];
    }

    // control getters
    function latestControlSnapshotIndex() internal view returns (uint256) {
        return boardControlHistory.length.sub(1);
    }

    function getLatestControlSnapshot() internal view returns (BoardSnapshotControl memory) {
        return boardControlHistory[latestControlSnapshotIndex()];
    }

    function getLastControlSnapshotIndexOf(address staker)
        public
        view
        returns (uint256)
    {
        return stakersControl[staker].lastSnapshotIndex;
    }

    function getLastControlSnapshotOf(address staker)
        internal
        view
        returns (BoardSnapshotControl memory)
    {
        return boardControlHistory[getLastControlSnapshotIndexOf(staker)];
    }

    // =========== Director getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestShareSnapshot().rewardPerShare;
    }

    function rewardPerControl() public view returns (uint256) {
        return getLatestControlSnapshot().rewardPerControl;
    }

    
    // Staking and the dates staked calculate the percentage they would forfeit if they withdraw now
    // be the warning
    function getStakedAmountsShare() public view returns (uint256[2][] memory earned) {
            StakingSeatShare memory seatS = stakersShare[msg.sender];
            return seatS.stakingWhenQuatity;
    }

    function earned(address staker) public view returns (uint256, uint256) {
        uint256 latestRPS = getLatestShareSnapshot().rewardPerShare;
        uint256 storedRPS = getLastShareSnapshotOf(staker).rewardPerShare;

        uint256 latestRPC = getLatestControlSnapshot().rewardPerControl;
        uint256 storedRPC = getLastControlSnapshotOf(staker).rewardPerControl;

        return
            (getbalanceOfShare(staker).mul(latestRPS.sub(storedRPS)).div(1e18).add(stakersShare[staker].rewardEarned),
            getbalanceOfControl(staker).mul(latestRPC.sub(storedRPC)).div(1e18).add(stakersControl[staker].rewardEarned));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeShare(uint256 amount)
        public
        override
        onlyOneBlock
    {
        require(amount > 0, 'Boardroom: Cannot stake 0');
        stakeShareForThirdParty(msg.sender, msg.sender,amount);
        emit Staked(msg.sender, amount);
    }

    function stakeShareForThirdParty(address staker, address from,uint256 amount)
        public
        override
        onlyOneBlock
        updateRewardShare(staker, amount)
        {
            require(amount > 0, 'Boardroom: Cannot stake 0');
            super.stakeShareForThirdParty(staker, from, amount);
            emit Staked(from, amount);
        }

    function stakeControl(uint256 amount)
        public
        override
        onlyOneBlock
    {
        require(amount > 0, 'Boardroom: Cannot stake 0');
        stakeControlForThirdParty(msg.sender, msg.sender, amount);
        emit Staked(msg.sender, amount);
    }

    function stakeControlForThirdParty(address staker, address from, uint256 amount)
        public
        override
        onlyOneBlock
        updateRewardControl(staker, amount)
    {
        require(amount > 0, 'Boardroom: Cannot stake 0');
        super.stakeControlForThirdParty(staker, from, amount);
        emit Staked(staker, amount);
    }

    // this function withdraws all of your LIFT tokens regardless of timestamp 
    // using this function could lead to significant reductions if claimed LIFT
    function withdrawShareDontCallMeUnlessYouAreCertain()
        public
        onlyOneBlock
        stakerExists
        updateRewardWithdraw(msg.sender)
    {
        uint256 actualAmount = 0;
        require(getbalanceOfShare(msg.sender) > 0, 'Boardroom: Cannot withdraw 0');

        StakingSeatShare storage seatS = stakersShare[msg.sender];
        //forloop that iterates on the stakings and determines the reduction if any before creating a final amount for withdrawl
         for (uint256 i = 0; i < seatS.stakingWhenQuatity.length; i++) {
             uint256[2] storage arrStaked = seatS.stakingWhenQuatity[i];
             uint daysStaked = (block.timestamp - arrStaked[1]) / 60 / 60 / 24; // = Y Days
             if (daysStaked >= daysRequiredStaked){
                   settotalSupplyShare(gettotalSupplyShare().sub(arrStaked[0])); 
                   setbalanceOfShare(msg.sender, getbalanceOfShare(msg.sender).sub(arrStaked[0]));
                   IERC20(share).safeTransfer(msg.sender, arrStaked[0]);
                   actualAmount += arrStaked[0];
             } else {
                //calculate reduction percentage  
                // EX only staked 35 days of 60 
                // 60 - 35 = 25% reduction
                // 100 - 25% = 75% remaining (multiply by that / div 100)
                uint256 reducedAmount = arrStaked[0].mul(uint256(100).sub(daysRequiredStaked.sub(daysStaked))).div(100);
                settotalSupplyShare(gettotalSupplyShare().sub(arrStaked[0])); 
                setbalanceOfShare(msg.sender, getbalanceOfShare(msg.sender).sub(arrStaked[0]));
                IERC20(share).safeTransfer(msg.sender, reducedAmount);
                IERC20(share).safeTransfer(address(ideaFund), arrStaked[0].sub(reducedAmount));
                actualAmount += reducedAmount;
             }
            //Make sure this is actually 0ing out and saving to the struct
            arrStaked[0] = 0;
            arrStaked[1] = 0;
         }

        emit WithdrawnWithReductionShare(msg.sender, actualAmount);
    }

    // The withdrawShare function with a timestamp input should take that data right out of the below 
    // and feed it back to withdraw
    function withdrawShare(uint256 stakedTimeStamp)
        public
        onlyOneBlock
        stakerExists
        updateRewardWithdraw(msg.sender)
    {
        uint256 amount = 0;
        uint256 actualAmount = 0;

        StakingSeatShare storage seatS = stakersShare[msg.sender];
        //forloop that iterates on the stakings and determines the reduction if any before creating a final amount for withdrawl
         for (uint256 i = 0; i < seatS.stakingWhenQuatity.length; i++) {
             uint256[2] storage arrStaked = seatS.stakingWhenQuatity[i];
             if(arrStaked[1] == stakedTimeStamp) {
                amount = arrStaked[0];
                uint daysStaked = (block.timestamp - arrStaked[1]) / 60 / 60 / 24; // = Y Days
                //console.log("days staked", daysStaked);
                if (daysStaked >= daysRequiredStaked){
                    settotalSupplyShare(gettotalSupplyShare().sub(arrStaked[0])); 
                    setbalanceOfShare(msg.sender, getbalanceOfShare(msg.sender).sub(arrStaked[0]));
                    IERC20(share).safeTransfer(msg.sender, arrStaked[0]);
                    actualAmount += arrStaked[0];
                } else {
                    //calculate reduction percentage  
                    // EX only staked 35 days of 60 
                    // 60 - 35 = 25% reduction
                    // 100 - 25% = 75% remaining (multiply by that / div 100)
                    uint256 reducedAmount = arrStaked[0].mul(uint256(100).sub(daysRequiredStaked.sub(daysStaked))).div(100);

                    settotalSupplyShare(gettotalSupplyShare().sub(arrStaked[0])); 
                    setbalanceOfShare(msg.sender, getbalanceOfShare(msg.sender).sub(arrStaked[0]));
                    IERC20(share).safeTransfer(msg.sender, reducedAmount);
                    IERC20(share).safeTransfer(address(ideaFund), arrStaked[0].sub(reducedAmount));
                    actualAmount += reducedAmount;
                }
                
                //Make sure this is actually 0ing out and saving to the struct
                arrStaked[0] = 0;
                arrStaked[1] = 0;
             }          
         }

        emit WithdrawnWithReductionShare(msg.sender, actualAmount);
    }

    function withdrawControl(uint256 amount)
        public
        override
        onlyOneBlock
        stakerExists
        updateRewardWithdraw(msg.sender)
    {
        require(amount > 0, 'Boardroom: Cannot withdraw 0');
        super.withdrawControl(amount);
        emit WithdrawControl(msg.sender, amount);
    }

    function claimReward()
        public
        updateRewardWithdraw(msg.sender)
    {
        uint256 reward = stakersShare[msg.sender].rewardEarned;
        reward += stakersControl[msg.sender].rewardEarned;

        if (reward > 0) {
            stakersShare[msg.sender].rewardEarned = 0;
            stakersControl[msg.sender].rewardEarned = 0;
            IERC20(control).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function allocateSeigniorage(uint256 amount)
        external
        onlyOneBlock
        onlyOperator
    {
        if(amount == 0)
            return;

        if(gettotalSupplyShare() == 0 && gettotalSupplyControl() == 0)
            return;

        uint256 shareValue = gettotalSupplyShare().mul(IOracle(theOracle).priceOf(share));
        uint256 controlValue = gettotalSupplyControl().mul(IOracle(theOracle).priceOf(control));

        uint256 totalStakedValue = shareValue + controlValue;

        uint percision = 9;

        uint256 rewardPerShareValue = amount.mul(shareValue.mul(10**percision).div(totalStakedValue)).div(10**percision);
        uint256 rewardPerControlValue = amount.mul(controlValue.mul(10**percision).div(totalStakedValue)).div(10**percision);

        if (rewardPerShareValue > 0) {
            uint256 prevRPS = getLatestShareSnapshot().rewardPerShare;

            uint256 nextRPS = prevRPS.add(rewardPerShareValue.mul(1e18).div(gettotalSupplyShare()));

            BoardSnapshotShare memory newSSnapshot = BoardSnapshotShare({
                time: block.number,
                rewardReceived: amount,
                rewardPerShare: nextRPS
            });
            boardShareHistory.push(newSSnapshot);
        }

        if (rewardPerControlValue > 0 ) {
            uint256 prevRPC = getLatestControlSnapshot().rewardPerControl;

            uint256 nextRPC = prevRPC.add(rewardPerControlValue.mul(1e18).div(gettotalSupplyControl()));

            BoardSnapshotControl memory newCSnapshot = BoardSnapshotControl({
                time: block.number,
                rewardReceived: amount,
                rewardPerControl: nextRPC
            });
            boardControlHistory.push(newCSnapshot);
        }

        IERC20(control).safeTransferFrom(msg.sender, address(this), amount);
        emit RewardAdded(msg.sender, amount);
    }

    function updateOracle(address newOracle) public onlyOwner {
        theOracle = newOracle;
    }

    function setIdeaFund(address newFund) public onlyOwner {
        ideaFund = newFund;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event WithdrawControl(address indexed user, uint256 amount); 
    event WithdrawnWithReductionShare(address indexed user, uint256 actualAmount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IOracle {
    function priceOf(address token) external view returns (uint256 priceOfToken);
    function wbtcPriceOne() external view returns (uint256 priceOfwBTC);
    function pairFor(address _factor, address _token1, address _token2) external view returns (address pairaddy);
}

pragma solidity >=0.6.0;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            'ContractGuard: one block, one function'
        );
        require(
            !checkSameSenderReentranted(),
            'ContractGuard: one block, one function'
        );

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            'operator: caller is not the operator'
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            'operator: zero address given for new operator'
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

abstract contract ShareWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public share; //LIFT
    address public control; //CTRL

    uint256 private _totalSupplyShare;
    uint256 private _totalSupplyControl;

    mapping(address => uint256) private _shareBalances;
    mapping(address => uint256) private _controlBalances;

    function gettotalSupplyShare() public view returns (uint256) {
        return _totalSupplyShare;
    }

    function gettotalSupplyControl() public view returns (uint256) {
        return _totalSupplyControl;
    }

    function getbalanceOfShare(address account) public view returns (uint256) {
        return _shareBalances[account];
    }

    function getbalanceOfControl(address account) public view returns (uint256) {
        return _controlBalances[account];
    }

    function settotalSupplyShare(uint256 amount) internal {
        _totalSupplyShare = amount;
    }

    function setbalanceOfShare(address account, uint256 amount) internal {
        _shareBalances[account] = amount;
    }

    function stakeShare(uint256 amount) public virtual {        
        stakeShareForThirdParty(msg.sender, msg.sender, amount);
    }
 
    function stakeShareForThirdParty(address staker, address from, uint256 amount) public virtual {
        _totalSupplyShare = _totalSupplyShare.add(amount);
        _shareBalances[staker] = _shareBalances[staker].add(amount);
        IERC20(share).safeTransferFrom(from, address(this), amount);
    }

    function stakeControl(uint256 amount) public virtual {
        stakeControlForThirdParty(msg.sender, msg.sender, amount);
    }    

    function stakeControlForThirdParty(address staker, address from, uint256 amount) public virtual {
        _totalSupplyControl = _totalSupplyControl.add(amount);
        _controlBalances[staker] = _controlBalances[staker].add(amount);
        IERC20(control).safeTransferFrom(from, address(this), amount);
    }

    function withdrawControl(uint256 amount) public virtual {
        uint256 stakerBalance = _controlBalances[msg.sender];
        require(
            stakerBalance >= amount,
            'Boardroom: withdraw request greater than staked amount'
        );
        _totalSupplyControl = _totalSupplyControl.sub(amount);
        _controlBalances[msg.sender] = stakerBalance.sub(amount);
        IERC20(control).safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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