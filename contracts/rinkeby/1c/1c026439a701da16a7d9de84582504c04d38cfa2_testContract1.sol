/**
 *Submitted for verification at Etherscan.io on 2021-12-06
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


contract testContract1 {

    struct Client{
        address client;
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
        uint256 clientId;
        uint32[] tokenBought;
    }

    address public owner;
    address public bot;
    address public devTeam;
    address private opensea;
    address[] private whitelistedAddresses;
    uint256 private devBalance;
    mapping(address => bool) private addressIsWhitelisted;
    uint256 private subscriptionMinimalDuration;
    uint256 private constant inactivityThreshold = 30 days;


    uint256 private constant maxWithdrawFee = 10;
    uint256 private withdrawFee;
    uint256 private globalExtensionFee;
    uint256 private globalSubscriptionFee;

    bool private allowNewClient;
    bool private allowNewSubscription;
    bool private allowNewSubscriptionForWhitelistedOnly;
    mapping(address => bool) private nftCollectionAddressIsBanned;

    Client[] private clients;
    Subscription[] private subscriptions;
    mapping(address => uint256) private addressToClientId;
    mapping(uint256 => uint256[]) private clientIdToSubscriptionsId;
    mapping(address => uint256[]) private collectionAdrToSubscriptionId;

    event NewSubscription(address nftCollection);
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

    modifier customerOnly() {
        _isCustomer();
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

    function _isCustomer() internal view {
        require(
        addressToClientId[msg.sender] != uint256(0x0),
        "Not a Customer"
        );
    }

    modifier refundGas {
        require(msg.sender == bot);
        uint256 gasAtStart = gasleft();
        _;
        uint256 gasSpent = gasAtStart - gasleft() + 28925;
        (bool success, ) = devTeam.call{value:gasSpent * tx.gasprice}("");
        require(success, "Transfer failed.");
    }

    constructor(address _bot, address _devTeam, address _opensea, address[] memory _whitelistAddresses, uint _globalFee, uint _globalSubscriptionFee, uint _globalExtensionFee) {
        allowNewClient = true;
        withdrawFee = _globalFee;
        globalExtensionFee = _globalExtensionFee;
        globalSubscriptionFee = _globalSubscriptionFee;
        allowNewSubscription = true;
        // allowNewSubscriptionForWhitelistedOnly = false;
        subscriptionMinimalDuration = 14 days;
        // keep clients(0) for owner
        owner = msg.sender;
        createClient(msg.sender);
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

    function createClient(address _newClientAddress) private returns(uint256 _clientId) {
        require(allowNewClient == true, "Client creation is disabled.");
        uint activity = block.timestamp + inactivityThreshold;
        clients.push(Client(_newClientAddress, 0, uint32(withdrawFee), uint64(activity), allowNewClient));
        uint32 clientId = uint32(clients.length - 1);
        addressToClientId[_newClientAddress] = clientId;
        return clientId;
    }

    function createSubscription(address _nftCollectionAddress, uint256 _amount, uint256 _maxBuyPrice, uint256 _clientId) private {
        require(nftCollectionAddressIsBanned[_nftCollectionAddress] == false, "Reject disabled collection");
        uint expirationDate = block.timestamp + subscriptionMinimalDuration;
        uint32[] memory tokenBoughtList;
        subscriptions.push(Subscription(_nftCollectionAddress, _amount, _maxBuyPrice, uint64(expirationDate), _clientId, tokenBoughtList));
        uint256 subscriptionId = subscriptions.length - 1;
        collectionAdrToSubscriptionId[_nftCollectionAddress].push(subscriptionId);
        clientIdToSubscriptionsId[_clientId].push(subscriptionId);
    }

    function extendSubscription(address _nftCollectionAddress) customerOnly() public payable {
        uint256 clientId = addressToClientId[msg.sender];
        clients[clientId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        for (uint i = 0; i < clientIdToSubscriptionsId[clientId].length; i++){
            uint subId = clientIdToSubscriptionsId[clientId][i];
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
                clients[clientId].balance += addBalance;
                break;
            }
        }
    }

    function changeClientAddress(address _oldClientAddress, address _newClientAddress) ownerOnly() public {
        uint256 clientId = addressToClientId[_oldClientAddress];
        require(clientId != uint256(0x0), "The old address is not a client!");
        require(block.timestamp > clients[clientId].lastActivity + inactivityThreshold, "Address still in activity range");
        addressToClientId[_newClientAddress] = clientId;
        delete addressToClientId[_oldClientAddress];
        clients[clientId].lastActivity = uint64(block.timestamp + inactivityThreshold);
    }

    function addETHToSubscription(address _nftCollectionAddress) customerOnly() public payable {
        require(msg.value > 0, "Incorrect amount");
        uint256 clientId = addressToClientId[msg.sender];
        clients[clientId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        for (uint32 i = 0; i < clientIdToSubscriptionsId[clientId].length; i++){
            uint256 subId = clientIdToSubscriptionsId[clientId][i];
            if (subscriptions[subId].nftCollection == _nftCollectionAddress) {
                subscriptions[subId].balance += msg.value;
                clients[clientId].balance += msg.value;
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
        uint256 clientId = subscriptions[_subscriptionId].clientId;
        for (uint i = 0; i < clientIdToSubscriptionsId[clientId].length; i++){
            if (clientIdToSubscriptionsId[clientId][i] == _subscriptionId) {
                clientIdToSubscriptionsId[clientId][i] = clientIdToSubscriptionsId[clientId][clientIdToSubscriptionsId[clientId].length - 1];
                clientIdToSubscriptionsId[clientId].pop();
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
        uint256 clientId = addressToClientId[msg.sender];
        if (clientId == uint256(0x0)) {
            clientId = createClient(msg.sender);
        }
        require(clients[clientId].authorized, "Unauthorized client !!");
        clients[clientId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        for (uint i = 0; i < collectionAdrToSubscriptionId[_nftCollectionAddress].length; i++) {
            if (subscriptions[collectionAdrToSubscriptionId[_nftCollectionAddress][i]].expirationDate > block.timestamp)
                require(_maxBuyPriceForTokenInCollection > subscriptions[collectionAdrToSubscriptionId[_nftCollectionAddress][i]].maxBuyPrice, "Buy price for subscription is already in taken range");
            else {
                cleanSubscription(collectionAdrToSubscriptionId[_nftCollectionAddress][i]);
            }
        }
        createSubscription(_nftCollectionAddress, uint(msg.value), _maxBuyPriceForTokenInCollection, clientId);
        clients[clientId].balance += msg.value;
        emit NewSubscription(_nftCollectionAddress);
    }

    function setGlobalClientsCreationAutorization(bool _state) ownerOnly() public {
        allowNewClient = _state;
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

    function setClientAutorization(address _clientAddress, bool _authorized) ownerOnly() public {
        require(addressToClientId[_clientAddress] != uint256(0x0), "Unknown customer");
        uint clientId = addressToClientId[_clientAddress];
        clients[clientId].authorized = _authorized;
    }

    function setClientFee(address _clientAddress, uint _clientFee) ownerOnly() public {
        require(addressToClientId[_clientAddress] != uint256(0x0), "Unknown customer");
        require(_clientFee <= maxWithdrawFee, "_newFee exceed maximum withdraw fee allowed");
        uint clientId = addressToClientId[_clientAddress];
        clients[clientId].withdrawFee = uint32(_clientFee);
    }

    function transferNftOwnership(address _collectionAddress, address _to, uint _tokenId) private {
        ERC721 collectionContract = ERC721(_collectionAddress);
        collectionContract.transferFrom(address(this), _to, _tokenId);
    }

    function withdrawAllForCustomer() customerOnly() public {
        uint clientId = addressToClientId[msg.sender];
        uint[] memory subsId = clientIdToSubscriptionsId[clientId];
        for (uint i = 0; i < subsId.length; i++) {
            for (uint j = 0; j < subscriptions[subsId[i]].tokenBought.length; j++) {
                transferNftOwnership(subscriptions[subsId[i]].nftCollection, msg.sender, subscriptions[subsId[i]].tokenBought[j]);
            }
            cleanSubscription(subsId[i]);
        }
        (bool success, ) = msg.sender.call{value:clients[clientId].balance}("");
        require(success, "Transfer failed.");
        clients[clientId].balance = 0;
    }

    function closeAndWithdrawSubscription(address _nftContract) customerOnly() public {
        uint clientId = addressToClientId[msg.sender];
        uint amount = 0;
        clients[clientId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        uint[] memory subsId = clientIdToSubscriptionsId[clientId];
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
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed.");
        clients[clientId].balance -= amount;
    }

    function withdrawNFT(address _nftContract, uint _tokenId) customerOnly() public {
        uint clientId = addressToClientId[msg.sender];
        clients[clientId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        uint[] memory subsId = collectionAdrToSubscriptionId[_nftContract];
        for (uint i = 0; i < subsId.length; i++) {
            if (subscriptions[subsId[i]].clientId == clientId && subscriptions[subsId[i]].tokenBought.length > 0) {
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

    function withdrawAllNFT() customerOnly() public {
        uint clientId = addressToClientId[msg.sender];
        clients[clientId].lastActivity = uint64(block.timestamp + inactivityThreshold);
        uint[] memory subsId = clientIdToSubscriptionsId[clientId];
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
            (bool success, ) = devTeam.call{value:amount}("");
            require(success, "Transfer failed.");
            devBalance -= amount;
        }
    }

    function makeClientPay(uint subId, uint amount, uint clientWithdrawFee) private {
        uint fee = amount * clientWithdrawFee / 100;
        subscriptions[subId].balance -= amount + fee;   
        clients[subscriptions[subId].clientId].balance -= amount + fee;
        devBalance += fee;
    }

    function callAtomicMatch(address[14] memory addrs, uint[18] memory uints, uint8[8] memory feeMethodsSidesKindsHowToCalls, bytes memory calldataBuy, bytes memory calldataSell, bytes memory replacementPatternBuy, bytes memory replacementPatternSell, bytes memory staticExtradataBuy, bytes memory staticExtradataSell, uint8[2] memory vs, bytes32[5] memory rssMetadata) private {
        Exchange(opensea).atomicMatch_{value:uints[4]/10^18}(addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell, vs, rssMetadata);
    }

    function checkIfOrdersValid(address _nftCollection, uint[] memory _prices) botOnly() view public returns (bool[] memory) {
        uint[] memory subsId = collectionAdrToSubscriptionId[_nftCollection];
        bool[] memory priceValid = new bool[](_prices.length);
        for (uint j = 0; j < _prices.length; j++) {
            for (uint i = 0; i < subsId.length; i++) {
                if (subscriptions[subsId[i]].maxBuyPrice >= _prices[j] && subscriptions[subsId[i]].expirationDate >= block.timestamp && subscriptions[subsId[i]].balance >= _prices[j] + _prices[j] * clients[subscriptions[subsId[i]].clientId].withdrawFee / 100) {
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
            if (subscriptions[subsId[i]].maxBuyPrice >= uints[4] && subscriptions[subsId[i]].expirationDate >= block.timestamp && subscriptions[subsId[i]].balance >= uints[4] + uints[4] * clients[subscriptions[subsId[i]].clientId].withdrawFee / 100) {
                callAtomicMatch(addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell, vs, rssMetadata);
                makeClientPay(subsId[i], uints[4], clients[subscriptions[subsId[i]].clientId].withdrawFee);
                subscriptions[subsId[i]].tokenBought.push(uint32(_tokenId));
            }
        }
    }
    
    function getClientAutorization(address _clientAddress) ownerOnly() public view returns (bool) {
        return clients[addressToClientId[_clientAddress]].authorized;
    }

    function getDevTeamBalance() devTeamOnly() public view returns (uint) {
        return uint(devBalance);
    }

    function getMyBalanceForSubscription(address _collectionAdr) public view returns (uint) {
        require(collectionAdrToSubscriptionId[_collectionAdr].length > 0);
        uint clientId = addressToClientId[msg.sender];
        for (uint i = 0;i < collectionAdrToSubscriptionId[_collectionAdr].length;i++){
            if (subscriptions[i].clientId == clientId)
                return (subscriptions[i].balance);
        }
        return 0;
    }

    function getMyBalance() customerOnly() public view returns (uint) {
        return (clients[addressToClientId[msg.sender]].balance);
    }

    function getMyFee() customerOnly() public view returns (uint) {
        return (clients[addressToClientId[msg.sender]].withdrawFee);
    }

    function getClientBalance(address _clientAddress) ownerOnly() public view returns (uint) {
        require(addressToClientId[_clientAddress] != uint256(0x0), "Unknown customer");
        return uint(clients[addressToClientId[_clientAddress]].balance);
    }

    function getClientFee(address _clientAddress) ownerOnly() public view returns (uint) {
        require(addressToClientId[_clientAddress] != uint256(0x0), "Unknown customer");
        return uint(clients[addressToClientId[_clientAddress]].withdrawFee);
    }

    function getNftCollectionBanState(address _nftCollectionAddress) public view returns (bool) {
        return nftCollectionAddressIsBanned[_nftCollectionAddress];
    }

    function getCreationAutorization() ownerOnly() public view returns(bool, bool, bool){
        return (allowNewSubscription, allowNewSubscriptionForWhitelistedOnly, allowNewClient);
    }
    
    function getFees() public view returns(uint, uint, uint) {
        return (globalSubscriptionFee, globalExtensionFee, withdrawFee);
    }

    function getWhitelistedAddresses() ownerOnly() public view returns (address[] memory) {
        return whitelistedAddresses;
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
        uint256 clientId = addressToClientId[msg.sender];
        require(clientIdToSubscriptionsId[clientId].length > 0, "You don't have subscription");
        uint tabSize = clientIdToSubscriptionsId[clientId].length;
        address[] memory nftCollections = new address[](tabSize);
        uint[] memory expirationDates = new uint[](tabSize);
        uint[] memory balances = new uint[](tabSize);
        uint[] memory maxBuyPrices = new uint[](tabSize);
        uint[] memory tokenBuyCounts = new uint[](tabSize);
        for (uint i = 0;i < tabSize;i++){
            uint id = clientIdToSubscriptionsId[clientId][i];
            nftCollections[i] = subscriptions[id].nftCollection;
            expirationDates[i] = subscriptions[id].expirationDate;
            balances[i] = subscriptions[id].balance;
            maxBuyPrices[i] = subscriptions[id].maxBuyPrice;
            tokenBuyCounts[i] = subscriptions[id].tokenBought.length;
        }
        return (nftCollections, expirationDates, balances, maxBuyPrices, tokenBuyCounts);
    }

}