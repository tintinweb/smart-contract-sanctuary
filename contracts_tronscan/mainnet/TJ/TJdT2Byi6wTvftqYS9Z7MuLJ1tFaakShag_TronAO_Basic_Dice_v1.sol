//SourceUnit: contract.sol

pragma solidity ^0.4.25;

contract TronAO_Basic_Dice_v1 {
    address public owner = msg.sender;
	 address support = msg.sender;
    uint public prizeFund;
    address private lastSender;
    address private lastOrigin;
    
    address public lastInvestor;
    uint public lastInvestedAt;
     uint public startTime;
    uint public totalInvestors;
    uint public totalInvested;
    
    // records registrations
    mapping (address => bool) public registered;
    // records amounts invested
    mapping (address => mapping (uint => uint)) public invested;
    // records blocks at which investments were made
    mapping (address => uint) public atBlock;
    // records referrers
    mapping (address => address) public referrers;
    // records shares
    mapping (address => mapping (uint => uint)) public shares;
    
    event Dice(address indexed from, uint256 bet, uint256 prize, uint256 number, uint256 rollUnder);
    
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
        require(msg.value >= 10000000 && msg.value <= 10000000000);
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
        if (number < rollUnder) {
            uint prize = msg.value * 98 / rollUnder;
            msg.sender.transfer(prize);
            
            emit Dice(msg.sender, msg.value, prize, number, rollUnder);
        } else {
           
            emit Dice(msg.sender, msg.value, 0, number, rollUnder);
        }
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

    constructor() public {
        startTime = now; // we start after the contract deployment;
        owner = msg.sender;
    }

    function () external payable onlyOwner {

    }
}