pragma solidity ^0.4.19;


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
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
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
    function buyBlueStarEgg(address _master, uint _tokens, uint16 _amount) public returns(uint);
}

contract DragonTreasureToken is BasicAccessControl, TokenERC20 {
    // metadata
    string public constant name = "DragonTreasureToken";
    string public constant symbol = "DTT";
    uint256 public constant decimals = 8;
    string public version = "1.0";

    // deposit address
    address public inGameRewardAddress;
    address public userGrowPoolAddress;
    address public developerAddress;
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
    function DragonTreasureToken(address _inGameRewardAddress, address _userGrowPoolAddress, address _developerAddress) public {
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

    function buyBlueStarEgg(uint _tokens, uint16 _amount) isActive requirePaymentContract external {
        if (_tokens > balanceOf[msg.sender])
            revert();
        PaymentInterface payment = PaymentInterface(paymentContract);
        uint deductedTokens = payment.buyBlueStarEgg(msg.sender, _tokens, _amount);
        if (deductedTokens == 0 || deductedTokens > _tokens)
            revert();
        _transfer(msg.sender, inGameRewardAddress, deductedTokens);
    }
}