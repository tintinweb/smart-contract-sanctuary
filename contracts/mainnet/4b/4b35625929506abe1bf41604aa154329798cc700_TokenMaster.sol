/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16 <0.5.17;

// based on MyAdvancedToken8,2017-2021, inspired by parity sampleContract, Consensys-ERC20 and openzepelin

contract TokenMaster {
    address internal masterCopy;

    bytes32 internal name32;
    uint256 private ownerPrices;                                                // buyPrice, sellPrice, owner address

    mapping(address => uint256)                     private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    // -------------------------------------------------------------
    
    uint256 constant k_buyPr       = 1 ether / 1000000;                         // price per share
    uint256 constant k_sellPr      = k_buyPr - (k_buyPr/10);
    uint256 constant k_sellBuy     = uint256( (uint256(uint256(k_buyPr)<<160) + uint256(uint256(k_sellPr)<<208)) & k_pMask );
    
    uint256 private _guardCounter  = 1;
    
    uint256 constant contractShare = uint256(1000000*10*2);                     // 10% contract reserve
    uint256 constant contractShare2= uint256(1000000*10*1);
    
    uint256 constant provision     = uint256(1111100*2);                        // 1.11% provision
    uint256 constant provision2    = uint256(1111100*1);
    
    uint256 constant k_aMask       = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_sMask       = 0xffffffffffff0000000000000000000000000000000000000000000000000000;
    uint256 constant k_bMask       = 0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_mask        = 0x0000000000000000000000000000000000000000000000000000ffffffffffff;
    uint256 constant k_pMask       = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_frozenFlag  = 0x0000000000000000000000000000000000000000000000000000000000000001;
    uint256 constant k_shareMask   = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;

    address constant k_add00       = address(0x0);
    address constant k_provisonRec = address(0x00ec140832E635eF2f5786C60a55cc83eAf8D59d);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);
    event Deployment(address owner, address theContract);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    modifier nonReentrant() {
      _guardCounter += 1;
      uint256 localCounter = _guardCounter;
      _;
      require(localCounter == _guardCounter,"re-entrance attack prohibited. Yeah!");
    }
    
    function owner() external view returns (address ow) {
      return address(uint160(ownerPrices & k_aMask));
    }
    
    function name() external view returns (string memory) {
      return bytes32ToStr(name32);
    }
    
    function standard() external pure returns (string memory std) {
      return 'ERC-20';
    }
    
    function symbol() external pure returns (string memory sym) {
      return 'shares';
    }
    
    function decimals() external pure returns (uint8 dec) {
      return  2;
    }
    
    function totalSupply() external pure returns (uint256 spl) {
      return 1000000;
    }
    
    function sellPrice() external view returns (uint256 sp) {
      return uint256( (uint256( ownerPrices & k_sMask )>>208) & k_mask );
    }
    
    function buyPrice() external view returns (uint256 bp) {
      return uint256( (uint256( ownerPrices & k_bMask )>>160) & k_mask );
    }
    
    function balanceOf(address tokenOwner) external view returns (uint thebalance) {
      return balances[tokenOwner]>>1;
    }
    
    function frozen(address tokenOwner) external view returns (bool isFrozen) {
      return (uint256(balances[tokenOwner] & k_frozenFlag) > 0);
    }
    
    function tokenAllow(address tokenOwner,address spender) external view returns (uint256 tokens) {
      return allowed[tokenOwner][spender];
    }
    
    function saveOwner(uint256 buyP,uint256 sellP,address own) private pure returns (bytes32 o) {
      return bytes32( uint256(uint256(buyP)<<160) + uint256(uint256(sellP)<<208) + uint256(uint160(own)) );
    }
    
    function char(byte b) private pure returns (byte c) {
        if (uint8(b) < uint8(10)) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function b_String(bytes32 _bytes32, uint len, bool isString) private pure returns (string memory) {
        uint8 off = 0;
        if (isString) off = 2;
        bytes memory s = new bytes((len*2)+off);

        if (isString) {
          s[0] = 0x30;
          s[1] = 0x78;
        }
      
        uint8 count = 0;
        
        for (uint i = 0; i < len; i++) {
            byte b = byte(uint8(uint(_bytes32) / (2 ** (8 * ((len-1) - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[off+(2 * i)] = char(hi);
            s[off+(2 * i) + 1] = char(lo);
            count++;
        }
        
        return string(s);
    }
    
    function mb32(bytes memory _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(add(_data, 32))
      }
    }
    
    function bytes32ToStr(bytes32 _b) internal pure returns (string memory)
    { 
      bytes memory bArr = new bytes(32); 
      for (uint256 i;i<32;i++) { bArr[i] = _b[i]; } 
      return string(bArr); 
    }  
    
    function approve_v2d(address spender, uint tokens) external {
        require(uint256(balances[msg.sender] & k_frozenFlag)==0,"account frozen!");
        require(allowed[msg.sender][spender] == 0, "approve = 0 required!");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
    }
    
    function transfer_G8l(address toReceiver, uint amount) external {
        uint balSender = balances[msg.sender];
        require(uint256(balSender & k_frozenFlag)==0,"account frozen!");
        
        require(balSender>>1 >= amount,"not enough token!");
        uint bal = balances[toReceiver]>>1;
        require(bal + amount >= bal,"overflow error!");
        balances[msg.sender] -= amount<<1;
        balances[toReceiver] += amount<<1;
        
        emit Transfer(msg.sender, toReceiver, amount);
    }
    
    function transferFrom_78S(address from, address toReceiver, uint amount) external {
        require(uint256(balances[msg.sender] & k_frozenFlag)==0,"account frozen!");

        require(allowed[from][msg.sender] >= amount,"allowance too small");
        allowed[from][msg.sender] -= amount;
        
        require(balances[from]>>1 >= amount,"not enough token!");
        uint bal = balances[toReceiver]>>1;
        require(bal + amount >= bal,"overflow error!");
        balances[from] -= amount<<1;
        balances[toReceiver] += amount<<1;

        emit Transfer(from, toReceiver, amount);
    }
    
    function transferOwnership_m0(address newOwner) external {
        uint256 oPrices = ownerPrices;
        require(msg.sender == address(uint160(oPrices & k_aMask)),"only owner");
        ownerPrices =  uint256(oPrices & k_pMask) + uint256(uint160(newOwner));
    }
    
    function freezeAccount_16R(address target, bool freeze) external {
        require(msg.sender == address(uint160(ownerPrices & k_aMask)),"only owner");
        uint b = balances[target];
        b = b-uint256(b%2);
        if (!freeze||target==k_provisonRec) balances[target] = uint256(b); else balances[target] = uint256(b+1);
        emit FrozenFunds(target, freeze);
    }

    function setPrices_7d4(uint256 newSellPrice, uint256 newBuyPrice) external {
        address o = address(uint160(ownerPrices & k_aMask));
        require(msg.sender == o,"only owner");
        ownerPrices = uint256(newBuyPrice<<160) + uint256(newSellPrice<<208) + uint256(o);
    }
      
    function buy_uae() payable external nonReentrant {
        require(msg.value>0,"value 0!");
        
        uint bal = balances[msg.sender];
        require(uint256(bal & k_frozenFlag)==0,"account frozen!");
        
        uint256 ownPrices = ownerPrices;
        uint256 bPrice    = uint256( (uint256( ownPrices & k_bMask )>>160) & k_mask );
        
        require(msg.value>0&&bPrice>0,"value/price 0");
        uint amount = uint256(msg.value / bPrice);
        
        require(balances[address(this)]>>1 >= amount,"not enough token!");
        require((bal>>1) + (amount<<1) >= (bal>>1),"overflow error!");
        balances[address(this)] -= amount<<1;
        balances[msg.sender]    += amount<<1;

        emit Transfer(address(this), msg.sender, amount);
    }

    function sell_LA2(uint256 amount) external nonReentrant {
        uint bal = balances[msg.sender];
        require(uint256(bal & k_frozenFlag)==0,"account frozen!");
        
        uint256 ownPrices = ownerPrices;
        uint256 sPrice    = uint256( (uint256( ownPrices & k_sMask )>>208) & k_mask );

        require(amount>0&&sPrice>0,"value/price 0");
        require(bal>>1 >= amount,"not enough token!");
        
        bal = balances[address(this)]>>1;
        require(bal+amount >= bal,"overflow error!");
        balances[msg.sender] -= amount<<1;
        balances[address(this)] += amount<<1;

        msg.sender.transfer(amount * sPrice);
        emit Transfer(msg.sender, address(this), amount);
    }
    
    function newToken(uint256[] calldata _data) external payable nonReentrant
    {
        uint l = _data.length-1;
        require(l<=31 && l>=2,"2-31 owners only");

        ownerPrices = k_sellBuy + uint256(uint160(msg.sender) & k_aMask);        
        name32      = bytes32(_data[l]);

        address    iOwner;
        uint256    iShare;
        
        uint i=0;
        do {
          iOwner = address(uint160(_data[i] & k_aMask));
          iShare = uint256(uint256(_data[i] & k_pMask)>>159) & k_shareMask;          
          require((iShare != 0) && (iOwner != k_add00),"Illegal owner/share in list.");
          
          balances[iOwner] = iShare;
          emit Transfer(address(this), iOwner, iShare>>1);
          
          i++;
        } while(i<l);

        balances[address(this)] = contractShare;                                // +10.00% token for proxyToken contract
        emit Transfer(k_add00, address(this), contractShare2);
        
        balances[k_provisonRec] = provision;                                    // + 1.11% token provision
        emit Transfer(k_add00, k_provisonRec, provision2);
    }

    function() external payable {
      if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }
    
    constructor (bytes32 tokenName) public payable
    { 
        name32      = tokenName;
        ownerPrices = k_sellBuy + uint256(uint160(msg.sender) & k_aMask);
        emit Deployment(msg.sender, address(this));
    }
}