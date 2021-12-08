/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Exchange {
  function atomicMatch_(
      address[14] memory addrs,
      uint[18] memory uints,
      uint8[8] memory feeMethodsSidesKindsHowToCalls,
      bytes memory calldataBuy,
      bytes memory calldataSell,
      bytes memory replacementPatternBuy,
      bytes memory replacementPatternSell,
      bytes memory staticExtradataBuy,
      bytes memory staticExtradataSell,
      uint8[2] memory vs,
      bytes32[5] memory rssMetadata)
      public
      virtual
      payable;
}

abstract contract ERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;
}


contract contractTest1 {

    struct User{
        address user;
        uint256 balance;
        uint32 withdrawFee;
        uint64 lastActivity;
        bool authorized;
    }


    struct Subscription{
        address nftCollection;
        uint256 balance;
        uint256 maxBuyPrice;
        uint64 expirationDate;
        uint256 userId;
        uint32[] tokenBought;
    }
    address private owner;
    address private bot;
    address private devTeam;
    address private opensea;
    address[] private whitelistedAddresses;
    uint256 private devBalance;
    mapping(address => bool) private addressIsWhitelisted;
    uint256 private subscriptionMinimalDuration;
    uint256 private constant inactivityThreshold = 30 days;

    // Fees
    uint256 private constant maxWithdrawFee = 10;
    uint256 private withdrawFee;
    uint256 private globalExtensionFee;
    uint256 private globalSubscriptionFee;

    bool private allowNewUser;
    bool private allowNewSubscription;
    bool private allowNewSubscriptionForWhitelistedOnly;
    mapping(address => bool) private nftCollectionAddressIsBanned;

    User[] private users;
    Subscription[] private subscriptions;
    mapping(address => uint256) private addressToUserId;
    mapping(uint256 => uint256[]) private userIdToSubscriptionsId;
    mapping(address => uint256[]) private collectionAdrToSubscriptionId;

    event NewSubscription(address nftCollection);
    event tokenBought(address nftCollection, uint tokenId);
    event emitU256(uint256 u);
    event emitU256Array(uint256[] u);

    modifier ownerOnly() {
        _isOwner();
        _;
    }

    modifier botOnly() {
        _isBot();
        _;
    }

    modifier devTeamOnly() {
        _isDevTeam();
        _;
    }

    modifier userOnly() {
        _isUser();
        _;
    }

    function _isOwner() internal view {
        require(
        msg.sender == owner,
        "Restricted to contract's owner"
        );
    }

    function _isBot() internal view {
        require(
        msg.sender == bot,
        "Restricted to contract's bot"
        );
    }

    function _isDevTeam() internal view {
        require(
        msg.sender == devTeam,
        "Restricted to contract's developer"
        );
    }

    function _isUser() internal view {
        require(
        addressToUserId[msg.sender] != uint256(0x0),
        "Not a User"
        );
    }

    modifier refundGas {
        require(msg.sender == bot);
        uint256 gasAtStart = gasleft();
        _;
        uint256 gasSpent = gasAtStart - gasleft() + 28925;
        devBalance += gasSpent * tx.gasprice;
    }

    constructor(address _bot, address _devTeam, address _opensea, address[] memory _whitelistAddresses, uint _globalFee, uint _globalSubscriptionFee, uint _globalExtensionFee) {
        allowNewUser = true;
        withdrawFee = _globalFee;
        globalExtensionFee = _globalExtensionFee;
        globalSubscriptionFee = _globalSubscriptionFee;
        allowNewSubscriptionForWhitelistedOnly = true;
        subscriptionMinimalDuration = 30 days;
        owner = msg.sender;
        createUser(msg.sender);
        bot = _bot;
        devTeam = _devTeam;
        opensea = _opensea;
        for (uint i=0;i < _whitelistAddresses.length;i++) {
            addressIsWhitelisted[_whitelistAddresses[i]] = true;
            whitelistedAddresses.push(_whitelistAddresses[i]);
        }
    }

    function transferBotOwnership(address _newBotAddress) ownerOnly() public {
        bot = _newBotAddress;
    }

    function transferOwnership(address _newOwnerAddress) ownerOnly() public {
        owner = _newOwnerAddress;
    }

    function removeWhitelistedAddress(address _whitelistedAddress) ownerOnly() public {
        require(addressIsWhitelisted[_whitelistedAddress] == true, "Address is not whitelisted");
        delete addressIsWhitelisted[_whitelistedAddress];
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _whitelistedAddress) {
                whitelistedAddresses[i] = whitelistedAddresses[whitelistedAddresses.length - 1];
                whitelistedAddresses.pop();
                break;
            }
        }
    }

    function addWhitelistedAddress(address _newWhitelistAddress) ownerOnly() public{
        require(addressIsWhitelisted[_newWhitelistAddress] == false, "Address is already whitelisted");
        addressIsWhitelisted[_newWhitelistAddress] = true;
        whitelistedAddresses.push(_newWhitelistAddress);
    }

    function createUser(address _newUserAddress) private returns(uint256 _userId) {
        require(allowNewUser == true, "User creation is disabled");
        uint activity = block.timestamp + inactivityThreshold;
        users.push(User(_newUserAddress, 0, uint32(withdrawFee), uint64(activity), allowNewUser));
        uint32 userId = uint32(users.length - 1);
        addressToUserId[_newUserAddress] = userId;
        return userId;
    }

    function createSubscription(address _nftCollectionAddress, uint256 _amount, uint256 _maxBuyPrice, uint256 _userId) private {
        require(nftCollectionAddressIsBanned[_nftCollectionAddress] == false, "Reject disabled collection");
        uint expirationDate = block.timestamp + subscriptionMinimalDuration;
        uint32[] memory tokenBoughtList;
        subscriptions.push(Subscription(_nftCollectionAddress, _amount, _maxBuyPrice, uint64(expirationDate), _userId, tokenBoughtList));
        uint256 subscriptionId = subscriptions.length - 1;
        collectionAdrToSubscriptionId[_nftCollectionAddress].push(subscriptionId);
        userIdToSubscriptionsId[_userId].push(subscriptionId);
    }

    function extendSubscription(address _nftCollectionAddress) userOnly() public payable {
        uint256 userId = addressToUserId[msg.sender];
        users[userId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        for (uint i = 0; i < userIdToSubscriptionsId[userId].length; i++){
            uint subId = userIdToSubscriptionsId[userId][i];
            if (subscriptions[subId].nftCollection == _nftCollectionAddress) {
                uint addBalance = msg.value;
                if (addressIsWhitelisted[msg.sender] == false) {
                    require(msg.value >= globalExtensionFee, "Not enough ETH to cover fee");
                    addBalance -= globalExtensionFee;
                    devBalance += globalExtensionFee;
                }
                uint expirationDate = block.timestamp + subscriptionMinimalDuration;
                subscriptions[subId].expirationDate = uint64(expirationDate);
                subscriptions[subId].balance += addBalance;
                users[userId].balance += addBalance;
                break;
            }
        }
    }

    function changeUserAddress(address _oldUserAddress, address _newUserAddress) ownerOnly() public {
        uint256 userId = addressToUserId[_oldUserAddress];
        require(userId != uint256(0x0), "The old address is not a user!");
        require(block.timestamp > users[userId].lastActivity + inactivityThreshold, "Address still in activity range");
        addressToUserId[_newUserAddress] = userId;
        delete addressToUserId[_oldUserAddress];
        users[userId].lastActivity = uint64(block.timestamp + inactivityThreshold);
    }

    function addETHToSubscription(address _nftCollectionAddress) userOnly() public payable {
        require(msg.value > 0, "Incorrect amount");
        uint256 userId = addressToUserId[msg.sender];
        users[userId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        for (uint32 i = 0; i < userIdToSubscriptionsId[userId].length; i++){
            uint256 subId = userIdToSubscriptionsId[userId][i];
            if (subscriptions[subId].nftCollection == _nftCollectionAddress) {
                subscriptions[subId].balance += msg.value;
                users[userId].balance += msg.value;
                break;
            }
        }
    }

    function cleanSubscription(uint _subscriptionId) private {
        address nftCollection = subscriptions[_subscriptionId].nftCollection;
        for (uint i = 0; i < collectionAdrToSubscriptionId[nftCollection].length; i++){
            if (collectionAdrToSubscriptionId[nftCollection][i] == _subscriptionId) {
                collectionAdrToSubscriptionId[nftCollection][i] = collectionAdrToSubscriptionId[nftCollection][collectionAdrToSubscriptionId[nftCollection].length - 1];
                collectionAdrToSubscriptionId[nftCollection].pop();
                break;
            }
        }
        uint256 userId = subscriptions[_subscriptionId].userId;
        for (uint i = 0; i < userIdToSubscriptionsId[userId].length; i++){
            if (userIdToSubscriptionsId[userId][i] == _subscriptionId) {
                userIdToSubscriptionsId[userId][i] = userIdToSubscriptionsId[userId][userIdToSubscriptionsId[userId].length - 1];
                userIdToSubscriptionsId[userId].pop();
                break;
            }
        }
        subscriptions[_subscriptionId] = subscriptions[subscriptions.length - 1];
        subscriptions.pop();
    }

    function subscribe(address _nftCollectionAddress, uint _maxBuyPriceForTokenInCollection) public payable {
        require(_maxBuyPriceForTokenInCollection > 0, "Incorrect max price");
        require(msg.value > _maxBuyPriceForTokenInCollection, "amount is <= max price");
        if (addressIsWhitelisted[msg.sender] == false) {
            require(allowNewSubscription, "Subscription currently disabled");
        } else {
            if (!allowNewSubscription)
                require(allowNewSubscriptionForWhitelistedOnly, "Subscription currently disabled");
        }
        uint256 userId = addressToUserId[msg.sender];
        if (userId == uint256(0x0)) {
            userId = createUser(msg.sender);
        }
        require(users[userId].authorized, "Unauthorized user !!");
        users[userId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        for (uint i = 0; i < collectionAdrToSubscriptionId[_nftCollectionAddress].length; i++) {
            if (subscriptions[collectionAdrToSubscriptionId[_nftCollectionAddress][i]].expirationDate > block.timestamp)
                require(_maxBuyPriceForTokenInCollection > subscriptions[collectionAdrToSubscriptionId[_nftCollectionAddress][i]].maxBuyPrice, "Buy price for subscription is already in taken range");
            else {
                cleanSubscription(collectionAdrToSubscriptionId[_nftCollectionAddress][i]);
            }
        }
        createSubscription(_nftCollectionAddress, uint(msg.value), _maxBuyPriceForTokenInCollection, userId);
        users[userId].balance += msg.value;
        emit NewSubscription(_nftCollectionAddress);
    }

    function setGlobalUsersCreationAutorization(bool _state) ownerOnly() public {
        allowNewUser = _state;
    }

    function setGlobalFee(uint _newFee) ownerOnly() public {
        require(_newFee <= maxWithdrawFee, "_newFee exceed maximum withdraw fee allowed");
        withdrawFee =_newFee;
    }

    function setGlobalExtensionFee(uint _newFee) ownerOnly() public {
        globalExtensionFee =_newFee;
    }

    function setGlobalSubscriptionFee(uint _newFee) ownerOnly() public {
        globalSubscriptionFee =_newFee;
    }

    function setGlobalSubscriptionCreationAutorization(bool _allowNewSubscription, bool _allowNewSubscriptionForWhitelistedOnly) ownerOnly() public {
        allowNewSubscription = _allowNewSubscription;
        allowNewSubscriptionForWhitelistedOnly = _allowNewSubscriptionForWhitelistedOnly;
    }

    function setNftCollectionBanState(address _nftCollectionAddress, bool _ban) ownerOnly() public {
        nftCollectionAddressIsBanned[_nftCollectionAddress] = _ban;
    }

    function setUserAutorization(address _userAddress, bool _authorized) ownerOnly() public {
        require(addressToUserId[_userAddress] != uint256(0x0), "Unknown user");
        uint userId = addressToUserId[_userAddress];
        users[userId].authorized = _authorized;
    }

    function setUserFee(address _userAddress, uint _userFee) ownerOnly() public {
        require(addressToUserId[_userAddress] != uint256(0x0), "Unknown user");
        require(_userFee <= maxWithdrawFee, "_newFee exceed maximum withdraw fee allowed");
        uint userId = addressToUserId[_userAddress];
        users[userId].withdrawFee = uint32(_userFee);
    }

    function transferNftOwnership(address _collectionAddress, address _to, uint _tokenId) private {
        ERC721 collectionContract = ERC721(_collectionAddress);
        collectionContract.transferFrom(address(this), _to, _tokenId);
    }

    function withdrawAllForUser() userOnly() public {
        uint userId = addressToUserId[msg.sender];
        uint[] memory subsId = userIdToSubscriptionsId[userId];
        for (uint i = 0; i < subsId.length; i++) {
            for (uint j = 0; j < subscriptions[subsId[i]].tokenBought.length; j++) {
                transferNftOwnership(subscriptions[subsId[i]].nftCollection, msg.sender, subscriptions[subsId[i]].tokenBought[j]);
            }
            cleanSubscription(subsId[i]);
        }
        uint amount = users[userId].balance;
        users[userId].balance = 0;
        payable(msg.sender).transfer(amount);
    }

    function closeAndWithdrawSubscription(address _nftContract) userOnly() public {
        uint userId = addressToUserId[msg.sender];
        uint amount = 0;
        users[userId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        uint[] memory subsId = userIdToSubscriptionsId[userId];
        for (uint i = 0; i < subsId.length; i++) {
            if (subscriptions[subsId[i]].nftCollection == _nftContract){
                amount += subscriptions[subsId[i]].balance;
                for (uint j = 0; j < subscriptions[subsId[i]].tokenBought.length; j++) {
                    transferNftOwnership(_nftContract, msg.sender, subscriptions[subsId[i]].tokenBought[j]);
                    delete subscriptions[subsId[i]].tokenBought[j];
                }
                cleanSubscription(subsId[i]);
            }
        }
        require(amount > 0, "No fund to withdraw");
        users[userId].balance -= amount;
        payable(msg.sender).transfer(amount);
    }

    function withdrawNFT(address _nftContract, uint _tokenId) userOnly() public {
        uint userId = addressToUserId[msg.sender];
        users[userId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        uint[] memory subsId = collectionAdrToSubscriptionId[_nftContract];
        for (uint i = 0; i < subsId.length; i++) {
            if (subscriptions[subsId[i]].userId == userId && subscriptions[subsId[i]].tokenBought.length > 0) {
                for (uint j = 0; j < subscriptions[subsId[i]].tokenBought.length; j++) {
                    if (subscriptions[subsId[i]].tokenBought[j] == _tokenId) {
                        transferNftOwnership(_nftContract, msg.sender, subscriptions[subsId[i]].tokenBought[j]);
                        delete subscriptions[subsId[i]].tokenBought[j];
                        return ;
                    }
                }
            }
        }
    }

    function withdrawAllNFT() userOnly() public {
        uint userId = addressToUserId[msg.sender];
        users[userId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        uint[] memory subsId = userIdToSubscriptionsId[userId];
        for (uint i = 0; i < subsId.length; i++) {
            if (subscriptions[subsId[i]].tokenBought.length > 0) {
                for (uint j = 0; j < subscriptions[subsId[i]].tokenBought.length; j++) {
                    transferNftOwnership(subscriptions[subsId[i]].nftCollection, msg.sender, subscriptions[subsId[i]].tokenBought[j]);
                    delete subscriptions[subsId[i]].tokenBought[j];
                }
            }
        }
    }

    function withdrawDevBalance(uint _amount) devTeamOnly() public {
        uint amount = _amount;
        if (amount >= devBalance)
            amount = devBalance;
        if (amount != 0) {
            devBalance -= amount;
            payable(msg.sender).transfer(amount);
        }
    }

    function makeUserPay(uint subId, uint amount, uint userWithdrawFee) private {
        uint fee = amount * userWithdrawFee / 100;
        subscriptions[subId].balance -= amount + fee;   
        users[subscriptions[subId].userId].balance -= amount + fee;
        devBalance += fee;
    }

    function callAtomicMatch(address[14] memory addrs, uint[18] memory uints, uint8[8] memory feeMethodsSidesKindsHowToCalls, bytes memory calldataBuy, bytes memory calldataSell, bytes memory replacementPatternBuy, bytes memory replacementPatternSell, bytes memory staticExtradataBuy, bytes memory staticExtradataSell, uint8[2] memory vs, bytes32[5] memory rssMetadata) private {

        (bool success, ) = address(opensea).call{value:uints[4]/10^18}(abi.encodeWithSignature("atomicMatch_(address[14], uint[18], uint8[8], bytes, bytes, bytes, bytes, bytes, bytes, uint8[2], bytes32[5])", addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell, vs, rssMetadata));
        require(success, "atomicMatch call failed");
    }

    function checkIfOrdersValid(address _nftCollection, uint[] memory _prices) botOnly() view public returns (bool[] memory) {
        uint[] memory subsId = collectionAdrToSubscriptionId[_nftCollection];
        bool[] memory priceValid = new bool[](_prices.length);
        for (uint j = 0; j < _prices.length; j++) {
            for (uint i = 0; i < subsId.length; i++) {
                if (subscriptions[subsId[i]].maxBuyPrice >= _prices[j] && subscriptions[subsId[i]].expirationDate >= block.timestamp && subscriptions[subsId[i]].balance >= _prices[j] + _prices[j] * users[subscriptions[subsId[i]].userId].withdrawFee / 100) {
                    priceValid[j] = true;
                }
                else if (i == subsId.length - 1) {
                    priceValid[j] = false;
                }
            }
        }
        return (priceValid);
    }

    function createOrder(address[14] memory addrs, uint[18] memory uints, uint8[8] memory feeMethodsSidesKindsHowToCalls, bytes memory calldataBuy, bytes memory calldataSell, bytes memory replacementPatternBuy, bytes memory replacementPatternSell, bytes memory staticExtradataBuy, bytes memory staticExtradataSell, uint8[2] memory vs, bytes32[5] memory rssMetadata, uint256 _tokenId) botOnly() public {
        require(collectionAdrToSubscriptionId[addrs[4]].length > 0);
        uint[] memory subsId = collectionAdrToSubscriptionId[addrs[4]];
        for (uint i = 0; i < subsId.length; i++) {
            if (subscriptions[subsId[i]].maxBuyPrice >= uints[4] && subscriptions[subsId[i]].expirationDate >= block.timestamp && subscriptions[subsId[i]].balance >= uints[4] + uints[4] * users[subscriptions[subsId[i]].userId].withdrawFee / 100) {
                callAtomicMatch(addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell, vs, rssMetadata);
                makeUserPay(subsId[i], uints[4], users[subscriptions[subsId[i]].userId].withdrawFee);
                subscriptions[subsId[i]].tokenBought.push(uint32(_tokenId));
                emit tokenBought(addrs[4], _tokenId);
                return ;
            }
        }
    }
    
    function getUserAutorization(address _userAddress) ownerOnly() public view returns (bool) {
        return users[addressToUserId[_userAddress]].authorized;
    }

    function getDevTeamBalance() devTeamOnly() public view returns (uint) {
        return uint(devBalance);
    }

    function getMyBalanceForSubscription(address _collectionAdr) public view returns (uint) {
        require(collectionAdrToSubscriptionId[_collectionAdr].length > 0);
        uint userId = addressToUserId[msg.sender];
        for (uint i = 0;i < collectionAdrToSubscriptionId[_collectionAdr].length;i++){
            if (subscriptions[i].userId == userId)
                return (subscriptions[i].balance);
        }
        return 0;
    }

    function getMyBalance() userOnly() public view returns (uint) {
        return (users[addressToUserId[msg.sender]].balance);
    }

    function getMyFee() userOnly() public view returns (uint) {
        return (users[addressToUserId[msg.sender]].withdrawFee);
    }

    function getUserBalance(address _userAddress) ownerOnly() public view returns (uint) {
        require(addressToUserId[_userAddress] != uint256(0x0), "Unknown user");
        return uint(users[addressToUserId[_userAddress]].balance);
    }

    function getUserFee(address _userAddress) ownerOnly() public view returns (uint) {
        require(addressToUserId[_userAddress] != uint256(0x0), "Unknown user");
        return uint(users[addressToUserId[_userAddress]].withdrawFee);
    }

    function getNftCollectionBanState(address _nftCollectionAddress) public view returns (bool) {
        return nftCollectionAddressIsBanned[_nftCollectionAddress];
    }

    function getCreationAutorization() ownerOnly() public view returns(bool, bool, bool){
        return (allowNewSubscription, allowNewSubscriptionForWhitelistedOnly, allowNewUser);
    }
    
    function getFees() public view returns(uint, uint, uint) {
        return (globalSubscriptionFee, globalExtensionFee, withdrawFee);
    }

    function getWhitelistedAddresses() ownerOnly() public view returns (address[] memory) {
        return whitelistedAddresses;
    }

    function getAddresses() ownerOnly() public view returns (address[3] memory) {
        return [owner, bot, devTeam];
    }

    function getSubscriptions() ownerOnly() public view 
    returns(address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        uint tabSize = subscriptions.length;
        address[] memory nftCollections = new address[](tabSize);
        uint[] memory expirationDates = new uint[](tabSize);
        uint[] memory balances = new uint[](tabSize);
        uint[] memory maxBuyPrices = new uint[](tabSize);
        uint[] memory tokenBuyCounts = new uint[](tabSize);
        for (uint i = 0; i < tabSize; i++){
            nftCollections[i] = subscriptions[i].nftCollection;
            expirationDates[i] = subscriptions[i].expirationDate;
            balances[i] = subscriptions[i].balance;
            maxBuyPrices[i] = subscriptions[i].maxBuyPrice;
            tokenBuyCounts[i] = subscriptions[i].tokenBought.length;
        }
        return (nftCollections, expirationDates, balances, maxBuyPrices, tokenBuyCounts);
    }

    function getMySubscriptions() public view 
    returns(address[] memory, uint[] memory, uint[] memory, uint[] memory, uint[] memory){
        uint256 userId = addressToUserId[msg.sender];
        require(userIdToSubscriptionsId[userId].length > 0, "You don't have subscription");
        uint tabSize = userIdToSubscriptionsId[userId].length;
        address[] memory nftCollections = new address[](tabSize);
        uint[] memory expirationDates = new uint[](tabSize);
        uint[] memory balances = new uint[](tabSize);
        uint[] memory maxBuyPrices = new uint[](tabSize);
        uint[] memory tokenBuyCounts = new uint[](tabSize);
        for (uint i = 0;i < tabSize;i++){
            uint id = userIdToSubscriptionsId[userId][i];
            nftCollections[i] = subscriptions[id].nftCollection;
            expirationDates[i] = subscriptions[id].expirationDate;
            balances[i] = subscriptions[id].balance;
            maxBuyPrices[i] = subscriptions[id].maxBuyPrice;
            tokenBuyCounts[i] = subscriptions[id].tokenBought.length;
        }
        return (nftCollections, expirationDates, balances, maxBuyPrices, tokenBuyCounts);
    }

}