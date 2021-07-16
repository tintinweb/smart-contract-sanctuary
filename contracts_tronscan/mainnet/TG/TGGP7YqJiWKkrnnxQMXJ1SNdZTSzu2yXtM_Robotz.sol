//SourceUnit: Robotz5.sol

pragma solidity ^0.4.25;

contract Robotz {
    address support = msg.sender;
    address private lastSender;
    address private lastOrigin;
    uint public totalFrozen;
    uint public tokenId = 1002775;
    
    uint public prizeFund;
    bool public prizeReceived;
    address public lastInvestor;
    uint public lastInvestedAt;
    
    uint public totalInvestors;
    uint public totalInvested;
    
    // records registrations
    mapping (address => bool) public registered;
    // records amounts invested
    mapping (address => mapping (uint => uint)) public invested;
    // records amounts invested by user
    mapping (address => uint) public investedByUser;
    // records amounts withdrawn
    mapping (address => uint) public withdrawn;
    // records blocks at which investments were made
    mapping (address => uint) public atBlock;
    // records referrers
    mapping (address => address) public referrers;
    // records objects
    mapping (address => mapping (uint => uint)) public objects;
    // frozen tokens
    mapping (address => uint) public frozen;
    // upgrades
    mapping (address => uint) public upgrades;

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
            if (registered[referrerAddress] && referrerAddress != msg.sender) {
                referrers[msg.sender] = referrerAddress;
            }

            totalInvestors++;
            registered[msg.sender] = true;

            emit Registered(msg.sender);
        }
    }

    function buy(address referrerAddress) external payable {
        require(block.number >= 20371644);
        require(msg.value == 50000000 || msg.value == 100000000 || msg.value == 200000000 || msg.value == 500000000
            || msg.value == 1000000000 || msg.value == 5000000000 || msg.value == 10000000000 || msg.value == 100000000000 || msg.value == 200000000000);
        
        objects[msg.sender][msg.value]++;
        prizeFund += msg.value / 25;
        support.transfer(msg.value * 3 / 25);
        
        _register(referrerAddress);
        
        if (referrers[msg.sender] != 0x0) {
            referrers[msg.sender].transfer(msg.value / 20);
        } else {
            support.transfer(msg.value / 20);
        }
        
        lastInvestor = msg.sender;
        lastInvestedAt = block.number;

        getAllProfit();
        
        invested[msg.sender][msg.value] += msg.value;
        investedByUser[msg.sender] += msg.value;
        totalInvested += msg.value;

        msg.sender.transferToken(msg.value * 100, tokenId);

        prizeReceived = false;
    }

    function getProfitFrom(address user, uint price, uint percentage) internal view returns (uint) {
        return invested[user][price] * (percentage + upgrades[user]) / 1000 * (block.number - atBlock[user]) / 864000;
    }

    function getAllProfitAmount(address user) public view returns (uint) {
        uint max1 = (address(this).balance - prizeFund) * 9 / 10;
        uint max2 = investedByUser[user] * 6 / 5 - withdrawn[user];
        
        uint amount =
            getProfitFrom(user, 50000000, 950) +
            getProfitFrom(user, 100000000, 951) +
            getProfitFrom(user, 200000000, 952) +
            getProfitFrom(user, 500000000, 953) +
            getProfitFrom(user, 1000000000, 954) +
            getProfitFrom(user, 5000000000, 955) +
            getProfitFrom(user, 10000000000, 956) +
            getProfitFrom(user, 100000000000, 957) +
            getProfitFrom(user, 200000000000, 958);
        
        if (amount > max1) {
          amount = max1;
        }
        if (amount > max2) {
          amount = max2;
        }
        
        return amount;
    }

    function getAllProfit() internal {
        if (atBlock[msg.sender] > 0) {
            uint amount = getAllProfitAmount(msg.sender);

            if (amount > 0) {
                msg.sender.transfer(amount);
                withdrawn[msg.sender] += amount;
            }
        }

        atBlock[msg.sender] = block.number;
    }

    function getProfit() external {
        getAllProfit();
    }

    function allowGetPrizeFund(address user) public view returns (bool) {
        return !prizeReceived && lastInvestor == user && block.number >= lastInvestedAt + 2400 && prizeFund >= 2000000;
    }

    function getPrizeFund() external {
        require(allowGetPrizeFund(msg.sender));
        uint amount = prizeFund / 2;
        msg.sender.transfer(amount);
        prizeFund -= amount;
        prizeReceived = true;
    }

    function register(address referrerAddress) external notContract {
        _register(referrerAddress);
    }

    function freeze(address referrerAddress) external payable {
        require(msg.tokenid == tokenId);
        require(msg.tokenvalue > 0);

        _register(referrerAddress);

        frozen[msg.sender] += msg.tokenvalue;
        totalFrozen += msg.tokenvalue;
    }

    function unfreeze() external {
        totalFrozen -= frozen[msg.sender];
        msg.sender.transferToken(frozen[msg.sender], tokenId);
        frozen[msg.sender] = 0;
    }

    function upgrade(address referrerAddress) external payable {
        require(msg.tokenid == tokenId);
        require(upgrades[msg.sender] == 0 && msg.tokenvalue == 50000000000 ||
          upgrades[msg.sender] == 1 && msg.tokenvalue == 100000000000 ||
          upgrades[msg.sender] == 2 && msg.tokenvalue == 300000000000 ||
          upgrades[msg.sender] == 3 && msg.tokenvalue == 1000000000000 ||
          upgrades[msg.sender] == 4 && msg.tokenvalue == 10000000000000);

        _register(referrerAddress);
        
        getAllProfit();
        
        upgrades[msg.sender]++;
        support.transferToken(msg.tokenvalue, tokenId);
    }
}