//SourceUnit: contract.sol

pragma solidity ^0.4.25;

contract TronAO_Basic_Dice_v2 {
    address public owner = msg.sender;
	address support = msg.sender;
    
    address private lastSender;
    address private lastOrigin;
    
    address public lastInvestor;
    uint public lastInvestedAt;
    
	uint public totalUsers;
    uint public totalInvestors;
    uint public totalInvested;
    
    uint public tokenId = 1002794; // TronAO Dice Token ID
    uint public stageSize = 1000000000; // TronAO Dice Token Supply
    uint public initialK = 500;
    uint public tokensPaid;
    uint public totalFrozen;
    uint public freezePeriod = 28800; // TronAO Dice Token Minimum Freeze Period is 1 day
    
    int public dividends;
    uint public dividendsToPay;
    
    uint public prizeFund;
    bool public prizeReceived;
    
    mapping (address => bool) public registered; // records registrations
    mapping (address => mapping (uint => uint)) public invested; // records amounts invested
    mapping (address => uint) public atBlock; // records blocks at which investments were made
    mapping (address => address) public referrers; // records referrers
    mapping (address => mapping (uint => uint)) public shares; // records shares
    mapping (address => uint) public frozen; // frozen tokens
    mapping (address => uint) public frozenAt; // time frozen
	
    event Registered(address user);
    event Dice(address indexed from, uint256 bet, uint256 prize, uint256 number, uint256 rollUnder, uint256 tokenReward);
    
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

    function getOwnerProfit(uint amount) external onlyOwner {
        uint max = address(this).balance;
        owner.transfer(amount < max ? amount : max);
    }
    
    function dice(uint rollUnder, address referrerAddress) external payable notContract {
        require(msg.value >= 10000000 && msg.value <= getMaxBet(rollUnder));
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
        
        uint number = random(100);
        
        uint stage = tokensPaid / 1000000 / stageSize;
        uint toPay = msg.value * 100 / (initialK + 50 * stage);
        if (toPay <= address(this).tokenBalance(tokenId)) {
            msg.sender.transferToken(toPay, tokenId);
            tokensPaid += toPay;
        } else {
            toPay = 0;
        }
        
        if (number < rollUnder) {
        	uint divToSub = (prize - msg.value) / 2;
            dividends -= int(divToSub);
            uint prize = msg.value * 98 / rollUnder;
            msg.sender.transfer(prize);
            emit Dice(msg.sender, msg.value, prize, number, rollUnder, toPay);
        } else {
            dividends += int(msg.value) / 2;
            emit Dice(msg.sender, msg.value, 0, number, rollUnder, toPay);
        }
        
       // msg.sender.transferToken(msg.value / 2, tokenId);
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

	function getMaxBet(uint rollUnder) public view returns (uint) {
        uint udivs = dividends > 0 ? uint(dividends) : 0;
        uint maxBet = (address(this).balance - udivs) * rollUnder / (98 - rollUnder) / 40;
        return maxBet > 100000000000 ? 100000000000 : maxBet;
    }

    function getDivs(uint amount) external onlyOwner {
        uint udivs = dividends > 0 ? uint(dividends) : 0;
        uint max = address(this).balance - udivs;
        owner.transfer(amount < max ? amount : max);
    }

	function withdrawTokens(uint amount) external onlyOwner {
        owner.transferToken(amount, tokenId);
    }
    
    function clearDividends() external onlyOwner {
        dividendsToPay = dividends > 0 ? uint(dividends) : 0;
        dividends = 0;
        if (dividendsToPay > 0) {
            owner.transfer(dividendsToPay);
        }
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