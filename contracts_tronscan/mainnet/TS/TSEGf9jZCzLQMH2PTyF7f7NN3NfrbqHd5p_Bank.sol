//SourceUnit: bank.sol

pragma solidity ^0.4.25;

interface Token {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function transfer(address _to, uint _value) external returns (bool);
    function balanceOf(address who) external returns (uint);
    function allowance(address _owner, address _spender) external returns (uint remaining);
}

interface Medianizer {
    function read() external view returns (uint);
}

contract Bank {
    using SafeMath for uint;

    modifier onlyAdmin() {require(msg.sender == admin, 'Only admin');_;}

    modifier checkDeposit(uint amount) {
        require(token.allowance(msg.sender, address(this)) >= amount, 'Invalid Allowance');
        require(token.balanceOf(msg.sender) >= amount, 'Invalid Amount');
        _;
    }

    bool internal limitTokens = false;
    bool internal bankClosed = false;

    uint internal trxLimit = 100000e6;      // 100k trx
    uint internal tokenLimit = 1000e18;     // $1000
    uint internal minBuy = 1000e6;          // 1k trx
    uint internal minSell = 10e18;          // $10

    uint public feePercentage = 5;
    uint public payback;
    uint public paid;
    uint public trxEarned;
    uint public tokensEarned;

    Medianizer private median;
    Token private token;

    address private admin;

    constructor(address _token, address _median) public {
        token = Token(_token);
        median = Medianizer(_median);
        admin = msg.sender;
    }

    function bankData() public view returns (bool closed, uint market, uint buy, uint sell, uint tronBal, uint tokenBal) {
        closed = bankClosed;
        market = median.read();
        
        buy = (market / 100).mul(100 - feePercentage);
        sell = (market / 100).mul(100 + feePercentage);
        
        tronBal = address(this).balance;
        if (tronBal > trxLimit) {tronBal = trxLimit;}
        
        tokenBal = token.balanceOf(address(this));
        if (tokenBal > tokenLimit && limitTokens) {tokenBal = tokenLimit;}
    }

    function depositTrx() external payable onlyAdmin {
        uint market = median.read();
        payback += market * (msg.value / 1e6);
    }

    function deposit(uint amount) external onlyAdmin checkDeposit(amount) {
        token.transferFrom(admin, address(this), amount);
        payback += amount;
    }

    function toggleBank() external onlyAdmin {
        bankClosed = !bankClosed;
    }

    function toggleTokenLimit() external onlyAdmin {
        limitTokens = !limitTokens;
    }

    function changeLimits(uint _trxLimit, uint _tokenLimit) external onlyAdmin {
        trxLimit = _trxLimit;
        tokenLimit = _tokenLimit;
    }

    function changeMinimum(uint _minBuy, uint _minSell) external onlyAdmin {
        minBuy = _minBuy;
        minSell = _minSell;
    }

    function changeFee(uint _feePercentage) external onlyAdmin {
        require(_feePercentage <= 10, 'Chill out brother');
        feePercentage = _feePercentage;
    }

    function changeMedianizer(address _median) external onlyAdmin {
        median = Medianizer(_median);
        require(median.read() > 0, 'USDJ is fucked');
    }

    function withdraw(uint amount) external onlyAdmin {
        require(amount <= address(this).balance, 'Not enough TRX');
        address(admin).transfer(amount);
        paid += median.read() * (amount / 1e6);
    }

    function withdrawTokens(uint amount) external onlyAdmin {
        require(amount <= token.balanceOf(address(this)), 'Not enough tokens');
        token.transfer(address(admin), amount);
        paid += amount;
    }

    function buyTokens() external payable {
        require(!bankClosed, 'The bank has been declared non-essential');
        require(msg.value >= minBuy, 'No shrimp allowed');

        uint market = median.read();
        require(market > 0, 'USDJ is fucked');
        uint buyRate = (market / 100).mul(100 - feePercentage);

        uint received = buyRate * (msg.value / 1e6);
        require(received <= token.balanceOf(address(this)), 'Not enough minerals');

        tokensEarned += ((market * (msg.value) / 1e6) - received);
        token.transfer(msg.sender, received);

        if (address(this).balance > trxLimit) {splitTrx();}
        if (token.balanceOf(address(this)) > tokenLimit && limitTokens) {splitTokens();}
    }

    function sellTokens(uint amount) external checkDeposit(amount) {
        require(!bankClosed, 'The bank has been declared non-essential');
        require(amount >= minSell, 'No shrimp allowed');

        uint market = median.read();
        require(market > 0, 'USDJ is fucked');
        uint sellRate = (market / 100).mul(100 + feePercentage);

        uint received = (amount / sellRate) * 1e6;
        require(received <= address(this).balance, 'You require more vespene gas');

        trxEarned += (((amount / market) * 1e6) - received);

        token.transferFrom(msg.sender, address(this), amount);

        if (token.balanceOf(address(this)) > tokenLimit && limitTokens) {splitTokens();}
        address(msg.sender).transfer(received);
    }

    function splitTrx() internal {
        uint excess = address(this).balance - trxLimit;
        address(admin).transfer(excess);
        paid += median.read() * (excess / 1e6);
        return;
    }

    function splitTokens() internal {
        uint excess = token.balanceOf(address(this)) - tokenLimit;
        token.transfer(address(admin), excess);
        paid += excess;
        return;
    }

    function getSplit(uint num) internal pure returns (uint, uint, uint) {
        uint a = num / 10;
        uint b = num - a;
        uint c = b / 2;
        return ((b-c), c, a);
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {return 0;}
        uint c = a * b;
        require(c / a == b, "safemath mul");
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "safemath sub");
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "safemath add");
        return c;
    }
}