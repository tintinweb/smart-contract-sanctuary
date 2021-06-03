/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;


// Part: SafeMath

// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
contract SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
    }
    
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */    
    function safeMul(uint a, uint b) public pure returns (uint c) { 
        c = a * b; require(a == 0 || c / a == b); 
    } 
    
        /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
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

/**
 * @title Owner
 * @dev Creact Token inherit the Owner contract and SafeMath contract
 */
contract Creact_Token is SafeMath, Owner {
    /// @notice token status. With the same token that was generated. Equals uncreated token 
    bool public _initialization = false;
    
    /// @notice ERC-20 token name for this token
    string public name;
    
     /// @notice ERC-20 token symbol for this token
    string public symbol;
    
    /// @notice ERC-20 token decimals for this token
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    
    /// @notice Total number of tokens in circulation
    uint256 public _totalSupply;

    /// @notice Official record of token balances for each account
    mapping(address => uint) public balances;
    
    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint)) public allowed;
    
    /// @notice The standard ERC-20 transfer event
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    /// @notice The standard ERC-20 approval event
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    

    /**
     * @notice Creact token
     */
    function initialization() public {
        require(_initialization==true);
        name = "HelloWord";
        symbol = "HW";
        decimals = 18;
        _totalSupply = 10000000000000000000000;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `_owner`
     * @param _owner The address of the _owner holding the funds
     * @param spender The address of the _owner spending the funds
     * @return The number of tokens approved
     */
    
    function allowance(address _owner, address spender) public view returns (uint) {
        return allowed[_owner][spender];
    }
    
    /**
    * @notice `msg.sender` approves `spender` to spend `tokens` tokens
    * @param spender The address of the account able to transfer the tokens
    * @param tokens The amount of wei to be approved for transfer
    * @return Whether the approval was successful or not
    */
    function approve(address spender, uint tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `to`
     * @param to The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address to, uint tokens) public returns (bool) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    /**
     * @notice Transfer `amount` tokens from `from` to `to`
     * @param from The address of the source account
     * @param to The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}


/**
 * @title Contribute
 * @dev make capital contribute
 */
contract Contribute is Creact_Token {
    
    /// @notice contribution amount
    uint public price;
    
    /// @notice maximum number of members to join
    uint public amountMember;
    
    /// @notice amount of time to be involved in contributing
    uint public time;
    
    /// @notice Contribution start time
    uint public timeBegin;
    
    /// @notice contribution status. Jf equals false the contribution is not initialized. if equals the initialization contribution
    bool public status = false;

    /// @notice Information about members participating in contributions
    /// @pragma addressMember Member address
    /// @pragma amount contribution amount
    struct Member {
        address addressMember;
        uint256 amount;
    }
    
    ///@notice Initialize the member array
    Member[] public member;
    
    ///@notice deposit event
    event notificationContribute(address sender, uint amount, uint balance);
    
    ///@notice Refund event
    event transferContributeErro(address sender, uint amount, uint balance);
    
    ///@notice check initialization contribution
    modifier statusTrue() {
        require(status == true);
        _;
    }
    
    ///@notice check contribution time
    modifier checkTime() {
        require(timeBegin + time > block.timestamp);
        _;
    }

    /**
     * @notice TContributing members
     */    
    function setContribute(uint _price, uint _amountMember, uint _time) public isOwner {
        require(status==false);
        price = _price;
        amountMember = _amountMember;
        time = _time;
        status = true;
        timeBegin = block.timestamp;
        member.push(Member(getOwner(), 0));
    }
    
    /**
     * @notice TContributing members
     */  
    function contributeMember() public statusTrue checkTime payable 
    {
        require(msg.value == price);
        require(getLength() < amountMember);
        member.push(Member(msg.sender, msg.value));
        emit notificationContribute( msg.sender, msg.value, address(this).balance);
    }
    
    /**
     * @notice The contract owner participates in the contribution
     */  
    function contributeOwenr() public statusTrue checkTime isOwner payable 
    {
        require(member[0].amount == 0);
        /// @notice The amount of the contract owner's contribution is equal to the total amount of all participating members' contributions
        require(msg.value == price*amountMember);
        member[0]=Member(getOwner(), (msg.value));
        emit notificationContribute( msg.sender, msg.value, address(this).balance);
    }

    /// @notice Refund to members when they don't contribute enough
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
    
    /// @notice Proceed to create tokens and distribute money to participating members
    function contributeSuccess() public statusTrue {
        require(getLength() == amountMember,"erro 1");
        require(member[0].amount == price*amountMember, "erro 2");
        require(_initialization==false, "erro 3");
        _initialization=true;
        initialization();
        for(uint64 i=0; i<member.length; i++)
        {
            
            balances[member[i].addressMember]=safeAdd(balances[member[i].addressMember], uint(_totalSupply*member[i].amount)/uint(getBalance()));
            
        }
    }
    
 //call 
    
    /// @notice contribution amount
    function getPrice() public view statusTrue returns (uint)
    {
        return price;
    }
    
    /// @notice maximum number of members to join
    function getAmountMember() public view statusTrue returns (uint)
    {
        return amountMember;
    }
    
    /// @notice contribution status. Jf equals false the contribution is not initialized. if equals the initialization contribution
    function getStatus() public view  returns (bool)
    {
        return status;
    }
    
    /// @notice Total amount in the contract
    function getBalance() public view statusTrue returns (uint) 
    {
        return address(this).balance;
    }
    
    /// @notice Contribution start time
    function getTimeBegin() public statusTrue view returns (uint) 
    {
        return timeBegin;
    }
    
    /// @notice amount of time to be involved in contributing
    function getTime() public statusTrue view returns (uint) {
        return time;
    }
    
    /// @notice Number of members who have contributed capital
    function getLength() public view statusTrue returns (uint)
    {
        return member.length-1;
    }
    
    /// @notice Information about members who have contributed capital
    function getMember() public view statusTrue returns (Member[] memory) 
    {
        return (member);
    }
    
// Owner reset test. Only use to check contract 
    
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