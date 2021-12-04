/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

pragma solidity >=0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
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

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
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
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        
        
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        
        
        

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface CommonInterface {

  

  function getUserReferrer(address userAddress) external view returns (address);

  

  function stake(address userAddress, uint256 amount, uint8 stakeTypeIdx) external;

  function tokensReceived(address userAddress) external view returns (uint256);

  

  function mint(address _receiver, uint256 _amount) external;

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

struct Plan {
  uint256 minAmount;
  uint256 maxAmount;
  uint256 lockDuration;
  uint16 discountPromille;
  uint8 monthlyPercent;
  uint8 referralPromille;
}

struct Purchase {
  uint8 planIdx;
  uint256 boughtTokens;
  uint256 buyPrice;
  uint256 tokensReceived;
  uint256 time;
  uint8 monthlyRewardsReceived;

  bool monthlyRewardsClaimed;
  bool isClaimed;
}

struct RefStats {
  uint256 referralsNumber;
  mapping(address => bool) isReferral;
  uint256 referralReward;
}

contract BuyTokensCheap is Ownable {
  using SafeERC20 for IERC20;

  address public ADMIN_ADDRESS  = 0xAa1c989344301943d13797747cb093d68dF27A6a;
  address public ORACLE_ADDRESS = 0xAa1c989344301943d13797747cb093d68dF27A6a;

  address public constant BUSD_TOKEN_CONTRACT_ADDRESS = 0xd175Cfb9b2096129d568400569DF087912afb5c9; // BUSD token contract address


  address public mainContractAddress;
  address public tokenContractAddress;

  Plan[] public plans;
  uint256 public tokenPrice = 1e18; 

  mapping(address => Purchase[]) purchases;

  uint256 public constant CLAIMING_PERIOD = 1 hours;

  mapping(address => RefStats) public refStats;

  event TokenPriceChanged(address indexed initiator, uint256 price, uint256 time);

  event TokensBought(address indexed buyer, uint8 indexed planIdx, uint256 indexed purchaseIdx, uint256 tokensAmount, uint256 tokenPrice, uint256 time);
  event MonthlyClaimReceived(address indexed recipient, uint256 indexed purchaseIdx, uint256 rewardsNumber, uint256 tokensAmount, uint256 time);
  event ClaimReceived(address indexed recipient, uint256 indexed purchaseIdx, uint256 tokensAmount, uint256 time);
  event ReferralRewardReceived(address indexed buyer, address indexed referrer, uint8 indexed planIdx, uint256 rewardAmount, uint256 time);

  constructor(address _mainContractAddress, address _tokenContractAddress) {
    mainContractAddress = _mainContractAddress;
    tokenContractAddress = _tokenContractAddress;

    uint256 SHORT_DURATION = 6 hours;
    uint256 LONG_DURATION = 2 * SHORT_DURATION;

    plans.push(Plan({
      minAmount: 1000e18, maxAmount: 10000e18, lockDuration: SHORT_DURATION, discountPromille: 25, monthlyPercent: 5, referralPromille: 5
    }));
    plans.push(Plan({
      minAmount: 1000e18, maxAmount: 10000e18, lockDuration: LONG_DURATION, discountPromille: 50, monthlyPercent: 5, referralPromille: 5
    }));

    plans.push(Plan({
      minAmount: 10000e18, maxAmount: 20000e18, lockDuration: SHORT_DURATION, discountPromille: 75, monthlyPercent: 5, referralPromille: 10
    }));
    plans.push(Plan({
      minAmount: 10000e18, maxAmount: 20000e18, lockDuration: LONG_DURATION, discountPromille: 100, monthlyPercent: 5, referralPromille: 10
    }));
    
    plans.push(Plan({
      minAmount: 20000e18, maxAmount: 30000e18, lockDuration: SHORT_DURATION, discountPromille: 150, monthlyPercent: 5, referralPromille: 15
    }));
    plans.push(Plan({
      minAmount: 20000e18, maxAmount: 30000e18, lockDuration: LONG_DURATION, discountPromille: 200, monthlyPercent: 5, referralPromille: 15
    }));

    plans.push(Plan({
      minAmount: 30000e18, maxAmount: 40000e18, lockDuration: SHORT_DURATION, discountPromille: 250, monthlyPercent: 5, referralPromille: 20
    }));
    plans.push(Plan({
      minAmount: 30000e18, maxAmount: 40000e18, lockDuration: LONG_DURATION, discountPromille: 300, monthlyPercent: 5, referralPromille: 20
    }));

    plans.push(Plan({
      minAmount: 40000e18, maxAmount: 50000e18, lockDuration: SHORT_DURATION, discountPromille: 350, monthlyPercent: 7, referralPromille: 25
    }));
    plans.push(Plan({
      minAmount: 40000e18, maxAmount: 50000e18, lockDuration: LONG_DURATION, discountPromille: 400, monthlyPercent: 7, referralPromille: 25
    }));

    plans.push(Plan({
      minAmount: 100000e18, maxAmount: 100000e18, lockDuration: LONG_DURATION, discountPromille: 650, monthlyPercent: 9, referralPromille: 30
    }));

  }

  function buy(uint8 planIdx, uint256 amountBUSD, address referrer) external {
    require(planIdx < plans.length, "Invalid plan Idx");
    require(amountBUSD >= plans[planIdx].minAmount, "BUSD amount too low");
    require(amountBUSD < plans[planIdx].maxAmount || (amountBUSD == plans[planIdx].maxAmount && planIdx >= 8), "BUSD amount too high");

    IERC20(BUSD_TOKEN_CONTRACT_ADDRESS).safeTransferFrom(msg.sender, owner(), amountBUSD);

    uint256 tokensAmount = amountBUSD * 1e18 * 1000 / (1000 - plans[planIdx].discountPromille) / tokenPrice;
    purchases[msg.sender].push(Purchase({
      planIdx: planIdx,
      boughtTokens: tokensAmount,
      buyPrice: tokenPrice,
      tokensReceived: 0,
      time: block.timestamp,
      monthlyRewardsReceived: 0,

      monthlyRewardsClaimed: false,
      isClaimed: false
    }));

    CommonInterface(tokenContractAddress).mint(address(this), tokensAmount);

    emit TokensBought(msg.sender, planIdx, purchases[msg.sender].length - 1, tokensAmount, tokenPrice, block.timestamp);

    
    if (referrer == address(0x0)) {
      referrer = CommonInterface(mainContractAddress).getUserReferrer(msg.sender);
    }

    if (referrer != address(0x0)) {
      uint256 refReward = tokensAmount * plans[planIdx].referralPromille / 1000;

      CommonInterface(tokenContractAddress).mint(referrer, refReward);

      emit ReferralRewardReceived(msg.sender, referrer, planIdx, refReward, block.timestamp);

      if (!refStats[referrer].isReferral[msg.sender]) {
        refStats[referrer].isReferral[msg.sender] = true;
        refStats[referrer].referralsNumber++;
      }
      refStats[referrer].referralReward+= refReward;
    }
  }

  function claimMonthlyTokens(uint256 purchaseIdx) external {
    require(purchaseIdx < purchases[msg.sender].length, "Invalid purchase Idx");
    require(!purchases[msg.sender][purchaseIdx].monthlyRewardsClaimed, "All monthly rewards claimed for this purchase");
    require(
      purchases[msg.sender][purchaseIdx].tokensReceived < purchases[msg.sender][purchaseIdx].boughtTokens,
      "You have received all tokens from this purchase"
    );

    Plan memory plan = plans[purchases[msg.sender][purchaseIdx].planIdx];

    uint256 finalTime = block.timestamp;
    if (finalTime > purchases[msg.sender][purchaseIdx].time + plan.lockDuration) {
      finalTime = purchases[msg.sender][purchaseIdx].time + plan.lockDuration;
    }
    uint8 months = uint8((finalTime - purchases[msg.sender][purchaseIdx].time) / CLAIMING_PERIOD);
    if (months > purchases[msg.sender][purchaseIdx].monthlyRewardsReceived) {
      uint8 rewardsNumber = months - purchases[msg.sender][purchaseIdx].monthlyRewardsReceived;
      if (rewardsNumber == 0) {
        return;
      }

      uint256 percent = plan.monthlyPercent * rewardsNumber;
      uint256 tokensAmount = purchases[msg.sender][purchaseIdx].boughtTokens * percent / 100;

      purchases[msg.sender][purchaseIdx].monthlyRewardsReceived+= rewardsNumber;
      purchases[msg.sender][purchaseIdx].tokensReceived+= tokensAmount;

      if (block.timestamp >= purchases[msg.sender][purchaseIdx].time + plan.lockDuration) {
        purchases[msg.sender][purchaseIdx].monthlyRewardsClaimed = true;
      }

      IERC20(tokenContractAddress).safeTransfer(msg.sender, tokensAmount);

      emit MonthlyClaimReceived(msg.sender, purchaseIdx, rewardsNumber, tokensAmount, block.timestamp);
    }
  }

  function claimMonthlyTokens() external {
    uint256 totalTokensAmount;

    for (uint256 purchaseIdx = 0; purchaseIdx < purchases[msg.sender].length; purchaseIdx++) {
      if (purchases[msg.sender][purchaseIdx].monthlyRewardsClaimed) {
        continue;
      }
      if (purchases[msg.sender][purchaseIdx].tokensReceived == purchases[msg.sender][purchaseIdx].boughtTokens) {
        continue;
      }

      Plan memory plan = plans[purchases[msg.sender][purchaseIdx].planIdx];

      uint256 finalTime = block.timestamp;
      if (finalTime > purchases[msg.sender][purchaseIdx].time + plan.lockDuration) {
        finalTime = purchases[msg.sender][purchaseIdx].time + plan.lockDuration;
      }
      uint8 months = uint8((finalTime - purchases[msg.sender][purchaseIdx].time) / CLAIMING_PERIOD);
      if (months > purchases[msg.sender][purchaseIdx].monthlyRewardsReceived) {
        uint8 rewardsNumber = months - purchases[msg.sender][purchaseIdx].monthlyRewardsReceived;
        if (rewardsNumber == 0) {
          continue;
        }

        uint256 percent = plan.monthlyPercent * rewardsNumber;
        uint256 tokensAmount = purchases[msg.sender][purchaseIdx].boughtTokens * percent / 100;

        purchases[msg.sender][purchaseIdx].monthlyRewardsReceived+= rewardsNumber;
        purchases[msg.sender][purchaseIdx].tokensReceived+= tokensAmount;
        totalTokensAmount+= tokensAmount;

        if (block.timestamp >= purchases[msg.sender][purchaseIdx].time + plan.lockDuration) {
          purchases[msg.sender][purchaseIdx].monthlyRewardsClaimed = true;
        }

        emit MonthlyClaimReceived(msg.sender, purchaseIdx, rewardsNumber, tokensAmount, block.timestamp);
      }
    }

    if (totalTokensAmount > 0) {
      IERC20(tokenContractAddress).safeTransfer(msg.sender, totalTokensAmount);
    }
  }

  function claimTokens() external {
    uint256 totalTokensAmount;

    for (uint256 purchaseIdx = 0; purchaseIdx < purchases[msg.sender].length; purchaseIdx++) {
      if (purchases[msg.sender][purchaseIdx].isClaimed) {
        continue;
      }
      if (purchases[msg.sender][purchaseIdx].tokensReceived == purchases[msg.sender][purchaseIdx].boughtTokens) {
        continue;
      }

      Plan memory plan = plans[purchases[msg.sender][purchaseIdx].planIdx];

      if (block.timestamp >= purchases[msg.sender][purchaseIdx].time + plan.lockDuration) {
        uint256 tokensAmount = purchases[msg.sender][purchaseIdx].boughtTokens - purchases[msg.sender][purchaseIdx].tokensReceived;

        purchases[msg.sender][purchaseIdx].tokensReceived= purchases[msg.sender][purchaseIdx].boughtTokens;
        totalTokensAmount+= tokensAmount;

        purchases[msg.sender][purchaseIdx].monthlyRewardsClaimed = true;
        purchases[msg.sender][purchaseIdx].isClaimed = true;

        emit ClaimReceived(msg.sender, purchaseIdx, tokensAmount, block.timestamp);
      }
    }

    if (totalTokensAmount > 0) {
      IERC20(tokenContractAddress).safeTransfer(msg.sender, totalTokensAmount);
    }
  }

  

  modifier onlyFromList(address[3] memory _addresses) {
    bool isInList = false;
    for (uint8 i = 0; i < 3; i++) {
      if (msg.sender == _addresses[i] && _addresses[i] != address(0x0)) {
        isInList = true;
        break;
      }
    }
    require(isInList, "Only permitted address can call this method");
    _;
  }

  function changeTokenPrice(uint256 price) external onlyFromList([owner(), ADMIN_ADDRESS, ORACLE_ADDRESS]) {
    require(price > 1e9, "Set token price in wei");

    tokenPrice = price;

    emit TokenPriceChanged(msg.sender, tokenPrice, block.timestamp);
  }

  function setAdminAddress(address adminAddress) external onlyOwner {
    require(adminAddress != address(0x0), "Invalid admin adderess");

    ADMIN_ADDRESS = adminAddress;
  }

  function setOracleAddress(address oracleAddress) external onlyOwner {
    require(oracleAddress != address(0x0), "Invalid oracle adderess");

    ORACLE_ADDRESS = oracleAddress;
  }

  function changeDiscountPromille(uint8 planIdx, uint16 discountPromille) external onlyOwner {
    require(planIdx < 11, "Invalid plan idx");
    require(discountPromille < 1000, "Invalid discount");

    plans[planIdx].discountPromille = discountPromille;
  }

  function retrieveTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
    require(_amount > 0, "Invalid amount");
    require(_tokenAddress != tokenContractAddress, "You can't retrieve RST tokens");

    IERC20(_tokenAddress).safeTransfer(owner(), _amount);
  }

  function viewUserPurchases(address userAddress) view external returns (Purchase[] memory ){
     return purchases[userAddress];
  }

  function viewAllPlans() view external returns (Plan[] memory){
    Plan[] memory allPlans = new Plan[](plans.length);
    for(uint8 i = 0; i < plans.length; i++){
      allPlans[i] = plans[i];
    }
    return allPlans;

  }

}