pragma solidity ^0.4.13;

interface TokenERC20 {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function balanceOf(address _owner) constant returns (uint256 balance);
}


interface TokenNotifier {

    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

/**
 * @title SafeMath (from https://github.com/OpenZeppelin/zeppelin-solidity/blob/4d91118dd964618863395dcca25a50ff137bf5b6/contracts/math/SafeMath.sol)
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    
    function safeMul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Owned {

    address owner;
    
    function Owned() { owner = msg.sender; }

    modifier onlyOwner { require(msg.sender == owner); _; }
}


contract PersianToken is TokenERC20, Owned, SafeMath {

    // The actual total supply is not constant and it will be updated with the real redeemed tokens once the ICO is over
    uint256 public totalSupply = 0;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint8 public constant decimals = 18;
    string public constant name = &#39;Persian&#39;;
    string public constant symbol = &#39;PRS&#39;;
    string public constant version = &#39;1.0.0&#39;;

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] < _value) return false;
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if(balances[msg.sender] < _value || allowed[_from][msg.sender] < _value) return false;
        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        if(!approve(_spender, _value)) return false;
        TokenNotifier(_spender).receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


contract TokenICO is PersianToken {

    uint256 public icoStartBlock;
    uint256 public icoEndBlock;
    uint256 public totalContributions;
    mapping (address => uint256) public contributions;

    // At max 300.000 Persian (with 18 decimals) will be ever generated from this ICO
    uint256 public constant maxTotalSupply = 300000 * 10**18;

    event Contributed(address indexed _contributor, uint256 _value, uint256 _estimatedTotalTokenBalance);
    event Claimed(address indexed _contributor, uint256 _value);

    function contribute() onlyDuringICO payable external returns (bool success) {
        totalContributions = safeAdd(totalContributions, msg.value);
        contributions[msg.sender] = safeAdd(contributions[msg.sender], msg.value);
        Contributed(msg.sender, msg.value, estimateBalanceOf(msg.sender));
        return true;
    }

    function claimToken() onlyAfterICO external returns (bool success) {
        uint256 balance = estimateBalanceOf(msg.sender);
        contributions[msg.sender] = 0;
        balances[msg.sender] = safeAdd(balances[msg.sender], balance);
        totalSupply = safeAdd(totalSupply, balance);
        require(totalSupply <= maxTotalSupply);
        Claimed(msg.sender, balance);
        return true;
    }

    function redeemEther() onlyAfterICO onlyOwner external  {
        owner.transfer(this.balance);
    }

    function estimateBalanceOf(address _owner) constant returns (uint256 estimatedTokens) {
        return contributions[_owner] > 0 ? safeMul( maxTotalSupply / totalContributions, contributions[_owner]) : 0;
    }

    // This check is an helper function for &#208;App to check the effect of the NEXT tx, NOT simply the current state of the contract
    function isICOOpen() constant returns (bool _open) {
        return block.number >= (icoStartBlock - 1) && !isICOEnded();
    }

    // This check is an helper function for &#208;App to check the effect of the NEXT tx, NOT simply the current state of the contract
    function isICOEnded() constant returns (bool _ended) {
        return block.number >= icoEndBlock;
    }

    modifier onlyDuringICO {
        require(block.number >= icoStartBlock && block.number <= icoEndBlock); _;
    }

    modifier onlyAfterICO {
        require(block.number > icoEndBlock); _;
    }
}


contract PersianTokenICO is TokenICO {

    function PersianTokenICO(uint256 _icoStartBlock, uint256 _icoEndBlock) {
        icoStartBlock = _icoStartBlock;
        icoEndBlock = _icoEndBlock;
    }
  
    function () onlyDuringICO payable {
        totalContributions = safeAdd(totalContributions, msg.value);
        contributions[msg.sender] = safeAdd(contributions[msg.sender], msg.value);
        Contributed(msg.sender, msg.value, estimateBalanceOf(msg.sender));
    }

}