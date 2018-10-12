pragma solidity ^0.4.24;


contract Ownable 
{
    address public owner;
    address public newOwner;
    
    constructor() public 
    {
        owner = msg.sender;
    }

    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _owner) onlyOwner public 
    {
        require(_owner != 0);
        newOwner = _owner;
    }
    
    function confirmOwner() public 
    {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

library SafeMath 
{

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) 
    {

        if (_a == 0) { return 0; }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) 
    {
        return _a / _b;
    }


    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) 
    {
        assert(_b <= _a);
        return _a - _b;
    }


    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) 
    {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}


contract KassaNetwork is Ownable 
{

    using SafeMath for uint;

    string  public constant name    = &#39;Kassa 50/15&#39;;
    uint public startTimestamp = now;

    uint public constant procKoef = 10000;
    uint public constant perDay = 250;
    uint public constant fee = 800;
    uint public constant bonusReferrer = 700;

    uint public constant procReturn = 9000;


    uint public constant maxDepositDays = 60;


    uint public constant minimalDeposit = 0.1 ether;
    uint public constant maximalDeposit = 1 ether;

    uint public countInvestors = 0;
    uint public totalInvest = 0;
    uint public totalPenalty = 0;
    uint public totalSelfInvest = 0;
    uint public totalPaid = 0;

    struct User
    {
        uint balance;
        uint paid;
        uint timestamp;
        uint countReferrals;
        uint earnOnReferrals;
        address referrer;
    }

    mapping (address => User) private user;

    mapping (uint => uint) private usedDeposit;

    function getInteres(address addr) private view returns(uint) 
    {
        uint diffTime = user[addr].timestamp > 0 ? now.sub(user[addr].timestamp) : 0;

        uint diffDays = diffTime.div(24 hours);

        if( diffDays > maxDepositDays ) diffDays = maxDepositDays;

        return user[addr].balance.mul(perDay).mul(diffDays).div(procKoef);
    }

    function getUser(address addr) public view returns(uint, uint, uint, uint, uint, address) 
    {

        return (
            user[addr].balance,
            user[addr].paid,
            getInteres(addr),
            user[addr].countReferrals,
            user[addr].earnOnReferrals,
            user[addr].referrer
        );

    }




    function getCurrentDay() public view returns(uint nday) 
    {
        uint diffTime = now.sub(startTimestamp);
        nday = diffTime.div(24 hours);

        return nday;
    }


    function getCurrentDayDepositLimit() public view returns(uint limit) 
    {
        uint nDay = getCurrentDay();

        return getDayDepositLimit(nDay);
    }


    function getDayDepositLimit(uint nDay) public pure returns(uint limit) 
    {                         
        return 40 ether;
    }


    function() public payable 
    {
        processPayment(msg.value, msg.data);
    }



    function processPayment(uint moneyValue, bytes refData) private
    {

        if (msg.sender == owner) 
        { 
            totalSelfInvest = totalSelfInvest.add(moneyValue);
            return; 
        }

        if (moneyValue == 0) 
        { 
            sendPayment();
            return; 
        }


        if (moneyValue < minimalDeposit) 
        { 
            totalPenalty = totalPenalty.add(moneyValue);
            return; 
        }

        address referrer = bytesToAddress(refData);

        if (user[msg.sender].balance > 0 || 
            refData.length != 20 || 
            moneyValue > maximalDeposit ||
            referrer != owner &&
              (
                 user[referrer].balance <= 0 || 
                 referrer == msg.sender) 
              )
        { 
            uint amount = moneyValue.mul(procReturn).div(procKoef);

            totalPenalty = totalPenalty.add(moneyValue.sub(amount));

            msg.sender.transfer(amount);

            return; 
        }



        uint nDay = getCurrentDay();

        uint restDepositPerDay = getCurrentDayDepositLimit().sub(usedDeposit[nDay]);

        uint addDeposit = moneyValue;


        if (moneyValue > restDepositPerDay)
        {
            uint returnDeposit = moneyValue.sub(restDepositPerDay);

            uint returnAmount = returnDeposit.mul(procReturn).div(procKoef);

            addDeposit = addDeposit.sub(returnDeposit);

            totalPenalty = totalPenalty.add(returnDeposit.sub(returnAmount));

            msg.sender.transfer(returnAmount);
        }




        register(referrer);
        sendFee(addDeposit);
        sendReferrer(addDeposit);
        updateInvestBalance(addDeposit);
    }


    function register(address referrer) private 
    {
        user[msg.sender].timestamp = now;
        countInvestors++;

        user[msg.sender].referrer = referrer;
        user[referrer].countReferrals++;
    }

    function sendFee(uint addDeposit) private 
    {
        transfer(owner, addDeposit.mul(fee).div(procKoef));
    }

    function sendReferrer(uint addDeposit) private 
    {
        address referrer = user[msg.sender].referrer;

        uint amountReferrer = addDeposit.mul(bonusReferrer).div(procKoef);
        user[referrer].earnOnReferrals = user[referrer].earnOnReferrals.add(amountReferrer);
        transfer(referrer, amountReferrer);
    }

    function sendPayment() public 
    {
        uint amount = getInteres(msg.sender) - user[msg.sender].paid;
        if (amount > 0) 
        {
            transfer(msg.sender, amount);
        }

    }

    function updateInvestBalance(uint addDeposit) private 
    {
        user[msg.sender].balance = user[msg.sender].balance.add(addDeposit);
        totalInvest = totalInvest.add(addDeposit);
    }

    function transfer(address receiver, uint amount) private 
    {
        if (amount > 0) 
        {
            if (receiver != owner) { totalPaid = totalPaid.add(amount); }

            user[receiver].paid = user[receiver].paid.add(amount);

            if (amount > address(this).balance) 
            {
                selfdestruct(receiver);
            } 
            else 
            {
                receiver.transfer(amount);
            }
        }
    }

    function bytesToAddress(bytes source) private pure returns(address addr) 
    {
        assembly { addr := mload(add(source,0x14)) }
        return addr;
    }

}