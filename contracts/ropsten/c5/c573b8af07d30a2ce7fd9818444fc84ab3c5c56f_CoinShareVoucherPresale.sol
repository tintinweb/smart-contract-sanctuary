pragma solidity ^0.4.24;

// File: contracts/Authorizable.sol

contract Authorizable {
    
    constructor() internal {}

    event AuthorizationSet(address indexed addressAuthorized,bool indexed authorization);

    function isAuthorized(address addr) public view returns (bool);

    function setAuthorized(address addressAuthorized, bool authorization) public;
}

// File: contracts/ERC223.sol

contract ERC223 {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    constructor() internal {}

    // Checks if the address refers to a contract
    // returns true if to is a contract false otherwise
    function _isContract(address to) internal view returns (bool) {
        uint codeLength;
        assembly {
            codeLength := extcodesize(to)
        }
        return codeLength > 0;
    }

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool ok);
    function transfer(address to, uint256 value, bytes data) public returns (bool ok);
    function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool ok);
}

// File: contracts/ERC223TokenReceiver.sol

contract ERC223TokenReceiver {

    constructor () internal {}

    function tokenFallback(address from, uint256 value, bytes data) public;
}

// File: contracts/SafeMath.sol

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a  == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256 c) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256 c) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

}

// File: contracts/BaseERC223Token.sol

contract BaseERC223Token is ERC223 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    constructor (uint256 _totalSupply, string _name, string _symbol, uint8 _decimals) internal {
        decimals = _decimals;
        totalSupply = _totalSupply;
        name = _name;
        symbol = _symbol;
        _balances[msg.sender] = totalSupply;
    }

    function balanceOf(address who) public view returns (uint256){
        return _balances[who];
    }


    function transfer(address to, uint256 value) public returns(bool) {
        require(to != address(0));
        require(to != address(this));
        require(_balances[msg.sender] >= value);
        bytes memory empty;
        return transfer(to, value, empty);
    }

    function transfer(address to, uint256 value, bytes data) public returns(bool) {
        return _transferInternal(msg.sender,to, value, data);
    }


    function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns(bool) {
        return _transferInternal(msg.sender, to, value, data, custom_fallback);
    }

    function _transferInternal(address from, address to, uint256 value, bytes data) internal returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(to != address(this));
        require(_balances[from] >= value);
        if (_isContract(to)) {
            return _transferToContract(from, to, value, data);
        } else {
            return _transferToAddress(from, to, value, data);
        }
    }

    function _transferInternal(address from, address to, uint256 value, bytes data, string custom_fallback) internal returns(bool) {
        require(from != address(0));
        require(to != address(0));
        require(to != address(this));
        require(_balances[from] >= value);
        if (_isContract(to)) {
            _balances[from] = _balances[from].sub(value);
            _balances[to] = _balances[to].add(value);

            assert(to.call.value(0)(bytes4(keccak256(custom_fallback)), from, value, data));
            emit Transfer(from, to, value, data);
            return true;
        } else {
            return _transferToAddress(from, to, value, data);
        }
    }

    function _transferToContract(address from,address to, uint256 value, bytes data) private returns(bool) {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        ERC223TokenReceiver receiver = ERC223TokenReceiver(to);
        receiver.tokenFallback(from, value, data);
        emit Transfer(from, to, value, data);
        return true;
    }

    function _transferToAddress(address from, address to, uint256 value, bytes data) private returns(bool) {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value, data);
        return true;
    }

}

// File: contracts/CoinShareVoucherInterface.sol

contract CoinShareVoucherInterface is ERC223, Authorizable {

    // function transferFrom(address from, address to, uint256 value) public returns(bool);
}

// File: contracts/IterableAddressMap.sol

library IterableAddressMap {
    struct _entry {
        // this is the index in the lookup table + 1
        // so we can use 0 (the default) as a guard
        uint256 keyIndex;
        // the actual value
        uint256 value;
    }
    
    struct Data {
        mapping(address => _entry) data;
        address[] lookup;
    }

    function put(Data storage self, address key, uint256 value) internal returns(bool replaced) {
        // get the entry keeping it as a storage so when we update it
        // the behavior is similar to using a by mutable reference
        _entry storage e = self.data[key];
        e.value = value;
        if (e.keyIndex > 0) {
            // if the entry already has a key > 0 then we are
            // accessing an existing entry
            return true;
        } else {
            // otherwise we need to push the address in the lookup structure
            e.keyIndex = ++self.lookup.length;
            self.lookup[e.keyIndex-1] = key;
            return false;
        }
    }

    function remove(Data storage self, address key) internal returns(bool success) {
        _entry storage e = self.data[key];
        if (e.keyIndex == 0) {
            // not present
            return false;
        } else if(self.lookup.length == 1){
            // cleanup the table
            delete self.data[key];
            self.lookup.length = 0;
            return true;
        } else {
            // swaps element to be removed for last element in the lookup table
            // set the index of last stored address
            address lastAddress= self.lookup[self.lookup.length - 1];
            self.data[lastAddress].keyIndex = e.keyIndex;
            // swaps the entry in the lookup table
            self.lookup[e.keyIndex - 1] = lastAddress;
            // decrease the length of the array
            self.lookup.length -= 1;
            // remove the entry
            delete self.data[key];
            return true;
        }
    }

    function clear(Data storage self) internal {
        if (self.lookup.length == 0) return;
        for(uint i = 0; i< self.lookup.length; i++) {
            delete self.data[self.lookup[i]];
        }
        delete self.lookup;
    }

    function contains(Data storage self, address key) internal view returns (bool exists) {
        return self.data[key].keyIndex > 0;
    }

    function get(Data storage self, address key) internal view returns (uint256) {
        return self.data[key].value;
    }

    function size(Data storage self) internal view returns(uint256) {
        return self.lookup.length;
    }

    function entryAt(Data storage self, uint256 index) internal view returns(address,uint256) {
        address key = keyAt(self, index);
        return (key, self.data[key].value);
    }

    function keyAt(Data storage self, uint256 index) internal view returns(address) {
        //require(index < self.lookup.length);
        return self.lookup[index];
    }

}

// File: contracts/Ownable.sol

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function isOwner(address who) internal view returns(bool) {
        return who == owner;
    }

   /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: contracts/Startable.sol

contract Startable {
    
    event Start();
    
    bool internal _started = false;

    constructor (bool initiallyStarted) internal {
        _started = initiallyStarted;
    }

    modifier whenStarted() {
        require(_started, "This function can only be called when the contract is started.");
        _;
    }

    function started() public view returns (bool) {
        return _started;
    }

    function start() public {
        _started = true;
        emit Start();
    }

}

// File: contracts/Stoppable.sol

contract Stoppable is Startable {
    
    event Stop();

    constructor(bool initiallyStarted) Startable(initiallyStarted) internal {

    }

    modifier whenStopped() {
        require(!_started,"This function can be called only when contract is stopped.");
        _;
    }

    function stop() public {
        _started = false;
        emit Stop();
    }

}

// File: contracts/CoinShareBasePresale.sol

/**
 * This contract implement the voucher presale for Coinshare.
 * Voucher can be bought by only whitelisted adresses at a specified price per token.
 * Buyers are allowed to buy tokens only above a certain threshold of purchase.
 */
contract CoinShareBasePresale is Ownable, Stoppable, ERC223TokenReceiver{
    using SafeMath for uint256;
    using IterableAddressMap for IterableAddressMap.Data;

    /** Event emitted when a given quantity of tokens is purchased */
    event TokensPurchased(address indexed buyer, uint256 indexed tokens, uint256 indexed price,uint256 weiSpent);
    event WhiteListUpdated(address indexed buyer, bool indexed enabled, uint256 indexed priceOverride);
    event IntermediariesListUpdated(address indexed intermediary, bool indexed enabled);
    enum RateType {Conversion,Price,Quota,Parcel}
    event RateChanged(RateType indexed rateType,uint256 value);
    event RateUpdaterChanged(address indexed previous, address indexed current);

    CoinShareVoucherInterface public token;

    // stores the whitelist with local price overrides
    // if the whitelisted has a 0 price override the default is used
    IterableAddressMap.Data private _whiteList;

    IterableAddressMap.Data private _intermediaries;

    address public beneficiary;
    address public notary;
    uint256 public notaryParcel;

    bool public canChangeBeneficiary;

    address public rateUpdater;

    uint256 public etherPriceInUSD;
    uint256 public lastEtherPriceInUSDUpdateTimestamp;
    uint256 public tokenPriceInUSD;
    uint256 public minimumUSDPerTransaction;

    uint256 public weiCollected;
    uint256 public soldTokens;

    uint256 private decimals;
    uint256 private totalSupply;

    modifier onlyOwnerOrRateUpdater() {
        require(msg.sender == owner || (rateUpdater != address(0) && msg.sender == rateUpdater),
            "Only owner or designated rate updater can call this function.");
        _;
    }

    modifier onlyIntermediary() {
        require(isIntermediary(msg.sender)||msg.sender == owner || msg.sender == beneficiary,
            "Only authorized intermediaries can call this function.");
        _;
    }

    constructor (address _beneficiary,
        CoinShareVoucherInterface _soldToken,
        uint256 initialTokenPriceInUSD,
        uint256 initialEtherPriceInUSD,
        uint256 _minimumUSDPerTransaction,
        uint256 _parcelPercentage,
        bool _canChangeBeneficiary)
    Stoppable(false)
    internal {
        require(_beneficiary != address(0));
        require(_soldToken != address(0));
        require(initialTokenPriceInUSD > 0);
        require(initialEtherPriceInUSD > 0);
        require(_minimumUSDPerTransaction > 0);
        canChangeBeneficiary = _canChangeBeneficiary;
        beneficiary = _beneficiary;
        notary = owner;
        token = _soldToken;
        decimals = token.decimals();
        totalSupply = token.totalSupply();
        etherPriceInUSD = initialEtherPriceInUSD;
        lastEtherPriceInUSDUpdateTimestamp = etherPriceInUSD;
        tokenPriceInUSD = initialTokenPriceInUSD;
        notaryParcel = _parcelPercentage;
        minimumUSDPerTransaction = _minimumUSDPerTransaction;
        rateUpdater = address(0);
        // transfer all remaining tokens to the crowdsale???
        // this is not doable here since the tokens allows only owner
        // to use this methods, thus the presale cannot automatically
        // acquire all tokens.
        // we can:
        // * handle those steps through an external transaction. (the current choice)
        // * deploy the contract from here and give back ownership to msg.sender
        // * check in ownership through transaction.origin instead of msg.sender (bad practice)
        //
        //  _soldToken.transfer(address(this),token.balanceOf(msg.sender));
        //  _soldToken.setAuthorized(address(this), true);
    }


    function _buyTokens(address buyer, address refundTo) internal whenStarted{
        require(buyer != address(0));
        require(refundTo != address(0));
        require(isWhitelisted(buyer));
        uint256 weiAmount = msg.value;
        require(weiAmount != 0);

        uint256 refunds;
        uint256 tokensPurchased;
        uint256 totalValue;
        uint256 notaryValue;
        (refunds,tokensPurchased) = _processPurchase(buyer, weiAmount);
        (totalValue,notaryValue) = _processFunds(weiAmount,refunds);

        _updateStats(totalValue, tokensPurchased);
        _forwardFunds(refundTo,refunds,totalValue,notaryValue);
    }

    function checkMinimumQuota(address buyer,uint256 usdAmount) internal returns (bool);


    function _processPurchase(address _buyer,uint256 weiAmount) private returns (uint256,uint256){
        uint256 priceOverride = _whiteList.get(_buyer);
        uint256 usdAmount = weiAmount.mul(etherPriceInUSD).div(10 ** uint256(decimals));
        checkMinimumQuota(_buyer, usdAmount);

        uint256 _tokenPriceInUSD = priceOverride == 0 ? tokenPriceInUSD : priceOverride;
        uint256 oneToken = 10 ** uint256(decimals);

        uint256 tokensToBuy = usdAmount.mul(oneToken).div(_tokenPriceInUSD);
        // what if there are not enough tokens to be sold
        uint256 availableTokens = token.balanceOf(this);
        // hard check
        // require(availableTokens>= tokensToBuy,"Not enough tokens remaining");
        // soft check with refund
        require(availableTokens > 0);
        uint256 refund;
        if (availableTokens < tokensToBuy) {
            // calculate the refund !!!CHECK!!!
            refund = (tokensToBuy - availableTokens).mul(_tokenPriceInUSD).div(etherPriceInUSD);
            weiAmount = weiAmount.sub(refund);
            tokensToBuy = availableTokens;
        }

        token.transfer(_buyer, tokensToBuy);
        //sold tokens event
        emit TokensPurchased(_buyer,tokensToBuy,_tokenPriceInUSD,weiAmount);
        return (refund, tokensToBuy);

    }

    function _processFunds(uint256 weiAmount,uint256 refunds) private view returns(uint256, uint256){
        uint256 totalValue;
        uint256 notaryValue;
        if (refunds>0){
            totalValue = weiAmount.sub(refunds);
        } else {
            totalValue = weiAmount;
        }
        notaryValue = totalValue.mul(notaryParcel).div(100 * (10 ** uint256(decimals)));
        totalValue = totalValue.sub(notaryValue);
        return (totalValue,notaryValue);
    }

    function _forwardFunds(address refundTo, uint256 refunds, uint256 totalValue, uint256 notaryValue) private {
        beneficiary.transfer(totalValue);
        notary.transfer(notaryValue);
        if(refunds>0) {
            refundTo.transfer(refunds);
        }
        // !!!CHECK!!! it may be better to have a refund through a claim
        // strategy
    }

    function _updateStats(uint256 weiAmount, uint256 tokensAmount) private {
        weiCollected = weiCollected.add(weiAmount);
        soldTokens = soldTokens.add(tokensAmount);
    }

    function isIntermediary(address _addr) public view returns(bool) {
        return _intermediaries.contains(_addr);
    }

    function intermediariesCount() public view returns (uint256) {
        return _intermediaries.size();
    }

    function getIntermediary(uint256 index) public view returns (address) {
        return _intermediaries.keyAt(index);
    }

    function addIntermediary(address _addr) public onlyOwner returns(bool){
        require(_addr != address(0));
        if(!_intermediaries.put(_addr, 1)){
            emit IntermediariesListUpdated(_addr, true);
            return true;
        }
        return false;
    }

    function removeIntermediary(address _addr) public onlyOwner returns(bool) {
        require(_addr != address(0));
        if(_intermediaries.remove(_addr)) {
            emit IntermediariesListUpdated(_addr, false);
            return true;
        }
        return false;
    }

    function isWhitelisted(address key) public view returns(bool){
        return _whiteList.contains(key);
    }

    function whitelistSize() public view returns(uint256) {
        return _whiteList.size();
    }

    function getWhitelistEntry(uint256 index) public view returns(address,uint256) {
        require(index < _whiteList.size());
        return _whiteList.entryAt(index);
    }


    function whitelistAddress(address _buyer,uint256 priceOverride) public onlyOwner returns(bool){
        require(_buyer != address(0));
        _whiteList.put(_buyer,priceOverride);
        emit WhiteListUpdated(_buyer,true,priceOverride);
        return true;
    }

    function removeFromWhitelist(address _buyer) public onlyOwner returns(bool) {
        require(_buyer != address(0));
        _whiteList.remove(_buyer);
        emit WhiteListUpdated(_buyer, false, 0);
        return true;
    }

    function updateMinimumQuota(uint256 _minimumUSDPerTransaction) public onlyOwner {
        require(_minimumUSDPerTransaction>0);
        minimumUSDPerTransaction = _minimumUSDPerTransaction;
        emit RateChanged(RateType.Quota, _minimumUSDPerTransaction);
    }

    function updateConversionRate(uint256 etherPrice) public onlyOwnerOrRateUpdater {
        require(etherPrice > 0);
        etherPriceInUSD = etherPrice;
        lastEtherPriceInUSDUpdateTimestamp = block.timestamp;
        emit RateChanged(RateType.Conversion, etherPrice);
    }

    function setNotaryParcel(uint256 _parcel) public onlyOwner {
        require(_parcel>0);
        notaryParcel = _parcel;
        emit RateChanged(RateType.Parcel, _parcel);
    }

    function updateTokenPrice(uint256 _tokenPriceUSD) public onlyOwner {
        require(_tokenPriceUSD > 0);
        tokenPriceInUSD = _tokenPriceUSD;
        emit RateChanged(RateType.Price, _tokenPriceUSD);
    }

    function setNotaryAddress(address _notary) public onlyOwner {
        require(_notary != address(0));
        notary = _notary;
    }

    function setUpdater(address _rateUpdater) public onlyOwner {
        require(_rateUpdater != address(this));
        require(_rateUpdater != address(owner));

        emit RateUpdaterChanged(rateUpdater,_rateUpdater);
        rateUpdater = _rateUpdater;

    }

    function start() public onlyOwner {
        super.start();
    }

    function stop() public onlyOwner {
        super.stop();
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(canChangeBeneficiary);
        require(_beneficiary != address(0));
        beneficiary = _beneficiary;
    }


    function withdrawTokens(address _beneficiary, uint256 value) public onlyOwner {
        require(_beneficiary != address(0));
        require(_beneficiary != address(this));
        require(token.balanceOf(this) >= value);
        token.transfer(_beneficiary,value);
        emit TokensPurchased(_beneficiary,value,0,0);
    }

    function withdrawTokens(address _beneficiary) public onlyOwner {
        withdrawTokens(_beneficiary, token.balanceOf(this));
    }

    function withdraw(address _beneficiary, uint256 value) public onlyOwner {
        require(address(this).balance >= value);
        require(_beneficiary != address(0));
        require(_beneficiary != address(this));
        _beneficiary.transfer(value);
    }

    function withdraw(address _beneficiary) public onlyOwner {
        withdraw(_beneficiary, address(this).balance);
    }
}

// File: contracts/CoinShareVoucherPresale.sol

/**
 * This contract implement the voucher presale for Coinshare.
 * Voucher can be bought by only whitelisted adresses at a specified price per token.
 * Buyers are allowed to buy tokens only above a certain threshold of purchase.
 */
contract CoinShareVoucherPresale is CoinShareBasePresale {

    constructor(address _beneficiary,
                CoinShareVoucherInterface _soldToken,
                uint256 initialTokenPriceInUSD,
                uint256 initialEtherPriceInUSD,
                uint256 _minimumUSDPerTransaction,
                uint256 _parcelPercentage,
                bool _canChangeBeneficiary
                )
    CoinShareBasePresale(_beneficiary,
                             _soldToken,
                             initialTokenPriceInUSD,
                             initialEtherPriceInUSD,
                             _minimumUSDPerTransaction,
                             _parcelPercentage,
                             _canChangeBeneficiary)
        public {
    }

    function () external payable {
        _buyTokens(msg.sender, msg.sender);
    }

    function buyTokens() external payable {
        _buyTokens(msg.sender, msg.sender);
    }

    function buyTokensForAddress(address buyFor) external onlyIntermediary payable {
        _buyTokens(buyFor,msg.sender);
    }

    function tokenFallback(address from, uint256 value, bytes data) public {

    }


    function checkMinimumQuota(address _buyer, uint256 usdAmount) internal returns (bool) {
        require(usdAmount >= minimumUSDPerTransaction);
        return true;
    }

}