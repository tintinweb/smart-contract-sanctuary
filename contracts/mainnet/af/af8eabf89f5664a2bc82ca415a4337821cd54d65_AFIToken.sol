pragma solidity ^0.4.23;

// File: contracts/Ownable.sol

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require((msg.sender == owner) || (tx.origin == owner));
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/Bonus.sol

contract Bonus is Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) public buyerBonus;
    mapping(address => bool) hasBought;
    address[] public buyerList;
    
    function _addBonus(address _beneficiary, uint256 _bonus) internal {
        if(hasBought[_beneficiary]){
            buyerBonus[_beneficiary] = buyerBonus[_beneficiary].add(_bonus);
        } else {
            hasBought[_beneficiary] = true;
            buyerList.push(_beneficiary);
            buyerBonus[_beneficiary] = _bonus;
        }
    }
}

// File: contracts/ERC20Basic.sol

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/ERC20.sol

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/CrowdSale.sol

contract Crowdsale is Bonus {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // ICO exchange rate
    uint256 public rate;

    // ICO Time
    uint256 public openingTimePeriodOne;
    uint256 public closingTimePeriodOne;
    uint256 public openingTimePeriodTwo;
    uint256 public closingTimePeriodTwo;
    uint256 public bonusDeliverTime;

    // Diff bonus rate decided by time
    uint256 public bonusRatePrivateSale;
    uint256 public bonusRatePeriodOne;
    uint256 public bonusRatePeriodTwo;

    // Token decimal
    uint256 decimals;
    uint256 public tokenUnsold;
    uint256 public bonusUnsold;
    uint256 public constant minPurchaseAmount = 0.1 ether;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenBonus(address indexed purchaser, address indexed beneficiary, uint256 bonus);

    modifier onlyWhileOpen {
        require(block.timestamp <= closingTimePeriodTwo);
        _;
    }

    constructor (uint256 _openingTimePeriodOne, uint256 _closingTimePeriodOne, uint256 _openingTimePeriodTwo, uint256 _closingTimePeriodTwo, uint256 _bonusDeliverTime,
        uint256 _rate, uint256 _bonusRatePrivateSale, uint256 _bonusRatePeriodOne, uint256 _bonusRatePeriodTwo, 
        address _wallet, ERC20 _token, uint256 _decimals, uint256 _tokenUnsold, uint256 _bonusUnsold) public {
        require(_wallet != address(0));
        require(_token != address(0));
        require(_openingTimePeriodOne >= block.timestamp);
        require(_closingTimePeriodOne >= _openingTimePeriodOne);
        require(_openingTimePeriodTwo >= _closingTimePeriodOne);
        require(_closingTimePeriodTwo >= _openingTimePeriodTwo);

        wallet = _wallet;
        token = _token;
        openingTimePeriodOne = _openingTimePeriodOne;
        closingTimePeriodOne = _closingTimePeriodOne;
        openingTimePeriodTwo = _openingTimePeriodTwo;
        closingTimePeriodTwo = _closingTimePeriodTwo;
        bonusDeliverTime = _bonusDeliverTime;
        rate = _rate;
        bonusRatePrivateSale = _bonusRatePrivateSale;
        bonusRatePeriodOne = _bonusRatePeriodOne;
        bonusRatePeriodTwo = _bonusRatePeriodTwo;
        tokenUnsold = _tokenUnsold;
        bonusUnsold = _bonusUnsold;
        decimals = _decimals;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be sent
        uint256 tokens = _getTokenAmount(weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        // calculate bonus amount to be sent
        uint256 bonus = _getTokenBonus(weiAmount);
        _addBonus(_beneficiary, bonus);
        bonusUnsold = bonusUnsold.sub(bonus);
        emit TokenBonus(
            msg.sender,
            _beneficiary,
            bonus
        );
        _forwardFunds();
    }
	
    function isClosed() public view returns (bool) {
        return block.timestamp > closingTimePeriodTwo;
    }

    function isOpened() public view returns (bool) {
        return (block.timestamp < closingTimePeriodOne && block.timestamp > openingTimePeriodOne) || (block.timestamp < closingTimePeriodTwo && block.timestamp > openingTimePeriodTwo);
    }

    function privateCrowdsale(address _beneficiary, uint256 _ethAmount) external onlyOwner{
        _preValidatePurchase(_beneficiary, _ethAmount);

        // calculate token amount to be sent
        uint256 tokens = _getTokenAmount(_ethAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            _ethAmount,
            tokens
        );

        // calculate bonus amount to be sent
        uint256 bonus = _ethAmount.mul(10 ** uint256(decimals)).div(1 ether).mul(bonusRatePrivateSale);
        _addBonus(_beneficiary, bonus);
        bonusUnsold = bonusUnsold.sub(bonus);
        emit TokenBonus(
            msg.sender,
            _beneficiary,
            bonus
        );
    }
    
    function returnToken() external onlyOwner{
        require(block.timestamp > closingTimePeriodTwo);
        require(tokenUnsold > 0);
        token.transfer(wallet,tokenUnsold);
        tokenUnsold = tokenUnsold.sub(tokenUnsold);
    }

    /**
     * WARNING: Make sure that user who owns bonus is still in whitelist!!!
     */
    function deliverBonus() public onlyOwner {
        require(bonusDeliverTime <= block.timestamp);
        for (uint i = 0; i<buyerList.length; i++){
            uint256 amount = buyerBonus[buyerList[i]];
            token.transfer(buyerList[i], amount);
            buyerBonus[buyerList[i]] = 0;
        }
    }

    function returnBonus() external onlyOwner{
        require(block.timestamp > bonusDeliverTime);
        require(bonusUnsold > 0);
        token.transfer(wallet, bonusUnsold);
        bonusUnsold = bonusUnsold.sub(bonusUnsold);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen
    {
        require(_beneficiary != address(0));
        require(_weiAmount >= minPurchaseAmount);
    }

    function _validateMaxSellAmount(uint256 _tokenAmount) internal view onlyWhileOpen {
        require(tokenUnsold >= _tokenAmount);
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
        tokenUnsold = tokenUnsold.sub(_tokenAmount);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _validateMaxSellAmount(_tokenAmount);
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _getTokenAmount( uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(10 ** uint256(decimals)).div(1 ether).mul(rate);
    }

    function _getTokenBonus(uint256 _weiAmount) internal view returns (uint256) {
        uint256 bonusRate = 0;
        if(block.timestamp > openingTimePeriodOne && block.timestamp < closingTimePeriodOne){
            bonusRate = bonusRatePeriodOne;
        } else if(block.timestamp > openingTimePeriodTwo && block.timestamp < closingTimePeriodTwo){
            bonusRate = bonusRatePeriodTwo;
        }
        return _weiAmount.mul(10 ** uint256(decimals)).div(1 ether).mul(bonusRate);
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

// File: contracts/StandardToken.sol

contract StandardToken is ERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 totalSupply_;
    bool public transferOpen = true;

    modifier onlyWhileTransferOpen {
        require(transferOpen);
        _;
    }

    function setTransfer(bool _open) external onlyOwner{
        transferOpen = _open;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public onlyWhileTransferOpen returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyWhileTransferOpen returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

// File: contracts/Whitelist.sol

contract Whitelist is Ownable {

    using SafeMath for uint256;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) whitelistIndexMap;
    address[] public whitelistArray;
    uint256 public whitelistLength = 0;

    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
        if (whitelistIndexMap[_beneficiary] == 0){
            if (whitelistArray.length <= whitelistLength){
                whitelistArray.push(_beneficiary);
            } else {
                whitelistArray[whitelistLength] = _beneficiary;
            }
            whitelistLength = whitelistLength.add(1);
            whitelistIndexMap[_beneficiary] = whitelistLength;
        }
    }

    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
        if (whitelistIndexMap[_beneficiary] > 0){
            uint index = whitelistIndexMap[_beneficiary]-1;
            whitelistArray[index] = whitelistArray[whitelistLength-1];
            whitelistArray[whitelistLength-1] = 0;
            whitelistIndexMap[_beneficiary] = 0;
            whitelistLength = whitelistLength.sub(1);
        }
    }
}

// File: contracts/AFIToken.sol

contract AFIToken is StandardToken, Crowdsale, Whitelist {
    using SafeMath for uint256;
    string public constant name = "AlchemyCoin";
    string public constant symbol = "AFI";
    uint8 public constant decimals = 8;
    uint256 constant INITIAL_SUPPLY = 125000000 * (10 ** uint256(decimals));
    uint256 constant ICO_SUPPLY = 50000000 * (10 ** uint256(decimals));
    uint256 constant ICO_BONUS = 12500000 * (10 ** uint256(decimals));
    uint256 public minRevenueToDeliver = 0;
    address public assignRevenueContract;
    uint256 public snapshotBlockHeight;
    mapping(address => uint256) public snapshotBalance;
    // Custom Setting values ---------------------------------
    uint256 constant _openingTimePeriodOne = 1531713600;
    uint256 constant _closingTimePeriodOne = 1534132800;
    uint256 constant _openingTimePeriodTwo = 1535342400;
    uint256 constant _closingTimePeriodTwo = 1536552000;
    uint256 constant _bonusDeliverTime = 1552276800;
    address _wallet = 0x2Dc02F830072eB33A12Da0852053eAF896185910;
    address _afiWallet = 0x991E2130f5bF113E2282A5F58E626467D2221599;
    // -------------------------------------------------------
    uint256 constant _rate = 1000;
    uint256 constant _bonusRatePrivateSale = 250;
    uint256 constant _bonusRatePeriodOne = 150;
    uint256 constant _bonusRatePeriodTwo = 50;
    

    constructor() public 
    Crowdsale(_openingTimePeriodOne, _closingTimePeriodOne, _openingTimePeriodTwo, _closingTimePeriodTwo, _bonusDeliverTime,
        _rate, _bonusRatePrivateSale, _bonusRatePeriodOne, _bonusRatePeriodTwo, 
        _wallet, this, decimals, ICO_SUPPLY, ICO_BONUS)
    {
        totalSupply_ = INITIAL_SUPPLY;
        emit Transfer(0x0, _afiWallet, INITIAL_SUPPLY - ICO_SUPPLY - ICO_BONUS);
        emit Transfer(0x0, this, ICO_SUPPLY);
        balances[_afiWallet] = INITIAL_SUPPLY - ICO_SUPPLY - ICO_BONUS;
        
        // add admin
        whitelist[_afiWallet] = true;
        whitelistArray.push(_afiWallet);
        whitelistLength = whitelistLength.add(1);
        whitelistIndexMap[_afiWallet] = whitelistLength;
        
        // add contract
        whitelist[this] = true;
        whitelistArray.push(this);
        whitelistLength = whitelistLength.add(1);
        whitelistIndexMap[this] = whitelistLength;
        balances[this] = ICO_SUPPLY + ICO_BONUS;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view isWhitelisted(_beneficiary){
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function transfer(address _to, uint256 _value) public isWhitelisted(_to) isWhitelisted(msg.sender) returns (bool) {
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isWhitelisted(_to) isWhitelisted(_from)  returns (bool){
        super.transferFrom(_from, _to, _value);
    }

    function setRevenueContract(address _contract) external onlyOwner{
        assignRevenueContract = _contract;
    }

    function createBalanceSnapshot() external onlyOwner {
        snapshotBlockHeight = block.number;
        for(uint256 i = 0; i < whitelistLength; i++) {
            snapshotBalance[whitelistArray[i]] = balances[whitelistArray[i]];
        }
    }

    function setMinRevenue(uint256 _minRevenue) external onlyOwner {
        minRevenueToDeliver = _minRevenue;
    }

    function assignRevenue(uint256 _totalRevenue) external onlyOwner{
        address contractAddress = assignRevenueContract;

        for (uint256 i = 0; i<whitelistLength; i++){
            if(whitelistArray[i] == address(this)){
                continue;
            }
            uint256 amount = _totalRevenue.mul(snapshotBalance[whitelistArray[i]]).div(INITIAL_SUPPLY);
            if(amount > minRevenueToDeliver){
                bool done = contractAddress.call(bytes4(keccak256("transferRevenue(address,uint256)")),whitelistArray[i],amount);
                require(done == true);
            }
        }
    }
}