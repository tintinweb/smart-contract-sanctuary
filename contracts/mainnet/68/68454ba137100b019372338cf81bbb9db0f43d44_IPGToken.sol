pragma solidity ^0.4.16;

contract IPGToken {
    string public name = "IPGToken";      //  token name
    string public symbol = "IPG";           //  token symbol
    string public version = "1.0";
    uint256 public decimals = 8;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (uint256 => address) public games;
    uint256 public gameCount = 0;

    uint256 public totalSupply = 0;
    bool public stopped = true;

    uint256 public sellPrice = 2107170701898561;
    uint256 public buyPrice = 2107170701898561;
    //00000000
    uint256 constant valueFounder = 10000000000000;
    address owner = 0x0b1Bd7B954517f1C1429709D4856B19f1E8aa176;
    address dev = 0x815dE3E00Be485DBCA2A2ADf40f945a8E0343b29;


    modifier isDev {
        assert(dev == msg.sender);
        _;
    }


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

    constructor () public {
        totalSupply = valueFounder;
        balanceOf[owner] = valueFounder;
        gameCount = 0;
        emit Transfer(0x0, owner, valueFounder);
    }

    function changeOwner(address _newaddress) isOwner public {
        owner = _newaddress;
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
        require(balanceOf[owner] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        balanceOf[owner] -= amount;                        // subtracts amount from seller&#39;s balance
        emit Transfer(owner, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }


    function sell(uint amount) public isRunning validAddress returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[owner] += amount;                        // adds the amount to owner&#39;s balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller&#39;s balance
        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit Transfer(msg.sender, owner, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }


    function GetBuyPrice() public view returns (uint) {
      return buyPrice;
    }

    function GetSellPrice() public view returns (uint) {
      return sellPrice;
    }

    function addGame(address _game) isDev public {
        games[gameCount] = _game;
        gameCount++;
    }

    function changeGame(address _game, uint256 _index) isDev public {
       games[_index] = _game;
    }

    function transferInGame (address _from, address _to, uint256 _value) public returns (bool success) {
        bool is_allowed = false;
        for (uint256 i = 0; i < gameCount; i++){
            if (games[i] == msg.sender){
                is_allowed = true;
            }
        }
        require(is_allowed == true);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
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