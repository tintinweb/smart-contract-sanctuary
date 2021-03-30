/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.4.16;

// copyright [email protected]

contract SafeMath {

    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

    function safeAdd(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) pure internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = true;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

interface TokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract TokenERC20 {
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}

contract PaymentInterface {
    function createCastle(address _trainer, uint _tokens, string _name, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) public returns(uint);
    function catchMonster(address _trainer, uint _tokens, uint32 _classId, string _name) public returns(uint);
    function payService(address _trainer, uint _tokens, uint32 _type, string _text, uint64 _param1, uint64 _param2, uint64 _param3, uint64 _param4, uint64 _param5, uint64 _param6) public returns(uint);
}

contract EtheremonToken is BasicAccessControl, TokenERC20 {
    // metadata
    string public constant name = "EtheremonToken";
    string public constant symbol = "EMONT";
    uint256 public constant decimals = 8;
    string public version = "1.0";
    
    // deposit address
    address public inGameRewardAddress;
    address public userGrowPoolAddress;
    address public developerAddress;
    
    // Etheremon payment
    address public paymentContract;
    
    // for future feature
    uint256 public sellPrice;
    uint256 public buyPrice;
    bool public trading = false;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    
    modifier isTrading {
        require(trading == true || msg.sender == owner);
        _;
    }
    
    modifier requirePaymentContract {
        require(paymentContract != address(0));
        _;        
    }
    
    function () payable public {}

    // constructor    
    function EtheremonToken(address _inGameRewardAddress, address _userGrowPoolAddress, address _developerAddress, address _paymentContract) public {
        require(_inGameRewardAddress != address(0));
        require(_userGrowPoolAddress != address(0));
        require(_developerAddress != address(0));
        inGameRewardAddress = _inGameRewardAddress;
        userGrowPoolAddress = _userGrowPoolAddress;
        developerAddress = _developerAddress;

        balanceOf[inGameRewardAddress] = 14000000 * 10**uint(decimals);
        balanceOf[userGrowPoolAddress] = 5000000 * 10**uint(decimals);
        balanceOf[developerAddress] = 1000000 * 10**uint(decimals);
        totalSupply = balanceOf[inGameRewardAddress] + balanceOf[userGrowPoolAddress] + balanceOf[developerAddress];
        paymentContract = _paymentContract;
    }
    
    // moderators
    function setAddress(address _inGameRewardAddress, address _userGrowPoolAddress, address _developerAddress, address _paymentContract) onlyModerators external {
        inGameRewardAddress = _inGameRewardAddress;
        userGrowPoolAddress = _userGrowPoolAddress;
        developerAddress = _developerAddress;
        paymentContract = _paymentContract;
    }
    
    // public
    function withdrawEther(address _sendTo, uint _amount) onlyModerators external {
        if (_amount > this.balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }
    
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        FrozenFunds(_target, _freeze);
    }
    
    function buy() payable isTrading public {
        uint amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) isTrading public {
        require(this.balance >= amount * sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * sellPrice);
    }
    
    // Etheremon 
    function createCastle(uint _tokens, string _name, uint64 _a1, uint64 _a2, uint64 _a3, uint64 _s1, uint64 _s2, uint64 _s3) isActive requirePaymentContract external {
        if (_tokens > balanceOf[msg.sender])
            revert();
        PaymentInterface payment = PaymentInterface(paymentContract);
        uint deductedTokens = payment.createCastle(msg.sender, _tokens, _name, _a1, _a2, _a3, _s1, _s2, _s3);
        if (deductedTokens == 0 || deductedTokens > _tokens)
            revert();
        _transfer(msg.sender, inGameRewardAddress, deductedTokens);
    }
    
    function catchMonster(uint _tokens, uint32 _classId, string _name) isActive requirePaymentContract external {
        if (_tokens > balanceOf[msg.sender])
            revert();
        PaymentInterface payment = PaymentInterface(paymentContract);
        uint deductedTokens = payment.catchMonster(msg.sender, _tokens, _classId, _name);
        if (deductedTokens == 0 || deductedTokens > _tokens)
            revert();
        _transfer(msg.sender, inGameRewardAddress, deductedTokens);
    }
    
    function payService(uint _tokens, uint32 _type, string _text, uint64 _param1, uint64 _param2, uint64 _param3, uint64 _param4, uint64 _param5, uint64 _param6) isActive requirePaymentContract external {
        if (_tokens > balanceOf[msg.sender])
            revert();
        PaymentInterface payment = PaymentInterface(paymentContract);
        uint deductedTokens = payment.payService(msg.sender, _tokens, _type, _text, _param1, _param2, _param3, _param4, _param5, _param6);
        if (deductedTokens == 0 || deductedTokens > _tokens)
            revert();
        _transfer(msg.sender, inGameRewardAddress, deductedTokens);
    }
}