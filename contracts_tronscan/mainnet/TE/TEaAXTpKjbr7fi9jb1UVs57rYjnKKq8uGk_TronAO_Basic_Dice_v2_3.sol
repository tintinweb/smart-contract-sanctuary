//SourceUnit: dice2.3.sol

pragma solidity ^0.4.25;

contract TronAO_Basic_Dice_v2_3 {
    address public owner = msg.sender;
    address support = msg.sender;
    address private lastSender;
    address private lastOrigin;
    uint public totalFrozen;
    uint public stageSize = 28800; // 1 day
    uint public freezePeriod = 86400; // 3 days
    uint public tokenId = 1002794;
    uint public dividends;
    uint public prevDividends;
    uint public prevStage;
    uint public dividendsPaid;
    uint public frozenUsed;
    address public lastInvestor;
    uint public lastInvestedAt;
    uint public startTime;
    uint public totalInvestors;
    uint public totalInvested;
	uint public initialK = 500;
    uint public prizeFund;
    bool public prizeReceived;
	uint public totalUsers;
	
    mapping (address => bool) public registered; // records registrations
    mapping (address => mapping (uint => uint)) public invested; // records amounts invested
    mapping (address => uint) public atBlock; // records blocks at which investments were made
    mapping (address => address) public referrers; // records referrers
    mapping (address => mapping (uint => uint)) public shares; // records shares
    mapping (address => uint) public frozen; // records frozen token
    mapping (address => uint) public frozenAt;
    mapping (address => uint) public gotDivs;
    
    event Registered(address user);
    event Dice(address indexed from, uint256 bet, uint256 prize, uint256 number, uint256 rollUnder, uint256 toPay);
    
    
    uint private seed;
 
    modifier notContract() {
        lastSender = msg.sender;
        lastOrigin = tx.origin;
        require(lastSender == lastOrigin);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function getCurrentStage() public view returns (uint) {
        return block.number / stageSize;
    }
    
    // uint256 to bytes32
    function toBytes(uint256 x) internal pure returns (bytes b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
    
    // returns a pseudo-random number
    function random(uint lessThan) internal returns (uint) {
        seed += block.timestamp + uint(msg.sender);
        return uint(sha256(toBytes(uint(blockhash(block.number - 1)) + seed))) % lessThan;
    }

    function getMaxBet() public view returns (uint) {
        uint maxBet = (address(this).balance - prevDividends - dividends + dividendsPaid) / 25;
        return maxBet > 10000000000 ? 10000000000 : maxBet;
    }

    function getProfit(uint amount) external onlyOwner {
        uint max = address(this).balance - prevDividends - dividends + dividendsPaid;
        owner.transfer(amount < max ? amount : max);
    }
    
    function dice(uint rollUnder, address referrerAddress) external payable notContract {
        require(msg.value >= 10000000 && msg.value <= getMaxBet());
        require(rollUnder >= 4 && rollUnder <= 95);

		if (msg.value == 100000000 || msg.value == 200000000 || msg.value == 1000000000){
        shares[msg.sender][msg.value]++;
        }
        
        support.transfer(msg.value / 10);
        prizeFund += msg.value * 7 / 100;
        
        if (!registered[msg.sender]) {
            require(referrerAddress != msg.sender);     
            if (registered[referrerAddress]) {
                referrers[msg.sender] = referrerAddress;
            }

            totalInvestors++;
            registered[msg.sender] = true;
        }
        
        if (referrers[msg.sender] != 0x0) {
            referrers[msg.sender].transfer(msg.value / 10);
        }
        
        lastInvestor = msg.sender;
        lastInvestedAt = block.number;

        getAllProfit();
        
        invested[msg.sender][msg.value] += msg.value;
        totalInvested += msg.value;

		uint toPay = msg.value  * 98 / rollUnder;
        msg.sender.transferToken(toPay, tokenId);
        
        uint number = random(100);
        if (number < rollUnder) {
            uint prize = msg.value * 98 / rollUnder;
            msg.sender.transfer(prize);
            uint divToSub = (prize - msg.value) / 2;
            dividends = divToSub < dividends ? dividends - divToSub : 0;
            emit Dice(msg.sender, msg.value, prize, number, rollUnder, toPay);
        } else {
            dividends += msg.value / 2;
            emit Dice(msg.sender, msg.value, 0, number, rollUnder, toPay);
        }
    }

    function freeze(address referrerAddress) external payable {
        require(msg.tokenid == tokenId);
        require(msg.tokenvalue > 0);
        if (!registered[msg.sender]) {
            require(referrerAddress != msg.sender);     
            if (registered[referrerAddress]) {
                referrers[msg.sender] = referrerAddress;
            }
            totalInvestors++;
            registered[msg.sender] = true;
        }
        frozen[msg.sender] += msg.tokenvalue;
        frozenAt[msg.sender] = block.number;
        totalFrozen += msg.tokenvalue;
    }

    function unfreeze() external {
        require(block.number - frozenAt[msg.sender] >= freezePeriod);
        totalFrozen -= frozen[msg.sender];
        msg.sender.transferToken(frozen[msg.sender], tokenId);
        frozen[msg.sender] = 0;
        delete frozenAt[msg.sender];
    }

    function getDivs() external {
        require(prevDividends > dividendsPaid);
        require(totalFrozen > frozenUsed);
        uint stage = getCurrentStage();
        require(stage > gotDivs[msg.sender]);
        gotDivs[msg.sender] = stage;
        uint amount = (prevDividends - dividendsPaid) * frozen[msg.sender] / (totalFrozen - frozenUsed);
        require(amount > 0);
		support.transfer(msg.value / 10);
        msg.sender.transfer(amount);
        dividendsPaid += amount;
        frozenUsed += frozen[msg.sender];
    }

	function getOwnerProfit(uint amount) external onlyOwner {
        uint max = address(this).balance;
        owner.transfer(amount < max ? amount : max);
    }

	function getProfitFrom(address user, uint price, uint percentage) internal view returns (uint) {
        return invested[user][price] * percentage / 100 * (block.number - atBlock[user]) / 864000;
    }

    function getAllProfitAmount(address user) public view returns (uint) {
        	return getProfitFrom(user, 100000000, 5) +
            getProfitFrom(user, 200000000, 15) +
            getProfitFrom(user, 1000000000, 101);
    }

    function getAllProfit() internal {
        if (atBlock[msg.sender] > 0) {
            uint max = (address(this).balance - prizeFund) * 9 / 10;
            uint amount = getAllProfitAmount(msg.sender);
            
            if (amount > max) {
                amount = max;
            }

            if (amount > 0) {
            support.transfer(amount / 10);
            msg.sender.transfer(amount);
            }
        }

        atBlock[msg.sender] = block.number;
    }

    function getProfit() external {
        getAllProfit();
    }

    function allowGetPrizeFund(address user) public view returns (bool) {
        return lastInvestor == user && block.number >= lastInvestedAt + 200 && prizeFund > 0;
    }

    function getPrizeFund() external {
        require(allowGetPrizeFund(msg.sender));
        support.transfer(prizeFund / 10);
        msg.sender.transfer(prizeFund);
        prizeFund = 0;
    }

	function withdrawTokens(uint amount) external onlyOwner {
        owner.transferToken(amount, tokenId);
    }
    
  function _register(address referrerAddress) internal {
        if (!registered[msg.sender]) {   
            if (registered[referrerAddress] && referrerAddress != msg.sender) {
                referrers[msg.sender] = referrerAddress;
            }

            totalUsers++;
            registered[msg.sender] = true;

            emit Registered(msg.sender);
        }
    }

    function () external payable onlyOwner {

    }
}