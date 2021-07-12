/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


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

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor ()  {
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

interface IMintableToken is IERC20 {

  function mint(address _receiver, uint256 _amount) external;

}

contract BnbFarm is Ownable {
    using SafeMath for uint256;

    uint256 constant public DEPOSITS_MAX = 100;
    uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;
    uint256[] public REFERRAL_LEVELS_PERCENTS = [1000, 700, 400, 200, 100, 100, 50, 50];
    uint256[] public REFERRAL_LEVELS_MILESTONES = [0, 30 ether, 120 ether, 500 ether, 1000 ether, 3000 ether, 10000 ether, 20000 ether];
    uint8 constant public REFERRAL_DEPTH = 10;
    uint8 constant public REFERRAL_TURNOVER_DEPTH = 5;

    address payable constant public DEFAULT_REFERRER_ADDRESS = 0x2B2FE21A85B033c3E64DF5861c08f5C3504c0c30; //CHANGE THIS

    
    address payable constant public MARKETING_ADDRESS = 0x2B2FE21A85B033c3E64DF5861c08f5C3504c0c30; //CHANGE THIS
    uint256 constant public MARKETING_FEE = 1500;
    address payable constant public PROMOTION_ADDRESS = 0x2B2FE21A85B033c3E64DF5861c08f5C3504c0c30; //CHANGE THIS
    uint256 constant public PROMOTION_FEE = 500;
    address payable constant public LIQUIDITY_ADDRESS = 0x2B2FE21A85B033c3E64DF5861c08f5C3504c0c30; //CHANGE THIS
    uint256 constant public LIQUIDITY_FEE = 300;

    uint256 constant public BASE_PERCENT = 200; 

    
    uint256 constant public MAX_HOLD_PERCENT = 10000; 
    uint256 constant public HOLD_BONUS_PERCENT = 10; 

    
    uint256 constant public MAX_CONTRACT_PERCENT = 10000; 
    uint256 constant public CONTRACT_BALANCE_STEP = 100 ether; 
    uint256 constant public CONTRACT_HOLD_BONUS_PERCENT = 10; 

    
    uint256 constant public MAX_DEPOSIT_PERCENT = 10000; 
    uint256 constant public USER_DEPOSITS_STEP = 10 ether; 
    uint256 constant public VIP_BONUS_PERCENT = 10; 

    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public PERCENTS_DIVIDER = 10000;

    uint256 public totalDeposits;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;

    uint256 public contractPercent;

    address public tokenContractAddress;
    struct Token {
      address tokenContractAddress;
      address flipTokenContractAddress;
      uint256 rate; 
    }
    mapping (address => Token) tokens;
    mapping (address => address) flipTokens;

    struct Stake {
      uint256 amount;
      uint256 checkpoint;
      uint256 checkpointHold;
      uint256 accumulatedReward;
      uint256 withdrawnReward;
    }
    

    mapping (address => mapping (address => Stake)) stakes;
     //0 ==> Executive
    // 1 ==> Manager
    // 2 ==> Director
    
    

    
    uint256 constant public HOLD_BONUS_PERCENT_STAKE = 10; 
    uint256 constant public HOLD_BONUS_PERCENT_LIMIT = 10000; 

    
    uint256 constant public USER_DEPOSITS_STEP_STAKE = 10 ether; 
    uint256 constant public VIP_BONUS_PERCENT_STAKE = 100; 
    uint256 constant public VIP_BONUS_PERCENT_LIMIT = 100000; 

    uint256 public MULTIPLIER = 3;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 refback;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint256 bonus;
        uint256[REFERRAL_DEPTH] refs;
        uint256[REFERRAL_DEPTH] refsNumber;
        uint16 rbackPercent;
        uint8 refLevel;
        uint256 refTurnover;
    }

    mapping (address => User) public users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event RefBack(address indexed referrer, address indexed referral, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    
    event Staked(address indexed user, address indexed tokenContractAddress, address indexed flipTokenContractAddress, uint256 amount);
    event Unstaked(address indexed user, address indexed tokenContractAddress, address indexed flipTokenContractAddress, uint256 amount);
    event RewardWithdrawn(address indexed user, address indexed tokenContractAddress, address indexed flipTokenContractAddress, uint256 reward);

    constructor() {
        contractPercent = getContractBalanceRate();
        badges["Executive"]=0;
        badges["Manager"] =0;
        badges["Director"]= 0;
    }

    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 0.05 BNB");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");

        uint256 marketingFee = msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint256 promotionFee = msg.value.mul(PROMOTION_FEE).div(PERCENTS_DIVIDER);
        uint256 liquidityFee = msg.value.mul(LIQUIDITY_FEE).div(PERCENTS_DIVIDER);

        MARKETING_ADDRESS.transfer(marketingFee);
        PROMOTION_ADDRESS.transfer(promotionFee);
        LIQUIDITY_ADDRESS.transfer(liquidityFee);

        emit FeePayed(msg.sender, marketingFee.add(promotionFee).add(liquidityFee));
        address upline;

        bool isNewUser = false;
        if (user.referrer == address(0)) {
            isNewUser = true;
            if (isActive(referrer) && referrer != msg.sender) {
              user.referrer = referrer;
            } else {
              user.referrer = DEFAULT_REFERRER_ADDRESS;
            }
        }

        uint256 refbackAmount;
        if (user.referrer != address(0)) {
            bool[] memory distributedLevels = new bool[](REFERRAL_LEVELS_PERCENTS.length);

            address current = msg.sender;
            upline = user.referrer;
            uint8 maxRefLevel = 0;
            for (uint256 i = 0; i < REFERRAL_DEPTH; i++) {
                if (upline == address(0)) {
                  break;
                }

                uint256 refPercent = 0;
                if (i == 0) {
                  refPercent = REFERRAL_LEVELS_PERCENTS[users[upline].refLevel];

                  maxRefLevel = users[upline].refLevel;
                  for (uint8 j = users[upline].refLevel; j >= 0; j--) {
                    distributedLevels[j] = true;

                    if (j == 0) {
                      break;
                    }
                  }
                } else if (users[upline].refLevel > maxRefLevel && !distributedLevels[users[upline].refLevel]) {
                  refPercent = REFERRAL_LEVELS_PERCENTS[users[upline].refLevel]
                          .sub(REFERRAL_LEVELS_PERCENTS[maxRefLevel], "Ref percent calculation error");

                  maxRefLevel = users[upline].refLevel;
                  for (uint8 j = users[upline].refLevel; j >= 0; j--) {
                    distributedLevels[j] = true;

                    if (j == 0) {
                      break;
                    }
                  }
                }

                uint256 amount = msg.value.mul(refPercent).div(PERCENTS_DIVIDER);

                if (i == 0 && users[upline].rbackPercent > 0 && amount > 0) {
                    refbackAmount = amount.mul(uint256(users[upline].rbackPercent)).div(PERCENTS_DIVIDER);
                    msg.sender.transfer(refbackAmount);

                    emit RefBack(upline, msg.sender, refbackAmount);

                    amount = amount.sub(refbackAmount);
                }

                if (amount > 0) {
                    address(uint160(upline)).transfer(amount);
                    users[upline].bonus = uint256(users[upline].bonus).add(amount);

                    emit RefBonus(upline, msg.sender, i, amount);
                }

                users[upline].refs[i]++;
                if (isNewUser) {
                  users[upline].refsNumber[i]++;
                }

                current = upline;
                upline = users[upline].referrer;
            }

            upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_TURNOVER_DEPTH; i++) {
                if (upline == address(0)) {
                  break;
                }

                updateReferralLevel(upline, msg.value);

                upline = users[upline].referrer;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(msg.value, 0, refbackAmount, uint32(block.timestamp)));

        totalInvested = totalInvested.add(msg.value);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint256 contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, msg.value);

        
        if (isContract(tokenContractAddress)) {
          IMintableToken(tokenContractAddress).mint(msg.sender, msg.value.mul(tokens[tokenContractAddress].rate));
        }
        
        
        
        
        
        //calling setuser badge everytime a deposit is made
        // setUserBadge(upline);
        
        
        //require(badges[_role]!=0,"invalid badge");
        
        address payable _upline = payable(upline);
        string memory _role;
        
       
        
        uint256 _directCount = getUserDirect(upline);
        uint256 _userCurrentEarning = getUserAvailable(upline);
        uint256 _userWithdrawn = getUserTotalWithdrawn(upline);
        uint256 _userTotalEarning = _userCurrentEarning.add(_userWithdrawn);
        if(_userTotalEarning >= badges["Manager"] && _directCount >= 5){
            // you became manager 
            _role = "Manager";
        } else if(_userTotalEarning >= badges["Executive"] && _directCount >= 15){
            // you became executive
            _role = "Executive";
        } else if(_userTotalEarning >= badges["Director"] && _directCount >= 30){
            // you became director
            _role = "Director";
        } 
        
        
        
        if(keccak256(abi.encodePacked(userBadge[upline].userBadge))!=keccak256(abi.encodePacked(_role))){
            
            uint256 amount = (badges[_role].mul(5)).div(100);
            userBadge[upline].userBadge = _role;
            userBadge[upline].userAmount= amount;
            userBadge[upline].isPayed= true;
            _upline.transfer(amount);
            
        }
        
    
        
        
        
        
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends;

        for (uint8 i = 0; i < user.deposits.length; i++) {

            if (uint256(user.deposits[i].withdrawn) < uint256(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint256(user.deposits[i].withdrawn).add(dividends) > uint256(user.deposits[i].amount).mul(2)) {
                    dividends = (uint256(user.deposits[i].amount).mul(2)).sub(uint256(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint256(user.deposits[i].withdrawn).add(dividends); 
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = uint32(block.timestamp);

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function setRefback(uint16 rbackPercent) public {
        require(rbackPercent <= 10000);

        User storage user = users[msg.sender];

        if (user.deposits.length > 0) {
            user.rbackPercent = rbackPercent;
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint256) {
        uint256 contractBalance = address(this).balance;
        uint256 contractBalancePercent = BASE_PERCENT.add(
          contractBalance
            .div(CONTRACT_BALANCE_STEP)
            .mul(CONTRACT_HOLD_BONUS_PERCENT)
        );

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }

    function getUserDepositRate(address userAddress) public view returns (uint256) {
        uint256 userDepositRate;

        if (getUserAmountOfDeposits(userAddress) > 0) {
            userDepositRate = getUserTotalDeposits(userAddress).div(USER_DEPOSITS_STEP).mul(VIP_BONUS_PERCENT);

            if (userDepositRate > MAX_DEPOSIT_PERCENT) {
                userDepositRate = MAX_DEPOSIT_PERCENT;
            }
        }

        return userDepositRate;
    }

    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint256 userDepositRate = getUserDepositRate(userAddress);

            uint256 timeMultiplier = (block.timestamp.sub(uint256(user.checkpoint))).div(TIME_STEP).mul(HOLD_BONUS_PERCENT);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }

            return contractPercent.add(timeMultiplier).add(userDepositRate);
        } else {
            return contractPercent;
        }
    }

    function getUserAvailable(address userAddress) public view returns (uint256) {
        User memory user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint8 i = 0; i < user.deposits.length; i++) {

            if (uint256(user.deposits[i].withdrawn) < uint256(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint256(user.deposits[i].withdrawn).add(dividends) > uint256(user.deposits[i].amount).mul(2)) {
                    dividends = (uint256(user.deposits[i].amount).mul(2)).sub(uint256(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);
            }

        }

        return totalDividends;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint256(user.deposits[user.deposits.length-1].withdrawn) < uint256(user.deposits[user.deposits.length-1].amount).mul(2);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 amount = user.bonus;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn).add(user.deposits[i].refback);
        }

        return amount;
    }

    function getUserDeposits(address userAddress, uint256 last, uint256 first) public view
      returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        User storage user = users[userAddress];

        uint256 count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }

        uint256[] memory amount = new uint256[](count);
        uint256[] memory withdrawn = new uint256[](count);
        uint256[] memory refback = new uint256[](count);
        uint256[] memory start = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = first; i > last; i--) {
            amount[index] = user.deposits[i-1].amount;
            withdrawn[index] = user.deposits[i-1].withdrawn;
            refback[index] = user.deposits[i-1].refback;
            start[index] = uint256(user.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn, refback, start);
    }

    function getSiteStats() public view returns (uint256, uint256, uint256, uint256) {
        return (totalInvested, totalDeposits, address(this).balance, contractPercent);
    }

    function getUserStats(address userAddress) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 userPerc = getUserPercentRate(userAddress);
        uint256 userAvailable = getUserAvailable(userAddress);
        uint256 userDepsTotal = getUserTotalDeposits(userAddress);
        uint256 userDeposits = getUserAmountOfDeposits(userAddress);
        uint256 userWithdrawn = getUserTotalWithdrawn(userAddress);
        uint256 userDepositRate = getUserDepositRate(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn, userDepositRate);
    }

    function getDepositsRates(address userAddress) public view returns (uint256, uint256, uint256, uint256) {
      User memory user = users[userAddress];

      uint256 holdBonusPercent = (block.timestamp.sub(uint256(user.checkpoint))).div(TIME_STEP).mul(HOLD_BONUS_PERCENT);
      if (holdBonusPercent > MAX_HOLD_PERCENT) {
          holdBonusPercent = MAX_HOLD_PERCENT;
      }

      return (
        BASE_PERCENT, 
        !isActive(userAddress) ? 0 : holdBonusPercent, 
        address(this).balance.div(CONTRACT_BALANCE_STEP).mul(CONTRACT_HOLD_BONUS_PERCENT), 
        !isActive(userAddress) ? 0 : getUserDepositRate(userAddress) 
      );
    }

    function getUserReferralsStats(address userAddress) public view
      returns (address, uint16, uint16, uint256, uint256[REFERRAL_DEPTH] memory, uint256[REFERRAL_DEPTH] memory, uint256, uint256) {
        User storage user = users[userAddress];

        return (
          user.referrer,
          user.rbackPercent,
          users[user.referrer].rbackPercent,
          user.bonus,
          user.refs,
          user.refsNumber,
          user.refLevel,
          user.refTurnover
        );
    }
    
    function getUserDirect(address userAddress) public view returns(uint256){
        
        User storage user = users[userAddress];
        
        return user.refsNumber[0];
        
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function setTokenContractAddress(address _tokenContractAddress, address _flipTokenContractAddress, uint256 _rate) external onlyOwner {
      require(_rate > 0 && _rate <= 1000, "Invalid rate value");
      require(isContract(_tokenContractAddress), "Provided address is not a token contract address");
      require(isContract(_flipTokenContractAddress), "Provided address is not a flip token contract address");

      tokenContractAddress = _tokenContractAddress;
      tokens[_tokenContractAddress] = Token(_tokenContractAddress, _flipTokenContractAddress, _rate);
      flipTokens[_flipTokenContractAddress] = _tokenContractAddress;
    }

    function updateReferralLevel(address _userAddress, uint256 _amount) private {
      users[_userAddress].refTurnover = users[_userAddress].refTurnover.add(_amount);

      for (uint8 level = uint8(REFERRAL_LEVELS_MILESTONES.length - 1); level > 0; level--) {
        if (users[_userAddress].refTurnover >= REFERRAL_LEVELS_MILESTONES[level]) {
          users[_userAddress].refLevel = level;

          break;
        }
      }
    }

    

    function getStakeVIPBonusRate(address userAddress, address flipTokenContractAddress) public view returns (uint256) {
        uint256 vipBonusRate = stakes[userAddress][flipTokenContractAddress].amount.div(USER_DEPOSITS_STEP_STAKE).mul(VIP_BONUS_PERCENT_STAKE);

        if (vipBonusRate > VIP_BONUS_PERCENT_LIMIT) {
          return VIP_BONUS_PERCENT_LIMIT;
        }

        return vipBonusRate;
    }

    function getStakeHOLDBonusRate(address userAddress, address flipTokenContractAddress) public view returns (uint256) {
        if (stakes[userAddress][flipTokenContractAddress].checkpointHold == 0) {
          return 0;
        }

        uint256 holdBonusRate = (block.timestamp.sub(stakes[userAddress][flipTokenContractAddress].checkpointHold)).div(TIME_STEP).mul(HOLD_BONUS_PERCENT_STAKE);

        if (holdBonusRate > HOLD_BONUS_PERCENT_LIMIT) {
          return HOLD_BONUS_PERCENT_LIMIT;
        }

        return holdBonusRate;
    }

    function getUserStakePercentRate(address userAddress, address flipTokenContractAddress) public view returns (uint256) {
        return getStakeVIPBonusRate(userAddress, flipTokenContractAddress)
          .add(getStakeHOLDBonusRate(userAddress, flipTokenContractAddress));
    }

    function stake(address _flipTokenContractAddress, uint256 _amount) external returns (bool) {
      require(_amount > 0, "Invalid tokens amount value");
      require(isContract(_flipTokenContractAddress), "Provided address is not a flip token contract address");

      if (!IERC20(_flipTokenContractAddress).transferFrom(msg.sender, address(this), _amount)) {
        return false;
      }

      uint256 reward = availableReward(msg.sender, _flipTokenContractAddress);
      if (reward > 0) {
        stakes[msg.sender][_flipTokenContractAddress].accumulatedReward = stakes[msg.sender][_flipTokenContractAddress].accumulatedReward.add(reward);
      }

      stakes[msg.sender][_flipTokenContractAddress].amount = stakes[msg.sender][_flipTokenContractAddress].amount.add(_amount);
      stakes[msg.sender][_flipTokenContractAddress].checkpoint = block.timestamp;
      if (stakes[msg.sender][_flipTokenContractAddress].checkpointHold == 0) {
        stakes[msg.sender][_flipTokenContractAddress].checkpointHold = block.timestamp;
      }

      emit Staked(msg.sender, flipTokens[_flipTokenContractAddress], _flipTokenContractAddress, _amount);

      return true;
    }

    function availableReward(address userAddress, address flipTokenContractAddress) public view returns (uint256) {
      uint256 userPercentRate = getUserStakePercentRate(userAddress, flipTokenContractAddress);

      return (stakes[userAddress][flipTokenContractAddress].amount
        .mul(PERCENTS_DIVIDER.add(userPercentRate)).div(PERCENTS_DIVIDER))
        .mul(MULTIPLIER)
        .mul(block.timestamp.sub(stakes[userAddress][flipTokenContractAddress].checkpoint))
        .div(TIME_STEP);
    }

    function withdrawReward(address _flipTokenContractAddress) external {
      uint256 reward = stakes[msg.sender][_flipTokenContractAddress].accumulatedReward
        .add(availableReward(msg.sender, _flipTokenContractAddress));

      if (reward > 0) {
        address _tokenContractAddress = flipTokens[_flipTokenContractAddress];

        
        if (isContract(_tokenContractAddress)) {
          stakes[msg.sender][_flipTokenContractAddress].checkpoint = block.timestamp;
          stakes[msg.sender][_flipTokenContractAddress].accumulatedReward = 0;
          stakes[msg.sender][_flipTokenContractAddress].withdrawnReward = stakes[msg.sender][_flipTokenContractAddress].withdrawnReward.add(reward);

          IMintableToken(_tokenContractAddress).mint(msg.sender, reward);

          emit RewardWithdrawn(msg.sender, _tokenContractAddress, _flipTokenContractAddress, reward);
        }
      }
    }

    function unstake(address _flipTokenContractAddress, uint256 _amount) external {
      require(_amount > 0, "Invalid tokens amount value");
      require(_amount <= stakes[msg.sender][_flipTokenContractAddress].amount, "Not enough tokens on the stake balance");
      require(isContract(_flipTokenContractAddress), "Provided address is not a flip token contract address");

      uint256 reward = availableReward(msg.sender, _flipTokenContractAddress);
      if (reward > 0) {
        stakes[msg.sender][_flipTokenContractAddress].accumulatedReward = stakes[msg.sender][_flipTokenContractAddress].accumulatedReward.add(reward);
      }

      stakes[msg.sender][_flipTokenContractAddress].amount = stakes[msg.sender][_flipTokenContractAddress].amount.sub(_amount);
      stakes[msg.sender][_flipTokenContractAddress].checkpoint = block.timestamp;
      if (stakes[msg.sender][_flipTokenContractAddress].amount > 0) {
        stakes[msg.sender][_flipTokenContractAddress].checkpointHold = block.timestamp;
      } else {
        stakes[msg.sender][_flipTokenContractAddress].checkpointHold = 0; 
      }

      require(IERC20(_flipTokenContractAddress).transfer(msg.sender, _amount));

      emit Unstaked(msg.sender, flipTokens[_flipTokenContractAddress], _flipTokenContractAddress, _amount);
    }

    function getUserStakeStats(address _userAddress, address _flipTokenContractAddress) public view
      returns (uint256, uint256, uint256, uint256, uint256)
    {
      return (
        stakes[_userAddress][_flipTokenContractAddress].amount,
        stakes[_userAddress][_flipTokenContractAddress].accumulatedReward,
        stakes[_userAddress][_flipTokenContractAddress].withdrawnReward,
        getStakeVIPBonusRate(_userAddress, _flipTokenContractAddress),
        getStakeHOLDBonusRate(_userAddress, _flipTokenContractAddress)
      );
    }

    function getUserStakeTimeCheckpoints(address _userAddress, address _flipTokenContractAddress) public view returns (uint256, uint256) {
      return (
        stakes[_userAddress][_flipTokenContractAddress].checkpoint,
        stakes[_userAddress][_flipTokenContractAddress].checkpointHold
      );
    }

    function updateMultiplier(uint256 multiplier) public onlyOwner {
      require(multiplier > 0 && multiplier <= 50, "Multiplier is out of range");

      MULTIPLIER = multiplier;
    }

    function emergencySwapExit() public onlyOwner returns(bool)
    {
        require(msg.sender == owner());
        msg.sender.transfer(address(this).balance);
        return true;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //  User badge logic ==================================>
    
    
    struct Badge{
        uint256 userAmount;
        bool isPayed;
        string userBadge;
    }
    
    mapping (string=>uint256) public badges;
    //string [] public badgeRole = ["Executive", "Manager", "Director"];
    mapping (address=> Badge) public userBadge;

    
    function getUserBadgeStats() public view returns(bool, string memory){
        return(
            userBadge[msg.sender].isPayed,
            userBadge[msg.sender].userBadge
            );
    }
    
    

    
    function setExecutiveAmount(uint256 _amount) public onlyOwner{
        
        badges["Executive"] = _amount;
    }
    
    function setManagerAmount(uint256 _amount) public onlyOwner{
        
        badges["Manager"] = _amount; 
    }
    
    function setDirectorAmount(uint256 _amount) public onlyOwner{
        
        badges["Director"] = _amount; 
    }

    


}