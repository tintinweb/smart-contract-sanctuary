pragma solidity ^0.4.24;

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


contract ERC20 {
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 public totalSupply;
    function balanceOf(address who) view external returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract CoolPandaToken is ERC20, Lockable  {
    using SafeMath for uint256;

    uint256 public decimals = 18;
    address public fundWallet = 0x071961b88F848D09C3d988E8814F38cbAE755C44;
    uint256 public tokenPrice;

    function balanceOf(address _addr) external view returns (uint256) {
        return balances[_addr];
    }

    function allowance(address _from, address _spender) external view returns (uint256) {
        return allowed[_from][_spender];
    }

    function transfer(address _to, uint256 _value)
    isTokenTransfer
    public
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

    function setFundWallet(address _newAddr) external onlyOwner {
        require(_newAddr != address(0));
        fundWallet = _newAddr;
    }

    function transferEth() onlyOwner external {
        fundWallet.transfer(address(this).balance);
    }

    function setTokenPrice(uint256 _newBuyPrice) external onlyOwner {
        tokenPrice = _newBuyPrice;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract PaoToken is CoolPandaToken {
    using SafeMath for uint256;

    string public name = "PAO Token";
    string public symbol = "PAO";
    uint fundRatio = 6;
    uint256 public minBuyETH = 50;

    JPYC public jpyc;                       //JPYC Address
    uint256 public jypcBonus = 40000;       

    event JypcBonus(uint256 paoAmount, uint256 jpycAmount);

    // constructor
    constructor() public {
        totalSupply = 10000000000 * 10 ** uint256(decimals);
        tokenPrice = 50000;
        balances[fundWallet] = totalSupply * fundRatio / 10;
        balances[address(this)] = totalSupply.sub(balances[fundWallet]);
    }

    // @notice Buy tokens from contract by sending ether
    function () payable public {
        if(fundWallet != msg.sender){
            require (msg.value >= (minBuyETH * 10 ** uint256(decimals)));   // Check if minimum amount 
            uint256 amount = msg.value.mul(tokenPrice);                     // calculates the amount
            _buyToken(msg.sender, amount);                                  // makes the transfers
            fundWallet.transfer(msg.value);                              // send ether to the fundWallet
        }
    }

    function _buyToken(address _to, uint256 _value) isTokenTransfer internal {
        address _from = address(this);
        require (_to != 0x0);                                                   // Prevent transfer to 0x0 address.
        require (balances[_from] >= _value);                                    // Check if the sender has enough
        require (balances[_to].add(_value) >= balances[_to]);                   // Check for overflows
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        //give bonus consume token
        uint256 _jpycAmount = _getJYPCBonus();
        jpyc.giveBonus(_to, _jpycAmount);

        emit JypcBonus(_value,_jpycAmount);
    }

    function _getJYPCBonus() internal view returns (uint256 amount){
        return msg.value.mul(jypcBonus); 
    }  

    function setMinBuyEth(uint256 _amount) external onlyOwner{
        minBuyETH = _amount;
    }

    function setJypcBonus(uint256 _amount) external onlyOwner{
        jypcBonus = _amount;
    }

    function transferToken() onlyOwner external {
        address _from = address(this);
        uint256 _total = balances[_from];
        balances[_from] = balances[_from].sub(_total);
        balances[fundWallet] = balances[fundWallet].add(_total);
    }

    function setJpycContactAddress(address _tokenAddress) external onlyOwner {
        jpyc = JPYC(_tokenAddress);
    }
}

contract JPYC is CoolPandaToken {
    using SafeMath for uint256;

    string public name = "Japan Yen Coin";
    uint256 _initialSupply = 10000000000 * 10 ** uint256(decimals);
    string public symbol = "JPYC";
    address public paoContactAddress;

    event Issue(uint256 amount);

    // constructor
    constructor() public {
        tokenPrice = 47000;           //JPY to ETH (rough number)
        totalSupply = _initialSupply;
        balances[fundWallet] = _initialSupply;
    }

    function () payable public {
        uint amount = msg.value.mul(tokenPrice);             // calculates the amount
        _giveToken(msg.sender, amount);                          // makes the transfers
        fundWallet.transfer(msg.value);                         // send ether to the public collection wallet
    }

    function _giveToken(address _to, uint256 _value) isTokenTransfer internal {
        require (_to != 0x0);                                       // Prevent transfer to 0x0 address.
        require(totalSupply.add(_value) >= totalSupply);
        require (balances[_to].add(_value) >= balances[_to]);       // Check for overflows

        totalSupply = totalSupply.add(_value);
        balances[_to] = balances[_to].add(_value);                  // Add the same to the recipient
        emit Transfer(address(this), _to, _value);
    }

    function issue(uint256 amount) external onlyOwner {
        _giveToken(fundWallet, amount);

        emit Issue(amount);
    }

    function setPaoContactAddress(address _newAddr) external onlyOwner {
        require(_newAddr != address(0));
        paoContactAddress = _newAddr;
    }

    function giveBonus(address _to, uint256 _value)
    isTokenTransfer
    external
    returns (bool success) {
        require(_to != address(0));
        if(msg.sender == paoContactAddress){
            _giveToken(_to,_value);
            return true;
        }
        return false;
    }
}