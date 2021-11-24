/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint(address account, uint amount) external;
}

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


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// MasterChef is the master of Good. He can make Good and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Good is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

interface AwardCommunityPool{
  function setCommunity(address _addr) external;  
  function isCommunity(address _addr) external returns(bool);
}

interface DividendTracker {
	function setBalance(address account, uint256 newBalance) external;
	function process(uint256 gas) external returns (uint256, uint256, uint256);
	function distributeDividends_cake(uint256 _amount) external;
}

contract AwardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    // Info of each userInfo.
    struct UserInfo {
        uint256 amount; 
        uint256 rewardDebt; 
        uint256 trueReward;
        address leader;
        uint256 brokerage;
        uint256 inviteNum;
    }
    mapping(address => UserInfo) public userInfo;
    // Info of each poolInfo.
    struct PoolInfo {
        IERC20 pledgeToken; 
        uint256 pledgeTotal;
        uint256 lastRewardBlock; 
        uint256 accPerShare; 
        address burnAddress;
        address dividendWallet;
        address recommendWallet;
        address communityWallet;
        address ecoWallet;
        uint256 burnRate;
        uint256 dividendRate;
        uint256 recommendRate;
        uint256 communityRate;
        uint256 ecoRate;
    }

    IERC20 public award = IERC20(0xcA53AeE899688aE56DA92A649b0c9af10056EaE8);
    uint256 public awardPerBlock = 3472 * 10 ** 14;
    PoolInfo public poolInfo;
    uint256 public startBlock;
    uint256 public endBlock;
    address public owner;

    bool public paused = false;
    
    uint256 public maxPledge = 10000 * 10 ** 18;
    uint256 public minPledge = 50 * 10 ** 18;
    
    uint256 public maxProfitRate = 2;
    uint256 public gasForProcessing = 30000;
    uint256 public communityNum = 1;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user,  uint256 amount);
    event SetPause( bool paused);
    event ErrorInProcess(address msgSender);
	event ProcessedDividendTracker(
		uint256 iterations,
		uint256 claims,
		uint256 lastProcessedIndex,
		bool indexed automatic,
		uint256 gas,
		address indexed processor
	);

    constructor() public {
        owner = msg.sender;
    }

    function add(address _pledgeToken, 
                uint256 _burnRate, address _burnAddress,
                uint256 _dividendRate, address _dividendWallet,
                uint256 _recommendRate, address _recommendWallet,
                uint256 _communityRate, address _communityWallet,
                uint256 _ecoRate, address _ecoWallet) external onlyOwner {
        poolInfo.lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.pledgeToken = IERC20(_pledgeToken);
        poolInfo.burnRate = _burnRate;
        poolInfo.burnAddress = _burnAddress;
        poolInfo.dividendRate = _dividendRate;
        poolInfo.dividendWallet = _dividendWallet;
        poolInfo.recommendRate = _recommendRate;
        poolInfo.recommendWallet = _recommendWallet;
        poolInfo.communityRate = _communityRate;
        poolInfo.communityWallet = _communityWallet;
        poolInfo.ecoRate = _ecoRate;
        poolInfo.ecoWallet = _ecoWallet;
    }

    function setMaxAndMin(uint256 _max, uint256 _min) external onlyOwner{
        maxPledge = _max;
        minPledge = _min;
    }
    
    function setStartAndEnd(uint256 _startBlock, uint256 _endBlock) external onlyOwner{
        startBlock = _startBlock;
        endBlock = _endBlock;
    }
    
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256){
        return _to.sub(_from);
    }


    function pendingAward(address _user) external view returns(uint256){
        
        uint256 curBlock = endBlock < block.number ? endBlock : block.number;
        uint256 accPerShare = poolInfo.accPerShare;
        
        if (curBlock > poolInfo.lastRewardBlock && poolInfo.pledgeTotal != 0) {
            uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, curBlock);
            uint256 Reward = multiplier.mul(awardPerBlock);
            accPerShare = accPerShare.add(
                Reward.mul(1e12).div(poolInfo.pledgeTotal)
                );
        }
        
        if(userInfo[_user].trueReward.add(
            userInfo[_user].amount.mul(accPerShare).div(1e12).sub(userInfo[_user].rewardDebt)
            ) >= userInfo[_user].amount.mul(maxProfitRate)){
            return userInfo[_user].amount.mul(maxProfitRate).sub(userInfo[_user].trueReward);
        }
        return userInfo[_user].amount.mul(accPerShare).div(1e12).sub(userInfo[_user].rewardDebt);
    }

    function updatePool() public {
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }
      
        if (poolInfo.pledgeTotal == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(poolInfo.lastRewardBlock, block.number);
        uint256 awardReward = multiplier.mul(awardPerBlock);

        poolInfo.accPerShare = poolInfo.accPerShare.add(awardReward.mul(1e12).div(poolInfo.pledgeTotal));
        poolInfo.lastRewardBlock = block.number;
    }

    function pledge(uint256 _amount, address _leader) public notPause {

        require(_amount >= minPledge,"Too few");
        require(_amount <= maxPledge,"Too many");
        require(userInfo[msg.sender].amount == 0,"Not over yet");
        
        updatePool();
        poolInfo.pledgeToken.transferFrom(msg.sender,poolInfo.burnAddress,getAmount(_amount,poolInfo.burnRate));
        poolInfo.pledgeToken.transferFrom(msg.sender,poolInfo.dividendWallet,getAmount(_amount,poolInfo.dividendRate));
        poolInfo.pledgeToken.transferFrom(msg.sender,poolInfo.communityWallet,getAmount(_amount,poolInfo.communityRate));
        poolInfo.pledgeToken.transferFrom(msg.sender,poolInfo.ecoWallet,getAmount(_amount,poolInfo.ecoRate));
        
        handling(_amount,msg.sender,_leader);
        userInfo[msg.sender].amount = _amount;
        poolInfo.pledgeTotal = poolInfo.pledgeTotal.add(_amount);
        
        userInfo[msg.sender].rewardDebt = userInfo[msg.sender].amount.mul(poolInfo.accPerShare).div(1e12);
       
        try DividendTracker(poolInfo.dividendWallet).setBalance(msg.sender,_amount) {} catch {}
        try DividendTracker(poolInfo.dividendWallet).distributeDividends_cake(getAmount(_amount,poolInfo.dividendRate)){} catch {}
        try DividendTracker(poolInfo.dividendWallet).process(gasForProcessing) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
				emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gasForProcessing, tx.origin);
		}catch{
				emit ErrorInProcess(msg.sender);
		}
        
        emit Deposit(msg.sender, _amount);
    }
    
    function handling(uint256 _amount, address _from, address _leader)internal{
        if(userInfo[_from].leader == address(0) && _leader != address(0) &&_leader != _from){
            userInfo[_from].leader = _leader;
            userInfo[_leader].inviteNum = userInfo[_leader].inviteNum.add(1);
            if(userInfo[_leader].inviteNum >= communityNum){
                bool Community = AwardCommunityPool(poolInfo.communityWallet).isCommunity(_leader);
                if(Community == false){
                    try AwardCommunityPool(poolInfo.communityWallet).setCommunity(_leader) {} catch {}
                }
            }
        }
        if(userInfo[_from].leader !=address(0)){
            poolInfo.pledgeToken.transferFrom(msg.sender,userInfo[_from].leader,getAmount(_amount,poolInfo.recommendRate));
        }else{
            poolInfo.pledgeToken.transferFrom(msg.sender,poolInfo.recommendWallet,getAmount(_amount,poolInfo.recommendRate));
        }
    }
    
    function getAmount(uint256 _amount, uint256 _rate) internal pure returns(uint256){
        return _amount.mul(_rate).div(1000);
    }


    function withdraw() public  notPause {
        updatePool();
        uint256 pending = userInfo[msg.sender].amount.mul(poolInfo.accPerShare).div(1e12).sub(userInfo[msg.sender].rewardDebt);
        
        if(userInfo[msg.sender].trueReward.add(pending) >= userInfo[msg.sender].amount.mul(maxProfitRate)){
            pending = userInfo[msg.sender].amount.mul(maxProfitRate).sub(userInfo[msg.sender].trueReward);
            poolInfo.pledgeTotal = poolInfo.pledgeTotal.sub(userInfo[msg.sender].amount);
            userInfo[msg.sender].amount = 0;
            userInfo[msg.sender].trueReward = 0;
            try DividendTracker(poolInfo.dividendWallet).setBalance(msg.sender,0) {} catch {}
           
        }else{
            userInfo[msg.sender].trueReward = userInfo[msg.sender].trueReward.add(pending);
        }
        
        userInfo[msg.sender].rewardDebt = userInfo[msg.sender].amount.mul(poolInfo.accPerShare).div(1e12);
        safeTransferAward(msg.sender, pending);
        
        try DividendTracker(poolInfo.dividendWallet).process(gasForProcessing) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
				emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gasForProcessing, tx.origin);
		}catch{
				emit ErrorInProcess(msg.sender);
		}

    }


   
    function safeTransferAward(address _to, uint256 _amount) internal {
        uint256 awardBal = award.balanceOf(address(this));
        if (_amount > awardBal) {
            award.transfer(_to, awardBal);
        } else {
            award.transfer(_to, _amount);
        }
    }

    function setAwardPerBlock(uint256 _awardPerBlock) public onlyOwner  {
       awardPerBlock = _awardPerBlock;
    }
    
    function setCommunityNum(uint256 _communityNum) public onlyOwner{
        communityNum = _communityNum ;
    }
    
    function setMaxProfitRate(uint256 _maxProfitRate)public onlyOwner{
        maxProfitRate = _maxProfitRate;
    }
    
    function setPause() public onlyOwner {
        paused = !paused;
        emit SetPause(paused);

    }
    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }
    function withdrawStuckTokens(address _token, uint256 _amount) public onlyOwner {
		IERC20(_token).transfer(msg.sender, _amount);
	}
	
	function PayTransfer(address payable recipient) public onlyOwner {
		recipient.transfer(address(this).balance);
	}

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
}