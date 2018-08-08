pragma solidity ^0.4.24;
interface tokenRecipient{
    function receiveApproval(address _from,uint256 _value,address _token,bytes _extraData) external ;
}
contract DiverseCurrencyCirculationEcosystem{
    //public var
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public sellPrice; //grow to wei not eth!
    uint256 public buyPrice;
    bool public sellOpen;
    bool public buyOpen;
    
    //store token data set
    mapping(address => uint256) public balanceOf;
    //transition limite
    mapping(address => mapping(address => uint256)) public allowance;
    //freeze account 
    mapping(address=>bool) public frozenAccount;
    
    //event for transition
    event Transfer(address indexed from,address indexed to , uint256 value);
    //event for allowance
    event Approval(address indexed owner,address indexed spender,uint256 value);
    //event for freeze/unfreeze Account 
    event FrozenFunds(address target,bool freeze);
    //TODO event for sell token , do&#39;t need it now
    event SellToken(address seller,uint256 sellPrice, uint256 amount,uint256 getEth);
    //TODO event for buy token , do&#39;t need it now 
    event BuyToken(address buyer,uint256 buyPrice,uint256 amount,uint256 spendEth);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    //func constructor
    constructor() public {
        owner = 0xc22F305B804a7AD7684eC4BB07A0553BDf4d51c7;
        name = "DCEGL";
        symbol = "DCEGL";
        decimals = 18;
        totalSupply = 8600000000 * 10 ** uint256(18);
        
        //init totalSupply to map(db)
        balanceOf[owner] = totalSupply;
    }
    
 function () public payable {  
     if(msg.sender!=owner){
         _buy();    
     }
 }
 
    // public functions
    // 1 Transfer tokens 
    function transfer(address _to,uint256 _value) public{
        require(!frozenAccount[msg.sender]);
        if(_to == address(this)){
          _sell(msg.sender,_value);
        }else{
            _transfer(msg.sender,_to,_value);
        }
    }
    
    // 2 Transfer Other&#39;s tokens ,who had approve some token to me 
    function transferFrom(address _from,address _to,uint256 _value) public returns (bool success){
        //validate the allowance 
        require(!frozenAccount[_from]&&!frozenAccount[msg.sender]);
        require(_value<=allowance[_from][msg.sender]);
        //do action :sub allowance and do transfer 
        allowance[_from][msg.sender] -= _value;
        if(_to == address(this)){
            _sell(_from,_value);
        }else
        {
            _transfer(_from,_to,_value);
        }
        
        return true;
    }
    //A is msg.sender or i 
    //B is the person who has approve me to use his token or _from 
    //C is the receipient or _to
    
    // 3 set allowance for other address,like B approve A(_spender) to use his token
    function approve(address _spender,uint256 _value) public returns (bool success){
        require(!frozenAccount[msg.sender]);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    // 4 allowance and notify the receipient/spender 
    function approveAndCall(address _spender,uint256 _value,bytes _extraData)
    public returns (bool success){
        require(!frozenAccount[msg.sender]);
        tokenRecipient spender = tokenRecipient(_spender);
        if(approve(_spender,_value)){
            spender.receiveApproval(msg.sender,_value,this,_extraData);
            return true;
        }
    }
    
    // onlyOwner function 
    // 11 freeze or unfreeze account 
    function freezeAccount(address target,bool freeze)  onlyOwner public{
        require(target!=owner);
        frozenAccount[target] = freeze;
        emit FrozenFunds(target,freeze);
    }
    // 12 transfer contract  Ownership to newOwner and transfer all balanceOf oldOwner to newOwner
    function transferOwnership(address newOwner) onlyOwner public{
        _transfer(owner,newOwner,balanceOf[owner]);
        owner = newOwner;
    }
    // 13 set prices for sellPrice or buyPrice
    function setPrices(uint256 newSellPrice,uint256 newBuyPrice) onlyOwner public{
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    // 14 open/close user to  buy token 
    function setBuyOpen(bool newBuyOpen) onlyOwner public{
        require(buyPrice>0);
        buyOpen = newBuyOpen;
    }
    // 15 open/close user to  sell token 
    function setSellOpen(bool newSellOpen) onlyOwner public{
        require(sellPrice>0);
        sellOpen = newSellOpen;
    }
    // 16 transfer eth back to owner 
    function transferEth(uint256 amount) onlyOwner public{
        msg.sender.transfer(amount*10**uint256(18));
    }
    
    //internal transfer function
 // 1 _transfer
    function _transfer(address _from,address _to, uint256 _value) internal {
        //validate input and other internal limites
        require(_to != 0x0);//check to address
        require(balanceOf[_from] >= _value);//check from address has enough balance 
        require(balanceOf[_to] + _value >balanceOf[_to]);//after transfer the balance of _to address is ok ,no overflow
        uint256 previousBalances = balanceOf[_from]+balanceOf[_to];//store it for add asset to power the security
        //do transfer:sub from _from address,and add to the _to address
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        //after transfer: emit transfer event,and add asset for security
        emit Transfer(_from,_to,_value);
        assert(balanceOf[_from]+balanceOf[_to] == previousBalances);
    }
 // 2 _buy 
    function _buy() internal returns (uint256 amount){
        require(buyOpen);
        require(buyPrice>0);
        require(msg.value>0);
        amount = msg.value / buyPrice;                    // calculates the amount
        _transfer(owner,msg.sender,amount);
        emit BuyToken(msg.sender,buyPrice,amount,msg.value);
        return amount;                                    // ends function and returns
    }
    
    // 3 _sell 
    function _sell(address _from,uint256 amount) internal returns (uint256 revenue){
        require(sellOpen);
        require(!frozenAccount[_from]);
        require(amount>0);
        require(sellPrice>0);
        require(_from!=owner);
        _transfer(_from,owner,amount);
        revenue = amount * sellPrice;
        _from.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit SellToken(_from,sellPrice,amount,revenue);
        return revenue;                                   // ends function and returns
    }
}