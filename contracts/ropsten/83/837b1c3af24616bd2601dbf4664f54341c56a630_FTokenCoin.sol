pragma solidity ^0.4.24;

contract FTokenCoin {
    mapping (address => uint256) public balanceOf;

    string public name = "First Token Coin";
    string public symbol = "FTC";
    uint8 public decimals = 18;
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    address public fundsWallet;

    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        // Initially assign all tokens to the contract&#39;s creator.
        balanceOf[msg.sender] = totalSupply;
        unitsOneEthCanBuy = 100;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balanceOf[fundsWallet] >= amount);

        balanceOf[fundsWallet] = balanceOf[fundsWallet] - amount;
        balanceOf[msg.sender] = balanceOf[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender&#39;s balance
        balanceOf[to] += value;          // add to recipient&#39;s balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}