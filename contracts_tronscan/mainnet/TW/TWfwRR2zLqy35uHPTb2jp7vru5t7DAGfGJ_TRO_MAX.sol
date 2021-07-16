//SourceUnit: tromax.sol


/*
 *
 *   TRONexMax is a decentralized anonymous investment and wealth management platform based on TRX smart contract. Smart contract ensure the safety of all participants' funds.
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronexmax.com                                      │
 *   │                                                                       │
 *   │   Telegram Public Group: @TronSuper_Protocol                          │
 *   |                                                                       │
 *   |   Twitter: https://twitter.com/tronexmax                              │
 *   |   E-mail: admin@tronexmax.com                                         │
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any TRX amount (100 TRX minimum) using our website invest button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1% every 24 hours
 *   - Personal hold-bonus: +0.05% for every 12 hours without withdraw
 *   - Contract total amount bonus: +0.05% for every 1,000,000 TRX on platform address balance, the upper limit is 10%
 *
 *   - Minimal deposit: 100 TRX, no maximal limit
 *   - Total income: 200% (deposit included)
 *   - Earnings every moment, withdraw any time
 *
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 3-level referral commission: 5% - 2.5% - 0.5%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 87% Platform main balance, participants payouts
 *   - 5% Advertising and promotion expenses,Support work, technical functioning, administration fee
 *   - 8% Affiliate program bonuses
 *
 *   ────────────────────────────────────────────────────────────────────────
 *

 */


pragma solidity 0.5.12;

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


contract TRO_MAX is Creator{
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
    uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
    uint256 constant public TIME_STEP = 1 days;


//    uint256 constant public INVEST_MIN_AMOUNT = 2 ether ; //200 usdt
//    uint256 constant public CONTRACT_BALANCE_STEP = 100 ether;//15w usdt
//    uint256 constant public TIME_STEP = 60;

    uint256 constant public BASE_PERCENT = 10;
    uint256 constant public MAX_PERCENT = 100;
    uint256[] public REFERRAL_PERCENTS = [50, 25, 5];
    uint256 constant public USER_LEVEL_MAX = 3;

    uint256 constant public PROJECT_FEE = 50;
    uint256 constant public PERCENTS_DIVIDER = 1000;

    uint256 constant public NODE_LEVEL_MAX = 3;

    address public usdtToken = address(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c);


    uint256 private totalUsers;
    uint256 private totalInvested;
    uint256 private totalWithdrawn;
    uint256 private totalDeposits;


    address payable public projectAddress;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
        uint256 drawntime;
    }

    struct node_config {
        uint256 price;
        uint256 percent;
        uint256 max;
        uint256 bought;
    }

    node_config[]  public NODE_CONFIG;

    struct User {
        bool IsNode;
        address referrer;
        uint256 bonus;
        uint256 bonus_with_draw;
        uint256 l0_counter;
        uint256 l1_counter;
        uint256 l2_counter;
        Deposit[] deposits;
    }

    struct Node {
        uint256 node_level;
        uint256 node_bonus;
        uint256 sub_node_bonus;
        uint256 send_parallel_node_bonus;
        uint256 node_with_draw;
        uint256 l0_counter;
        uint256 l1_counter;
        uint256 l2_counter;
    }

    mapping(address => Node) public nodes;
    mapping(address => User) public users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
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

    bytes4 private constant transferFrom = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    function TokenTransferFrom(address from, address to, uint value) private {
        (bool success, bytes memory data) = usdtToken.call(abi.encodeWithSelector(transferFrom, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    function initialize(address payable projectAddr) public payable creatorOnly {

        require(projectAddress == address(0)&& projectAddr!= address(0), "initialize only would call once");
        require(!isContract(projectAddr)&&(tx.origin == msg.sender));
        projectAddress = projectAddr;

        //   NODE_CONFIG.push(node_config({price : 5 ether , percent : 10, max : 50}));
        //   NODE_CONFIG.push(node_config({price : 15 ether , percent : 20, max : 500}));
        //   NODE_CONFIG.push(node_config({price : 30 ether , percent : 50, max : 100}));

        NODE_CONFIG.push(node_config({price : 500 * 1000000, percent : 10, max : 2200, bought : 0}));
        NODE_CONFIG.push(node_config({price : 1500 * 1000000, percent : 20, max : 400, bought : 0}));
        NODE_CONFIG.push(node_config({price : 3000 * 1000000, percent : 50, max : 100, bought : 0}));

//        NODE_CONFIG.push(node_config({price : 5, percent : 10, max : 2200, bought : 0}));
//        NODE_CONFIG.push(node_config({price : 15, percent : 20, max : 400, bought : 0}));
//        NODE_CONFIG.push(node_config({price : 30, percent : 50, max : 100, bought : 0}));

        require(NODE_CONFIG.length == NODE_LEVEL_MAX);


    }

    function buyNode(uint256 level, uint256 price) public payable IsInitialized {

        //level from 0 ~ 2
        require(level >= 0 && level < NODE_CONFIG.length&&(tx.origin == msg.sender));
        require(NODE_CONFIG[level].bought < NODE_CONFIG[level].max, "counter over");
        TokenTransferFrom(msg.sender, projectAddress, NODE_CONFIG[level].price);
        //        projectAddress.transfer(msg.value);
        NODE_CONFIG[level].bought = NODE_CONFIG[level].bought + 1;

        Node storage node = nodes[msg.sender];
        User storage user = users[msg.sender];

        require(user.referrer!= address(0) );

        if (user.IsNode == true) {
            require(node.node_level < level, "can not buy lower node");
        }

        node.node_level = level;

        user.IsNode = true;

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 100; i++) {
                if (upline != address(0)) {
                    if (users[upline].IsNode == true) {
                        if (level == 0) {
                            nodes[upline].l0_counter = nodes[upline].l0_counter.add(1);
                        } else if (level == 1) {
                            nodes[upline].l1_counter = nodes[upline].l1_counter.add(1);
                        } else if (level == 2)
                        {
                            nodes[upline].l2_counter = nodes[upline].l2_counter.add(1);
                        }
                    }
                    upline = users[upline].referrer;
                } else break;
            }
        }
    }

    function find_upline_node(address upline, uint256 level) public view returns (address, uint256)
    {
        //inorder to show the meaning of first in
        if(level > 0x9999){
            level = 0;
        }

        for (uint256 i = 0; i < 200; i++) {
            if (upline != address(0)) {
                User memory user = users[upline];
                if (user.IsNode == true) {
                    Node memory node = nodes[upline];
                    if (node.node_level >= level)
                        return (upline, node.node_level);
                }
            } else {
                return (address(0), 0);
            }
            upline = users[upline].referrer;
        }

        return (address(0), 0);
    }

    function add_node_income(uint256 value) internal {

        address upline_node = users[msg.sender].referrer;

        address[NODE_LEVEL_MAX] memory nodeTempAddress;
        uint256[NODE_LEVEL_MAX] memory levelTempPercent;
        uint256 counter = 0;
        uint256 tem_level =0x9999;
        for (; counter < NODE_LEVEL_MAX; counter++) {
            address tem_address;
            (tem_address, tem_level) = find_upline_node(upline_node, tem_level+1);
            if (tem_address == address(0)) {
                break;
            }
            levelTempPercent[counter] = NODE_CONFIG[tem_level].percent;
            nodeTempAddress[counter] = tem_address;
            if (tem_level >= NODE_LEVEL_MAX - 1) {
                //if  reached the top should break
                break;
            }
            upline_node = users[tem_address].referrer;
        }


        uint256 user_persent = 0;
        for (uint256 pos = 0; pos <= counter; pos++) {
            address temp_address = nodeTempAddress[pos];
            if (temp_address != address(0)) {
                user_persent = levelTempPercent[pos];
                uint256 amount = value.mul(user_persent).div(PERCENTS_DIVIDER);
                nodes[temp_address].node_bonus = nodes[temp_address].node_bonus.add(amount);
                emit NodeFee(msg.sender, temp_address, amount);
            } else
            {
                break;
            }
        }

    }

    function invest(address referrer, uint256 value) public payable IsInitialized {

        require(!isContract(referrer) && !isContract(msg.sender)&&(tx.origin == msg.sender));
        address upline = referrer;
        require(msg.value >= INVEST_MIN_AMOUNT);
        User storage user = users[msg.sender];

        if (referrer != projectAddress) {
            if (user.referrer == address(0)) {
                if (upline == address(0) || users[upline].deposits.length == 0 || referrer == msg.sender) {
                    require(false, "check failed");
                }
            }
        }
        emit NewDeposit(msg.sender, msg.value);

        uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        projectAddress.transfer(fee);

        emit FeePayed(msg.sender, fee);

        //if user have no referrer
        if (user.referrer == address(0)) {
            user.referrer = referrer;
            for (uint256 i = 0; i < USER_LEVEL_MAX; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        users[upline].l0_counter = users[upline].l0_counter.add(1);
                    } else if (i == 1) {
                        users[upline].l1_counter = users[upline].l1_counter.add(1);
                    }
                    else if (i == 2) {
                        users[upline].l2_counter = users[upline].l2_counter.add(1);
                    }
                    upline = users[upline].referrer;
                } else {
                    break;
                }
            }
        }

        upline = user.referrer;
        for (uint256 i = 0; i < USER_LEVEL_MAX; i++) {
            if (upline != address(0)) {
                uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                users[upline].bonus = users[upline].bonus.add(amount);
                emit RefBonus(upline, msg.sender, i, amount);
                upline = users[upline].referrer;
            } else break;
        }

        if (user.deposits.length == 0) {
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }
        user.deposits.push(Deposit(msg.value, 0, block.timestamp, block.timestamp));
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        //add the node income
        add_node_income(msg.value);
    }

    function find_parallel_node(address user_addr) public view returns (bool){
        if (user_addr == address(0)) {
            return false;
        }
        User memory user = users[msg.sender];
        if (user.IsNode != true || user.referrer == address(0)) {
            return false;
        }
        Node memory node = nodes[msg.sender];
        address upline_node;
        uint256 temp_level;
        (upline_node, temp_level) = find_upline_node(user.referrer, node.node_level);
        if (upline_node != address(0) && (node.node_level == temp_level)) {
            return true;
        }
        return false;

    }

    function withdraw_node_income() public IsInitialized {

        require(!isContract(msg.sender)&&(tx.origin == msg.sender));

        User storage user = users[msg.sender];
        require(user.IsNode == true, "user.IsNode != true");
        Node storage node = nodes[msg.sender];
        uint256 bonus = node.node_bonus + node.sub_node_bonus  - node.node_with_draw;

        require(bonus > 0);
        address upline_node;
        uint256 temp_level;
        (upline_node, temp_level) = find_upline_node(user.referrer, node.node_level);
        uint256 up_node_amount = 0;
        // find the same level node
        if (upline_node != address(0) && (node.node_level == temp_level)) {
            up_node_amount = bonus.mul(10).div(100);
            nodes[upline_node].sub_node_bonus = nodes[upline_node].sub_node_bonus.add(up_node_amount);
            //withdraw
            emit UpNodeFee(msg.sender, upline_node, up_node_amount);
        }


        //        require(usdtToken.transfer(msg.sender, bonus), "fail transform");
        msg.sender.transfer(bonus);
        node.node_with_draw = node.node_with_draw.add(bonus);

        totalWithdrawn = totalWithdrawn.add(bonus);

        emit WithDrawnNodeFee(msg.sender, bonus);

    }

   // function alldraw() public {
    //    msg.sender.transfer(address(this).balance);
    //}

    function withdraw() public IsInitialized {

        require(!isContract(msg.sender)&&(tx.origin == msg.sender));

        User storage user = users[msg.sender];

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit memory temp = user.deposits[i];
            if (temp.withdrawn < temp.amount.mul(2)) {
                uint256 userPercentRate = getUserPercentRate(msg.sender, temp.drawntime);
                dividends = (temp.amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                .mul(block.timestamp.sub(temp.drawntime))
                .div(TIME_STEP);
                if (temp.withdrawn.add(dividends) > temp.amount.mul(2)) {
                    dividends = (temp.amount.mul(2)).sub(temp.withdrawn);
                }

                totalAmount = totalAmount.add(dividends);
                /// changing of storage data
                user.deposits[i].withdrawn = temp.withdrawn.add(dividends);
                user.deposits[i].drawntime = block.timestamp;
            }
        }

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonus_with_draw = user.bonus_with_draw.add(user.bonus);
            user.bonus = 0;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }

    function getInfo(address userAddress) public view returns (uint256[20] memory) {
        uint256[20] memory info;
        uint i = 0;
        /* 0 */info[i++] = address(this).balance;
        /* 1 */info[i++] = getUserPercentMaxRate(userAddress);
        /* 2 */info[i++] = getContractBalanceRate();
        /* 3 */info[i++] = getUserDividends(userAddress);
        /* 4 */info[i++] = getUserAvailable(userAddress);
        /* 5 */info[i++] = getUserTotalDeposits(userAddress);
        /* 6 */info[i++] = getUserTotalWithdrawn(userAddress);
        /* 7 */info[i++] = users[userAddress].deposits.length;
        /* 8 */info[i++] = totalUsers;
        /* 9 */info[i++] = totalInvested;
        /* 10 */info[i++] = totalWithdrawn;
        /* 11 */info[i++] = totalDeposits;
        /* 12 */info[i++] = find_parallel_node(userAddress) == true ? 1 : 0;

        return info;
    }

    function getContractBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    function getContractBalanceRate() internal view returns (uint256) {
        uint256 contractBalance = address(this).balance;
        uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
        contractBalancePercent = contractBalancePercent.min(MAX_PERCENT);
        return BASE_PERCENT.add(contractBalancePercent);
    }

    function getUserPercentRate(address userAddress, uint256 time) internal view returns (uint256) {
        uint256 contractBalanceRate = getContractBalanceRate();
        if (isActive(userAddress)) {
            uint256 timeMultiplier = (block.timestamp.sub(time)).div(TIME_STEP);
            return contractBalanceRate.add(timeMultiplier.min(40));
        } else {
            return contractBalanceRate;
        }
    }
    //get the max rate to show
    function getUserPercentMaxRate(address userAddress) internal view returns (uint256) {
        User memory user = users[userAddress];
        uint256 time = block.timestamp;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit memory temp = user.deposits[i];
            if (temp.withdrawn < temp.amount.mul(2)) {
                time = time.min(temp.drawntime);
            }
        }
        return getUserPercentRate(userAddress, time);
    }

    function getUserDividends(address userAddress) internal view returns (uint256) {
        User memory user = users[userAddress];
        uint256 totalDividends = 0;
        uint256 dividends = 0;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            Deposit memory temp = user.deposits[i];

            if (temp.withdrawn < temp.amount.mul(2)) {
                uint256 userPercentRate = getUserPercentRate(msg.sender, temp.drawntime);
                dividends = (temp.amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                .mul(block.timestamp.sub(temp.drawntime))
                .div(TIME_STEP);
                if (temp.withdrawn.add(dividends) > temp.amount.mul(2)) {
                    dividends = (temp.amount.mul(2)).sub(temp.withdrawn);
                }
                totalDividends = totalDividends.add(dividends);
                /// no update of withdrawn because that is view function
            }
        }

        return totalDividends;
    }


    function getUserReferralBonus(address userAddress) internal view returns (uint256) {
        return users[userAddress].bonus;
    }

    function getUserAvailable(address userAddress) internal view returns (uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length - 1].withdrawn < user.deposits[user.deposits.length - 1].amount.mul(2)) {
                return true;
            }
        }
        return false;
    }


    function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) internal view returns (uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) internal view returns (uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
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