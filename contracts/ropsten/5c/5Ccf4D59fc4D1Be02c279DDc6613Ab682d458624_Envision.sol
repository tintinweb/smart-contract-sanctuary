/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.8;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address private _owner;

  constructor() public {
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function owner(
  ) public view returns (address) {
    return _owner;
  }

  function isOwner(
  ) public view returns (bool) {
    return msg.sender == _owner;
  }
  
    /**
   * transferOwnership
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    _owner = newOwner;
  }
}

contract Envision is IERC20, Ownable {

    using SafeMath for uint;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    uint256 internal _maxSupply = 200000000 * 10 ** 18;
    
    uint public burnWalletFee = 50;
    uint public poolWalletFee = 50;
    uint public marketingWalletFee = 50;
    uint public totalFeePercent = 1000;
    
    address public burnWalletAdress = 0x0f22F0f1C70b0277dEE7F0FF1ac480CB594Ca450;
    address public poolWalletAddress = 0x0f22F0f1C70b0277dEE7F0FF1ac480CB594Ca450;
    address public marketingWalletAddress = 0x0f22F0f1C70b0277dEE7F0FF1ac480CB594Ca450;
    
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event Mint(address indexed minter, address indexed account, uint256 amount);
    event Burn(address indexed burner, address indexed account, uint256 amount);

    constructor (
        string memory name, 
        string memory symbol, 
        uint8 decimals, 
        uint256 totalSupply
    ) public
    {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }

    function name(
    ) public view returns (string memory)
    {
        return _name;
    }

    function symbol(
    ) public view returns (string memory)
    {
        return _symbol;
    }

    function decimals(
    ) public view returns (uint8)
    {
        return _decimals;
    }

    function totalSupply(
    ) public view returns (uint256)
    {
        return _totalSupply;
    }

    function setTotalFeePercent(uint _totalFeePercent) public onlyOwner{
      totalFeePercent = _totalFeePercent;
    }

    function setBurnWalletFee(address _burnWalletAddress,  uint _feePercent) public onlyOwner{
        burnWalletAdress = _burnWalletAddress;    
        burnWalletFee = _feePercent;
    }
    
    function setMarketWalletFee(address _marketWalletAddress,  uint _feePercent) public onlyOwner{
        marketingWalletAddress = _marketWalletAddress;    
        marketingWalletFee = _feePercent;
    }
    
    function setPoolWalletFee(address _poolWalletAddress,  uint _feePercent) public onlyOwner{
        poolWalletAddress = _poolWalletAddress;    
        poolWalletFee = _feePercent;
    }
    
    function transferbyOwner(address _to, uint256 _value) public onlyOwner  returns (bool) {
        require(_to != address(0), 'Envision: to address is not valid');
        require(_value <= _balances[msg.sender], 'Envision: insufficient balance');
        _balances[msg.sender] = SafeMath.sub(_balances[msg.sender], _value);
        _balances[_to] = _balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transfer(
        address _to, 
        uint256 _value
    ) public override
      returns (bool)
    {
        require(_to != address(0), 'Envision: to address is not valid');
        require(_value <= _balances[msg.sender], 'Envision: insufficient balance');
        
        _balances[msg.sender] = SafeMath.sub(_balances[msg.sender], _value);
        
        uint256 remainFee = totalFeePercent - burnWalletFee - poolWalletFee - marketingWalletFee;
        _balances[_to] = _balances[_to].add(_value.mul(remainFee).div(totalFeePercent));
        _balances[burnWalletAdress] = _balances[burnWalletAdress].add(_value.mul(burnWalletFee).div(totalFeePercent));
        _balances[poolWalletAddress] = _balances[poolWalletAddress].add(_value.mul(poolWalletFee).div(totalFeePercent));
        _balances[marketingWalletAddress] = _balances[marketingWalletAddress].add(_value.mul(marketingWalletFee).div(totalFeePercent));
        
        emit Transfer(msg.sender, _to, _value.mul(remainFee).div(totalFeePercent));
        
        return true;
    }

   function balanceOf(
       address _owner
    ) public override view returns (uint256 balance) 
    {
        return _balances[_owner];
    }

    function approve(
       address _spender, 
       uint256 _value
    ) public override
      returns (bool) 
    {
        _allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
   }

   function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) public override
      returns (bool) 
    {
        require(_from != address(0), 'Envision: from address is not valid');
        require(_to != address(0), 'Envision: to address is not valid');
        require(_value <= _balances[_from], 'Envision: insufficient balance');
        require(_value <= _allowed[_from][msg.sender], 'Envision: from not allowed');

        _balances[_from] = SafeMath.sub(_balances[_from], _value);
        uint256 remainFee = totalFeePercent - burnWalletFee - poolWalletFee - marketingWalletFee;
        _balances[_to] = _balances[_to].add(_value.mul(remainFee).div(totalFeePercent));
        _balances[burnWalletAdress] = _balances[burnWalletAdress].add(_value.mul(burnWalletFee).div(totalFeePercent));
        _balances[poolWalletAddress] = _balances[poolWalletAddress].add(_value.mul(poolWalletFee).div(totalFeePercent));
        _balances[marketingWalletAddress] = _balances[marketingWalletAddress].add(_value.mul(marketingWalletFee).div(totalFeePercent));
        
        _allowed[_from][msg.sender] = SafeMath.sub(_allowed[_from][msg.sender], _value);
        
        emit Transfer(_from, _to, _value.mul(remainFee).div(totalFeePercent));
        
        return true;
   }

    function allowance(
        address _owner, 
        address _spender
    ) public override view 
      returns (uint256) 
    {
        return _allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender, 
        uint _addedValue
    ) public
      returns (bool)
    {
        _allowed[msg.sender][_spender] = SafeMath.add(_allowed[msg.sender][_spender], _addedValue);
        
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        
        return true;
    }

    function decreaseApproval(
        address _spender, 
        uint _subtractedValue
    ) public
      returns (bool) 
    {
        uint oldValue = _allowed[msg.sender][_spender];
        
        if (_subtractedValue > oldValue) {
            _allowed[msg.sender][_spender] = 0;
        } else {
            _allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        
        return true;
   }

    function mint(
        address _to,
        uint _amount
    ) public onlyOwner
    {
        require(_to != address(0), 'Envision: to address is not valid');
        require(_amount > 0, 'Envision: amount is not valid');
        require(_totalSupply + _amount <= _maxSupply, 'Envision: max supply limited');

        _totalSupply = _totalSupply.add(_amount);
        _balances[_to] = _balances[_to].add(_amount);

        emit Mint(msg.sender, _to, _amount);
    }

    function burn(
        address _from,
        uint _amount
    ) public
        onlyOwner
    {
        require(_from != address(0), 'Envision: from address is not valid');
        require(_balances[_from] >= _amount, 'Envision: insufficient balance');
        
        _balances[_from] = _balances[_from].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);

        emit Burn(msg.sender, _from, _amount);
    }

}