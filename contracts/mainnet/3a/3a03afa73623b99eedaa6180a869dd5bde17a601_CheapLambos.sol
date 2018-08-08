pragma solidity ^0.4.21;

// send at least 1 wei with 0x1cb07902 as input data to this contract
// you will receive 1 million real authentic lambos!

contract CheapLambos {

    string public name = "Lambo";      //  token name
    string public symbol = "LAMBO";           //  token symbol
    uint256 public decimals = 18;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 0;

    address owner;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }



    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function Lambo() public {
        owner = msg.sender;
        mint(owner);
    }

    function transfer(address _to, uint256 _value) public validAddress returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public validAddress returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // WTF you want to burn LAMBO!?
    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[0x0] += _value;
        emit Transfer(msg.sender, 0x0, _value);
    }
    
    function mint(address who) public {
        if (who == 0x0){
            who = msg.sender;
        }
        require(balanceOf[who] == 0);
        _mint(who, 1);
    }
    
    function mintMore(address who) public payable{
        if (who == 0x0){
            who = msg.sender;
        }
        require(msg.value >= (1 wei));
        _mint(who,1000000);
        owner.transfer(msg.value);
    }
    
    function _mint(address who, uint256 howmuch) internal {
        balanceOf[who] = balanceOf[who] + howmuch * (10 ** decimals);
        totalSupply = totalSupply + howmuch * (10 ** decimals);
        emit Transfer(0x0, who, howmuch * (10 ** decimals));
    }
    

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}