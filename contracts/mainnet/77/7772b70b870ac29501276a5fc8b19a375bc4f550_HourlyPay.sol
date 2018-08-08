pragma experimental "v0.5.0";

////////////////////
//   HOURLY PAY   //
//    CONTRACT    //
//    v 0.2.1     //
////////////////////

// The Hourly Pay Contract allows you to track your time and get paid a hourly wage for tracked time.
//
// HOW IT WORKS:
//
//  1. Client creates the contract, making himself the owner of the contract.
//
//  2. Client can fund the contract with ETH by simply sending money to the contract (via payable fallback function).
//
//  3. Before hiring someone, client can change additional parameters, such as:
//
//      - setContractDurationInDays(days) - The duration of the contract (default is 365 days).
//
//      - setDailyHourLimit(hours) - How much hours the Employee can work per day (default is 8 hours).
//
//      - setPaydayFrequencyInDays(days) - How often the Employee can withdraw the earnings (default is every 3 days).
//
//      - setBeginTimeTS(utcTimestamp) - Work on contract can be started after this timestamp (default is contract creation time).
//                                       Also defines the start of Day and Week for accounting and daily limits.
//                                       Day transition time should be convenient for the employee (like 4am),
//                                       so that work doesn&#39;t cross between days,
//                                       The excess won&#39;t be transferred to the next day.
//
//  4. Client hires the Employee by invoking hire(addressOfEmployee, ratePerHourInWei)
//     This starts the project and puts the contract in a workable state.
//     Before hiring, contract should be loaded with enough ETH to provide at least one day of work at specified ratePerHourInWei
// 
//  5. To start work and earn ETH the Employee should:
//
//      invoke startWork() when he starts working to run the timer.
//
//      invoke stopWork() when he finishes working to stop the timer.
//
//    After the timer is stopped - the ETH earnings are calculated and recorded on Employee&#39;s internal balance.
//    If the stopWork() is invoked after more hours had passed than dailyLimit - the excess is ignored
//    and only the dailyLimit is added to the internal balance.
//
//  6. Employee can withdraw earnings from internal balance after paydayFrequencyInDays days have passed after BeginTimeTS:
//      by invoking withdraw()
//
//    After each withdrawal the paydayFrequencyInDays is reset and starts counting itself from the TS of the first startWork() after withdrawal.
//
//    This delay is implemented as a safety mechanism, so the Client can have time to check the work and
//    cancel the earnings if something goes wrong.
//    That way only money earned during the last paydayFrequencyInDays is at risk.
//
//  7. Client can fire() the Employee after his services are no longer needed.
//    That would stop any ongoing work by terminating the timer and won&#39;t allow to start the work again.
//
//  8. If anything in the relationship or hour counting goes wrong, there are safety functions:
//      - refundAll() - terminates all unwithdrawn earnings.
//      - refund(amount) - terminates the (amount) of unwithdrawn earnings.
//    Can be only called if not working.
//    Both of these can be called by Client or Employee.
//      * TODO: Still need to think if allowing Client to do that won&#39;t hurt the Employee.
//      * TODO: SecondsWorkedToday don&#39;t reset after refund, so dailyLimit still affects
//      * TODO: Think of a better name. ClearEarnings?
//
//  9. Client can withdraw any excess ETH from the contract via:
//      - clientWithdrawAll() - withdraws all funds minus locked in earnings.
//      - clientWithdraw(amount) - withdraws (amount), not locked in earnings.
//     Can be invoked only if Employee isn&#39;t hired or has been fired.
//
// 10. Client and Contract Ownership can be made "Public"/"None" by calling:
//      - releaseOwnership()
//     It simply sets the Owner (Client) to 0x0, so no one is in control of the contract anymore.
//     That way the contract can be used on projects as Hourly-Wage Donations.
//
///////////////////////////////////////////////////////////////////////////////////////////////////

contract HourlyPay { 

    ////////////////////////////////
    // Addresses

    address public owner;           // Client and owner address
    address public employeeAddress = 0x0;  // Employee address


    /////////////////////////////////
    // Contract business properties
    
    uint public beginTimeTS;               // When the contract work can be started. Also TS of day transition.
    uint public ratePerHourInWei;          // Employee rate in wei
    uint public earnings = 0;              // Earnings of employee
    bool public hired = false;             // If the employee is hired and approved to perform work
    bool public working = false;           // Is employee currently working with timer on?
    uint public startedWorkTS;             // Timestamp of when the timer started counting time
    uint public workedTodayInSeconds = 0;  // How many seconds worked today
    uint public currentDayTS;
    uint public lastPaydayTS;
    string public contractName = "Hourly Pay Contract";

    ////////////////////////////////
    // Contract Limits and maximums
    
    uint16 public contractDurationInDays = 365;  // Overall contract duration in days, default is 365 and it&#39;s also maximum for safety reasons
    uint8 public dailyHourLimit = 8;               // Limits the hours per day, max 24 hours
    uint8 public paydayFrequencyInDays = 3;       // How often can Withdraw be called, default is every 3 days

    uint8 constant hoursInWeek = 168;
    uint8 constant maxDaysInFrequency = 30; // every 30 days is a wise maximum


    ////////////////
    // Constructor

    constructor() public {
        owner = msg.sender;
        beginTimeTS = now;
        currentDayTS = beginTimeTS;
        lastPaydayTS = beginTimeTS;
    }


    //////////////
    // Modifiers

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyEmployee {
        require(msg.sender == employeeAddress);
        _;
    }
    
    modifier onlyOwnerOrEmployee {
        require((msg.sender == employeeAddress) || (msg.sender == owner));
        _;
    }

    modifier beforeHire {
        require(employeeAddress == 0x0);                        // Contract can hire someone only once
        require(hired == false);                                // Shouldn&#39;t be already hired
        _;
    }


    ///////////
    // Events
    
    event GotFunds(address sender, uint amount);
    event ContractDurationInDaysChanged(uint16 contractDurationInDays);
    event DailyHourLimitChanged(uint8 dailyHourLimit);
    event PaydayFrequencyInDaysChanged(uint32 paydayFrequencyInDays);
    event BeginTimeTSChanged(uint beginTimeTS);
    event Hired(address employeeAddress, uint ratePerHourInWei, uint hiredTS);
    event NewDay(uint currentDayTS, uint16 contractDaysLeft);
    event StartedWork(uint startedWorkTS, uint workedTodayInSeconds, string comment);
    event StoppedWork(uint stoppedWorkTS, uint workedInSeconds, uint earned);
    event Withdrawal(uint amount, address employeeAddress, uint withdrawalTS);
    event Fired(address employeeAddress, uint firedTS);
    event Refunded(uint amount, address whoInitiatedRefund, uint refundTS);
    event ClientWithdrawal(uint amount, uint clientWithdrawalTS);
    event ContractNameChanged(string contractName);
    
    ////////////////////////////////////////////////
    // Fallback function to fund contract with ETH
    
    function () external payable {
        emit GotFunds(msg.sender, msg.value);
    }
    
    
    ///////////////////////////
    // Main Setters

    function setContractName(string newContractName) external onlyOwner beforeHire {
        contractName = newContractName;
        emit ContractNameChanged(contractName);
    }

    function setContractDurationInDays(uint16 newContractDurationInDays) external onlyOwner beforeHire {
        require(newContractDurationInDays <= 365);
        contractDurationInDays = newContractDurationInDays;
        emit ContractDurationInDaysChanged(contractDurationInDays);
    }
    
    function setDailyHourLimit(uint8 newDailyHourLimit) external onlyOwner beforeHire {
        require(newDailyHourLimit <= 24);
        dailyHourLimit = newDailyHourLimit;
        emit DailyHourLimitChanged(dailyHourLimit);
    }

    function setPaydayFrequencyInDays(uint8 newPaydayFrequencyInDays) external onlyOwner beforeHire {
        require(newPaydayFrequencyInDays < maxDaysInFrequency);
        paydayFrequencyInDays = newPaydayFrequencyInDays;
        emit PaydayFrequencyInDaysChanged(paydayFrequencyInDays);
    }
    
    function setBeginTimeTS(uint newBeginTimeTS) external onlyOwner beforeHire {
        beginTimeTS = newBeginTimeTS;
        currentDayTS = beginTimeTS;
        lastPaydayTS = beginTimeTS;
        emit BeginTimeTSChanged(beginTimeTS);
    }
    
    ///////////////////
    // Helper getters
    
    function getWorkSecondsInProgress() public view returns(uint) {
        if (!working) return 0;
        return now - startedWorkTS;
    }
    
    function isOvertime() external view returns(bool) {
        if (workedTodayInSeconds + getWorkSecondsInProgress() > dailyHourLimit * 1 hours) return true;
        return false;
    }
    
    function hasEnoughFundsToStart() public view returns(bool) {
        return ((address(this).balance > earnings) &&
                (address(this).balance - earnings >= ratePerHourInWei * (dailyHourLimit * 1 hours - (isNewDay() ? 0 : workedTodayInSeconds)) / 1 hours));
    }
    
    function isNewDay() public view returns(bool) {
        return (now - currentDayTS > 1 days);
    }
    
    function canStartWork() public view returns(bool) {
        return (hired
            && !working
            && (now > beginTimeTS)
            && (now < beginTimeTS + (contractDurationInDays * 1 days))
            && hasEnoughFundsToStart()
            && ((workedTodayInSeconds < dailyHourLimit * 1 hours) || isNewDay()));
    }

    function canStopWork() external view returns(bool) {
        return (working
            && hired
            && (now > startedWorkTS));
    }

    function currentTime() external view returns(uint) {
        return now;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    ////////////////////////////
    // Main workflow functions

    function releaseOwnership() external onlyOwner {
        owner = 0x0;
    }

    function hire(address newEmployeeAddress, uint newRatePerHourInWei) external onlyOwner beforeHire {
        require(newEmployeeAddress != 0x0);                     // Protection from burning the ETH

        // Contract should be loaded with ETH for a minimum one day balance to perform Hire:
        require(address(this).balance >= newRatePerHourInWei * dailyHourLimit);
        employeeAddress = newEmployeeAddress;
        ratePerHourInWei = newRatePerHourInWei;
        
        hired = true;
        emit Hired(employeeAddress, ratePerHourInWei, now);
    }

    function startWork(string comment) external onlyEmployee {
        require(hired == true);
        require(working == false);
        
        require(now > beginTimeTS); // can start working only after contract beginTimeTS
        require(now < beginTimeTS + (contractDurationInDays * 1 days)); // can&#39;t start after contractDurationInDays has passed since beginTimeTS
        
        checkForNewDay();
        
        require(workedTodayInSeconds < dailyHourLimit * 1 hours); // can&#39;t start if already approached dailyHourLimit

        require(address(this).balance > earnings); // balance must be greater than earnings        

        // balance minus earnings must be sufficient for at least 1 day of work minus workedTodayInSeconds:
        require(address(this).balance - earnings >= ratePerHourInWei * (dailyHourLimit * 1 hours - workedTodayInSeconds) / 1 hours);
        
        if (earnings == 0) lastPaydayTS = now; // reset the payday timer TS if this is the first time work starts after last payday

        startedWorkTS = now;
        working = true;
        
        emit StartedWork(startedWorkTS, workedTodayInSeconds, comment);
    }
    
    function checkForNewDay() internal {
        if (now - currentDayTS > 1 days) { // new day
            while (currentDayTS < now) {
                currentDayTS += 1 days;
            }
            currentDayTS -= 1 days;
            workedTodayInSeconds = 0;
            emit NewDay(currentDayTS, uint16 ((beginTimeTS + (contractDurationInDays * 1 days) - currentDayTS) / 1 days));
        }
    }
    
    function stopWork() external onlyEmployee {
        stopWorkInternal();
    }
    
    function stopWorkInternal() internal {
        require(hired == true);
        require(working == true);
    
        require(now > startedWorkTS); // just a temporary overflow check, in case of miners manipulate time
        
        
        uint newWorkedTodayInSeconds = workedTodayInSeconds + (now - startedWorkTS);
        if (newWorkedTodayInSeconds > dailyHourLimit * 1 hours) { // check for overflow
            newWorkedTodayInSeconds = dailyHourLimit * 1 hours;   // and assign max dailyHourLimit if there is an overflow
        }
        
        uint earned = (newWorkedTodayInSeconds - workedTodayInSeconds) * ratePerHourInWei / 1 hours;
        earnings += earned; // add new earned ETH to earnings
        
        emit StoppedWork(now, newWorkedTodayInSeconds - workedTodayInSeconds, earned);

        workedTodayInSeconds = newWorkedTodayInSeconds; // updated todays works in seconds
        working = false;

        checkForNewDay();
    }

    function withdraw() external onlyEmployee {
        require(working == false);
        require(earnings > 0);
        require(earnings <= address(this).balance);
        
        require(now - lastPaydayTS > paydayFrequencyInDays * 1 days); // check if payday frequency days passed after last withdrawal
        
        lastPaydayTS = now;
        uint amountToWithdraw = earnings;
        earnings = 0;
        
        employeeAddress.transfer(amountToWithdraw);
        
        emit Withdrawal(amountToWithdraw, employeeAddress, now);
    }
    
    function withdrawAfterEnd() external onlyEmployee {
        require(owner == 0x0); // only if there&#39;s no owner
        require(now > beginTimeTS + (contractDurationInDays * 1 days)); // only after contract end
        require(address(this).balance > 0); // only if there&#39;s balance

        employeeAddress.transfer(address(this).balance);
        emit Withdrawal(address(this).balance, employeeAddress, now);
    }
    
    function fire() external onlyOwner {
        if (working) stopWorkInternal(); // cease all motor functions if working
        
        hired = false; // fire
        
        emit Fired(employeeAddress, now);
    }

    function refundAll() external onlyOwnerOrEmployee {    // terminates all unwithdrawn earnings.
        require(working == false);
        require(earnings > 0);
        uint amount = earnings;
        earnings = 0;

        emit Refunded(amount, msg.sender, now);
    }
    
    function refund(uint amount) external onlyOwnerOrEmployee {  // terminates the (amount) of unwithdrawn earnings.
        require(working == false);
        require(amount < earnings);
        earnings -= amount;

        emit Refunded(amount, msg.sender, now);
    }

    function clientWithdrawAll() external onlyOwner { // withdraws all funds minus locked in earnings.
        require(hired == false);
        require(address(this).balance > earnings);
        uint amount = address(this).balance - earnings;
        
        owner.transfer(amount);
        
        emit ClientWithdrawal(amount, now);
    }
    
    function clientWithdraw(uint amount) external onlyOwner { // withdraws (amount), if not locked in earnings.
        require(hired == false);
        require(address(this).balance > earnings);
        require(amount < address(this).balance);
        require(address(this).balance - amount > earnings);
        
        owner.transfer(amount);

        emit ClientWithdrawal(amount, now);
    }
}