pragma solidity ^0.4.20;

contract ForeignToken {
    function balanceOf(address _owner) public constant returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract ForeignTokenProvider is Ownable {
    function withdrawForeignTokens(address _tokenContract) public onlyOwner returns (bool) {
        ForeignToken foreignToken = ForeignToken(_tokenContract);
        uint256 amount = foreignToken.balanceOf(address(this));

        return foreignToken.transfer(owner, amount);
    }
}

contract XataToken is ForeignTokenProvider {
    bool public purchasingAllowed = false;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    uint256 public totalContribution = 0;
    uint256 public totalBonusTokensIssued = 0;
    uint256 public totalSupply = 0;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public pure returns (string) {return "Sobirayu na Xatu";}

    function symbol() public pure returns (string) {return "XATA";}

    function decimals() public pure returns (uint32) {return 18;}

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {

        if (_value == 0) {
            return false;
        }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];

        if (!sufficientFunds || overflowed) {
          return false;
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_value == 0) {
            return false;
        }

        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];

        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];

        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;

            allowed[_from][msg.sender] -= _value;

            emit Transfer(_from, _to, _value);

            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) {
            return false;
        }

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function mintBonus(address _to) public onlyOwner {
        uint256 bonusValue = 10 * 1 ether;

        totalBonusTokensIssued += bonusValue;
        totalSupply += bonusValue;
        balances[_to] += bonusValue;

        emit Transfer(address(this), _to, bonusValue);
    }

    function enablePurchasing() public onlyOwner {
        purchasingAllowed = true;
    }

    function disablePurchasing() public onlyOwner {
        purchasingAllowed = false;
    }

    function getStats() public constant returns (uint256, uint256, uint256, bool) {
        return (totalContribution, totalSupply, totalBonusTokensIssued, purchasingAllowed);
    }

    function() external payable {
        require(purchasingAllowed);
        require(msg.value > 0);

        owner.transfer(msg.value);
        totalContribution += msg.value;

        uint256 tokensIssued = (msg.value * 100);

        if (msg.value >= 10 finney) {
            tokensIssued += totalContribution;
            totalBonusTokensIssued += totalContribution;
        }

        totalSupply += tokensIssued;
        balances[msg.sender] += tokensIssued;

        emit Transfer(address(this), msg.sender, tokensIssued);
    }
}