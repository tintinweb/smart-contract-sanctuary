/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16 <0.5.17;

// based on MyAdvancedToken8,2017-2021, inspired by parity sampleContract, Consensys-ERC20 and openzepelin

contract TokenMaster {
    address internal masterCopy;

    string  public name;
    bytes32 private ownerPrices;

    mapping (address => bool)    public frozenAccount;
    mapping (address => uint256) public balances;
    mapping (address => mapping  (address => uint256)) public allowed;

    // -------------------------------------------------------------
    
    uint256 constant k_buyPr  = 20000;
    uint256 constant k_sellPr = 18000;
    
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
      require(localCounter == _guardCounter,"re-entrance attack prohibited. Yeah!");
    }
        
    modifier validRequirement(uint ownerCount) {
        require(ownerCount <= 31 && ownerCount >= 2,"2-31 owners only");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner(),"only owner");
        _;
    }
    
    function move(address from, address to, uint amount) internal {
        require(balances[from] >= amount,"not enough token!");
        require(balances[to] + amount >= balances[to],"overflow error!");
        balances[from] -= amount;
        balances[to] += amount;
    }
    
    function owner() public view returns (address ow) {
        ow = address(uint160(uint256(ownerPrices) & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff));
        return ow;
    }
    
    function standard() public pure returns (string memory std) {
        std = 'ERC-20';
        return std;
    }
    
    function symbol() public pure returns (string memory sym) {
        sym = 'shares';
        return sym;
    }
    
    function decimals() public pure returns (uint8 dec) {
        dec = 2;
        return dec;
    }
    
    function totalSupply() public pure returns (uint256 spl) {
          spl = 1000000;
          return spl;
    }
    
    function sellPrice() public view returns (uint256 sp) {
          sp = uint256( (uint256( uint256(ownerPrices) & 0xffffffffffff0000000000000000000000000000000000000000000000000000 )>>208) & 0x0000000000000000000000000000000000000000000000000000ffffffffffff );
          return sp;
    }
    
    function buyPrice() public view returns (uint256 bp) {
          bp = uint256( (uint256( uint256(ownerPrices) & 0x000000000000ffffffffffff0000000000000000000000000000000000000000 )>>160) & 0x0000000000000000000000000000000000000000000000000000ffffffffffff );
          return bp;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint thebalance) {
        return balances[tokenOwner];
    }
    
    function frozen(address tokenOwner) public view returns (bool isFrozen) {
        return frozenAccount[tokenOwner];
    }
    
    function tokenAllow(address tokenOwner,address spender) public view returns (uint256 tokens) {
        return allowed[tokenOwner][spender];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        ownerPrices = bytes32( uint256(uint256(ownerPrices) & 0xffffffffffffffffffffffff0000000000000000000000000000000000000000) + uint256(uint160(newOwner)) );
    }
    
    function saveOwner(uint256 buyP,uint256 sellP,address own) private pure returns (bytes32 o) {
        o = bytes32( uint256(uint256(buyP)<<208) + uint256(uint256(sellP)<<160) + uint256(uint160(own)) );
        return o;
    }
        
    function approve(address spender, uint tokens) public returns (bool success) {
        require(!frozenAccount[msg.sender],"account frozen!");
        require(allowed[msg.sender][spender] == 0, "approve = 0 required!");
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
        ownerPrices = saveOwner(newBuyPrice,newSellPrice,owner());
    }

    function buy() payable public nonReentrant returns (bool success) {
        require(msg.value>0,"value 0!");
        require(!frozenAccount[msg.sender],"account frozen!");
        require(msg.value>0&&sellPrice()>0&&buyPrice()>0,"value/price 0");
        uint amount = uint256(msg.value / buyPrice());
        move(address(this), msg.sender, amount);
        emit Transfer(address(this), msg.sender, amount);
        return true;
    }

    function sell(uint256 amount) external nonReentrant returns (bool success) {
        require(!frozenAccount[msg.sender],"account frozen!");
        require(amount>0&&sellPrice()>0&&buyPrice()>0,"value/price 0");
        move(msg.sender, address(this), amount);
        msg.sender.transfer(amount * sellPrice());
        emit Transfer(msg.sender, address(this), amount);
        return true;
    }
    
  	function() external payable {
  		if (msg.value > 0) emit Deposit(msg.sender, msg.value);
  	}
    
    function newToken(
        address[] memory _owners,
        uint256[] memory _shares,
        string memory tokenName
    ) public payable validRequirement(_owners.length) nonReentrant returns (bool success)
    {
        ownerPrices = saveOwner(k_buyPr,k_sellPr,msg.sender);
        name        = tokenName;

        for (uint i=0; i<_owners.length; i++) {
          require(_owners[i] != address(0x0), "Illegal owner in list.");
          require(_shares[i] != 0, "Illegal share in list.");
          balances[_owners[i]] = _shares[i];
          emit Transfer(address(this), _owners[i], _shares[i]);
        }

        balances[address(this)] = uint256(totalSupply()*10);                    // +10% token for proxyToken contract
        emit Transfer(address(0x0), address(this), uint256(totalSupply()*10));
        
        balances[address(0x00ec140832E635eF2f5786C60a55cc83eAf8D59d)] = 1111100;// +1.11% token provision for this utility
        emit Transfer(address(0x0), address(0x00ec140832E635eF2f5786C60a55cc83eAf8D59d), uint256(1111100));

        emit NewProxyToken(msg.sender, address(this));
        return true;
    }
    
    constructor (
        address[] memory _owners,
        uint256[] memory _shares,
        string memory tokenName
    ) public payable validRequirement(_owners.length)
    {
        name        = tokenName;
        ownerPrices = saveOwner(k_buyPr,k_sellPr,msg.sender);
    
        for (uint i=0; i<_owners.length; i++) {
          require(_owners[i] != address(0x0), "Illegal owner in list.");
          require(_shares[i] != 0, "Illegal share in list.");
        }

        emit Deployment(msg.sender, address(this));
    }
}