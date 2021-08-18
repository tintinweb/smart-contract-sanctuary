/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity ^0.8.7;



contract SafeApeV5 {
    string public name = "SafeApe V5";
    string public symbol = "$APE";
    address public owner;
    uint public totalSupply;
    uint public decimals;
    uint public marketing_tax;
    uint public reflections_tax;
    uint public sellLockTime;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    mapping(address => uint) dividends;
    mapping(address => uint256) transaction_timestamps;
    address[] holders;
    address[] exemptedFromTax;
    bool public trading;

    address public marketing_wallet = 0x1cFF7944Ce4A5c0d5E9e039C9C1D75453098C780;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    modifier isOwner()  {
        require(msg.sender == owner, "Only owner can execute this function");
        _;
    }


    constructor(uint _totalSupply, uint _decimals) {
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** decimals;
        owner = msg.sender;
        sellLockTime = 300;
        reflections_tax = 10;
        marketing_tax = 5;
        trading = true;
        exemptedFromTax.push(msg.sender);
        exemptedFromTax.push(marketing_wallet);
        exemptedFromTax.push(address(0));
        balances[msg.sender] += totalSupply;
        holders.push(msg.sender);
    }

    function renounceOwnership() isOwner() public {
        owner = address(0);
    }
    
    function exemptFromTax(address _address) isOwner() public {
        exemptedFromTax.push(_address);
    }

    function transferOwner(address newOwner) isOwner() public {
        owner = newOwner;
    }

    function balanceOf(address tokenOwner) public view returns(uint){
        return balances[tokenOwner];
    }

    function approve(address spender, uint tokens) public returns(bool){
        require(msg.sender!=spender);
        allowances[msg.sender][spender] += tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowances[tokenOwner][spender];
    }

    function transfer(address to, uint amount) public {
        require(balances[msg.sender] >= amount, "Balance of the address is too low");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        transaction_timestamps[to] = block.timestamp;
        emit Transfer(msg.sender, to, amount);
        if(!isAvailable(to)){
            holders.push(to);
        }
        if(balances[msg.sender] == 0)  {
            remove(getIndex(msg.sender));
        }
    }

    function transferFrom(address from, address to, uint tokens) public returns(bool) {
        require(trading, "SafeApe: Trading is not enabled at the moment");
        require(balances[from] >= tokens, "SafeApe: Balance of the address is too low");
        require(allowances[from][msg.sender] >= tokens, "SafeApe: Allowance is low");
        require(block.timestamp - transaction_timestamps[from] > sellLockTime , "SafeApe: Your selling ability is currently frozen");
        balances[from] -= tokens;
        if(!isExempted(from)) {
            uint marketing_amount = calculateFee(marketing_tax, tokens);
            uint reflection_amount = calculateFee(reflections_tax, tokens);
            balances[marketing_wallet] += marketing_amount;
            distributeReflections(reflection_amount, to);
            tokens -= marketing_amount + reflection_amount;
        }
        balances[to] += tokens;
        if(!isAvailable(to)){
            holders.push(to);
        }
        if(balances[from] == 0)  {
            remove(getIndex(from));
        }
        transaction_timestamps[from] = block.timestamp;
        emit Transfer(from, to, tokens);
        return true;
    }

    function getUnlockTime(address _address) public view returns(uint) {
        uint lastTransaction = block.timestamp - transaction_timestamps[_address];
        if(lastTransaction > 300) {
            return 0;
        }
        else {
            return sellLockTime - lastTransaction;
        }
    }

    function distributeReflections(uint amount, address to) internal {
        uint remaining_amount = amount;
        for(uint i = 0 ; i < holders.length; i++) {
            address holder = holders[i];
            if(!isExempted(holder)) {
                uint dividend = calculateDividendAmount(calculateSupplyPerc(balances[holder]), amount);
                balances[holder] += dividend;
                dividends[holder] += dividend;
                remaining_amount -= dividend;
            }
        }
        balances[to] += remaining_amount;
    }
    

    function updateMarketingTax(uint newTax) isOwner public {
        marketing_tax = newTax;
    }

    function updateMarketingWallet(address newAddress) isOwner public {
        marketing_wallet = newAddress;
    }

    function updateReflectionsTax(uint newTax) isOwner public {
        reflections_tax = newTax;
    }


    function getIndex(address _address) internal view returns(uint) {
        for(uint i = 0 ; i < holders.length; i++) {
            if(_address == holders[i]) {
                return i;
            }
        }
        revert("Not such holder");
    }

    function isAvailable(address _address) internal view returns(bool) {
        for(uint i = 0 ; i < holders.length; i++) {
            if(_address == holders[i]) {
                return true;
            }
        }
        return false;
    }
    
    function isExempted(address _address) internal view returns(bool) {
        for(uint i = 0 ; i < exemptedFromTax.length; i++) {
            if(_address == exemptedFromTax[i]) {
                return true;
            }
        }
        return false;
    }

    function calculateFee(uint _fee, uint amount) internal pure returns(uint){
        return (amount/10000) * (_fee * 100);
    }

    function calculateDividendAmount(uint _fee, uint amount) internal pure returns(uint){
        return (amount/10000) * (_fee);
    }

    function calculateSupplyPerc(uint balance) internal view returns(uint) {
        return balance * 10000 / totalSupply;
    }

    function tradeSwitch() public {
        trading = !trading;
    }
    
    function dividendsEarned(address _address) public view returns(uint){
        return dividends[_address];
    }
    
    function remove(uint index) internal returns(bool) {
        require(index <= holders.length);

        for (uint i = index; i<holders.length-1; i++){
            holders[i] = holders[i+1];
        }
        holders.pop();
        return true;
    }
}