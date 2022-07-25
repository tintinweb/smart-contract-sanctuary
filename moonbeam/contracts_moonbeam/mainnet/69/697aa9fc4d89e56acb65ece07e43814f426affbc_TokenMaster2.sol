/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9 <0.8.10;

// ungravel.eth, GroupWallet, GroupWalletMaster, GroupWalletFactory, ProxyWallet, TokenMaster, ProxyToken by pepihasenfuss.eth 2017-2022, Copyright (c) 2022

// GroupWallet and ungravel is entirely based on Ethereum Name Service, "ENS", the domain name registry.
// inspired by parity sampleContract, Consensys-ERC20 and openzeppelin smart contracts

//   ENS, ENSRegistryWithFallback, PublicResolver, Resolver, FIFS-Registrar, Registrar, AuctionRegistrar, BaseRegistrar, ReverseRegistrar, DefaultReverseResolver, ETHRegistrarController,
//   PriceOracle, SimplePriceOracle, StablePriceOracle, ENSMigrationSubdomainRegistrar, CustomRegistrar, Root, RegistrarMigration are contracts of "ENS", by Nick Johnson. ENS-License:
//
//   Copyright (c) 2018, True Names Limited
//
//   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


interface AbstractGWP {
  function getIsOwner(address _owner)      external view returns (bool);
  function getOwners()                     external view returns (address[] memory);
  function getTransactionsCount()          external view returns (uint);
  function getTransactionRecord(uint _tNb) external view returns (uint256);
  function getGWF() external view returns (address);
  function getAllTransactions() external view returns (uint256[] memory transArr);
}

contract AbstractBaseR {
  event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
  event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
  event NameRenewed(uint256 indexed id, uint expires);

  bytes32 public baseNode;                                                      // The namehash of the TLD this registrar owns (eg, .eth)
}

interface AbstractENS {
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
  event Transfer(bytes32 indexed node, address owner);
  event NewResolver(bytes32 indexed node, address resolver);
  event NewTTL(bytes32 indexed node, uint64 ttl);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function setSubnodeRecord(bytes32 node, bytes32 label, address sub_owner, address sub_resolver, uint64 sub_ttl) external;
  function setOwner(bytes32 node, address set_owner) external;
  function owner(bytes32 node) external view returns (address);
  function recordExists(bytes32 node) external view returns (bool);
}

interface AbstractResolver {
  event AddrChanged(bytes32 indexed node, address a);
  event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
  event NameChanged(bytes32 indexed node, string name);
  event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
  event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
  event ContenthashChanged(bytes32 indexed node, bytes hash);

  function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
  function addr(bytes32 node) external view returns (address payable);
  function text(bytes32 node, string calldata key) external view returns (string memory);
  function name(bytes32 node) external view returns (string memory);

  function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
  function setAddr(bytes32 node, address r_addr) external;
  function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
  function setName(bytes32 node, string calldata _name) external;
  function setText(bytes32 node, string calldata key, string calldata value) external;
  function setAuthorisation(bytes32 node, address target, bool isAuthorised) external;
}

abstract contract AbstractRR {
  AbstractResolver public defaultResolver;
  function node(address addr) external pure virtual returns (bytes32);
}

interface AbstractDefaultRR {
  function node(address addr) external pure returns (bytes32);
}

interface AbstractReverseRegistrar {
  function claim(address owner) external returns (bytes32);
  function claimWithResolver(address owner, address resolver) external returns (bytes32);
  function setName(string memory name) external returns (bytes32);
  function node(address addr) external pure returns (bytes32);
}

abstract contract AbstractGWF {
  AbstractResolver                public  resolverContract;
  AbstractENS                     public  ens;
  AbstractBaseR                   public  base;
  AbstractRR                      public  reverseContract;

  function getProxyToken(bytes32 _domainHash) external view virtual returns (address p);
  function getGWProxy(bytes32 _dHash) external view virtual returns (address);
  function getIsOwner(bytes32 _dHash,address _owner) external view virtual returns (bool);
  function domainReport(string calldata _dom,uint command) external payable virtual returns (uint256 report, address gwpc, address ptc, address gwfc, bytes memory structure);
  function getGWF() external view virtual returns (address);
}

abstract contract AbstractTM {
  address internal masterCopy;

  bytes32 internal name32;
  uint256 private ownerPrices;                                                  // buyPrice, sellPrice, owner address

  mapping(address => uint256)                     private balances;
  mapping(address => mapping(address => uint256)) private allowed;

  function getMemberBalances(bytes32 hash,address gwfc) external view virtual returns (uint[] memory);
  function balanceOf(address tokenOwner) external view virtual returns (uint thebalance);
  function sellPrice() external view virtual returns (uint256 sp);
  function buyPrice() external view virtual returns (uint256 bp);
  function name() external view virtual returns (string memory);
}


contract TokenMaster2 {
    address internal masterCopy;

    bytes32 internal name32;
    uint256 private ownerPrices;                                                // buyPrice, sellPrice, owner address

    mapping(address => uint256)                     private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    // -------------------------------------------------------------
    
    uint256 constant k_buyPr       = 1 ether / 10000;                           // price per share
    uint256 constant k_sellPr      = k_buyPr - (k_buyPr/10);
    uint256 constant k_sellBuy     = uint256( (uint256(uint256(k_buyPr)<<160) + uint256(uint256(k_sellPr)<<208)) & k_pMask );
    
    uint256 private _guardCounter  = 1;
    
    uint256 constant contractShare = uint256(1000000*10*2);                     // 10% ProxyToken contract reserve, 10% GroupWallet contract reserve
    uint256 constant contractShare2= uint256(1000000*10*1);
        
    uint256 constant k_aMask       = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_sMask       = 0xffffffffffff0000000000000000000000000000000000000000000000000000;
    uint256 constant k_bMask       = 0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_mask        = 0x0000000000000000000000000000000000000000000000000000ffffffffffff;
    uint256 constant k_pMask       = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_frozenFlag  = 0x0000000000000000000000000000000000000000000000000000000000000001;
    uint256 constant k_shareMask   = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;

    address constant k_add00       = address(0x0);

    event TestReturn(uint256 v1, uint256 v2, uint256 v3, uint256 v4);
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
    

    // ----------------------- ERC20 -------------------------------------------

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
      return 120000000;
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
    
    function getResolverReport(bytes32 hash) external view returns (address rslv_owner, address gwp, bytes memory abi32_, bytes memory abi128_, address[] memory GWPowners ) 
    {
      AbstractGWF gwfc = AbstractGWF(address(uint160(ownerPrices & k_aMask)));  // GWF - GroupWalletFactory contract
      AbstractGWP gwpc = AbstractGWP(gwfc.getGWProxy(hash));
      
      (uint256 ignore1, bytes memory abi32 ) = gwfc.resolverContract().ABI(hash,32 );
      (uint256 ignore2, bytes memory abi128) = gwfc.resolverContract().ABI(hash,128);
      
      ignore1 = ignore1 + ignore2;
      
      return (gwfc.ens().owner(hash), address(gwpc), abi32, abi128, gwpc.getOwners());
    }
    
    function tokenReportBalances(bytes32 hash) external view returns (uint256[] memory tokenR, address[] memory GWPowners, uint[] memory balArr )
    {      
      address gwfc  = address(uint160(ownerPrices & k_aMask));                  // GWF - GroupWalletFactory contract
      address gwpc  = AbstractGWF(gwfc).getGWProxy(hash);                       // GWP - GroupWalletProxy contract
      
      GWPowners = AbstractGWP(gwpc).getOwners();
      
      uint256[] memory token = new uint256[](10);
      
      token[0] = uint256(uint160(gwfc));
      token[1] = uint256(uint160(gwpc));
      token[2] = 2;
      token[3] = uint256( (uint256( ownerPrices & k_sMask )>>208) & k_mask );
      token[4] = uint256( (uint256( ownerPrices & k_bMask )>>160) & k_mask );
      token[5] = uint256(balances[address(this)]>>1);
      token[6] = uint256(balances[gwpc]>>1);
      token[7] = uint256(bytes32(name32 | 0x2000000000000000000000000000000000000000000000000000000000000000));
      token[8] = uint256(gwpc.balance);
      token[9] = uint256(address(this).balance);
      
      balArr = AbstractTM(address(this)).getMemberBalances(hash,gwfc);

      return ( token, GWPowners, balArr );
    }
    
    function getMemberBalances(bytes32 hash, address gwfc) external view returns (uint[] memory)
    {
      address gwpc = AbstractGWF(gwfc).getGWProxy(hash);                        // GWP - GroupWalletProxy contract
      address ptc  = AbstractGWF(gwfc).getProxyToken(hash);                     // PT  - ProxyToken contract
      address[] memory l_ownerArr = AbstractGWP(gwpc).getOwners(); // owners
      
      require(l_ownerArr.length>=2, "Bad owners array!");
      
      uint m = l_ownerArr.length*2;
      uint t = AbstractGWP(gwpc).getTransactionsCount();
      uint[] memory balArr = new uint[](m+t);
      
      uint[] memory tArr = AbstractGWP(gwpc).getAllTransactions();
      
      address memAddr;
      uint i=0;
      do {
        memAddr = l_ownerArr[i];
        
        balArr[i*2]     = uint(memAddr.balance);                                // ETH or GLMR, native crypto currency of chain
        balArr[(i*2)+1] = uint(AbstractTM(ptc).balanceOf(memAddr));             // shares of TokenProxy contract
        
        i++;
      } while(i<l_ownerArr.length&&i<31);

      if ((t==0) || (tArr.length==0)) return balArr;

      i=0;
      do {
        balArr[i+m] = uint256(tArr[i]);
        i++;
      } while(i<tArr.length);

      return balArr;
    }
    
    function getNodeHash(string memory dn,address gwfc) internal view returns (bytes32 hash) {
      
      hash = keccak256( abi.encodePacked( AbstractBaseR(AbstractGWF(gwfc).base()).baseNode(), keccak256( substring( bytes(dn), delArr(dn)[0]+1, delArr(dn)[1] - delArr(dn)[0] -1 ) ) ) ); // domain e.g. 'ethereum-foundation'
      hash = keccak256( abi.encodePacked( hash,                                               keccak256( substring( bytes(dn), 0, delArr(dn)[0] ) ) ) );                                  // label e.g.  'vitalik'
      
      return hash;
    }

    function getMemberReverseRecords(address gwpc, address gwfc) private view returns (uint256 result) 
    {
      address[] memory owners = AbstractGWP(gwpc).getOwners();                  // owners() - taken from GWPC
      bytes32 node;
      string memory nm;
      result = 0;
      uint256 m = 1;
      uint256 n = 256;
      uint256 l = 65536;

      for (uint i = 0; i < owners.length; i++) {
        node = AbstractGWF(gwfc).reverseContract().node(owners[i]);
        nm   = AbstractResolver(AbstractRR(AbstractGWF(gwfc).reverseContract()).defaultResolver()).name( node );
        
        if ( uint256(mb32(bytes( nm ))) > 0 ) {
          result += m;
        
          if ( bytes( AbstractGWF(gwfc).resolverContract().text( getNodeHash( nm,gwfc ),'me_photo')     ).length > 0) result += n;
          if ( bytes( AbstractGWF(gwfc).resolverContract().text( getNodeHash( nm,gwfc ),'me_statement') ).length > 0) result += l;
        }
      
        m = m*2;
        n = n*2;
        l = l*2;
      }
      
      return uint256( result );
    }
    
    function getDomainReport(string calldata _domain, address gwfc, bytes32 hash) external payable returns (uint256[] memory token, bytes memory structure, address[] memory GWPowners, uint[] memory balArr, bytes memory abi128_)
    {
      {
        if (address(gwfc) == address(k_add00))                                  return (new uint256[](0), bytes("gwfc"),           new address[](0), new uint[](0), bytes("gwfc"));
        if (address(gwfc)!=address(AbstractGWF(gwfc).getGWF()))                 return (new uint256[](0), bytes("gwfc - invalid"), new address[](0), new uint[](0), bytes("gwfc - invalid"));
      }
      
      (uint256 report_, address gwpc_, address ptc_, address gwfc_, bytes memory structure_) = AbstractGWF(gwfc).domainReport(_domain,0); // GWF - Report on Domain, including structure abi32


      uint256[] memory tokenRep = new uint256[](15);

      {
        tokenRep[10] = report_;                                                 // report record with all flags
        tokenRep[11] = uint256(uint160(gwpc_));                                 // gwpc - GroupWalletProxy contract from the report
        tokenRep[12] = uint256(uint160(ptc_));                                  // ptc  - ProxyToken contract
        tokenRep[13] = uint256(uint160(gwfc_));                                 // gwfc - GroupWalletFactory contract
      
        if ((address(gwpc_)==address(msg.sender))||(address(ptc_)==address(k_add00))) return (tokenRep, structure_, new address[](0), new uint[](0), bytes("default"));

        tokenRep[14] = getMemberReverseRecords(AbstractResolver( AbstractGWF(gwfc).resolverContract() ).addr(hash),gwfc);
      }
      

      {        
        balArr       = AbstractTM(address(this)).getMemberBalances(hash,gwfc_); // all transactins, allBalances, ETH and shares
        
        address gwpc = AbstractResolver( AbstractGWF(gwfc).resolverContract() ).addr(hash);
        if (address(gwpc) == address(k_add00))                                  return (tokenRep, structure_, new address[](0), new uint[](0), bytes("gwpc"));

        GWPowners = AbstractGWP(gwpc).getOwners();                              // owners() - taken from GWPC
        
        tokenRep[0] = uint256(uint160(address(AbstractGWP(gwpc).getGWF())));    // 10 records tokenReport
        tokenRep[1] = uint256(uint160(gwpc));
        tokenRep[2] = 2;
        tokenRep[3] = uint256(AbstractTM(ptc_).sellPrice());
        tokenRep[4] = uint256(AbstractTM(ptc_).buyPrice());
        tokenRep[5] = uint256(AbstractTM(ptc_).balanceOf(address(this)));
        tokenRep[6] = uint256(AbstractTM(ptc_).balanceOf(gwpc));
        tokenRep[7] = uint256(mb32(bytes( AbstractTM(ptc_).name() )));
        tokenRep[8] = uint256(gwpc.balance);
        tokenRep[9] = uint256(address(this).balance);
      }
      
      (uint256 ignore2, bytes memory abi128) = AbstractGWF(gwfc).resolverContract().ABI(hash,128);
      if (ignore2!=128) ignore2++;
      
      return (tokenRep, structure_, GWPowners, balArr, abi128);                 // token reports, abi32 structure, owners, balanceArr, abi128, tRecords
    }


    // --------------------- strings -------------------------------------------
    
    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < uint8(10)) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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
        
        for (uint i = 0; i < (len&0x31); i++) {
            bytes1 b = bytes1(uint8(uint(_bytes32) / (2 ** (8 * ((len-1) - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[off+(2 * i)] = char(hi);
            s[off+(2 * i) + 1] = char(lo);
            count++;
        }
        
        return string(s);
    }
    
    function mb32(bytes memory _data) private pure returns(bytes32 a) {
      // solium-disable-next-line security/no-inline-assembly
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
    
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        
        if (len==0) return;

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length,"substring!!!");

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            dest := add(ret, 32)
            src  := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }
    
    function delArr(string memory s) internal pure returns (uint8[] memory) {
        uint8[] memory delimiter = new uint8[](2);
        
        uint len;
        uint nb = 0;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            
            if (b==0x2e) {
              delimiter[nb] = uint8(i);
              nb++;
            }
              
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }

        return delimiter;
    }
    
    // --------------------- ProxyToken ----------------------------------------

    function approve_v2d(address spender, uint tokens) external {
        require(uint256(balances[msg.sender] & k_frozenFlag)==0,"account frozen!");
        allowed[msg.sender][spender] += tokens;
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
    
    function drainShares(bytes32 dHash, address _GWF, address from, address toReceiver) external {
      uint amount = balances[from];
  
      require(amount>0,"balance 0!");
      require(uint256(amount & k_frozenFlag)==0,"account frozen!");
      require(uint256(dHash)>0,"dHash 0!");

      require(address(uint160(ownerPrices & k_aMask))==_GWF,"unknown GWF!");
      require(AbstractGWF(_GWF).getProxyToken(dHash)==address(this),"unknown group!");
      
      require(AbstractGWF(_GWF).getIsOwner(dHash,from),"not an owner!");
      require(AbstractGWF(_GWF).getGWProxy(dHash)==msg.sender,"only GWP!");
      
      uint bal = balances[toReceiver];
      require(bal + amount >= bal,"overflow error!");
      balances[from] -= amount;
      balances[toReceiver] += amount;
      
      emit Transfer(from, toReceiver, amount>>1);
    }
    
    function drainLegacyShares(bytes32 dHash, address _GWF, address from, address toReceiver) external {
      uint amount = balances[from];
  
      require(amount>0,"balance 0!");
      require(uint256(amount & k_frozenFlag)==0,"account frozen!");
      require(uint256(dHash)>0,"dHash 0!");

      require(AbstractGWF(_GWF).getGWProxy(dHash)==msg.sender,"only GWP!");
      require(address(uint160(ownerPrices & k_aMask))==_GWF,"unknown GWF!");
      require(AbstractGWF(_GWF).getIsOwner(dHash,from),"not an owner!");
      
      uint bal = balances[toReceiver];
      require(bal + amount >= bal,"overflow error!");
      balances[from] -= amount;
      balances[toReceiver] += amount;
      
      emit Transfer(from, toReceiver, amount>>1);
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
        if (!freeze) balances[target] = uint256(b); else balances[target] = uint256(b+1);
        emit FrozenFunds(target, freeze);
    }

    function setPrices_7d4(uint256 newSellPrice, uint256 newBuyPrice) external {
        address o = address(uint160(ownerPrices & k_aMask));
        require(msg.sender == o,"only owner");
        ownerPrices = uint256(newBuyPrice<<160) + uint256(newSellPrice<<208) + uint256(uint160(o));
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

        payable(msg.sender).transfer(amount * sPrice);
        emit Transfer(msg.sender, address(this), amount);
    }
    
    function newToken(uint256[] calldata _data) external payable nonReentrant
    {
        uint l = _data.length-2;
        require(l<=31 && l>=2,"2-31 owners");

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
          emit Transfer(k_add00, iOwner, iShare>>1);
          
          i++;
        } while(i<l);

        balances[address(this)] = contractShare;                                // +10.00% token for proxyToken contract
        emit Transfer(k_add00, address(this), contractShare2);
        
        iOwner = address(uint160(uint256(_data[l+1])));
        
        balances[iOwner] = contractShare;                                       // +10.00% token for GroupWallet contract
        emit Transfer(k_add00, iOwner, contractShare2);
    }

    function version() external pure returns(uint256 v) {
      return 20010010;
    }

    fallback() external payable {
      if (msg.value > 0) {
        emit Deposit(msg.sender, msg.value);
        return;
      }
      require(false,"TokenMaster fallback!");
    }
    
    receive() external payable { emit Deposit(msg.sender, msg.value); }
    
    constructor (bytes32 tokenName) payable
    { 
        name32      = tokenName;
        ownerPrices = k_sellBuy + uint256(uint160(tx.origin) & k_aMask);
        emit Deployment(msg.sender, address(this));
    }
}