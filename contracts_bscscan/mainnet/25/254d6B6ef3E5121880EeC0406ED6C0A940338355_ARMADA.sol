/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

/**
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.6;

 /*                              >  Armada  <
 *
 *                  Introducing The Time Designed Smart Contract
 *
 *    A HYPER-DEFLATIONARY, WARCHEST POWERED CRYPTOCURRENCY WITH LIQUID FEES
 *
 *                           https://armadacrypto.com
 *                           https://t.me/armadatoken
 *
 //                       AAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 //                       AAAAAAAAAAAAAA  AAAAAAAAAAAAA
 //                       AAAAAAAAAAAAA    AAAAAAAAAAAA
 //                       AAAAAAAAAAAA      AAAAAAAAAAA
 //                       AAAAAAAAAAA        AAAAAAAAAA
 //                       AAAAAAAAAA          AAAAAAAAA
 //                       AAAAAAAAA     AA     AAAAAAAA
 //                       AAAAAAAA     AAAA     AAAAAAA
 //                       AAAAAAA     AAAAAA     AAAAAA
 //                       AAAAAA     AAAAAAAA    AAAAAA
 //                       AAAAA     AAAAAAAAAA    AAAAA
 //                       AAAA     AAAAAAAAAAAA    AAAA
 //                       AAA     AAAAAAAAAAAAAA    AAA
 //                       AAA    AAAAAAAAAAAAAAAA   AAA
 //                       AAA   MMMMMMMMMMMMMMMMM   AAA
 //                       AAA   MMMMMMMMMMMMMMMMM   AAA
 //                       AAA   MMMMMMMM  MMMMMMM   AAA
 //                       AAA   MMMMMMM    MMMMMM   AAA
 //                       AAA   MMMMM       MMMMM   AAA
 //                       AAA   MMMM   MMMM  MMMM   AAA
 //                       AAA   MM   MMMMMMM   MM   AAA
 //                       AAA      MMMMMMMMMMM      AAA
 //                       AAA     MMMMMMMMMMMMMM    AAA
 //                       AAA   MMMMMMMMMMMMMMMMM   AAA
 //                       AAAMMMMMMMMMMMMMMMMMMMMMMMAAA

*                            -  Time is Currency  -
*                           - Armada is on a Voyage -

*/ library SafeMath {

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
        uint256 FleetRewardsFee;
        uint256 warchestfee;
        uint256 MarketingChestFee;
        uint256 MutinyFee;
        bool exist;
        uint256 lastUpdated;
        uint256 nextReductionTime;
        uint256 amount;
    }

    mapping(address => FeeStruct) public fees;
    address[] feeholders;
    mapping (address => uint256) feeholdersIndexes;

    event LogNewFeeHolder(address indexed _userAddress, uint256 _FleetRewardsFee, uint256 _warchestfee,
    uint256 _MarketingChestFee, uint256 _MutinyFee, uint256 _amount);

    event LogUpdateFeeHolder(address indexed _userAddress, uint256 _FleetRewardsFee, uint256 _warchestfee,
    uint256 _MarketingChestFee, uint256 _MutinyFee, uint256 _lastUpdated, uint256 _nextReductionTime, uint256 _amount);


    uint256 internal reductionPerSec = 39; //0.00000039 per second
    uint256 internal reductionDivisor = 10**8; // reduction multiplier
    uint256 internal updateFeeTime = 1; // every second
    uint256 internal FEES_DIVISOR = 10**10; // gives you the true percentage
    // uint256 public secondsInADay = 86400; // total number of seconds in a day
    // uint256 reductionRate = totalFees.div(secondsInADay);
    uint256 public FleetRewardsFee = 2;
    uint256 public warchestfee = 12;
    uint256 public MarketingChestFee = 2;
    uint256 public MutinyFee = 14;

    uint256 internal FleetRewardsFee_ = FleetRewardsFee * reductionDivisor;
    uint256 internal warchestfee_ = warchestfee * reductionDivisor;
    uint256 internal MarketingChestFee_ = MarketingChestFee * reductionDivisor;
    uint256 internal MutinyFee_ = MutinyFee * reductionDivisor;

    uint256 internal baseTotalFees = warchestfee_.add(FleetRewardsFee_).add(MarketingChestFee_);
    uint256 internal baseSellerTotalFees = baseTotalFees.add(MutinyFee_);


    function _getHolderFees (address _userAddress, bool feeReduction) internal view returns
    (uint256, uint256, uint256, uint256, uint256) {

        (uint256 _estimatedFleetRewardsFee, uint256 _estimatedwarchestfee, uint256 _estimatedMarketingChestFee,
            uint256 _estimatedMutinyFee, uint256 _estimatedAccruedFees) = getEstimatedFee(_userAddress);

        // if it's user's first time use the default fee else use the estimate
        uint256 getFleetRewardsFee = !feeReduction ? FleetRewardsFee_ : _estimatedFleetRewardsFee;
        uint256 getwarchestfee = !feeReduction ? warchestfee_ : _estimatedwarchestfee;
        uint256 getMarketingChestFee = !feeReduction ? MarketingChestFee_ : _estimatedMarketingChestFee;

        uint256 getMutinyFee = !feeReduction ? MutinyFee_ :  _estimatedMutinyFee;
        uint256 getReducedFee  = !feeReduction ? reductionPerSec : _estimatedAccruedFees;

        return (
           getFleetRewardsFee,
           getwarchestfee,
           getMarketingChestFee,
           getMutinyFee,
           getReducedFee
            );

    }

    function setFeeHolder(address _userAddress, uint256 _amount) internal {
        uint256 fee = _amount.mul(baseTotalFees).div(FEES_DIVISOR);
        _amount = _amount.sub(fee);
        addFeeHolder(
            _userAddress,
            FleetRewardsFee_,
            warchestfee_,
            MarketingChestFee_,
            MutinyFee_,
            block.timestamp,
            block.timestamp + 1,
            _amount
            );
    }

    function getEstimatedFee (address _userAddress) public view returns(uint256 reduceFleetRewardsFee, uint256 reducewarchestfee,
    uint256 reduceMarketingChestFee, uint256 reduceMutinyFee, uint256 estimatedAccruedFees) {

         // grab the fees that has accrued since last transaction
        uint256 accruedTime = block.timestamp - fees[_userAddress].lastUpdated;
        uint256 accruedFees = accruedTime.mul(reductionPerSec);

        return (
            fees[_userAddress].FleetRewardsFee <= accruedFees ? 0 : fees[_userAddress].FleetRewardsFee.sub(accruedFees),
            fees[_userAddress].warchestfee <= accruedFees ? 0 : fees[_userAddress].warchestfee.sub(accruedFees),
            fees[_userAddress].MarketingChestFee <= accruedFees ? 0 : fees[_userAddress].MarketingChestFee.sub(accruedFees),
            fees[_userAddress].MutinyFee <= accruedFees ? 0 : fees[_userAddress].MutinyFee.sub(accruedFees),
            accruedFees
            );
        }

    /*
    * The reAdjustFees takes into consideration the type of transaction
    * if the token holder is selling it uses the reduced fees.
    * if the holder wants to buy more tokens, the readjustment rate is lower.
    * It basically reduces the accruedFees gotten from getEstimatedFee based on buy
    */
    function calculateBuyingReadjustment(address _userAddress, uint256 _amount, uint256 accruedFees, uint256 _FleetRewardsFee, uint256 _warchestfee,
    uint256 _MarketingChestFee, uint256 _MutinyFee) internal view returns (uint256, uint256, uint256, uint256) {

        uint256 estimatedTotal = _FleetRewardsFee.add(_MarketingChestFee).add(_warchestfee).add(_MutinyFee);
        uint256 previousAmount = fees[_userAddress].amount;

        (uint256 newAccruedFees) = getNewAccruedFees(accruedFees, previousAmount, _amount, estimatedTotal);

        uint256 getFleetRewardsFee = _FleetRewardsFee.add(newAccruedFees);
        uint256 getwarchestfee = _warchestfee.add(newAccruedFees);
        uint256 getMarketingChestFee = _MarketingChestFee.add(newAccruedFees);
        uint256 getMutinyFee =  _MutinyFee.add(newAccruedFees);

        return (
            getFleetRewardsFee,
            getwarchestfee,
            getMarketingChestFee,
            getMutinyFee
            );

    }

    function getNewAccruedFees(uint256 accruedFees, uint256 previousAmount, uint256 _amount, uint256 estimatedTotal)
    private view returns(uint256){
        uint256 nominalAmount = previousAmount.add(_amount);
        nominalAmount = nominalAmount >= previousAmount ? nominalAmount.sub(previousAmount) : previousAmount.sub(nominalAmount);
        nominalAmount = nominalAmount.div(10**18); // divide with decimals of token

        uint256 newAccruedFees;

        if(accruedFees > nominalAmount) {
            newAccruedFees = accruedFees.sub(nominalAmount);
        }
        else if(nominalAmount > accruedFees) {
            newAccruedFees = nominalAmount.sub(accruedFees);
        }
        else if(accruedFees == nominalAmount) {
            newAccruedFees = accruedFees > 100 ? accruedFees.sub(10**2) : accruedFees;
        }

        // new accruedFees cannot be greater than the previous accrued Fee
        if(newAccruedFees > accruedFees) {
            newAccruedFees = accruedFees.sub(10**2);
        }

        // when readjusted it cannot be greater than the sum of the default fees
        // what the default readjusts to, when completed
        if(estimatedTotal.add(accruedFees.mul(4)) > baseSellerTotalFees) {
            newAccruedFees = accruedFees > 100 ? accruedFees.sub(10**2) : accruedFees;
        }

        return newAccruedFees;
    }

    function reAdjustFees(uint256 _amount, uint256 accruedFees, uint256 _FleetRewardsFee, uint256 _warchestfee,  uint256 _MarketingChestFee,
         uint256 _MutinyFee, bool isBuying) internal {

        (uint256 _newFleetRewardsFee, uint256 _newMarketingChestFee, uint256 _newwarchestfee, uint256 _newMutinyFee) =
            calculateBuyingReadjustment (msg.sender, _amount, accruedFees, _FleetRewardsFee, _MarketingChestFee, _warchestfee, _MutinyFee);

         // new amount after readjustment
        (uint256 __amount) = removeFeesFromAmount(msg.sender, _amount, isBuying);

         bool _isBuying = isBuying;
         uint256 _accruedFees = accruedFees;
         uint256 __FleetRewardsFee = _FleetRewardsFee;
         uint256 __MarketingChestFee = _MarketingChestFee;
         uint256 __warchestfee = _warchestfee;
         uint256 __MutinyFee = _MutinyFee;

        updateFeeHolder(
            msg.sender,
            _isBuying ? _newFleetRewardsFee : __FleetRewardsFee.add(_accruedFees),
            _isBuying ? _newwarchestfee : __warchestfee.add(_accruedFees),
            _isBuying ? _newMarketingChestFee : __MarketingChestFee.add(_accruedFees),
            _isBuying ? _newMutinyFee : __MutinyFee.add(_accruedFees),
            block.timestamp,
            block.timestamp + updateFeeTime,
            _isBuying ? fees[msg.sender].amount.add(__amount) : fees[msg.sender].amount.sub(__amount)
            );
    }

    function removeFeesFromAmount(address _userAddress, uint256 _amount, bool isBuying) internal view returns(uint256){

      (uint256 _estimatedFleetRewardsFee, uint256 _estimatedwarchestfee, uint256 _estimatedMarketingChestFee,
            uint256 _estimatedMutinyFee,) = getEstimatedFee(_userAddress);

            // calculate the new amount (minus fees)
         // take fee
         uint256 estimatedFeeTotal = _estimatedFleetRewardsFee.add(_estimatedwarchestfee).add(_estimatedMarketingChestFee);
         estimatedFeeTotal = !isBuying ? estimatedFeeTotal.add(_estimatedMutinyFee) : estimatedFeeTotal;

         uint256 fee = _amount.mul(estimatedFeeTotal).div(FEES_DIVISOR);
        _amount = _amount.sub(fee);
        return _amount;
    }

    function addFeeHolder(address _userAddress, uint256 _FleetRewardsFee, uint256 _warchestfee,
        uint256 _MarketingChestFee, uint256 _MutinyFee, uint256 _lastUpdated, uint256 _nextReductionTime, uint256 _amount) internal {
        require(!isFeeHolder(_userAddress), "Fee Holder already exist!");
        feeholdersIndexes[_userAddress] = feeholders.length;
        feeholders.push(_userAddress);

        fees[_userAddress].FleetRewardsFee = _FleetRewardsFee;
        fees[_userAddress].warchestfee = _warchestfee;
        fees[_userAddress].MarketingChestFee = _MarketingChestFee;
        fees[_userAddress].MutinyFee = _MutinyFee;
        fees[_userAddress].exist = true;
        fees[_userAddress].lastUpdated = _lastUpdated;
        fees[_userAddress].nextReductionTime = _nextReductionTime;
        fees[_userAddress].amount = _amount;

        emit LogNewFeeHolder(
            _userAddress,
            _FleetRewardsFee,
            _warchestfee,
            _MarketingChestFee,
            _MutinyFee,
            _amount
            );
      }

    function updateFeeHolder(address _userAddress, uint256 _FleetRewardsFee, uint256 _warchestfee,
        uint256 _MarketingChestFee, uint256 _MutinyFee, uint256 _lastUpdated, uint256 _nextReductionTime, uint256 _amount) internal {

        require(isFeeHolder(_userAddress), "Fee Holder does not exist!");
        fees[_userAddress].FleetRewardsFee = _FleetRewardsFee;
        fees[_userAddress].warchestfee = _warchestfee;
        fees[_userAddress].MarketingChestFee = _MarketingChestFee;
        fees[_userAddress].lastUpdated = _lastUpdated;
        fees[_userAddress].nextReductionTime = _nextReductionTime;
        fees[_userAddress].amount = _amount;

        emit LogUpdateFeeHolder(
            _userAddress,
            _FleetRewardsFee,
            _warchestfee,
            _MarketingChestFee,
            _MutinyFee,
            _lastUpdated,
            _nextReductionTime,
            _amount
          );
      }

    function isFeeHolder(address userAddress) public view returns(bool isIndeed) {
        if(feeholders.length == 0) return false;
        return (fees[userAddress].exist);
    }

    function getFeeholder(address _userAddress) public view returns(uint256 _FleetRewardsFee, uint256 _warchestfee,
        uint256 _MarketingChestFee, uint256 _MutinyFee, uint256 _lastUpdated, uint256 _nextReductionTime, uint256 _amount)
      {
        return(
          fees[_userAddress].FleetRewardsFee,
          fees[_userAddress].warchestfee,
          fees[_userAddress].MarketingChestFee,
          fees[_userAddress].MutinyFee,
          fees[_userAddress].lastUpdated,
          fees[_userAddress].nextReductionTime,
          fees[_userAddress].amount
          );
    }

    function getFeeHoldersCount() public view returns(uint256 count) {
        return feeholders.length;
 }

}



contract ARMADA is IERC20Metadata, DepreciatingFees, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address public MarketingChestAddress = 0x6D07c5Bd49042e160A57B198d7afF472aA3b1F69; // MarketingChest Address
    address internal deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public presaleAddress = address(0);

    string constant _name = "Armada";
    string constant _symbol = "ARMD";
    uint8 constant _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _totalSupply = 1000000000000 * 10**18;
    uint256 internal _reflectedSupply = (MAX - (MAX % _totalSupply));

    uint256 private collectedFeeTotal;

    uint256 public maxTxAmount = _totalSupply / 1000; // 0.5% of the total supply
    uint256 public maxWalletBalance = _totalSupply / 50; // 2% of the total supply

    bool public autoWarChestOpen = true;
    uint256 public autoWarchestAmount = 1 * 10**18;
    bool public takeFeeEnabled = true;
    bool public isInPresale = false;

    uint256 public MarketingChestDivisor = MarketingChestFee;

    bool private swapping;
    bool public swapEnabled = true;
    uint256 public swapTokensAtAmount = 2000000 * (10**18);

    IPancakeV2Router public router;
    address public pair;

    mapping (address => uint256) internal _reflectedBalances;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromRewards;
    address[] private _excluded;

    event UpdatePancakeswapRouter(address indexed newAddress, address indexed oldAddress);
    event WarChestOpenUpdated(bool enabled);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event MarketingChestWalletUpdated(address indexed newMarketingChestWallet, address indexed oldMarketingChestWallet);

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor () {
        _reflectedBalances[owner()] = _reflectedSupply;

        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        router = _newPancakeRouter;

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude the owner and this contract from rewards
        _exclude(owner());
        _exclude(address(this));

        // exclude the pair address from rewards - we don't want to redistribute
        _exclude(pair);
        _exclude(deadAddress);

        _approve(owner(), address(router), ~uint256(0));

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

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

    function transfer(address recipient, uint256 amount) external override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
        }

    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
        }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
        }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool){
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
         * in FleetRewards
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
        require(owner != address(0), "BaseFleetRewardsToken: approve from the zero address");
        require(spender != address(0), "BaseFleetRewardsToken: approve to the zero address");

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
            feesSum = isBuying ? baseTotalFees : baseSellerTotalFees;
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

    function getautoWarchestAmount() external view returns (uint256) {
        return autoWarchestAmount;
    }

    function totalCollectedFees() external view returns (uint256) {
        return collectedFeeTotal;
    }

     function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
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
        warchestfee = 0;
        MarketingChestFee = 0;
        FleetRewardsFee = 0;
        MutinyFee = 0;
        maxTxAmount = 1000000000000 * (10**18);
        maxWalletBalance = 1000000000000 * (10**18);
    }

    function afterPreSale() external onlyOwner {
        takeFeeEnabled = true;
        swapEnabled = true;
        isInPresale = false;
        warchestfee = 12;
        MarketingChestFee = 2;
        FleetRewardsFee = 2;
        MutinyFee = 14;
        maxTxAmount = 40142 * (10**18);
        maxWalletBalance = 4014201 * (10**18);
    }

    function setWarChestEnabled(bool _enabled) external onlyOwner {
        autoWarChestOpen = _enabled;
        emit WarChestOpenUpdated(_enabled);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled  = _enabled;
    }

    function OpenWarChest(uint256 amount) public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(!swapping, "ARMADA: A swapping process is currently running, wait till that is complete");
        require(contractBalance >= amount, "ARMADA: Insufficient Funds");

        warChestTokens(amount);
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

    function updateMarketingChestFee(uint256 newFee) external onlyOwner {
        require(newFee >= 0 && newFee <= 10, "MarketingChest Fee must be between 0 and 10");
        MarketingChestFee = newFee;
    }

    function updatewarchestfee(uint256 newFee) external onlyOwner {
        require(newFee >= 0 && newFee <= 20, "Buy Back Fee must be between 0 and 10");
        warchestfee = newFee;
    }

    function updateFleetRewardsFee(uint256 newFee) external onlyOwner {
        require(newFee >= 0 && newFee <= 10, "FleetRewards Fee must be between 0 and 10");
        FleetRewardsFee = newFee;
    }

    function setMarketingChestDivisor(uint256 divisor) external onlyOwner() {
        MarketingChestDivisor = divisor;
    }

    function setReductionPerSec(uint256 persec) external onlyOwner() {
        reductionPerSec = persec;
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


    function _takeFee(uint256 amount, uint256 currentRate, uint256 fee, address recipient) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rAmount = tAmount.mul(currentRate);

        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rAmount);
        if(_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tAmount);

        collectedFeeTotal = collectedFeeTotal.add(tAmount);
    }

    function _transferTokens(address sender, address recipient, uint256 amount, bool takeFee, bool feeReduction) private {

        // grab the estimated reduced fees
            (uint256 reduceFleetRewardsFee, uint256 reducewarchestfee, uint256 reduceMarketingChestFee,
        uint256 reduceMutinyFee, uint256 estimatedAccruedFees) = _getHolderFees(msg.sender, feeReduction);


         uint256 sumOfFees = isInPresale ? 0 : reduceFleetRewardsFee.add(reduceMarketingChestFee).add(reducewarchestfee);

         bool isBuying = true;

        if(recipient == pair) {
            sumOfFees = isInPresale ? 0 : sumOfFees.add(reduceMutinyFee);
            isBuying  = false;
        }

        if(feeReduction) {
            // Adjust the Fee struct to reflect the new transaction
            reAdjustFees(amount, estimatedAccruedFees, reduceFleetRewardsFee, reducewarchestfee, reduceMarketingChestFee, reduceMutinyFee, isBuying);
        }

        if ( !takeFee ){ sumOfFees = 0; }

        processReflectedBal(sender, recipient, amount, sumOfFees, isBuying, reduceFleetRewardsFee, reducewarchestfee, reduceMarketingChestFee, reduceMutinyFee);

    }

    function processReflectedBal (address sender, address recipient, uint256 amount, uint256 sumOfFees, bool isBuying,
    uint256 reduceFleetRewardsFee, uint256 reducewarchestfee, uint256 reduceMarketingChestFee, uint256 reduceMutinyFee) internal {

        (uint256 rAmount, uint256 rTransferAmount, uint256 tAmount,
        uint256 tTransferAmount, uint256 currentRate ) = _getValues(amount, sumOfFees);
        bool _isBuying = isBuying;

        theReflection(sender, recipient, rAmount, rTransferAmount, tAmount, tTransferAmount);

        _takeFees(amount, currentRate, sumOfFees, reduceFleetRewardsFee, reducewarchestfee, reduceMarketingChestFee, reduceMutinyFee, _isBuying);

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


    function _takeFees(uint256 amount, uint256 currentRate, uint256 sumOfFees, uint256 reduceFleetRewardsFee, uint256 reducewarchestfee,
    uint256 reduceMarketingChestFee,  uint256 reduceMutinyFee, bool isBuying) private {
        if ( sumOfFees > 0 && !isInPresale ){
            _redistribute( amount, currentRate, reduceFleetRewardsFee);  // redistribute to holders
            _takeFee( amount, currentRate, reducewarchestfee, address(this)); // buy back fee
            _takeFee( amount, currentRate, reduceMarketingChestFee, address(this)); // MarketingChest fee

            if(!isBuying) {
                _takeFee( amount, currentRate, reduceMutinyFee, address(this));
                }
        }
    }

    function _beforeTokenTransfer() private {
        // also adjust fees - add later

        if ( !isInPresale ){
            uint256 contractTokenBalance = balanceOf(address(this));
            // swap
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;

            if (!swapping && canSwap && swapEnabled) {
                swapping = true;
                swapTokens(contractTokenBalance);
                swapping = false;
            }

            uint256 warChestBalance = address(this).balance;
            // auto buy back
            if(autoWarChestOpen && warChestBalance >= autoWarchestAmount && !swapping) {
                warChestBalance = autoWarchestAmount;

                warChestTokens(warChestBalance.div(100));
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

         if(!isInPresale) {
           // create a new fee holder
            if(!isFeeHolder(msg.sender)) {
               setFeeHolder(msg.sender, amount); // create a new fee holder
               feeReduction = false;
            }
         }
         // if contract is in presale, then there should be no fee reduction
        if(isInPresale){ feeReduction = false; }

        _beforeTokenTransfer();
        _transferTokens(sender, recipient, amount, _isTakeFee, feeReduction );

    }


    function swapTokens(uint256 contractTokenBalance) private {

        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        //Send to MarketingChest address
        transferToAddressBNB(payable(MarketingChestAddress), transferredBalance.div(10**2).mul(MarketingChestDivisor));

    }

    function warChestTokens(uint256 amount) private {
    	if (amount > 0) {
    	    swapBNBForTokens(amount);
	    }
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

    function swapBNBForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

      // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp
        );

        emit SwapETHForTokens(amount, path);
    }

    function transferToAddressBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

}

//       d8888 8888888b.  888b     d888        d8888 8888888b.        d8888
//      d88888 888   Y88b 8888b   d8888       d88888 888  "Y88b      d88888
//     d88P888 888    888 88888b.d88888      d88P888 888    888     d88P888
//    d88P 888 888   d88P 888Y88888P888     d88P 888 888    888    d88P 888
//   d88P  888 8888888P"  888 Y888P 888    d88P  888 888    888   d88P  888
//  d88P   888 888 T88b   888  Y8P  888   d88P   888 888    888  d88P   888
// d8888888888 888  T88b  888   "   888  d8888888888 888  .d88P d8888888888
//d88P     888 888   T88b 888       888 d88P     888 8888888P" d88P     888