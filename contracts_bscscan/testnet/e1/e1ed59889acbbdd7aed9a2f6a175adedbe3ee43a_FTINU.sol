/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

pragma solidity ^0.5.10;

/*
___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_


=== 'FTINU' Token contract with following features ===
    => BEP20 Compliance
    => SafeMath implementation 
    => owner can freeze any wallet to prevent fraud
    => Burnable 


======================= Quick Stats =====================

    => Name        : FTINU
    => Symbol      : FTINU
    => Max supply  : 100,000,000,000,000
    => Decimals    : 8

============= Independant Audit of the code ==============

    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program

-------------------------------------------------------------------
 Copyright (c) 2021 onwards FT INU
-------------------------------------------------------------------
*/ 


//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//

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
    require(b <= a, 'SafeMath sub failed');
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

    

    function transferOwnership(address payable _newOwner) public {
        require(msg.sender == owner);
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//

contract FTINU is owned {
    
    using SafeMath for uint256;

    string constant private _name = "FTINU";
    string constant private _symbol = "FTINU";
    uint256 constant private _decimals = 8;
    uint256 private _totalSupply;                       
    uint256 constant public maxSupply = 100000000000000 * (10**_decimals);
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event FrozenAccounts(address target, bool frozen);
    event Approval(address indexed from, address indexed spender, uint256 value);
    
    address public minerContract;
    address public dexContract;
    bool public dexContractChangeLock;
    
    constructor() public{ }
    
    function name() public pure returns(string memory){
        return _name;
    }
    
    function symbol() public pure returns(string memory){
        return _symbol;
    }
    
    function decimals() public pure returns(uint256){
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address user) public view returns(uint256){
        return _balanceOf[user];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require (_to != address(0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        
        // overflow and undeflow checked by SafeMath Library
        _balanceOf[_from] = _balanceOf[_from].sub(_value);    // Subtract from the sender
        _balanceOf[_to] = _balanceOf[_to].add(_value);        // Add the same to the recipient
        
        // emit Transfer event
        emit Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //no need to check for input validations, as that is ruled by SafeMath
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //checking of allowance and token value is done by SafeMath
        //we want to pre-approve system contracts so that it does not need to ask for approval calls
        if(msg.sender != minerContract && msg.sender != dexContract){
            _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        }
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {

        /* AUDITOR NOTE:
            Many dex and dapps pre-approve large amount of tokens to save gas for subsequent transaction. This is good use case.
            On flip-side, some malicious dapp, may pre-approve large amount and then drain all token balance from user.
            So following condition is kept in commented. It can be be kept that way or not based on client's consent.
        */
        //require(_balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function increase_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }
    
    function decrease_allowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {

        //checking of enough token balance is done by SafeMath
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
    
    function freezeAccount(address target, bool freeze) public {
        require(msg.sender == owner);
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
    
    function setMinerContract(address _minerContract) external returns(bool){
        require(msg.sender == owner);
        require(_minerContract != address(0), 'Invalid address');
        minerContract = _minerContract;
        return true;
    }
    
    function mintTokens(address receipient, uint256 tokenAmount) external returns(bool){
        require(msg.sender == minerContract, 'Invalid caller');
        require(_totalSupply.add(tokenAmount) <= maxSupply, 'Max supply reached');
        
        _balanceOf[receipient] = _balanceOf[receipient].add(tokenAmount);
        _totalSupply = _totalSupply.add(tokenAmount);
        emit Transfer(address(0), receipient, tokenAmount);
        
        return true;
    }
    
    function setDexContract(address _dexContract) external returns(bool){
        require(msg.sender == owner);
        require(_dexContract != address(0), 'Invalid address');
        require(!dexContractChangeLock, 'Dex contrat can not be changed');
        dexContractChangeLock=true;
        dexContract = _dexContract;
        return true;
    }
    
    
    
}