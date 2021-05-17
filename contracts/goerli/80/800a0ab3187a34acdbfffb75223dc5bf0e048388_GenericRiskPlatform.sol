/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

/**
    _________________________________________________________________________________________
     1. Stakers can stake upto 12 hours from Pool start time.
     2. The Pool will run for 7 days.
     3. StartPool : Admin will provide `Player1` and `Player2` value initially and start the pools.
     4. StopPool : Admin will provide both value once 7 days is completed.
    __________________________________________________________________________________________
     1. Low Risk  : Stake limit is [6x] of liquidity. 
     2. High Risk : Stake limit is [3x] of liquidity. 
     3. Low Risk is denoted by  [true].
     4. High Risk is denoted by [false]. 
     ___________________________________________________________________________________________
     Stakers must have 20k Wolfy tokens in their wallet to participate in any of the risk pools.
        Mainnet : 20,000

     Pool Duration 
        Mainet  : 7 days

     Stake Allowed
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
    function _msgSender() internal view virtual returns (address) {
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

contract GenericRiskPlatform is Ownable,ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    uint256 public startTime = 0;

    constructor(address _wolfy, address _asset) public{
      WOLFY = IERC20(_wolfy);
      ASSET = IERC20(_asset);
    }
    
    // uint256 public defiPulse;
    // uint256 public snp500; 

    uint256 public player1; 
    uint256 public player2;

    uint256 public netPlayer1;
    uint256 public netPlayer2;

    bool  A;
    bool  B;

    bool public poolStarted;
   
    uint256 winnerScale;
    bool who;

    uint8 public locationCheck;

    address[] _lowRiskAssetUsers;
    address[] _highRiskAssetUsers;

    uint256 public depositLowRiskAsset;
    uint256 public depositHighRiskAsset;
   
    uint256 wolfyLimit = 10*10**3*10**9; // mainnet

    uint256 public targetHigh;
    uint256 public targetLow; 
    
    bool checker ;
  
    IERC20 public WOLFY;
    IERC20 public ASSET;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(bool => uint256)) private _balancesRiskPool;
    mapping(address =>  mapping(bool => uint256)) public _lossAssetStakers;
    mapping(address =>  mapping(bool => uint256)) public _profitAssetStakers;
   
    // address + isLowRisk + count ==> bool
    mapping(address => mapping(bool => mapping(uint256 => bool))) public previousResults;
    
    uint256 public runCount;
    
     
    
    //----| Set 15 for 1.5x |----| 10 for 1x |---| 23 for 2.3x |--
    function setTargetLow(uint256 _targetLow) public onlyOwner {
        require(poolStarted == false, "Pool has  been started ");
      targetLow =  _targetLow;
    }

    //----| Set 50 for 5x |----| 100 for 10x |---| 120 for 12x |--
    function setTargetHigh(uint256 _targetHigh) public onlyOwner {
         require(poolStarted == false, "Pool has  been started ");
       targetHigh = _targetHigh;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account]; 
    }

    //====== | Get total profits/loss [Asset] pool wise |====| Profit{true} and Loss{false} |
    function getProfitLossAsset(bool _isLowRisk, bool _isProfit) public view returns (uint256) {
        
        if(_isProfit){
            return _profitAssetStakers[msg.sender][_isLowRisk]; 
        }
            return _lossAssetStakers[msg.sender][_isLowRisk]; 
    }

    function checkBalanceAsset(address account, bool _isLowRisk) public view returns (uint256) {
        return _balancesRiskPool[account][_isLowRisk];   
    }

    function storeUsers(address receiver, address[] storage arrayData) internal{

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

    function stakeAsset(uint256 _amount, bool _isLowRisk) public  {
        
    require(_amount > 0 , "Please add some good amount");
    require(poolStarted, "Pool has not been started yet");
    require(block.timestamp <= startTime.add(12 hours),"Its more than 12 hours since pool started" ); // Can stake upto 12 hours from start pool.
    require(WOLFY.balanceOf(msg.sender) >= wolfyLimit, "You must possess 10K WOLFY Tokens to Participate");

    uint256 stakeAmount;
      if (liquidityReward >= 1)
      {
          stakeAmount = _amount - ((_amount.mul(liquidityReward)).div(100)).div(10);
      }
      else
      {
          stakeAmount = _amount;
      }
     if(_isLowRisk){
         
        require(depositLowRiskAsset.add(stakeAmount) <= (totalLiquidityLowRsik + liquidityDetailsOwner._assetLowRisk).mul(6), "Target 6X reaching");   
        require(_balancesRiskPool[msg.sender][_isLowRisk].add(stakeAmount) <= (totalLiquidityLowRsik + liquidityDetailsOwner._assetLowRisk).mul(6), "Exceeding low risk ETH limit");
        
     
       
        liquidityRewardCollectedLowRsik += ((_amount.mul(liquidityReward)).div(100)).div(10);
       depositLowRiskAsset += stakeAmount;

     } else {

        require(depositHighRiskAsset.add(stakeAmount) <= (totalLiquidityHighRsik + liquidityDetailsOwner._assetHighRisk).mul(3), "Target 3X reaching");
        require(_balancesRiskPool[msg.sender][_isLowRisk].add(stakeAmount) <= (totalLiquidityHighRsik + liquidityDetailsOwner._assetHighRisk).mul(3), "Exceeding high risk ETH limit");
      
        liquidityRewardCollectedHighRsik += ((_amount.mul(liquidityReward)).div(100)).div(10);
        depositHighRiskAsset += stakeAmount;
    
     }

        _isLowRisk == true ? storeUsers(msg.sender, _lowRiskAssetUsers): storeUsers(msg.sender, _highRiskAssetUsers); 
        _balancesRiskPool[msg.sender][_isLowRisk] = _balancesRiskPool[msg.sender][_isLowRisk].add(stakeAmount);
        ASSET.safeTransferFrom(msg.sender, address(this), _amount);        //______| Record of ETH deposit |______
    }

    // Add ASSET liquidity
    uint256 public totalLiquidityLowRsik;
    uint256 public totalLiquidityHighRsik;
    struct LiquidityDetails
    {
        uint256 _assetLowRisk;
        uint256 _assetHighRisk;
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
    function addAsset(uint256 amount, bool _isLowRisk) public { 
        // _balancesRiskPool[msg.sender][_isLowRisk] = _balancesRiskPool[msg.sender][_isLowRisk].add(amount);
        //  ASSET.safeTransferFrom(msg.sender, address(this), amount);
         
        if (msg.sender != owner())
        {
            if (_isLowRisk)
            {
                LiquidityDetailsRecord.push(LiquidityDetails(amount,0,msg.sender,block.timestamp,true,false,false));
            }
            else
            {
                LiquidityDetailsRecord.push(LiquidityDetails(0,amount,msg.sender,block.timestamp,false,false,false));
            }
            if (_isLowRisk == true)
            {
                totalLiquidityLowRsik += amount;
                currentLowLiquidity[msg.sender] = currentLowLiquidity[msg.sender].add(amount);
                storeUsers(msg.sender,LiquidityLRUsers);
            
            }
            else
            {
                totalLiquidityHighRsik += amount;
                currentHighLiquidity[msg.sender] = currentHighLiquidity[msg.sender].add(amount);
                storeUsers(msg.sender,LiquidityHRUsers);
            }
            
        }
         if (msg.sender == owner() && _isLowRisk)
        {
            liquidityDetailsOwner._address = owner();
            liquidityDetailsOwner._assetLowRisk += amount;
        }
        else if (msg.sender == owner() && _isLowRisk == false)
        {
            liquidityDetailsOwner._address = owner();
            liquidityDetailsOwner._assetHighRisk += amount;
        }
        ASSET.safeTransferFrom(msg.sender, address(this), amount);
         
    }
     function getLiquidityProviderUser() external view returns(LiquidityDetails[] memory)
    {
        return LiquidityDetailsRecord;
    }
    function getOwnerLiquidity(bool _isLowRisk)  external view returns(uint256)
    {
        if (_isLowRisk)
        {
            return liquidityDetailsOwner._assetLowRisk;
        }
        else
        {
            return  liquidityDetailsOwner._assetHighRisk;
        }
    }
    function getLiquiidtyProviderAccountBalance(address _account,bool _isLowRisk) external view returns(uint256)
    {
   
        if(_isLowRisk)
        {
           return currentLowLiquidity[_account];
        }
        else
        {
            return currentHighLiquidity[_account];
        }
        
    }
    function raisePercent(uint256 _v1, uint256 _v2) internal pure returns (uint256, bool) {
        if(_v1 > _v2){
          return (_v1.sub(_v2).mul(1000) == 0 ? 0 : (_v1.sub(_v2).mul(1000).div(_v1)), false); //___| Deprecation over time |______
       } else{
          return (_v2.sub(_v1).mul(1000) == 0 ? 0 : (_v2.sub(_v1).mul(1000).div(_v1)), true); //___| Increase over time |____
       } 
    }

    function checkPerformance(uint256 _inputPlayer1, uint256 _inputPlayer2, bool _polarityPlayer1, bool _polarityPlayer2) public {
        
         if(!_polarityPlayer1 && !_polarityPlayer2){
        
            if(_inputPlayer1 > _inputPlayer2){
                winnerScale = _inputPlayer1.mul(10).div(_inputPlayer2);
                who = false;
            
            } else {
                winnerScale = _inputPlayer2.mul(10).div(_inputPlayer1);
                who = true;
                
            }

        // Player1 = Positive |=====| Player2 = Negative
        } else if(_polarityPlayer2 && !_polarityPlayer2){  

            winnerScale = _inputPlayer1.add(_inputPlayer2).mul(10).div(_inputPlayer1);
            who = true;
           
        // Player1 = Negative |=====| Player2 = Positive 
        }else if(!_polarityPlayer1 && _polarityPlayer2){
          
            winnerScale = _inputPlayer1.add(_inputPlayer2).mul(10).div(_inputPlayer2);
            who = false;
  
        }else if(_polarityPlayer1 && _polarityPlayer2){
            
            if(_inputPlayer1 > _inputPlayer2){
                winnerScale = _inputPlayer1.mul(10).div(_inputPlayer2);
                who = true;
           
            } else {
                winnerScale = _inputPlayer2.mul(10).div(_inputPlayer1);
                who = false;
            }

        } else {

            winnerScale = 0;
            who = false;
        }


    }
    
    LiquidityDetails[]  tempRecordForloss;
   
    function checkAdminBalance(uint256 _factor, bool _champ) internal  // for deducting LP balance if admin dont have enough stake
    {
        uint256 totalWinLowRisk;
        uint256 totalWinHighRisk;
        if(_factor >= targetLow && _champ == true){

          // ######## LR ##########  ETH  ######## PROFIT ###############
          // ETH : ETH increased by 12% of all stakers.
            for(uint i = 0 ; i < _lowRiskAssetUsers.length; i++)
            {
             
             // Reduce from Admin low risk wallet
                totalWinLowRisk += _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(120).div(1000);
            }
        } 
      
        // factor >= 5x | High Risk Winning
        if(_factor >= targetHigh && _champ == true){
          
            // ######### HR ########### ETH ############ PROFIT ###########
            for(uint i = 0 ; i < _highRiskAssetUsers.length ; i++){
                // ***** Reduce from Admin wallet *****
                totalWinHighRisk += _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(300).div(1000);
            }
        } 
      
        if (totalWinHighRisk >= liquidityDetailsOwner._assetHighRisk)
        {
            
            uint256 clonetotalLiquidityHighRsik = totalLiquidityHighRsik;
            uint256 diffrenceTobePaidHighRisk = totalWinHighRisk - liquidityDetailsOwner._assetHighRisk;
            for (uint256 i=0;i<LiquidityHRUsers.length;i++)
            {
               
                uint256 deductionPercentage = (currentHighLiquidity[LiquidityHRUsers[i]].mul(100))/clonetotalLiquidityHighRsik;
               
                 uint256 amount = (diffrenceTobePaidHighRisk.mul(deductionPercentage)).div(100);
                
                 currentHighLiquidity[LiquidityHRUsers[i]] = currentHighLiquidity[LiquidityHRUsers[i]].sub(amount);
                
                 tempRecordForloss.push(LiquidityDetails(0,amount,LiquidityHRUsers[i],block.timestamp,false,false,true));
               
                 totalLiquidityHighRsik -= amount;
            }
            for (uint256 i=0;i<tempRecordForloss.length;i++)
            {
                LiquidityDetailsRecord.push(tempRecordForloss[i]);
            }
             
            liquidityDetailsOwner._assetHighRisk = 0;
            delete tempRecordForloss;
            
        }
        if (totalWinLowRisk >= liquidityDetailsOwner._assetLowRisk)
        {
             uint256 diffrenceTobePaidLowRisk = totalWinLowRisk - liquidityDetailsOwner._assetLowRisk;
             uint256 clonetotalLiquidityLowRsik =totalLiquidityLowRsik;
            for (uint256 i=0;i<LiquidityLRUsers.length;i++)
            {
                uint256 deductionPercentage = (currentLowLiquidity[LiquidityLRUsers[i]].mul(100))/clonetotalLiquidityLowRsik;
                 uint256 amount =  (diffrenceTobePaidLowRisk.mul(deductionPercentage)).div(100);
                 
                currentLowLiquidity[LiquidityLRUsers[i]] = currentLowLiquidity[LiquidityLRUsers[i]].sub(amount);
                
                tempRecordForloss.push(LiquidityDetails(amount,0,LiquidityLRUsers[i],block.timestamp,true,false,true));
                totalLiquidityLowRsik -= amount;
                
            }
            for (uint256 i=0;i<tempRecordForloss.length;i++)
            {
                LiquidityDetailsRecord.push(tempRecordForloss[i]);
            }
          
             liquidityDetailsOwner._assetLowRisk = 0;
            delete tempRecordForloss;
        }
       
        
    }
  
    function rewardManager(uint256 _factor, bool _champ) internal {
       
        checkAdminBalance(_factor,_champ);
       runCount += 1 ;

       //-----| Low Risk Winning factor |---------
       if(_factor >= targetLow && _champ == true){

        // ########## LR ########## ASSET ########## PROFIT #############
        // ASSETS increased by 12% 
        for(uint i = 0 ; i < _lowRiskAssetUsers.length ; i++){
             
             // Reduce from Admin low risk wallet
            if (liquidityDetailsOwner._assetLowRisk >= _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(120).div(1000))
            {
                liquidityDetailsOwner._assetLowRisk -= _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(120).div(1000);
                 // Maintaining Profits | Token 
               
                   _profitAssetStakers[_lowRiskAssetUsers[i]][true] += _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(120).div(1000);
              
                // Increase their balances
                _balancesRiskPool[_lowRiskAssetUsers[i]][true] += _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(120).div(1000);

                // // address + isLowRisk + count ==> bool
                previousResults[_lowRiskAssetUsers[i]][true][runCount] = true;
            }
            else
            {
                liquidityDetailsOwner._assetLowRisk = 0;
                 // Maintaining Profits | Token 
               
                _profitAssetStakers[_lowRiskAssetUsers[i]][true] += _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(120).div(1000);
                
                // Increase their balances
                _balancesRiskPool[_lowRiskAssetUsers[i]][true] += _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(120).div(1000);

                // // address + isLowRisk + count ==> bool
                previousResults[_lowRiskAssetUsers[i]][true][runCount] = true;
            }
           
        
        }
          
        } else {

            // ######## LR ############ ASSET ############ LOSS ###########
            // ASSETS decreased by 15% for all stakers.
            for(uint i = 0 ; i < _lowRiskAssetUsers.length ; i++){

                liquidityDetailsOwner._assetLowRisk += _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(150).div(1000);
                 // Storing everytime staker is in loss
                _lossAssetStakers[_lowRiskAssetUsers[i]][true] += _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(150).div(1000);
                // Reducing stakers balance
                _balancesRiskPool[_lowRiskAssetUsers[i]][true] -= _balancesRiskPool[_lowRiskAssetUsers[i]][true].mul(150).div(1000);
                //// address + isLowRisk + count ==> bool
                previousResults[_lowRiskAssetUsers[i]][true][runCount] = false;
            
            }     
        }

        //-----| High Risk Winning factor |--------- 
       
        if(_factor >= targetHigh && _champ == true){
          
            // ######### HR ########### ASSET ############ PROFIT ###########
            // ASSETS increased by 30% of all stakers.
            for(uint i = 0 ; i < _highRiskAssetUsers.length ; i++){
                
                 // ***** Reduce from Admin wallet *****
               
                if (liquidityDetailsOwner._assetHighRisk >= _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(300).div(1000))
                {
                     liquidityDetailsOwner._assetHighRisk -= _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(300).div(1000);
                    
                    // Storing everytime staker is winning | Token | ETH
                    _profitAssetStakers[_highRiskAssetUsers[i]][false] += _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(300).div(1000);
                    // Adding profits to staker balance
                    _balancesRiskPool[_highRiskAssetUsers[i]][false] += _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(300).div(1000);
                    // address + isLowRisk + count ==> bool
                    previousResults[_highRiskAssetUsers[i]][false][runCount] = true;
                }
                else
                {
                     liquidityDetailsOwner._assetHighRisk = 0;
                   
                    // Storing everytime staker is winning | Token | ETH
                    _profitAssetStakers[_highRiskAssetUsers[i]][false] += _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(300).div(1000);
                    // Adding profits to staker balance
                    _balancesRiskPool[_highRiskAssetUsers[i]][false] += _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(300).div(1000);
                // address + isLowRisk + count ==> bool
                    previousResults[_highRiskAssetUsers[i]][false][runCount] = true;
                }
            }

           
        // factor < targetHigh | High Risk Losing
        } else {

            // ######### HR ########### ASSET ############ LOSS ###########
            // Tokens decreased by 35% of all stakers.
            for(uint i = 0 ; i < _highRiskAssetUsers.length ; i++){

               // ########### Increase for Admin wallet #############
              liquidityDetailsOwner._assetHighRisk += _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(350).div(1000);
              
                // _lossWOLFYStakers _lossETHStakers _profitWOLFYStakers _profitETHStakers
               _lossAssetStakers[_highRiskAssetUsers[i]][false] += _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(350).div(1000);
                // Reducing from staker balances
              _balancesRiskPool[_highRiskAssetUsers[i]][false] -= _balancesRiskPool[_highRiskAssetUsers[i]][false].mul(350).div(1000);
                // address + isLowRisk + count ==> bool
               previousResults[_highRiskAssetUsers[i]][false][runCount] = false;
               
       
            }
        }
    }

    function startPool(uint256 _player1, uint256 _player2) public onlyOwner { 
        
     
        require(!poolStarted, "Previous pool not finalized yet!!");
        require( totalLiquidityLowRsik + liquidityDetailsOwner._assetLowRisk > 0 ," LowRisk : Please add ETH liquidity");
        require( totalLiquidityHighRsik + liquidityDetailsOwner._assetHighRisk > 0 ," HighRisk : Please add ETH liquidity");


        player1 = _player1;
        player2 = _player2;
       
        startTime = block.timestamp;
        poolStarted = true;

    }

    // Value of `Player1` and `Player2` after 7 days
   
    function stopPool(uint256 _player1, uint256 _player2) public onlyOwner { 
        //require(block.timestamp > startTime.add(7 days), "Can stop once 7 days are finished"); //### 7 days #### Mainnet
        
        
        require(poolStarted, "Pool not started yet!!");
      
        (netPlayer1, A) = raisePercent(player1,_player1);             //___either positive or negative
        (netPlayer2, B)  = raisePercent(player2,_player2);           //___either positive or negative

        distributeLiquidityRewards(true);
        distributeLiquidityRewards(false);
        
        checkPerformance(netPlayer1, netPlayer2, A, B);
       
        rewardManager(winnerScale, who);
        poolStarted = false;
    }
    
   
    function getProfits(bool _isLowRisk) public view returns (uint256){
        return _profitAssetStakers[msg.sender][_isLowRisk];
    }

    function getLosses(bool _isLowRisk) public view returns (uint256){
        return _lossAssetStakers[msg.sender][_isLowRisk];
    }

     //______| Total Asset liquidity low Risk |_______
    function getLiquidityAsset(address _who, bool _isLowRisk) public view returns (uint256){
      // return _balancesRiskPool[_who][_isLowRisk];
       if (_isLowRisk == true)
        {
            return totalLiquidityLowRsik + liquidityDetailsOwner._assetLowRisk;
        }
        else
        {
            return totalLiquidityHighRsik + liquidityDetailsOwner._assetHighRisk;
        }
    }


    //______| Net earning Asset |____|Profits must higher than loss|___
    function netEarning(bool _isLowRisk) public view returns (uint256){
         if(getProfits(_isLowRisk) > getLosses(_isLowRisk)){
           return getProfits(_isLowRisk).sub(getLosses(_isLowRisk));
       } else {
            return 0;
       }
    }

    // updateLimitVariables
    function updateAssetLimitVariables() internal{
        depositLowRiskAsset = 0;
        depositHighRiskAsset = 0;

        for(uint i = 0; i < _lowRiskAssetUsers.length ; i++){
           depositLowRiskAsset += _balancesRiskPool[_lowRiskAssetUsers[i]][true];
        }

        for(uint i = 0; i < _highRiskAssetUsers.length ; i++){
           depositHighRiskAsset += _balancesRiskPool[_lowRiskAssetUsers[i]][false];
        }   
    }

   
    //TODO : Not allowed if pools are running
    function withdrawLiquidityToken(uint256 _amount, bool _isLowRisk) external nonReentrant
    {
        
         require(!poolStarted, "Cannot withdraw ETH when pool is running");
         if (_isLowRisk)
         {
              require(_amount <= currentLowLiquidity[msg.sender],"Insufficient Balance");
              currentLowLiquidity[msg.sender] -= _amount;
              totalLiquidityLowRsik -= _amount;
              LiquidityDetailsRecord.push(LiquidityDetails(_amount,0,msg.sender,block.timestamp,true,true,false));
              ASSET.safeTransfer(msg.sender, _amount);
               
         }
         else
         {
              require(_amount <= currentHighLiquidity[msg.sender],"Insufficient Balance");
              currentHighLiquidity[msg.sender] -= _amount;
              LiquidityDetailsRecord.push(LiquidityDetails(0,_amount,msg.sender,block.timestamp,false,true,false));
              totalLiquidityHighRsik -= _amount;
              ASSET.safeTransfer(msg.sender, _amount);
         }
    }
    function withdrawToken(uint256 _amount, bool _isLowRisk) public nonReentrant {
      require(!poolStarted, "Cannot withdraw Asset when pool is running");
      require(msg.sender != owner(), "Owner cannot withdraw tokens");
      require(_amount <= _balancesRiskPool[msg.sender][_isLowRisk], "Insufficient Tokens in your wallet");
      _balancesRiskPool[msg.sender][_isLowRisk] = _balancesRiskPool[msg.sender][_isLowRisk].sub(_amount);
      ASSET.safeTransfer(msg.sender, _amount);

      if(_isLowRisk){
        depositLowRiskAsset -= _amount;
      } else{
        depositHighRiskAsset -= _amount;
      }
      
    }
    
     //______| liquidity reward calculation |_______
    
    uint256 liquidityRewardCollectedLowRsik;
    uint256 liquidityRewardCollectedHighRsik;
    uint256 liquidityReward = 20; // 2% = 20 
    function getliquidityReward() public view returns(uint256) {
       return liquidityReward;
    }
    function getliquidityRewardCollected(bool _isLowRisk) public view returns(uint256) {
        
        if (_isLowRisk)
        {
            return liquidityRewardCollectedLowRsik;
        }
        else
        {
            return liquidityRewardCollectedHighRsik;
        }
    }
    struct RewardPaid{
        uint256 rewardPaid;
        uint256 rewardPaidDate;
        bool isWithdraw;
    }
    mapping(address => uint256) rewardByUser;
    mapping (address => RewardPaid[]) rewardPaidRecord;
    function getUserTotalReward() external view returns(uint256)
    {
        return rewardByUser[msg.sender].div(10**18);
    }
    
    function  distributeLiquidityRewards(bool _isLowRisk) internal  // for distributin rewards to LP based on their fund added
    {
        for (uint i=0;i<LiquidityDetailsRecord.length;i++)
        {
            if(_isLowRisk && LiquidityDetailsRecord[i].isLowRisk == true)
            {
                //((LiquidityDetailsRecord[i]._etherLowRisk.mul(10**decimals())).mul(100*10**decimals()).div(totalLiquidityLowRsik.mul(10**decimals()));
                uint256 rewardPerc = ((LiquidityDetailsRecord[i]._assetLowRisk.mul(10**decimals())).mul(100*10**decimals())).div(totalLiquidityLowRsik.mul(10**decimals()));
                
                uint256 rewardAmount = ((liquidityRewardCollectedLowRsik.mul(10**decimals()) ).mul(rewardPerc) )/(100 * 10**decimals());
                
                rewardPaidRecord[LiquidityDetailsRecord[i]._address].push(RewardPaid(rewardAmount.div(10**decimals()),block.timestamp,false));
                
                rewardByUser[LiquidityDetailsRecord[i]._address] += rewardAmount;
            }
            else if(_isLowRisk == false && LiquidityDetailsRecord[i].isLowRisk == false)
            {
                uint256 rewardPerc = ((LiquidityDetailsRecord[i]._assetHighRisk.mul(10**decimals())).mul(100*10**decimals())).div(totalLiquidityHighRsik.mul(10**decimals()));
             
                uint256 rewardAmount = ((liquidityRewardCollectedHighRsik.mul(10**decimals()) ).mul(rewardPerc) )/(100 * 10**decimals());
                
                rewardPaidRecord[LiquidityDetailsRecord[i]._address].push(RewardPaid(rewardAmount.div(10**decimals()),block.timestamp,false));
                
                rewardByUser[LiquidityDetailsRecord[i]._address] += rewardAmount;
            }
        }
        if(_isLowRisk)
        {
            liquidityRewardCollectedLowRsik = 0;
        }
        else
        {
            liquidityRewardCollectedHighRsik = 0;
        }
        
    }
    function getRewardPaidRecord() external view returns(RewardPaid[] memory)
    {
        return rewardPaidRecord[msg.sender];
    }
    
    function WithdrawReward(uint256 amount) external nonReentrant
    {
        require(amount<=rewardByUser[msg.sender],"Insufficient Balance");
        rewardByUser[msg.sender] -= amount;
        
        ASSET.safeTransfer(msg.sender,amount);
        rewardPaidRecord[msg.sender].push(RewardPaid(amount,block.timestamp,true));
        
    }
    function decimals() public view returns(uint256)
    {
        return ASSET.decimals();
    }
}