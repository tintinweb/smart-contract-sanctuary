/**
 *Submitted for verification at Etherscan.io on 2021-03-15
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
    event NewTokenProxy(address sender,address TokenProxy);

    string public standard = 'ERC-20';
    uint256 private _guardCounter = 1;

    mapping (bytes32 => address) public pAddr;                                  // proxy contract address, owner of proxyToken
    mapping (address => bytes32) public dHash;                                  // domainHash  pAddr [ dHash[ msg.sender ] ]
    
    mapping (bytes32 => mapping  (address => bool))    public frozenAccount;
    mapping (bytes32 => mapping  (address => uint256)) public balances;
    mapping (bytes32 => mapping  (address => mapping  (address => uint256))) public allowed;

    mapping (bytes32 => string)   public nm;
    mapping (bytes32 => string)   public symb;
    mapping (bytes32 => uint8)    public dec;
    mapping (bytes32 => uint256)  public sply;
    
    mapping (bytes32 => uint256)  public sellP;
    mapping (bytes32 => uint256)  public buyP;


    function proxy() view internal returns (address o) {
      return pAddr [ dHash[ msg.sender ] ];
    }

    function pTokenHash() view internal returns (bytes32 h) {
      return dHash[ msg.sender ];
    }

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
        require(msg.sender == proxy(),"only owner");
        _;
    }
    
    function move(address from, address to, uint amount) internal {
        bytes32 o = pTokenHash();
        require(balances[o][from] >= amount);
        require(balances[o][to] + amount >= balances[o][to]);
        balances[o][from] -= amount;
        balances[o][to] += amount;
    }

    function name() public view returns (string memory) {
        return nm[ pTokenHash() ];
    }

    function symbol() public view returns (string memory) {
        return symb[ pTokenHash() ];
    }
    
    function decimals() public view returns (uint8) {
        return dec[ pTokenHash() ];
    }
    
    function totalSupply() public view returns (uint256) {
        return sply[ pTokenHash() ];
    }
    
    function sellPrice() public view returns (uint256) {
        return sellP[ pTokenHash() ];
    }
  
    function buyPrice() public view returns (uint256) {
        return buyP[ pTokenHash() ];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint thebalance) {
        return balances[pTokenHash()][tokenOwner];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pAddr[pTokenHash()] = newOwner;
    }
        
    function approve(address spender, uint tokens) public returns (bool success) {
        bytes32 o = pTokenHash();
        require(!frozenAccount[o][msg.sender],"account frozen!");
        
        require(allowed[o][msg.sender][spender] == 0, "");
        allowed[o][msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address toReceiver, uint amount) public returns (bool success) {
      bytes32 o = pTokenHash();
      require(!frozenAccount[o][msg.sender],"account frozen!");
      move(msg.sender, toReceiver, amount);
      emit Transfer(msg.sender, toReceiver, amount);
      return true;
    }
    
    function transferFrom(address from, address toReceiver, uint amount) public returns (bool success) {
        bytes32 o = pTokenHash();
        require(!frozenAccount[o][msg.sender],"account frozen!");
        require(allowed[o][from][msg.sender] >= amount,"allowance too small");
        allowed[o][from][msg.sender] -= amount;
        move(from, toReceiver, amount);
        emit Transfer(from, toReceiver, amount);
        return true;
    }
    
    function freezeAccount(address target, bool freeze) public onlyOwner {
        bytes32 o = pTokenHash();
        frozenAccount[o][target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellP[ pTokenHash() ] = newSellPrice;
        buyP [ pTokenHash() ] = newBuyPrice;
    }

    function buy() payable public nonReentrant returns (bool success) {
        bytes32 o = pTokenHash();
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
        bytes32 o = pTokenHash();
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
        bytes32 _domainHash,
        uint256 initialSupply,
        address[] memory _owners,
        uint256[] memory _shares,
        uint8 decimalUnits,
        string memory tokenName,
        string memory tokenSymbol
    ) public payable validRequirement(_owners.length) returns (bool success)
    {
        bytes32 o = _domainHash;

        require(pAddr[o] == address(0x0), "Token existing!");
        require(dHash[msg.sender] != _domainHash, "Token domainHash existing!");
        
        address proxySender    = msg.sender;
        
        pAddr[o]               = proxySender;
        dHash[proxySender]     = _domainHash;


        for (uint i=0; i<_owners.length; i++) {
          require(_owners[i] != address(0x0), "Illegal owner in list.");
          require(_shares[i] != 0, "Illegal share in list.");
          balances[o][_owners[i]] = _shares[i];
          emit Transfer(address(this), _owners[i], _shares[i]);
        }

        balances[o][proxySender] = uint256(initialSupply/10); // +10% token for proxyToken contract
        emit Transfer(address(0x0), proxySender, uint256(initialSupply/10));

        sply[o]     = initialSupply;
        nm[o]       = tokenName;
        symb[o]     = tokenSymbol;
        dec[o]      = decimalUnits;
        sellP[o]    = 95;
        buyP[o]     = 100;
        
        emit NewTokenProxy(proxySender, address(this));
        return true;
    }
    
    constructor (
        bytes32 _domainHash,
        uint256 initialSupply,
        address[] memory _owners,
        uint256[] memory _shares,
        uint8 decimalUnits,
        string memory tokenName,
        string memory tokenSymbol
    ) public payable validRequirement(_owners.length)
    {
        pAddr[_domainHash] = msg.sender;
        dHash[msg.sender]  = _domainHash;
        emit Deployment(msg.sender, address(this));
    }
}