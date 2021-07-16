//SourceUnit: Keys3D.sol

pragma solidity 0.4.25;

contract Keys3D {
    address support = msg.sender;
    address private lastSender;
    address private lastOrigin;
    uint public totalFrozen;
    uint public tokenId = 1002937;
    
    uint public prizeFund;
    bool public prizeReceived;
    address public lastInvestor;
    uint public lastInvestedAt;
    
    uint public totalInvestors;
    uint public totalInvested;
    
    mapping (address => bool) public registered;                 // records registrations
    mapping (address => mapping (uint => uint)) public invested; // records amounts invested
    mapping (address => uint) public atBlock;                    // records blocks at which investments were made
    mapping (address => address) public referrers;               // records referrers
    mapping (address => mapping (uint => uint)) public objects;  // records objects
    mapping (address => uint) public frozen;                     // frozen tokens
    mapping (address => uint) public upgrades;                   // upgrades
    
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
            if (registered[referrerAddress] && referrerAddress != msg.sender) {referrers[msg.sender] = referrerAddress;}
            totalInvestors++;
            registered[msg.sender] = true;
            emit Registered(msg.sender);
        }
    }

    function buy(address referrerAddress) external payable {
        // Require a valid transaction, with correct denomination.
        
        //     50 TRX in makes    2 TRX for game,      6 TRX for dev.
        //    100 TRX in makes    4 TRX for game,     12 TRX for dev.
        //    200 TRX in makes    8 TRX for game,     24 TRX for dev.
        //    500 TRX in makes   20 TRX for game,     60 TRX for dev.
        //   1000 TRX in makes   40 TRX for game,    120 TRX for dev.
        //   5000 TRX in makes  200 TRX for game,    600 TRX for dev.
        //  10000 TRX in makes  400 TRX for game,   1200 TRX for dev.
        // 100000 TRX in makes 4000 TRX for game,  12000 TRX for dev.
        
        require(block.number >= 18155224);
        require(
            msg.value == 50000000     || 
            msg.value == 100000000    || 
            msg.value == 200000000    || 
            msg.value == 500000000    || 
            msg.value == 1000000000   || 
            msg.value == 5000000000   || 
            msg.value == 10000000000  || 
            msg.value == 100000000000
        );
        
        objects[msg.sender][msg.value]++; // Give the player their keys
        prizeFund += msg.value / 25;
        support.transfer(msg.value * 3 / 25); // 12% of all TRX into the game goes to the developer.
        
        _register(referrerAddress); // Register the user's referral.
        
        if (referrers[msg.sender] != 0x0) {
            referrers[msg.sender].transfer(msg.value / 20);
        } 
        lastInvestor = msg.sender;
        lastInvestedAt = block.number;
        getAllProfit();
        
        invested[msg.sender][msg.value] += msg.value;
        totalInvested += msg.value;
        msg.sender.transferToken(msg.value * 100, tokenId);
        prizeReceived = false;
    }

    function getProfitFrom(address user, uint price, uint percentage) internal view returns (uint) {
        return invested[user][price] * (percentage + upgrades[user]) / 100 * (block.number - atBlock[user]) / 864000;
    }

    function getAllProfitAmount(address user) public view returns (uint) {
        return
            getProfitFrom(user, 50000000, 95) +
            getProfitFrom(user, 100000000, 96) +
            getProfitFrom(user, 200000000, 97) +
            getProfitFrom(user, 500000000, 98) +
            getProfitFrom(user, 1000000000, 99) +
            getProfitFrom(user, 5000000000, 100) +
            getProfitFrom(user, 10000000000, 101) +
            getProfitFrom(user, 100000000000, 102);
    }

    function getAllProfit() internal {
        if (atBlock[msg.sender] > 0) {
            uint max = (address(this).balance - prizeFund) * 9 / 10;
            uint amount = getAllProfitAmount(msg.sender);
            if (amount > max) {amount = max;}
            if (amount > 0) {msg.sender.transfer(amount);}
        }

        atBlock[msg.sender] = block.number;
    }

    function getProfit() external {getAllProfit();}

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

    function register(address referrerAddress) external notContract {_register(referrerAddress);}

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
        require(
            upgrades[msg.sender] == 0 && msg.tokenvalue == 50000000000 ||
            upgrades[msg.sender] == 1 && msg.tokenvalue == 100000000000 ||
            upgrades[msg.sender] == 2 && msg.tokenvalue == 300000000000 ||
            upgrades[msg.sender] == 3 && msg.tokenvalue == 1000000000000 ||
            upgrades[msg.sender] == 4 && msg.tokenvalue == 10000000000000);

            _register(referrerAddress);
            getAllProfit();
            upgrades[msg.sender]++;
            support.transferToken(msg.tokenvalue, tokenId
        );
    }
}