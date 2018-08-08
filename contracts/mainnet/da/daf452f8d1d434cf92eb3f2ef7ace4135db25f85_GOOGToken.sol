pragma solidity ^0.4.19;

contract GOOGToken {
    string  public name = "GOOGOL TOKEN";
    string  public symbol = "GOOG";
    string  public standard = "GOOG Token v1.0";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

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

    event Burn(address indexed from, uint256 value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;


    function GOOGToken () public {
    
        uint256 _initialSupply = (2**256)-1;
        
        //totalSupply = _initialSupply;
        totalSupply = _initialSupply;//_initialSupply * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}


contract GOOGTokenSale {
    address admin;
    GOOGToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokenRate;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);

    function GOOGTokenSale(GOOGToken _tokenContract) public {
    
        uint256 _tokenPrice = 1;
        uint256 _tokenRate = 1e54;
        admin = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;//1000000000000000;
        tokenRate = _tokenRate;
    }

    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function divide(uint x, uint y) internal pure returns (uint256) {
        uint256 c = x / y;
        return c;
    }

    //function buyTokens(uint256 _numberOfTokens) public payable {
    function buyTokens() public payable {
        uint256 _numberOfTokens;

        //_numberOfTokens = divide(msg.value , tokenPrice);
        //_numberOfTokens = multiply(_numberOfTokens,1e18);

        _numberOfTokens = multiply(msg.value,tokenRate);


        //require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(this) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));



        tokensSold += _numberOfTokens;
         
          
        Sell(msg.sender, _numberOfTokens);
    }

    // Handle Ethereum sent directly to the sale contract
    function()
        payable
        public
    {
        uint256 _numberOfTokens;

        //_numberOfTokens = divide(msg.value , tokenPrice);
        //_numberOfTokens = multiply(_numberOfTokens,1e18);

        _numberOfTokens = multiply(msg.value,tokenRate);

        //require(msg.value == multiply(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(this) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));



        tokensSold += _numberOfTokens;
         
          
        Sell(msg.sender, _numberOfTokens);
    }


    function setPrice(uint256 _tokenPrice) public {
        require(msg.sender == admin);

        tokenPrice = _tokenPrice;
         
    }

    function setRate(uint256 _tokenRate) public {
        require(msg.sender == admin);

        tokenRate = _tokenRate;
         
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(this)));

        admin.transfer(address(this).balance);
    }

    function withdraw() public {
        require(msg.sender == admin);
        //require(tokenContract.transfer(admin, tokenContract.balanceOf(this)));

        admin.transfer(address(this).balance);
    }

    function withdrawPartial(uint256 _withdrawAmount) public {
        require(msg.sender == admin);
        require(address(this).balance >= _withdrawAmount);
        //require(tokenContract.transfer(admin, tokenContract.balanceOf(this)));

        admin.transfer(_withdrawAmount);
    }
}