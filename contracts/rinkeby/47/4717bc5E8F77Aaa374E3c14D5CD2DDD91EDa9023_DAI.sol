// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

contract LibNote {
  event LogNote(
    bytes4   indexed  sig,
    address  indexed  usr,
    bytes32  indexed  arg1,
    bytes32  indexed  arg2,
    bytes             data
  ) anonymous;

  modifier note {
    _;
    // assembly {
    //     // log an 'anonymous' event with a constant 6 words of calldata
    //     // and four indexed topics: selector, caller, arg1 and arg2
    //     let mark := msize()                         // end of memory ensures zero
    //     mstore(0x40, add(mark, 288))              // update free memory pointer
    //     mstore(mark, 0x20)                        // bytes type data offset
    //     mstore(add(mark, 0x20), 224)              // bytes size (padded)
    //     calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
    //     log4(mark, 288,                           // calldata
    //          shl(224, shr(224, calldataload(0))), // msg.sig
    //          caller(),                              // msg.sender
    //          calldataload(4),                     // arg1
    //          calldataload(36)                     // arg2
    //         )
    // }
  }
}

interface IDAI {


    // --- Auth ---
  function wards() external returns ( uint256 );

  function rely(address guy) external;

  function deny(address guy) external;

    // --- Token ---
  function transfer(address dst, uint wad) external returns (bool);

  function transferFrom(address src, address dst, uint wad) external returns (bool);

  function mint(address usr, uint wad) external;

  function burn(address usr, uint wad) external;

  function approve(address usr, uint wad) external returns (bool);

    // --- Alias ---
  function push(address usr, uint wad) external;

  function pull(address usr, uint wad) external;

  function move(address src, address dst, uint wad) external;

    // --- Approve by signature ---
  function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

////// /nix/store/8xb41r4qd0cjb63wcrxf1qmfg88p0961-dss-6fd7de0/src/dai.sol
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.5.12; */

/* import "./lib.sol"; */

contract DAI is LibNote {
  
  event Approval(address indexed src, address indexed guy, uint wad);
  event Transfer(address indexed src, address indexed dst, uint wad);
  
    // --- Auth ---
    mapping (address => uint) public wards;

    function rely(address guy) external note auth { wards[guy] = 1; }

    function deny(address guy) external note auth { wards[guy] = 0; }

    modifier auth {
        require(wards[msg.sender] == 1, "Dai/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string  public constant name     = "Dai Stablecoin";
    string  public constant symbol   = "DAI";
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;
    uint public dailyDAILimit;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) private allowances;
    mapping (address => uint)                      public nonces;
    mapping (address => uint)                      public lastMintRestart;
    mapping (address => uint)                      public daiMintedToday;

    // event Approval(address indexed src, address indexed guy, uint wad);
    // event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 chainId_) {
        wards[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
        dailyDAILimit = 10000000000000000000000;
    }

    function allowance( address account_, address sender_ ) external view returns ( uint ) {
      return _allowance( account_, sender_ );
    }

    function _allowance( address account_, address sender_ ) internal view returns ( uint ) {
      
      return allowances[account_][sender_];
    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public returns (bool) {
      
      
      require(balanceOf[src] >= wad, "Dai/insufficient-balance");
        if (src != msg.sender && _allowance( src, msg.sender ) != uint(-1)) {
            require(_allowance( src, msg.sender ) >= wad, "Dai/insufficient-allowance");
            allowances[src][msg.sender] = sub(_allowance( src, msg.sender ), wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }

    function addAuth(address usr) external auth {
        wards[usr] = 1;
    }

    function adjustDailyDAILimit(uint _limit) external auth {
        dailyDAILimit = _limit;
    }

    function mint(address usr, uint wad) external {

      if(wards[msg.sender] == 0) {
        require(add(wad, daiMintedToday[msg.sender]) <= dailyDAILimit || sub(block.number, lastMintRestart[msg.sender]) >= 6500 && wad <= dailyDAILimit, "Over daily DAI Limit");
        if( sub(block.number, lastMintRestart[msg.sender]) >= 6500 ) {
            daiMintedToday[msg.sender] = wad;
            lastMintRestart[msg.sender] = block.number;
        } else {
            daiMintedToday[msg.sender] = add(daiMintedToday[msg.sender], wad);
        }
      }
      
      balanceOf[usr] = add(balanceOf[usr], wad);
      
      totalSupply    = add(totalSupply, wad);
      
      
      emit Transfer(address(0), usr, wad);
    }

    function burn(address usr, uint wad) external {
        require(balanceOf[usr] >= wad, "Dai/insufficient-balance");
        if (usr != msg.sender && _allowance( usr, msg.sender ) != uint(-1)) {
            require(_allowance( usr, msg.sender ) >= wad, "Dai/insufficient-allowance");
            allowances[usr][msg.sender] = sub(_allowance( usr, msg.sender ), wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply    = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }

    function _approve(address usr, uint wad) internal returns (bool) {
      
      allowances[msg.sender][usr] = wad;
      
      emit Approval(msg.sender, usr, wad);
      return true;
    }

    function approve(address usr_, uint wad_ ) external returns (bool) {
      
      return _approve( usr_, wad_ ) ;
    }

    // --- Alias ---
    function push(address usr, uint wad) external {
        transferFrom(msg.sender, usr, wad);
    }

    function pull(address usr, uint wad) external {
        transferFrom(usr, msg.sender, wad);
    }

    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }

    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "Dai/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Dai/invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "Dai/permit-expired");
        require(nonce == nonces[holder]++, "Dai/invalid-nonce");
        uint wad = allowed ? uint(-1) : 0;
        allowances[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}