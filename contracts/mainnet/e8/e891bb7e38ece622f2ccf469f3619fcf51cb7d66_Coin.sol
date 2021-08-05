/**
 *Submitted for verification at Etherscan.io on 2020-11-10
*/

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

pragma solidity ^0.6.7;

contract Coin {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "Coin/account-not-authorized");
        _;
    }

    modifier canChangeData() {
        require(changeData == 1, "Coin/cannot-change-namings");
        _;
    }

    // --- ERC20 Data ---
    string  public name;
    string  public symbol;
    string  public version = "1";

    uint8   public constant decimals = 18;

    uint256 public chainId;
    uint256 public totalSupply;
    uint256 public changeData;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Approval(address indexed src, address indexed guy, uint amount);
    event Transfer(address indexed src, address indexed dst, uint amount);
    event ModifyParameters(bytes32 parameter, uint data);

    // --- Math ---
    function addition(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function subtract(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 chainId_
      ) public {
        authorizedAccounts[msg.sender] = 1;
        name          = name_;
        symbol        = symbol_;
        changeData    = 1;
        chainId       = chainId_;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
        emit AddAuthorization(msg.sender);
        emit ModifyParameters("changeData", 1);
    }

    // --- Administration ---
    function modifyParameters(bytes32 parameter, uint data) external isAuthorized canChangeData {
        if (parameter == "changeData") {
          changeData = data;
        }
        else revert("Coin/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Naming ---
    function setName(string calldata name_) external isAuthorized canChangeData {
        name             = name_;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this)
        ));
    }
    function setSymbol(string calldata symbol_) external isAuthorized canChangeData {
        symbol = symbol_;
    }

    // --- Token ---
    function transfer(address dst, uint amount) external returns (bool) {
        return transferFrom(msg.sender, dst, amount);
    }
    function transferFrom(address src, address dst, uint amount)
        public returns (bool)
    {
        require(balanceOf[src] >= amount, "Coin/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= amount, "Coin/insufficient-allowance");
            allowance[src][msg.sender] = subtract(allowance[src][msg.sender], amount);
        }
        balanceOf[src] = subtract(balanceOf[src], amount);
        balanceOf[dst] = addition(balanceOf[dst], amount);
        emit Transfer(src, dst, amount);
        return true;
    }
    function mint(address usr, uint amount) external isAuthorized {
        balanceOf[usr] = addition(balanceOf[usr], amount);
        totalSupply    = addition(totalSupply, amount);
        emit Transfer(address(0), usr, amount);
    }
    function burn(address usr, uint amount) external {
        require(balanceOf[usr] >= amount, "Coin/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint(-1)) {
            require(allowance[usr][msg.sender] >= amount, "Coin/insufficient-allowance");
            allowance[usr][msg.sender] = subtract(allowance[usr][msg.sender], amount);
        }
        balanceOf[usr] = subtract(balanceOf[usr], amount);
        totalSupply    = subtract(totalSupply, amount);
        emit Transfer(usr, address(0), amount);
    }
    function approve(address usr, uint amount) external returns (bool) {
        allowance[msg.sender][usr] = amount;
        emit Approval(msg.sender, usr, amount);
        return true;
    }

    // --- Alias ---
    function push(address usr, uint amount) external {
        transferFrom(msg.sender, usr, amount);
    }
    function pull(address usr, uint amount) external {
        transferFrom(usr, msg.sender, amount);
    }
    function move(address src, address dst, uint amount) external {
        transferFrom(src, dst, amount);
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external
    {
        require(changeData != 1, "Coin/can-still-change-namings");
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

        require(holder != address(0), "Coin/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Coin/invalid-permit");
        require(expiry == 0 || now <= expiry, "Coin/permit-expired");
        require(nonce == nonces[holder]++, "Coin/invalid-nonce");
        uint wad = allowed ? uint(-1) : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}