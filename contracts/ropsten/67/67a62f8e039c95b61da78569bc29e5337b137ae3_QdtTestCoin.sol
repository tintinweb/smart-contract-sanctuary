/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// ---------------------------------------------------- 
// QdtTestCoin Token By Qdt Limited.
// An ERC20 standard
// 
// author: Qdt. Team
// Contact： [email protected]

interface ERC20Interface {
    function totalSupply() external view returns (uint256 _totalSupply);
    function balanceOf(address _owner) external view returns(uint256 balance);
    function transfer(address _to, uint256 _value) external returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success);
    function approve(address _spender, uint256 _value) external returns(bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract QdtTestCoin is ERC20Interface {
    // origin attribute
    uint256 public constant decimals = 2;
    string public constant symbol = "QdtTC";
    string public constant name = "QdtTestCoin";
    
    // creator attribute
    string public _describe; // project background description
    bool public _selling = true; // initial _selling
    uint256 public _totalSupply = 10 ** 5; // total supply is 10^5 unit, equivalent to 10 ^ 3 QdtTC
    uint256 public _originalBuyPrice = 1 * 10**4; // original buy 1ETH = 100 QdtTC = 1 * 10 ** 4 unit
    address payable public owner;   // mint
    uint256 public _icoPercent = 10; // ico percent
    uint256 public _icoSupply = _totalSupply * _icoPercent / 100; // ico, initially, it is _totalSupply
    uint256 public _minimumBuy = 1 * 10 ** 16; // minimum buy 0.01 ETH, 1 ether = 10 ** 18 wei, transfer unit: Wei
    uint256 public _maximumBuy = 5 * 10 ** 17; // maximum buy 0.5 ETH, same as above
        
    // running attribute
    mapping(address => uint256) private balances; // amount of each account
    mapping(address => mapping(address => uint256)) private allowed; // approve the transfer of an amount to another account
    mapping(address => bool) private approvedInvestorList; // list of approved investors
    mapping(address => uint256) private deposit; // deposit
    uint256 public totalTokenSold = 0; // total token sold
    bool public tradable = false; // tradable
    
    
    /*
        Functions, Executed by the owner
    */
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }    
    
    /*
        Functions, Check on sale status,
        only allow sale if _selling is on
    */
    modifier onSale() {
        require(_selling);
        _;
    }
    
    /*
        Functions, Check the validity of address is investor
    */
    modifier vaildInvestor(){
        require(approvedInvestorList[msg.sender]);
        _;
    }
    
    /*
        Functions, Check the validity od msg value
        value must greater than equal minimumBuyPrice
        total deposit must less than equal maximumBuyPrice
    */
    modifier validValue(){
        require((msg.value >= _minimumBuy) &&
        ((deposit[msg.sender] + msg.value) <= _maximumBuy));
        _;
    }
    
    /*
        Status, is starting
    */
    modifier isTradable(){
        require(tradable == true || msg.sender == owner);
        _;
    }
    
    
    /// allows to buy ether.
    receive() external payable {
        buyQdtTC();
    }
    
    /// call buyQdtTC is OK or call default: receive
    function buyQdtTC() public payable onSale validValue vaildInvestor {
        uint256 requestedUnits = (msg.value * _originalBuyPrice) / 10 ** 18; // change to unit: ether.Wei * buyPrice / 1ether.Wei = request ethers same as QdtTC
        require(balances[owner] >= requestedUnits);
        // prepare transfer data
        balances[owner] -= requestedUnits;
        balances[msg.sender] += requestedUnits;
        
        // increase total deposit amount
        deposit[msg.sender] += msg.value;
        
        // check total and auto turnOffSale
        totalTokenSold += requestedUnits;
        if (totalTokenSold >= _icoSupply) {
            _selling = false;
        }
        
        // submit transfrt
        emit Transfer(owner, msg.sender, requestedUnits); // log: creator.token to investor
        owner.transfer(msg.value); // contract.ether.wei to creator.address
    }
    
    // Constructor
    constructor (string memory describe)  {
        owner = payable(msg.sender);
        setBuyPrice(_originalBuyPrice);
        balances[owner] = _totalSupply; // init creator.token
        _describe = describe;
        emit Transfer(payable(0x0), owner, _totalSupply); // log: same as
    }
    
    /// Gets totalSupply
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }
    
    /// Enables sale
    function turnOnSale() public onlyOwner {
        _selling = true;
    }
    
    /// Dieable sale
    function turnOffSale() public onlyOwner {
        _selling = false;
    }
    
    /// Enable tradable
    function turnOnTradable() public onlyOwner {
        tradable = true;
    }
    
    /// newIcoPercent new value of icoPercent
    function setIcoPercent(uint256 newIcoPercent) public onlyOwner {
        _icoPercent = newIcoPercent;
        _icoSupply = _totalSupply * _icoPercent / 100;
    }
    
    /// newMaximumBuy new values of _maximumBuy
    function setMaximumBuy(uint256 newMaximumBuy) public onlyOwner {
        _maximumBuy = newMaximumBuy;
    }
    
    /// Updating buy price, Pricing
    function setBuyPrice(uint256 newBuyPrice) onlyOwner public {
        require(newBuyPrice > 0);
        _originalBuyPrice = newBuyPrice; // 100 QdtTC = 100 00 unit, to 1ETH
        // control maximum buy USD = 10000 USD, QdtTC price is 20 USD
        // maximum_QdtTC = 500 QdtTC = 500,00 unit
        // 100 QdtTC = 1ETH => maximumETH = 100,00 / _originalBuyPrice
        // 500,00 / 100,00 ~ 5ETH => change to wei
        // The above explains the price relationship of QdtTC, ETH, and USD
        // The actual price is based on the exchange volume of ETH/USD and QdtTC to ETH
        _maximumBuy = 10 ** 18 * 50000 / _originalBuyPrice;
    }
    
    /// _add Address of the account
    function balanceOf(address _addr) override public view returns(uint256) {
        return balances[_addr];
    }
    
    /// check address is approved investor
    function isApprovedInvestor(address _addr) public view returns (bool) {
        return approvedInvestorList[_addr];
    }
    
    /// _addr address get deposit
    function getDeposit (address _addr) public view returns(uint256) {
        return deposit[_addr];
    }
    
    /// Adds list of new investors to the investors list and approve all
    function addInvestorList(address[] memory newInvestorList) onlyOwner public {
        for (uint256 i=0;i<newInvestorList.length;i++) {
            approvedInvestorList[newInvestorList[i]] = true;
        }
    }
    
    /// Removes list of investors from list
    function removeInvestorList(address[] memory investorList) onlyOwner public {
        for (uint256 i=0; i< investorList.length; i++) {
            approvedInvestorList[investorList[i]] = false;
        }
    }
    
    /// Transfers the balance from msg.sender to an account
    function  transfer(address _to, uint256 _amount) override public isTradable returns (bool success) {
        if ((balances[msg.sender] >= _amount) && (_amount >= 0) && (balances[_to] + _amount > balances[_to])){
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        }
        return false;
    }
    
    /// Senf _value of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _amount) override public isTradable returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]){
                balances[_from] -= _amount;
                allowed[_from][msg.sender] -= _amount;
                balances[_to] += _amount;
                emit Transfer(_from, _to, _amount);
                return true;
            }
            return false;
    }
    
    /// Allow _spender to withdraw from your account, multiple times, up to the _value amount
    function approve(address _spender, uint256 _amount) override public isTradable returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    /// get allowance
    function allowance(address _owner, address _spender) override public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
    /// Withdraws Ether in contract
    function withdraw() onlyOwner public returns (bool) {
        return owner.send(address(this).balance);
    }

    /// Show describe
    function getDescribe() public view returns(string memory){
        return _describe;
    }
}