pragma solidity ^0.4.18;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

/**
* @dev Multiplies two numbers, throws on overflow.
*/
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

    /**
    * @title Ownable
    * @dev The Ownable contract has an owner address, and provides basic authorization control
    * functions, this simplifies the implementation of "user permissions".
    */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
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
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Lockable is Ownable {
    uint256 public creationTime;
    bool public tokenTransferLocker;
    mapping(address => bool) lockaddress;

    event Locked(address lockaddress);
    event Unlocked(address lockaddress);
    event TokenTransferLocker(bool _setto);

    // if Token transfer
    modifier isTokenTransfer {
        // only contract holder can send token during locked period
        if(msg.sender != owner) {
            // if token transfer is not allow
            require(!tokenTransferLocker);
            if(lockaddress[msg.sender]){
                revert();
            }
        }
        _;
    }

    // This modifier check whether the contract should be in a locked
    // or unlocked state, then acts and updates accordingly if
    // necessary
    modifier checkLock {
        if (lockaddress[msg.sender]) {
            revert();
        }
        _;
    }

    constructor() public {
        creationTime = now;
        owner = msg.sender;
    }


    function isTokenTransferLocked()
    external
    view
    returns (bool)
    {
        return tokenTransferLocker;
    }

    function enableTokenTransfer()
    external
    onlyOwner
    {
        delete tokenTransferLocker;
        emit TokenTransferLocker(false);
    }

    function disableTokenTransfer()
    external
    onlyOwner
    {
        tokenTransferLocker = true;
        emit TokenTransferLocker(true);
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract PaoToken is Lockable {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    string public name = "PAO Token";
    uint8 public decimals = 0;
    uint256 totalSupply_ = 10000000000 * 10 ** uint256(decimals);
    uint256 public tokenBuyPrice = 5000;
    string public symbol = "PAO";
    address public publicSaleWallet = 0x5A0DA1fD7f6b084A81F07fb9d641D295b2E7e669;
    address public reservedWallet = 0x8a7fe9893c63f718Ad066a1dd48458eC47F2FbaD;
    uint publicSaleRatio = 3;
    uint reservedRatio = 7;

    address public consumeAddress;
    ConsumeToken consumeToken;  //consume token

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // constructor
    constructor() public {
        balances[reservedWallet] = totalSupply_ * reservedRatio / 10;
        balances[publicSaleWallet] = totalSupply_ * publicSaleRatio / 10;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return balances[_addr];
    }

    function allowance(address _from, address _spender) external view returns (uint256) {
        return allowed[_from][_spender];
    }

    function transfer(address _to, uint256 _value)
    isTokenTransfer
    external
    returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)
    isTokenTransfer
    external
    returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
    isTokenTransfer
    public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        isTokenTransfer
        external
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    //internal transfer, only can be called by this contract
    function _buyToken(address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address.
        require (balances[publicSaleWallet] >= _value);               // Check if the sender has enough
        require (balances[_to] + _value >= balances[_to]); // Check for overflows
        balances[publicSaleWallet] -= _value;                         // Subtract from the sender
        balances[_to] += _value;                           // Add the same to the recipient

        //give bonus consume token
        consumeToken.transfer(_to, 1000);


        emit Transfer(publicSaleWallet, _to, _value);
    }

    // @notice Buy tokens from contract by sending ether
    function () payable public {
        uint amount = msg.value.mul(tokenBuyPrice);             // calculates the amount
        _buyToken(msg.sender, amount);                          // makes the transfers
        publicSaleWallet.transfer(msg.value);                   // send ether to the public collection wallet
    }

    function setPrices(uint256 newBuyPrice) onlyOwner public {
        tokenBuyPrice = newBuyPrice;
    }

    function transferSaleWallet(address newAddr) external onlyOwner {
        require(newAddr != address(0));
        publicSaleWallet = newAddr;
    }

    function transferEth() onlyOwner external {
        publicSaleWallet.transfer(address(this).balance);
    }

    function setConsumeTokenAddress(address _tokenAddress) public {
        consumeAddress = _tokenAddress;
        consumeToken = ConsumeToken(_tokenAddress);
    }

}

contract ConsumeToken is Lockable {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    string public name = "Consume Token";
    uint8 public decimals = 2;
    uint256 totalSupply_ = 10000000000 * 10 ** uint256(decimals);
    uint256 public tokenBuyPrice = 54106;           //JPY to ETH
    string public symbol = "Con";
    address public fundWallet = 0x5A0DA1fD7f6b084A81F07fb9d641D295b2E7e669;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // constructor
    constructor() public {
        balances[fundWallet] = totalSupply_;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return balances[_addr];
    }

    function allowance(address _from, address _spender) external view returns (uint256) {
        return allowed[_from][_spender];
    }

    function transfer(address _to, uint256 _value)
    isTokenTransfer
    external
    returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)
    isTokenTransfer
    external
    returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
    isTokenTransfer
    public
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //internal transfer, only can be called by this contract
    function _buyToken(address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address.
        require (balances[fundWallet] >= _value);               // Check if the sender has enough
        require (balances[_to] + _value >= balances[_to]); // Check for overflows
        balances[fundWallet] -= _value;                         // Subtract from the sender
        balances[_to] += _value;                           // Add the same to the recipient
        emit Transfer(fundWallet, _to, _value);
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        isTokenTransfer
        external
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    // @notice Buy tokens from contract by sending ether
    function () payable public {
        uint amount = msg.value.mul(tokenBuyPrice);             // calculates the amount
        _buyToken(msg.sender, amount);                          // makes the transfers
        fundWallet.transfer(msg.value);                   // send ether to the public collection wallet
    }

    function setPrices(uint256 newBuyPrice) onlyOwner public {
        tokenBuyPrice = newBuyPrice;
    }

    function transferSaleWallet(address newAddr) external onlyOwner {
        require(newAddr != address(0));
        fundWallet = newAddr;
    }

    function transferEth() onlyOwner external {
        fundWallet.transfer(address(this).balance);
    }
}