/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
    c = a / b;
}
}


contract BlockChainProject2021_06 is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address public hider_address;   //It is a wallet that can't make any transaction. It is the entity that contrains all the hidden founds
    uint256 public _totalSupply;
    uint[3] public amount;                 //These are the fixed amounts that can be transferred in hidden mode
    uint public commissionRate;              //Expressed as number of token of commission for every 1000 tokens taken from the hidden mode
    uint private commission_profit;          //It is the profit given by the commissions payed
    uint public secure_number;              //It is a divisor of the the total hidden_founds, used to find if it's secure to transfer founds
    address public provider_address;

    //This is a structure containing all the data related to an anonimized transaction
    struct InvisibleTransaction{
        address sender_address;             //Wallet address of the sender
        address receiver_address;           //Wallet address of the receiver
        uint amount_type;                   //The type of quantized amount to be sent
        bool completed;                     //If true means that the transaction has been completed
        uint priority;                      //The priority of the transaction, from 0 to 10, 10 is the max priority
    }

    //This is the array containing some transaction, when I hav to add one new, I'll write on the first avaiable
    //From transaction 0 to 9999 there is priority 100000, from 10000 to 19999 there is priority 9 an so on and so forth
    InvisibleTransaction[100000] invisible_transaction_list;

    //This is the public mapping between an user and his public balance
    mapping(address => uint) balances;

    //This is the private mapping between an user and his private balance, accessible only by himself
    mapping(address => uint) hidden_balances;

    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "TestCourse20210601";
        symbol = "TC0001";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        hider_address =  address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        amount[0]=5000000000000000000;
        amount[1]=50000000000000000000;
        amount[2]=500000000000000000000;
        commissionRate=1;
        commission_profit=0;
        secure_number=10;
        provider_address=msg.sender;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function getAmountByIndex(uint index) public view returns (uint){
        require(index>=0 && index<=2, "Not valid index");
        return amount[index];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(msg.sender != hider_address, "You are the hider, these are not your money");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function setAmount(uint index, uint newAmount) public returns (bool success){
        require(index>=0 && index<=2, "Not valid index");
        amount[index] = newAmount;
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(msg.sender != hider_address, "You are the hider, these are not your money");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function hideBalance(uint tokens) public returns (bool success){
        require(msg.sender != hider_address, "You are the hider, these are not your money");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[hider_address] = safeAdd(balances[hider_address], tokens);
        hidden_balances[msg.sender] = safeAdd(hidden_balances[msg.sender], tokens);
        emit Transfer(msg.sender, hider_address, tokens);
        return true;
    }

    function myHiddenBalance() public view returns (uint balance) {
        return hidden_balances[msg.sender];
    }

    function commissionApproved(uint tokens, address from) private returns (bool success){
        if(hidden_balances[from]-tokens-tokens*commissionRate/1000>=0){
            hidden_balances[from] = safeSub(hidden_balances[from],tokens*commissionRate/1000);
            commission_profit = safeAdd(commission_profit,tokens*commissionRate/1000);
            return true;
        }
        return false;
    }

    function isSecure(uint tokens) private view returns(bool success){
        if(hidden_balances[hider_address]/secure_number > tokens){
            return true;
        }
        return false;
    }

    function getHiddenBalance(uint amountIndex) private returns (bool success){
        require(msg.sender != hider_address, "You are the hider, these are not your money");
        require(amountIndex>=0 && amountIndex<=2, "Not valid Index");
        require(isSecure(amount[amountIndex]),"The transaction is not secure, it could be found the identity of the sender");
        require(commissionApproved(amount[amountIndex], msg.sender), "Founds not sufficient to cover commission costs");
        hidden_balances[msg.sender] = safeSub(hidden_balances[msg.sender], amount[amountIndex]);
        balances[hider_address] = safeAdd(balances[hider_address], amount[amountIndex]);
        emit Transfer(msg.sender, hider_address, amount[amountIndex]);
        return true;
    }

    function getSecureNumber() public pure returns (uint secureNumber){
        return secureNumber;
    }

    function setSecureNumber(uint secureNumber) public returns (bool success){
        require(msg.sender==provider_address, "Not allowed to chenge this variable");
        require(secureNumber>0 && secureNumber<=1000, "Invalid secure Number");
        secure_number = secureNumber;
        return true;
    }

    function setCommissionRate(uint commission_rate) public returns (bool success){
        require(msg.sender==provider_address, "Not allowed to chenge this variable");
        require(commission_rate>=0 && commission_rate<=10, "Invalid commission rate");
        commissionRate=commission_rate;
        return true;
    }


    function hideTransferFromVisible(address to, uint tokens) public returns (bool success) {
        require(msg.sender != hider_address, "You are the hider, these are not your money");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[hider_address] = safeAdd(balances[hider_address], tokens);
        hidden_balances[to] = safeAdd(hidden_balances[to], tokens);
        emit Transfer(msg.sender, hider_address, tokens);
        return true;
    }

    function hideTransferFromHide(address to, uint tokens) public returns (bool success) {
        require(msg.sender != hider_address, "You are the hider, these are not your money");
        hidden_balances[msg.sender] = safeSub(hidden_balances[msg.sender], tokens);
        hidden_balances[to] = safeAdd(hidden_balances[to], tokens);
        return true;
    }

}