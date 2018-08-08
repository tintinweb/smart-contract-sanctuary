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


contract ERC20 {
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 public _totalSupply;
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) view external returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract PaoToken is ERC20,Lockable {
    using SafeMath for uint256;

    string public name = "PAO Token";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 10000000000 * 10 ** uint256(decimals);
    uint256 public tokenBuyPrice = 5000;
    string public symbol = "PAO";
    address public publicSaleWallet = 0x5A0DA1fD7f6b084A81F07fb9d641D295b2E7e669;
    address public fundWallet = 0x8a7fe9893c63f718Ad066a1dd48458eC47F2FbaD;
    uint publicSaleRatio = 3;
    uint fundRatio = 7;

    mapping (uint256 => uint256) internal _levelPAO;
    mapping (uint256 => uint256) internal _levelBonusJPYC;

    JPYC public jpyc;       //JPYC Address

    // constructor
    constructor() public {
        balances[fundWallet] = _totalSupply * fundRatio / 10;
        balances[publicSaleWallet] = _totalSupply * publicSaleRatio / 10;

        _levelBonusJPYC[1] = 11000;
        _levelBonusJPYC[2] = 52000;
        _levelBonusJPYC[3] = 230000;
        _levelBonusJPYC[4] = 1400000;
        _levelPAO[1] = 10000;
        _levelPAO[2] = 50000;
        _levelPAO[3] = 200000;
        _levelPAO[4] = 1000000;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
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
        uint256 amount = msg.value.mul(tokenBuyPrice);          // calculates the amount
        _buyToken(msg.sender, amount);                          // makes the transfers
        publicSaleWallet.transfer(msg.value);                   // send ether to the public collection wallet
    }

    function _buyToken(address _to, uint256 _value) internal {
        require (_to != 0x0);                                                   // Prevent transfer to 0x0 address.
        require (balances[publicSaleWallet] >= _value);                         // Check if the sender has enough
        require (balances[_to].add(_value) >= balances[_to]);                   // Check for overflows
        balances[publicSaleWallet] = balances[publicSaleWallet].sub(_value);    // Subtract from the sender
        balances[_to] = balances[_to].add(_value);                              // Add the same to the recipient

        //give bonus consume token
        uint256 _jpycAmount = getJYPCBonus(_value / (10 ** uint256(decimals)));
        jpyc.giveBonus(_to, _jpycAmount);

        emit Transfer(publicSaleWallet, _to, _value);
    }

    function setBuyPrices(uint256 _newBuyPrice) external onlyOwner{
        tokenBuyPrice = _newBuyPrice;
    }

    function getJYPCBonus(uint256 _paoAmount) internal view returns (uint256 amount){
        if(_paoAmount >= _levelPAO[1] && _paoAmount < _levelPAO[2]){
            return _levelBonusJPYC[1];
        }else if(_paoAmount >= _levelPAO[2] && _paoAmount < _levelPAO[3]){
            return _levelBonusJPYC[2];
        }else if(_paoAmount >= _levelPAO[3] && _paoAmount < _levelPAO[4]){
            return _levelBonusJPYC[3];
        }else if(_paoAmount >= _levelPAO[4]){
            return _levelBonusJPYC[4];
        }else{
            return uint256(0);
        }
    }  

    function setLevelPAO(uint256 _lv1,uint256 _lv2,uint256 _lv3,uint256 _lv4) external onlyOwner{
        _levelPAO[1] = _lv1;
        _levelPAO[2] = _lv2;
        _levelPAO[3] = _lv3;
        _levelPAO[4] = _lv4;
    }

    function setLevelBonusJPYC(uint256 _lv1,uint256 _lv2,uint256 _lv3,uint256 _lv4) external onlyOwner{
        _levelBonusJPYC[1] = _lv1;
        _levelBonusJPYC[2] = _lv2;
        _levelBonusJPYC[3] = _lv3;
        _levelBonusJPYC[4] = _lv4;
    }

    function transferSaleWallet(address _newAddr) external onlyOwner {
        require(_newAddr != address(0));
        publicSaleWallet = _newAddr;
    }

    function transferEth() onlyOwner external {
        publicSaleWallet.transfer(address(this).balance);
    }

    function setJPYC(address _tokenAddress) external onlyOwner {
        jpyc = JPYC(_tokenAddress);
    }

}

contract JPYC is ERC20,Lockable {
    using SafeMath for uint256;

    string public name = "Japan Token Yen Coin";
    uint8 public decimals = 18;
    uint256 _initialSupply = 100000000000 * 10 ** uint256(decimals);
    uint256 public _totalSupply;
    uint256 public tokenBuyPrice = 49245;           //JPY to ETH
    string public symbol = "JPYC";
    address public fundWallet = 0x5A0DA1fD7f6b084A81F07fb9d641D295b2E7e669;
    address public paoContactAddress;

    event Issue(uint256 amount);

    // constructor
    constructor() public {
        _totalSupply = _initialSupply;
        balances[fundWallet] = _initialSupply;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
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

    function _giveToken(address _to, uint256 _value) internal {
        require (_to != 0x0);                                       // Prevent transfer to 0x0 address.
        require (balances[_to].add(_value) >= balances[_to]);       // Check for overflows

        _totalSupply = _totalSupply.add(_value);
        balances[_to] = balances[_to].add(_value);                  // Add the same to the recipient
        emit Transfer(address(this), _to, _value);
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

    function () payable public {
        uint amount = msg.value.mul(tokenBuyPrice);             // calculates the amount
        _giveToken(msg.sender, amount);                          // makes the transfers
        fundWallet.transfer(msg.value);                         // send ether to the public collection wallet
    }

    function issue(uint256 amount) external onlyOwner {
        require(_totalSupply.add(amount) >= _totalSupply);
        require(balances[fundWallet].add(amount) >= balances[fundWallet]);

        _giveToken(fundWallet,amount);
        balances[fundWallet].add(amount);

        emit Issue(amount);
    }

    function setPrices(uint256 _newBuyPrice) external onlyOwner {
        tokenBuyPrice = _newBuyPrice;
    }

    function transferFundWallet(address _newAddr) external onlyOwner {
        require(_newAddr != address(0));
        fundWallet = _newAddr;
    }

    function transferEth() onlyOwner external {
        fundWallet.transfer(address(this).balance);
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