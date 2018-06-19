pragma solidity 0.4.21;

/*--------------------------------------------------------------/*
        _      _                 _                _         
  _ __ ( ) ___| | ___  _   _  __| |  _____      _(_)___ ___ 
 | &#39;_ \|/ / __| |/ _ \| | | |/ _` | / __\ \ /\ / / / __/ __|
 | | | | | (__| | (_) | |_| | (_| |_\__ \\ V  V /| \__ \__ \
 |_| |_|  \___|_|\___/ \__,_|\__,_(_)___/ \_/\_/ |_|___/___/
                                                            
                              NCU Token   
                              
                 Token Code created:   23.03.2018
                                 - 
                 Token Code published: 04.04.2018
                 
                        by n&#39;cloud.swiss AG                                           
/*--------------------------------------------------------------*/

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
       c = a + b;
        require(c >= a);
   }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
       c = a - b;
   }
    function mul(uint a, uint b) internal pure returns (uint c) {
       c = a * b;
       require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
      c = a / b;
   }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol

    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}

contract NCU is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public constant decimals = 2;

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function NCU(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
        
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}


    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public {
        uint amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount * sellPrice);
    }
   }