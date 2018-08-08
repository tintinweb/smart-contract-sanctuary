pragma solidity ^0.4.19; // solhint-disable-line

library FifoLib {

    uint constant HEAD = 0;
    
    struct LinkedList {
        mapping (uint => uint) list;
        uint tail;
        uint size;
    }

    function size(LinkedList storage self)
        internal view returns (uint r) {
        return self.size;
    }

    function next(LinkedList storage self, uint n)
        internal view returns (uint) {
        return self.list[n];
    }

    // insert n after prev
    function insert(LinkedList storage self, uint prev, uint n) internal returns (uint) {
        require(n != HEAD && self.list[n] == HEAD && n != self.tail);
        self.list[n] = self.list[prev];
        self.list[prev] = n;
        self.size++;
        if (self.tail == prev) {
            self.tail = n;
        }
        return n;
    }
    
    // Remove node n preceded by prev
    function remove(LinkedList storage self, uint prev, uint n) internal returns (uint) {
        require(n != HEAD && self.list[prev] == n);
        self.list[prev] = self.list[n];
        delete self.list[n];
        self.size--;
        if (self.tail == n) {
            self.tail = prev;
        }
        return n;
    }

    function pushTail(LinkedList storage self, uint n) internal returns (uint) {
        return insert(self, self.tail, n);
    }
    
    function popHead(LinkedList storage self) internal returns (uint) {
        require(self.size > 0);
        return remove(self, HEAD, self.list[HEAD]);
    }
}

contract CompanyToken {
    event Founded(uint256 tokenId, string name, address owner, uint256 price);
    event SharesSold(uint256 tokenId, uint256 shares, uint256 price, address prevOwner, address newOnwer, string name);
    event Transfer(address from, address to, uint256 tokenId, uint256 shares);

    string public constant NAME = "CryptoCompanies"; // solhint-disable-line
    string public constant SYMBOL = "CompanyToken"; // solhint-disable-line

    uint256 private constant HEAD = 0;

    uint256 private startingPrice = 0.001 ether;
    uint256 private constant PROMO_CREATION_LIMIT = 5000;
    uint256 private firstStepLimit =  0.05 ether;
    uint256 private secondStepLimit = 0.5 ether;

    uint256 public commissionPoints = 5;

    // @dev max number of shares per company
    uint256 private constant TOTAL_SHARES = 100;

    // @dev companyIndex => (ownerAddress => numberOfShares)
    mapping (uint256 => mapping (address => uint256)) public companyIndexToOwners;

    struct Holding {
        address owner;
        uint256 shares;
    }

    // tokenId => holding fifo
    mapping (uint256 => FifoLib.LinkedList) private fifo;
    // tokenId => map(fifoIndex => holding)
    mapping (uint256 => mapping (uint256 => Holding)) private fifoStorage;

    mapping (uint256 => uint256) private fifoStorageKey;

    // number of shares traded
    // tokenId => circulatationCount
    mapping (uint256 => uint256) private circulationCounters;

    // @dev A mapping from CompanyIDs to the price of the token.
    mapping (uint256 => uint256) private companyIndexToPrice;

    // @dev Owner who has most shares 
    mapping (uint256 => address) private companyIndexToChairman;

    // @dev Whether buying shares is allowed. if false, only whole purchase is allowed.
    mapping (uint256 => bool) private shareTradingEnabled;


    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cooAddress;

    uint256 public promoCreatedCount;

    struct Company {
        string name;
    }

    Company[] private companies;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

    function CompanyToken() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    function createPromoCompany(address _owner, string _name, uint256 _price) public onlyCOO {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        address companyOwner = _owner;
        if (companyOwner == address(0)) {
            companyOwner = cooAddress;
        }

        if (_price <= 0) {
            _price = startingPrice;
        }

        promoCreatedCount++;
        _createCompany(_name, companyOwner, _price);
    }

    function createContractCompany(string _name) public onlyCOO {
        _createCompany(_name, address(this), startingPrice);
    }

    function setShareTradingEnabled(uint256 _tokenId, bool _enabled) public onlyCOO {
        shareTradingEnabled[_tokenId] = _enabled;
    }

    function setCommissionPoints(uint256 _point) public onlyCOO {
        require(_point >= 0 && _point <= 10);
        commissionPoints = _point;
    }

    function getCompany(uint256 _tokenId) public view returns (
        string companyName,
        bool isShareTradingEnabled,
        uint256 price,
        uint256 _nextPrice,
        address chairman,
        uint256 circulations
    ) {
        Company storage company = companies[_tokenId];
        companyName = company.name;
        isShareTradingEnabled = shareTradingEnabled[_tokenId];
        price = companyIndexToPrice[_tokenId];
        _nextPrice = nextPrice(_tokenId, price);
        chairman = companyIndexToChairman[_tokenId];
        circulations = circulationCounters[_tokenId];
    }

    function name() public pure returns (string) {
        return NAME;
    }

    function shareHoldersOf(uint256 _tokenId) public view returns (address[] memory addrs, uint256[] memory shares) {
        addrs = new address[](fifo[_tokenId].size);
        shares = new uint256[](fifo[_tokenId].size);

        uint256 fifoKey = FifoLib.next(fifo[_tokenId], HEAD);
        uint256 i;
        while (fifoKey != HEAD) {
            addrs[i] = fifoStorage[_tokenId][fifoKey].owner;
            shares[i] = fifoStorage[_tokenId][fifoKey].shares;
            fifoKey = FifoLib.next(fifo[_tokenId], fifoKey);
            i++;
        }
        return (addrs, shares);
    }

    function chairmanOf(uint256 _tokenId)
        public
        view
        returns (address chairman)
    {
        chairman = companyIndexToChairman[_tokenId];
        require(chairman != address(0));
    }

    function sharesOwned(address _owner, uint256 _tokenId) public view returns (uint256 shares) {
        return companyIndexToOwners[_tokenId][_owner];
    }

    function payout(address _to) public onlyCLevel {
        _payout(_to);
    }

    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return companyIndexToPrice[_tokenId];
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    function totalCompanies() public view returns (uint256 total) {
        return companies.length;
    }


    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

    /// For creating Company
    function _createCompany(string _name, address _owner, uint256 _price) private {
        require(_price % 100 == 0);

        Company memory _company = Company({
            name: _name
        });
        uint256 newCompanyId = companies.push(_company) - 1;

        // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
        // let&#39;s just be 100% sure we never let this happen.
        require(newCompanyId == uint256(uint32(newCompanyId)));

        Founded(newCompanyId, _name, _owner, _price);

        companyIndexToPrice[newCompanyId] = _price;

        _transfer(address(0), _owner, newCompanyId, TOTAL_SHARES);
    }

    /// Check for token ownership
    function _owns(address claimant, uint256 _tokenId, uint256 _shares) private view returns (bool) {
        return companyIndexToOwners[_tokenId][claimant] >= _shares;
    }

    /// For paying out balance on contract
    function _payout(address _to) private {
        if (_to == address(0)) {
            ceoAddress.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

    function _purchaseProcessFifoItem(uint256 _tokenId, Holding storage _holding, uint256 _sharesToFulfill)
        private
        returns (uint256 sharesFulfilled, uint256 payment) {

        sharesFulfilled = Math.min(_holding.shares, _sharesToFulfill);

        // underflow is not possible because decution is the minimun of the two
        _holding.shares -= sharesFulfilled;

        companyIndexToOwners[_tokenId][_holding.owner] = SafeMath.sub(companyIndexToOwners[_tokenId][_holding.owner], sharesFulfilled);

        uint256 currentTierLeft = SafeMath.sub(TOTAL_SHARES, circulationCounters[_tokenId] % TOTAL_SHARES);
        uint256 currentPriceShares = Math.min(currentTierLeft, sharesFulfilled);
        payment = SafeMath.div(SafeMath.mul(companyIndexToPrice[_tokenId], currentPriceShares), TOTAL_SHARES);

        SharesSold(_tokenId, currentPriceShares, companyIndexToPrice[_tokenId], _holding.owner, msg.sender, companies[_tokenId].name);

        if (sharesFulfilled >= currentTierLeft) {
            uint256 newPrice = nextPrice(_tokenId, companyIndexToPrice[_tokenId]);
            companyIndexToPrice[_tokenId] = newPrice;

            if (sharesFulfilled > currentTierLeft) {
                uint256 newPriceShares = sharesFulfilled - currentTierLeft;
                payment += SafeMath.div(SafeMath.mul(newPrice, newPriceShares), TOTAL_SHARES);
                SharesSold(_tokenId, newPriceShares, newPrice, _holding.owner, msg.sender, companies[_tokenId].name);
            }
        }

        circulationCounters[_tokenId] = SafeMath.add(circulationCounters[_tokenId], sharesFulfilled);

        // no need to transfer if seller is the contract
        if (_holding.owner != address(this)) {
            _holding.owner.transfer(SafeMath.div(SafeMath.mul(payment, 100 - commissionPoints), 100));
        }

        Transfer(_holding.owner, msg.sender, _tokenId, sharesFulfilled);
    }

    function _purchaseLoopFifo(uint256 _tokenId, uint256 _sharesToFulfill)
        private
        returns (uint256 sharesFulfilled, uint256 totalPayment) {
        uint256 prevFifoKey = HEAD;
        uint256 fifoKey = FifoLib.next(fifo[_tokenId], HEAD);
        while (fifoKey != HEAD) {
            Holding storage holding = fifoStorage[_tokenId][fifoKey];

            assert(holding.shares > 0);

            if (holding.owner != msg.sender) {
                uint256 itemSharesFulfilled;
                uint256 itemPayment;
                (itemSharesFulfilled, itemPayment) = _purchaseProcessFifoItem(_tokenId, holding, SafeMath.sub(_sharesToFulfill, sharesFulfilled));

                sharesFulfilled += itemSharesFulfilled;
                totalPayment += itemPayment;

                if (holding.shares == 0) {
                    // delete the record from fifo
                    FifoLib.remove(fifo[_tokenId], prevFifoKey, fifoKey);
                    fifoKey = prevFifoKey;
                }
            }

            if (sharesFulfilled == _sharesToFulfill) break;

            prevFifoKey = fifoKey;
            fifoKey = FifoLib.next(fifo[_tokenId], fifoKey);
        }  
    }

    function purchase(uint256 _tokenId, uint256 _shares) public payable {
        require(_sharesValid(_tokenId, _shares));
        require(companyIndexToOwners[_tokenId][msg.sender] + _shares <= TOTAL_SHARES);

        uint256 estimatedPayment = estimatePurchasePayment(_tokenId, _shares);

        require(msg.value >= estimatedPayment);

        uint256 sharesFulfilled;
        uint256 totalPayment;
        (sharesFulfilled, totalPayment) = _purchaseLoopFifo(_tokenId, _shares);

        assert(sharesFulfilled == _shares);
        assert(totalPayment == estimatedPayment);

        uint256 purchaseExess = SafeMath.sub(msg.value, totalPayment);
        assert(purchaseExess >= 0);

        if (purchaseExess > 0) {
            msg.sender.transfer(purchaseExess);
        }

        fifoStorage[_tokenId][FifoLib.pushTail(fifo[_tokenId], _nextFifoStorageKey(_tokenId))] = Holding({owner: msg.sender, shares: _shares});

        companyIndexToOwners[_tokenId][msg.sender] += _shares;

        if (companyIndexToOwners[_tokenId][msg.sender] > companyIndexToOwners[_tokenId][companyIndexToChairman[_tokenId]]) {
            companyIndexToChairman[_tokenId] = msg.sender;
        }
    }

    function estimatePurchasePayment(uint256 _tokenId, uint256 _shares) public view returns (uint256) {
        require(_shares <= TOTAL_SHARES);

        uint256 currentPrice = companyIndexToPrice[_tokenId];

        uint256 currentPriceShares = Math.min(_shares, TOTAL_SHARES - circulationCounters[_tokenId] % TOTAL_SHARES);
        return SafeMath.add(
            SafeMath.div(SafeMath.mul(currentPrice, currentPriceShares), TOTAL_SHARES),
            SafeMath.div(SafeMath.mul(nextPrice(_tokenId, currentPrice), _shares - currentPriceShares), TOTAL_SHARES)
        );
    }

    function nextPrice(uint256 _tokenId, uint256 _currentPrice) public view returns (uint256) {
        uint256 price;
        if (_currentPrice < firstStepLimit) {
          // first stage
          price = SafeMath.div(SafeMath.mul(_currentPrice, 200), 100);
        } else if (_currentPrice < secondStepLimit) {
          // second stage
          price = SafeMath.div(SafeMath.mul(_currentPrice, 120), 100);
        } else {
          // third stage
          price = SafeMath.div(SafeMath.mul(_currentPrice, 115), 100);
        }

        return price - price % 100;
    }

    function transfer(
        address _to,
        uint256 _tokenId,
        uint256 _shares
    ) public {
        require(_addressNotNull(_to));
        require(_sharesValid(_tokenId, _shares));
        require(_owns(msg.sender, _tokenId, _shares));

        _transfer(msg.sender, _to, _tokenId, _shares);
    }

    function transferFromContract(
        address _to,
        uint256 _tokenId,
        uint256 _shares
    ) public onlyCOO {
        address from = address(this);
        require(_addressNotNull(_to));
        require(_sharesValid(_tokenId, _shares));
        require(_owns(from, _tokenId, _shares));

        _transfer(from, _to, _tokenId, _shares);
    }

    function _transfer(address _from, address _to, uint256 _tokenId, uint256 _shares) private {
        if (_from != address(0)) {
            uint256 sharesToFulfill = _shares;

            uint256 fifoKey = FifoLib.next(fifo[_tokenId], HEAD);
            while (fifoKey != HEAD) {
                Holding storage holding = fifoStorage[_tokenId][fifoKey];

                assert(holding.shares > 0);

                if (holding.owner == _from) {
                    uint256 fulfilled = Math.min(holding.shares, sharesToFulfill);

                    if (holding.shares == fulfilled) {
                        // if all shares are taken, just modify the owner address in place
                        holding.owner = _to;
                    } else {
                        // underflow is not possible because deduction is the minimun of the two
                        holding.shares -= fulfilled;

                        // insert a new holding record
                        fifoStorage[_tokenId][FifoLib.insert(fifo[_tokenId], fifoKey, _nextFifoStorageKey(_tokenId))] = Holding({owner: _to, shares: fulfilled});

                        fifoKey = FifoLib.next(fifo[_tokenId], fifoKey);
                        // now fifoKey points to the newly inserted one 
                    }

                    // underflow is not possible because deduction is the minimun of the two
                    sharesToFulfill -= fulfilled;
                }

                if (sharesToFulfill == 0) break;

                fifoKey = FifoLib.next(fifo[_tokenId], fifoKey);
            }

            require(sharesToFulfill == 0);

            companyIndexToOwners[_tokenId][_from] -= _shares;
        } else {
            // genesis transfer
            fifoStorage[_tokenId][FifoLib.pushTail(fifo[_tokenId], _nextFifoStorageKey(_tokenId))] = Holding({owner: _to, shares: _shares});
        }

        companyIndexToOwners[_tokenId][_to] += _shares;

        if (companyIndexToOwners[_tokenId][_to] > companyIndexToOwners[_tokenId][companyIndexToChairman[_tokenId]]) {
            companyIndexToChairman[_tokenId] = _to;
        }

        // Emit the transfer event.
        Transfer(_from, _to, _tokenId, _shares);
    }

    function _sharesValid(uint256 _tokenId, uint256 _shares) private view returns (bool) {
        return (_shares > 0 && _shares <= TOTAL_SHARES) &&
            (shareTradingEnabled[_tokenId] || _shares == TOTAL_SHARES);
    }

    function _nextFifoStorageKey(uint256 _tokenId) private returns (uint256) {
        return ++fifoStorageKey[_tokenId];
    }
}


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return a;
        else return b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        else return b;
    }
}