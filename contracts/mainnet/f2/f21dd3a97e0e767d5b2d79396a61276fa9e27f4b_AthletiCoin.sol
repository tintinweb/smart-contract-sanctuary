pragma solidity ^0.4.16;

contract AthletiCoin {

    string public name = "AthletiCoin";      //  token name
    string public symbol = "ATHA";           //  token symbol
    //string public version = "realversion";
    uint256 public decimals = 18;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 0;
    bool public stopped = false;
    
    uint256 public sellPrice = 1530000000000;
    uint256 public buyPrice = 1530000000000;
    //000000000000000000
    uint256 constant valueFounder = 500000000000000000000000000;

    address owner = 0xA9F6e166D73D4b2CAeB89ca84101De2c763F8E86;
    address redeem_address = 0xA1b36225858809dd41c3BE9f601638F3e673Ef48;
    address owner2 = 0xC58ceD5BA5B1daa81BA2eD7062F5bBC9cE76dA8d;
    address owner3 = 0x06c7d7981D360D953213C6C99B01957441068C82;
    
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
        totalSupply = 2000000000000000000000000000;
        balanceOf[owner] = valueFounder;
        emit Transfer(0x0, owner, valueFounder);
        
        balanceOf[owner] = valueFounder;
        emit Transfer(0x0, owner2, valueFounder);
        
        balanceOf[owner] = valueFounder;
        emit Transfer(0x0, owner3, valueFounder);
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

    function redeem(address target, uint256 token_amount) public payable returns (uint amount){
        token_amount = token_amount * 1000000000000000000;
        uint256 fee_amount = token_amount * 2 / 102;
        uint256 redeem_amount = token_amount - fee_amount;
        uint256 sender_amount = balanceOf[msg.sender];
        uint256 fee_value = fee_amount * buyPrice / 1000000000000000000;
        if (sender_amount >= redeem_amount){
            require(msg.value >= fee_value);
            balanceOf[target] += redeem_amount;                  // adds the amount to buyer&#39;s balance
            balanceOf[msg.sender] -= redeem_amount; 
            emit Transfer(msg.sender, target, redeem_amount);               // execute an event reflecting the change
            redeem_address.transfer(msg.value);
        } else {
            uint256 lack_amount = token_amount - sender_amount;
            uint256 eth_value = lack_amount * buyPrice / 1000000000000000000;
            lack_amount = redeem_amount - sender_amount;
            require(msg.value >= eth_value);
            require(balanceOf[owner] >= lack_amount);    // checks if it has enough to sell
            
            balanceOf[target] += redeem_amount;                  // adds the amount to buyer&#39;s balance
            balanceOf[owner] -= lack_amount;                        // subtracts amount from seller&#39;s balance  
            balanceOf[msg.sender] = 0;
            
            eth_value = msg.value - fee_value;
            owner.transfer(eth_value);
            redeem_address.transfer(fee_value);
            emit Transfer(msg.sender, target, sender_amount);               // execute an event reflecting the change
            emit Transfer(owner, target, lack_amount);               // execute an event reflecting the change
        }
        return token_amount;                                    // ends function and returns
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