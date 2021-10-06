/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity 0.8.9;

interface IBXRToken {
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract Sale {
    address public owner;
    address public updater;
    address public token;

    uint256 internal rate;
    uint256 internal constant RATE_DELIMITER = 1000;

    uint256 internal oldRate;
    uint256 internal rateUpdateDelay = 5 minutes;
    uint256 internal rateBecomesValidAt;

    event Purchase(address indexed buyer, uint256 amount);
    event RateUpdate(uint256 newRate, uint256 rateBecomesValidAt);
    event DelayUpdate(uint256 newDelay);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensReceived(uint256 amount);
    event ChangedUpdater(address indexed previousUpdater, address indexed newUpdater);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyUpdater() {
        require(msg.sender == updater, "This function is callable only by updater");
        _;
    }

    constructor(address _token, uint256 _rate) {
        require(_token != address(0));
        require(_rate != 0);

        owner = msg.sender;
        token = _token;
        rate = _rate;
    }

    function recieve() external payable {
        require(msg.data.length == 0);

        buy();
    }

    function updateRate(uint256 newRate) internal {
        require(newRate != 0);

        if (block.timestamp > rateBecomesValidAt) {
            oldRate = rate;
        }
        rate = newRate;
        rateBecomesValidAt = block.timestamp + rateUpdateDelay;
        emit RateUpdate(newRate, rateBecomesValidAt);
    }

    function updateRateByOwner(uint256 newRate) external onlyOwner {
        updateRate(newRate);
    }

    function updateRateByUpdater(uint256 newRate) external onlyUpdater {
        (uint256 future_rate, uint256 timePriorToApply) = futureRate();
        require(timePriorToApply == 0, "New rate hasn't been applied yet");
        uint256 newRateMultiplied = newRate * 100;
        require(newRateMultiplied / 100 == newRate, "Integer overflow");
        // No need to check previous rate for overflow as newRate is checked
        // uint256 rateMultiplied = rate * 100;
        // require(rateMultiplied / 100 == rate, "Integer overflow");
        require(newRate * 99 <= future_rate * 100, "New rate is too high");

        updateRate(newRate);
    }

    function changeRateUpdateDelay(uint256 newDelay) external onlyOwner {
        rateUpdateDelay = newDelay;
        emit DelayUpdate(newDelay);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0);

        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(address payable to) external onlyOwner {
        require(address(this).balance > 0);

        to.transfer(address(this).balance);
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0));

        emit OwnershipTransferred(owner, _owner);

        owner = _owner;
    }

    function tokenFallback(address, uint value, bytes calldata) external {
        require(msg.sender == token);

        emit TokensReceived(value);
    }

    function buy() public payable returns (uint256) {
        uint256 availableTotal = availableTokens();
        require(availableTotal > 0);

        uint256 amount = weiToTokens(msg.value);
        
        // actual = min(amount, availableTotal)
        uint256 actual = amount < availableTotal ? amount : availableTotal;

        require(IBXRToken(token).transfer(msg.sender, actual));

        if (amount != actual) {
            uint256 weiRefund = msg.value - tokensToWei(actual);
            payable(msg.sender).transfer(weiRefund);
        }

        emit Purchase(msg.sender, actual);

        return actual;
    }

    function currentRate() public view returns (uint256) {
        return (block.timestamp < rateBecomesValidAt) ? oldRate : rate;
    }

    function weiToTokens(uint256 weiAmount) public view returns (uint256) {
        uint256 exchangeRate = currentRate();

        return weiAmount * exchangeRate / RATE_DELIMITER;
    }

    function tokensToWei(uint256 tokensAmount) public view returns (uint256) {
        uint256 exchangeRate = currentRate();

        return tokensAmount * RATE_DELIMITER / exchangeRate;
    }

    function futureRate() public view returns (uint256, uint256) {
        return (block.timestamp < rateBecomesValidAt) ? (rate, rateBecomesValidAt - block.timestamp) : (rate, 0);
    }

    function availableTokens() public view returns (uint256) {
        return IBXRToken(token).balanceOf(address(this));
    }

    function changeUpdater(address _updater) external onlyOwner {
        require(_updater != address(0), "Invalid _updater address");

        emit ChangedUpdater(updater, _updater);

        updater = _updater;
    }
}