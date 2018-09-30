pragma solidity ^0.4.24;

contract Owner {
    address public owner;

    constructor() public {
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

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes _extraData)
    external;
}

contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    constructor(
        string _tokenName,
        string _tokenSymbol,
        uint8 _decimals,
        uint256 _totalSupply) public {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value) internal {
        require(_to != 0x0);
        require(_from != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(
        address _to,
        uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        
        allowance[_from][msg.sender] -= _value;
        
        _transfer(_from, _to, _value);
        
        return true;
    }

    function approve(
        address _spender,
        uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        
        return true;
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            
            return true;
        }
    }

    function burn(
        uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        Burn(msg.sender, _value);

        return true;
    }

    function burnFrom(
        address _from,
        uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(_from, _value);

        return true;
    }
}

contract Stamps is Owner, ERC20Token {
    constructor(
        string _tokenName,
        string _tokenSymbol,
        uint8 _decimals,
        uint256 _totalSupply)
        ERC20Token(_tokenName, _tokenSymbol, _decimals, _totalSupply) public {
    }

    function transferStmpsToOwnerAccount(
        address _from,
        uint256 _value) onlyOwner public {
        _transfer(_from, owner, _value);
    }
}


contract STMPTokenSale is Owner {
     
    Stamps STMPToken;

    uint256 public ETH_PRICE;  // in USD CENTs
    uint256 public STMP_PRICE;  // in USD CENTs
    uint256 public STMPTokenDecimals;

    event TranserETH(string successMessage);

    constructor(address contractAddress, uint256 decimals, uint256 ethPrice, uint256 stmpPrice) public {
        STMPToken = Stamps(contractAddress);
        STMPTokenDecimals = decimals;
        ETH_PRICE = ethPrice;
        STMP_PRICE = stmpPrice;
    }

    function calcAmount(uint256 _value) internal view returns (uint256) {
        return (((_value ) * ETH_PRICE));
    }
   
    function buyTokens(address contributor) payable public returns(uint256) {
        require(msg.value > 0);
        uint256 amount = calcAmount(msg.value);
        uint256 tokens = calcTokens(amount);
        STMPToken.transfer(contributor, tokens/1 ether);
        
        return STMPToken.balanceOf(contributor);
    }
    
    function getSTMPDecimals() view public returns(uint256){
        return STMPTokenDecimals;
    }

    function calcTokens(uint256 _value) internal view returns(uint256){
        return (_value / STMP_PRICE) * 10 ** getSTMPDecimals();
    }
  
    function setETHPrice(uint256 amount) onlyOwner public {
        ETH_PRICE = amount;
    }
  
    function setSTMPPrice(uint256 amount) onlyOwner public {
        STMP_PRICE = amount;
    }
    
    function withdrawETH(uint256 amount) onlyOwner public {
        require(address(this).balance > 0);
        require(address(this).balance>=amount * 1 wei);
        if(owner.send(amount * 1 wei)){
            emit TranserETH("Ehters Sent to Owner account successfully");
        } else {
            revert();
        }
    }

    function withdrawTokens(uint256 amount) onlyOwner public {
        require(amount > 0);
        uint256 tokens = calcTokens(amount);
        STMPToken.transfer(owner, tokens);
    }

    function() payable internal{
        buyTokens(msg.sender);
    }
    
    function getETHBalance() view public returns(uint256){
        return this.balance;
    }
}