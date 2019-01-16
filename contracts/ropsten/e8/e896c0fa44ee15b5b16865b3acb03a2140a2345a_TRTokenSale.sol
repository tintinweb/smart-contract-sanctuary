pragma solidity ^0.4.24;

contract Token {
   
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TRToken is Token {

    string  public name = "TR Token";
    string  public symbol = "TRT";
    uint8 public decimals = 0;
    string  public version = "TRT Token v1.0";
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


     constructor (uint256 _initialSupply) public {
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

     function () {
        //if ether is sent to this address, send it back.
        throw;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {return false;}
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {return false;}
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract TRTokenSale {
    address admin;
    TRToken public tokenContract;
    uint256 public tokenPrice;

    event Sell(address _buyer, uint256 _amount);

      constructor (TRToken _tokenContract, uint256 _tokenPrice) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
       }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(this) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));
        emit Sell(msg.sender, _numberOfTokens);
    }

    function remainingTokens() public view returns (uint256) {
       return tokenContract.balanceOf(this);
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(this)));
        admin.transfer(address(this).balance); // not destroy the contract here Just transfer the balance to the admin
    }

    function changeTokenPrice(uint256 _tokenPrice) public {
        require(msg.sender == admin);
        tokenPrice = _tokenPrice;
    }
}