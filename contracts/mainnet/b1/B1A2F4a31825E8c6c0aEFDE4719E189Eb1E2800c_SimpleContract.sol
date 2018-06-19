pragma solidity ^ 0.4.16;

contract owned {
    address public owner;
    
    function owned() payable {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    function changeOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
}
contract Crowdsale is owned {
    
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function Crowdsale() payable owned() {
        totalSupply = 900000000000000000000000000000;
        balanceOf[this] = 1000000000000000000000000;
        balanceOf[owner] = totalSupply - balanceOf[this];
        Transfer(this, owner, balanceOf[owner]);
    }
    
    function () payable {
        require(balanceOf[this] > 0);
        uint256 tokens = 5000000000000000000000 * msg.value / 1000000000000000000;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint valueWei = tokens * 1000000000000000000 / 5000000000000000000000;
            msg.sender.transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}
contract Token is Crowdsale {
    
    string  public standard    = &#39;Token 0.1&#39;;
    string  public name        = &#39;SocCoin&#39;;
    string  public symbol      = &#39;SCN&#39;;
    uint8   public decimals    = 18;
    
    function Token() payable Crowdsale() {}
    
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
}

contract SimpleContract is Token {
    
    function SimpleContract() payable Token() {}
    
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }
    function killme() public onlyOwner {
        selfdestruct(owner);
    }
}