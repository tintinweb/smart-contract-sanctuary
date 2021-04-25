/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

//pragma solidity ^0.4.11;
/*
 * This file is part of the Ketahazure repository  (https://github.com/ketahazure).
 * Copyright (c) 2021 Ketahazure.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
*/
/*
Point Gn[CPU_GRP_SIZE / 2];
Point _2Gn;
*/
contract KTHZR {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {
            // log an 'anonymous' event with a constant 6 words of calldata
            // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize                         // end of memory ensures zero
            mstore(0x40, add(mark, 288))              // update free memory pointer
            mstore(mark, 0x20)                        // bytes type data offset
            mstore(add(mark, 0x20), 224)              // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)     // bytes payload
            log4(mark, 288,                           // calldata
                 shl(224, shr(224, calldataload(0))), // msg.sig
                 caller,                              // msg.sender
                 calldataload(4),                     // arg1
                 calldataload(36)                     // arg2
                )
        }
    }
}
/*
1. Software; Execute.
2. In order to rename investment; Execute.
3. In order to financial rehashtag; Execute.
4. In order to publish and broadcast share dividend; Execute.
*/
contract ketahazure is KTHZR {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external note auth { wards[guy] = 1; }
    function deny(address guy) external note auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "KTHZR/not-authorized");
        _;
    }
/*
This wallet introduces this contract therefore it was written "DO NOT ATTEMPT, IN ORDER TO, WITHOUT PERMISSION OR ELSE."
This "K.wal" or "K.eth" wallet introduces this contract, "K.sol" therefore, it was written "DO NOT ATTEMPT, IN ORDER TO, WITHOUT PERMISSION OR ELSE."
This: "K.wal", or "K.eth" wallet, introduces this: "K.sol" contract, therefore, it was written "DO NOT ATTEMPT, IN ORDER TO, WITHOUT PERMISSION OR ELSE."

This: "K.wal" -> "K.eth" = "K.sol";
Ketahazure: K++;
*/
    // --- ERC20 Data ---
    string  public constant name     = "Ketahazure Classic";
    string  public constant symbol   = "KTHZR";
    string  public constant version  = "1";
    uint8   public constant decimals = 8;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    //bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    //bytes32 public constant PERMIT_TYPEHASH = 0x3bB6728DD823a1B99F9FA9e89A49dEc83D6a66a9;

    constructor(uint256 chainId_) public {
        wards[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad)
        public returns (bool)
    {
        require(balanceOf[src] >= wad, "KTHZR/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "KTHZR/insufficient-allowance");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function mint(address usr, uint wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply    = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }
    function burn(address usr, uint wad) external {
        require(balanceOf[usr] >= wad, "KTHZR/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint(-1)) {
            require(allowance[usr][msg.sender] >= wad, "KTHZR/insufficient-allowance");
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply    = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }
    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
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
    //bytes32 digest = keccak256(abi.encodePacked( "\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, holder, spender, nonce, expiry, allowed)) ));
        require(holder != address(0), "KTHZR/invalid-address-0");
    //require(holder == ecrecover(digest, v, r, s), "KTHZR/invalid-permit");
        require(expiry == 0 || now <= expiry, "KTHZR/permit-expired");
        require(nonce == nonces[holder]++, "KTHZR/invalid-nonce");
        uint wad = allowed ? uint(-1) : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}