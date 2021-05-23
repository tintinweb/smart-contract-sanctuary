/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity ^0.8.0;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
    function division(uint a, uint b) public pure returns (uint c) {
        a=a-(a%b);
        c=a/b;
    }
}

contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {

        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}


contract Creact_Token is SafeMath, Owner {
    bool _initialization = false;
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    


    function initialization() public {
        require(_initialization==true);
        name = "HelloWord";
        symbol = "HW";
        decimals = 18;
        _totalSupply = 10000000000000000000000;
        //balances[getOwner()] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }



    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
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
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}

contract Contribute is Creact_Token {
    uint private price;
    uint private amountMember;
    uint private time;
    uint private timeBegin;
    bool private status = false;

    struct Member {
        address addressMember;
        uint256 amount;
    }
    
    Member[] member;
    
    event notificationContribute(address sender, uint amount, uint balance);
    event transferContributeErro(address sender, uint amount, uint balance);
    
    modifier statusTrue() {
        require(status == true);
        _;
    }
    
    modifier checkTime() {
        require(timeBegin + time > block.timestamp);
        _;
    }

// Contribute    
    function setContribute(uint _price, uint _amountMember, uint _time) public isOwner {
        require(status==false);
        price = _price;
        amountMember = _amountMember;
        time = _time;
        status = true;
        timeBegin = block.timestamp;
        member.push(Member(getOwner(), 0));
    }
    
    function contributeMember() public statusTrue checkTime payable 
    {
        require(msg.value == price);
        require(getLength() < amountMember);
        member.push(Member(msg.sender, msg.value));
        emit notificationContribute( msg.sender, msg.value, address(this).balance);
    }
    
    function contributeOwenr() public statusTrue checkTime isOwner payable 
    {
        require(member[0].amount == 0);
        require(msg.value == price*amountMember);
        member[0]=Member(getOwner(), (msg.value));
        emit notificationContribute( msg.sender, msg.value, address(this).balance);
    }

// the end
    function contributeErro() public statusTrue {
        require(getLength() < amountMember||member[0].amount == 0);
        require(timeBegin + time < block.timestamp);
        for(uint64 i=0; i<member.length; i++)
        {
            payable(member[i].addressMember).transfer(member[i].amount);   
            emit transferContributeErro(member[i].addressMember, member[i].amount, address(this).balance);
        }
        status = false;
        delete member;
    }
    
    function contributeSuccess() public statusTrue {
        require(getLength() == amountMember);
        require(member[0].amount == price*amountMember);
        require(_initialization==false);
        _initialization=true;
        initialization();
        for(uint64 i=0; i<member.length; i++)
        {
            
            balances[member[i].addressMember]=safeAdd(balances[member[i].addressMember], division(_totalSupply*(member[i].amount/(10**15)),getBalance()/(10**15)));
            
        }
    }
    
 //call 
    
    function getPrice() public view statusTrue returns (uint)
    {
        return price;
    }
    
    function getAmountMember() public view statusTrue returns (uint)
    {
        return amountMember;
    }
    
    function getStatus() public view  returns (bool)
    {
        return status;
    }
    
    function getBalance() public view statusTrue returns (uint) 
    {
        return address(this).balance;
    }
    
    function getTimeBegin() public statusTrue view returns (uint) 
    {
        return timeBegin;
    }
    
    function getTime() public statusTrue view returns (uint) {
        return time;
    }
    
    function getLength() public view statusTrue returns (uint)
    {
        return member.length-1;
    }
    
    function getMember() public view statusTrue returns (Member[] memory) 
    {
        return (member);
    }
    
// Owner reset test    
    
    function reset() public isOwner {
        payable(getOwner()).transfer(getBalance());
        emit transferContributeErro(getOwner(),getBalance(), address(this).balance);
        status = false;
        _initialization=false;
        for(uint64 i=0; i<member.length; i++)
        {
             balances[member[i].addressMember]=0;
        }
        delete member;
    }
    
}