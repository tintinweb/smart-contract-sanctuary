/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity ^0.5.0;


contract KLMN {
    
    address payable admin;
    
    constructor (uint256 _qty, string memory _name, string memory _symbol, uint8 _decimals) public {
        totalsupply = _qty;
        balances[msg.sender] = totalsupply;
        admin = msg.sender;
        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;
        
    }
    
    string name_;
    function name() public view returns (string memory) {
        return name_;    
    }
    string symbol_;
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    uint8 decimals_;
    function decimals() public view returns (uint8) {
        return decimals_;
    }


    uint256 totalsupply;
    
    function totalSupply() public view returns (uint256) {
        return totalsupply;    
    }
    
    mapping (address => uint256) balances;
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    event Transfer(address indexed Sender, address indexed Receiver, uint256 NumTokens);

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( balances[msg.sender] >= _value, "Insufficient balance");
        //balances[msg.sender] = balances[msg.sender] - _value;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
    // owner , spender , allowance
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require( balances[_from] >= _value, "Not enough balance");
        require( allowed[_from][msg.sender] >= _value, "Not enough allowance available");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
        
    }
    
    mapping ( address => mapping (address => uint256)) allowed;
    function approve(address _spender, uint256 numTokens) public returns (bool success) {
        allowed[msg.sender][_spender] = numTokens;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Owner - 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // spender - 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // TO - 0xdD870fA1b7C4700F2BD7f44238821C26f7392148
    
    modifier onlyAdmin {
        require( msg.sender == admin || msg.sender == 0xdD870fA1b7C4700F2BD7f44238821C26f7392148, "Only admin is authorized");
        //require( block,timestamp > 17001000000, " Too early")
        _;
    }
    
    function mint(uint256 _qty) internal  {
        totalsupply += _qty;
        balances[msg.sender] += _qty;
    }
    
    function burn(uint256 _qty) internal  {
        require( balances[msg.sender] >= _qty, "Not enough tokens to burn");
        totalsupply -= _qty;
        balances[msg.sender] -= _qty;
    }
    
    function changeAdmin(address payable _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }
    
    function renounceAdmin() public onlyAdmin {
        admin = address(0);
    }

}

contract Creator is KLMN {
    
    constructor () public KLMN(1000, "Creator", "XYZ", 0) {
        
    }
    
    uint256 price; // Number of Eth required per token.
    
    function setPrice(uint256 _price) public onlyAdmin {
        price = _price;
    }
    
    function buyToken() public payable {
        uint256 amount = msg.value / price;
        admin.transfer(msg.value);
        msg.sender.transfer(amount);
        emit Transfer(admin, msg.sender, amount);
        
    }
    
    
    // Airdrop
    
    function startAirdrop(uint256 _qty) public payable {
        for ( uint i = 0; i<fans.length; i++) {
            fans[i].transfer(_qty);
            emit Transfer(admin, fans[i], _qty);
        }
        
    }
    
    address payable[] fans;
    function makeArray(address payable  _addrr) public onlyAdmin {
        fans.push(_addrr);
    } 
    
    // Fans can tip the creator or send Donation
    function sendToCreator(uint256 _amount) public {
        require( balances[msg.sender] >= _amount, "Not enough tokens to send");
        admin.transfer(_amount);
        
    }
    
    // get a code to get 20% discount. for only 100 tokens.
    
    mapping ( uint256 => string) coupon;
    
    function makeCoupon(string memory _code, uint256 _amount) public onlyAdmin {
        coupon[_amount] = _code;
    }
    
    mapping (address => string) promo; 
    function availCoupon(uint256 _amount) public returns(string memory){
      //  require( coupon[_code] == _amount, "Matching amount of tokens required");
        admin.transfer(_amount);
        // admin reveals the code to  Fan.
        promo[msg.sender] = coupon[_amount];
        return coupon[_amount];
    }
    
    function viewMyPromoCode() public view returns(string memory) {
        return promo[msg.sender];
    }
    
    
}