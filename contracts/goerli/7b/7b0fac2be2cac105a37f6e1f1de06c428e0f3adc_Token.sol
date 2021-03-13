/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16 <0.5.17;

contract IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

contract Token is IERC20 {
    // based on MyAdvancedToken8,2017-2021, based on parity sampleContract, consensys ERC20 and openzepelin-contracts
        
    address public owner;
    uint256 public sellPrice = 95;
    uint256 public buyPrice  = 100;

    mapping (address => bool)    public frozenAccount;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping  (address => uint256)) public allowance;
    mapping (address => bool)    public isOwner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);
    event Deployment(address owner, address theContract);

    string  public standard = 'ERC-20';
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;
    
    modifier validRequirement(uint ownerCount) {
        require(ownerCount <= 31 && ownerCount >= 2, "only 2-31 owners");
        _;
    }
    
    modifier notNull(address _address) {
        require(_address != address(0x0),"address = 0x0 error");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"only owner");
        _;
    }
  
    modifier balanced(uint256 _val) {
        require(balanceOf[msg.sender] >= _val,"balance low");
        _;
    }
  
    modifier notFrozen(address _from) {
        require(!frozenAccount[_from],"frozen account");
        _;
    }
  
    modifier avoidOverflow(address _to,uint256 _val) {
        require(balanceOf[_to] + _val >= balanceOf[_to],"overflow error");
        _;
    }
    
    modifier avoidUnderflow(address _addr,uint256 _val) {
        require(balanceOf[_addr] - _val < balanceOf[_addr],"underflow error");
        _;
    }
      
    modifier sellBuyPrices(uint256 amount) {
        require(amount>0&&sellPrice>0&&buyPrice>0,"value/price 0");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function approve(address _spender, uint256 _value) public 
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function transfer(address _to, uint256 _value) public balanced(_value) notFrozen(msg.sender) avoidOverflow(_to,_value) avoidUnderflow(msg.sender,_value) returns (bool success) {
        balanceOf[msg.sender] -= _value;                                        // Subtract from the sender
        balanceOf[_to] += _value;                                               // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                                 // Notify anyone listening
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public balanced(_value) notFrozen(_from) avoidOverflow(_to,_value) avoidUnderflow(_from,_value) returns (bool success) {
        if (_value > allowance[_from][msg.sender]) revert("not allowed");       // Check allowance
        require(_to != address(0),"bad address");

        balanceOf[_from] -= _value;                                             // Subtract from the sender
        balanceOf[_to]   += _value;                                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice  = newBuyPrice;
    }

    function buy() payable public sellBuyPrices(msg.value) avoidOverflow(msg.sender,msg.value / buyPrice) avoidUnderflow(address(this),msg.value / buyPrice) {
        require(msg.value>0,"value 0!");
        uint amount = msg.value / buyPrice;                                     // calculates the amount
        if (balanceOf[address(this)] < amount) revert("bad token balance");     // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                                        // adds the amount to buyer's balance
        balanceOf[address(this)] -= amount;                                     // subtracts amount from seller's balance
        emit Transfer(address(this), msg.sender, amount);                       // execute an event
    }

    function sell(uint256 amount) public sellBuyPrices(amount) avoidOverflow(address(this),amount) avoidUnderflow(msg.sender,amount) balanced(amount) {
        bool sendSUCCESS;
        balanceOf[address(this)] += amount;                                     // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                                        // subtracts the amount from seller's balance
        
        sendSUCCESS = msg.sender.send(amount * sellPrice);
        if (!sendSUCCESS) {                                                     // sends ether to the seller. It's important
            revert("send token failed");                                        // to do this last to avoid recursion attacks
        } else {
            emit Transfer(msg.sender, address(this), amount);                   // executes an event
        }               
    }
    
  	function() external payable {
  		if (msg.value > 0) emit Deposit(msg.sender, msg.value);
  	}
    
    constructor (
        uint256 initialSupply,
        address[] memory _owners,
        uint256[] memory _shares,
        uint8 decimalUnits,
        string memory tokenName,
        string memory tokenSymbol
    ) public payable validRequirement(_owners.length)
    {
        owner = msg.sender;
        
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0x0), "Illegal owner in owners list.");
            require(_shares[i] != 0, "Illegal share in list.");
            isOwner[_owners[i]] = true;
            balanceOf[_owners[i]] = _shares[i];
            emit Transfer(address(this), _owners[i], _shares[i]);
        }

        balanceOf[address(this)] = initialSupply/10;                            // Give token contract +10% tokens
        emit Transfer(address(0x0), address(this), initialSupply/10);

        totalSupply = initialSupply;                                            // Update total supply
        name        = tokenName;
        symbol      = tokenSymbol;
        decimals    = decimalUnits;
        
        emit Deployment(msg.sender, address(this));
    }
}