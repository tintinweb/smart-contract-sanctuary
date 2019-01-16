pragma solidity ^0.4.25;
contract TokenERC20 {

    address public creator;

    function TokenERC20() public{
        creator=msg.sender;
    }
    modifier onlyCreator{
        require(msg.sender==creator);
        _;
    }

    function updateCreator(address newCreator) onlyCreator public{
        creator = newCreator;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

 contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    uint256 public total;
    
    struct Lock{
        uint256 time;
        uint256 number;
    }
    
    mapping(address=>Lock) public locks;
    
    mapping (address => bool) public frozenAccount;
    
    mapping(address=>uint256) public balanceOf;
    
    mapping(address=>mapping(address=>uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Burn(address indexed from, uint256 value);
    
    function MyToken(string tokenName,string tokenSymbol,uint256 tokenTotal) public {
        
        name = tokenName;
        symbol = tokenSymbol;
        total=tokenTotal*10**uint256(decimals);
        balanceOf[msg.sender]=total;
    }
    
    function _transfer(address _from,address _to,uint256 _value) internal{
        require(_to!=0x0 && balanceOf[_from]>_value && balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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
    
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        total -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        total -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    
    function totalSupply() constant  public returns (uint256 totalSupply){
        return total;
    }
}
contract LYB is MyToken,TokenERC20{
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    
    
    event FrozenFunds(address target, bool frozen);

    function LYB(string tokenName,string tokenSymbol,uint256 tokenTotal) MyToken(tokenName, tokenSymbol,tokenTotal) public {}
    
     function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) public returns(bool){
       if(msg.sender!=creator){
          if(locks[msg.sender].time>=block.timestamp){
              require((balanceOf[msg.sender]-_value)/1000000000000000000>=locks[msg.sender].number);
          }
           
       }
        _transfer(msg.sender, _to, _value); 
    }
    function lock(address _to,uint256 _time,uint256 _number)  public{
        require(msg.sender==creator);
        locks[_to].time=_time;
        locks[_to].number = _number;
    }
     function mintToken(address target, uint256 mintedAmount) onlyCreator public {
        balanceOf[target] += mintedAmount;
        total += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    function freezeAccount(address target, bool freeze) onlyCreator public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyCreator public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function buy() payable public {
        uint amount = msg.value / buyPrice;               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }
}