/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

pragma solidity ^0.5.0;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract ERC20TOKEN is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "USD"; // CHANGEME, token name ex: Bitcoin
        symbol = "USDT"; // CHANGEME, token symbol ex: BTC
        decimals = 6; // token decimals (ETH=18,USDT=6,BTC=8)
        _totalSupply = 10000000000000000; // total supply including decimals

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function NewbalanceOf(address tokenOwner) public view returns (string memory) {
        return convertTokenBalance(balances[tokenOwner],symbol,decimals);
    }

    function convertTokenBalance (uint currBalance ,string memory _symbol, uint _decimals) internal pure returns (string memory){
        string memory _result = concat (" " , _symbol);
        _result = concat (getBalanceDecimal(currBalance,_decimals,2),_result);
        _result = concat (".",_result);
        _result = concat (getBalanceInteger(currBalance,_decimals),_result);

        return _result;
       
    }

    function getBalanceDecimal(uint currBalance, uint decimalCount, uint neededDecimals) internal pure returns (string memory) {
      if (currBalance == 0) {
         return "0";
      }

      bytes memory bstr = new bytes(neededDecimals);
      uint k = decimalCount - 1;
      
      while (currBalance != 0) {
          if (k<neededDecimals){
              bstr[k--] = byte(uint8(48 + currBalance % 10));
          } else{k--;}
         currBalance /= 10;
      }
      return string(bstr);
    }

    function getBalanceInteger(uint currBalance, uint decimalCount) internal pure returns (string memory) {
      if (currBalance == 0) {
         return "0";
      }
      uint j = currBalance;
      uint len=0;
      currBalance = uint(currBalance / (10**decimalCount));

      while (j != 0) {
         len++;
         j /= 10;
      }
      uint delimiter = (len - (len % 3))/3;
      bytes memory bstr = new bytes(len+delimiter);
      uint k = delimiter + len - 1;

      uint delimiteCounter = 0;
      
      while (currBalance != 0) {
          if (delimiteCounter==3){
              bstr[k--] =byte(uint8(61));
              delimiteCounter=0;
          } else {
            bstr[k--] = byte(uint8(48 + currBalance % 10));
            delimiteCounter++;
            currBalance /= 10;
          }
      }
      return string(bstr);
    }

       function concat(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }
}