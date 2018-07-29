pragma solidity ^0.4.16;

contract TargetHit {
    string public name = &quot;Target Hit&quot;;      //  token name
    string public symbol = &quot;TGH&quot;;           //  token symbol
    string public version = &quot;3.0&quot;;
    uint256 public decimals = 8;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 33333333300000000;

    bool public stopped = true;

    uint256 public price = 30000300003000;
    //000 000 000 000 000 000

    address owner = 0x65A05c896d9A6f428B3936ac5db8df28752Ccd44;
    address devteam = 0x3a9a6720B687a4F2Fc8e2d82a0B896C505340f62;

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
        uint256 Supply = totalSupply * 33 / 100;
        balanceOf[devteam] = Supply;
        emit Transfer(0x0, devteam, Supply);
        Supply = totalSupply - Supply;
        balanceOf[owner] = Supply;
        emit Transfer(0x0, owner, Supply);
    }

    function changeOwner(address _newaddress) isOwner public {
        owner = _newaddress;
    }

    function setPrices(uint256 newPrice) isOwner public {
        price = newPrice;
    }

    function buy() public payable returns (uint amount){
        require(stopped == false);
        amount = msg.value / price;                    // calculates the amount
        require(balanceOf[owner] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer&#39;s balance
        balanceOf[owner] -= amount;                        // subtracts amount from seller&#39;s balance
        owner.transfer(msg.value);
        emit Transfer(owner, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }


    function GetPrice() public view returns (uint256) {
      return price;
    }

    function deployTokens (uint256[] _amounts, address[] _recipient) public isOwner {
        for(uint i = 0; i< _recipient.length; i++)
        {
            if (_amounts[i] > 0) {
              if (transferfromOwner(_recipient[i], _amounts[i])){
                totalSupply = totalSupply - _amounts[i];
              }
            }
        }
    }

    function transferfromOwner(address _to, uint256 _value) private returns (bool success) {
        require(balanceOf[owner] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[owner] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(owner, _to, _value);
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

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}