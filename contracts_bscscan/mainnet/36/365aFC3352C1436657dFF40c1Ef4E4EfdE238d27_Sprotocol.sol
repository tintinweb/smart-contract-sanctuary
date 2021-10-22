/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

pragma solidity ^0.5.17;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

}

/*************************************************************/
/*       SynchronizedProtcol - "Sprotocol"  starts here       */
/*************************************************************/

contract Sprotocol {

    using SafeMath for uint256;

    address public rebaseOracle;       // Used for authentication
    address public owner;              // Used for authentication
    address public newOwner;

    uint8 public decimals;
    uint256 public totalSupply;
    string public name;
    string public symbol;

    uint256 private constant MAX_UINT256 = ~uint256(0);   // (2^256) - 1
    uint256 private constant MAXSUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private totalAtoms;
    uint256 private atomsPerMolecule;

    mapping (address => uint256) private atomBalances;
    mapping (address => mapping (address => uint256)) private allowedMolecules;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LogRebase(uint256 _totalSupply);
    event LogNewRebaseOracle(address _rebaseOracle);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor(address allocationsContract) public
    {
        decimals = 18;                    // decimals  
        totalSupply = 10000000*10**18;    // initial supply: 10000000 WTISDR
        name = "Sprotocol";               // Synchronized Protocol´s display name
        symbol = "WTISDR";                // symbol for display purposes

        owner = msg.sender;
        totalAtoms = MAX_UINT256 - (MAX_UINT256 % totalSupply);    
        atomBalances[allocationsContract] = totalAtoms;
        atomsPerMolecule = totalAtoms.div(totalSupply);

        emit Transfer(address(0), allocationsContract, totalSupply);
    }
 
    // totalAtoms is a multiple of totalSupply so that atomsPerMolecule is an integer.
   
    /**
     * @param newRebaseOracle The address of the new oracle for rebasement (used for authentication).
     */
    function setRebaseOracle(address newRebaseOracle) external {
        require(msg.sender == owner, "Can only be executed by owner.");
        rebaseOracle = newRebaseOracle;

        emit LogNewRebaseOracle(rebaseOracle);
    }

    /**
     * @dev Propose a new owner.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public
    {
        require(msg.sender == owner, "Can only be executed by owner.");
        require(_newOwner != address(0), "0x00 address not allowed.");
        newOwner = _newOwner;
    }

    /**
     * @dev Accept new owner.
     */
    function acceptOwnership() public
    {
        require(msg.sender == newOwner, "Sender not authorized.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /**
     * @dev Notifies Sprotocol contract about a new rebase cycle.
     * @param supplyDelta The number of new molecule tokens to add into or remove from circulation.
     * @param increaseSupply Whether to increase or decrease the total supply.
     * @return The total number of molecules after the supply adjustment.
     */
    function rebase(uint256 supplyDelta, bool increaseSupply) external returns (uint256) {
        require(msg.sender == rebaseOracle, "Can only be executed by rebaseOracle.");
        
        if (supplyDelta == 0) {
            emit LogRebase(totalSupply);
            return totalSupply;
        }

        if (increaseSupply == true) {
            totalSupply = totalSupply.add(supplyDelta);
        } else {
            totalSupply = totalSupply.sub(supplyDelta);
        }

        if (totalSupply > MAXSUPPLY) {
            totalSupply = MAXSUPPLY;
        }

        atomsPerMolecule = totalAtoms.div(totalSupply);

        emit LogRebase(totalSupply);
        return totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view returns (uint256) {
        return atomBalances[who].div(atomsPerMolecule);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0),"Invalid address.");
        require(to != address(this),"Molecules contract can't receive WTISDR.");

        uint256 atomValue = value.mul(atomsPerMolecule);

        atomBalances[msg.sender] = atomBalances[msg.sender].sub(atomValue);
        atomBalances[to] = atomBalances[to].add(atomValue);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowedMolecules[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0),"Invalid address.");
        require(to != address(this),"Molecules contract can't receive WTISDR.");

        allowedMolecules[from][msg.sender] = allowedMolecules[from][msg.sender].sub(value);

        uint256 atomValue = value.mul(atomsPerMolecule);
        atomBalances[from] = atomBalances[from].sub(atomValue);
        atomBalances[to] = atomBalances[to].add(atomValue);
        
        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 and therefore also for BEP20 compatibility.
     * IncreaseAllowance and decreaseAllowance should be used instead.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        allowedMolecules[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowedMolecules[msg.sender][spender] = allowedMolecules[msg.sender][spender].add(addedValue);

        emit Approval(msg.sender, spender, allowedMolecules[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowedMolecules[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            allowedMolecules[msg.sender][spender] = 0;
        } else {
            allowedMolecules[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowedMolecules[msg.sender][spender]);
        return true;
    }
}