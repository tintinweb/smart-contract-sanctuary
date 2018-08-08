pragma solidity ^0.4.21;

contract StandardToken {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint public totalSupply;
}

contract MintableToken is StandardToken {
    address public owner;

    bool public isMinted = false;

    function mint(address _to) public {
        assert(msg.sender == owner && !isMinted);

        balances[_to] = totalSupply;
        isMinted = true;
    }
}

contract SafeNetToken is MintableToken {
    string public name = &#39;SafeNet Token&#39;;
    string public symbol = &#39;SNT&#39;;
    uint8 public decimals = 18;

    function SafeNetToken(uint _totalSupply) public {
        owner = msg.sender;
        totalSupply = _totalSupply;
    }
}

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

contract Treaties {
    using SafeMath for uint;

    SafeNetToken public token; 

    address public creator;
    bool public creatorInited = false;

    address public wallet;

    uint public walletPercentage = 100;

    address[] public owners;
    address[] public teams;
    address[] public investors;

    mapping (address => bool) public inList;

    uint public tokensInUse = 0;

    mapping (address => uint) public refunds;

    struct Request {
        uint8 rType; // 0 - owner, 1 - team, 2 - investor(eth), 3 - investor(fiat), 4 - new percentage
        address beneficiary;
        string treatyHash;
        uint tokensAmount;
        uint ethAmount;
        uint percentage;

        uint8 isConfirmed; // 0 - pending, 1 - declined, 2 - accepted
        address[] ownersConfirm;
    }

    Request[] public requests;

    modifier onlyOwner() {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                _;
            }
        }
    }   

    event NewRequest(uint8 rType, address beneficiary, string treatyHash, uint tokensAmount, uint ethAmount, uint percentage, uint id);
    event RequestConfirmed(uint id);
    event RequestDeclined(uint id);
    event RefundsCalculated();

    function Treaties(address _wallet, SafeNetToken _token) public {
        creator = msg.sender;
        token = _token;
        wallet = _wallet;
    }

    function() external payable {
        splitProfit(msg.value);
    }

    // after mint
    function initCreator(uint _tokensAmount) public {
        assert(msg.sender == creator && !creatorInited);

        owners.push(creator);
        assert(token.transfer(creator, _tokensAmount));
        tokensInUse += _tokensAmount;
        inList[creator] = true;
        creatorInited = true;
    }


    function createTreatyRequest(uint8 _rType, string _treatyHash, uint _tokensAmount) public {
        require(_rType <= 1);

        requests.push(Request({
            rType: _rType,
            beneficiary: msg.sender,
            treatyHash: _treatyHash,
            tokensAmount: _tokensAmount,
            ethAmount: 0,
            percentage: 0,
            isConfirmed: 0,
            ownersConfirm: new address[](0)
            }));

        emit NewRequest(_rType, msg.sender, _treatyHash, _tokensAmount, 0, 0, requests.length - 1);
    }

    function createEthInvestorRequest(uint _tokensAmount) public payable {
        assert(msg.value > 0);

        requests.push(Request({
            rType: 2,
            beneficiary: msg.sender,
            treatyHash: &#39;&#39;,
            tokensAmount: _tokensAmount,
            ethAmount: msg.value,
            percentage: 0,
            isConfirmed: 0,
            ownersConfirm: new address[](0)
            }));

        emit NewRequest(2, msg.sender, "", _tokensAmount, msg.value, 0, requests.length - 1);
    }

    function removeEthInvestorRequest(uint id) public {
        require(id < requests.length);
        assert(requests[id].isConfirmed == 0 && requests[id].rType == 2);
        assert(requests[id].beneficiary == msg.sender);

        requests[id].isConfirmed = 1;
        assert(msg.sender.send(requests[id].ethAmount));
        emit RequestDeclined(id);
    }

    function createFiatInvestorRequest(uint _tokensAmount) public {
        requests.push(Request({
            rType: 3,
            beneficiary: msg.sender,
            treatyHash: &#39;&#39;,
            tokensAmount: _tokensAmount,
            ethAmount: 0,
            percentage: 0,
            isConfirmed: 0,
            ownersConfirm: new address[](0)
            }));

        emit NewRequest(3, msg.sender, "", _tokensAmount, 0, 0, requests.length - 1);
    }

    function createPercentageRequest(uint _percentage) public onlyOwner {
        require(_percentage <= 100);

        requests.push(Request({
            rType: 4,
            beneficiary: msg.sender,
            treatyHash: &#39;&#39;,
            tokensAmount: 0,
            ethAmount: 0,
            percentage: _percentage,
            isConfirmed: 0,
            ownersConfirm: new address[](0)
            }));

        emit NewRequest(4, msg.sender, "", 0, 0, _percentage, requests.length - 1);
    }


    function confirmRequest(uint id) public onlyOwner {
        require(id < requests.length);
        assert(requests[id].isConfirmed == 0);

        uint tokensConfirmed = 0;
        for (uint i = 0; i < requests[id].ownersConfirm.length; i++) {
            assert(requests[id].ownersConfirm[i] != msg.sender);
            tokensConfirmed += token.balanceOf(requests[id].ownersConfirm[i]);
        }

        requests[id].ownersConfirm.push(msg.sender);
        tokensConfirmed += token.balanceOf(msg.sender);

        uint tokensInOwners = 0;
        for (i = 0; i < owners.length; i++) {
            tokensInOwners += token.balanceOf(owners[i]);
        }

        if (tokensConfirmed > tokensInOwners / 2) {
            if (requests[id].rType == 4) {
                walletPercentage = requests[id].percentage;

            } else {
                if (!inList[requests[id].beneficiary]) {
                    if (requests[id].rType == 0) {
                        owners.push(requests[id].beneficiary);
                        token.transfer(creator, requests[id].tokensAmount / 10);
                    }
                    if (requests[id].rType == 1) {
                        teams.push(requests[id].beneficiary);
                    }
                    if (requests[id].rType == 2 || requests[id].rType == 3) {
                        investors.push(requests[id].beneficiary);
                    }
                    inList[requests[id].beneficiary] = true;
                }

                if (requests[id].rType == 2) {
                    assert(wallet.send(requests[id].ethAmount));
                }

                token.transfer(requests[id].beneficiary, requests[id].tokensAmount);
                tokensInUse += requests[id].tokensAmount;
            }

            requests[id].isConfirmed = 2;
            emit RequestConfirmed(id);
        }
    }

    function rejectRequest(uint id) public onlyOwner {
        require(id < requests.length);
        assert(requests[id].isConfirmed == 0);

        for (uint i = 0; i < requests[id].ownersConfirm.length; i++) {
            if (requests[id].ownersConfirm[i] == msg.sender) {
                requests[id].ownersConfirm[i] = requests[id].ownersConfirm[requests[id].ownersConfirm.length - 1];
                requests[id].ownersConfirm.length--;
                break;
            }
        }
    }


    function splitProfit(uint profit) internal {
        uint rest = profit;
        uint refund;
        address addr;
        for (uint i = 0; i < owners.length; i++) {
            addr = owners[i];
            refund = profit.mul(token.balanceOf(addr)).mul(100 - walletPercentage).div(100).div(tokensInUse);
            refunds[addr] += refund;
            rest -= refund;
        }
        for (i = 0; i < teams.length; i++) {
            addr = teams[i];
            refund = profit.mul(token.balanceOf(addr)).mul(100 - walletPercentage).div(100).div(tokensInUse);
            refunds[addr] += refund;
            rest -= refund;
        }
        for (i = 0; i < investors.length; i++) {
            addr = investors[i];
            refund = profit.mul(token.balanceOf(addr)).mul(100 - walletPercentage).div(100).div(tokensInUse);
            refunds[addr] += refund;
            rest -= refund;
        }

        assert(wallet.send(rest));
        emit RefundsCalculated();
    }

    function withdrawRefunds() public {
        assert(refunds[msg.sender] > 0);
        uint refund = refunds[msg.sender];
        refunds[msg.sender] = 0;
        assert(msg.sender.send(refund));
    }
}