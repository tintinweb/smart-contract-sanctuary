/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

/**
 *  SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.0;

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
        return msg.data;
    }
}


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

interface IThreeKingdomsToken{

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
   
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function amountForEth(uint256 ethAmount) external view returns(uint256 tokenAmount);
}

abstract contract IThreeKingdomsBattle{
    
    function genesisBreed(uint256 maxAmount) virtual public; 
    
    function breed(uint256 tokenIdA,uint256 tokenIdB) virtual public;
    
    function hatch(uint256 tokenId) virtual public;
    
    function statusChange(uint256 tokenId,uint8 status) virtual public;    
    
    function feedEnergy(uint256 tokenId,uint256 energy) virtual public; 
    
    function feedPoint(uint256 tokenId, uint256 position, uint256 point, uint256 expire) virtual public; 
    
    function equipt(uint256 tokenId, uint256 position, uint256 equipmentId) virtual public;
    
    function petInfo(uint256 tokenId) virtual public view returns(
        uint8 form,uint8 level,uint8 element,uint256 energyLimit,uint256 energyPoint,uint256 honorPoint,
        uint256 helthPoint,uint256 attackPoint,uint256 defensePoint,uint256 speedPoint,uint8 depositStatus
    );
    
    function petPotionInfo(uint256 tokenId) virtual public view returns(
        uint256 helthPointAdded,uint256 helthPointExpire,
        uint256 attackPointAdded,uint256 attackPointExpire,
        uint256 defensePointAdded,uint256 defensePointExpire,
        uint256 speedPointAdded,uint256 speedPointExpire
    );
    
    function petEquipmentInfo(uint256 tokenId) virtual public view returns(
        uint256 headEquipmentId,
        uint256 handLeftEquipmentId,
        uint256 handRightEquipmentId,
        uint256 bodyEquipmentId,
        uint256 footEquipmentId
    );
    
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    
}

//deposit token reward
abstract contract Depositable{
    function deposit(uint256 amount) virtual public;
}

contract teeBattle is Ownable,Depositable {
    using SafeMath for uint256;

    struct PetInfo {
        uint256 tokenId; 
        uint256 stakedBlock; //calc energyPoint per block stamp
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 lastRewardBlock;
        uint256 accREWPerShare;
        uint256 totalDeposit; //total deposit pet energyLimit
    }
    
    address public nftTokenAddress;
    address public tokenAddress;
    
    PoolInfo public poolInfo;
    
    mapping(address => mapping(uint256 => PetInfo)) public petInfo; // address => tokenId => petInfo

    // The block number when rew mining starts.
    uint256 public startBlock;
    // The block number when rew mining end;
    uint256 public endBlock;
    
    uint256 public rewDepositedTotal; //total deposited reward
    uint256 public rewPerBlock;  //reward in each block
    uint256 public rewIncreasePercent = 6000;  //max 10000, min 0, 10000 means endBlock not change, all increase rewardPerBlock, 0 means rewards not change,all increase endblock
    uint256 public rewPerBlockMax = 5*1e18;    //max rewPerBlock, if deposit too much, reward will remain in max value, ignore increase percent, all increase endblock
    
    uint256 public energyRecoverSpeed = 120; //1200 blocks (1 hour) 10 point

    event Stake(address indexed user, uint256 indexed tokenId);
    event UnStake(address indexed user, uint256 indexed tokenId);
    event Claim(address indexed user, uint256 indexed tokenId);
    event EmergencyWithdraw(address indexed user, uint256 indexed tokenId);

    constructor(
        address _tokenAddress,
        address _nftTokenAddress
    ) {
        tokenAddress = _tokenAddress;
        nftTokenAddress = _nftTokenAddress;
    }

    function setRewIncreasePercent(uint256 _percent) public onlyOwner{
        require(_percent<=10000,"invalid amount");
        rewIncreasePercent = _percent;
    }
    
    function setRewPerBlockMax(uint256 _max) public onlyOwner{
        rewPerBlockMax = _max;
    }
    
    function sweep() public onlyOwner{
        uint256 amount = IThreeKingdomsToken(tokenAddress).balanceOf(address(this));
        IThreeKingdomsToken(tokenAddress).transfer(msg.sender,amount);
    }
    
    function setEnergyRecoverSpeed(uint256 _point) public onlyOwner{
        energyRecoverSpeed = _point;
    }
    
    function initDeposit(uint256 _rewAmount) public onlyOwner{
        require(startBlock==0,"farm has started!");
        
        uint256 beforeAmount = IThreeKingdomsToken(tokenAddress).balanceOf(address(this));
        IThreeKingdomsToken(tokenAddress).transferFrom(msg.sender,address(this),_rewAmount);
        uint256 afterAmount = IThreeKingdomsToken(tokenAddress).balanceOf(address(this));
        
        uint256 balance = afterAmount.sub(beforeAmount);
        require(balance == _rewAmount, "Error balance");
        
        rewDepositedTotal = rewDepositedTotal.add(_rewAmount);
    }
    
    function start(uint256 _startBlock) public onlyOwner{
        require(startBlock==0,"farm has started!");
        if(_startBlock==0){
            startBlock = block.number;
        }
        else{
            startBlock = _startBlock;
        }
        rewPerBlock = 15*1e17; //init rew per block
        updatePool();
        
        uint256 cycle = rewDepositedTotal.div(rewPerBlock);
        endBlock = startBlock.add(cycle);
        updatePoolLastRewardBlock(block.number);
    }
    
    //deposit the profit
    function deposit(uint256 _rewAmount) public override {
        require(startBlock>0,"farm not start");
        updatePool();
        uint256 beforeAmount = IThreeKingdomsToken(tokenAddress).balanceOf(address(this));
        IThreeKingdomsToken(tokenAddress).transferFrom(msg.sender,address(this),_rewAmount);
        uint256 afterAmount = IThreeKingdomsToken(tokenAddress).balanceOf(address(this));
        
        uint256 balance = afterAmount.sub(beforeAmount);
        require(balance == _rewAmount, "Error balance");

        //calc rewardPerBlock
        rewPerBlock = calcRewPerBlock(rewPerBlock,_rewAmount,rewDepositedTotal,rewIncreasePercent);
        if(rewPerBlock>rewPerBlockMax){
            rewPerBlock = rewPerBlockMax;
        }
        
        rewDepositedTotal = rewDepositedTotal.add(_rewAmount);  //accumulate deposited reward
        uint256 cycle = rewDepositedTotal.div(rewPerBlock);
        endBlock = startBlock.add(cycle);
        updatePoolLastRewardBlock(block.number);
    }
    
    function calcRewPerBlock(uint256 _rewPerBlock,uint256 _rewAddAmount,uint256 _rewDepositedTotal,uint256 _rewIncreasePercent) public pure returns(uint256){
        uint256 increaseRate = _rewAddAmount.mul(1e12).div(_rewDepositedTotal).mul(_rewIncreasePercent).div(10000).add(1e12);
        _rewPerBlock = increaseRate.mul(_rewPerBlock).div(1e12);
        return _rewPerBlock;
    }
    
    function updatePoolLastRewardBlock(uint256 _lastRewardBlock) private {
        poolInfo.lastRewardBlock = _lastRewardBlock;
    }
    

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        uint256 number = block.number > endBlock ? endBlock : block.number;
        if (number <= poolInfo.lastRewardBlock) {
            return;
        }
        uint256 totalEnergy = poolInfo.totalDeposit;
        if (totalEnergy == 0) {
            poolInfo.lastRewardBlock = number;
            return;
        }
        uint256 multiplier = number.sub(poolInfo.lastRewardBlock);
        uint256 rewReward = multiplier.mul(rewPerBlock);
        poolInfo.accREWPerShare = poolInfo.accREWPerShare.add(rewReward.mul(1e12).div(totalEnergy));
        poolInfo.lastRewardBlock = number;
    }


    function pending(address _user, uint256 _tokenId) external view returns (uint256) {
        (,,,uint256 energyLimit,uint256 energyPoint,,,,,,uint8 depositStatus) = IThreeKingdomsBattle(nftTokenAddress).petInfo(_tokenId);
        require(depositStatus==1,"pet is not staked in farm");
        require(IThreeKingdomsBattle(nftTokenAddress).ownerOf(_tokenId)==_user,"owner invalid");
        
        PetInfo memory _petInfo = petInfo[_user][_tokenId];
        uint256 energyRecovered = block.number.sub(_petInfo.stakedBlock).div(energyRecoverSpeed);
        uint256 currentEnergy = energyPoint.add(energyRecovered);
        if(currentEnergy>energyLimit)
            currentEnergy = energyLimit;
        
        uint256 accREWPerShare = poolInfo.accREWPerShare;
        uint256 totalEnergy = poolInfo.totalDeposit;
        uint256 number = block.number > endBlock ? endBlock : block.number;
        if (number > poolInfo.lastRewardBlock && totalEnergy != 0) {
            uint256 multiplier = number.sub(poolInfo.lastRewardBlock);
            uint256 rewReward = multiplier.mul(rewPerBlock);
            accREWPerShare = accREWPerShare.add(rewReward.mul(1e12).div(totalEnergy));
        }
        return currentEnergy.mul(accREWPerShare.sub(_petInfo.rewardDebt)).div(1e12);
    }

    function claim(uint256 _tokenId) public{
        (,,,uint256 energyLimit,uint256 energyPoint,,,,,,uint8 depositStatus) = IThreeKingdomsBattle(nftTokenAddress).petInfo(_tokenId);
        require(depositStatus==1,"pet is not staked in farm");
        
        address petOwner = IThreeKingdomsBattle(nftTokenAddress).ownerOf(_tokenId);
        require(petOwner==msg.sender,"owner invalid");
        PetInfo storage _petInfo = petInfo[petOwner][_tokenId];
        updatePool();
        
        uint256 energyRecovered = block.number.sub(_petInfo.stakedBlock).div(energyRecoverSpeed);
        uint256 currentEnergy = energyPoint.add(energyRecovered);
        if(currentEnergy>energyLimit)
            currentEnergy = energyLimit;
        
        if (currentEnergy > 0) {
            uint256 pendingAmount = currentEnergy.mul(poolInfo.accREWPerShare.sub(_petInfo.rewardDebt)).div(1e12);
            if (pendingAmount > 0) {
                uint256 tokenBalance = IThreeKingdomsToken(tokenAddress).balanceOf(address(this));
                if(pendingAmount>tokenBalance)
                    pendingAmount = tokenBalance;
                IThreeKingdomsToken(tokenAddress).transfer(msg.sender,pendingAmount);
                _petInfo.rewardDebt = poolInfo.accREWPerShare;
                emit Claim(msg.sender,_tokenId);
            }
        }
    }

    
    function stake(uint256 _tokenId) public {
        (uint8 form,,,uint256 energyLimit,,,,,,,uint8 depositStatus) = IThreeKingdomsBattle(nftTokenAddress).petInfo(_tokenId);
        require(depositStatus==0,"pet is not free");
        require(form==1,"egg can not stake");
        
        address petOwner = IThreeKingdomsBattle(nftTokenAddress).ownerOf(_tokenId);
        require(petOwner==msg.sender,"owner invalid");
        updatePool();
        
        PetInfo storage _petInfo = petInfo[msg.sender][_tokenId];
        _petInfo.tokenId = _tokenId;
        _petInfo.stakedBlock = block.number;
        _petInfo.rewardDebt = poolInfo.accREWPerShare;
        
        IThreeKingdomsBattle(nftTokenAddress).statusChange(_tokenId,1); //change status
        poolInfo.totalDeposit = poolInfo.totalDeposit.add(energyLimit);
        
        emit Stake(msg.sender, _tokenId);
    }


    function unStake(uint256 _tokenId) public {
        (,,,uint256 energyLimit,uint256 energyPoint,,,,,,uint8 depositStatus) = IThreeKingdomsBattle(nftTokenAddress).petInfo(_tokenId);
        require(depositStatus==1,"pet is not staked in farm");
        
        address petOwner = IThreeKingdomsBattle(nftTokenAddress).ownerOf(_tokenId);
        require(petOwner==msg.sender,"owner invalid");
        PetInfo storage _petInfo = petInfo[petOwner][_tokenId];
        updatePool();
        
        uint256 energyRecovered = block.number.sub(_petInfo.stakedBlock).div(energyRecoverSpeed);
        uint256 currentEnergy = energyPoint.add(energyRecovered);
        if(currentEnergy>energyLimit)
            currentEnergy = energyLimit;
        
        if (currentEnergy > 0) {
            uint256 pendingAmount = currentEnergy.mul(poolInfo.accREWPerShare.sub(_petInfo.rewardDebt)).div(1e12);
            if (pendingAmount > 0) {
                uint256 tokenBalance = IThreeKingdomsToken(tokenAddress).balanceOf(address(this));
                if(pendingAmount>tokenBalance)
                    pendingAmount = tokenBalance;
                IThreeKingdomsToken(tokenAddress).transfer(msg.sender,pendingAmount);
                _petInfo.rewardDebt = poolInfo.accREWPerShare;
                emit Claim(msg.sender,_tokenId);
            }
        }
        
        IThreeKingdomsBattle(nftTokenAddress).statusChange(_tokenId,0); //change status
        IThreeKingdomsBattle(nftTokenAddress).feedEnergy(_tokenId,energyRecovered);  //update energy
        poolInfo.totalDeposit = poolInfo.totalDeposit.sub(energyLimit);
        
        emit UnStake(msg.sender, _tokenId);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _tokenId) public {
        (,,,uint256 energyLimit,,,,,,,uint8 depositStatus) = IThreeKingdomsBattle(nftTokenAddress).petInfo(_tokenId);
        require(depositStatus==1,"pet is not staked in farm");
        
        address petOwner = IThreeKingdomsBattle(nftTokenAddress).ownerOf(_tokenId);
        require(petOwner==msg.sender,"owner invalid");
        
        
        IThreeKingdomsBattle(nftTokenAddress).statusChange(_tokenId,0); //change status
        poolInfo.totalDeposit = poolInfo.totalDeposit.sub(energyLimit);
        
        emit EmergencyWithdraw(msg.sender, _tokenId);
    }
}