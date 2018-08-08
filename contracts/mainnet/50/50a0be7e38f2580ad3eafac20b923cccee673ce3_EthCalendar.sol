pragma solidity ^0.4.24;

contract EthCalendar {
    // Initial price of a day is 0.003 ETH
    uint256 constant initialDayPrice = 3000000000000000 wei;

    // Address of the contract owner
    address contractOwner;

    // Mapping of addresses to the pending withdrawal amount
    mapping(address => uint256) pendingWithdrawals;

    // Mapping of day ids to their structs
    mapping(uint16 => Day) dayStructs;

    // Fired when a day was bought
    event DayBought(uint16 dayId);

    // Holds all information about a day
    struct Day {
        address owner;
        string message;
        uint256 sellprice;
        uint256 buyprice;
    }

    // Set contract owner on deploy
    constructor() public {
        contractOwner = msg.sender;
    }

    // Ensures sender is the contract owner
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "sender must be contract owner");
        _;
    }

    // Ensures dayid is in valid range
    modifier onlyValidDay (uint16 dayId) {
        require(dayId >= 0 && dayId <= 365, "day id must be between 0 and 365");
        _;
    }

    // Ensures sender is the owner of a specific day
    modifier onlyDayOwner(uint16 dayId) {
        require(msg.sender == dayStructs[dayId].owner, "sender must be owner of day");
        _;
    }

    // Ensures sender is not the owner of a specific day
    modifier notDayOwner(uint16 dayId) {
        require(msg.sender != dayStructs[dayId].owner, "sender can&#39;t be owner of day");
        _;
    }

    // Ensures message is of a valid length
    modifier onlyValidMessage(string message) {
        require(bytes(message).length > 0, "message has to be set");
        _;
    }

    // Ensures the updated sellprice is below the here defined moving maximum.
    // The maximum is oriented to the price the day is bought.
    // Into baseprice the buyprice needs to be passed. This could be either msg.value or a stored value from previous tx.
    modifier onlyValidSellprice(uint256 sellprice, uint256 baseprice) {
        // Set the moving maximum to twice the paid amount
        require(sellprice > 0 && sellprice <= baseprice * 2, "new sell price must be lower than or equal to twice the paid price");
        _;
    }

    // Ensures the transfered value of the tx is large enough to pay for a specific day
    modifier onlySufficientPayment(uint16 dayId) {
        // The current price needs to be covered by the sent amount.
        // It is possible to pay more than needed.
        require(msg.value >= getCurrentPrice(dayId), "tx value must be greater than or equal to price of day");
        _;
    }

    // Any address can buy a day for the specified minimum price.
    // A sell price and a message need to be specified in this call.
    // The new sell price has a maximum of twice the paid amount.
    // A day can be bought for more than the specified sell price. So the maximum new sell price can be arbitrary high.
    function buyDay(uint16 dayId, uint256 sellprice, string message) public payable
        onlyValidDay(dayId)
        notDayOwner(dayId)
        onlyValidMessage(message)
        onlySufficientPayment(dayId)
        onlyValidSellprice(sellprice, msg.value) {

        if (hasOwner(dayId)) {
            // Day already has an owner
            // Contract owner takes 2% cut on transaction
            uint256 contractOwnerCut = (msg.value * 200) / 10000;
            uint256 dayOwnerShare = msg.value - contractOwnerCut;

            // Credit contract owner and day owner their shares
            pendingWithdrawals[contractOwner] += contractOwnerCut;
            pendingWithdrawals[dayStructs[dayId].owner] += dayOwnerShare;
        } else {
            // Day has no owner yet.
            // Contract owner gets credited the initial transaction
            pendingWithdrawals[contractOwner] += msg.value;
        }

        // Update the data of the day bought
        dayStructs[dayId].owner = msg.sender;
        dayStructs[dayId].message = message;
        dayStructs[dayId].sellprice = sellprice;
        dayStructs[dayId].buyprice = msg.value;

        emit DayBought(dayId);
    }

    // Owner can change price of his days
    function changePrice(uint16 dayId, uint256 sellprice) public
        onlyValidDay(dayId)
        onlyDayOwner(dayId)
        onlyValidSellprice(sellprice, dayStructs[dayId].buyprice) {
        dayStructs[dayId].sellprice = sellprice;
    }

    // Owner can change personal message of his days
    function changeMessage(uint16 dayId, string message) public
        onlyValidDay(dayId)
        onlyDayOwner(dayId)
        onlyValidMessage(message) {
        dayStructs[dayId].message = message;
    }

    // Owner can tranfer his day to another address
    function transferDay(uint16 dayId, address recipient) public
        onlyValidDay(dayId)
        onlyDayOwner(dayId) {
        dayStructs[dayId].owner = recipient;
    }

    // Returns day details
    function getDay (uint16 dayId) public view
        onlyValidDay(dayId)
    returns (uint16 id, address owner, string message, uint256 sellprice, uint256 buyprice) {
        return(  
            dayId,
            dayStructs[dayId].owner,
            dayStructs[dayId].message,
            getCurrentPrice(dayId),
            dayStructs[dayId].buyprice
        );    
    }

    // Returns the senders balance
    function getBalance() public view
    returns (uint256 amount) {
        return pendingWithdrawals[msg.sender];
    }

    // User can withdraw his balance
    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    // Returns whether or not the day is already bought
    function hasOwner(uint16 dayId) private view
    returns (bool dayHasOwner) {
        return dayStructs[dayId].owner != address(0);
    }

    // Returns the price the day currently can be bought for
    function getCurrentPrice(uint16 dayId) private view
    returns (uint256 currentPrice) {
        return hasOwner(dayId) ?
            dayStructs[dayId].sellprice :
            initialDayPrice;
    }
}