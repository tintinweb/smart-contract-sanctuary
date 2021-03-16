/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16 <0.5.17;

// based on MyAdvancedToken8,2017-2021, inspired by parity sampleContract, Consensys-ERC20 and openzepelin

contract TokenMaster {
    address internal masterCopy;

    string  public constant standard    = 'ERC-20';
    string  public constant symbol      = "shares";
    uint8   public constant decimals    = 2;
    uint256 public constant totalSupply = 1000000;

    string  public name;
    address public owner;
    bytes32 public dHash;

    mapping (address => bool)    public frozenAccount;
    mapping (address => uint256) public balances;
    mapping (address => mapping  (address => uint256)) public allowed;

    uint256 public sellPrice = 20000;
    uint256 public buyPrice  = 20000;

    // -------------------------------------------------------------
    
    uint256 private _guardCounter = 1;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);
    event Deployment(address owner, address theContract);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event NewProxyToken(address sender,address TokenProxy);


    modifier nonReentrant() {
      _guardCounter += 1;
      uint256 localCounter = _guardCounter;
      _;
      require(localCounter == _guardCounter);
    }
        
    modifier validRequirement(uint ownerCount) {
        require(ownerCount <= 31 && ownerCount >= 2,"2-31 owners only");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"only owner");
        _;
    }
    
    function move(address from, address to, uint amount) internal {
        require(balances[from] >= amount);
        require(balances[to] + amount >= balances[to]);
        balances[from] -= amount;
        balances[to] += amount;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint thebalance) {
        return balances[tokenOwner];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
        
    function approve(address spender, uint tokens) public returns (bool success) {
        require(!frozenAccount[msg.sender],"account frozen!");
        require(allowed[msg.sender][spender] == 0, "");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address toReceiver, uint amount) public returns (bool success) {
      require(!frozenAccount[msg.sender],"account frozen!");
      move(msg.sender, toReceiver, amount);
      emit Transfer(msg.sender, toReceiver, amount);
      return true;
    }
    
    function transferFrom(address from, address toReceiver, uint amount) public returns (bool success) {
        require(!frozenAccount[msg.sender],"account frozen!");
        require(allowed[from][msg.sender] >= amount,"allowance too small");
        allowed[from][msg.sender] -= amount;
        move(from, toReceiver, amount);
        emit Transfer(from, toReceiver, amount);
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

    function buy() payable public nonReentrant returns (bool success) {
        require(msg.value>0,"value 0!");
        require(!frozenAccount[msg.sender],"account frozen!");
        require(msg.value>0&&sellPrice>0&&buyPrice>0,"value/price 0");
        uint amount = uint256(msg.value / buyPrice);
        move(address(this), msg.sender, amount);
        emit Transfer(address(this), msg.sender, amount);
        return true;
    }

    function sell(uint256 amount) external nonReentrant returns (bool success) {
        require(!frozenAccount[msg.sender],"account frozen!");
        require(amount>0&&sellPrice>0&&buyPrice>0,"value/price 0");
        move(msg.sender, address(this), amount);
        msg.sender.transfer(amount * sellPrice);
        emit Transfer(msg.sender, address(this), amount);
        return true;
    }
    
  	function() external payable {
  		if (msg.value > 0) emit Deposit(msg.sender, msg.value);
  	}
    
    function newToken(
        bytes32 _domainHash,
        address[] memory _owners,
        uint256[] memory _shares,
        string memory tokenName
    ) public payable validRequirement(_owners.length) returns (bool success)
    {
        dHash  = _domainHash;
        owner  = msg.sender;
        name   = tokenName;

        for (uint i=0; i<_owners.length; i++) {
          require(_owners[i] != address(0x0), "Illegal owner in list.");
          require(_shares[i] != 0, "Illegal share in list.");
          balances[_owners[i]] = _shares[i];
          emit Transfer(address(this), _owners[i], _shares[i]);
        }

        balances[address(this)] = uint256(totalSupply*10);                      // +10% token for proxyToken contract
        emit Transfer(address(0x0), address(this), uint256(totalSupply*10));

        emit NewProxyToken(msg.sender, address(this));
        return true;
    }
    
    constructor (
        bytes32 _domainHash,
        address[] memory _owners,
        uint256[] memory _shares,
        string memory tokenName
    ) public payable validRequirement(_owners.length)
    {
        dHash = _domainHash;
        owner  = msg.sender;
        name   = 'TokenMasterContract';
        
        for (uint i=0; i<_owners.length; i++) {
          require(_owners[i] != address(0x0), "Illegal owner in list.");
          require(_shares[i] != 0, "Illegal share in list.");
        }

        emit Deployment(msg.sender, address(this));
    }
}