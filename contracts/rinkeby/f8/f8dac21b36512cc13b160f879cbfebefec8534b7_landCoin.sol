/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity 0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    //require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 


contract landCoin is owned{
    //=======Declaration=========
    
    using SafeMath for uint256;
    string constant private _name = 'landCoin';
    string constant private _symbol = 'LND';
    uint256 constant private _decimals = 18;
    uint256 private _totalSupply = 10000000000 * (10**_decimals); 
    uint256 constant public _maxsupply = 10000000000 * (10**_decimals);  
    bool public safeguard;
    
    mapping(address => uint256) private _balanceof;
    mapping(address => mapping(address =>uint256)) public _allowance;
    mapping(address => bool) public _flozenAccount;
    
    //============Events============
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Burn(address indexed from, uint256 value);
    
    event FlozenAccount(address indexed targetaccount, bool flozen);
    
    event Approve(address indexed from, address indexed sender, uint256 amount);
    
    //============ ERC20 function========
    
    function name() public pure returns(string memory){
        return _name;
        
    }
    
    function symbol() public pure returns(string memory){
        return _symbol;
        
    }
    
     function decimals() public pure returns(uint256){
        return _decimals;
        
    }
    
     function totalSupply() public view returns(uint256){
         
        return _totalSupply;
        
    }
    
     function balanceOF(address user) public view returns(uint256){
         
        return _balanceof[user];
        
    }
    
    function allowance(address owner, address spender) public view returns(uint256){
        
        return _allowance[owner][spender];
        
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        
     require(!safeguard);
     require(_to != address(0));
     require(!_flozenAccount[_from]);
     require(!_flozenAccount[_to]);
     
     _balanceof[_from] = _balanceof[_from].sub(_value);
     _balanceof[_to] = _balanceof[_to].add(_value);
     
     emit Transfer(_from,_to,_value);
    }
    
    function transfer(address _to, uint256 _value) public returns(bool success){
        
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        _transfer(_from,_to,_value);
        return true;
    }
    
    function _approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
        _allowance[msg.sender][_spender]=_value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }
    
    function changeSafeguardStatus() onlyOwner public{
        
        if(safeguard == false)
            safeguard=true;
        else 
            safeguard=false;
    }
    
    constructor() public{
        
        _balanceof[owner] =_totalSupply;
    }
    
    function() external payable{}
}