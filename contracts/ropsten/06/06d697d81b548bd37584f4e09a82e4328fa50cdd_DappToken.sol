pragma solidity ^0.4.2;

contract DappToken {
  //constructor
  // set the total number of tokens
  //read the total number of tokens
  uint256 public totalSupply;
  //Name
  string public name = &quot;DApp Token&quot;;
  //Symbol
  string public symbol = &quot;DAPP&quot;;
  //standard
  string public standard = &quot;DApp Token v1.0&quot;;

  event Transfer(
      address indexed _from,
      address indexed _to,
      uint256 _value
    );

  event Approval(
          address indexed _owner,
          address indexed _spender,
          uint256 _value
      );
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  function DappToken (uint256 _initialSupply) public {
    balanceOf[msg.sender] = _initialSupply;
    totalSupply = _initialSupply;
    //allocate the inital supply

  }
  //Transfer
  function transfer(address _to, uint256 _value) public returns (bool success){
    //Exception if the account doesnt have enough
    require(balanceOf[msg.sender] >= _value);
    //transfer the balance
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    //Transfer Event
   emit  Transfer(msg.sender, _to, _value);
    //return a boolean
    return true;
  }

  //Delegated transfer

    function approve(address _spender, uint256 _value) public returns (bool success) {
      //allowance
        allowance[msg.sender][_spender] = _value;
        // approval amount
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}


contract DappTokenSale {
    address admin;
    DappToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);

    function DappTokenSale(DappToken _tokenContract, uint256 _tokenPrice) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(this) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));

        tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(this)));

        // UPDATE: Let&#39;s not destroy the contract here
        // Just transfer the balance to the admin
        admin.transfer(address(this).balance);
    }
}