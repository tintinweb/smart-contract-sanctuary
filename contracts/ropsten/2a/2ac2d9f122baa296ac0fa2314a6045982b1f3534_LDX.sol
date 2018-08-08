pragma solidity 0.4.24;

// Created for conduction of leadrex ICO - https://leadrex.io/
// Copying in whole or in part is prohibited.
// Authors: https://loftchain.io/

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes _extraData
    ) external;
}

contract LDX is owned {
    using SafeMath for uint256;

    string public name = "LeadRex";
    string public symbol = "LDX";
    uint8 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    uint256 public totalSupply = 135900000 * DEC;

    enum State { Active, Refunding, Closed }
    State public state;

    struct Round {
        uint256 _softCap;
        uint256 _hardCap;
        address _wallet;
        uint256 _tokensForRound;
        uint256 _rate;
        uint256 _minValue;
        uint256 _bonus1;
        uint256 _bonus4;
        uint256 _bonus8;
        uint256 _bonus15;
        uint256 _number;
    }

    struct Deposited {
        mapping(address => uint256) _deposited;
    }

    mapping(uint => Round) public roundInfo;
    mapping(uint => Deposited) allDeposited;

    Round public currentRound;

    constructor() public {
        roundInfo[0] = Round(
            0,
            770 * 1 ether,
            0x950D69e56F4dFE84D0f590E0f9F1BdC6d60A46A9,
            18600000 * DEC,
            16200,
            0.1 ether,
            15,
            20,
            25,
            30,
            0
        );
        roundInfo[1] = Round(
            0,
            1230 * 1 ether,
            0x792Cf510b2082c3287C80ba3bb1616D13d2525E3,
            21000000 * DEC,
            13000,
            0.1 ether,
            10,
            15,
            20,
            25,
            1
        );
        roundInfo[2] = Round(
            0,
            1850 * 1 ether,
            0x2382Caf2cc1122b1f13EB10155c5C7c69b88975f,
            19000000 * DEC,
            8200,
            0.05 ether,
            5,
            10,
            15,
            20,
            2
        );
        roundInfo[3] = Round(
            0,
            4620 * 1 ether,
            0x57B1fDfE53756e71b1388EcE6cB7C045185BC71C,
            25000000 * DEC,
            4333,
            0.05 ether,
            5,
            10,
            15,
            20,
            3
        );
        roundInfo[4] = Round(
            0,
            10700 * 1 ether,
            0xA9764d8eb302d6a3D363104B94C657849273D5CE,
            26000000 * DEC,
            2000,
            0.05 ether,
            5,
            10,
            15,
            20,
            4
        );

        balanceOf[msg.sender] = totalSupply;

        state = State.Active;

        currentRound = roundInfo[0];
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    modifier transferredIsOn {
        require(state != State.Active);
        _;
    }

    function transfer(address _to, uint256 _value) transferredIsOn public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) transferredIsOn public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function transferOwner(address _to, uint256 _value) onlyOwner public {
        _transfer(msg.sender, _to, _value);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function buyTokens(address beneficiary) payable public {
        require(state == State.Active);
        require(msg.value >= currentRound._minValue);
        require(currentRound._rate > 0);
        require(address(this).balance <= currentRound._hardCap);
        uint amount = currentRound._rate.mul(msg.value);
        uint bonus = getBonusPercent(msg.value);
        amount = amount.add(amount.mul(bonus).div(100));
        require(amount <= currentRound._tokensForRound);

        _transfer(owner, msg.sender, amount);

        currentRound._tokensForRound = currentRound._tokensForRound.sub(amount);
        uint _num = currentRound._number;
        allDeposited[_num]._deposited[beneficiary] = allDeposited[_num]._deposited[beneficiary].add(msg.value);
    }

    function() external payable {
        buyTokens(msg.sender);
    }

    function getBonusPercent(uint _value) internal view returns(uint _bonus) {
        if (_value >= 15 ether) {
            return currentRound._bonus15;
        } else if (_value >= 8 ether) {
            return currentRound._bonus8;
        } else if (_value >= 4 ether) {
            return currentRound._bonus4;
        } else if (_value >= 1 ether) {
            return currentRound._bonus1;
        } else return 0;
    }

    function finishRound() onlyOwner public {
        if (address(this).balance < currentRound._softCap) {
            enableRefunds();
        } else {
            currentRound._wallet.transfer(address(this).balance);
            uint256 _nextRound = currentRound._number + 1;
            uint256 _burnTokens = currentRound._tokensForRound;
            balanceOf[owner] = balanceOf[owner].sub(_burnTokens);
            if (_nextRound < 5) {
                currentRound = roundInfo[_nextRound];
            } else {
                state = State.Closed;
            }
        }
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        require(allDeposited[currentRound._number]._deposited[investor] > 0);
        uint256 depositedValue = allDeposited[currentRound._number]._deposited[investor];
        allDeposited[currentRound._number]._deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }

    function withdraw(uint amount) onlyOwner public returns(bool) {
        require(amount <= address(this).balance);
        owner.transfer(amount);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
}