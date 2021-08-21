/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity ^0.6.0;

interface Token {

    //function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract EcommToken is Token {
    string  public name = "Ecommerce Token";
    string  public symbol = "ECTK";
    string  public standard = "Ecommerce Token v1.0";
    uint256 private totalSupply = 100;
    uint256 public leftSupply = 100;
    uint256 public tokenPrice = 1;
    address public contractOwner;
    uint256 amountTobuy;
    uint256 dexBalance;

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
    
    event Bought(address _buyer, uint256 amount);
    
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public whoPaid;


    // Crea il token e assegna alle variabili "name", "symbol" e "totalSupply"
    // i loro valori che definiscono il contratto
    constructor () public {
        balanceOf[address(this)] = totalSupply;
        contractOwner = 0x0cbdC5cFfE55D6E2dB656123607F78c80Ba86C3D;
    }

    // Funzione per trasferire i token a un indirizzo
    // è richiesto solo che il balance del mittente sia superiore a quanto vuole trasferire
    function transfer(address _to, uint256 _value) public override returns (bool success){
        
        require(leftSupply >= _value);

        //whoPaid[msg.sender] = msg.value;
        //contractOwner.send(msg.value);
        leftSupply -= _value;
        balanceOf[_to] += _value;
        emit Transfer(address(this), _to, _value);
        return true;

    }
    
    /*function buy(uint256  _numberOfTokens) payable public {
        require(msg.value == _numberOfTokens);
	    amountTobuy = msg.value;
	    //dexBalance = token.balanceOf(address(this));
	    require(amountTobuy > 0, "You need to send some ether");
	    //require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
	    transfer(msg.sender, amountTobuy);
	    emit Bought(msg.sender , amountTobuy);
	}*/
    // Funzione dedicata all'acquisto dei token da parte degli utenti
    // ogni utente compra "n-token" che poi vengono salavati sul proprio wallet personale
    /*function buyToken(uint256 _numberOfTokens) payable public {
        require(msg.value == _numberOfTokens);
        transfer(msg.sender, _numberOfTokens);
        whoPaid[msg.sender] = msg.value;
        contractOwner.send(msg.value);
        leftSupply -= _numberOfTokens;
    }*/

    // Approva il trasferimento a un inidirizzo "xy"
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Funzioni che servono a "delegre" il trasferimento dei token
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
    
    function getTknPrice() public view returns (uint256) {
        return tokenPrice;
    }
    
    function setBalance(address _to, uint256 _value) public {
        balanceOf[_to] += _value;
    }
}


contract DappTokenSale {
    address payable admin;
    EcommToken public ecommToken;
    uint256 public tokenPrice;
    uint256 public tokensSold;
    uint public current;
    uint public chainStartTime;
    
    address public addressEcommToken;

    event Sell(address _buyer, uint256 _amount);

    constructor() public {
        admin = msg.sender;
    }
    
    function setEcommTknAddress(address _addressEcommToken) public{
        addressEcommToken = _addressEcommToken;
    }
    
    function getPrice() public  returns (uint256) {
        EcommToken ecommToken = EcommToken(addressEcommToken);
        tokenPrice =  ecommToken.getTknPrice();
    }
    
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable returns (bool success) {
        EcommToken ecommToken = EcommToken(addressEcommToken);
        require(msg.value == _numberOfTokens);
        //require(ecommToken.balanceOf(address(this)) >= _numberOfTokens);
        require(ecommToken.transfer(msg.sender, _numberOfTokens));
        //current = address(this).balance;
        chainStartTime = block.timestamp;
        //tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
        return true;
    }

    function endSale() public {
        require(msg.sender == admin);
        require(ecommToken.transfer(admin, ecommToken.balanceOf(address(this))));

        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin
        admin.transfer(address(this).balance);
    }
}



contract DEX {

    event Bought(uint256 amount);
    event Sold(uint256 amount);


    Token public token;

    constructor() public {
        token = new EcommToken();
    }

    function buy() payable public {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some Ether");
        //require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }

    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        msg.sender.transfer(amount);
        emit Sold(amount);
    }

}