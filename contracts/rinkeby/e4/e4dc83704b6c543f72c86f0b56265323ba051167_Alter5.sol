/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.5.1;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract Ownable {
    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Owner did not send the message");
        _;
    }
    
    function getOwner() public view returns(address) {
        return owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

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




contract Alter5 is ERC20Interface, SafeMath, Ownable {
    // uint256 InvestorPointer;
    struct Investor {
        uint256 investmentBalance;
        uint investorPointer;
    }
    address[] investorList;
    mapping(address => Investor) public Investors;
    bool public investmentPeriod;
    uint256 public totalInvestment;

    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event InvestmentPeriodFinished(bool investmentPeriod);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Alter5";
        symbol = "ALTR";
        decimals = 18;
        _totalSupply = 100000000000000000000;
        investmentPeriod = true;
        totalInvestment = 0;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
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
 
    function isInvestor(address investorAddress) public view returns(bool itIsInvestor) {
        // require(investorList.length > 0, "There are no investors added");
        if(investorList.length == 0) {
            return false;
        }
        return (investorList[Investors[investorAddress].investorPointer] == investorAddress);
    }

    function getInvestorCount() public view returns(uint256 investorCount) {
        return investorList.length;
    }


    function newInvestor(address investorAddress, uint256 investment) internal returns(bool success) {
        require(isInvestor(investorAddress) == false, "Investor already registered");
        // entityStructs[entityAddress].listPointer = entityList.push(entityAddress) - 1;
        Investors[investorAddress].investmentBalance = investment;
        totalInvestment = safeAdd(totalInvestment, investment);
        Investors[investorAddress].investorPointer = investorList.push(investorAddress) - 1;
        return true;
    }

    function updateInvestorAddInvestment(address investorAddress, uint256 investment) internal returns(bool success) {
        require(isInvestor(investorAddress) == true, "Investor not registered");
        Investors[investorAddress].investmentBalance = safeAdd(Investors[investorAddress].investmentBalance, investment);
        totalInvestment = safeAdd(totalInvestment, investment);
        return true;
    }
    
    function updateInvestorSubtractInvestment(address investorAddress, uint256 investment) internal returns(bool success) {
        require(isInvestor(investorAddress) == true, "Investor not registered");
        Investors[investorAddress].investmentBalance = safeSub(Investors[investorAddress].investmentBalance, investment);
        totalInvestment = safeSub(totalInvestment, investment);
        return true;
    }

    function deleteInvestor(address investorAddress) internal returns(bool success) {
        require(isInvestor(investorAddress) == true, "Investor not registered");
        uint rowToDelete = Investors[investorAddress].investorPointer;
        uint256 investmentToRevoke = Investors[investorAddress].investmentBalance;
        address keyToMove   = investorList[investorList.length-1];
        investorList[rowToDelete] = keyToMove;
        Investors[keyToMove].investorPointer = rowToDelete;
        investorList.length--;
        totalInvestment = safeSub(totalInvestment, investmentToRevoke); 
        return true;
    }

    function getInvestment(address investorAddress) public view returns(uint256 investmentBalance) {
        require(isInvestor(investorAddress) == true, "The address is not an investor" );
        return Investors[investorAddress].investmentBalance;
    }

    function addInvestment(address investorAddress, uint256 investment) public onlyOwner returns(bool success) {
        require(investmentPeriod == true, "Investment period finished");
        return newInvestor(investorAddress, investment);
    }
    
    function updateInvestmentAdd(address investorAddress, uint256 investment) public onlyOwner returns(bool success) {
        require(investmentPeriod == true, "Investment period finished");
        return updateInvestorAddInvestment(investorAddress, investment);
    }
    
    function updateInvestmentSubtract(address investorAddress, uint256 investment) public onlyOwner returns(bool success) {
        require(investmentPeriod == true, "Investment period finished");
        return updateInvestorSubtractInvestment(investorAddress, investment);
    }

    function cancelInvestment(address investorAddress) public onlyOwner returns(bool success) {
        require(investmentPeriod == true, "Investment period finished");
        return deleteInvestor(investorAddress);
    }

    function finishInvestmentPeriod() public onlyOwner returns(bool success) {
        require(investmentPeriod == true, "Investment period finished");
        uint256 coeff = safeDiv(_totalSupply, totalInvestment);
        for(uint i=0; i< investorList.length; i++) {
            uint256 coinsToSend = safeMul(Investors[investorList[i]].investmentBalance,coeff);
            transfer(investorList[i], coinsToSend);
        }
        investmentPeriod = false;
        emit InvestmentPeriodFinished(investmentPeriod);
        return true;
    }

}