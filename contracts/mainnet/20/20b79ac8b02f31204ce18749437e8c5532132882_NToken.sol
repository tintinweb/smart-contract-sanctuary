/**
 *Submitted for verification at Etherscan.io on 2020-05-12
*/

pragma solidity ^0.6.0;

contract NToken {

    address private owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals = 2;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
 
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        _totalSupply = initialSupply  * (10 ** 2);
        _balanceOf[msg.sender] = _totalSupply;
        _name = tokenName;
        _symbol = tokenSymbol;
        owner = msg.sender; 
    }
    
    
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function changeName(string memory newName) public isOwner {
        _name = newName;
    }

    function changeSymbol(string memory newSymbol) public isOwner {
        _symbol = newSymbol;
    }    

    function getOwner() external view returns (address) {
        return owner;
    }
    
    function invent(uint256 _value) public isOwner returns (bool success) {
        _balanceOf[msg.sender] += _value * (10 ** 2);            // Subtract from the sender
        _totalSupply += _value;                      // Updates totalSupply
        return true;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(address(_to) != address(0x0));
        // Check if the sender has enough
        require(_balanceOf[_from] >= _value);
        // Check for overflows
        require(_balanceOf[_to] + _value > _balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = _balanceOf[_from] + _balanceOf[_to];
        // Subtract from the sender
        _balanceOf[_from] -= _value;
        // Add the same to the recipient
        _balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
    }


    function transfer(address _to, uint256 _value) public payable{
        _transfer(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _allowance[_from][msg.sender]);     // Check allowance
        _allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

   
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        _allowance[msg.sender][_spender] = _value;
        return true;
    }


    
    function burn(uint256 _value) public returns (bool success) {
        require(_balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        _balanceOf[msg.sender] -= _value;            // Subtract from the sender
        _totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

   
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= _allowance[_from][msg.sender]);    // Check allowance
        _balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        _allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        _totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
      function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view  returns (uint256) {
        return _balanceOf[account];
    }
    function allowance(address own, address spender) public view returns (uint256) {
        return _allowance[own][spender];
    }
}