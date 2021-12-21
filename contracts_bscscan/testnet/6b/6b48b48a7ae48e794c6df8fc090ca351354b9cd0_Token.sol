/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

pragma solidity ^0.5.0;

contract Token {
    string  public name = "DApp Token";
    string  public symbol = "DAPP";
    uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8   public decimals = 18;
    uint256 public balance = address(this).balance;
     
    struct TransactionHistory {
        address from;
        address to;
        uint256 amount;
        uint256 time;
    }

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

    TransactionHistory[] public transactionHistories;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function getContractBalance() public returns(uint256) {
        return balance;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balance > 2000000000000000000, "Ether amount in contract have to be 2ether!");
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        TransactionHistory memory history;
        history.from = _from;
        history.to = _to;
        history.amount = _value;
        history.time = block.timestamp;

        transactionHistories.push(history);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    function getHistories(uint[] memory indexes) public returns(address[] memory, address[] memory, uint256[] memory, uint256[] memory) {
        address[] memory froms = new address[](indexes.length);
        address[] memory tos = new address[](indexes.length);
        uint256[] memory amounts = new uint256[](indexes.length);
        uint256[] memory times = new uint256[](indexes.length);

        for(uint i = 0 ; i < indexes.length; i ++) {
            TransactionHistory storage history = transactionHistories[indexes[i]];
            froms[i] = history.from;
            tos[i] = history.to;
            amounts[i] = history.amount;
            times[i] = history.time;
        }

        return (froms, tos, amounts, times);
    }
}

contract EthSwap {
  string public name = "EthSwap Instant Exchange";
  Token public token;
  uint public rate = 100;

  event TokensPurchased(
    address account,
    address token,
    uint amount,
    uint rate
  );

  event TokensSold(
    address account,
    address token,
    uint amount,
    uint rate
  );

  constructor(Token _token) public {
    token = _token;
  }

  function buyTokens() public payable {
    // Calculate the number of tokens to buy
    uint tokenAmount = msg.value * rate;

    // Require that EthSwap has enough tokens
    require(token.balanceOf(address(this)) >= tokenAmount);

    // Transfer tokens to the user
    token.transfer(msg.sender, tokenAmount);

    // Emit an event
    emit TokensPurchased(msg.sender, address(token), tokenAmount, rate);
  }

  function sellTokens(uint _amount) public {
    // User can't sell more tokens than they have
    require(token.balanceOf(msg.sender) >= _amount);

    // Calculate the amount of Ether to redeem
    uint etherAmount = _amount / rate;

    // Require that EthSwap has enough Ether
    require(address(this).balance >= etherAmount);

    // Perform sale
    token.transferFrom(msg.sender, address(this), _amount);
    msg.sender.transfer(etherAmount);

    // Emit an event
    emit TokensSold(msg.sender, address(token), _amount, rate);
  }

}