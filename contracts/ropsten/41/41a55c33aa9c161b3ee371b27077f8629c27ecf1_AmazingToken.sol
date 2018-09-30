pragma solidity ^0.4.11;
contract AmazingToken{
    
    uint256 public totalSupply;
    
    mapping (address => uint256) balances;
    
    modifier onlyValidAddress(address _to){
        require(_to != address(0x00));
        _;
    }
    
    modifier onlyValidValue(address _from,uint256 _value){
        require(_value <= balances[_from]);
        _;
    }
    
    function () public payable {
        uint256 _issued = (msg.value*100)/10**18;
        totalSupply += _issued;
        balances[msg.sender] = _issued;
    }
    
    function balanceOf(address _owner) constant public 
    returns(uint256){
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) 
    onlyValidAddress(_to) onlyValidValue(msg.sender,_value) public 
    returns(bool){
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }
    
}



pragma solidity ^0.4.11;
contract AmazingTokenInterface{
    uint256 public totalSupply;
    function () public payable;
    function balanceOf(address _owner)
    constant public returns(uint256);
    function transfer(address _to, uint256 _value)
    public returns(bool);
}
contract AmazingDex {
    AmazingTokenInterface AmazingToken;
    address ChiroWallet = 0xf54f8439F5d9845b0f452Fe4F06d667c29921695;
    
    uint256 public rate = 100;
    modifier onlyValidAddress(address _to){
        require(_to != address(0x00));
        _;
    }
    
    modifier onlyChiro(){
        require(msg.sender == ChiroWallet);
        _;
    }
    
    function setRate(uint256 _rate)
    onlyChiro public returns(uint256){
        rate = _rate;
        return rate;
    }
    
    function AmazingDex(address _amazingTokenAddress) 
    onlyValidAddress(_amazingTokenAddress) public {
        AmazingToken = AmazingTokenInterface(_amazingTokenAddress);
    }
    function buyToken()
    onlyValidAddress(msg.sender) public payable {
        uint256 _value = (msg.value*rate)/10**18;
        assert(AmazingToken.transfer(msg.sender, _value));
        ChiroWallet.transfer(msg.value);
    }
}