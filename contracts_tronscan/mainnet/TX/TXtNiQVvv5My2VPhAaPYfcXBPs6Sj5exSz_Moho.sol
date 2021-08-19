//SourceUnit: Address.sol

pragma solidity 0.5.8;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        // 空字符串hash值
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        //内联编译（inline assembly）语言，是用一种非常底层的方式来访问EVM
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


//SourceUnit: SafeERC20.sol

pragma solidity 0.5.8;

import "./Address.sol";
import "./SafeMath.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        //if (returndata.length > 0) {
          //  require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        //}
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: SafeMath.sol

pragma solidity 0.5.8;

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


//SourceUnit: moho.sol

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";

contract LiquidityStake {
    function isJoinStakeOf(address user) public view returns(bool);
    function getInviteAddressOf(address account) public view returns(address);
}

contract Moho is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Define box values
    uint256 private decimals = 6;
    uint256 public boxTrxOne = 3000 * 10 ** decimals;
    uint256 public boxTrxTwo = 12000 * 10 ** decimals;
    uint256 public boxTrxThree = 30000 * 10 ** decimals;
    uint256 public boxUsdtOne = 300 * 10 ** decimals;
    uint256 public boxUsdtTwo = 1000 * 10 ** decimals;
    uint256 public boxUsdtThree = 3000 * 10 ** decimals;

//     uint256 private decimals = 6;
//     uint256 public boxTrxOne = 3 * 10 ** decimals;
//     uint256 public boxTrxTwo = 120 * 10 ** decimals;
//     uint256 public boxTrxThree = 300 * 10 ** decimals;
//     uint256 public boxUsdtOne = 3 * 10 ** decimals;
//     uint256 public boxUsdtTwo = 10 * 10 ** decimals;
//     uint256 public boxUsdtThree = 30 * 10 ** decimals;

    // Related address information
    ERC20 public usdtTokenContract;
    address public technologyAddress;
    address public nodeDistributionAddress;

    // Calculation of relevant parameters
    uint256 public luckDrawStartTime;
    mapping(address => uint256) accountLastLuckDrawTime;
    mapping(address => uint256) accountTodayLuckDrawCount;
    uint256 public wheelTotal = 150;
    uint256 public wheelMaxWin = 15;
    uint256 public wheelNowWin = 0;
    uint256 public wheelCount = 1;
    uint256 public randNonce = 0;
    uint256 public wheelNowRewardMaximum = 0;

    // Statistics of winning data
    uint256 public luckDrawWinTotalCount = 0;
    uint256 public luckDrawWinTotalTrx = 0;
    uint256 public luckDrawWinTotalUsdt = 0;
    mapping(address => uint256) luckDrawWinUserTrx;
    mapping(address => uint256) luckDrawWinUserUsdt;

    uint256 public priceNowTrxRea = 1 * 10 ** decimals;// 1TRX = 1REA
    uint256 public priceNowUsdtRea = 14 * 10 ** decimals;// 1U = 14REA
    mapping(address => uint256) luckDrawUsePledgedReaUser;
    uint256 public luckDrawUsePledgedReaTotal = 0;

    address public accountAdmin;
    address public firstLuckDrawAddress;
    mapping(address => address) inviteAddress;

    // Switch Settings
    bool public luckDrawIsStart = false;
    bool public mohoPledgeIsStart = false;
    uint256 private resultAmount;
    uint256 public luckDrawIsShow = 3; // 0=均不显示；1=仅显示TRX盒子；2=仅显示USDT盒子；3=显示TRX和USDT盒子

    // mohePledge relevant
    ERC20 public reaTokenContract;
    mapping(address => uint256) userMohoPledgedRea;
    mapping(address => uint256) userMohoPledgedCount;
    mapping(address => uint256) userMohoLuckDrawCount;
    mapping(address => uint256) effectivePromotionCount;
    uint256 public mohoPledgedReaTotal;

    mapping(uint256 => mapping(address => MohoLuckDrawOrder)) public mohoLuckDrawOrders;
    struct MohoLuckDrawOrder {
        uint256 index;
        bool isExist;
        uint256 mohoLuckDrawTime;
        uint256 mohoLuckDrawReaAmount;
        bool isPledge;
        uint256 mohoPledgeIndex;
        uint256 usetPledgeLevel;
        uint256 cosmeticEarnings;
    }
    mapping(uint256 => mapping(address => MohoPledgeOrder)) public mohoPledgeOrders;
    struct MohoPledgeOrder {
        bool isExist;
        uint256 pledgeLevel;
        uint256 cosmeticEarnings;
        uint256 mohoPledgeAmount;
        uint256 pledgeTime;
        uint256 mohoTakeTokenTime;
        uint256 lastWithdrawalTime;
        uint256 luckDrawIndex;
    }
    mapping(address => uint256) userMohoPledgedEarnedIncome;
    mapping(address => uint256) accountDynamicBenefits;

    LiquidityStake public liquidityStakeContract;

    // Add event log
    event  LuckDraw(address indexed account,string boxType,uint256 num,bool isWin,uint256 resultAmount);
    event  RandomNumber(address indexed account,uint256 num);
    event  MohoPledge(address indexed account,uint256 pledgeLevel,uint256 num,uint256 cosmeticEarnings);
    event  MohoTakeToken(address indexed account,uint256 ordersIndex,uint256 num);
    event  MohoTakeProfit(address indexed account,uint256 ordersIndex,uint256 num);
    event  GetSedimentUsdt(address indexed account,address indexed to,uint256 num);
    event  GetSedimentRea(address indexed account,address indexed to,uint256 num);
    event  GetSedimentTrx(address indexed account,address indexed to,uint256 num);
    event  Winnings(address indexed account,string boxType,uint256 num,uint256 winnings,string content,uint256 resultAmount);
    event  BindingInvitation(address indexed sender, address indexed invite,uint256 time);
    event  Giving100u(address indexed sender, uint256 num);
    event  StaticIncome(address indexed sender, address indexed direct,uint256 resultAmount,uint256 luckDrawAmount,uint256 num,string content);
    event  EffectivePromotionCount(address indexed sender, address indexed pledge,uint256 changeNum,uint256 nowNum);
    event  DynamicBenefits(address indexed sender, address indexed pledge,uint256 hierarchy,uint256 extractionYield,uint256 teamReturns);
    event  WithdrawDynamicBenefits(address indexed sender, uint256 num);

    constructor(address _usdtTokenContract,address _reaTokenContract) public {
        usdtTokenContract = ERC20(_usdtTokenContract);
        reaTokenContract = ERC20(_reaTokenContract);
    }

    // create LiquidityStake Contract
    function createLiquidityStakeContract(address _liquidityStakeContract) public onlyOwner returns (string memory result) {
        liquidityStakeContract = LiquidityStake(_liquidityStakeContract);
        return "createLiquidityStakeContract success";// return result
    }

    //==============================Giving100uOrder============================================
    function giving100u() public returns (string memory result) {
        // Open the mohePledge or not
        require(mohoPledgeIsStart,"setMohoPledgeIsStart: Is false.");
        // Have you received 100U as a gift
        uint256 luckDrawIndex = uint256(2021);
        MohoLuckDrawOrder storage luckDraw = mohoLuckDrawOrders[luckDrawIndex][msg.sender];
        require(luckDraw.isExist==false,"luckDrawIndex: The current raffle order ID does is exist.");
        // Write to claim REA quota
        uint256 givingAmount = 100 * 10 ** decimals;
        uint256 returnAmountUserChangeRea = givingAmount.mul(priceNowUsdtRea).div(1000000);
        mohoLuckDrawOrders[luckDrawIndex][msg.sender] = MohoLuckDrawOrder(luckDrawIndex,true,block.timestamp,returnAmountUserChangeRea,false,uint256(0),uint256(1),uint256(3));
        luckDrawUsePledgedReaTotal += returnAmountUserChangeRea;
        luckDrawUsePledgedReaUser[msg.sender] += returnAmountUserChangeRea;

        emit Giving100u(msg.sender,returnAmountUserChangeRea);// set log
        return "giving100u success";// return result
    }
    //==============================Ownership operation related============================================
    // Obtain usdt deposited in the contract; Only the contract ownership address can be called; Current quantity and address can be selected.
    function getSedimentUsdt(address to,uint256 amount) public onlyOwner returns (string memory result) {
        // Determine whether the contract USDT balance is sufficient
        require(usdtTokenContract.balanceOf(address(this))>=amount,"usdtTokenContract: Insufficient balance of USDT TOKEN available to contract.");
        usdtTokenContract.safeTransfer(to,amount);// Transfer usdt to destination address
        emit GetSedimentUsdt(msg.sender,to,amount);// set log
        return "getSedimentUsdt success";// return result
    }
    // Obtain trx deposited in the contract; Only the contract ownership address can be called; Current quantity and address can be selected.
    function getSedimentTrx(address to,uint256 amount) public onlyOwner returns (string memory result) {
        // Determine whether the contract TRX balance is sufficient
        require(address(this).balance>=amount,"TRX: Insufficient balance of TRX available to contract.");
        address(uint160(to)).transfer(amount);// Transfer trx to destination address
        emit GetSedimentTrx(msg.sender,to,amount);// set log
        return "getSedimentTrx success";// return result
    }
    function getSedimentRea(address to,uint256 amount) public onlyOwner returns (string memory result) {
        // Determine whether the contract REA balance is sufficient
        require(reaTokenContract.balanceOf(address(this))>=amount,"reaTokenContract: Insufficient balance of REA TOKEN available to contract.");
        reaTokenContract.safeTransfer(to,amount);// Transfer rea to destination address
        emit GetSedimentRea(msg.sender,to,amount);// set log
        return "getSedimentRea success";// return result
    }
    //==============================mohoTakeProfit============================================
    // Withdrawal of income
    function mohoTakeProfit(uint256 ordersIndex) public returns (string memory result) {
        // Does the current user have a box pledge
        require(userMohoPledgedCount[msg.sender]>=1,"userMohoPledgedCount: Box Pledge does not exist for the current user.");
        // The current user box pledge number must be greater than 0
        require(userMohoPledgedRea[msg.sender]>0,"userMohoPledgedRea: The total number of boxes pledged by the current user must be 0.");
        // Get order details
        MohoPledgeOrder storage order = mohoPledgeOrders[ordersIndex][msg.sender];
        require(order.isExist==true,"order: The current subscript user order does not exist.");

        // Earned income
        uint256 nowTime = block.timestamp;
        uint256 diff = nowTime.sub(order.lastWithdrawalTime);
        uint256 mohoTakeProfitAmount = uint256(0);
        require(diff>3,"diff: No income available.");
        // Number of bonus days
        uint256 countDay = 0;
        if(diff>3){
             countDay = diff.div(3);
             mohoTakeProfitAmount = order.mohoPledgeAmount.mul(order.cosmeticEarnings).div(1000).mul(countDay).mul(95).div(100);// ProfitAmount set 95%
             mohoTakeProfitAmount = mohoTakeProfitAmount.div(28800);
        }
        mohoPledgeOrders[ordersIndex][msg.sender].lastWithdrawalTime += countDay.mul(uint256(3));

        // Distribute revenue to users
        reaTokenContract.safeTransfer(address(msg.sender),mohoTakeProfitAmount);

        userMohoPledgedEarnedIncome[msg.sender] += mohoTakeProfitAmount;
        emit MohoTakeProfit(msg.sender,ordersIndex,mohoTakeProfitAmount);

        dynamicBenefits(mohoTakeProfitAmount);

        return "mohoTakeProfit success";
    }

    // withdraw DynamicBenefits
    function withdrawDynamicBenefits() public returns (string memory result) {
        // Account team dynamic income balance judgment
        require(accountDynamicBenefits[msg.sender]>0,"accountDynamicBenefits: Account team dynamic return is equal to 0.");
        reaTokenContract.safeTransfer(address(msg.sender),accountDynamicBenefits[msg.sender]);// Transfer rea to destination address
        emit WithdrawDynamicBenefits(msg.sender,accountDynamicBenefits[msg.sender]);
        accountDynamicBenefits[msg.sender] = uint256(0);// All extracts

        return "withdrawDynamicBenefits success";
    }

    // dynamicBenefits => mohoTakeToken + mohoTakeProfit
    function dynamicBenefits(uint256 mohoTakeProfitAmount) private {
        // Define initial values
        address directN = address(msg.sender);
        uint256 senderTrx = userMohoPledgedRea[msg.sender].mul(10000).div(priceNowTrxRea);
        // Up to 12 generations
       for(uint256 levelN = 1; levelN < 13; levelN++) {
            if(inviteAddress[directN]!=address(0) && inviteAddress[directN]!=firstLuckDrawAddress){
                  // Get my supervisor's address
                  directN = inviteAddress[directN];
                  uint256 lastAccountDynamicBenefits = mohoTakeProfitAmount;
                  if(userMohoPledgedCount[directN]>=1){
                          if(effectivePromotionCount[directN]>=1){
                                  uint256 ratio = uint256(2);
                                  // directN in Pledged
                                  if(effectivePromotionCount[directN]<=5){
                                      ratio += effectivePromotionCount[directN];
                                  }else{
                                      ratio += uint256(5);
                                  }

                                  // levelN 1=4；2=5；3=6；4=9；5=12
                                  uint256 levelMax = uint256(4);
                                  if(effectivePromotionCount[directN]==2){
                                      levelMax = uint256(5);
                                  }else if(effectivePromotionCount[directN]==3){
                                      levelMax = uint256(6);
                                  }else if(effectivePromotionCount[directN]==4){
                                      levelMax = uint256(9);
                                  }else if(effectivePromotionCount[directN]>=5){
                                      levelMax = uint256(12);
                                  }

                                  // Within acceptable algebra
                                  if(levelN<=levelMax){
                                      // Team dynamic revenue - burn calculation: my box pledge amount (in TRX)/superior referral box pledge amount (in TRX)
                                      uint256 directNTrx = userMohoPledgedRea[directN].mul(10000).div(priceNowTrxRea);
                                      uint256 burnsCoefficient = directNTrx.mul(100).div(senderTrx);// Combustion coefficient %
                                      if(burnsCoefficient>=100){
                                           burnsCoefficient = uint256(100);
                                      }else if(burnsCoefficient<=1){
                                           burnsCoefficient = uint256(1);
                                      }
                                      lastAccountDynamicBenefits = lastAccountDynamicBenefits.mul(burnsCoefficient).div(100);  // Burn calculation is performed on the radix

                                      // Calculate rewards for superiors
                                      for(uint256 j = 0; j < levelN; j++){
                                          lastAccountDynamicBenefits = lastAccountDynamicBenefits.mul(ratio).div(10);// Algebraic levels are obtained by power
                                      }
                                      accountDynamicBenefits[directN] += lastAccountDynamicBenefits;
                                      emit DynamicBenefits(msg.sender, directN,levelN,mohoTakeProfitAmount,lastAccountDynamicBenefits);
                                  }
                          }
                  }
            }else{
                 directN = inviteAddress[directN];
                 if(directN == firstLuckDrawAddress){
                      uint256 lastAccountDynamicBenefits = mohoTakeProfitAmount;
                      uint256 ratio = uint256(7);   // 70%
                      // Calculate rewards for superiors
                      for(uint256 j = 0; j < levelN; j++){
                          lastAccountDynamicBenefits = lastAccountDynamicBenefits.mul(ratio).div(10);// Algebraic levels are obtained by power
                      }
                      accountDynamicBenefits[directN] += lastAccountDynamicBenefits;
                      emit DynamicBenefits(msg.sender, directN,levelN,mohoTakeProfitAmount,lastAccountDynamicBenefits);
                 }// The root node can not invest

                 levelN = 13;// Ending the loop
            }
       }
    }

    // Get moho NowOrder Profit
    function mohoNowOrderProfitOf(address mohoTakeTokenAddress,uint256 ordersIndex) public view returns(uint256) {
        MohoPledgeOrder storage order = mohoPledgeOrders[ordersIndex][mohoTakeTokenAddress];

        if(!order.isExist){
            return 0;// fasle = > 0
        }
        // Earned income
        uint256 nowTime = block.timestamp;
        uint256 diff = nowTime.sub(order.lastWithdrawalTime);
        uint256 mohoTakeProfitAmount = uint256(0);
        if(diff>3){
             // Number of bonus days
             uint256 countDay = diff.div(3);
             mohoTakeProfitAmount = order.mohoPledgeAmount.mul(order.cosmeticEarnings).div(1000).mul(countDay);// ProfitAmount set 95%
             mohoTakeProfitAmount = mohoTakeProfitAmount.div(28800);
        }
        return mohoTakeProfitAmount;
    }
    //==============================mohoTakeToken============================================
    // Extract the principal
    function mohoTakeToken(uint256 ordersIndex) public returns (string memory result) {
        // Does the current user have a box pledge
        require(userMohoPledgedCount[msg.sender]>=1,"userMohoPledgedCount: Box Pledge does not exist for the current user.");
        // The current user box pledge number must be greater than 0
        require(userMohoPledgedRea[msg.sender]>0,"userMohoPledgedRea: The total number of boxes pledged by the current user must be 0.");
        // Get order details
        MohoPledgeOrder storage order = mohoPledgeOrders[ordersIndex][msg.sender];
        require(order.isExist==true,"order: The current subscript user order does not exist.");

        // update luckDrawIndex information
        uint256 luckDrawIndex = mohoPledgeOrders[ordersIndex][msg.sender].luckDrawIndex;
        mohoLuckDrawOrders[luckDrawIndex][msg.sender].isPledge = false;
        mohoLuckDrawOrders[luckDrawIndex][msg.sender].mohoPledgeIndex = uint256(0);

        // Update order information
        mohoPledgeOrders[ordersIndex][msg.sender].isExist = false;
        mohoPledgeOrders[ordersIndex][msg.sender].mohoTakeTokenTime = block.timestamp;
        mohoPledgeOrders[ordersIndex][msg.sender].luckDrawIndex = uint256(0);

        // Earned income
        uint256 nowTime = block.timestamp;
        uint256 diff = nowTime.sub(order.lastWithdrawalTime);
        uint256 mohoTakeProfitAmount = uint256(0);
        // Number of bonus days
        uint256 countDay = 0;
        if(diff>3){
             countDay = diff.div(3);
             mohoTakeProfitAmount = order.mohoPledgeAmount.mul(order.cosmeticEarnings).div(1000).mul(countDay).mul(95).div(100);// ProfitAmount set 95%
             mohoTakeProfitAmount = mohoTakeProfitAmount.div(28800);
        }
        mohoPledgeOrders[ordersIndex][msg.sender].lastWithdrawalTime += countDay.mul(uint256(3));

        // Distribute revenue to users
        reaTokenContract.safeTransfer(address(msg.sender),mohoTakeProfitAmount);

        userMohoPledgedEarnedIncome[msg.sender] += mohoTakeProfitAmount;
        emit MohoTakeProfit(msg.sender,ordersIndex,mohoTakeProfitAmount);

        if(mohoTakeProfitAmount>0){
             dynamicBenefits(mohoTakeProfitAmount);
        }

        // Transfer the principal to the user
        reaTokenContract.safeTransfer(address(msg.sender),order.mohoPledgeAmount.mul(95).div(100));// mohoPledgeAmount set 95%

        // Update pledge statistics
        mohoPledgedReaTotal -= order.mohoPledgeAmount;
        userMohoPledgedRea[msg.sender] -= order.mohoPledgeAmount;
        userMohoPledgedCount[msg.sender] -= uint256(1);

        // set log
        emit MohoTakeToken(msg.sender,ordersIndex,order.mohoPledgeAmount);

        // effectivePromotionCount -1  => Cancellation of the last pledge reduces the effective number of direct referees
        if(userMohoPledgedCount[msg.sender]<1){
              address direct1 = inviteAddress[msg.sender];
              effectivePromotionCount[direct1] -= uint256(1);
              emit EffectivePromotionCount(msg.sender,direct1,uint256(0),effectivePromotionCount[direct1]);
        }

        return "mohoTakeToken + mohoTakeProfit success";
    }

    // Get userMoho Pledged Earned Income
    function userMohoPledgedEarnedIncomeOf(address mohoTakeTokenAddress) public view returns(uint256) {
        return userMohoPledgedEarnedIncome[mohoTakeTokenAddress];
    }

    // Get account DynamicBenefits
    function accountDynamicBenefitsOf(address mohoTakeTokenAddress) public view returns(uint256) {
        return accountDynamicBenefits[mohoTakeTokenAddress];
    }
   //==============================mohePledge============================================

    // Box pledge function
    function mohoPledge(address _inviteAddress,uint256 luckDrawIndex) public returns (string memory result) {
        // Open the mohePledge or not
        require(mohoPledgeIsStart,"setMohoPledgeIsStart: Is false.");

        // Creation address does not need to be filled in
        if(firstLuckDrawAddress != msg.sender){
                if(inviteAddress[msg.sender]==address(0)){
                    if(liquidityStakeContract.getInviteAddressOf(msg.sender)!=address(0)){
                        _inviteAddress =   liquidityStakeContract.getInviteAddressOf(msg.sender);
                    }else{
                        if(_inviteAddress != firstLuckDrawAddress){ // The root node can not invest
                          // Inviteaddress must have participated in the pledge address
                          require(liquidityStakeContract.isJoinStakeOf(_inviteAddress)== true || userMohoPledgedCount[_inviteAddress] >=1, "The invitational address has no promotion authority");
                        }
                    }
                    // Write invitation relationship
                    inviteAddress[msg.sender]  = _inviteAddress;

                    emit BindingInvitation(msg.sender, _inviteAddress,block.timestamp);
                }
        }

        // Up to five simultaneous pledges
        if(luckDrawIndex<2021){
            if(mohoLuckDrawOrders[2021][msg.sender].isPledge){
                require(userMohoPledgedCount[msg.sender]<8,"userMohoPledgedCount: Up to seven simultaneous pledges.");
            }else{
                require(userMohoPledgedCount[msg.sender]<7,"userMohoPledgedCount: Up to seven simultaneous pledges.");
            }
        }
        // Set luckDraw mohoLuckDrawReaAmount
        MohoLuckDrawOrder storage luckDraw = mohoLuckDrawOrders[luckDrawIndex][msg.sender];
        require(luckDraw.isExist==true,"luckDrawIndex: The current raffle order ID does not exist.");
        require(luckDraw.isPledge==false,"luckDrawIndex: The current raffle order ID has been pledged.");
        uint256 mohoPledgeAmount = luckDraw.mohoLuckDrawReaAmount;
        // Determine whether the user REA balance is sufficient
        require(reaTokenContract.balanceOf(msg.sender)>=mohoPledgeAmount,"reaTokenContract: Insufficient balance of REA TOKEN available to users.");
        // The user box draw can pledge whether the balance is sufficient
        require(luckDrawUsePledgedReaUser[msg.sender].sub(userMohoPledgedRea[msg.sender])>=mohoPledgeAmount,"userMohoPledgedCount: The user box lottery can pledge insufficient balance.");

        // Calculate the pledge level
        /* uint256 pledgeLevelTwo = boxUsdtTwo.mul(1).div(3).mul(priceNowUsdtRea).div(1000000);
        uint256 pledgeLevelThree = boxUsdtThree.mul(1).div(3).mul(priceNowUsdtRea).div(1000000); */
        uint256 usetPledgeLevel = luckDraw.usetPledgeLevel;
        uint256 cosmeticEarnings = luckDraw.cosmeticEarnings;
        /* if(mohoPledgeAmount>=pledgeLevelThree){
            usetPledgeLevel = uint256(3); cosmeticEarnings = uint256(7);
        }else if(mohoPledgeAmount>=pledgeLevelTwo){
            usetPledgeLevel = uint256(2); cosmeticEarnings = uint256(5);
        }else{
            usetPledgeLevel = uint256(1); cosmeticEarnings = uint256(3);
        } */

        // Transfer the user REA to the contract
        reaTokenContract.safeTransferFrom(address(msg.sender),address(this),mohoPledgeAmount);

        // set order max = 8 = 7 + 1
        for(uint256 i = 0; i < 8; i++) {
            MohoPledgeOrder storage order = mohoPledgeOrders[i][msg.sender];
            if(order.isExist==false){
                mohoPledgeOrders[i][msg.sender] = MohoPledgeOrder(true,usetPledgeLevel,cosmeticEarnings,mohoPledgeAmount,block.timestamp,block.timestamp,block.timestamp,luckDrawIndex);
                // Update luckDraw
                luckDraw.isPledge = true;
                luckDraw.mohoPledgeIndex = i ;

                i = 8;// Write ends the current loop
            }
        }

        // effectivePromotionCount +1  => Add effective number of direct referees for the first pledge
        if(userMohoPledgedCount[msg.sender]<1){
              address direct1 = inviteAddress[msg.sender];
              effectivePromotionCount[direct1] += uint256(1);
              emit EffectivePromotionCount(msg.sender,direct1,uint256(1),effectivePromotionCount[direct1]);
        }

        // mohoPledged statistical
        mohoPledgedReaTotal += mohoPledgeAmount;
        userMohoPledgedRea[msg.sender] += mohoPledgeAmount;
        userMohoPledgedCount[msg.sender] += uint256(1);

        // set log
        emit MohoPledge(msg.sender,usetPledgeLevel,mohoPledgeAmount,cosmeticEarnings);

        return "mohoPledge success";
    }

    // Get user MohoPledged Rea
    function userMohoPledgedReaOf(address mohoPledgeAddress) public view returns(uint256) {
        return userMohoPledgedRea[mohoPledgeAddress];
    }

    // Get user MohoPledged Count
    function userMohoPledgedCountOf(address mohoPledgeAddress) public view returns(uint256) {
        return userMohoPledgedCount[mohoPledgeAddress];
    }

    // Get effective Promotion Count
    function effectivePromotionCountOf(address mohoPledgeAddress) public view returns(uint256) {
        return effectivePromotionCount[mohoPledgeAddress];
    }

    // Update setLuckDrawIsStart
    function setMohoPledgeIsStart(bool _mohoPledgeIsStart) public onlyOwner {
        mohoPledgeIsStart = _mohoPledgeIsStart;
    }

    // Update setLuckDrawIsStart
    function setLuckDrawIsStart(bool _luckDrawIsStart) public onlyOwner {
        luckDrawIsStart = _luckDrawIsStart;
        luckDrawStartTime = block.timestamp;// Set luckDrawStartTime
    }

    // Update luckDrawIsShow
    function setLuckDrawIsShow(uint256 _luckDrawIsShow) public onlyOwner {
        luckDrawIsShow = _luckDrawIsShow;
    }
    //==============================luckDraw============================================
    // Set the creation node address
    function setFirstLuckDrawAddress(address _firstLuckDrawAddress) public onlyOwner {
        firstLuckDrawAddress = _firstLuckDrawAddress;
    }
    // Get the inviter's address
    function getInviteAddress(address account) public view returns(address) {
        return inviteAddress[account];
    }
    //getFirstLuckDrawAddress
    function getFirstLuckDrawAddress() public view returns(address) {
        return firstLuckDrawAddress;
    }
    // Get userMohoLuckDraw Count
    function userMohoLuckDrawCountOf(address luckDrawAddress) public view returns(uint256) {
        return userMohoLuckDrawCount[luckDrawAddress];
    }

    function luckDrawTRX(address _inviteAddress,string memory boxType) public payable returns (uint256 resultAmount) {
          if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxTrxOne'))){
              require(msg.value>=boxTrxOne,"TRX: The desired TRX must be greater than 3.");
          }else if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxTrxTwo'))){
              require(msg.value>=boxTrxTwo,"TRX: The desired TRX must be greater than 12000.");
          }else if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxTrxThree'))){
              require(msg.value>=boxTrxThree,"TRX: The desired TRX must be greater than 30000.");
          }else{
              require(false,"boxType: The participating box does not exist.");
          }

          return luckDraw(_inviteAddress,boxType);
    }

    function luckDrawUSDT(address _inviteAddress,string memory boxType) public returns (uint256 resultAmount) {
          if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxUsdtOne'))){
              // pass
          }else if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxUsdtTwo'))){
              // pass
          }else if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxUsdtThree'))){
              // pass
          }else{
              require(false,"boxType: The participating box does not exist.");
          }

          return luckDraw(_inviteAddress,boxType);
    }


    // Participate in the magic box lottery
    function luckDraw(address _inviteAddress,string memory boxType) private returns (uint256 resultAmount) {
        // Open the box or not
        require(luckDrawIsStart,"luckDrawIsStart: Is false.");

        // Creation address does not need to be filled in
        if(firstLuckDrawAddress != msg.sender){
                if(inviteAddress[msg.sender]==address(0)){
                    if(liquidityStakeContract.getInviteAddressOf(msg.sender)!=address(0)){
                        _inviteAddress =   liquidityStakeContract.getInviteAddressOf(msg.sender);
                    }else{
                      if(_inviteAddress != firstLuckDrawAddress){ // The root node can not invest
                        // Inviteaddress must have participated in the pledge address
                        require(liquidityStakeContract.isJoinStakeOf(_inviteAddress)== true || userMohoPledgedCount[_inviteAddress] >=1, "The invitational address has no promotion authority");
                      }
                    }
                    // Write invitation relationship
                    inviteAddress[msg.sender]  = _inviteAddress;

                    emit BindingInvitation(msg.sender, _inviteAddress,block.timestamp);
                }
        }

        // Get luckDrawAmount And luckDrawCoinName
        uint256 luckDrawAmount;
        string memory luckDrawCoinName;
        uint256 usetPledgeLevel;
        uint256 cosmeticEarnings;

        if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxTrxOne'))){
            luckDrawAmount = boxTrxOne;luckDrawCoinName = 'TRX';
            usetPledgeLevel = uint256(1); cosmeticEarnings = uint256(3);
        }else if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxTrxTwo'))){
            luckDrawAmount = boxTrxTwo;luckDrawCoinName = 'TRX';
            usetPledgeLevel = uint256(2); cosmeticEarnings = uint256(5);
        }else if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxTrxThree'))){
            luckDrawAmount = boxTrxThree;luckDrawCoinName = 'TRX';
            usetPledgeLevel = uint256(3); cosmeticEarnings = uint256(7);
        }else if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxUsdtOne'))){
            luckDrawAmount = boxUsdtOne;luckDrawCoinName = 'USDT';
            usetPledgeLevel = uint256(1); cosmeticEarnings = uint256(3);
        }else if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxUsdtTwo'))){
            luckDrawAmount = boxUsdtTwo;luckDrawCoinName = 'USDT';
            usetPledgeLevel = uint256(2); cosmeticEarnings = uint256(5);
        }else if(keccak256(abi.encodePacked(boxType)) == keccak256(abi.encodePacked('boxUsdtThree'))){
            luckDrawAmount = boxUsdtThree;luckDrawCoinName = 'USDT';
            usetPledgeLevel = uint256(3); cosmeticEarnings = uint256(7);
        }else{
            require(false,"boxType: The participating box does not exist.");
        }

        // luckDraw into
        uint256 time = block.timestamp;
        uint256 diff = time.sub(luckDrawStartTime);
        uint256 diffCount = diff.div(86400);
        if(diffCount>=1){
            luckDrawStartTime += uint256(86400).mul(diffCount);// update luckDrawStartTime
            accountTodayLuckDrawCount[msg.sender] = uint256(0);// More than 1 day replacement is 0
        }
        require(accountTodayLuckDrawCount[msg.sender]<3,"time: Participate in a box draw up to 3 times per day.");

        accountLastLuckDrawTime[msg.sender] = time;
        accountTodayLuckDrawCount[msg.sender] += uint256(1);// todat count +1

        // Judge whether the balance meets the participation conditions
        bool isWin;
        /* uint256 public wheelTotal = 150;
        uint256 public wheelMaxWin = 15;
        uint256 public wheelNowWin = 0;
        uint256 public wheelCount = 1; */

        // Winning calculation
        if(wheelTotal<=0){
            wheelTotal = uint256(149); wheelCount += uint256(1); wheelNowWin = uint256(0); wheelNowRewardMaximum = uint256(0);
        }else{
            wheelTotal -= uint256(1);
        }

        if(wheelMaxWin == wheelNowWin){
            isWin = false;//must false
        }else if(wheelMaxWin-wheelNowWin>=wheelTotal){
            isWin = true;// must true
        }else{
           uint256 randomNumber = randomNumber();
           emit RandomNumber(msg.sender,randomNumber);
           if(randomNumber == 6){     //Test use >=7   30%
              isWin = true; wheelNowWin += uint256(1);
           }else{
              isWin = false;
           }
        }

        if(keccak256(abi.encodePacked(luckDrawCoinName)) == keccak256(abi.encodePacked('TRX'))){
            // ===============send trx start=========

            // Allocation of lottery amount
            if(isWin){
                // The winnings are distributed : technologyAddress 1.43% + nodeDistributionAddress 2% + teamReturnsAddress 6.9%
                uint256 returnAmountUser = luckDrawAmount.mul(2).div(3);

                require(address(this).balance>=luckDrawAmount,"TRX: Insufficient balance of TRX available to contract.");
                address(uint160(msg.sender)).transfer(returnAmountUser);
                address(uint160(technologyAddress)).transfer(luckDrawAmount.mul(143).div(10000));
                address(uint160(nodeDistributionAddress)).transfer(luckDrawAmount.mul(200).div(10000));

                // Statistics of winning data
                uint256 returnAmountWinLuckDraw = luckDrawAmount.mul(1).div(3);
                luckDrawWinTotalCount += uint256(1);
                luckDrawWinTotalTrx += returnAmountWinLuckDraw;
                luckDrawWinUserTrx[msg.sender] += returnAmountWinLuckDraw;
                // Statistics of winning rea
                uint256 returnAmountUserChangeRea = returnAmountWinLuckDraw.mul(priceNowTrxRea).div(1000000);
                luckDrawUsePledgedReaTotal += returnAmountUserChangeRea;
                luckDrawUsePledgedReaUser[msg.sender] += returnAmountUserChangeRea;
                // Define the return value
                resultAmount = uint256(0);

                // Magic box lottery winning user order written
                userMohoLuckDrawCount[msg.sender] += uint256(1);
                // set order - max 1000
                for(uint256 i = 0; i < 1000; i++) {
                    MohoLuckDrawOrder storage order = mohoLuckDrawOrders[i][msg.sender];
                    if(order.isExist==false){
                        mohoLuckDrawOrders[i][msg.sender] = MohoLuckDrawOrder(i,true,block.timestamp,returnAmountUserChangeRea,false,uint256(0),usetPledgeLevel,cosmeticEarnings);
                        i = 1000;// Write ends the current loop
                    }
                }
            }else{
                // wheelNowRewardMaximum
                uint256 winningsAmount;
                if(wheelMaxWin == wheelNowRewardMaximum){
                    winningsAmount = luckDrawAmount.mul(2).div(100);//must 2%
                    resultAmount = uint256(2);
                }else if(wheelMaxWin.sub(wheelNowRewardMaximum).add(wheelMaxWin).sub(wheelNowWin)>=wheelTotal){
                    winningsAmount = luckDrawAmount.mul(7).div(100);// must 7%
                    resultAmount = uint256(7);wheelNowRewardMaximum += uint256(1);
                }else{
                   uint256 randomNumberWinnings = randomNumber();
                   if(randomNumberWinnings == 7){
                      winningsAmount = luckDrawAmount.mul(7).div(100); wheelNowRewardMaximum += uint256(1);
                      resultAmount = uint256(7);
                   }else{
                      winningsAmount = luckDrawAmount.mul(2).div(100);
                      resultAmount = uint256(2);
                   }
                }

                require(address(this).balance>=luckDrawAmount.add(winningsAmount),"TRX: Insufficient balance of TRX available to contract.");
                // Lottery amount returned to users
                address(uint160(msg.sender)).transfer(luckDrawAmount);
                // The winnings are distributed : 80% - 2% luckDrawAmount + 10% + 7% luckDrawAmount
                address(uint160(msg.sender)).transfer(winningsAmount);

                // StaticIncome
                if(inviteAddress[msg.sender]!=address(0)){
                     address direct1 = inviteAddress[msg.sender];
                     if(userMohoPledgedCount[direct1]>=1){
                          address(uint160(direct1)).transfer(winningsAmount.mul(20).div(100));
                          emit StaticIncome(msg.sender,direct1,resultAmount,luckDrawAmount,winningsAmount.mul(20).div(100),"TRX");
                     }
                     if(inviteAddress[direct1]!=address(0)){
                          address direct2 = inviteAddress[direct1];
                          if(userMohoPledgedCount[direct2]>=1){
                               address(uint160(direct2)).transfer(winningsAmount.mul(10).div(100));
                               emit StaticIncome(msg.sender,direct2,resultAmount,luckDrawAmount,winningsAmount.mul(10).div(100),"TRX");
                          }
                     }
                }

                // set log
                emit Winnings(msg.sender,boxType,luckDrawAmount,winningsAmount,"TRX",resultAmount);
            }
            // ===============send trx end=========
        }else{
            usdtTokenContract.safeTransferFrom(address(msg.sender),address(this),luckDrawAmount);

            // Allocation of lottery amount
            if(isWin){
                // The winnings are distributed : technologyAddress 1.43% + nodeDistributionAddress 2% + teamReturnsAddress 6.9%
                uint256 returnAmountUser = luckDrawAmount.mul(2).div(3);
                usdtTokenContract.safeTransfer(address(msg.sender),returnAmountUser);
                usdtTokenContract.safeTransfer(technologyAddress,luckDrawAmount.mul(143).div(10000));
                usdtTokenContract.safeTransfer(nodeDistributionAddress,luckDrawAmount.mul(200).div(10000));

                // Statistics of winning data
                uint256 returnAmountWinLuckDraw = luckDrawAmount.mul(1).div(3);
                luckDrawWinTotalCount += uint256(1);
                luckDrawWinTotalUsdt += returnAmountWinLuckDraw;
                luckDrawWinUserUsdt[msg.sender] += returnAmountWinLuckDraw;
                // Statistics of winning rea
                uint256 returnAmountUserChangeRea = returnAmountWinLuckDraw.mul(priceNowUsdtRea).div(1000000);
                luckDrawUsePledgedReaTotal += returnAmountUserChangeRea;
                luckDrawUsePledgedReaUser[msg.sender] += returnAmountUserChangeRea;
                // Define the return value
                resultAmount = uint256(0);

                // Magic box lottery winning user order written
                userMohoLuckDrawCount[msg.sender] += uint256(1);
                // set order - max 1000
                for(uint256 i = 0; i < 1000; i++) {
                    MohoLuckDrawOrder storage order = mohoLuckDrawOrders[i][msg.sender];
                    if(order.isExist==false){
                        mohoLuckDrawOrders[i][msg.sender] = MohoLuckDrawOrder(i,true,block.timestamp,returnAmountUserChangeRea,false,uint256(0),usetPledgeLevel,cosmeticEarnings);
                        i = 1000;// Write ends the current loop
                    }
                }
            }else{
                // wheelNowRewardMaximum
                uint256 winningsAmount;
                if(wheelMaxWin == wheelNowRewardMaximum){
                    winningsAmount = luckDrawAmount.mul(2).div(100);//must 2%
                    resultAmount = uint256(2);
                }else if(wheelMaxWin.sub(wheelNowRewardMaximum).add(wheelMaxWin).sub(wheelNowWin)>=wheelTotal){
                    winningsAmount = luckDrawAmount.mul(7).div(100);// must 7%
                    resultAmount = uint256(7);wheelNowRewardMaximum += uint256(1);
                }else{
                   uint256 randomNumberWinnings = randomNumber();
                   if(randomNumberWinnings == 7){
                      winningsAmount = luckDrawAmount.mul(7).div(100); wheelNowRewardMaximum += uint256(1);
                      resultAmount = uint256(7);
                   }else{
                      winningsAmount = luckDrawAmount.mul(2).div(100);
                      resultAmount = uint256(2);
                   }
                }
                // Lottery amount returned to users
                usdtTokenContract.safeTransfer(address(msg.sender),luckDrawAmount);
                // The winnings are distributed : 80% - 2% luckDrawAmount + 10% + 7% luckDrawAmount
                usdtTokenContract.safeTransfer(address(msg.sender),winningsAmount);

                // StaticIncome
                if(inviteAddress[msg.sender]!=address(0)){
                     address direct1 = inviteAddress[msg.sender];
                     if(userMohoPledgedCount[direct1]>=1){
                          usdtTokenContract.safeTransfer(direct1,winningsAmount.mul(20).div(100));
                          emit StaticIncome(msg.sender,direct1,resultAmount,luckDrawAmount,winningsAmount.mul(20).div(100),"USDT");
                     }
                     if(inviteAddress[direct1]!=address(0)){
                          address direct2 = inviteAddress[direct1];
                          if(userMohoPledgedCount[direct2]>=1){
                               usdtTokenContract.safeTransfer(direct2,winningsAmount.mul(10).div(100));
                               emit StaticIncome(msg.sender,direct2,resultAmount,luckDrawAmount,winningsAmount.mul(10).div(100),"USDT");
                          }
                     }
                }

                // set log
                emit Winnings(msg.sender,boxType,luckDrawAmount,winningsAmount,"USDT",resultAmount);
            }
        }
        // set log
        emit LuckDraw(msg.sender,boxType,luckDrawAmount,isWin,resultAmount);
    }

    // Get Pledged Rea User
    function luckDrawUsePledgedReaUserOf(address luckDrawAddress) public view returns(uint256) {
        return luckDrawUsePledgedReaUser[luckDrawAddress];
    }

    // Get winning data usdt
    function luckDrawWinUserUsdtOf(address luckDrawAddress) public view returns(uint256) {
        return luckDrawWinUserUsdt[luckDrawAddress];
    }

    // Get winning data trx
    function luckDrawWinUserTrxOf(address luckDrawAddress) public view returns(uint256) {
        return luckDrawWinUserTrx[luckDrawAddress];
    }

    // Update technology collection address
    function setTechnologyAddress(address _technologyAddress) public onlyOwner {
        technologyAddress = _technologyAddress;
    }

    // Update nodeDistribution collection address
    function setNodeDistributionAddress(address _nodeDistributionAddress) public onlyOwner {
        nodeDistributionAddress = _nodeDistributionAddress;
    }

    // Random return 0-9 integer
    function randomNumber() private returns(uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10;
        randNonce++;
        return rand;
    }

    // Get the last time stamp of the user's participation in the lottery
    function accountLastLuckDrawTimeOf(address luckDrawAddress) public view returns(uint256) {
        return accountLastLuckDrawTime[luckDrawAddress];
    }

    // The number of times the account participated in the magic box lottery today
    function accountTodayLuckDrawCountOf(address luckDrawAddress) public view returns(uint256) {
        return accountTodayLuckDrawCount[luckDrawAddress];
    }

    // set Price Now Trx Rea
    function setPriceNowTrxRea(uint256 _priceNowTrxRea) public  {
        require(msg.sender==accountAdmin, "Admin: caller is not the admin");
        priceNowTrxRea = _priceNowTrxRea;
    }

    // set Price Now Usdt Rea
    function setPriceNowUsdtRea(uint256 _priceNowUsdtRea) public  {
        require(msg.sender==accountAdmin, "Admin: caller is not the admin");
        priceNowUsdtRea = _priceNowUsdtRea;
    }

    // set Account Admin
    function setAccountAdmin(address _accountAdmin) public onlyOwner {
        accountAdmin = _accountAdmin;
    }

}