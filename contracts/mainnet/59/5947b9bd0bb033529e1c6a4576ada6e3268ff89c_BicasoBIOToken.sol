pragma solidity ^0.4.24;
interface tokenRecipient{
    function receiveApproval(address _from,uint256 _value,address _token,bytes _extraData) external ;
}
contract BicasoBIOToken{
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public sellPrice;
    uint256 public buyPrice;
    bool public sellOpen;
    bool public buyOpen;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address=>bool) public frozenAccount;
    event Transfer(address indexed from,address indexed to , uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event FrozenFunds(address target,bool freeze);
    event SellToken(address seller,uint256 sellPrice, uint256 amount,uint256 getEth);
    event BuyToken(address buyer,uint256 buyPrice,uint256 amount,uint256 spendEth);
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
     constructor() public {
        owner = 0x28F1DdeC2218ec95b14076127a7AdE2F2986E4A6;
        name = "BICASO";
        symbol = "BIO";
        decimals = 8;
        totalSupply = 5000000000 * 10 ** uint256(8);
        balanceOf[owner] = totalSupply;
    }
	function () public payable {  
     if(msg.sender!=owner){
         _buy();    
     }
	}
    function transfer(address _to,uint256 _value) public{
        require(!frozenAccount[msg.sender]);
        if(_to == address(this)){
          _sell(msg.sender,_value);
        }else{
            _transfer(msg.sender,_to,_value);
        }
    }
    function transferFrom(address _from,address _to,uint256 _value) public returns (bool success){
        require(!frozenAccount[_from]&&!frozenAccount[msg.sender]);
        require(_value<=allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        if(_to == address(this)){
            _sell(_from,_value);
        }else
        {
            _transfer(_from,_to,_value);
        }
        
        return true;
    }
    function approve(address _spender,uint256 _value) public returns (bool success){
        require(!frozenAccount[msg.sender]);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function approveAndCall(address _spender,uint256 _value,bytes _extraData)
    public returns (bool success){
        require(!frozenAccount[msg.sender]);
        tokenRecipient spender = tokenRecipient(_spender);
        if(approve(_spender,_value)){
            spender.receiveApproval(msg.sender,_value,this,_extraData);
            return true;
        }
    }
    function freezeAccount(address target,bool freeze)  onlyOwner public{
        require(target!=owner);
        frozenAccount[target] = freeze;
        emit FrozenFunds(target,freeze);
    }
    function transferOwnership(address newOwner) onlyOwner public{
        _transfer(owner,newOwner,balanceOf[owner]);
        owner = newOwner;
    }
    function setPrices(uint256 newSellPrice,uint256 newBuyPrice) onlyOwner public{
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function setBuyOpen(bool newBuyOpen) onlyOwner public{
        require(buyPrice>0);
        buyOpen = newBuyOpen;
    }
    function setSellOpen(bool newSellOpen) onlyOwner public{
        require(sellPrice>0);
        sellOpen = newSellOpen;
    }
    function transferEth(uint256 amount) onlyOwner public{
        msg.sender.transfer(amount*10**uint256(18));
    }
    function _transfer(address _from,address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from]+balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from,_to,_value);
        assert(balanceOf[_from]+balanceOf[_to] == previousBalances);
    }
    function _buy() internal returns (uint256 amount){
        require(buyOpen);
        require(buyPrice>0);
        require(msg.value>0);
        amount = msg.value / buyPrice;
        _transfer(owner,msg.sender,amount);
        emit BuyToken(msg.sender,buyPrice,amount,msg.value);
        return amount;
    }
    function _sell(address _from,uint256 amount) internal returns (uint256 revenue){
        require(sellOpen);
        require(!frozenAccount[_from]);
        require(amount>0);
        require(sellPrice>0);
        require(_from!=owner);
        _transfer(_from,owner,amount);
        revenue = amount * sellPrice;
        _from.transfer(revenue);
        emit SellToken(_from,sellPrice,amount,revenue);
        return revenue;
    }
}