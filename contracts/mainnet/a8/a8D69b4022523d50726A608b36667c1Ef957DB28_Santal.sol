pragma solidity ^0.4.8;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 supply);
    function balance() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Santal is ERC20Interface {
    string public constant symbol = "TXQ";
    string public constant name = "santal";
    uint8  public constant decimals = 18;

    uint256 public _airdropTotal = 0;
    uint256 public _airdropLimit = 10 * 10000 * 1000000000000000000;
    uint256 public _airdropAmount = 10 * 1000000000000000000; 
    uint256 public totalSupply = 50000 * 10000 * 1000000000000000000;
    uint safeGas = 2300;
    
    uint256 public unitsOneEthCanBuy = 8000 * 1000000000000000000;
    uint256 public canBuyLimit = 1000 * 10000 * 1000000000000000000;
    uint256 public hasBuyTotal = 0;
    uint256 public totalEthInWei;
    uint256 constant public unitEthWei = 1000000000000000000;
    address public owner;
    bool public isBuyStopped;
    bool public isAirdropStopped;

    mapping(address => uint256) balances;
    mapping(address => bool) initialized;
    mapping(address => bool) hasBuyed;


    mapping(address => mapping (address => uint256)) allowed;
    
    event LOG_SuccessfulSend(address addr, uint amount);
    event LOG_FailedSend(address receiver, uint amount);
    event LOG_ZeroSend();
    
    event LOG_BuyStopped();
    event LOG_BuyResumed();
    
    event LOG_AirdropStopped();
    event LOG_AirdropResumed();
    
    event LOG_OwnerAddressChanged(address oldAddr, address newOwnerAddress);
    
    modifier onlyOwner {
        if (owner != msg.sender) throw;
        _;
    }

    function Santal() {
        owner = msg.sender;
        initialized[msg.sender] = true;
        balances[msg.sender] = totalSupply - _airdropLimit - canBuyLimit;
    }
    
    function() payable{
        
        if (isBuyStopped) throw;
        
        if (!hasBuyed[msg.sender]) {
            hasBuyed[msg.sender] = true;
        }

        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * (unitsOneEthCanBuy / unitEthWei);
        
        hasBuyTotal += amount;
         
        if(amount > canBuyLimit || hasBuyTotal > canBuyLimit) throw;
        
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(owner, msg.sender, amount);

        safeSend(owner, msg.value);
    }
    
    function safeSend(address addr, uint value)
        private {

        if (value == 0) {
            LOG_ZeroSend();
            return;
        }

        if (!(addr.call.gas(safeGas).value(value)())) {
            LOG_FailedSend(addr, value);
        }

        LOG_SuccessfulSend(addr,value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    function totalSupply() constant returns (uint256 supply) {
        return totalSupply;
    }

    function balance() constant returns (uint256) {
        return getBalance(msg.sender);
    }

    function balanceOf(address _address) constant returns (uint256) {
        return getBalance(_address);
    }

    function transfer(address _to, uint256 _amount) returns (bool success) {
        initialize(msg.sender);

        if (balances[msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(msg.sender, _to, _amount);

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        initialize(_from);

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[_from] -= _amount;
                allowed[_from][msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(_from, _to, _amount);

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function initialize(address _address) internal returns (bool success) {
        if (!isAirdropStopped && _airdropTotal < _airdropLimit && !initialized[_address]) {
            initialized[_address] = true;
            balances[_address] = _airdropAmount;
            _airdropTotal += _airdropAmount;
        }
        return true;
    }

    function getBalance(address _address) internal returns (uint256) {
        if (_airdropTotal < _airdropLimit && !initialized[_address] && !hasBuyed[_address]) {
            return balances[_address] + _airdropAmount;
        }
        else {
            return balances[_address];
        }
    }
    
    function stopBuy()
        onlyOwner {

        isBuyStopped = true;
        LOG_BuyStopped();
    }

    function resumeBuy()
        onlyOwner {

        isBuyStopped = false;
        LOG_BuyResumed();
    }
    
    function stopAirdrop()
        onlyOwner {

        isAirdropStopped = true;
        LOG_AirdropStopped();
    }

    function resumeAirdrop()
        onlyOwner {

        isAirdropStopped = false;
        LOG_AirdropResumed();
    }
    
        function changeOwnerAddress(address newOwner)
        onlyOwner {

        if (newOwner == address(0x0)) throw;
        owner = newOwner;
        LOG_OwnerAddressChanged(owner, newOwner);
    }
}