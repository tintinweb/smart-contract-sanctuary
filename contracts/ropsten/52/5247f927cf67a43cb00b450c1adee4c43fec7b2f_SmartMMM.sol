pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

pragma solidity ^0.4.24;

contract SmartMMM is Ownable
{
    struct DepositItem {
        uint time;
        uint sum;
        uint withdrawalTime;
        uint restartIndex;
        uint invested;
        uint payments;
        uint referralPayments;
        uint cashback;
        uint referalsLevelOneCount;
        uint referalsLevelTwoCount;
        address referrerLevelOne;
        address referrerLevelTwo;
    }

    address public techSupport = 0x5e39ffdf3f816f1e75fc1e4cdcfd2c58ec562172;
    address public adsSupport = 0xcbed23447b3298f29a115664a445263e59d6c47b;

    mapping(address => DepositItem) public deposits;
    mapping(address => bool) public referrers;
    mapping(address => uint) public waitingReferrers;

    uint public referrerPrice = 70700000000000000; // 0.0707 ether
    uint public referrerBeforeEndTime = 0;
    uint public maxBalance = 0;
    uint public invested;
    uint public payments;
    uint public referralPayments;
    uint public investorsCount;
    uint[] public historyOfRestarts;

    event Deposit(address indexed from, uint256 value);
    event Withdraw(address indexed to, uint256 value);
    event PayBonus(address indexed to, uint256 value);

    constructor () public
    {
        historyOfRestarts.push(now);
    }


    function bytesToAddress(bytes source) private pure returns(address parsedAddress)
    {
        assembly {
            parsedAddress := mload(add(source,0x14))
        }
        return parsedAddress;
    }

    function getReferrersPercentsByBalance(uint balance) public pure returns(uint referrerLevelOnePercent, uint referrerLevelTwoPercent, uint cashBackPercent)
    {
        if(balance >= 0 && balance < 25000 ether) return (40, 10, 20);
        else if(balance >= 25000 ether && balance < 100000 ether) return (30, 0, 15);
        else if(balance >= 100000 ether && balance < 200000 ether) return (20, 0, 10);
        else if(balance >= 200000 ether && balance < 500000 ether) return (10, 0, 5);
        else return (6, 0, 3);
    }

    function getSupportsPercentsByBalance(uint balance) public pure returns(uint techSupportPercent, uint adsSupportPercent)
    {
        if(balance >= 0 && balance < 25000 ether) return (30, 70);
        else if(balance >= 25000 ether && balance < 100000 ether) return (20, 50);
        else if(balance >= 100000 ether && balance < 500000 ether) return (15, 40);
        else return (10, 30);
    }

    function getPercentByBalance(uint balance) public pure returns(uint)
    {
        if(balance < 25 ether) return 69444444444;
        else if(balance >= 25 ether && balance < 250 ether) return 104166666667;
        else if(balance >= 250 ether && balance < 2500 ether ) return 138888888889;
        else if(balance >= 2500 ether && balance < 25000 ether) return 173611111111;
        else if(balance >= 25000 ether && balance < 50000 ether) return 138888888889;
        else if(balance >= 50000 ether && balance < 100000 ether) return 104166666667;
        else if(balance >= 100000 ether && balance < 150000 ether) return 69444444444;
        else if(balance >= 150000 ether && balance < 200000 ether) return 55555555555;
        else if(balance >= 200000 ether && balance < 250000 ether) return 416666666667;
        else if(balance >= 250000 ether && balance < 300000 ether) return 277777777778;
        else if(balance >= 300000 ether && balance < 500000 ether) return 138888888889;
        else return 6944444444;
    }

    function () public payable
    {
        if(msg.value == 0)
        {
            payWithdraw(msg.sender);
            return;
        }

        if(msg.value == referrerPrice && !referrers[msg.sender] && waitingReferrers[msg.sender] == 0 && deposits[msg.sender].sum != 0)
        {
            waitingReferrers[msg.sender] = now;
        }
        else
        {
            addDeposit(msg.sender, msg.value);
        }
    }

    function isNeedRestart(uint balance) public returns (bool)
    {
        if(balance < maxBalance / 100 * 30) {
            maxBalance = 0;
            return true;
        }
        return false;
    }

    function calculateNewTime(uint oldTime, uint oldSum, uint newSum, uint currentTime) public pure returns (uint)
    {
        return oldTime + newSum / (newSum + oldSum) * (currentTime - oldTime);
    }

    function calculateNewDepositSum(uint minutesBetweenRestart, uint minutesWork, uint depositSum) public pure returns (uint)
    {
        if(minutesWork > minutesBetweenRestart) minutesWork = minutesBetweenRestart;
        return (depositSum *(100-(uint(minutesWork) * 100 / minutesBetweenRestart)+7)/100);
    }

    function addDeposit(address investorAddress, uint weiAmount) private
    {
        checkReferrer(investorAddress, weiAmount);
        DepositItem memory deposit = deposits[investorAddress];
        if(deposit.sum == 0)
        {
            deposit.time = now;
            investorsCount++;
        }
        else
        {
            uint sum = getWithdrawSum(investorAddress);
            deposit.sum += sum;
            deposit.time = calculateNewTime(deposit.time, deposit.sum, weiAmount, now);
        }
        deposit.withdrawalTime = now;
        deposit.sum += weiAmount;
        deposit.restartIndex = historyOfRestarts.length - 1;
        deposit.invested += weiAmount;
        deposits[investorAddress] = deposit;

        emit Deposit(investorAddress, weiAmount);

        payToSupport(weiAmount);

        if (maxBalance < address(this).balance) {
            maxBalance = address(this).balance;
        }
        invested += weiAmount;
    }

    function payToSupport(uint weiAmount) private {
        (uint techSupportPercent, uint adsSupportPercent) = getSupportsPercentsByBalance(address(this).balance);
        techSupport.transfer(weiAmount * techSupportPercent / 1000);
        adsSupport.transfer(weiAmount * adsSupportPercent / 1000);
    }

    function checkReferrer(address investorAddress, uint weiAmount) private
    {
        if (deposits[investorAddress].sum == 0 && msg.data.length == 20) {
            address referrerLevelOneAddress = bytesToAddress(bytes(msg.data));
            if (referrerLevelOneAddress != investorAddress && referrerLevelOneAddress != address(0)) {
                if (referrers[referrerLevelOneAddress] || waitingReferrers[referrerLevelOneAddress] != 0 && (now - waitingReferrers[referrerLevelOneAddress]) >= 7 days || now <= referrerBeforeEndTime) {
                    deposits[investorAddress].referrerLevelOne = referrerLevelOneAddress;
                    deposits[referrerLevelOneAddress].referalsLevelOneCount++;
                    address referrerLevelTwoAddress = deposits[referrerLevelOneAddress].referrerLevelOne;
                    if (referrerLevelTwoAddress != investorAddress && referrerLevelTwoAddress != address(0)) {
                        deposits[investorAddress].referrerLevelTwo = referrerLevelTwoAddress;
                        deposits[referrerLevelTwoAddress].referalsLevelTwoCount++;
                    }
                }
            }
        }
        if (deposits[investorAddress].referrerLevelOne != address(0)) {

            (uint referrerLevelOnePercent, uint referrerLevelTwoPercent, uint cashBackPercent) = getReferrersPercentsByBalance(address(this).balance);

            uint cashBackBonus = weiAmount * cashBackPercent / 1000;
            uint referrerLevelOneBonus = weiAmount * referrerLevelOnePercent / 1000;

            emit PayBonus(investorAddress, cashBackBonus);
            emit PayBonus(referrerLevelOneAddress, referrerLevelOneBonus);

            referralPayments += referrerLevelOneBonus;
            deposits[referrerLevelOneAddress].referralPayments += referrerLevelOneBonus;
            referrerLevelOneAddress.transfer(referrerLevelOneBonus);

            deposits[investorAddress].cashback += cashBackBonus;
            investorAddress.transfer(cashBackBonus);

            if (deposits[investorAddress].referrerLevelTwo != address(0) && referrerLevelTwoPercent > 0) {
                uint referrerLevelTwoBonus = weiAmount * referrerLevelTwoPercent / 1000;
                emit PayBonus(referrerLevelTwoAddress, referrerLevelTwoBonus);
                referralPayments += referrerLevelTwoBonus;
                deposits[referrerLevelTwoAddress].referralPayments += referrerLevelTwoBonus;
                referrerLevelTwoAddress.transfer(referrerLevelTwoBonus);
            }
        }
    }

    function payWithdraw(address to) private
    {
        require(deposits[to].sum > 0);

        uint balance = address(this).balance;
        if(isNeedRestart(balance))
        {
            historyOfRestarts.push(now);
        }

        uint lastRestartIndex = historyOfRestarts.length - 1;

        if(lastRestartIndex - deposits[to].restartIndex >= 1)
        {
            uint minutesBetweenRestart = (historyOfRestarts[lastRestartIndex] - historyOfRestarts[deposits[to].restartIndex]) / 1 minutes;
            uint minutesWork = (historyOfRestarts[lastRestartIndex] - deposits[to].time) / 1 minutes;
            deposits[to].sum = calculateNewDepositSum(minutesBetweenRestart, minutesWork, deposits[to].sum);
            deposits[to].restartIndex = lastRestartIndex;
            deposits[to].time = now;
        }

        uint sum = getWithdrawSum(to);
        require(sum > 0);

        deposits[to].withdrawalTime = now;
        deposits[to].payments += sum;
        payments += sum;
        to.transfer(sum);

        emit Withdraw(to, sum);
    }

    function getWithdrawSum(address investorAddress) private view returns(uint sum) {
        uint minutesCount = (now - deposits[investorAddress].withdrawalTime) / 1 minutes;
        uint percent = getPercentByBalance(address(this).balance);
        sum = deposits[investorAddress].sum * percent / 10000000000000000 * minutesCount;
    }

    function addReferrer(address referrerAddress) onlyOwner public
    {
        referrers[referrerAddress] = true;
    }

    function setReferrerPrice(uint newPrice) onlyOwner public
    {
        referrerPrice = newPrice;
    }

    function setReferrerBeforeEndTime(uint newTime) onlyOwner public
    {
        referrerBeforeEndTime = newTime;
    }

    function getDaysAfterStart() public constant returns(uint daysAfterStart) {
        daysAfterStart = (now - historyOfRestarts[0]) / 1 days;
    }

    function getDaysAfterLastRestart() public constant returns(uint daysAfeterLastRestart) {
        daysAfeterLastRestart = (now - historyOfRestarts[historyOfRestarts.length - 1]) / 1 days;
    }
}