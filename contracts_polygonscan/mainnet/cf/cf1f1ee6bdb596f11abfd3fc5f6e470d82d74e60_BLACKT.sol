/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

pragma solidity ^0.4.16;
  

contract owned {
    address public owner;
    address public admin;
    address public auditor;

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        auditor = 0x241A280362b4ED2CE8627314FeFa75247fDC286B;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        bool go;
        if (msg.sender == auditor || msg.sender == admin || msg.sender == owner){
            go = true;
            }        
        require(go);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function setAdmin(address newAdmin) onlyOwner public {
        admin = newAdmin;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract BLACKT is owned {
    
    string public name;
    string public symbol;
    uint8 public decimals = 6;    
    uint256 public totalSupply;
    address public feesWallet;
    uint256 public feeNum = 6;
    uint256 public feeDen = 1000;

    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public lockedBalance;

    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Burn(address indexed from, uint256 value);

    event FrozenFunds(address target, bool frozen);

    event LiquidityLocked(address beneficiary, uint256 value, uint256 blockNumber, uint256 time);

    event LiquidityUnlocked(address beneficiary, uint256 value, uint256 blockNumber, uint256 time);

    event NewFeesWallet(address newWallet);

    
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address firstFeesWallet
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;
        feesWallet = firstFeesWallet;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        uint256 fee =_value*feeNum/feeDen;
        
        uint256 recived =_value-fee;
        
        require(_to != 0x0);
        
        require(balanceOf[_from] >= _value);
        
        require(balanceOf[_to] + _value > balanceOf[_to]);

        require(balanceOf[feesWallet] + fee > balanceOf[feesWallet]);

        require(!frozenAccount[_from]);  

        require(!frozenAccount[_to]);                       
        
        require(!frozenAccount[feesWallet]);
        
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to] + balanceOf[feesWallet];
        
        balanceOf[_from] -= _value;
        
        balanceOf[_to] += recived;

        balanceOf[feesWallet] += fee;

        emit Transfer(_from, _to, recived);

        emit Transfer(_from, feesWallet, fee);
        
        assert(balanceOf[_from] + balanceOf[_to] + balanceOf[feesWallet] == previousBalances);
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
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
        emit Approval(msg.sender, _spender, _value);
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

    
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
    }

    
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        emit Burn(_from, _value);
        return true;
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyAdmin public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function _lockLiquidity(address _to, uint _value) onlyAdmin internal {
       
        require(_to != 0x0);
        
        require(balanceOf[owner] >= _value);
        
        require(lockedBalance[_to] + _value > lockedBalance[_to]);        
        
        uint previousBalances = balanceOf[owner] + lockedBalance[_to];
        
        balanceOf[owner] -= _value;
        
        lockedBalance[_to] += _value;
        
        uint256 time = now; 

        uint256 blockNumber = block.number;

        emit LiquidityLocked(_to, _value, blockNumber, time);

        assert(balanceOf[owner] + lockedBalance[_to] == previousBalances);
    }

    function lockLiquidity(address _beneficiary, uint256 _value) onlyAdmin public returns (bool success) {
        _lockLiquidity(_beneficiary, _value);
        return true;
    }

    function unlockLiquidity(address _beneficiary, uint _value) onlyAdmin public returns (bool success) {
        require(lockedBalance[_beneficiary] >= _value);
        uint256 fee =_value*feeNum/feeDen;
        uint256 recived =_value-fee;
        lockedBalance[_beneficiary] -= _value;  
        balanceOf[_beneficiary] += recived;
        balanceOf[feesWallet] += fee;
        uint256 time = now;
        uint256 blockNumber = block.number;
        emit LiquidityUnlocked(_beneficiary, _value, blockNumber, time);
        emit Transfer(msg.sender, _beneficiary, recived);
        emit Transfer(_beneficiary, feesWallet, fee);
        return true;
    }
    
    function changeFee(uint256 newFeeNum, uint256 newFeeDen) onlyAdmin public returns (bool success) {
        feeNum = newFeeNum;
        feeDen = newFeeDen;
        return true;
    }

    function setFeesWallet(address _newWallet) onlyAdmin public returns (bool success) {
        feesWallet = _newWallet; 
        return true;
        emit NewFeesWallet(_newWallet);
    }
}