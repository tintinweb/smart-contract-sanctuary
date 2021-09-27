// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";
import "./ERC20Burnable.sol";

/// @author Zarela Team 
/// @title Decentralized marketplace platform for peer-to-peer transferring of Biosignals
contract ZarelaSmartContract is ERC20 , ERC20Burnable {
    
    // token distribution 17m reward pool and 3m other(2m team , 1m fundraising)
    constructor() {
        _mint(msg.sender , 3000000000000000);
        _mint(address(this) , 17000000000000000);
    }

    event orderRegistered(
        address owner,
        uint orderId
        );
    event contributed(
        address contributor,
        address labrotory,
        uint orderId,
        address mage,
        uint difficulty
        );
    event orderFinished(
        uint orderId
        );
    event signalsApproved(
        uint orderId,
        uint confirmCount
        );
   
    uint public maxUserDailyReward = 50000000000 ; // Max User Daily Reward As BIOBIT + 50 + _decimals 
    uint public totalTokenReleaseDaily = 14400000000000 ; // Total Tokens That Release From Zarela Reward Pool Per Day 
    
    address payable[] public paymentQueue; // All addresses pending reward (angels or laboratory)
    uint public halvingCounter; // Halving Counter
    uint public countDown24Hours = block.timestamp; // Starting 24 hours Timer By Block Timestamp (From Deploy Zarela)
    uint public dayCounterOf20Months; // Day Counter Of 20 Months (590 days  =  20 months )
    uint public indexCounter; // Index Of Entered Contributors Array 
    uint public lastRewardableIndex; // Index Of Last Person Who Should Get Reward Until Yesterday
    uint public indexOfAddressPendingReward; // Index Of allAngelsAddresses Array Pending For Reward
    address addressOfPendingReward; // Address Of allAngelsAddresses Array Pending For Reward
    uint public paymentDay; // Payment Day
    uint public todayContributionsCount; // Count Of Today Contributions
    uint[] public dailyContributionsCount; //  Count Of Daily Contributions
    uint public bankBalance; // The Amount of Tokens Remained and Can Add to Rewarding for Next Day
    uint[] public remainedDailyTokens; // Daily Token Remained
    uint public indexOfZeroDailyTokens; // Index Of remainedDailyTokens Array That Before Day There is No Token
    uint public dayOfTokenBurning; // The Day That Token Will be Burned
    uint public zarelaDayCounter; // The Day Count Of Zarela Age
    uint[] public burnedTokensPerDay; // Array Of Burned Tokens Per Day
    uint[] public dailyRewardPerContributor; // Array Of Daily Reward Per Countributor
    uint[] public dailyBalance; // Array Of Daily Balance 
    uint public zarelaDifficultyOfDay; // The Difficulty Of Zarela Network Per Day
    bool public isZarelaEnd; // is Zarela End?
    
    struct Order {
        uint orderId; // Order ID
        string orderTitle; // Order Title
        address orderOwner; // Order Owner
        uint tokenPerContributor; // Allcoated Biobit Per Contributor
        uint tokenPerLaboratory;  // Allcoated Biobit Per Laboratory
        uint totalContributors; // Total Contributors
        string zPaper; // zPaper
        string description; // Description Of Order
        uint totalContributorsRemain; // Total Contributors Remain
        uint countOfRegisteredContributions; // Count of Registered Contributions
        uint registrationTime; // Order Registration Time
        string accessPublicKey; // Encryption Owner Public Key 
    }
    
    struct Category {
        string zarelaCategory; // Zarela Category (Hashtags)
        uint businessCategory; // Business Category
    } 
    
    struct OrderData {
        uint orderId; // Order ID
        uint[] dataRegistrationTime;  // Data Registration Time
        string[] ipfsHash; //  IPFS Hash Of Data (Stored In IPFS)
        string[] encryptionKey; // IPFS Hash of  Encrypted AES Secret Key (Stored In IPFS)
        address[] contributorAddresses; // Array Of Contributors addresses
        address[] laboratoryAddresses; // Array Of laboratory addresses
        bool[] whoGainedReward; // Array Of addresses that Gained the Reward  (true means angel and false means laboratory)
        bool[] isConfirmedByMage; // is Confirmed By Mage?
        uint[] zarelaDay; // in Which Zarela Day This Data is Imported
    }
    
    struct User {
        uint tokenGainedFromSC; // Total Tokens That User Gained From Smart Contract (Reward Pool)
        uint tokenGainedFromMages; // Total Tokens That User Gained From Mages
        uint[] angelContributedOrders; // Array Of Orderids That User is Contributed as Angel
        uint[] laboratoryContributedOrders;  // Array Of Orderids That User is Contributed as Hub
        uint[] ownedOrders; // Array Of Order ids That User is Owned
    }
    
    mapping(uint => OrderData) public orderDataMap;
    mapping(address => User) public userMap;
    Order[] public orders;
    Category[]public Categories;

    modifier onlyRequester(uint _Order_Number) {
        Order storage myorder = orders[_Order_Number];
        require(myorder.orderOwner == msg.sender, "You Are Not Owner");
        _;
    }
    
    modifier checkOrderId(uint _Order_Number) {
        Order storage myorder = orders[_Order_Number];
        require(_Order_Number == myorder.orderId , "This Order Number Is Not Correct");
        _;
    }
    
    modifier notNull(address _address) {
        require(address(0) != _address, "Send To The Zero Address");
        _;
    }
    
    /// @dev make any kind of request that may be answered with a file.This function is only called by Mage 
    function submitNewRequest(
        string memory _orderTitle,
        string memory _description,
        string memory _zPaper,
        uint _tokenPerContributor,
        uint _tokenPerLaboratory,
        uint _totalContributors,
        string memory _zarelaCategory,
        uint _businessCategory,
        string memory _accessPublicKey
    )
        public
    {
        require(_balances[msg.sender] >= ((_tokenPerContributor + _tokenPerLaboratory) * _totalContributors), "Your Token Is Not Enough");
        ERC20.transfer(address(this),((_tokenPerContributor + _tokenPerLaboratory) * _totalContributors));
        uint orderId = orders.length;
        orders.push(
            Order(
                orderId,
                _orderTitle,
                msg.sender,
                _tokenPerContributor,
                _tokenPerLaboratory,
                _totalContributors,
                _zPaper,
                _description,
                _totalContributors,
                0,
                block.timestamp,
                _accessPublicKey
                )
            );
        userMap[msg.sender].ownedOrders.push(orderId);
        Categories.push(
            Category(
                    _zarelaCategory,
                    _businessCategory
                )
            );
        emit orderRegistered(msg.sender, orderId);
    }
    
    
    /// @dev Send the angel signal to mage and save then signal IPFS Hash in the block.Also, due to the difficulty of the Zarela network,
    /// each user pays the Reward to a number of people in the non-Reward queue
    function contribute(
        uint _orderId,
        address payable _contributorAddress,
        address payable _laboratoryAddress,
        bool _isContributorGainReward, 
        address _orderOwner,
        string memory _ipfsHash,
        string memory _encryptionKey
    )
        public 
        checkOrderId (_orderId)
        notNull(_orderOwner)
        notNull(_contributorAddress)
        notNull(_laboratoryAddress)
        
    {
        require(orders[_orderId].totalContributorsRemain != 0 ,"Order Was Finished");
        require(_orderOwner ==  orders[_orderId].orderOwner , "Requester Address Was Not Entered Correctly");
        require(msg.sender == _laboratoryAddress || msg.sender == _contributorAddress , "You Are Not Angel Or Laboratory");
        if (isZarelaEnd != true) {
            address payable rewardRecipientAddress;
            if (_isContributorGainReward == true) {
                rewardRecipientAddress = _contributorAddress;
                orderDataMap[_orderId].whoGainedReward.push(true);
            } else {
                rewardRecipientAddress = _laboratoryAddress;
                orderDataMap[_orderId].whoGainedReward.push(false);
            }
            if (block.timestamp < countDown24Hours + 24 hours) {
                paymentQueue.push(rewardRecipientAddress);
                todayContributionsCount++;
            } else {
                paymentQueue.push(address(0));
                paymentQueue.push(rewardRecipientAddress);
                dailyContributionsCount.push(todayContributionsCount);
                if (dayCounterOf20Months >= 589) { //20 month
                    maxUserDailyReward = maxUserDailyReward / 2 ;
                    totalTokenReleaseDaily = totalTokenReleaseDaily / 2 ;
                    halvingCounter++;
                    dayCounterOf20Months = 0 ;
                }
                if (_balances[address(this)] >= totalTokenReleaseDaily) {
                    _balances[address(this)] = _balances[address(this)] - totalTokenReleaseDaily;
                    bankBalance+=(totalTokenReleaseDaily);
                } else if (bankBalance > 0 && _balances[address(this)] < totalTokenReleaseDaily) {
                    bankBalance+= totalTokenReleaseDaily;
                    totalTokenReleaseDaily = 0; 
                } else {
                    totalTokenReleaseDaily = 0;
                    isZarelaEnd = true;
                }
                
                remainedDailyTokens.push(totalTokenReleaseDaily);
                
                if (zarelaDayCounter >= 44) { // 45 days
                    bankBalance = bankBalance - (remainedDailyTokens[dayOfTokenBurning]);
                    burnedTokensPerDay.push(remainedDailyTokens[dayOfTokenBurning]);
                    remainedDailyTokens[dayOfTokenBurning] = 0;
                    dayOfTokenBurning++;
                }
                
                dailyBalance.push(bankBalance);
                
                if (maxUserDailyReward * dailyContributionsCount[zarelaDayCounter] >= bankBalance) {
                    dailyBalance[zarelaDayCounter] = bankBalance;
                    dailyRewardPerContributor.push(bankBalance/dailyContributionsCount[zarelaDayCounter]);
                    bankBalance = 0;
                } else {
                    dailyBalance[zarelaDayCounter] = maxUserDailyReward * dailyContributionsCount[zarelaDayCounter];
                    dailyRewardPerContributor.push(maxUserDailyReward);
                    bankBalance = bankBalance - (maxUserDailyReward * dailyContributionsCount[zarelaDayCounter]);
                }
               
                uint tempPrice = dailyBalance[zarelaDayCounter];
                
                if (tempPrice >= remainedDailyTokens[zarelaDayCounter]) {
                    tempPrice = tempPrice - (remainedDailyTokens[zarelaDayCounter]);
                    remainedDailyTokens[zarelaDayCounter] = 0;
                    while (tempPrice > 0) {
                        if (tempPrice > remainedDailyTokens[indexOfZeroDailyTokens]) {
                            tempPrice = tempPrice - (remainedDailyTokens[indexOfZeroDailyTokens]);
                            remainedDailyTokens[indexOfZeroDailyTokens] = 0;
                            indexOfZeroDailyTokens++;
                        } else {
                            remainedDailyTokens[indexOfZeroDailyTokens] =  remainedDailyTokens[indexOfZeroDailyTokens] - (tempPrice);
                            tempPrice = 0;
                        }
                    }
                } else {
                    remainedDailyTokens[zarelaDayCounter] = remainedDailyTokens[zarelaDayCounter] - tempPrice;
                }
                
                zarelaDifficultyOfDay = (lastRewardableIndex - indexOfAddressPendingReward) / dailyContributionsCount[zarelaDayCounter];
                
                if ((zarelaDayCounter - paymentDay) >= 7 && (lastRewardableIndex - indexOfAddressPendingReward) >= 384 ) {
                    zarelaDifficultyOfDay = 128;
                } else if (zarelaDifficultyOfDay < 5) {
                    zarelaDifficultyOfDay = 2**zarelaDifficultyOfDay;
                } else {
                    zarelaDifficultyOfDay = 32;
                }
                
                todayContributionsCount = 0;
                zarelaDayCounter++;
                dayCounterOf20Months++;
                countDown24Hours = block.timestamp;
    
            }
            if (paymentQueue[indexCounter] == address(0)) {
                lastRewardableIndex = indexCounter;
                _reward();
                indexCounter+=2;
                todayContributionsCount++;
            } else if (lastRewardableIndex != indexOfAddressPendingReward) {
                _reward();
                indexCounter++;
            } else {
                indexCounter++;
            }
        }
        
        orderDataMap[_orderId].orderId = _orderId;
        orders[_orderId].countOfRegisteredContributions++;
        orderDataMap[_orderId].ipfsHash.push(_ipfsHash);
        orderDataMap[_orderId].encryptionKey.push(_encryptionKey);
        orderDataMap[_orderId].contributorAddresses.push(_contributorAddress);
        orderDataMap[_orderId].laboratoryAddresses.push(_laboratoryAddress);
        orderDataMap[_orderId].isConfirmedByMage.push(false);
        orderDataMap[_orderId].dataRegistrationTime.push(block.timestamp);
        userMap[_contributorAddress].angelContributedOrders.push(_orderId);
        userMap[_laboratoryAddress].laboratoryContributedOrders.push(_orderId);
        orderDataMap[_orderId].zarelaDay.push(zarelaDayCounter);

        emit contributed(_contributorAddress , _laboratoryAddress ,_orderId ,_orderOwner ,zarelaDifficultyOfDay);
    }
    
    /// @dev Calculate and pay the Reward
    function _reward() private {
        uint temporary = indexOfAddressPendingReward;
        if (zarelaDifficultyOfDay == 128) {
            for (uint i= temporary; i < temporary + zarelaDifficultyOfDay; i++) {
                if (i >= lastRewardableIndex) {
                    break;
                }
                
                addressOfPendingReward = paymentQueue[i];
                
                if (addressOfPendingReward == address(0)) {
                    paymentDay++;
                    i++;
                    indexOfAddressPendingReward++;
                    addressOfPendingReward = paymentQueue[i];
                }
                
                _balances[addressOfPendingReward] = _balances[addressOfPendingReward] + ((dailyRewardPerContributor[paymentDay]));
                userMap[addressOfPendingReward].tokenGainedFromSC += (dailyRewardPerContributor[paymentDay]);
                indexOfAddressPendingReward++;
            }
        }
        if ((lastRewardableIndex - temporary) >= 16) {
            for (uint i = temporary  ; i < zarelaDifficultyOfDay + temporary ; i++) {
                if (i >= lastRewardableIndex) {
                    break;
                }
                
                addressOfPendingReward = paymentQueue[i];
                
                if (addressOfPendingReward == address(0)) {
                    paymentDay++;
                    i++;
                    indexOfAddressPendingReward++;
                    addressOfPendingReward = paymentQueue[i];
                }
                
                _balances[addressOfPendingReward] = _balances[addressOfPendingReward] + ((dailyRewardPerContributor[paymentDay]));
                userMap[addressOfPendingReward].tokenGainedFromSC += (dailyRewardPerContributor[paymentDay]);
                indexOfAddressPendingReward++;
            }
        } else if ((lastRewardableIndex - temporary) < 16) {
            for (uint i = temporary ; i < lastRewardableIndex ; i++) {
                addressOfPendingReward = paymentQueue[i];
                if (addressOfPendingReward == address(0)) {
                    paymentDay++;
                    i++;
                    indexOfAddressPendingReward++;
                    addressOfPendingReward = paymentQueue[i];
                }
                
                _balances[addressOfPendingReward] = _balances[addressOfPendingReward] + ((dailyRewardPerContributor[paymentDay]));
                userMap[addressOfPendingReward].tokenGainedFromSC += (dailyRewardPerContributor[paymentDay]);
                indexOfAddressPendingReward++;
            }
        }
    }
    
    /// @dev Confirm the signals sent by angels only by Requester (Mage) of that signal.
    /// The selection of files is based on their index.
    function confirmContributor(
        uint _orderId,
        uint[]memory _index
    )
        public 
        onlyRequester(_orderId)
        checkOrderId(_orderId)
    {
        Order storage myorder = orders[_orderId];
        require(_index.length >= 1,"You Should Select One At Least");
        require(_index.length <= myorder.totalContributorsRemain,"The number of entries is more than allowed");
        require(myorder.totalContributorsRemain != 0,"Your Order Is Done, And You Sent All of Rewards to Users");
        myorder.totalContributorsRemain = myorder.totalContributorsRemain - (_index.length);
        _balances[address(this)] = _balances[address(this)] - ( (myorder.tokenPerContributor + myorder.tokenPerLaboratory) *  _index.length);
        for (uint i;i < _index.length ; i++) {
            _balances[orderDataMap[_orderId].contributorAddresses[_index[i]]] = _balances[orderDataMap[_orderId].contributorAddresses[_index[i]]] + (myorder.tokenPerContributor);
            _balances[orderDataMap[_orderId].laboratoryAddresses[_index[i]]] = _balances[orderDataMap[_orderId].laboratoryAddresses[_index[i]]] + (myorder.tokenPerLaboratory);
            userMap[orderDataMap[_orderId].contributorAddresses[_index[i]]].tokenGainedFromMages+=(myorder.tokenPerContributor);
            userMap[orderDataMap[_orderId].laboratoryAddresses[_index[i]]].tokenGainedFromMages+=(myorder.tokenPerLaboratory);
            orderDataMap[_orderId].isConfirmedByMage[_index[i]] = true;
        }
        
        if (myorder.totalContributorsRemain == 0) {
            emit orderFinished(_orderId);
        }
        emit signalsApproved(_orderId,_index.length);
    }
    
    /// @dev retrieves the value of each the specefic order by `_orderId`
    /// @return the contributors addresses , the Laboratory addresses , Time to send that signal by the angel , Laboratory or angel gained reward? , Status (true , false) of confirmation , Zarela day sent that signal
    function getOrderData(
        uint _orderId
    )
        public
        checkOrderId (_orderId)
        view returns (
            address[] memory,
            address[] memory,
            uint[]memory,
            bool[]memory,
            bool[] memory,
            uint[] memory)
    {
        return (
            orderDataMap[_orderId].contributorAddresses,
            orderDataMap[_orderId].laboratoryAddresses,
            orderDataMap[_orderId].dataRegistrationTime,
            orderDataMap[_orderId].whoGainedReward,
            orderDataMap[_orderId].isConfirmedByMage,
            orderDataMap[_orderId].zarelaDay
            );
    }
    
    /// @dev Receive angels' signals by entering the orderId and just order's owner can access.
    /// @return ipfsHash,encryptionKey
    function ownerSpecificData(
        uint _orderId
        )
        public 
        onlyRequester(_orderId)
        checkOrderId(_orderId) 
        view returns
        (
            string[] memory,
            string[] memory
        )
    {
        return (orderDataMap[_orderId].ipfsHash,orderDataMap[_orderId].encryptionKey);
    }
    
    /// @dev Check the orders registered and contributed by the user (angel or mage) who calls the function
    /// @return _ownedOrders and _contributedOrders
    function orderResult()
        public view returns
    (uint[]memory _ownedOrders,
    uint[]memory _angelContributedOrders,
    uint[]memory _laboratoryContributedOrders)
    {
        return (
            userMap[msg.sender].ownedOrders,
            userMap[msg.sender].angelContributedOrders,
            userMap[msg.sender].laboratoryContributedOrders
        );
    }
    
    /// @dev Total number of orders registered in Zarela
    /// @return length of all orders that registered in zarela
    function orderSize()
        public view returns (uint){
        return orders.length;
    }
}