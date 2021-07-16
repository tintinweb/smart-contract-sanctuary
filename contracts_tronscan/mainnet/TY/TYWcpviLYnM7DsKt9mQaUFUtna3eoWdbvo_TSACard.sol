//SourceUnit: TSACard.sol

pragma solidity ^0.4.25;

contract TSACard {
    address support = msg.sender;
    address private lastSender;
    address private lastOrigin;
    uint public totalFrozen;
    uint public tokenId = 1002495;
    
    uint public prizeFund;
    address public lastInvestor;
    uint public lastInvestedAt;
    
    uint public totalInvestors;
    uint public totalInvested;
    
    mapping (address => bool) public registered;
    mapping (address => mapping (uint => uint)) public invested;
    mapping (address => uint) public atBlock;
    mapping (address => address) public referrers;
    mapping (address => mapping (uint => uint)) public buildings;
    mapping (address => uint) public frozen;

    event Registered(address user);
 
    modifier notContract() {
        lastSender = msg.sender;
        lastOrigin = tx.origin;
        require(lastSender == lastOrigin);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == support);
        _;
    }

    function _register(address referrerAddress) internal {
        if (!registered[msg.sender]) {
            require(referrerAddress != msg.sender);     
            if (registered[referrerAddress]) {
                referrers[msg.sender] = referrerAddress;
            }

            totalInvestors++;
            registered[msg.sender] = true;

            emit Registered(msg.sender);
        }
    }

    function buyBuilding(address referrerAddress) external payable {
        require(block.number >= 11291000);
        //cost card
        require(msg.value == 50000000 || msg.value == 100000000 || msg.value == 200000000 || msg.value == 500000000
            || msg.value == 1000000000 || msg.value == 5000000000 || msg.value == 10000000000 || msg.value == 100000000000);
        
        buildings[msg.sender][msg.value]++;
        prizeFund += msg.value * 7 / 100;
        support.transfer(msg.value / 20);
        
        _register(referrerAddress);
        
        if (referrers[msg.sender] != 0x0) {
            referrers[msg.sender].transfer(msg.value / 10);
        }
        
        lastInvestor = msg.sender;
        lastInvestedAt = block.number;

        getAllProfit();
        
        invested[msg.sender][msg.value] += msg.value;
        totalInvested += msg.value;

        msg.sender.transferToken(msg.value, tokenId);
    }

    function getProfitFrom(address user, uint price, uint percentage) internal view returns (uint) {
        return invested[user][price] * percentage / 100 * (block.number - atBlock[user]) / 864000;
    }

    function getAllProfitAmount(address user) public view returns (uint) {
        return
            getProfitFrom(user, 50000000, 10) +
            getProfitFrom(user, 100000000, 20) +
            getProfitFrom(user, 200000000, 30) +
            getProfitFrom(user, 500000000, 40) +
            getProfitFrom(user, 1000000000, 50) +
            getProfitFrom(user, 5000000000, 60) +
            getProfitFrom(user, 10000000000, 70) +
            getProfitFrom(user, 100000000000, 80);
    }

    function getAllProfit() internal {
        if (atBlock[msg.sender] > 0) {
            uint max = (address(this).balance - prizeFund) * 9 / 10;
            uint amount = getAllProfitAmount(msg.sender);
            
            if (amount > max) {
                amount = max;
            }

            if (amount > 0) {
                msg.sender.transfer(amount);
            }
        }

        atBlock[msg.sender] = block.number;
    }

    function getProfit() external {
        getAllProfit();
    }

    function allowGetPrizeFund(address user) public view returns (bool) {
        return lastInvestor == user && block.number >= lastInvestedAt + 1200 && prizeFund > 0;
    }

    function getPrizeFund() external {
        require(allowGetPrizeFund(msg.sender));
        msg.sender.transfer(prizeFund);
        prizeFund = 0;
    }

    function register(address referrerAddress) external notContract {
        _register(referrerAddress);
    }

    function freeze() external payable {
        require(msg.tokenid == tokenId);
        require(msg.tokenvalue > 0);
        frozen[msg.sender] += msg.tokenvalue;
        totalFrozen += msg.tokenvalue;
    }

    function unfreeze() external {
        totalFrozen -= frozen[msg.sender];
        msg.sender.transferToken(frozen[msg.sender], tokenId);
        frozen[msg.sender] = 0;
    }

    function () external payable onlyOwner {

    }
}