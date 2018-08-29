pragma solidity ^0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    // address where funds are collected
    address public wallet;

    // amount of raised money in wei
    uint256 public weiRaised;

    uint256 public tokenAllocated;

    uint256 public hardCap = 60000 ether;

    constructor (address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}

interface IContractErc20Token {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function balanceOf(address _owner) external constant returns (uint256 balance);
    function mint(address _to, uint256 _amount, address _owner) external returns (bool);
}


contract CryptoCasherCrowdsale is Ownable, Crowdsale {
    using SafeMath for uint256;

    IContractErc20Token public tokenContract;

    mapping (address => uint256) public deposited;
    mapping(address => bool) public whitelist;
    // List of admins
    mapping (address => bool) public contractAdmins;
    mapping (address => uint256) public paidTokens;
    uint8 constant decimals = 18;

    uint256 fundForSale = 525 * 10**5 * (10 ** uint256(decimals));

    address addressFundNonKYCReserv = 0x7AEcFB881B6Ff010E4b7fb582C562aa3FCCb2170;
    address addressFundBlchainReferal = 0x2F9092Fe1dACafF1165b080BfF3afFa6165e339a;

    uint256[] discount  = [200, 150, 75, 50, 25, 10];

    uint256 weiMinSale = 0.1 ether;

    uint256 priceToken = 714;

    uint256 public countInvestor;
    uint256 percentReferal = 5;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(uint256 tokenRaised, uint256 purchasedToken);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event NonWhitelistPurchase(address indexed _buyer, uint256 _tokens);
    event HardCapReached();

    constructor (address _owner, address _wallet) public
    Crowdsale(_wallet)
    {
        uint256 fundAdvisors = 6 * 10**6 * (10 ** uint256(decimals));
        uint256 fundBountyRefferal = 525 * 10**4 * (10 ** uint256(decimals));
        uint256 fundTeam = 1125 * 10**4 * (10 ** 18);

        require(_owner != address(0));
        require(_wallet != address(0));
        owner = _owner;
        //owner = msg.sender; //for test&#39;s

        tokenAllocated = tokenAllocated.add(fundAdvisors).add(fundBountyRefferal).add(fundTeam);
    }

    function setContractErc20Token(address _addressContract) public {
        require(_addressContract != address(0));
        tokenContract = IContractErc20Token(_addressContract);
    }

    // fallback function can be used to buy tokens
    function() payable public {
        buyTokens(msg.sender);
    }

    function setPriceToken(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0);
        priceToken = _newPrice;
    }

    // low level token purchase function
    function buyTokens(address _investor) public payable returns (uint256){
        require(_investor != address(0));
        uint256 weiAmount = msg.value;
        uint256 tokens = validPurchaseTokens(weiAmount);
        if (tokens == 0) {revert();}
        weiRaised = weiRaised.add(weiAmount);
        tokenAllocated = tokenAllocated.add(tokens);
        if(whitelist[_investor]) {
            tokenContract.mint(_investor, tokens, owner);
        } else {
            tokenContract.mint(addressFundNonKYCReserv, tokens, owner);
            paidTokens[_investor] = paidTokens[_investor].add(tokens);
            emit NonWhitelistPurchase(_investor, tokens);
        }
        emit TokenPurchase(_investor, weiAmount, tokens);
        if (deposited[_investor] == 0) {
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        checkReferalLink(tokens);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function getTotalAmountOfTokens(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentDate = now;
        uint256 currentPeriod = getPeriod(currentDate);
        uint256 amountOfTokens = 0;
        if(0 <= currentPeriod && currentPeriod < 7 && _weiAmount >= weiMinSale){
            amountOfTokens = _weiAmount.mul(priceToken).mul(discount[currentPeriod] + 1000).div(1000);
        }
        return amountOfTokens;
    }

    function getPeriod(uint256 _currentDate) public pure returns (uint) {
        //1538488800 - Tuesday, 2. October 2018 14:00:00 GMT && 1538499600 - Tuesday, 2. October 2018 17:00:00 GMT
        if( 1538488800 <= _currentDate && _currentDate <= 1538499600){
            return 0;
        }
        //1538499601  - Tuesday, 2. October 2018 17:00:01 GMT GMT && 1541167200 - Friday, 2. November 2018 14:00:00 GMT
        if( 1538499601  <= _currentDate && _currentDate <= 1541167200){
            return 1;
        }

        //1541167201 - Friday, 2. November 2018 14:00:01 GMT && 1543759200 - Sunday, 2. December 2018 14:00:00 GMT
        if( 1541167201 <= _currentDate && _currentDate <= 1543759200){
            return 2;
        }
        //1543759201 - Sunday, 2. December 2018 14:00:01 GMT && 1546437600 - Wednesday, 2. January 2019 14:00:00 GMT
        if( 1543759201 <= _currentDate && _currentDate <= 1546437600){
            return 3;
        }
        //1546437601 - Wednesday, 2. January 2019 14:00:01 GMT && 1549116000 - Saturday, 2. February 2019 14:00:00 GMT
        if( 1546437601 <= _currentDate && _currentDate <= 1549116000){
            return 4;
        }
        //1549116001 - Saturday, 2. February 2019 14:00:01 GMT && 1551535200 - Saturday, 2. March 2019 14:00:00
        if( 1549116001 <= _currentDate && _currentDate <= 1551535200){
            return 5;
        }

        return 10;
    }

    function deposit(address investor) internal {
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function checkReferalLink(uint256 _amountToken) internal returns(uint256 _refererTokens) {
        _refererTokens = 0;
        if(msg.data.length == 20) {
            address referer = bytesToAddress(bytes(msg.data));
            require(referer != msg.sender);
            _refererTokens = _amountToken.mul(percentReferal).div(100);
            if(tokenContract.balanceOf(addressFundBlchainReferal) >= _refererTokens.mul(2)) {
                tokenContract.mint(referer, _refererTokens, addressFundBlchainReferal);
                tokenContract.mint(msg.sender, _refererTokens, addressFundBlchainReferal);
            }
        }
    }

    function bytesToAddress(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return address(result);
    }

    function validPurchaseTokens(uint256 _weiAmount) public returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (tokenAllocated.add(addTokens) > fundForSale) {
            emit TokenLimitReached(tokenAllocated, addTokens);
            return 0;
        }
        if (weiRaised.add(_weiAmount) > hardCap) {
            emit HardCapReached();
            return 0;
        }
        return addTokens;
    }

    /**
    * @dev Add an contract admin
    */
    function setContractAdmin(address _admin, bool _isAdmin) external onlyOwner {
        require(_admin != address(0));
        contractAdmins[_admin] = _isAdmin;
    }

    /**
    * @dev Adds single address to whitelist.
    * @param _beneficiary Address to be added to the whitelist
    */
    function addToWhitelist(address _beneficiary) external onlyOwnerOrAnyAdmin {
        whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwnerOrAnyAdmin {
        require(_beneficiaries.length < 101);
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelist(address _beneficiary) external onlyOwnerOrAnyAdmin {
        whitelist[_beneficiary] = false;
    }

    modifier onlyOwnerOrAnyAdmin() {
        require(msg.sender == owner || contractAdmins[msg.sender]);
        _;
    }

    /**
     * Peterson&#39;s Law Protection
     * Claim tokens
     */
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        uint256 balance = tokenContract.balanceOf(this);
        tokenContract.transfer(owner, balance);
        emit Transfer(_token, owner, balance);
    }

    modifier onlyFundNonKYCReserv() {
        require(msg.sender == addressFundNonKYCReserv);
        _;
    }

    function batchTransferPaidTokens(address[] _recipients, uint256[] _values) external onlyFundNonKYCReserv returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);
        uint256 total = 0;
        for(uint i = 0; i < _values.length; i++){
            total = total.add(_values[i]);
        }
        require(total <= tokenContract.balanceOf(msg.sender));
        for(uint j = 0; j < _recipients.length; j++){
            require(0 <= _values[j]);
            require(_values[j] <= paidTokens[_recipients[j]]);
            paidTokens[_recipients[j]].sub(_values[j]);
            tokenContract.transferFrom(addressFundNonKYCReserv, _recipients[j], _values[j]);
            emit Transfer(msg.sender, _recipients[j], _values[j]);
        }
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return tokenContract.balanceOf(_owner);
    }

    function balanceOfNonKYC(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return paidTokens[_owner];
    }
}