/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.4.17;

/**
 * @title SafeMath Mathematical Safe Function
 * @dev Math operations with safety checks that throw on error.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Denominator greater than 0 will be automatically determined in the solidity contract
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
   * @title Ownable token owner
 * @dev The Ownable contract has an owner address, and provides basic authorization control.
 * @dev functions, this simplifies the implementation of "user permissions".
   * @dev This contract mainly indicates that the creator of the contract is the creator of the token. It also includes authorization control functions to simplify "user permissions".
 */

contract Ownable{
    //"owner"
    address public owner;
    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
             * @dev regards the person who created the contract as the initial "owner".
      */
    constructor() public{
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
             * @dev is temporarily unknown, it should be an operation that can only be performed by the owner.
      */
    modifier onlyOwner(){
        require(msg.sender == owner, "Only called by owner!");
        //This line indicates the inheritance used in this contract
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
         * @dev Power transfer to the new owner
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner{
        //First make sure that the new user is not at 0x0 address
        require(newOwner != address(0), "Cannot transfer owner to address 0");
        owner = newOwner;
    }
}

/**
   * @title ERC20Basic is based on REC20, not direct inheritance, but similar code
   * @dev Simpler version of ERC20 interface is a simplified version of ERC20 standard interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
   * @dev The new version of the compiler 0.6.1 requires abstract to be added before abstract contracts and virtual to abstract functions
 */
contract ERC20Basic{
     //Define a series of functions of the interface
     uint public _totalSupply;//Total issued currency
     function totalSupply() public view returns(uint);//View the total currency volume function
     function balanceOf(address who) public view returns(uint);//Check someone's balance
     function transfer(address to, uint value) public;//Transfer transaction function
     event Transfer(address indexed from, address indexed to, uint value);//Define the transfer record event
 }

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
   * @dev inherits from the above interface
 */
contract ERC20 is ERC20Basic{
    //Expanded third-party authorization function
    //Authorize others to use their own money, return the money?
    function allowance(address owner, address spender) public view returns(uint);
    //Transfer coins from whom (from) to whom (to)
    function transferFrom(address from, address to, uint value) public;
    //Authorized use quota function
    function approve(address spender, uint value) public;
    //Record authorization
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
   * @title Basic token basic token
 * @dev Basic version of StandardToken, with no allowances.
   * @dev only implements the basic functions of the token (no third-party authorization)
 * 
 */
 contract BasicToken is Ownable, ERC20Basic{
    //Use safe math functions
    using SafeMath for uint;
    mapping(address => uint) public balances;
    // additional variables for use if transaction fees ever became necessary
    // If it is necessary to charge transaction fees, other variables can be used
    uint public basisPointsRate = 0; //Basic interest rate
    uint public maximunFee = 0; //Maximum interest amount

    /**
         * @dev Fix for the ERC20 short address attack. To prevent short address attack, see the blog ERC20 article for details
         * @dev All transactions involving transfers (contract calls) need to add this restriction
    */
    modifier onlyPayloadSize(uint size){
        //msg.data is the content in the data field (calldata), generally 4 (function name) + 32 (transfer address) + 32 (transfer amount) = 68 bytes
        //Short address attack simply means that the transfer address is followed by 0 but deliberately defaulted, causing the 0 in front of the 32 bytes of the amount to be used as the address, and the automatic filling of 0 at the back causes the transfer amount to surge.
        //The parameter size is the number of bytes remaining except the function name
        //Solution: limit the length of the following bytes
        require(!(msg.data.length < size+4), "Invalid short address");
        _;
    }

    /**
         * @dev transfer token for a specified address transfer to a specified (non-short address) address
         * @param _to The address to transfer to. Transfer address
         * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32){
        //Calculate the interest first: (transfer amount * basic interest rate)/10000 (ps: because floating point will lack precision, so calculate it)
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        //Determine whether the maximum amount is exceeded
        if (fee > maximunFee) fee = maximunFee;
        //Calculate the remaining money
        uint sendAmount = _value.sub(fee);
        //The money to be transferred must be enough. I don’t know why this judgment is not added to the source code?
        //No need to check, because balances[msg.sender].sub(sendAmount) will be checked later, and an exception will be reported if it is insufficient.
        //require(balances[msg.sender] >= _value);
        //There is no need to judge overflow if there are safe math functions
        //Deduction
        balances[msg.sender] = balances[msg.sender].sub(sendAmount);
        //Add money
        balances[_to] = balances[_to].add(sendAmount);
        // where the interest goes ->owner
        if (fee > 0){
            //Because it is inherited from Ownable, you can get owner
            balances[owner] = balances[owner].add(fee);
            //Inherited from the ERCBasic interface, which declares the Transfer record
            //Record where the interest goes
            emit Transfer(msg.sender, owner, fee);
        }
        //Record the destination of the transfer, note that the recorded amount is not the total amount but the amount excluding the transaction fee
        emit Transfer(msg.sender, _to, sendAmount);
    }

    /**
         * @dev Gets the balance of the specified address. Check balance function
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns(uint balance){
        return balances[_owner];
    }

}
/**
   * @title Standard ERC20 token ERC20 standard token
 *
   * @dev Implementation of the basic standard token. According to the basic token standard
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
   * @dev borrowed from firstblood tokens
   * @dev expands the basic functions of the token -> added a third-party authorization function
 */
contract StandardToken is BasicToken, ERC20{
    //Authorized amount mapping: the mapping of the amount authorized by someone to everyone else
    mapping(address => mapping(address => uint)) public allowed;
    //uint maximum
    uint public constant MAX_UINT = 2**256-1;
    /**
         * @dev Transfer tokens from one address to another Authorized transfer: transfer from one account to another
         * @param _from address The address which you want to send tokens from authorized account
         * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(2 * 32){
        //Authorization amount: the amount of money that the authorizer authorizes the current caller to use
        uint _allowance = allowed[_from][msg.sender];
        //There is also no need to check whether the authorized amount is sufficient, the following sub function will detect this situation
        // require(_allowance >= _value);
        //1. Calculate interest first
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximunFee) fee = maximunFee;
        //2. Deduction
        // Why do you want to judge here?
        if (_allowance < MAX_UINT){
            //Note that what is deducted here is the total amount, including the interest will be removed from the authorized amount of the authorized party
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        balances[_from] = balances[_from].sub(_value);
        //3. Add money
        uint sendAmount = _value.sub(fee);
        balances[_to] = balances[_to].add(sendAmount);
        //4. Where the interest goes
        if (fee > 0){
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        //5. Record
        emit Transfer(_from, _to, sendAmount);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         * @dev The amount that the caller authorizes to others to use
         * @param _spender The address which will spend the funds. Grantee
         * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32){
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        //The limitation here is: the authorized amount that has been set cannot be changed unless it is changed to 0.
        //That is to say, the authorized amount for others can only be changed from 0 to value. This time, if you change it again, you can only change it back to 0
        require(!(_value != 0 && allowed[msg.sender][_spender] != 0), "You have only one chance to approve , you can only change it to 0 later");
        //1. Change allowed
        allowed[msg.sender][_spender] = _value;
        //2. Record
        emit Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
         * @param _owner address The address which owns the funds. The address which owns the funds.
         * @param _spender address The address which will spend the funds. See how much money is authorized
    * @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns(uint remaining){
        return allowed[_owner][_spender];
    }
}


/**
   * @title Pausable interrupt
 * @dev Base contract which allows children to implement an emergency stop mechanism.
   * @dev implements emergency stop mechanism
 */
contract Pausable is Ownable{
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
         * @dev restriction: the function can only be executed when the contract is not stopped.
    */
    modifier whenNotPaused(){
        require(!paused, "Must be used without pausing");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
         * @dev function can only be executed under stop conditions
    */
    modifier whenPaused(){
        require(paused, "Must be used under pause");
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
         * @dev can only be stopped by the token manager
    *
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
         * @dev can only be reopened by the token manager
    */
    function unpause() public onlyOwner whenPaused{
        paused = false;
        emit Unpause();
    }
}

/**
   * @dev blacklist
 */

contract BlackList is Ownable, BasicToken{
    //Blacklist mapping
    mapping(address => bool) isBlackListed;
    //event
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);


    //Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether)
    //Allow other contracts to call this blacklist (external) to see if this person is blacklisted
    function getBlackListStatus(address _maker) external view returns(bool){
        return isBlackListed[_maker];
    }

    //Get the Owner of the current token
    function getOwner() external view returns(address){
        return owner;
    }
    //Add blacklist
    function addBlackList(address _evilUser) public onlyOwner{
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    //Remove someone from the blacklist
    function removeBlackList(address _clearUser) public onlyOwner{
        isBlackListed[_clearUser] = false;
        emit RemovedBlackList(_clearUser);
    }

    //Remove money from blacklisted accounts
    function destroyBlackFunds(address _blackListUser) public onlyOwner{
        //1. Check whether it is in the blacklist
        require(isBlackListed[_blackListUser], "You can only clear the money of users in the blacklist");
        //2. Check the money to be cleared
        uint dirtyFunds = balanceOf(_blackListUser);
        //3. Deduction reset
        balances[_blackListUser] = 0;
        //4. Decrease in total token issuance
        _totalSupply = _totalSupply.sub(dirtyFunds);
        //5. Record
        emit DestroyedBlackFunds(_blackListUser, dirtyFunds);
    }
}


//Standard token expansion (in order to adapt to situations or expansions that do not support ERC20)
contract UpgradedStandardToken is StandardToken{
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    // These extension methods are from legacy contracts
    // And the contract caller must be the contract address
    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
}


//Main token
contract TetherToken is Pausable, StandardToken, BlackList{

    string public name;  //Token name
    string public symbol; //Logo
    uint public decimals; //Precision/number of decimal places
    address public upgradedAddress; //The address of the upgrade contract (must be the contract address)
    bool public deprecated; //Deprecated (support ERC20 or not)

    // The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals

    constructor(
        uint _initialSupply,
        string _name,
        string _symbol,
        uint _decimals
    ) public {
        //Total issued coins are given to owner
        _totalSupply = _initialSupply;
        balances[owner] = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        deprecated = false;
    }

    // Called when new token are issued
    event Issue(uint amount);

    // Called when tokens are redeemed
    event Redeem(uint amount);

    // Called when contract is deprecated
    event Deprecate(address newAddress);

    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    //If the ERC20 method is not recommended, it will be converted to an upgraded contract
    function transfer(address _to, uint _value) public whenNotPaused{
        //Exclude blacklist
        require(!isBlackListed[msg.sender], "The account you applied for is on the blacklist and cannot be transferred");
        // Determine whether to support ERC20
        if(deprecated){
            //If not, call the transferByLegacy function of the object instantiated with upgradedAddress
            //I don't know why msg.sender is sent here?
            //I guess the person who called this function (msg.sender) will also be transferred if the adaptation function is upgraded again
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        }else{
            //If you support it, call ERC20 transfer directly
            //There is no return value, I don’t know why return is added
            return super.transfer(_to, _value);
        }
    }

    //Similarly:
    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused{
        require(!isBlackListed[_from], "The account you applied for is on the blacklist and cannot be transferred");
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        }else{
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    //Note that the balance query here can also be used when the token is suspended
    function balanceOf(address who) public view returns(uint){
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        }else{
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint _value) public whenNotPaused{
        //There is no need to check here, if it is in the blacklist, then no matter how many authorizations are used, it will be detected during transferFrom
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        }else{
            return super.approve(_spender, _value);
        }

    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public view returns(uint){
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).allowance(_owner, _spender);
        }else{
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    //Oppose the current contract and use the new contract instead. upgradedAddress new contract address
    function deprecate(address _upgradedAddress) public onlyOwner{
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        //recording
        emit Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    //Against the current contract, if you want to change to a new contract, you need to know the current issuance in advance
    function totalSupply() public view returns(uint){
        if(deprecated){
            return UpgradedStandardToken(upgradedAddress).totalSupply();
        }else{
            return _totalSupply;
        }
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint _amount) public onlyOwner{
        //Increase the number of owners
        balances[owner] = balances[owner].add(_amount);
        //Increase the total amount of tokens issued
        _totalSupply = _totalSupply.add(_amount);
        //recording
        emit Issue(_amount);
    }

    // Adjust interest rate and maximum interest limit
    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner{
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        //Ensure transparency by hard-coding restrictions, beyond this limit, no more fees can be added
        require(newBasisPoints < 20, "The new BasisPoints cannot exceed 20"); //0.002
        require(newMaxFee < 50, "The new MaxFee cannot exceed 50"); //5*10**(decimals+1)
        basisPointsRate = newBasisPoints;
        maximunFee = newMaxFee.mul(10**decimals);
        //recording
        emit Params(newBasisPoints, newMaxFee);
    }
}