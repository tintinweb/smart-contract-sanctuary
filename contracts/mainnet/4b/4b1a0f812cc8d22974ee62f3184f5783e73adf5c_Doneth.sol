/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

pragma solidity ^0.4.15;

/**
 * @title Doneth (Doneth)
 * @dev Doneth is a contract that allows shared access to funds
 * in the form of Ether and ERC20 tokens. It is especially relevant
 * to donation based projects. The admins of the contract determine 
 * who is a member, and each member gets a number of shares. The 
 * number of shares each member has determines how much Ether/ERC20 
 * the member can withdraw from the contract.
 */


contract Doneth {

    address public implementation;
    // constructor(address _implementation) public {}

    address public owner;

    function Ownable() public {
        owner = tx.origin;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || tx.origin == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    using SafeMath for uint256;  

    bool public initialized;

    // Name of the contract
    string public name;

    // Sum of all shares allocated to members
    uint256 public totalShares;

    // Sum of all withdrawals done by members
    uint256 public totalWithdrawn;

    // Block number of when the contract was created
    uint256 public genesisBlockNumber;

    // Number of decimal places for floating point division
    uint256 constant public PRECISION = 18;

    // Variables for shared expense allocation
    uint256 public sharedExpense;
    uint256 public sharedExpenseWithdrawn;

    // Used to keep track of members
    mapping(address => Member) public members;
    address[] public memberKeys;
    struct Member {
        bool exists;
        bool admin;
        uint256 shares;
        uint256 withdrawn;
        string memberName;
        mapping(address => uint256) tokensWithdrawn;
    }

    // Used to keep track of ERC20 tokens used and how much withdrawn
    mapping(address => uint256) public tokens;

    function init() public {
        require(!initialized);
        initialized = true;

        owner = tx.origin;
        genesisBlockNumber = block.number;

        Member memory newMember;
        newMember.exists = true;
        newMember.admin = true;
        members[tx.origin] = newMember;
        memberKeys.push(tx.origin);

        totalShares = totalShares.add(1);
        members[tx.origin].shares = members[tx.origin].shares.add(1);
        AddShare(tx.origin, 1, members[tx.origin].shares);
    }

    event Deposit(address from, uint value);
    event Withdraw(address from, uint value, uint256 newTotalWithdrawn);
    event TokenWithdraw(address from, uint value, address token, uint amount);
    event AddShare(address who, uint256 addedShares, uint256 newTotalShares);
    event RemoveShare(address who, uint256 removedShares, uint256 newTotalShares);
    event ChangePrivilege(address who, bool oldValue, bool newValue);
    event ChangeContractName(string oldValue, string newValue);
    event ChangeMemberName(address who, string oldValue, string newValue);
    event ChangeSharedExpense(uint256 contractBalance, uint256 oldValue, uint256 newValue);
    event WithdrawSharedExpense(address from, address to, uint value, uint256 newSharedExpenseWithdrawn);

    // Fallback function accepts Ether from donators
    function () public payable {
        Deposit(msg.sender, msg.value);
    }

    modifier onlyAdmin() { 
        if (msg.sender != owner && !members[msg.sender].admin) revert();   
        _;
    }

    modifier onlyExisting(address who) { 
        if (!members[who].exists) revert(); 
        _;
    }

    // Series of getter functions for contract data
    function getMemberCount() public constant returns(uint) {
        return memberKeys.length;
    }
    
    function getMemberAtKey(uint key) public constant returns(address) {
        return memberKeys[key];
    }
    
    function getBalance() public constant returns(uint256 balance) {
        return this.balance;
    }
    
    function getContractInfo() public constant returns(string name, address owner,  uint256 genesisBlockNumber,  uint256 totalShares,  uint256 totalWithdrawn) {
        return (string(name), owner, genesisBlockNumber, totalShares, totalWithdrawn);
    }
    
    function returnMember(address _address) public constant onlyExisting(_address) returns(bool admin, uint256 shares, uint256 withdrawn, string memberName) {
      Member memory m = members[_address];
      return (m.admin, m.shares, m.withdrawn, m.memberName);
    }

    function checkERC20Balance(address token) public constant returns(uint256) {
        return ERC20(token).balanceOf(address(this));
    }

    // Function to add members to the contract 
    function addMember(address who, uint256 shares, bool admin, string memberName) public onlyAdmin() {
        // Don't allow the same member to be added twice
        if (members[who].exists) revert();
        if (bytes(memberName).length > 21) revert();

        Member memory newMember;
        newMember.exists = true;
        newMember.admin = admin;
        newMember.memberName = memberName;

        members[who] = newMember;
        memberKeys.push(who);
        addShare(who, shares);
    }

    function updateMember(address who, uint256 shares, bool isAdmin, string name) public onlyAdmin() {
        if (sha3(members[who].memberName) != sha3(name)) changeMemberName(who, name);
        if (members[who].admin != isAdmin) changeAdminPrivilege(who, isAdmin);
        if (members[who].shares != shares) allocateShares(who, shares);
    }

    // Only owner, admin or member can change member's name
    function changeMemberName(address who, string newName) public onlyExisting(who) {
        if (msg.sender != who && msg.sender != owner && !members[msg.sender].admin) revert();
        if (bytes(newName).length > 21) revert();
        ChangeMemberName(who, members[who].memberName, newName);
        members[who].memberName = newName;
    }

    function changeAdminPrivilege(address who, bool newValue) public onlyAdmin() {
        ChangePrivilege(who, members[who].admin, newValue);
        members[who].admin = newValue; 
    }

    // Only admins and owners can change the contract name
    function changeContractName(string newName) public onlyAdmin() {
        if (bytes(newName).length > 21) revert();
        ChangeContractName(name, newName);
        name = newName;
    }

    // Shared expense allocation allows admins to withdraw an amount to be used for shared
    // expenses. Shared expense allocation subtracts from the total balance of the contract. 
    // Only owner can change this amount.
    function changeSharedExpenseAllocation(uint256 newAllocation) public onlyOwner() {
        if (newAllocation < sharedExpenseWithdrawn) revert();
        if (newAllocation.sub(sharedExpenseWithdrawn) > this.balance) revert();

        ChangeSharedExpense(this.balance, sharedExpense, newAllocation);
        sharedExpense = newAllocation;
    }

    // Set share amount explicitly by calculating difference then adding or removing accordingly
    function allocateShares(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        uint256 currentShares = members[who].shares;
        if (amount == currentShares) revert();
        if (amount > currentShares) {
            addShare(who, amount.sub(currentShares));
        } else {
            removeShare(who, currentShares.sub(amount));
        }
    }

    // Increment the number of shares for a member
    function addShare(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        totalShares = totalShares.add(amount);
        members[who].shares = members[who].shares.add(amount);
        AddShare(who, amount, members[who].shares);
    }

    // Decrement the number of shares for a member
    function removeShare(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        totalShares = totalShares.sub(amount);
        members[who].shares = members[who].shares.sub(amount);
        RemoveShare(who, amount, members[who].shares);
    }

    // Function for a member to withdraw Ether from the contract proportional
    // to the amount of shares they have. Calculates the totalWithdrawableAmount
    // in Ether based on the member's share and the Ether balance of the contract,
    // then subtracts the amount of Ether that the member has already previously
    // withdrawn.
    function withdraw(uint256 amount) public onlyExisting(msg.sender) {
        uint256 newTotal = calculateTotalWithdrawableAmount(msg.sender);
        if (amount > newTotal.sub(members[msg.sender].withdrawn)) revert();
        
        members[msg.sender].withdrawn = members[msg.sender].withdrawn.add(amount);
        totalWithdrawn = totalWithdrawn.add(amount);
        msg.sender.transfer(amount);
        Withdraw(msg.sender, amount, totalWithdrawn);
    }

    // Withdrawal function for ERC20 tokensx
    function withdrawToken(uint256 amount, address token) public onlyExisting(msg.sender) {
        uint256 newTotal = calculateTotalWithdrawableTokenAmount(msg.sender, token);
        if (amount > newTotal.sub(members[msg.sender].tokensWithdrawn[token])) revert();

        members[msg.sender].tokensWithdrawn[token] = members[msg.sender].tokensWithdrawn[token].add(amount);
        tokens[token] = tokens[token].add(amount);
        ERC20(token).transfer(msg.sender, amount);
        TokenWithdraw(msg.sender, amount, token, tokens[token]);
    }

    // Withdraw from shared expense allocation. Total withdrawable is calculated as 
    // sharedExpense minus sharedExpenseWithdrawn. Only Admin can withdraw from shared expense.
    function withdrawSharedExpense(uint256 amount, address to) public onlyAdmin() {
        if (amount > calculateTotalExpenseWithdrawableAmount()) revert();
        
        sharedExpenseWithdrawn = sharedExpenseWithdrawn.add(amount);
        to.transfer(amount);
        WithdrawSharedExpense(msg.sender, to, amount, sharedExpenseWithdrawn);
    }

    // Converts from shares to Eth.
    // Ex: 2 shares, 4 total shares, 40 Eth balance
    // 40 Eth / 4 total shares = 10 eth per share * 2 shares = 20 Eth to cash out
    function calculateTotalWithdrawableAmount(address who) public constant onlyExisting(who) returns (uint256) {
        // Total balance to calculate share from = 
        // contract balance + totalWithdrawn - sharedExpense + sharedExpenseWithdrawn
        uint256 balanceSum = this.balance.add(totalWithdrawn);
        balanceSum = balanceSum.sub(sharedExpense);
        balanceSum = balanceSum.add(sharedExpenseWithdrawn);
        
        // Need to use parts-per notation to compute percentages for lack of floating point division
        uint256 ethPerSharePPN = balanceSum.percent(totalShares, PRECISION); 
        uint256 ethPPN = ethPerSharePPN.mul(members[who].shares);
        uint256 ethVal = ethPPN.div(10**PRECISION); 
        return ethVal;
    }


    function calculateTotalWithdrawableTokenAmount(address who, address token) public constant returns(uint256) {
        uint256 balanceSum = checkERC20Balance(token).add(tokens[token]);

        // Need to use parts-per notation to compute percentages for lack of floating point division
        uint256 tokPerSharePPN = balanceSum.percent(totalShares, PRECISION); 
        uint256 tokPPN = tokPerSharePPN.mul(members[who].shares);
        uint256 tokVal = tokPPN.div(10**PRECISION); 
        return tokVal;
    }

    function calculateTotalExpenseWithdrawableAmount() public constant returns(uint256) {
        return sharedExpense.sub(sharedExpenseWithdrawn);
    }

    // Used for testing
    function delegatePercent(uint256 a, uint256 b, uint256 c) public constant returns (uint256) {
        return a.percent(b, c);
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    // Using from SO: https://stackoverflow.com/questions/42738640/division-in-ethereum-solidity/42739843#42739843
    // Adapted to use SafeMath and uint256.
    function percent(uint256 numerator, uint256 denominator, uint256 precision) internal constant returns(uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 _numerator = mul(numerator, 10 ** (precision+1));
        // with rounding of last digit
        uint256 _quotient = (div(_numerator, denominator) + 5) / 10;
        return (_quotient);
    }
}