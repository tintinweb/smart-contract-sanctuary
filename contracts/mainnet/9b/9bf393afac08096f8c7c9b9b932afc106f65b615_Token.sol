pragma solidity ^0.4.16;

contract Token {
    uint8 public decimals = 6;
    uint8 public referralPromille = 20;
    uint256 public totalSupply = 2000000000000;
    uint256 public buyPrice = 1600000000;
    uint256 public sellPrice = 1400000000;
    string public name = "Brisfund token";
    string public symbol = "BRIS";
    mapping (address => bool) public lock;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    address owner;

    function Token() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!lock[msg.sender]);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!lock[_from]);
        require(allowance[_from][msg.sender] >= _value);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function setBlocking(address _address, bool _state) public onlyOwner returns (bool) {
        lock[_address] = _state;
        return true;
    }

    function setReferralPromille(uint8 _promille) public onlyOwner returns (bool) {
        require(_promille < 100);
        referralPromille = _promille;
        return true;
    }

    function setPrice(uint256 _buyPrice, uint256 _sellPrice) public onlyOwner returns (bool) {
        require(_sellPrice > 0);
        require(_buyPrice > _sellPrice);
        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
        return true;
    }

    function buy() public payable returns (bool) {
        uint value = msg.value / buyPrice;
        require(balanceOf[owner] >= value);
        require(balanceOf[msg.sender] + value > balanceOf[msg.sender]);
        balanceOf[owner] -= value;
        balanceOf[msg.sender] += value;
        Transfer(owner, msg.sender, value);
        return true;
    }

    function buyWithReferral(address _referral) public payable returns (bool) {
        uint value = msg.value / buyPrice;
        uint bonus = value / 1000 * referralPromille;
        require(balanceOf[owner] >= value + bonus);
        require(balanceOf[msg.sender] + value > balanceOf[msg.sender]);
        require(balanceOf[_referral] + bonus >= balanceOf[_referral]);
        balanceOf[owner] -= value + bonus;
        balanceOf[msg.sender] += value;
        balanceOf[_referral] += bonus;
        Transfer(owner, msg.sender, value);
        Transfer(owner, _referral, bonus);
        return true;
    }

    function sell(uint256 _tokenAmount) public returns (bool) {
        require(!lock[msg.sender]);
        uint ethValue = _tokenAmount * sellPrice;
        require(this.balance >= ethValue);
        require(balanceOf[msg.sender] >= _tokenAmount);
        require(balanceOf[owner] + _tokenAmount > balanceOf[owner]);
        balanceOf[msg.sender] -= _tokenAmount;
        balanceOf[owner] += _tokenAmount;
        msg.sender.transfer(ethValue);
        Transfer(msg.sender, owner, _tokenAmount);
        return true;
    }

    function changeSupply(uint256 _value, bool _add) public onlyOwner returns (bool) {
        if(_add) {
            require(balanceOf[owner] + _value > balanceOf[owner]);
            balanceOf[owner] += _value;
            totalSupply += _value;
            Transfer(0, owner, _value);
        } else {
            require(balanceOf[owner] >= _value);
            balanceOf[owner] -= _value;
            totalSupply -= _value;
            Transfer(owner, 0, _value);
        }
        return true;
    }

    function reverse(address _reversed, uint256 _value) public onlyOwner returns (bool) {
        require(balanceOf[_reversed] >= _value);
        require(balanceOf[owner] + _value > balanceOf[owner]);
        balanceOf[_reversed] -= _value;
        balanceOf[owner] += _value;
        Transfer(_reversed, owner, _value);
        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function kill() public onlyOwner {
        selfdestruct(owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}