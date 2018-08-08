pragma solidity ^0.4.16;

contract AthletiCoin {

    string public name = "AthletiCoin";      //  token name
    string public symbol = "ATH";           //  token symbol
    uint256 public decimals = 18;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 0;
    bool public stopped = false;

    uint256 public sellPrice = 1000000000;
    uint256 public buyPrice = 1000000000;
    //000000000000000000
    uint256 constant valueFounder = 500000000000000000000000000;
    address owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isRunning {
        assert (!stopped);
        _;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function AthletiCoin (address _addressFounder) public {
        owner = msg.sender;
        totalSupply = 2000000000000000000000000000;
        balanceOf[_addressFounder] = valueFounder;
        emit Transfer(0x0, _addressFounder, valueFounder);
    }

    function giveBlockReward() public {
        balanceOf[block.coinbase] += 15000;
    }

    function mintToken(address target, uint256 mintedAmount) isOwner public {
      balanceOf[target] += mintedAmount;
      totalSupply += mintedAmount;
      emit Transfer(0, this, mintedAmount);
      emit Transfer(this, target, mintedAmount);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) isOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() public payable returns (uint amount){
        amount = msg.value / buyPrice;                    // calculates the amount
        require(balanceOf[this] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        balanceOf[this] -= amount;                        // subtracts amount from seller&#39;s balance
        emit Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }

    function sell(uint amount) public returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner&#39;s balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller&#39;s balance
        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }


    function transfer(address _to, uint256 _value) public isRunning validAddress returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public isRunning validAddress returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public isRunning validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function stop() public isOwner {
        stopped = true;
    }

    function start() public isOwner {
        stopped = false;
    }

    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[0x0] += _value;
        emit Transfer(msg.sender, 0x0, _value);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}