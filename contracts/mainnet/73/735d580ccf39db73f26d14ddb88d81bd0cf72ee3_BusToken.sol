pragma solidity ^0.4.11;

// Token Issue Smart Contract for Bitconch Coin
// Symbol       : BUS
// Name         : Bitconch Coin
// Total Supply : 50 Billion
// Decimal      : 18
// Compiler     : 0.4.11+commit.68ef5810.Emscripten.clang
// Optimazation : Yes


// @title SafeMath
// @dev Math operations with safety checks that throw on error
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
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
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control functions
 */
contract Ownable {
    address public owner;

    // @dev Constructor sets the original `owner` of the contract to the sender account.
    function Ownable() {
        owner = msg.sender;
    }

    // @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    // @dev Allows the current owner to transfer control of the contract to a newOwner.
    // @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


/**
 * @title Claimable
 * @dev the ownership of contract needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
    address public pendingOwner;

    // @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    // @dev Allows the current owner to set the pendingOwner address.
    // @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) onlyOwner {
        pendingOwner = newOwner;
    }

    // @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership() onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = 0x0;
    }
}


/**
 * @title Contactable token
 * @dev Allowing the owner to provide a string with their contact information.
 */
contract Contactable is Ownable{

    string public contactInformation;

    // @dev Allows the owner to set a string with their contact information.
    // @param info The contact information to attach to the contract.
    function setContactInformation(string info) onlyOwner{
        contactInformation = info;
    }
}


/**
 * @title Contracts that should not own Ether
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be send to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
*/
contract HasNoEther is Ownable {

    /**
    * @dev Constructor that rejects incoming Ether
    * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
    * leave out payable, then Solidity will allow inheriting contracts to implement a payable
    * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
    * we could use assembly to access msg.value.
    */
    function HasNoEther() payable {
        require(msg.value == 0);
    }

    /**
     * @dev Disallows direct send by settings a default function without the `payable` flag.
     */
    function() external {
    }

    /**
     * @dev Transfer all Ether held by the contract to the owner.
     */
    function reclaimEther() external onlyOwner {
        assert(owner.send(this.balance));
    }
}


/**
 * @title Standard ERC20 token
 * @dev Implementation of the ERC20Interface
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    using SafeMath for uint256;

    // private
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // @dev Get the total token supply
    function totalSupply() constant returns (uint256) {
        return _totalSupply;
    }

    // @dev Gets the balance of the specified address.
    // @param _owner The address to query the the balance of.
    // @return An uint256 representing the amount owned by the passed address.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // @dev transfer token for a specified address
    // @param _to The address to transfer to.
    // @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value) returns (bool) {
        require(_to != 0x0 );
        require(_value > 0 );

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    // @dev Transfer tokens from one address to another
    // @param _from address The address which you want to send tokens from
    // @param _to address The address which you want to transfer to
    // @param _value uint256 the amout of tokens to be transfered
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(_from != 0x0 );
        require(_to != 0x0 );
        require(_value > 0 );

        var _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);

        Transfer(_from, _to, _value);
        return true;
    }

    // @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
    // @param _spender The address which will spend the funds.
    // @param _value The amount of tokens to be spent.
    function approve(address _spender, uint256 _value) returns (bool) {
        require(_spender != 0x0 );
        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_spender, 0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);
        return true;
    }

    // @dev Function to check the amount of tokens that an owner allowed to a spender.
    // @param _owner address The address which owns the funds.
    // @param _spender address The address which will spend the funds.
    // @return A uint256 specifing the amount of tokens still avaible for the spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract StandardToken is ERC20 {
    string public name;
    string public symbol;
    uint256 public decimals;

    function isToken() public constant returns (bool) {
        return true;
    }
}

/**
 * @dev FreezableToken
 *
 */
contract FreezableToken is StandardToken, Ownable {
    mapping (address => bool) public frozenAccounts;
    event FrozenFunds(address target, bool frozen);

    // @dev freeze account or unfreezen.
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccounts[target] = freeze;
        FrozenFunds(target, freeze);
    }

    // @dev Limit token transfer if _sender is frozen.
    modifier canTransfer(address _sender) {
        require(!frozenAccounts[_sender]);

        _;
    }

    function transfer(address _to, uint256 _value) canTransfer(msg.sender) returns (bool success) {
        // Call StandardToken.transfer()
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from) returns (bool success) {
        // Call StandardToken.transferForm()
        return super.transferFrom(_from, _to, _value);
    }
}

/**
 * @title BusToken
 * @dev The BusToken contract is Claimable, and provides ERC20 standard token.
 */
contract BusToken is Claimable, Contactable, HasNoEther, FreezableToken {
    // @dev Constructor initial token info
    function BusToken(){
        uint256 _decimals = 18;
        uint256 _supply = 50000000000*(10**_decimals);

        _totalSupply = _supply;
        balances[msg.sender] = _supply;
        name = "Bitconch Coin";
        symbol = "BUS";
        decimals = _decimals;
        contactInformation = "Bitconch Contact Email:info@bitconch.io";
    }
}


contract BusTokenLock is Ownable, HasNoEther {
    using SafeMath for uint256;

    // @dev How many investors we have now
    uint256 public investorCount;
    // @dev How many tokens investors have claimed so far
    uint256 public totalClaimed;
    // @dev How many tokens our internal book keeping tells us to have at the time of lock() when all investor data has been loaded
    uint256 public tokensAllocatedTotal;

    // must hold as much as tokens
    uint256 public tokensAtLeastHold;

    struct balance{
        address investor;
        uint256 amount;
        uint256 freezeEndAt;
        bool claimed;
    }

    mapping(address => balance[]) public balances;
    // @dev How many tokens investors have claimed
    mapping(address => uint256) public claimed;

    // @dev token
    FreezableToken public token;

    // @dev We allocated tokens for investor
    event Invested(address investor, uint256 amount, uint256 hour);

    // @dev We distributed tokens to an investor
    event Distributed(address investors, uint256 count);

    /**
     * @dev Create contract where lock up period is given days
     *
     * @param _owner Who can load investor data and lock
     * @param _token Token contract address we are distributing
     *
     */
    function BusTokenLock(address _owner, address _token) {
        require(_owner != 0x0);
        require(_token != 0x0);

        owner = _owner;
        token = FreezableToken(_token);
    }

    // @dev Add investor
    function addInvestor(address investor, uint256 _amount, uint256 hour) public onlyOwner {
        require(investor != 0x0);
        require(_amount > 0); // No empty buys

        uint256 amount = _amount *(10**token.decimals());
        if(balances[investor].length == 0) {
            investorCount++;
        }

        balances[investor].push(balance(investor, amount, now + hour*60*60, false));
        tokensAllocatedTotal += amount;
        tokensAtLeastHold += amount;
        // Do not lock if the given tokens are not on this contract
        require(token.balanceOf(address(this)) >= tokensAtLeastHold);

        Invested(investor, amount, hour);
    }

    // @dev can only withdraw rest of investor&#39;s tokens
    function withdrawLeftTokens() onlyOwner {
        token.transfer(owner, token.balanceOf(address(this))-tokensAtLeastHold);
    }

    // @dev Get the current balance of tokens
    // @return uint256 How many tokens there are currently
    function getBalance() public constant returns (uint256) {
        return token.balanceOf(address(this));
    }

    // @dev Claim N bought tokens to the investor as the msg sender
    function claim() {
        withdraw(msg.sender);
    }

    function withdraw(address investor) internal {
        require(balances[investor].length > 0);

        uint256 nowTS = now;
        uint256 withdrawTotal;
        for (uint i = 0; i < balances[investor].length; i++){
            if(balances[investor][i].claimed){
                continue;
            }
            if(nowTS<balances[investor][i].freezeEndAt){
                continue;
            }

            balances[investor][i].claimed=true;
            withdrawTotal += balances[investor][i].amount;
        }

        claimed[investor] += withdrawTotal;
        totalClaimed += withdrawTotal;
        token.transfer(investor, withdrawTotal);
        tokensAtLeastHold -= withdrawTotal;
        require(token.balanceOf(address(this)) >= tokensAtLeastHold);

        Distributed(investor, withdrawTotal);
    }
}