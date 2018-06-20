pragma solidity ^0.4.17;


contract ItemSelling {
    using SafeMath for uint256;
    using ArrayUtils for uint256[];

    /* Events */
    event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
    event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
    event BuyBack (uint256 indexed _itemId, address indexed _owner, uint256 _price);
    event Transfer(address indexed _from, address indexed _to, uint256 _itemId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _itemId);
    event Dividends(address indexed _owner, uint _dividends);

    /* Items */
    struct Item {
        uint256 id;
        address owner;
        uint256 startingPrice;
        uint256 prevPrice;
        uint256 price;
        uint256 transactions;
    }

    /* Players */
    struct Player {
        address id;
        uint256 transactions;
        uint256 [] ownedItems;
        uint256 lastPayedDividends;
        mapping (uint => TxInfo) txHistory;
        uint historyIdx;
    }

    struct TxInfo {
        address owner;
        uint256 itemId; // if type == 2 than itemId contains number of items for dividens
        uint256 price;  // if type == 2 than field price holds dividens amount for player
        uint txType;  // 0 - sold, 1 - bougth, 2 -dividens
        uint timestamp;
    }

    mapping(uint => TxInfo) public txBuffer;
    uint private txBufferMaxSize;
    uint private txIdx = 0;
    uint private playerHistoryMaxSize;

    mapping (uint256 => Item) private items;
    uint256 [] private itemList;

    mapping(address => Player) private players;
    address[] private playerList;


    /* Administration utility */
    address private owner;
    mapping (address => bool) private admins;
    bool private erc721Enabled = false;
    mapping (uint256 => address) private approvedOfItem;

    uint256 private DIVIDEND_TRANSACTION_NUMBER = 300;
    uint256 private dividendTransactionCount = 0;
    uint256 private dividendsAmount = 0;
    uint256 private lastDividendsAmount = 0;

    /* Next price calculation table */
    uint256 private increaseLimit1 = 0.05 ether;
    uint256 private increaseLimit2 = 0.5 ether;
    uint256 private increaseLimit3 = 2.0 ether;
    uint256 private increaseLimit4 = 5.0 ether;

    uint256 private fee = 6;
    uint256 private fee100 = 106;

    /* Contract body */
    function ItemSelling() public {
        owner = msg.sender;
        admins[owner] = true;
        txBufferMaxSize = 15;
        txIdx = 0;
        playerHistoryMaxSize = 15;
    }

    /* Modifiers */
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender]);
        _;
    }

    modifier onlyERC721() {
        require(erc721Enabled);
        _;
    }

    /* Owner */
    function setOwner (address _owner) onlyOwner() public {
        owner = _owner;
    }

    /* Admins functions */
    function addAdmin (address _admin) onlyOwner() public {
        admins[_admin] = true;
    }

    function removeAdmin (address _admin) onlyOwner() public {
        delete admins[_admin];
    }

    function isAdmin (address _admin) public view returns (bool _isAdmin) {
        return admins[_admin];
    }

    // Unlocks ERC721 behaviour, allowing for trading on third party platforms.
    function enableERC721 () onlyOwner() public {
        erc721Enabled = true;
    }

    function getBalance() onlyOwner view public returns (uint256 _balance) {
        return address(this).balance;
    }

    /* Items */
    function addItem(uint256 _itemId, uint256 _price, address _owner) onlyAdmins public {
        require(_price > 0);
        require(items[_itemId].id == 0);

        Item storage item = items[_itemId];
        item.id = _itemId;
        item.owner = _owner;
        item.startingPrice = _price;
        item.prevPrice = _price;
        item.price = _price;
        item.transactions = 0;

        itemList.push(_itemId) - 1;
    }

    function addItems (uint256[] _itemIds, uint256[] _prices, address _owner) onlyAdmins() public {
        require(_itemIds.length == _prices.length);
        for (uint256 i = 0; i < _itemIds.length; i++) {
            addItem(_itemIds[i], _prices[i], _owner);
        }
    }

    function getItemIds() view public returns (uint256[]) {
        return itemList;
    }

    function getItemIdsPagable (uint256 _from, uint256 _pageSize) public view returns (uint256[] _items) {
        uint256[] memory page = new uint256[](_pageSize);

        for (uint256 i = 0; i < _pageSize; i++) {
            page[i] = itemList[_from + i];
        }
        return page;
    }

    function itemExists(uint256 _itemId) view public returns (bool _exists) {
        return items[_itemId].price > 0;
    }

    function getItem(uint256 _itemId) view public returns (uint256, address, uint256, uint256, uint256, uint256, uint256, uint256) {
        Item storage item = items[_itemId];
        return (item.id, item.owner, item.startingPrice, item.price, calculateNextPrice(item.price), buybackPriceOf(_itemId), item.transactions, item.prevPrice);
    }

    function totalItems() public view returns (uint256 _itemsNumber) {
        return itemList.length;
    }

    function getItemsByOwner (address _owner) public view returns (uint256[] _itemsIds) {
        return players[_owner].ownedItems;
    }

    function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
        if (_price < increaseLimit1) {
            return _price.mul(200).div(100).mul(fee100).div(100);
        } else if (_price < increaseLimit2) {
            return _price.mul(140).div(100).mul(fee100).div(100);
        } else if (_price < increaseLimit3) {
            return _price.mul(125).div(100).mul(fee100).div(100);
        } else if (_price < increaseLimit4) {
            return _price.mul(120).div(100).mul(fee100).div(100);
        } else {
            return _price.mul(119).div(100).mul(fee100).div(100);
        }
    }

    function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
        if (_price < increaseLimit1) {
            return _price.mul(fee).div(fee100); // 6%
        } else if (_price < increaseLimit2) {
            return _price.mul(fee).div(fee100); // 6%
        } else if (_price < increaseLimit3) {
            return _price.mul(fee).div(fee100); // 6%
        } else if (_price < increaseLimit4) {
            return _price.mul(fee).div(fee100); // 6%
        } else {
            return _price.mul(fee).div(fee100); // 6%
        }
    }

    function buybackPriceOf(uint256 _itemId) public view returns (uint256 _buybackPrice){
        uint256 price = items[_itemId].price;
        uint256 startPrice = items[_itemId].startingPrice;

        uint256 bp = price.div(10); // 10% = price * 10 / 100 or price / 10
        uint256 sp = startPrice.mul(100).div(fee100);
        return bp < sp ? sp : bp;
    }

    /* Players */
    function createPlayerIfNeeded(address _playerId) internal {

        if (players[_playerId].id == address(0)) {
            Player storage player = players[_playerId];
            player.id = _playerId;
            player.transactions = 0;
            player.ownedItems = new uint256[](0);
            player.historyIdx = 0;
            player.lastPayedDividends = 0;

            playerList.push(_playerId) -1;
        }
    }

    function getPlayer(address _playerId) view public returns (address, uint256, uint256, uint256, uint256) {
        return (players[_playerId].id, players[_playerId].ownedItems.length, calculatePlayerValue(_playerId), players[_playerId].transactions, players[_playerId].lastPayedDividends);
    }

    function getPlayerIds() view public returns (address[]) {
        return playerList;
    }

    function calculatePlayerValue(address _playerId) view public returns(uint256 _value) {
        uint256 value = 0;
        for(uint256 i = 0; i < players[_playerId].ownedItems.length; i++){
            value += items[players[_playerId].ownedItems[i]].price;
        }
        return value;
    }

    function addPlayerTxHistory(address _playerId, uint256 _itemId, uint256 _price, uint _txType, uint _timestamp) internal {
        if (!isAdmin(_playerId)){
            Player storage player = players[_playerId];

            player.txHistory[player.historyIdx].owner = _playerId;
            player.txHistory[player.historyIdx].itemId = _itemId;
            player.txHistory[player.historyIdx].price = _price;
            player.txHistory[player.historyIdx].txType = _txType;
            player.txHistory[player.historyIdx].timestamp = _timestamp;
            player.historyIdx = player.historyIdx < playerHistoryMaxSize - 1 ? player.historyIdx + 1 : 0;
        }
    }

    // history
    function playerTransactionList(address _playerId)
        view
        public
        returns (uint256[] _itemIds, uint256[] _prices, uint[] _types, uint[] _ts )
    {
      //  _owners  = new address[](playerHistoryMaxSize);
        _itemIds = new uint256[](playerHistoryMaxSize);
        _prices  = new uint256[](playerHistoryMaxSize);
        _types   = new uint256[](playerHistoryMaxSize);
        _ts      = new uint[](playerHistoryMaxSize);

        uint offset = playerHistoryMaxSize - 1;
        if (players[_playerId].historyIdx > 0) {offset = players[_playerId].historyIdx - 1;}
        for (uint i = 0; i < playerHistoryMaxSize; i++){
        //    _owners[i]  = txBuffer[offset].owner;
            _itemIds[i] = players[_playerId].txHistory[offset].itemId;
            _prices[i]  = players[_playerId].txHistory[offset].price;
            _types[i]   = players[_playerId].txHistory[offset].txType;
            _ts[i]      = players[_playerId].txHistory[offset].timestamp;

            offset = offset > 0 ?  offset - 1 : playerHistoryMaxSize - 1;
        }
    }

    /* Buy */
    function buy (uint256 _itemId) payable public {
        Item storage item = items[_itemId];

        require(item.price > 0);
        require(item.owner != address(0));
        require(msg.value >= item.price);
        require(item.owner != msg.sender);
        require(!isContract(msg.sender));
        require(msg.sender != address(0));

        address oldOwner = item.owner;
        address newOwner = msg.sender;
        uint256 price = item.price;
        uint256 excess = msg.value.sub(price);

        createPlayerIfNeeded(newOwner);

        _transfer(oldOwner, newOwner, _itemId);
        addTxInBuffer(newOwner, _itemId, price, 1, now);
        addPlayerTxHistory(newOwner, _itemId, price, 1, now);
        addPlayerTxHistory(oldOwner, _itemId, price, 0, now);
        item.prevPrice = price;
        item.price = calculateNextPrice(price);
        item.transactions += 1;

        players[newOwner].transactions += 1;

        emit Bought(_itemId, newOwner, price);
        emit Sold(_itemId, oldOwner, price);

        // Devevloper&#39;s cut which is left in contract and accesed by
        // `withdrawAll` and `withdrawAmountTo` methods.
        uint256 devCut = calculateDevCut(price);

        // Transfer payment to old owner minus the developer&#39;s cut.
        if (!isAdmin(oldOwner)){
            oldOwner.transfer(price.sub(devCut));
        }

        if (excess > 0) {
            newOwner.transfer(excess);
        }

        proceedDividends(devCut);
        handleDividends();
    }

    function buyback(uint256 _itemId) public {
        Item storage item = items[_itemId];

        require(item.price > 0);
        require(item.owner != address(0));
        require(item.owner == msg.sender);
        require(!isContract(msg.sender));
        require(msg.sender != address(0));

        uint256 bprice = buybackPriceOf(_itemId);

        require(address(this).balance >= bprice);

        address oldOwner = msg.sender;
        address newOwner = owner;

        _transfer(oldOwner, newOwner, _itemId);
        addTxInBuffer(oldOwner, _itemId, bprice, 0, now);
        addPlayerTxHistory(oldOwner, _itemId, bprice, 0, now);

        item.price = calculateNextPrice(bprice);
        oldOwner.transfer(bprice);
        emit Sold(_itemId, oldOwner, bprice);
        emit BuyBack(_itemId, oldOwner, bprice);
    }

    function _transfer(address _from, address _to, uint256 _itemId) internal {

        require(itemExists(_itemId));
        require(items[_itemId].owner == _from);
        require(_to != address(0));
        require(_to != address(this));

        items[_itemId].owner = _to;
     //   approvedOfItem[_itemId] = 0;

        if (!isAdmin(_to)) {
            players[_to].ownedItems.push(_itemId) -1;
        }

        if (!isAdmin(_from)) {
            uint256 idx = players[_from].ownedItems.indexOf(_itemId);
            players[_from].ownedItems.remove(idx);
        }

        emit Transfer(_from, _to, _itemId);
    }

    /* Dividens */
    function getLastDividendsAmount() view public returns (uint256 _dividends) {
      return lastDividendsAmount;
    }

    function setDividendTransactionNumber(uint256 _txNumber) onlyAdmins public {
        DIVIDEND_TRANSACTION_NUMBER = _txNumber;
    }

    function getDividendTransactionLeft () view public returns (uint256 _txNumber) {
      return DIVIDEND_TRANSACTION_NUMBER - dividendTransactionCount;
    }

    function getTotalVolume() view public returns (uint256 _volume) {
        uint256 sum = 0;
        for (uint256 i = 0; i < itemList.length; i++){
            if (!isAdmin(items[itemList[i]].owner)) {
                sum += items[itemList[i]].price;
            }
        }
        return sum;
    }

    function proceedDividends(uint256 _devCut) internal {
        dividendTransactionCount += 1;
        dividendsAmount += _devCut.div(5); // *0.2
    }

    function handleDividends() internal {
        if (dividendTransactionCount < DIVIDEND_TRANSACTION_NUMBER ) return;

        lastDividendsAmount = dividendsAmount;
        dividendTransactionCount = 0;
        dividendsAmount = 0;

        uint256 totalCurrentVolume = getTotalVolume();
        uint256 userVolume = 0;
        uint256 userDividens = 0;

        for (uint256 i = 0; i < playerList.length; i++) {
            userVolume = calculatePlayerValue(playerList[i]);
            players[playerList[i]].lastPayedDividends = 0;
            if (userVolume > 0) {
                userDividens = userVolume.mul(lastDividendsAmount).div(totalCurrentVolume);
                players[playerList[i]].lastPayedDividends = userDividens;

                addPlayerTxHistory(playerList[i], players[playerList[i]].ownedItems.length, userDividens, 2, now);
                emit Dividends(playerList[i], userDividens);

                playerList[i].transfer(userDividens);
            }
            userVolume = 0;
            userDividens = 0;
        }
    }

    /* Withdraw */
    function hardWithdrawAll() onlyOwner public {
        owner.transfer(address(this).balance);
    }

    function withdrawAmount(uint256 _amount) onlyOwner public {
        require(_amount <= address(this).balance);
        owner.transfer(_amount);
    }

    function calculateAllBuyBackSum() view public returns (uint256 _buyBackSum) {
        uint256 sum = 0;
        for (uint256 i = 0; i < itemList.length; i++) {
            if (!isAdmin(items[itemList[i]].owner)) {
                sum += buybackPriceOf(itemList[i]);
            }
        }
        return sum;
    }

    function softWithdraw() onlyOwner public {
        uint256 buyBackSum = calculateAllBuyBackSum();
        uint256 requiredFunds = dividendsAmount + buyBackSum;

        uint256 withdrawal = address(this).balance - requiredFunds;
        require(withdrawal > 0);

        owner.transfer(withdrawal);
    }

    /* ERC721 */
    function approvedFor(uint256 _itemId) public view returns (address _approved) {
        return approvedOfItem[_itemId];
    }

    function approve(address _to, uint256 _itemId) onlyERC721() public {
        require(msg.sender != _to);
        require(itemExists(_itemId));
        require(items[_itemId].owner == msg.sender);

        if (_to == 0) {
            if (approvedOfItem[_itemId] != 0) {
                delete approvedOfItem[_itemId];
                emit Approval(msg.sender, 0, _itemId);
            }
        } else {
            approvedOfItem[_itemId] = _to;
            emit Approval(msg.sender, _to, _itemId);
        }
    }

    /* Transferring a country to another owner will entitle the new owner the profits from `buy` */
    function transfer(address _to, uint256 _itemId) onlyERC721() public {
        require(msg.sender == items[_itemId].owner);
        createPlayerIfNeeded(_to);
        _transfer(msg.sender, _to, _itemId);
    }

    function transferFrom(address _from, address _to, uint256 _itemId) onlyERC721() public {
        require(approvedFor(_itemId) == msg.sender);
        createPlayerIfNeeded(_to);
        _transfer(_from, _to, _itemId);
    }

    /* transactions */

    function addTxInBuffer(address _owner, uint256 _itemId, uint256 _price, uint _txType, uint _timestamp) internal {
        txBuffer[txIdx].owner = _owner;
        txBuffer[txIdx].itemId = _itemId;
        txBuffer[txIdx].price = _price;
        txBuffer[txIdx].txType = _txType;
        txBuffer[txIdx].timestamp = _timestamp;
        txIdx = txIdx  < txBufferMaxSize - 1 ? txIdx + 1 : 0;
    }

    function transactionList()
        view
        public
        returns (address[] _owners, uint256[] _itemIds, uint256[] _prices, uint[] _types, uint[] _ts )
    {
        _owners  = new address[](txBufferMaxSize);
        _itemIds = new uint256[](txBufferMaxSize);
        _prices  = new uint256[](txBufferMaxSize);
        _types   = new uint256[](txBufferMaxSize);
        _ts      = new uint[](txBufferMaxSize);

        uint offset = txBufferMaxSize - 1;
        if (txIdx > 0) { offset = txIdx - 1;}
        for (uint i = 0; i < txBufferMaxSize; i++){
            _owners[i]  = txBuffer[offset].owner;
            _itemIds[i] = txBuffer[offset].itemId;
            _prices[i]  = txBuffer[offset].price;
            _types[i]   = txBuffer[offset].txType;
            _ts[i]      = txBuffer[offset].timestamp;

            offset = offset > 0 ?  offset - 1 : txBufferMaxSize - 1;
        }
    }


    /* Util */
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) } // solium-disable-line
        return size > 0;
    }

}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library ArrayUtils {

    function remove(uint256[] storage self, uint256 _removeIdx) internal {
        if (_removeIdx < 0 || _removeIdx >= self.length) return;

        for (uint i = _removeIdx; i < self.length - 1; i++){
            self[i] = self[i + 1];
        }
        self.length--;
    }

    function indexOf(uint[] storage self, uint value) internal view returns (uint) {
        for (uint i = 0; i < self.length; i++){
            if (self[i] == value) return i;
        }
        return uint(-1);
    }
}