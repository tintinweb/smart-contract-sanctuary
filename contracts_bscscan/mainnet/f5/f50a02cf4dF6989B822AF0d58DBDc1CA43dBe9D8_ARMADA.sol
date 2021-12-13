/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/**
 * SPDX-License-Identifier: MIT
 */ 
pragma solidity ^0.8.10;

/**
 *                                                                 
 *  A HYPER-DEFLATIONARY, BUYBACK POWERED CRYPTOCURRENCY
 *  
 *  https://armadacrypto.com
 *  https://t.me/armadatoken
 */

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

library Address {
    function isContract(address account) internal view returns (bool) { 
        uint256 size; assembly { size := extcodesize(account) } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
        
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IPancakeV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


abstract contract DepreciatingFees {
    using SafeMath for uint256;
    
    struct FeeStruct {
        uint256 buying_rfiFee;
        uint256 buying_marketingFee;
        uint256 buying_developmentFee;
        uint256 buying_platformFee;
        uint256 selling_rfiFee;
        uint256 selling_marketingFee;
        uint256 selling_developmentFee;
        uint256 selling_platformFee;
        uint256 amount;
        bool exist;
        uint256 lastUpdated;
        uint256 nextReductionTime;
        
    }
    
    mapping(address => FeeStruct) public fees;
    address[] feeholders;
    mapping (address => uint256) feeholdersIndexes;
    
    event LogNewFeeHolder(address indexed _userAddress, uint256 _amount, uint256 timeAdded);
    
    event LogUpdateFeeHolder(address indexed _userAddress, uint256 _amount, 
    uint256 _lastUpdated, uint256 _nextReductionTime);
    

    uint256 internal buying_rfiReductionPerSec = 3306; // 0.0000033069 per second
    uint256 internal buying_marketingReductionPerSec = 6613; // 0.00000066138 per second
    uint256 internal buying_developmentReductionPerSec = 3306; // 0.0000033069 per second
    uint256 internal buying_platformReductionPerSec = 3306; // 0.0000033069 per second

    uint256 internal selling_rfiReductionPerSec = 8267; // 0.0000082672 per second
    uint256 internal selling_marketingReductionPerSec = 6613; // 0.00000066138 per second
    uint256 internal selling_developmentReductionPerSec = 3306; // 0.0000033069 per second
    uint256 internal selling_platformReductionPerSec = 6613; // 0.00000066138 per second
       
    uint256 internal reductionDivisor = 10**9; // reduction multiplier
    uint256 internal updateFeeTime = 1; // every second
    uint256 internal FEES_DIVISOR = 10**11; // gives you the true percentage
    
    uint256 public buying_rfiFee = 2;
    uint256 public buying_marketingFee = 4;
    uint256 public buying_developmentFee = 2;
    uint256 public buying_platformFee = 2;

    uint256 public selling_rfiFee = 5;
    uint256 public selling_marketingFee = 4;
    uint256 public selling_developmentFee = 2;
    uint256 public selling_platformFee = 4;
    
    uint256 internal buying_rfiFee_ = buying_rfiFee * reductionDivisor;
    uint256 internal buying_marketingFee_ = buying_marketingFee * reductionDivisor;
    uint256 internal buying_developmentFee_ = buying_developmentFee * reductionDivisor;
    uint256 internal buying_platformFee_ = buying_platformFee * reductionDivisor;

    uint256 internal selling_rfiFee_ = selling_rfiFee * reductionDivisor;
    uint256 internal selling_marketingFee_ = selling_marketingFee * reductionDivisor;
    uint256 internal selling_developmentFee_ = selling_developmentFee * reductionDivisor;
    uint256 internal selling_platformFee_ = selling_platformFee * reductionDivisor;
    
    uint256 internal buyTotalFees = buying_rfiFee_.add(buying_marketingFee_).add(buying_developmentFee_).add(buying_platformFee_);
    uint256 internal sellTotalFees = selling_rfiFee_.add(selling_marketingFee_).add(selling_developmentFee_).add(selling_platformFee_);


    function _getBuyHolderFees (address _userAddress, bool feeReduction) internal view returns 
    (uint256, uint256, uint256, uint256) {
        
        (uint256 _estimatedBuyRfiFee) = getBuyRfiEstimatedFee(_userAddress);
        (uint256 _estimatedBuyMarketingFee) = getBuyMarketingEstimatedFee(_userAddress);
        (uint256 _estimatedBuyDevFee) = getBuyDevEstimatedFee(_userAddress);
        (uint256 _estimatedBuyPlatformFee) = getBuyPlatformEstimatedFee(_userAddress);
        
        return (
            !feeReduction ? buying_rfiFee_ : _estimatedBuyRfiFee,
            !feeReduction ? buying_marketingFee_ : _estimatedBuyMarketingFee,
            !feeReduction ? buying_developmentFee_ :  _estimatedBuyDevFee,
            !feeReduction ? buying_platformFee_ :  _estimatedBuyPlatformFee
            );
    }

    function _getSellHolderFees (address _userAddress, bool feeReduction) internal view returns 
    (uint256, uint256, uint256, uint256) {

        (uint256 _estimatedSellRfiFee) = getSellRfiEstimatedFee(_userAddress);
        (uint256 _estimatedSellMarketingFee) = getSellMarketingEstimatedFee(_userAddress);
        (uint256 _estimatedSellDevFee) = getSellDevEstimatedFee(_userAddress);
        (uint256 _estimatedSellPlatformFee) = getSellPlatformEstimatedFee(_userAddress);
       
        return (
            !feeReduction ? selling_rfiFee_ : _estimatedSellRfiFee,
            !feeReduction ? selling_marketingFee_ : _estimatedSellMarketingFee,
            !feeReduction ? selling_developmentFee_ :  _estimatedSellDevFee,
            !feeReduction ? selling_platformFee_ :  _estimatedSellPlatformFee
            );
    }
    
    function getBuyRfiEstimatedFee (address _userAddress) public view returns(uint256) {
        (uint256 accruedTime) = getAccruedTime(_userAddress);
        uint256 _rfiFee = fees[_userAddress].buying_rfiFee; 

        return _rfiFee <= accruedTime.mul(buying_rfiReductionPerSec) ? 0 : 
        _rfiFee.sub(accruedTime.mul(buying_rfiReductionPerSec));
    }

    function getBuyMarketingEstimatedFee (address _userAddress) public view returns(uint256) {
        (uint256 accruedTime) = getAccruedTime(_userAddress);
        uint256 _marketingFee = fees[_userAddress].buying_marketingFee; 

        return _marketingFee <= accruedTime.mul(buying_marketingReductionPerSec) ? 0 : 
        _marketingFee.sub(accruedTime.mul(buying_marketingReductionPerSec));
    }

    function getBuyDevEstimatedFee (address _userAddress) public view returns(uint256) {
        (uint256 accruedTime) = getAccruedTime(_userAddress);
        uint256 _developmentFee = fees[_userAddress].buying_developmentFee; 

        return _developmentFee <= accruedTime.mul(buying_developmentReductionPerSec) ? 0 : 
        _developmentFee.sub(accruedTime.mul(buying_developmentReductionPerSec));
    }

    function getBuyPlatformEstimatedFee (address _userAddress) public view returns(uint256) {
        (uint256 accruedTime) = getAccruedTime(_userAddress);
        uint256 _platformFee = fees[_userAddress].buying_platformFee; 

        return _platformFee <= accruedTime.mul(buying_platformReductionPerSec) ? 0 : 
        _platformFee.sub(accruedTime.mul(buying_platformReductionPerSec));
    }

    function getSellRfiEstimatedFee (address _userAddress) public view returns(uint256) {
        (uint256 accruedTime) = getAccruedTime(_userAddress);
        uint256 _rfiFee = fees[_userAddress].selling_rfiFee; 

        return _rfiFee <= accruedTime.mul(selling_rfiReductionPerSec) ? 0 : 
        _rfiFee.sub(accruedTime.mul(selling_rfiReductionPerSec));
    }

    function getSellMarketingEstimatedFee (address _userAddress) public view returns(uint256) {
        (uint256 accruedTime) = getAccruedTime(_userAddress);
        uint256 _marketingFee = fees[_userAddress].selling_marketingFee; 

        return _marketingFee <= accruedTime.mul(selling_marketingReductionPerSec) ? 0 : 
        _marketingFee.sub(accruedTime.mul(selling_marketingReductionPerSec));
    }

    function getSellDevEstimatedFee (address _userAddress) public view returns(uint256) {
        (uint256 accruedTime) = getAccruedTime(_userAddress);
        uint256 _developmentFee = fees[_userAddress].selling_developmentFee; 

        return _developmentFee <= accruedTime.mul(selling_developmentReductionPerSec) ? 0 : 
        _developmentFee.sub(accruedTime.mul(selling_developmentReductionPerSec));
    }

    function getSellPlatformEstimatedFee (address _userAddress) public view returns(uint256) {
        (uint256 accruedTime) = getAccruedTime(_userAddress);
        uint256 _platformFee = fees[_userAddress].selling_platformFee; 

        return _platformFee <= accruedTime.mul(selling_platformReductionPerSec) ? 0 : 
        _platformFee.sub(accruedTime.mul(selling_platformReductionPerSec));
    }

    function getAccruedTime(address _userAddress) public view returns (uint256 _accruedTime) {
        uint256 accruedTime = block.timestamp - fees[_userAddress].lastUpdated;
        return accruedTime;
    }
    
    function calculateBuyingReadjustment(address _userAddress, uint256 _amount, uint256 _rfiFee,
    uint256 _marketingFee, uint256 _developmentFee, uint256 _platformFee) internal view returns 
    (uint256, uint256, uint256, uint256) {
        
        uint256 currentBalance = fees[_userAddress].amount;
        uint256 __amount = _amount;
        
        (uint256 getRfiFee) = formula(_rfiFee, currentBalance, _amount, buying_rfiFee_ );
        (uint256 getMarketingFee) = formula(_marketingFee, currentBalance, __amount, buying_marketingFee_ );
        (uint256 getDevelopmentFee) = formula(_developmentFee, currentBalance, __amount, buying_developmentFee_ );
        (uint256 getPlatformFee) = formula(_platformFee, currentBalance, __amount, buying_platformFee_ );
        
        return (
            getRfiFee,
            getMarketingFee,
            getDevelopmentFee,
            getPlatformFee
            );    
    }

    function calculateSellingReadjustment(address _userAddress, uint256 _amount, uint256 _rfiFee,
    uint256 _marketingFee, uint256 _developmentFee, uint256 _platformFee) internal view returns 
    (uint256, uint256, uint256, uint256) {
        
        uint256 currentBalance = fees[_userAddress].amount;
        uint256 __amount = _amount;
        
        (uint256 getRfiFee) = formula(_rfiFee, currentBalance, _amount, selling_rfiFee_ );
        (uint256 getMarketingFee) = formula(_marketingFee, currentBalance, __amount, selling_marketingFee_ );
        (uint256 getDevelopmentFee) = formula(_developmentFee, currentBalance, __amount, selling_developmentFee_ );
        (uint256 getPlatformFee) = formula(_platformFee, currentBalance, __amount, selling_platformFee_ );

        return (
            getRfiFee,
            getMarketingFee,
            getDevelopmentFee,
            getPlatformFee
            );    
    }
    
    function formula(uint256 currentFee, uint256 currentBalance, uint256 tokensPurchased, uint256 feeMultiplier) 
    private pure returns(uint256) {
        return  ((currentFee * currentBalance) + (feeMultiplier * tokensPurchased) )/ (currentBalance + tokensPurchased);
    }
    
    
    function reAdjustBuyingFees(address userAddress, uint256 _amount, uint256 _rfiFee, uint256 _marketingFee, 
        uint256 _developmentFee, uint256 _platformFee) internal onlyFeeHolder(userAddress) {
             
        (uint256 newRfiFee, uint256 newMarketingFee, uint256 newDevelopmentFee, uint256 newPlatformFee) = 
            calculateBuyingReadjustment (userAddress, _amount, _rfiFee, _marketingFee, _developmentFee, _platformFee);

        fees[userAddress].buying_rfiFee = newRfiFee;
        fees[userAddress].buying_marketingFee = newMarketingFee;
        fees[userAddress].buying_developmentFee = newDevelopmentFee;
        fees[userAddress].buying_platformFee = newPlatformFee;
    }

    function reAdjustSellingFees(address userAddress, uint256 _amount, uint256 _rfiFee, uint256 _marketingFee, 
         uint256 _developmentFee, uint256 _platformFee) internal onlyFeeHolder(userAddress) {
             
        (uint256 newRfiFee, uint256 newMarketingFee, uint256 newDevelopmentFee, uint256 newPlatformFee) = 
            calculateSellingReadjustment (userAddress, _amount, _rfiFee, _marketingFee, _developmentFee, _platformFee);

        fees[userAddress].selling_rfiFee = newRfiFee;
        fees[userAddress].selling_marketingFee = newMarketingFee;
        fees[userAddress].selling_developmentFee = newDevelopmentFee;
        fees[userAddress].selling_platformFee = newPlatformFee;   
    }

    function updateAmount (address _userAddress, uint256 _amount) internal onlyFeeHolder(_userAddress){
        fees[_userAddress].amount = fees[_userAddress].amount.add(_amount); 
        fees[_userAddress].lastUpdated = block.timestamp; 
        fees[_userAddress].nextReductionTime = block.timestamp + updateFeeTime;
    }
    
    function updateAmountOnSell(address _userAddress, uint256 _amount) internal {
       uint256 subTractAmt = fees[_userAddress].amount >= _amount ? fees[_userAddress].amount.sub(_amount) : _amount;
       fees[_userAddress].amount = subTractAmt; 
    }
    
   
    function returnAmount(uint256 _amount) private pure returns(uint256) {
        return _amount;
    }
    
    function setFeeHolder(address _userAddress, uint256 _amount) internal {
        addFeeHolder( _userAddress, _amount ); 
    }

    modifier onlyFeeHolder(address _userAddress) {
        require(isFeeHolder(_userAddress), "Fee Holder does not exist!");
        _;
    }

    function addFeeHolder(address _userAddress, uint256 _amount) private {
        require(!isFeeHolder(_userAddress), "Fee Holder already exist!");

        feeholdersIndexes[_userAddress] = feeholders.length;
        feeholders.push(_userAddress);
        
        fees[_userAddress].buying_rfiFee = buying_rfiFee_;
        fees[_userAddress].buying_marketingFee = buying_marketingFee_;
        fees[_userAddress].buying_developmentFee = buying_developmentFee_;
        fees[_userAddress].buying_platformFee = buying_platformFee_;

        fees[_userAddress].selling_rfiFee = selling_rfiFee_;
        fees[_userAddress].selling_marketingFee = selling_marketingFee_;
        fees[_userAddress].selling_developmentFee = selling_developmentFee_;
        fees[_userAddress].selling_platformFee = selling_platformFee_;

        fees[_userAddress].amount = _amount; 
        fees[_userAddress].exist = true;
        fees[_userAddress].lastUpdated = block.timestamp; 
        fees[_userAddress].nextReductionTime = block.timestamp + updateFeeTime;

        emit LogNewFeeHolder(
            _userAddress,
            _amount,
            block.timestamp
            );
      }
    
    function isFeeHolder(address userAddress) public view returns(bool isIndeed) {
        if(feeholders.length == 0) return false;
        return (fees[userAddress].exist);
    }
       
    function getFeeHoldersCount() public view returns(uint256 count) {
        return feeholders.length;
    } 
}

contract ARMADA is IERC20Metadata, DepreciatingFees, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address public marketingWallet = 0x6F33bA55D29034c4eE21e1e60ddc9CD97a9Bd5a0; // Marketing Address
    address public developmentWallet = 0x6F33bA55D29034c4eE21e1e60ddc9CD97a9Bd5a0; // Development Address
    address public platformWallet = 0x6F33bA55D29034c4eE21e1e60ddc9CD97a9Bd5a0; // _platformFee Address
    address internal deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public presaleAddress = address(0);
    
    string constant _name = "Armada";
    string constant _symbol = "AMRDT";
    uint8 constant _decimals = 18;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _totalSupply = 1000000000000 * 10**18;
    uint256 internal _reflectedSupply = (MAX - (MAX % _totalSupply));
    
    uint256 public collectedFeeTotal;
  
    uint256 public maxTxAmount = _totalSupply / 1000; // 0.5% of the total supply
    uint256 public maxWalletBalance = _totalSupply / 50; // 2% of the total supply
    
    bool public autoBuyBackEnabled = true;
    uint256 public autoBuybackAmount = 1 * 10**18;
    bool public takeFeeEnabled = true;
    
    bool public isInPresale = false;
    
    // Total = 100%
    uint256 public marketingPortionOfSwap = 40; // 50%
    uint256 public devPortionOfSwap = 20; // 20%
    uint256 public platformPortionOfSwap = 40; // 40%

    uint256 private swapDivisor = 10**2;
    
    bool private swapping;
    bool public swapEnabled = true;
    uint256 public swapTokensAtAmount = 1000 * (10**18);
    
    IPancakeV2Router public router;
    address public pair;
    
    mapping (address => uint256) internal _reflectedBalances;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    
    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromRewards;
    address[] private _excluded;
    
    /* ========== EVENTS ========== */
    event UpdatePancakeswapRouter(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event DevelopmentWalletUpdated(address indexed newDevelopmentWallet, address indexed oldDevelopmentWallet);
    event PlatformWalletUpdated(address indexed newPlatformWallet, address indexed oldPlatformWallet);
    event Recovered(address token, uint256 amount);
    
    event SwapETHForTokens( uint256 amountIn, address[] path );  
    event SwapTokensForETH( uint256 amountIn, address[] path );
    
    constructor () {
        _reflectedBalances[owner()] = _reflectedSupply;
        
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        router = _newPancakeRouter;
        
        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        // exclude the pair and burn addresses from rewards
        _exclude(pair);
        _exclude(deadAddress);
        
        _approve(owner(), address(router), ~uint256(0));
        
        emit Transfer(address(0), owner(), _totalSupply);
    }
    
    
    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256){
        if (_isExcludedFromRewards[account]) return _balances[account];
        return tokenFromReflection(_reflectedBalances[account]);
        }
        
    function transfer(address recipient, uint256 amount) public override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
        }
        
    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowances[owner][spender];
        }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
        }
        
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool){
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
        }
        
    function burn(uint256 amount) external {

        address sender = _msgSender();
        require(sender != address(0), "ERC20: burn from the zero address");
        require(sender != address(deadAddress), "ERC20: burn from the burn address");

        uint256 balance = balanceOf(sender);
        require(balance >= amount, "ERC20: burn amount exceeds balance");

        uint256 reflectedAmount = amount.mul(_getCurrentRate());

        // remove the amount from the sender's balance first
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(reflectedAmount);
        if (_isExcludedFromRewards[sender])
            _balances[sender] = _balances[sender].sub(amount);

        _burnTokens( sender, amount, reflectedAmount );
    }
    
    /**
     * @dev "Soft" burns the specified amount of tokens by sending them 
     * to the burn address
     */
    function _burnTokens(address sender, uint256 tBurn, uint256 rBurn) internal {

        /**
         * @dev Do not reduce _totalSupply and/or _reflectedSupply. (soft) burning by sending
         * tokens to the burn address (which should be excluded from rewards) is sufficient
         * in RFI
         */ 
        _reflectedBalances[deadAddress] = _reflectedBalances[deadAddress].add(rBurn);
        if (_isExcludedFromRewards[deadAddress])
            _balances[deadAddress] = _balances[deadAddress].add(tBurn);

        /**
         * @dev Emit the event so that the burn address balance is updated (on bscscan)
         */
        emit Transfer(sender, deadAddress, tBurn);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BaseRfiToken: approve from the zero address");
        require(spender != address(0), "BaseRfiToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
     /**
     * @dev Calculates and returns the reflected amount for the given amount with or without 
     * the transfer fees (deductTransferFee true/false)
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee, bool isBuying) external view returns(uint256) {
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        uint256 feesSum;
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount,0);
            return rAmount;
        } else {
            feesSum = isBuying ? buyTotalFees : sellTotalFees;
            (,uint256 rTransferAmount,,,) = _getValues(tAmount, feesSum);
            return rTransferAmount;
        }
    }

    /**
     * @dev Calculates and returns the amount of tokens corresponding to the given reflected amount.
     */
    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _reflectedSupply, "Amount must be less than total reflections");
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }
    
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromRewards[account], "Account is not included");
        _exclude(account);
    }
    
    function _exclude(address account) internal {
        if(_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(_reflectedBalances[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function setExcludedFromFee(address account, bool value) external onlyOwner { 
        _isExcludedFromFee[account] = value; 
        
    }

    function _getValues(uint256 tAmount, uint256 feesSum) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        
        return (rAmount, rTransferAmount, tAmount, tTransferAmount, currentRate);
    }
    
    function _getCurrentRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = _totalSupply;

        /**
         * The code below removes balances of addresses excluded from rewards from
         * rSupply and tSupply, which effectively increases the % of transaction fees
         * delivered to non-excluded holders
         */    
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectedBalances[_excluded[i]] > rSupply || _balances[_excluded[i]] > tSupply)
            return (_reflectedSupply, _totalSupply);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }
        if (tSupply == 0 || rSupply < _reflectedSupply.div(_totalSupply)) return (_reflectedSupply, _totalSupply);
        return (rSupply, tSupply);
    }
    
    
    /**
     * @dev Redistributes the specified amount among the current holders via the reflect.finance
     * algorithm, i.e. by updating the _reflectedSupply (_rSupply) which ultimately adjusts the
     * current rate used by `tokenFromReflection` and, in turn, the value returns from `balanceOf`. 
     * 
     */
    function _redistribute(uint256 amount, uint256 currentRate, uint256 fee) internal {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
        
        collectedFeeTotal = collectedFeeTotal.add(tFee);
    }

    // views
    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return swapTokensAtAmount;
    }
    
    function getAutoBuybackAmount() external view returns (uint256) {
        return autoBuybackAmount;
    } 
    
    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRewards[account];
    }
    
    function isExcludedFromFee(address account) public view returns(bool) { 
        return _isExcludedFromFee[account]; 
    }
    
     function totalCollectedFees() external view returns (uint256) {
        return collectedFeeTotal;
    }
    
    function beAFeeHolder(address userAddress) external {
        uint256 userBalance = balanceOf(address(userAddress));
        require(userBalance > 0, "You are not an Armada Token Holder");
        
         // create a new fee holder
        if(!isFeeHolder(userAddress)) {
          setFeeHolder(userAddress, userBalance);
        }
        
    }
    
    function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
  	    presaleAddress = _presaleAddress;
  	    
        _exclude(_presaleAddress);
        _isExcludedFromFee[_presaleAddress] = true;

        _exclude(_routerAddress);
        _isExcludedFromFee[_routerAddress] = true;
  	}
    
    function prepareForPreSale() external onlyOwner {
        takeFeeEnabled = false;
        swapEnabled = false;
        isInPresale = true;
        maxTxAmount = 1000000000000 * (10**18);
        maxWalletBalance = 1000000000000 * (10**18);
    }
    
    function afterPreSale() external onlyOwner {
        takeFeeEnabled = true;
        swapEnabled = true;
        isInPresale = false;
        maxTxAmount = 2000000 * (10**18);
        maxWalletBalance = 4014201 * (10**18);
    }
    
    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled  = _enabled;
    }
    
    function updateSwapTokensAt(uint256 _swaptokens) external onlyOwner {
        swapTokensAtAmount = _swaptokens * (10**18);
    }
    
    function updateWalletMax(uint256 _walletMax) external onlyOwner {
        maxWalletBalance = _walletMax * (10**18);
    }
    
    function updateTransactionMax(uint256 _txMax) external onlyOwner {
        maxTxAmount = _txMax * (10**18);
    }
    
    function updateBuyingFeesTotal() private {    
        buyTotalFees = buying_rfiFee_.add(buying_marketingFee_).add(buying_developmentFee_).add(buying_platformFee_);
    }

    function updateSellingFeesTotal() private {
        sellTotalFees = selling_rfiFee_.add(selling_marketingFee_).add(selling_developmentFee_).add(selling_platformFee_);
    }

    // reductionPerSec is the rate at which the Fee depreciates per second
    // formula: (fee/number of days) / total no of seconds in a day
    // example: dev fee is 2
    // depreciates for 7 days
    // (2/7)/86400 = 0.0000033069
    // mkae the result a wholenumber: 0.0000033069 * 1,000,000,000 (must be 9 zeroes) = 3306.9
    // use only the numbers before the decimal = 3306 (This should be used as reductionPerSec following this example)
    // Following this example will give you the corresponding reductionPerSec for the Fee

    function _updateBuyingRfiFee(uint256 newFee, uint256 reductionPerSec) external onlyOwner {
       buying_rfiFee = newFee;
       buying_rfiFee_ = newFee * reductionDivisor;
       buying_rfiReductionPerSec = reductionPerSec;

       updateBuyingFeesTotal();
    }

    function _updateBuyingMarketingFee(uint256 newFee, uint256 reductionPerSec) external onlyOwner {
       buying_marketingFee = newFee;
       buying_marketingFee_ = newFee * reductionDivisor;
       buying_marketingReductionPerSec = reductionPerSec;

       updateBuyingFeesTotal();
    }

    function _updateBuyingDevelopmentFee(uint256 newFee, uint256 reductionPerSec) external onlyOwner {
       buying_developmentFee = newFee;
       buying_developmentFee_ = newFee * reductionDivisor;
       buying_developmentReductionPerSec = reductionPerSec;

       updateBuyingFeesTotal();
    }

    function _updateBuyingPlatformFee(uint256 newFee, uint256 reductionPerSec) external onlyOwner {
       buying_platformFee = newFee;
       buying_platformFee_ = newFee * reductionDivisor;
       buying_platformReductionPerSec = reductionPerSec;

       updateBuyingFeesTotal();
    }

    function _updateSellingRfiFee(uint256 newFee, uint256 reductionPerSec) external onlyOwner {
       selling_rfiFee = newFee;
       selling_rfiFee_ = newFee * reductionDivisor;
       selling_rfiReductionPerSec = reductionPerSec;

       updateSellingFeesTotal();
    }

    function _updateSellingMarketingFee(uint256 newFee, uint256 reductionPerSec) external onlyOwner {
       selling_marketingFee = newFee;
       selling_marketingFee_ = newFee * reductionDivisor;
       selling_marketingReductionPerSec = reductionPerSec;

       updateSellingFeesTotal();
    }

    function _updateSellingDevelopmentFee(uint256 newFee, uint256 reductionPerSec) external onlyOwner {
       selling_developmentFee = newFee;
       selling_developmentFee_ = newFee * reductionDivisor;
       selling_developmentReductionPerSec = reductionPerSec;

       updateSellingFeesTotal();
    }

    function _updateSellingPlatformFee(uint256 newFee, uint256 reductionPerSec) external onlyOwner {
       selling_platformFee = newFee;
       selling_platformFee_ = newFee * reductionDivisor;
       selling_platformReductionPerSec = reductionPerSec;

       updateSellingFeesTotal();
    }
    
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        require(newMarketingWallet != marketingWallet, "The Marketing wallet is already this address");
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);

        marketingWallet = newMarketingWallet;
    }

    function updateDevelopmentWallet(address newDevelopmentWallet) external onlyOwner {
        require(newDevelopmentWallet != developmentWallet, "The Development wallet is already this address");
        emit DevelopmentWalletUpdated(newDevelopmentWallet, developmentWallet);

        developmentWallet = newDevelopmentWallet;
    }

    function updatePlatformWallet(address newPlatformWallet) external onlyOwner {
        require(newPlatformWallet != platformWallet, "The Platform wallet is already this address");
        emit PlatformWalletUpdated(newPlatformWallet, platformWallet);

        platformWallet = newPlatformWallet;
    }
    
    function setTakeFeeEnabled(bool __takeFee) external onlyOwner {
        takeFeeEnabled = __takeFee;
    }
      
    function setReductionDivisor(uint256 divisor) external onlyOwner() {
        reductionDivisor = divisor;
    }
    
    function setUpdateFeeTime(uint256 feeTime) external onlyOwner() {
        updateFeeTime = feeTime;
    }
    
    function setFeesDivisor(uint256 divisor) external onlyOwner() {
        FEES_DIVISOR = divisor;
    }
    
    function updateRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(router), "The router already has that address");
        router = IPancakeV2Router(newAddress);
        emit UpdatePancakeswapRouter(newAddress, address(router));
    }

    function updatePortionsOfSwap(uint256 marketingPortion, uint256 devPortion, uint256 platformPortion) external onlyOwner {
        
        uint256 totalPortion = marketingPortion.add(devPortion).add(platformPortion);
        require(totalPortion == 100, "Total must be equal to 100 (%)");
        
        marketingPortionOfSwap = marketingPortion;
        devPortionOfSwap = devPortion;
        platformPortionOfSwap = platformPortion;
    }

    function getSumOfFees (bool feeReduction, address userAddress, bool isBuying, uint256 amount) private returns (uint256) {
         // grab the estimated reduced fees
        (uint256 reduceBuyRfiFee, uint256 reduceBuyMarketingFee,  
        uint256 reduceBuyDevFee, uint256 reduceBuyPlatformFee) = _getBuyHolderFees(userAddress, feeReduction);

        // grab the estimated reduced fees
        (uint256 reduceSellRfiFee, uint256 reduceSellMarketingFee,  
        uint256 reduceSellDevFee, uint256 reduceSellPlatformFee) = _getSellHolderFees(userAddress, feeReduction);

        uint256 sumOfFees;

        if(isBuying){
            sumOfFees = reduceBuyRfiFee.add(reduceBuyMarketingFee).add(reduceBuyDevFee).add(reduceBuyPlatformFee);
        }
        else{
            sumOfFees = reduceSellRfiFee.add(reduceSellMarketingFee).add(reduceSellDevFee).add(reduceSellPlatformFee);
        }

        if(feeReduction) {
            if(isBuying) {
               // Adjust the Fee struct to reflect the new transaction
                reAdjustBuyingFees(userAddress, amount, reduceBuyRfiFee, reduceBuyMarketingFee, reduceBuyDevFee, reduceBuyPlatformFee); 
                reAdjustSellingFees(userAddress, amount, reduceSellRfiFee, reduceSellMarketingFee, reduceSellDevFee, reduceSellPlatformFee);
                updateAmount (userAddress, amount);
            }
            else{
                updateAmountOnSell(userAddress, amount);   
            } 
        }

        return sumOfFees;
    }
    
    function _transferTokens(address sender, address recipient, uint256 amount, 
    bool takeFee, bool feeReduction, address userAddress) private {

        bool isBuying = true;
         
        if(recipient == pair) {
            isBuying  = false;
        }
        
        if(sender != pair && recipient != pair) {
            isBuying = false;
        }

       (uint256 _sumOfFees)  = getSumOfFees (feeReduction, userAddress, isBuying, amount);
       uint256 sumOfFees = _sumOfFees;
       
        if ( !takeFee ){ sumOfFees = 0; }
        if( isInPresale ){ sumOfFees = 0; }
        
        processReflectedBal(sender, recipient, amount, sumOfFees, isBuying, feeReduction, userAddress);
       
    }
    
    function processReflectedBal (address sender, address recipient, uint256 amount, uint256 sumOfFees, bool isBuying, 
    bool feeReduction, address userAddress) internal {
        
        (uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, 
        uint256 tTransferAmount, uint256 currentRate ) = _getValues(amount, sumOfFees);

        bool _isBuying = isBuying;
         
        theReflection(sender, recipient, rAmount, rTransferAmount, tAmount, tTransferAmount); 
        
        _takeFees(amount, currentRate, sumOfFees, _isBuying, feeReduction, userAddress);
        
        emit Transfer(sender, recipient, tTransferAmount);
        
    }
    
    function theReflection(address sender, address recipient, uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, 
        uint256 tTransferAmount) private {
            
        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rTransferAmount);
        
        /**
         * Update the true/nominal balances for excluded accounts
         */        
        if (_isExcludedFromRewards[sender]) { _balances[sender] = _balances[sender].sub(tAmount); }
        if (_isExcludedFromRewards[recipient] ) { _balances[recipient] = _balances[recipient].add(tTransferAmount); }
    }
    
    
    function _takeFees(uint256 amount, uint256 currentRate, uint256 sumOfFees, 
    bool isBuying, bool feeReduction, address userAddress) private {
        // grab the estimated reduced fees
        (uint256 reduceBuyRfiFee, uint256 reduceBuyMarketingFee,  
        uint256 reduceBuyDevFee, uint256 reduceBuyPlatformFee) = _getBuyHolderFees(userAddress, feeReduction);

        (uint256 reduceSellRfiFee, uint256 reduceSellMarketingFee,  
        uint256 reduceSellDevFee, uint256 reduceSellPlatformFee) = _getSellHolderFees(userAddress, feeReduction);

        if ( sumOfFees > 0 && !isInPresale ){
            if(isBuying) {
                _redistribute( amount, currentRate, reduceBuyRfiFee);
                _takeFee( amount, currentRate, reduceBuyMarketingFee, address(this));
                _takeFee( amount, currentRate, reduceBuyDevFee, address(this));
                _takeFee( amount, currentRate, reduceBuyPlatformFee, address(this));
            }
            else{
                _redistribute( amount, currentRate, reduceSellRfiFee);
                _takeFee( amount, currentRate, reduceSellMarketingFee, address(this));
                _takeFee( amount, currentRate, reduceSellDevFee, address(this));
                _takeFee( amount, currentRate, reduceSellPlatformFee, address(this));
            }
        }
    }
    
    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);
        if(_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        collectedFeeTotal = collectedFeeTotal.add(tAmount);
    }
    
    function _beforeTokenTransfer(address recipient) private {
        // also adjust fees - add later
        
        if ( !isInPresale ){
            
            uint256 contractTokenBalance = balanceOf(address(this));
            // swap
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap && swapEnabled  && recipient == pair) {
                swapping = true;

                swapBack();

                swapping = false;
            }   
        }
    }
   
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Token: transfer from the zero address");
        require(recipient != address(0), "Token: transfer to the zero address");
        require(sender != address(deadAddress), "Token: transfer from the burn address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (
            sender != address(router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFee[recipient] && //no max for those excluded from fees
            !_isExcludedFromFee[sender] 
        ) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the Max Transaction Amount.");
            
        }
        
        if ( maxWalletBalance > 0 && !_isExcludedFromFee[recipient] && !_isExcludedFromFee[sender] && recipient != address(pair) ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(recipientBalance + amount <= maxWalletBalance, "New balance would exceed the maxWalletBalance");
            }
            
         // indicates whether or not feee should be deducted from the transfer
        bool _isTakeFee = takeFeeEnabled;
        if ( isInPresale ){ _isTakeFee = false; }
        
         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) { 
            _isTakeFee = false; 
        }
        
         bool feeReduction = true;
         address userAddress; 
         
         if(sender != pair && recipient == pair) {
             userAddress = sender;
         }
         else if(sender == pair && recipient != pair) {
             userAddress = recipient;
         }
         else {
             userAddress = msg.sender;
         }
         
         if(!isInPresale) {
           // create a new fee holder
            if(!isFeeHolder(userAddress)) {
               setFeeHolder(userAddress, recipient != pair ? amount : 0); // create a new fee holder
               feeReduction = false;
            } 
         }
         // if contract is in presale, then there should be no fee reduction
        if(isInPresale){ feeReduction = false; }
        
        _beforeTokenTransfer(recipient);
        _transferTokens(sender, recipient, amount, _isTakeFee, feeReduction, userAddress );
        
    }

    function swapBack() internal {
        uint256 amountToSwap = balanceOf(address(this));
        
        uint256 balanceBefore = address(this).balance;
        
        swapTokensForBNB(amountToSwap);

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        
        uint256 amountBNBMarketing = amountBNB.mul(marketingPortionOfSwap).div(swapDivisor);
        uint256 amountBNBDev = amountBNB.mul(devPortionOfSwap).div(swapDivisor);
        uint256 amountBNBPlatform = amountBNB.mul(platformPortionOfSwap).div(swapDivisor);
        
          //Send to addresses
        transferToAddress(payable(marketingWallet), amountBNBMarketing);
        transferToAddress(payable(developmentWallet), amountBNBDev);
        transferToAddress(payable(platformWallet), amountBNBPlatform);
    }
    
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function transferToAddress(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function TransferETH(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Cannot withdraw the ETH balance to the zero address");
        recipient.transfer(amount);
    }

    // Added to support recovering LP Rewards from other systems
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(this), "Cannot withdraw the staking token");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
    
    receive() external payable {}
    
}