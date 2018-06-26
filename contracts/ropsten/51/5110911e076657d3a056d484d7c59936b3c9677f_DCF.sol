pragma solidity ^0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract.
    */
    constructor(address _owner) public {
        owner = _owner == address(0) ? msg.sender : _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
    * @dev confirm ownership by a new owner
    */
    function confirmOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}


/**
 * @title IERC20Token - ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value)  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function allowance(address _owner, address _spender)  public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    /**
    * @dev constructor
    */
    constructor() public {
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



/**
 * @title ERC20Token - ERC20 base implementation
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Token is IERC20Token, SafeMath {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title ITokenEventListener
 * @dev Interface which should be implemented by token listener
 */
interface ITokenEventListener {
    /**
     * @dev Function is called after token transfer/transferFrom
     * @param _from Sender address
     * @param _to Receiver address
     * @param _value Amount of tokens
     */
    function onTokenTransfer(address _from, address _to, uint256 _value) external;
}

/**
 * @title ManagedToken
 * @dev ERC20 compatible token with issue and destroy facilities
 * @dev All transfers can be monitored by token event listener
 */
contract ManagedToken is ERC20Token, Ownable {
    bool public allowTransfers = false;                                         //Default not transfer
    bool public issuanceFinished = false;                                       //Finished issuance

    ITokenEventListener public eventListener;                                   //Listen events

    event AllowTransfersChanged(bool _newState);                                //Event:
    event Issue(address indexed _to, uint256 _value);                           //Event: Issue
    event Destroy(address indexed _from, uint256 _value);                       //Event:
    event IssuanceFinished();                                                   //Event: Finished issuance

    //Modifier: Allow all transfer if not any condition
    modifier transfersAllowed() {
        require(allowTransfers);
        _;
    }

    //Modifier: Allow continue to issue
    modifier canIssue() {
        require(!issuanceFinished);
        _;
    }

    /**
     * @dev ManagedToken constructor
     * @param _listener Token listener(address can be 0x0)
     * @param _owner Owner of contract(address can be 0x0)
     */
    constructor(address _listener, address _owner) public Ownable(_owner) {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        }
    }

    /**
     * @dev Enable/disable token transfers. Can be called only by owners
     * @param _allowTransfers True - allow False - disable
     */
    function setAllowTransfers(bool _allowTransfers) external onlyOwner {
        allowTransfers = _allowTransfers;

        //Call event
        emit AllowTransfersChanged(_allowTransfers);
    }

    /**
     * @dev Set/remove token event listener
     * @param _listener Listener address (Contract must implement ITokenEventListener interface)
     */
    function setListener(address _listener) public onlyOwner {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        } else {
            delete eventListener;
        }
    }

    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transfer(_to, _value);
        /* if(hasListener() && success) {
            eventListener.onTokenTransfer(msg.sender, _to, _value);
        } */
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transferFrom(_from, _to, _value);

        //If has Listenser and transfer success
        /* if(hasListener() && success) {
            //Call event listener
            eventListener.onTokenTransfer(_from, _to, _value);
        } */
        return success;
    }

    function hasListener() internal view returns(bool) {
        if(eventListener == address(0)) {
            return false;
        }
        return true;
    }

    /**
     * @dev Issue tokens to specified wallet
     * @param _to Wallet address
     * @param _value Amount of tokens
     */
    function issue(address _to, uint256 _value) external onlyOwner canIssue {
        require(totalSupply >= _value);
        totalSupply = safeSub(totalSupply, _value);
        balances[_to] = safeAdd(balances[_to], _value);
        //Call event
        emit Issue(_to, _value);
        emit Transfer(address(0), _to, _value);
    }

    /**
     * @dev Destroy tokens on specified address (Called byallowance owner or token holder)
     * @dev Fund contract address must be in the list of owners to burn token during refund
     * @param _from Wallet address
     * @param _value Amount of tokens to destroy
     */
    function destroy(address _from, uint256 _value) external onlyOwner {
        require(balances[_from] >= _value);

        totalSupply = safeAdd(totalSupply, _value);
        balances[_from] = safeSub(balances[_from], _value);

        emit Transfer(_from, address(0), _value);
        //Call event
        emit Destroy(_from, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From OpenZeppelin StandardToken.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From OpenZeppelin StandardToken.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Finish token issuance
     * @return True if success
     */
    function finishIssuance() public onlyOwner returns (bool) {
        issuanceFinished = true;
        //Call event
        emit IssuanceFinished();
        return true;
    }
}


/**
 * DCF Token Contract
 * @title DCF
 */
contract DCF is ManagedToken {
    uint256 public minDeposit;                                                  //Min of value to deposit
    uint256 public coinPrice;                                                   //Parse ether to token: 1 ether = (coinPrice/(1 ether)) Token
    bool public isPause = false;                                                //Pause issue token when deposit

    event WithdrawMoney(address _address, uint256 _value);

    /**
     * @dev DCF constructor
     * @param _coinPrice Price of coin(price should be greater 0)
     */
    constructor(uint256 _coinPrice) public ManagedToken(msg.sender, msg.sender) {
        name = &quot;DCF&quot;;
        symbol = &quot;DCF&quot;;
        decimals = 18;
        totalSupply = 500000000 ether;                                          //The maximum number of tokens is unchanged and totals will decrease after issue
        minDeposit = 0.01 ether;                                                //Default MIN of deposit is 0.01 ether.
        coinPrice = _coinPrice;                                                 //Price of coin can be changed.
    }

    /**
     * Throws if called when isPause = true
     */
    modifier canDeposit() {
        require(!isPause, &quot;Deposit to issue token is paused.&quot;);
        require(msg.value >= minDeposit, &quot;Deposit is required greater value of minDeposit&quot;);
        _;
    }

    /**
    * Deposit to buy token
    */
    function() payable public  {
        Deposit();
    }

    /**
     * Function Deposit private
     */
    function Deposit() private canDeposit {
        //Calculate number of token to issue
        uint256 value = safeDiv(safeMul(msg.value, 1 ether), coinPrice);
        //Check to have enough token to issue
        require(totalSupply >= value, &quot;Not enough token to issue.&quot;);
        //Total of token can continue to issue
        totalSupply = safeSub(totalSupply, value);

        //Add token to Sender
        if(balances[msg.sender] == 0){
            balances[msg.sender] = value;
        }else{
            balances[msg.sender] = safeAdd(balances[msg.sender], value);
        }

        //Event transfer token to Sender
        emit Transfer(address(0), msg.sender, value);
    }

    /**
      Begin: Set params by owner
    */

    function paused(bool pause) external onlyOwner {
        isPause = pause;
    }

    function setPriceToken(uint256 _coinPrice) external onlyOwner {
        coinPrice = _coinPrice;
    }

    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        minDeposit = _minDeposit;
    }

    /**
      End: Set params by owner
    */

    /**
     * @dev Transfer money from contract wallet to an address _address
     * Function call only by owner
     * @param _address Wallet address (address is not 0x00)
     * @param _value Amount of money will be withdrawed
     */
    function withdraw(address _address, uint256 _value) external onlyOwner {
        require(_address != address(0));
        require(_value <= address(this).balance);
        _address.transfer(_value);
        emit WithdrawMoney(_address, _value);
    }
}