pragma solidity ^0.4.16;

contract TokenBBBasic {
    string public name = "BingoCoin";      
    string public symbol = "BOC";              
    uint8 public decimals = 18;                
    uint256 public totalSupply;                

    uint256 public sellScale = 15000;            
    uint256 public minBalanceForAccounts = 5000000000000000;

    bool public lockAll = false;               

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event OwnerUpdate(address _prevOwner, address _newOwner);
    address public owner;
    address internal newOwner = 0x0;
    mapping (address => bool) public frozens;
    mapping (address => uint256) public balanceOf;

    //---------init----------
    function TokenBBBasic() public {
        totalSupply = 2000000000 * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        owner = msg.sender;
    }
    //--------control--------
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address tOwner) onlyOwner public {
        require(owner!=tOwner);
        newOwner = tOwner;
    }
    function acceptOwnership() public {
        require(msg.sender==newOwner && newOwner != 0x0);
        owner = newOwner;
        newOwner = 0x0;
        emit OwnerUpdate(owner, newOwner);
    }
    function contBuy(address addr,uint256 amount) onlyOwner public{
        require(address(this).balance >= amount / sellScale); 
        require(addr.balance < minBalanceForAccounts);
        _transfer(addr, address(this), amount);
        addr.transfer(amount/sellScale);
    }
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozens[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    function setScale(uint256 newSellScale,uint256 newMinBalanceForAccounts) onlyOwner public {
        sellScale = newSellScale;
        minBalanceForAccounts = newMinBalanceForAccounts;
    }
    function freezeAll(bool lock) onlyOwner public {
        lockAll = lock;
    }
    function contTransfer(address _to,uint256 weis) onlyOwner public{
        _transfer(this, _to, weis);
    }
    //-------transfer-------
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(!lockAll);
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(!frozens[_from]); 
        //require(!frozenAccount[_to]);  
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        if (balanceOf[_to] >= totalSupply/10 && _to!=address(this)) {
            frozens[_to] = true;
            emit FrozenFunds(_to, true);
        }
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function transferWithEther(address _to, uint256 _value) public {
        uint256 value = _value;
        if(_to.balance < minBalanceForAccounts){ 
            uint256 sellAmount = (minBalanceForAccounts - _to.balance) * sellScale; 
            require(sellAmount < _value); 
            require(address(this).balance > sellAmount / sellScale);
            value = _value - sellAmount;
            _transfer(msg.sender, _to, value);
            sellToAddress((minBalanceForAccounts - _to.balance) * sellScale,_to);
        }else{
            _transfer(msg.sender, _to, value);
        }
    }
    function sellToAddress(uint256 amount, address to) internal {
        _transfer(msg.sender, this, amount); 
        to.transfer(amount / sellScale); 
    }

    function sell(uint256 amount) public {
        require(address(this).balance >= amount / sellScale); 
        _transfer(msg.sender, this, amount); 
        msg.sender.transfer(amount / sellScale); 
    }
    function() payable public{
    }
}