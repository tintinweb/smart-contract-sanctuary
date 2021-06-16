/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

/**
    WolfyStreetBets v1 - DeFi Pulse Index (DPI) v S&P500 Index (SPX) --- 7 day staking 
    _________________________________________________________________________________________

     Pool Duration 
        Mainnet  : 7 days

     Staking period
       Mainnet : 12 hours
     ___________________________________________________________________________________________
     
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier validAddress(address addr) {


    require(addr != address(0), "Address cannot be 0x0");
    require(addr != address(this), "Address cannot be contract address");
    _;
    }
    constructor() public{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner validAddress(newOwner) {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    
     function decimals() external view returns (uint256);
     
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional

            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// true = lowRisk
// false = highRisk
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// BICONOMY TRUSTED FORWARDER RELAYER META TRANSACTIONS
/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */


contract WolfyStreetBetsv1 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    uint256 public poolStartTime = 0;
    uint256 public liquidityCycleStartTime = 0;

    /**
     * biconomy trusted forwarders
     *
     * mumbai testnet: 0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b
     * goerli testnet: 0xE041608922d06a4F26C0d4c27d8bCD01daf1f792
     * rinkeby testnet: 0xFD4973FeB2031D4409fB57afEE5dF2051b171104
     * matic mainnet: 0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8
     * binance smart chain mainnet: 0x86C80a8aa58e0A4fa09A69624c31Ab2a6CAD56b8
     *
    */ 

    constructor(//address _trustedForwarder, 
    address _asset) public {
        // trustedForwarder = _trustedForwarder;
        ASSET = IERC20(_asset);
    }

    uint256 public predictionAsset1; 
    uint256 public predictionAsset2;

    uint256 public netPredictionAsset1;
    uint256 public netPredictionAsset2;

    bool  A;
    bool  B;

    bool public poolStarted;
    bool public liquidityCycle = true;
   
    uint256 winnerScale;
    bool who;

    uint8 public locationCheck;

    address[] _lowRiskUsers;
    address[] _highRiskUsers;

    uint256 public depositLowRisk;
    uint256 public depositHighRisk;
   
    uint256 public highRiskMultiplier;
    uint256 public lowRiskMultiplier; 
    
    bool checker ;
  
    IERC20 public ASSET;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(bool => uint256)) private _poolBalances;
    mapping(address =>  mapping(bool => uint256)) public _losingStakers;
    mapping(address =>  mapping(bool => uint256)) public _profitStakers;
   
    // address + isLowRisk + count ==> bool
    mapping(address => mapping(bool => mapping(uint256 => bool))) public previousResults;
    
    uint256 public runCount;
    
    /*update trusted forwarder should upgrades from biconomy occur
    function setTrustedForwarder(address _trustedForwarder) public view onlyOwner {
        require (_trustedForwarder != address(0), "Address cannot be 0x0");
        require (_trustedForwarder != address(this), "Address cannot be contract address");
    }*/

    /* override Context _msgSender() to use BaseRelayRecipient _msgSender() thereby enabling meta transactions
    function _msgSender() internal override(Context, BaseRelayRecipient) view returns (address payable) {
       return BaseRelayRecipient._msgSender();
    }*/
    
    /** 
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract. 
     
    function versionRecipient() external view override returns (string memory) {
        return "1";
    }*/
    
    //----| Set 15 for 1.5x |----| 10 for 1x |---| 23 for 2.3x |--
    function setLowRiskMultiplier(uint256 _lowRiskMultiplier) public onlyOwner {
        require(poolStarted == false, "Pool has already been started!");
        lowRiskMultiplier =  _lowRiskMultiplier;
    }

    //----| Set 50 for 5x |----| 100 for 10x |---| 120 for 12x |--
    function setHighRiskMultiplier(uint256 _highRiskMultiplier) public onlyOwner {
        require(poolStarted == false, "Pool has already been started!");
        highRiskMultiplier = _highRiskMultiplier;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account]; 
    }

    //====== | Get total profits/loss [Asset] pool wise |====| Profit{true} and Loss{false} |
    function getProfitLossAsset(bool _isLowRisk, bool _isProfit) public view returns (uint256) {
        
        if(_isProfit) {
            return _profitStakers[_msgSender()][_isLowRisk]; 
        }
            return _losingStakers[_msgSender()][_isLowRisk]; 
    }

    function checkAssetBalance(address account, bool _isLowRisk) public view returns (uint256) {
        return _poolBalances[account][_isLowRisk];   
    }

    function storeUsers(address receiver, address[] storage arrayData) internal {

     for(uint i = 0; i < arrayData.length; i++){
        if(arrayData[i] == receiver) {
           checker = true;
        } else {
          checker = false;
        }

      }
        if(checker == false){
          arrayData.push(receiver) ;
        }
    }

    function startPool(uint256 _predictionAsset1, uint256 _predictionAsset2) public onlyOwner {            
        require(!poolStarted, "Previous pool not finalized yet");
        require(totalLiquidityLowRisk + liquidityDetailsOwner._lowRisk > 0 ," Low Risk Pool: Please add liquidity");
        require(totalLiquidityHighRisk + liquidityDetailsOwner._highRisk > 0 ," High Risk Pool: Please add liquidity");
        require(block.timestamp > liquidityCycleStartTime.add(5 minutes), "Liquidity evolution cycle not finalized yet");

        predictionAsset1 = _predictionAsset1;
        predictionAsset2 = _predictionAsset2;
       
        poolStartTime = block.timestamp;
        poolStarted = true;

        liquidityCycle = false;
    }

    // Value of `predictionAsset1` and `predictionAsset2` after 7 days
   
    function stopPool(uint256 _predictionAsset1, uint256 _predictionAsset2) public onlyOwner { 
        // FOR MAINNET PLEASE UNCOMMENT ME .
        // require(block.timestamp > poolStartTime.add(7 days), "Can stop after 7 days"); ### 7 days #### Mainnet        
        require(poolStarted, "Pool has not been started!");
    
        (netPredictionAsset1, A) = raisePercent(predictionAsset1,_predictionAsset1);            //___either positive or negative
        (netPredictionAsset2, B)  = raisePercent(predictionAsset2,_predictionAsset2);           //___either positive or negative

        distributeLiquidityRewards(true);
        distributeLiquidityRewards(false);
        
        checkPerformance(netPredictionAsset1, netPredictionAsset2, A, B);
       
        rewardManager(winnerScale, who);
        poolStarted = false;
        liquidityCycle = true;
        liquidityCycleStartTime = block.timestamp;
    }

    function stake(uint256 _amount, bool _isLowRisk) public {        
        require(_amount > 0 , "You can't stake with 0. Choose an amount!");
        require(poolStarted, "Cannot stake until pool has been started!");
        // FOR MAINNET PLEASE UNCOMMENT ME
        // require(block.timestamp <= poolStartTime.add(12 hours),"12 hour staking window has now passed!" ); // Can stake upto 12 hours from start pool.

        uint256 stakeAmount;
      if (liquidityReward >= 1) {
          stakeAmount = _amount - ((_amount.mul(liquidityReward)).div(100)).div(10);
      }
      else {
          stakeAmount = _amount;
      }
      if(_isLowRisk) {    
        require(depositLowRisk.add(stakeAmount) <= (totalLiquidityLowRisk + liquidityDetailsOwner._lowRisk).mul(6), "Low risk pool: Staking limit reached!");   
        require(_poolBalances[_msgSender()][_isLowRisk].add(stakeAmount) <= (totalLiquidityLowRisk + liquidityDetailsOwner._lowRisk).mul(6), "Low risk pool: Staking limit reached!");
        liquidityRewardCollectedLowRisk += ((_amount.mul(liquidityReward)).div(100)).div(10);
        depositLowRisk += stakeAmount;
     } 
     else {
        require(depositHighRisk.add(stakeAmount) <= (totalLiquidityHighRisk + liquidityDetailsOwner._highRisk).mul(3), "High risk pool: Staking limit reached!");
        require(_poolBalances[_msgSender()][_isLowRisk].add(stakeAmount) <= (totalLiquidityHighRisk + liquidityDetailsOwner._highRisk).mul(3), "High risk pool: Staking limit reached!");
        liquidityRewardCollectedHighRisk += ((_amount.mul(liquidityReward)).div(100)).div(10);
        depositHighRisk += stakeAmount;
     }
        _isLowRisk == true ? storeUsers(_msgSender(), _lowRiskUsers): storeUsers(_msgSender(), _highRiskUsers); 
        _poolBalances[_msgSender()][_isLowRisk] = _poolBalances[_msgSender()][_isLowRisk].add(stakeAmount);
        ASSET.safeTransferFrom(_msgSender(), address(this), _amount);        //______| Record of Asset deposit |______
    }

    // for deducting LP balance if owner LP doesn't cover it first
    function checkAdminBalance(uint256 _factor, bool _champ) internal {
        uint256 totalWinLowRisk;
        uint256 totalWinHighRisk;
        if(_factor >= lowRiskMultiplier && _champ == true) {
            // ######## LR | PROFIT ###############
            // increase by 12% of all stakers.
            for(uint i = 0 ; i < _lowRiskUsers.length; i++)
            {           
                // Reduce from owner low risk liquidity
                totalWinLowRisk += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);
            }
        } 
      
        // high risk win
        if(_factor >= highRiskMultiplier && _champ == true) {     
            // ######### HR | PROFIT ###########
            // increase by 30% of all stakers.
            for(uint i = 0 ; i < _highRiskUsers.length ; i++){
                // Reduce from owner high risk liquidity
                totalWinHighRisk += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
            }
        } 
      
        if (totalWinHighRisk >= liquidityDetailsOwner._highRisk) {          
            uint256 cloneTotalLiquidityHighRisk = totalLiquidityHighRisk;
            uint256 diffrenceTobePaidHighRisk = totalWinHighRisk - liquidityDetailsOwner._highRisk;
            for (uint256 i=0;i<LiquidityHRUsers.length;i++) {              
                uint256 deductionPercentage = (currentHighLiquidity[LiquidityHRUsers[i]].mul(100))/cloneTotalLiquidityHighRisk;        
                uint256 amount = (diffrenceTobePaidHighRisk.mul(deductionPercentage)).div(100);               
                currentHighLiquidity[LiquidityHRUsers[i]] = currentHighLiquidity[LiquidityHRUsers[i]].sub(amount);               
                tempRecordForloss.push(LiquidityDetails(0,amount,LiquidityHRUsers[i],block.timestamp,false,false,true));              
                totalLiquidityHighRisk -= amount;
            }
            for (uint256 i=0;i<tempRecordForloss.length;i++) {
                LiquidityDetailsRecord.push(tempRecordForloss[i]);
            }
             
            liquidityDetailsOwner._highRisk = 0;
            delete tempRecordForloss;
            
        }
        if (totalWinLowRisk >= liquidityDetailsOwner._lowRisk) {
             uint256 diffrenceTobePaidLowRisk = totalWinLowRisk - liquidityDetailsOwner._lowRisk;
             uint256 clonetotalLiquidityLowRisk =totalLiquidityLowRisk;
            for (uint256 i=0;i<LiquidityLRUsers.length;i++) {
                uint256 deductionPercentage = (currentLowLiquidity[LiquidityLRUsers[i]].mul(100))/clonetotalLiquidityLowRisk;
                uint256 amount =  (diffrenceTobePaidLowRisk.mul(deductionPercentage)).div(100);                 
                currentLowLiquidity[LiquidityLRUsers[i]] = currentLowLiquidity[LiquidityLRUsers[i]].sub(amount);                
                tempRecordForloss.push(LiquidityDetails(amount,0,LiquidityLRUsers[i],block.timestamp,true,false,true));
                totalLiquidityLowRisk -= amount;
                
            }
            for (uint256 i=0;i<tempRecordForloss.length;i++) {
                LiquidityDetailsRecord.push(tempRecordForloss[i]);
            }
          
            liquidityDetailsOwner._lowRisk = 0;
            delete tempRecordForloss;
        }              
    }
  
    function rewardManager(uint256 _factor, bool _champ) internal {      
        checkAdminBalance(_factor,_champ);
        runCount += 1 ;
        //-----| Low Risk Winning factor |---------
        if(_factor >= lowRiskMultiplier && _champ == true) {
            // ########## LR | PROFIT #############
            // Stake increased by 12% 
            for(uint i = 0 ; i < _lowRiskUsers.length ; i++) {           
                // Reduce from owner low risk liquidity
                if (liquidityDetailsOwner._lowRisk >= _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000)) {
                    liquidityDetailsOwner._lowRisk -= _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);
                    // Maintaining Profits | Token               
                    _profitStakers[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);              
                    // Increase their balances
                    _poolBalances[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);
                    // address + isLowRisk + count ==> bool
                    previousResults[_lowRiskUsers[i]][true][runCount] = true;
                }
                else {
                    liquidityDetailsOwner._lowRisk = 0;
                    // Maintaining Profits                
                    _profitStakers[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);               
                    // Increase their balances
                    _poolBalances[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);
                    // address + isLowRisk + count ==> bool
                    previousResults[_lowRiskUsers[i]][true][runCount] = true;
                }       
            }         
        } 
        else {
            // ######## LR | LOSS ###########
            // Stake decreased by 15%.
            for(uint i = 0 ; i < _lowRiskUsers.length ; i++){
                liquidityDetailsOwner._lowRisk += _poolBalances[_lowRiskUsers[i]][true].mul(150).div(1000);
                // Storing everytime staker is in loss
                _losingStakers[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(150).div(1000);
                // Reducing stakers balance
                _poolBalances[_lowRiskUsers[i]][true] -= _poolBalances[_lowRiskUsers[i]][true].mul(150).div(1000);
                // address + isLowRisk + count ==> bool
                previousResults[_lowRiskUsers[i]][true][runCount] = false;           
            }     
        }

        //-----| High Risk Winning factor |---------       
        if(_factor >= lowRiskMultiplier && _champ == true) {         
            // ######### HR | PROFIT ###########
            // Stake increased by 30%.
            for(uint i = 0 ; i < _highRiskUsers.length ; i++){               
                // Reduce from owner liquidity            
                if (liquidityDetailsOwner._highRisk >= _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000)) {
                    liquidityDetailsOwner._highRisk -= _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);                    
                    // Storing everytime staker is winning 
                    _profitStakers[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
                    // Adding profits to staker balance
                    _poolBalances[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
                    // address + isLowRisk + count ==> bool
                    previousResults[_highRiskUsers[i]][false][runCount] = true;
                }
                else {
                    liquidityDetailsOwner._highRisk = 0;                   
                    // Storing everytime staker is winning | Token | ETH
                    _profitStakers[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
                    // Adding profits to staker balance
                    _poolBalances[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
                    // address + isLowRisk + count ==> bool
                    previousResults[_highRiskUsers[i]][false][runCount] = true;
                }
            }           
        } 
        // factor < highRiskMultiplierH | High Risk Losing
        else {
            // ######### HR | LOSS ###########
            // Tokens decreased by 35% of all stakers.
            for(uint i = 0 ; i < _highRiskUsers.length ; i++) {
                // ########### Increase for owner liquidity #############
                liquidityDetailsOwner._highRisk += _poolBalances[_highRiskUsers[i]][false].mul(350).div(1000);       
                _losingStakers[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(350).div(1000);
                // Reducing from staker balances
                _poolBalances[_highRiskUsers[i]][false] -= _poolBalances[_highRiskUsers[i]][false].mul(350).div(1000);
                // address + isLowRisk + count ==> bool
                previousResults[_highRiskUsers[i]][false][runCount] = false;     
            }
        }
    }

    function checkPerformance(uint256 _inputPredictionAsset1, uint256 _inputpredictionAsset2, bool _polarityPredictionAsset1, bool _polaritypredictionAsset2) public {       
        if (!_polarityPredictionAsset1 && !_polaritypredictionAsset2) { 
            if(_inputPredictionAsset1 > _inputpredictionAsset2){
                winnerScale = _inputPredictionAsset1.mul(10).div(_inputpredictionAsset2);
                who = false;            
            } 
            else {
                winnerScale = _inputpredictionAsset2.mul(10).div(_inputPredictionAsset1);
                who = true;               
            }

        // predictionAsset1 = Positive |=====| predictionAsset2 = Negative
        } 
        else if (_polaritypredictionAsset2 && !_polaritypredictionAsset2) {  
            winnerScale = _inputPredictionAsset1.add(_inputpredictionAsset2).mul(10).div(_inputPredictionAsset1);
            who = true;           
        // predictionAsset1 = Negative |=====| predictionAsset2 = Positive 
        }
        else if(!_polarityPredictionAsset1 && _polaritypredictionAsset2) {       
            winnerScale = _inputPredictionAsset1.add(_inputpredictionAsset2).mul(10).div(_inputpredictionAsset2);
            who = false;  
        }
        else if(_polarityPredictionAsset1 && _polaritypredictionAsset2) {            
            if(_inputPredictionAsset1 > _inputpredictionAsset2){
                winnerScale = _inputPredictionAsset1.mul(10).div(_inputpredictionAsset2);
                who = true;           
            } 
            else {
                winnerScale = _inputpredictionAsset2.mul(10).div(_inputPredictionAsset1);
                who = false;
            }
        } 
        else {
            winnerScale = 0;
            who = false;
        }
    }

    function withdrawPredictionStake(uint256 _amount, bool _isLowRisk) public nonReentrant {
        require(!poolStarted, "Cannot withdraw Asset while pool is running");
        require(_msgSender() != owner());
        require(_amount <= _poolBalances[_msgSender()][_isLowRisk], "Insufficient Balance");
        _poolBalances[_msgSender()][_isLowRisk] = _poolBalances[_msgSender()][_isLowRisk].sub(_amount);
        ASSET.safeTransfer(_msgSender(), _amount);

        if (_isLowRisk) {
            depositLowRisk -= _amount;
        } 
        else {
            depositHighRisk -= _amount;
        }   
    }

    function raisePercent(uint256 _v1, uint256 _v2) internal pure returns (uint256, bool) {
        if (_v1 > _v2){
          return (_v1.sub(_v2).mul(1000) == 0 ? 0 : (_v1.sub(_v2).mul(1000).div(_v1)), false); //___| Deprecation over time |______
       } 
       else {
          return (_v2.sub(_v1).mul(1000) == 0 ? 0 : (_v2.sub(_v1).mul(1000).div(_v1)), true); //___| Increase over time |____
       } 
    }

    //______| Net earning Asset |____|Profits must higher than loss|___
    function netEarning(bool _isLowRisk) public view returns (uint256) {
        if (getProfits(_isLowRisk) > getLosses(_isLowRisk)) {
            return getProfits(_isLowRisk).sub(getLosses(_isLowRisk));
        } 
        else {
            return 0;
        }
    }

    // updateLimitVariables
    function updateAssetLimitVariables() internal{
        depositLowRisk = 0;
        depositHighRisk = 0;

        for(uint i = 0; i < _lowRiskUsers.length ; i++) {
           depositLowRisk += _poolBalances[_lowRiskUsers[i]][true];
        }

        for(uint i = 0; i < _highRiskUsers.length ; i++) {
           depositHighRisk += _poolBalances[_lowRiskUsers[i]][false];
        }   
    }    
   
    function getProfits(bool _isLowRisk) public view returns (uint256){
        return _profitStakers[_msgSender()][_isLowRisk];
    }

    function getLosses(bool _isLowRisk) public view returns (uint256){
        return _losingStakers[_msgSender()][_isLowRisk];
    }

    // Liquidity
    uint256 public totalLiquidityLowRisk;
    uint256 public totalLiquidityHighRisk;
    struct LiquidityDetails {
        uint256 _lowRisk;
        uint256 _highRisk;
        address _address;
        uint256 timestamp;
        bool isLowRisk;
        bool isWithdraw;
        bool isLoss;       
    }
    mapping(address => uint256) currentLowLiquidity;
    mapping(address => uint256) currentHighLiquidity; 
    LiquidityDetails[] LiquidityDetailsRecord;
    LiquidityDetails liquidityDetailsOwner;
    address[] LiquidityLRUsers;
    address[] LiquidityHRUsers;

    /**
     * poolStopped => liquidityCycle = true; => 12hr "liquidity cycle"
     * a timebox for "natural" liquidity change in pools whereby: 
     * LPs can withdraw liquidity 
     * post window => pool liquidity is locked until the next cycle, providing a stable liquid market
     * window also allows predictors additional time to analyse before deciding on participation 
     */ 
    function provideLiquidity (uint256 amount, bool _isLowRisk) public {
        if (_msgSender() != owner()) {
            if (_isLowRisk) {
                LiquidityDetailsRecord.push(LiquidityDetails(amount,0,_msgSender(),block.timestamp,true,false,false));
            }
            else {
                LiquidityDetailsRecord.push(LiquidityDetails(0,amount,_msgSender(),block.timestamp,false,false,false));
            }
            if (_isLowRisk == true) {
                totalLiquidityLowRisk += amount;
                currentLowLiquidity[_msgSender()] = currentLowLiquidity[_msgSender()].add(amount);
                storeUsers(_msgSender(),LiquidityLRUsers);
            
            }
            else {
                totalLiquidityHighRisk += amount;
                currentHighLiquidity[_msgSender()] = currentHighLiquidity[_msgSender()].add(amount);
                storeUsers(_msgSender(),LiquidityHRUsers);
            }
            
        }
         if (_msgSender() == owner() && _isLowRisk) {
            liquidityDetailsOwner._address = owner();
            liquidityDetailsOwner._lowRisk += amount;
        }
        else if (_msgSender() == owner() && _isLowRisk == false) {
            liquidityDetailsOwner._address = owner();
            liquidityDetailsOwner._highRisk += amount;
        }
        ASSET.safeTransferFrom(_msgSender(), address(this), amount);       
    }

    function getLiquidityProviderUser() external view returns(LiquidityDetails[] memory) {
        return LiquidityDetailsRecord;
    }

    function getOwnerLiquidity(bool _isLowRisk)  external view returns(uint256) {
        if (_isLowRisk)
        {
            return liquidityDetailsOwner._lowRisk;
        }
        else
        {
            return  liquidityDetailsOwner._highRisk;
        }
    }

    function getLiquidityProviderAccountBalance(address _account, bool _isLowRisk) external view returns(uint256) {  
        if (_isLowRisk)
        {
           return currentLowLiquidity[_account];
        }
        else
        {
            return currentHighLiquidity[_account];
        }        
    }
    
    LiquidityDetails[]  tempRecordForloss;
    
    function getUserProvisionedLiquidity(address _who, bool _isLowRisk) public view returns (uint256) {
        return _poolBalances[_who][_isLowRisk];
    }
    
    function getAllProvisionedLiquidity () public view returns (uint256) {
        return totalLiquidityLowRisk + totalLiquidityHighRisk;
    } 

    function withdrawLiquidity(uint256 _amount, bool _isLowRisk) external nonReentrant {
        require(_amount > 0 , "Choose an amount!");
        require(liquidityCycle, "Cannot withdraw liquidity outside of the liquidity cycle!");
        // PLEASE CHANGE TO (12 hours) FOR MAINNET
        require(block.timestamp <= liquidityCycleStartTime.add(5 minutes),"12 hour liquidity cycle has now passed!" ); 
        if (_isLowRisk) {
            require(_amount <= currentLowLiquidity[_msgSender()],"Insufficient Balance");
            currentLowLiquidity[_msgSender()] -= _amount;
            totalLiquidityLowRisk -= _amount;
            LiquidityDetailsRecord.push(LiquidityDetails(_amount,0,_msgSender(),block.timestamp,true,true,false));
            ASSET.safeTransfer(_msgSender(), _amount);           
        }
        else {
            require(_amount <= currentHighLiquidity[_msgSender()],"Insufficient Balance");
            currentHighLiquidity[_msgSender()] -= _amount;
            LiquidityDetailsRecord.push(LiquidityDetails(0,_amount,_msgSender(),block.timestamp,false,true,false));
            totalLiquidityHighRisk -= _amount;
            ASSET.safeTransfer(_msgSender(), _amount);
        }
    }
    
    //______| liquidity reward calculation |_______
    
    uint256 liquidityRewardCollectedLowRisk;
    uint256 liquidityRewardCollectedHighRisk;
    uint256 liquidityReward = 20; // 2% = 20 
    
    function getliquidityRewardCollected (bool _isLowRisk) public view returns(uint256) {       
        if (_isLowRisk)
        {
            return liquidityRewardCollectedLowRisk;
        }
        else
        {
            return liquidityRewardCollectedHighRisk;
        }
    }

    function getTotalLiquidityRewards () public view returns(uint256) {     
        return liquidityRewardCollectedLowRisk + liquidityRewardCollectedHighRisk;
    }
    
    struct RewardPaid{
        uint256 rewardPaid;
        uint256 rewardPaidDate;
        bool isWithdraw;
    }
    
    mapping(address => uint256) rewardByUser;
    mapping (address => RewardPaid[]) rewardPaidRecord;
    
    function getUserTotalReward() external view returns(uint256) {
        return rewardByUser[_msgSender()].div(10**decimals());
    }
    
    function  distributeLiquidityRewards(bool _isLowRisk) internal {
        for (uint i=0;i<LiquidityDetailsRecord.length;i++) {
            if(_isLowRisk && LiquidityDetailsRecord[i].isLowRisk == true) {
                uint256 rewardPerc = ((LiquidityDetailsRecord[i]._lowRisk.mul(10**decimals())).mul(100*10**decimals())).div(totalLiquidityLowRisk.mul(10**decimals()));              
                uint256 rewardAmount = ((liquidityRewardCollectedLowRisk.mul(10**decimals()) ).mul(rewardPerc) )/(100 * 10**decimals());         
                rewardPaidRecord[LiquidityDetailsRecord[i]._address].push(RewardPaid(rewardAmount.div(10**decimals()),block.timestamp,false));              
                rewardByUser[LiquidityDetailsRecord[i]._address] += rewardAmount;
            }
            else if(_isLowRisk == false && LiquidityDetailsRecord[i].isLowRisk == false) {
                uint256 rewardPerc = ((LiquidityDetailsRecord[i]._highRisk.mul(10**decimals())).mul(100*10**decimals())).div(totalLiquidityHighRisk.mul(10**decimals()));
                uint256 rewardAmount = ((liquidityRewardCollectedHighRisk.mul(10**decimals()) ).mul(rewardPerc) )/(100 * 10**decimals());               
                rewardPaidRecord[LiquidityDetailsRecord[i]._address].push(RewardPaid(rewardAmount.div(10**decimals()),block.timestamp,false));               
                rewardByUser[LiquidityDetailsRecord[i]._address] += rewardAmount;
            }
        }
        if(_isLowRisk) {
            liquidityRewardCollectedLowRisk = 0;
        }
        else {
            liquidityRewardCollectedHighRisk = 0;
        }
        
    }

    function getRewardPaidRecord() external view returns(RewardPaid[] memory) {
        return rewardPaidRecord[_msgSender()];
    }
    
    function withdrawLiquidityRewards(uint256 amount) external nonReentrant {
        require(amount<=rewardByUser[_msgSender()],"Insufficient Balance");
        rewardByUser[_msgSender()] = rewardByUser[_msgSender()].sub(amount.mul(10**decimals())); 
        ASSET.safeTransfer(_msgSender(),amount);
        rewardPaidRecord[_msgSender()].push(RewardPaid(amount,block.timestamp,true));       
    }

    function decimals() public view returns(uint256) {
        return ASSET.decimals();
    }
}