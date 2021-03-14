/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16 <0.5.17;

// based on MyAdvancedToken8,2017-2021, inspired by parity sampleContract, Consensys-ERC20 and openzepelin

contract TokenMaster {
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);
    event Deployment(address owner, address theContract);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    string public standard = 'ERC-20';
    uint256 private _guardCounter = 1;

    mapping (address => address) public theowner;
    mapping (address => mapping  (address => bool))    public frozenAccount;
    mapping (address => mapping  (address => uint256)) public balances;
    mapping (address => mapping  (address => mapping  (address => uint256))) public allowed;

    mapping (address => string)   public nm;
    mapping (address => string)   public symb;
    mapping (address => uint8)    public dec;
    mapping (address => uint256)  public sply;
    
    mapping (address => uint256)  public sellP;
    mapping (address => uint256)  public buyP;


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
        require(msg.sender == theowner[msg.sender],"only owner");
        _;
    }
    
    function move(address from, address to, uint amount) internal {
        address o = theowner[msg.sender];
        require(balances[o][from] >= amount);
        require(balances[o][to] + amount >= balances[o][to]);
        balances[o][from] -= amount;
        balances[o][to] += amount;
    }

    function name() public view returns (string memory) {
        return nm[ theowner[msg.sender] ];
    }

    function symbol() public view returns (string memory) {
        return symb[ theowner[msg.sender] ];
    }
    
    function decimals() public view returns (uint8) {
        return dec[ theowner[msg.sender] ];
    }
    
    function totalSupply() public view returns (uint256) {
        return sply[ theowner[msg.sender] ];
    }
    
    function sellPrice() public view returns (uint256) {
        return sellP[ theowner[msg.sender] ];
    }
  
    function buyPrice() public view returns (uint256) {
        return buyP[ theowner[msg.sender] ];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint thebalance) {
        address o = theowner[msg.sender];
        return balances[o][tokenOwner];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        theowner[msg.sender] = newOwner;
    }
        
    function approve(address spender, uint tokens) public returns (bool success) {
        address o = theowner[msg.sender];
        require(!frozenAccount[o][msg.sender],"account frozen!");
        
        require(allowed[o][msg.sender][spender] == 0, "");
        allowed[o][msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address toReceiver, uint amount) public returns (bool success) {
      address o = theowner[msg.sender];
      require(!frozenAccount[o][msg.sender],"account frozen!");
      move(msg.sender, toReceiver, amount);
      emit Transfer(msg.sender, toReceiver, amount);
      return true;
    }
    
    function transferFrom(address from, address toReceiver, uint amount) public returns (bool success) {
        address o = theowner[msg.sender];
        require(!frozenAccount[o][msg.sender],"account frozen!");
        require(allowed[o][from][msg.sender] >= amount,"allowance too small");
        allowed[o][from][msg.sender] -= amount;
        move(from, toReceiver, amount);
        emit Transfer(from, toReceiver, amount);
        return true;
    }
    
    function freezeAccount(address target, bool freeze) public onlyOwner {
        address o = theowner[msg.sender];
        frozenAccount[o][target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellP[ theowner[msg.sender] ] = newSellPrice;
        buyP[ theowner[msg.sender] ] = newBuyPrice;
    }

    function buy() payable public nonReentrant returns (bool success) {
        address o = theowner[msg.sender];
        require(msg.value>0,"value 0!");
        require(!frozenAccount[o][msg.sender],"account frozen!");
        uint256 p = buyP[o];
        require(msg.value>0&&sellP[o]>0&&p>0,"value/price 0");
        uint amount = uint256(msg.value / p);
        move(address(this), msg.sender, amount);
        emit Transfer(address(this), msg.sender, amount);
        return true;
    }

    function sell(uint256 amount) external nonReentrant returns (bool success) {
        address o = theowner[msg.sender];
        uint256 s = sellP[o];
        require(!frozenAccount[o][msg.sender],"account frozen!");
        require(amount>0&&s>0&&buyP[o]>0,"value/price 0");
        move(msg.sender, address(this), amount);
        msg.sender.transfer(amount * s);
        emit Transfer(msg.sender, address(this), amount);
        return true;
    }
    
  	function() external payable {
  		if (msg.value > 0) emit Deposit(msg.sender, msg.value);
  	}
    
    function newToken(
        uint256 initialSupply,
        address[] memory _owners,
        uint256[] memory _shares,
        uint8 decimalUnits,
        string memory tokenName,
        string memory tokenSymbol
    ) public payable nonReentrant validRequirement(_owners.length) returns (bool success)
    {
        require(theowner[msg.sender] == address(0x0), "Token existing!");
        theowner[msg.sender] = msg.sender;
        address o = theowner[msg.sender];

        for (uint i=0; i<_owners.length; i++) {
          require(_owners[i] != address(0x0), "Illegal owner in list.");
          require(_shares[i] != 0, "Illegal share in list.");
          balances[o][_owners[i]] = _shares[i];
          emit Transfer(address(this), _owners[i], _shares[i]);
        }

        balances[o][msg.sender] = uint256(initialSupply/10); // +10% token for proxyToken contract
        emit Transfer(address(0x0), msg.sender, uint256(initialSupply/10));

        sply[msg.sender]     = initialSupply;
        nm[msg.sender]       = tokenName;
        symb[msg.sender]     = tokenSymbol;
        dec[msg.sender]      = decimalUnits;
        sellP[msg.sender]    = 95;
        buyP[msg.sender]     = 100;
        
        //emit Deployment(msg.sender, address(this));
        return true;
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
        require(theowner[msg.sender] == address(0x0), "Token existing!");
        theowner[msg.sender] = msg.sender;
        address o = theowner[msg.sender];


        for (uint i=0; i<_owners.length; i++) {
            require(_owners[i] != address(0x0), "Illegal owner in owners list.");
            require(_shares[i] != 0, "Illegal share in list.");
            balances[o][_owners[i]] = _shares[i];
            emit Transfer(address(this), _owners[i], _shares[i]);
        }

        balances[o][address(this)] = uint256(initialSupply/10); // Give token contract +10% tokens
        emit Transfer(address(0x0), address(this), uint256(initialSupply/10));

        sply[msg.sender]     = initialSupply;
        nm[msg.sender]       = tokenName;
        symb[msg.sender]     = tokenSymbol;
        dec[msg.sender]      = decimalUnits;
        sellP[msg.sender]    = 95;
        buyP[msg.sender]     = 100;
        
        emit Deployment(msg.sender, address(this));
    }
}