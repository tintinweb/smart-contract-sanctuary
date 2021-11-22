/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico, lucasvo
pragma solidity >=0.7.0;

contract ERC20 {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) public auth { wards[usr] = 1; }
    function deny(address usr) public auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- ERC20 Data ---
    uint8   public constant decimals = 18;
    string  public name;
    string  public symbol;
    string  public constant version = "1";
    uint256 public totalSupply;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Approval(address indexed src, address indexed usr, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // --- Math ---
    function safeAdd_(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-add-overflow");
    }
    function safeSub_(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "math-sub-underflow");
    }

    constructor(string memory symbol_, string memory name_) {
        wards[msg.sender] = 1;
        symbol = symbol_;
        name = name_;

        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    // --- ERC20 ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad)
        public virtual returns (bool)
    {
        require(balanceOf[src] >= wad, "cent/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad, "cent/insufficient-allowance");
            allowance[src][msg.sender] = safeSub_(allowance[src][msg.sender], wad);
        }
        balanceOf[src] = safeSub_(balanceOf[src], wad);
        balanceOf[dst] = safeAdd_(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function mint(address usr, uint wad) external virtual auth {
        balanceOf[usr] = safeAdd_(balanceOf[usr], wad);
        totalSupply    = safeAdd_(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }
    function burn(address usr, uint wad) public {
        require(balanceOf[usr] >= wad, "cent/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != type(uint256).max) {
            require(allowance[usr][msg.sender] >= wad, "cent/insufficient-allowance");
            allowance[usr][msg.sender] = safeSub_(allowance[usr][msg.sender], wad);
        }
        balanceOf[usr] = safeSub_(balanceOf[usr], wad);
        totalSupply    = safeSub_(totalSupply, wad);
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
    function burnFrom(address usr, uint wad) external {
        burn(usr, wad);
    }

    // --- Approve by signature ---
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'cent/past-deadline');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'cent-erc20/invalid-sig');
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}