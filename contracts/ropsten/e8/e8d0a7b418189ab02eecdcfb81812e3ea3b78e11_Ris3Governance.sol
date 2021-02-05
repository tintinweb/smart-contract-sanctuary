/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

pragma solidity ^0.5.0;
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount);

    function mintByGovernance(uint256 amount) external;
    
    function burn(uint256 amount) external;
    
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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

//Factory contract interface
interface ris3Factory {
    function governmentBurnTokens() external;
}

//Farm contract interface
interface ris3Farm {
    function governmentBurnTokens() external;
}

//Tax pool contract interface
interface taxPool {
    function governmentCollectTaxes() external;
    function getTaxSentToGovernment() view external returns (uint256 _sentToGovernment);
}

pragma solidity ^0.5.0;

contract Ris3Governance is Ownable {
    using SafeMath for uint256;
    
    address public ris3Address = 0x319CA636F56Ec1052f38f2B3A4DB4B7e135103Cd;
    IERC20 public ris3 = IERC20(ris3Address);
    
    // 6 days are spent producing votes and minting tokens
    // On the 7th day, production stop and vote creation stops
    uint256 public govTenure = 1 hours;
    uint256 public stakingDuration = 20 minutes;
    uint256 public electionDuration = 30 minutes;
    uint256 public ruleDisplayDuration = 30 minutes;
    
    bool public stopElection;
    uint256 public currentGovType;
    uint256 private currentVoteCounts;
    
    uint256 public cycleStartTime = now;
    uint256 public govElectionStartTime = cycleStartTime + govTenure;
    uint256 public lastRewardMintingTime;
    uint256 public totalStaked;
    address public dictatorAddress;
    address public farmAddress;
    ris3Farm public farm = ris3Farm(farmAddress);
    address public factoryAddress;
    ris3Factory public factory = ris3Factory(factoryAddress);
    address public taxPoolAddress;
    taxPool public taxes = taxPool(taxPoolAddress);
    
    struct ris3Items {
        uint256 lastStakingTime;
        uint256 totalAmount;
    }
    mapping(address => ris3Items) public userBalance;
    
    struct ris3Rewards {
        uint256 totalWithdrawn;
        uint256 lastWithdrawTime;
    }
    mapping(address => ris3Rewards) public userRewardInfo;
    
    //options given
    mapping(uint256 => string) public governmentOptions;
    mapping(uint256 => uint256) public taxRatesOptions;
    mapping(uint256 => uint256) public prodRatesOptions;
    mapping(uint256 => string) public taxPoolUsesOptions;
    
    //laws
    uint256 public currentTaxRatesType;
    uint256 public currentProdRatesType;
    uint256 public currentTaxPoolUsesType;
    
    //votes collection
    mapping(uint256 => uint256) public votesByTaxRateType;
    mapping(uint256 => uint256) public votesByProdRatesType;
    mapping(uint256 => uint256) public votesByTaxPoolUsesType;
    mapping(uint256 => uint256) public votesByGovType;
    
    address[] private addressArray;
    mapping(address => uint256) public votesByAddress;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Burned(uint256 amount);
    
    constructor () public {
        //set goverment  types options
        governmentOptions[1] = "Socialism";
        governmentOptions[2] = "Democracy";
        governmentOptions[3] = "Dictatorship";
        
        //set tax rates options
        taxRatesOptions[1] = 10;
        taxRatesOptions[2] = 30;
        taxRatesOptions[3] = 50;
        
        //set production rates options
        prodRatesOptions[1] = 100000 * 1 ether; //multiply 1 ether to add deciaml places
        prodRatesOptions[2] = 300000 * 1 ether; //multiply 1 ether to add deciaml places
        prodRatesOptions[3] = 500000 * 1 ether; //multiply 1 ether to add deciaml places
        
        //set tax pools uses options
        taxPoolUsesOptions[1] = "Distribute all";
        taxPoolUsesOptions[2] = "Half distribute";
        taxPoolUsesOptions[3] = "Burn all";
        
        //set default for first cycle
        currentGovType = 2;
        currentTaxRatesType = 2;
        currentProdRatesType = 2;
        currentTaxPoolUsesType = 2;
        
    }
    
    function stake(uint256 amount) public {
        require(amount > 0, "Cannot stake 0");
        require(now > cycleStartTime && now < cycleStartTime + stakingDuration, "Staking can be done only on first day"); //staking only on first day
        
        (uint256 _amount, uint256 fee) = ris3.calculateAmountsAfterFee(msg.sender, address(this), amount);
        
        //add value in ris3 token balance for user
        userBalance[msg.sender].totalAmount = getUserBalance(msg.sender).add(amount);
        userBalance[msg.sender].lastStakingTime = now;
        
        //add to total staked
        totalStaked = totalStaked.add(_amount);
        
        ris3.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, _amount);
    }

    //get user balance
    function getUserBalance(address userAddress) view public returns (uint256 _amount)
    {
        if (userBalance[userAddress].lastStakingTime < cycleStartTime) {
            return 0;
        } else {
            return userBalance[userAddress].totalAmount;
        }
    }
    
    //get total rewards collected by user
    function getTotalRewardCollectedByUser(address userAddress) view public returns (uint256 _totalRewardCollected) 
    {
        if (userRewardInfo[userAddress].lastWithdrawTime < cycleStartTime) {
            return 0;
        } else {
            userRewardInfo[userAddress].totalWithdrawn;
        }
    }
    
    function calculateRewardTesting(address userAddress) public view returns (uint256 _percnt, uint256 _diff, uint256 _userRewardPerMinute) {
        
        //uint256 amount = 0;
        uint256 ris3Amount = getUserBalance(userAddress);
        uint256 percnt = ris3Amount.mul(100);
                percnt = percnt.div(totalStaked);
        
        uint256 diff = 0;
        uint256 totalRewards = getTotalRewards();
        
        //if not withdrawn on current cycle yet
        if (userRewardInfo[userAddress].lastWithdrawTime < cycleStartTime) {
           if (now < govElectionStartTime) {
               diff = now - getWithdrawingStartTime();
           } else {
               diff = govElectionStartTime - getWithdrawingStartTime();
           }
           
        } else {
           if (now < govElectionStartTime) {
              diff = now - userRewardInfo[userAddress].lastWithdrawTime;
           } else {
              diff = govElectionStartTime - userRewardInfo[userAddress].lastWithdrawTime;
           }
        }
        diff = diff / 60 / 60; //count for every 1 second
        uint256 rewardsEveryMinutes = totalRewards / 5 / 24 / 60; //get rewards every minutes
        uint256 userRewardPerMinute = rewardsEveryMinutes.mul(percnt);
                userRewardPerMinute = userRewardPerMinute.div(100);
                
        return ( percnt, diff, userRewardPerMinute);
    }
    
    //calculate your rewards
    function calculateReward(address userAddress) public view returns (uint256 _reward) {
        uint256 amount = 0;
        uint256 ris3Amount = getUserBalance(userAddress);
        uint256 percnt = ris3Amount.mul(100);
                percnt = percnt.div(totalStaked);
        
        uint256 diff = 0;
        uint256 totalRewards = getTotalRewards();
        
        //rewards can be calculated after staking done only
        if (now < getWithdrawingStartTime()){
            return amount;
        } else {
            //if not withdrawn on current cycle yet
            if (userRewardInfo[userAddress].lastWithdrawTime < cycleStartTime) {
               if (now < govElectionStartTime) {
                   diff = now - getWithdrawingStartTime();
               } else {
                   diff = govElectionStartTime - getWithdrawingStartTime();
               }
               
            } else {
               if (now < govElectionStartTime) {
                  diff = now - userRewardInfo[userAddress].lastWithdrawTime;
               } else {
                  diff = govElectionStartTime - userRewardInfo[userAddress].lastWithdrawTime;
               }
            }
            diff = diff / 60 / 60; //count for every 1 second
            
            uint256 rewardsEveryMinutes = totalRewards / 5 / 24 / 60 / 60; //get rewards every second
            uint256 userRewardPerMinute = rewardsEveryMinutes.mul(percnt);
                    userRewardPerMinute = userRewardPerMinute.div(100);
                    userRewardPerMinute = userRewardPerMinute * 1 ether;
            
            amount = userRewardPerMinute.mul(diff);
            return amount;
        }
    }
    
    //withdraw your reward
    function withdrawRewards() public {
        uint256 amount = calculateReward(msg.sender);
        require(amount > 0, "No rewards for this address");
        require(now > getWithdrawingStartTime(), "Can withdraw after staking time");
        
        if (userRewardInfo[msg.sender].lastWithdrawTime < cycleStartTime) {
            userRewardInfo[msg.sender].totalWithdrawn = amount;
        } else {
            userRewardInfo[msg.sender].totalWithdrawn = userRewardInfo[msg.sender].totalWithdrawn.add(amount);
        }
        
        userRewardInfo[msg.sender].lastWithdrawTime = now;
        
        ris3.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    /*get number of votes of an address*/
    function getNumOfVotesByAddress(address _withdrawalAddress) public view returns (uint256 _amount) {
        return getUserBalance(_withdrawalAddress);
    }
    
    //withdraw tokens
    function withdrawStaking(uint256 amount) public {
        require(amount == 0, "Amount can not be zero");
        require(now > cycleStartTime && now < cycleStartTime + stakingDuration, "Can withdraw only on first day"); //Can withdraw only on first day
        require(amount <= (getUserBalance(msg.sender)), "You do not have enough balance");
        
        userBalance[msg.sender].totalAmount = getUserBalance(msg.sender).sub(amount);
        
        ris3.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    function startElection() public {
        require(now > govElectionStartTime, "Election time have not started");
        stopElection = false;
    }
    
    function electGovernment(uint256 govType, uint256 taxRates, uint256 prodRates, uint256 taxPoolUses, address _dictatorAddress) public {
        require(!stopElection, "Election done");
        require(now >= govElectionStartTime && now <= govElectionStartTime + electionDuration, "Election time passed");
        uint256 yourVotes = getNumOfVotesByAddress(msg.sender);
        require(yourVotes > 0, "You do not have any vote");
        
        // 1 is for Socialism, 2 is for Democracy and 3 is for Dictatorship
        require(govType == 1 || govType == 2 || govType == 3, "Wrong government type");
        votesByGovType[govType] += yourVotes;
        
        if (govType == 2) {
            require(taxRates == 1 || taxRates == 2 || taxRates == 3, "Wrong tax rate option");
            require(prodRates == 1 || prodRates == 2 || prodRates == 3, "Wrong production rates option");
            require(taxPoolUses == 1 || taxPoolUses == 2 || taxPoolUses == 3, "Wrong taxPoolUses option"); 
            
            votesByTaxRateType[taxRates] += yourVotes;
            votesByProdRatesType[prodRates] += yourVotes;
            votesByTaxPoolUsesType[taxPoolUses] += yourVotes;
        }
        
        if (govType == 3) {
            votesByAddress[_dictatorAddress] += yourVotes;
            addressArray.push(_dictatorAddress);
        }
        
        currentVoteCounts += yourVotes;
    }
    
    function finishElection() public {
        require(now > govElectionStartTime + electionDuration, "Election is happening");
        require(!stopElection, "Election finished");
        stopElection = true;
        uint256 maxVotes;
        for (uint256 i = 1; i <= 3; i++) {
            if (votesByGovType[i] > maxVotes) {
                maxVotes = votesByGovType[i];
                currentGovType = i;
            }
        }
        
        //set laws for Socialism
        if (currentGovType == 1) {
            currentTaxRatesType = 3;
            currentProdRatesType = 3;
            currentTaxPoolUsesType = 1;
        }
        
        //set laws for Democracy
        uint256 maxTaxRateVotes; uint256 maxProdVotes; uint256 maxTaxPoolVotes;
        if (currentGovType == 2) {
            for (uint256 i = 1; i <= 3; i++) {
                if (votesByTaxRateType[i] > maxTaxRateVotes) {
                    maxTaxRateVotes = votesByTaxRateType[i];
                    currentTaxRatesType = i;
                }
                
                if (votesByProdRatesType[i] > maxProdVotes) {
                    maxProdVotes = votesByProdRatesType[i];
                    currentProdRatesType = i;
                }
                
                if (votesByTaxPoolUsesType[i] > maxTaxPoolVotes) {
                    maxTaxPoolVotes = votesByTaxPoolUsesType[i];
                    currentTaxPoolUsesType = i;
                }
            }
        }
        
        //set default laws in case of dictator. dictator can change laws within 12 hours
        if (currentGovType == 3) {
            uint256 maxVoteFor;
            for (uint256 i = 0; i < addressArray.length; i++) { 
                if (votesByAddress[addressArray[i]] > maxVoteFor) {
                    maxVoteFor = votesByAddress[addressArray[i]];
                    dictatorAddress = addressArray[i];
                }
            }
            
             //default rules
            currentTaxRatesType = 3;
            currentProdRatesType = 3;
            currentTaxPoolUsesType = 1;
        }
        
    }
    
    function dictatorSetLaws(uint256 taxRates, uint256 prodRates, uint256 taxPoolUses) public {
        require(dictatorAddress == msg.sender, "Only dictator");
        require(currentGovType == 3, "Wrong government type");
        require(taxRates == 1 || taxRates == 2 || taxRates == 3, "Wrong tax rate option");
        require(prodRates == 1 || prodRates == 2 || prodRates == 3, "Wrong production rates option");
        require(taxPoolUses == 1 || taxPoolUses == 2 || taxPoolUses == 3, "Wrong taxPoolUses option"); 
        
        currentTaxRatesType = taxRates;
        currentProdRatesType = prodRates;
        currentTaxPoolUsesType = taxPoolUses;
    }
    
    function startNewCycle() public {
        require(now > govElectionStartTime + electionDuration + ruleDisplayDuration, "Election is happening");
        govElectionStartTime = now + govTenure;
        
        totalStaked = 0;
        cycleStartTime = now;
        
        uint256 totalRewards = getTotalRemainingRewards();
        ris3.burn(totalRewards); //burn rewards which are not collected
        emit Burned(totalRewards);
        
        //Burn remaining tokens on farm and factory
        if (farmAddress != 0x0000000000000000000000000000000000000000) {
            farm.governmentBurnTokens();
        }
        
        if (factoryAddress != 0x0000000000000000000000000000000000000000) {
            factory.governmentBurnTokens();
        }
        
        //collect taxes for next cycle from tax pool
        taxes.governmentCollectTaxes();
    }

    //mint reward for farm and factory
    function mintRewards() public { 
        require(now > cycleStartTime && now < cycleStartTime + stakingDuration, "Rewards can be mined on first day only");
        require(lastRewardMintingTime < cycleStartTime, "Rewards already mined");
        
        lastRewardMintingTime = now;
        
        //mine new tokens for farm and factory
        uint256 prodAmount = prodRatesOptions[currentProdRatesType];
        
        //transfer the amount to farm and factory
        if (farmAddress != 0x0000000000000000000000000000000000000000) {
            ris3.mintByGovernance(prodAmount);
            ris3.transfer(farmAddress, prodRatesOptions[currentProdRatesType]);
        }
        
        if (factoryAddress != 0x0000000000000000000000000000000000000000) {
            ris3.mintByGovernance(prodAmount);
            ris3.transfer(factoryAddress, prodRatesOptions[currentProdRatesType]);
        }
    }
    
    function setGovTenure(uint256 _govTenure) public onlyOwner {
        govTenure = _govTenure;
    }
    
    function setStakingDuration(uint256 _stakingDuration) public onlyOwner {
        stakingDuration = _stakingDuration;
    }
    
    function setElectionDuration(uint256 _electionDuration) public onlyOwner {
        electionDuration = _electionDuration;
    }
    
    function setRuleDisplayDuration(uint256 _ruleDisplayDuration) public onlyOwner {
        ruleDisplayDuration = _ruleDisplayDuration;
    }
    
    function getCurrentGov() public view returns (string memory currentGoverment) {
        return governmentOptions[currentGovType];
    }
    
    function getCurrentLaws() public view returns (uint256 taxRates, uint256 prodRates, string memory taxPoolUses) {
        return (taxRatesOptions[currentTaxRatesType],prodRatesOptions[currentProdRatesType],taxPoolUsesOptions[currentTaxPoolUsesType]);
    }
    
    function getCurrentTaxPoolUsesType() public view returns (uint256 _currentTaxPoolUsesType) {
        return currentTaxPoolUsesType;
    }
    
    function getCycleStartTime() public view returns (uint256 _cycleStartTime) {
        return cycleStartTime;
    }
    
    function getWithdrawingStartTime() public view returns (uint256 _withdrawingStartTime) {
        return cycleStartTime + stakingDuration;
    }
    
    function getGovElectionStartTime() public view returns (uint256 _govElectionStartTime) {
        return govElectionStartTime;
    }
    
    function getTotalStaked() public view returns (uint256 _totalStaked) {
        return totalStaked;
    }
    
    function getTotalRewards() public view returns (uint256 _totalRewards) {
        return taxes.getTaxSentToGovernment();
    }
    
    function getTotalRemainingRewards() public view returns (uint256 _totalRemainingRewards) {
        return ris3.balanceOf(address(this)) - totalStaked;
    }
    
    //get ris3 toten address
    function getRis3Address() public view returns (address _ris3Address) {
        return ris3Address;
    }
    
    //get farm address
    function getFarmAddress() public view returns (address _farmAddress) {
        return farmAddress;
    }
    
    //get factory address
    function getFactoryAddress() public view returns (address _factoryAddress) {
        return factoryAddress;
    }
    
    //get tax pool address
    function getTaxPoolAddress() public view returns (address _taxPoolAddressAddress) {
        return taxPoolAddress;
    }
    
    //set ris3 toten address
    function setRis3Address(address _ris3Address) public onlyOwner {
        ris3Address = _ris3Address;
        ris3 = IERC20(ris3Address);
    }
    
    //set farm address
    function setFarmAddress(address _farmAddress) public onlyOwner {
        farmAddress = _farmAddress;
        farm = ris3Farm(farmAddress);
    }
    
    //set factory address
    function setFactoryAddress(address _factoryAddress) public onlyOwner {
        factoryAddress = _factoryAddress;
        factory = ris3Factory(factoryAddress);
    }
    
    //set tax pool address
    function setTaxPoolAddress(address _taxPoolAddress) public onlyOwner {
        taxPoolAddress = _taxPoolAddress;
        taxes = taxPool(taxPoolAddress);
    }
    
    function emergencyStartNewCycleForTesting() public onlyOwner {
        govElectionStartTime = now + govTenure;
        
        totalStaked = 0;
        cycleStartTime = now;
        
        uint256 totalRewards = getTotalRemainingRewards();
        ris3.burn(totalRewards); //burn rewards which are not collected
        emit Burned(totalRewards);
        
        //Burn remaining tokens on farm and factory
        if (farmAddress != 0x0000000000000000000000000000000000000000) {
            farm.governmentBurnTokens();
        }
        
        if (factoryAddress != 0x0000000000000000000000000000000000000000) {
            factory.governmentBurnTokens();
        }
        
        //collect taxes for next cycle from tax pool
        taxes.governmentCollectTaxes();
    }
    
}