/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/interfaces/ICoFiXERC20.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface ICoFiXERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    // function name() external pure returns (string memory);
    // function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    // function DOMAIN_SEPARATOR() external view returns (bytes32);
    // function PERMIT_TYPEHASH() external pure returns (bytes32);
    // function nonces(address owner) external view returns (uint);

    // function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


// File contracts/CoFiXERC20.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
// ERC20 token implementation, inherited by CoFiXPair contract, no owner or governance
contract CoFiXERC20 is ICoFiXERC20 {

    //string public constant nameForDomain = 'CoFiX Pool Token';
    uint8 public override constant decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    //bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");
    //bytes32 public override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    //mapping(address => uint) public override nonces;

    //event Approval(address indexed owner, address indexed spender, uint value);
    //event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        // uint chainId;
        // assembly {
        //     chainId := chainid()
        // }
        // DOMAIN_SEPARATOR = keccak256(
        //     abi.encode(
        //         keccak256('EIP712Domain(string name,string version,uint chainId,address verifyingContract)'),
        //         keccak256(bytes(nameForDomain)),
        //         keccak256(bytes('1')),
        //         chainId,
        //         address(this)
        //     )
        // );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply + (value);
        balanceOf[to] = balanceOf[to] + (value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from] - (value);
        totalSupply = totalSupply - (value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from] - (value);
        balanceOf[to] = balanceOf[to] + (value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
           allowance[from][msg.sender] = allowance[from][msg.sender] - (value);
        }
        _transfer(from, to, value);
        return true;
    }

    // function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
    //     require(deadline >= block.timestamp, 'CERC20: EXPIRED');
    //     bytes32 digest = keccak256(
    //         abi.encodePacked(
    //             '\x19\x01',
    //             DOMAIN_SEPARATOR,
    //             keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
    //         )
    //     );
    //     address recoveredAddress = ecrecover(digest, v, r, s);
    //     require(recoveredAddress != address(0) && recoveredAddress == owner, 'CERC20: INVALID_SIGNATURE');
    //     _approve(owner, spender, value);
    // }
}


// File contracts/CoFiXAnchorToken.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Anchor pool xtoken
contract CoFiXAnchorToken is CoFiXERC20 {

    // Address of anchor pool
    address immutable POOL;

    // ERC20 - name
    string public name;
    
    // ERC20 - symbol
    string public symbol;

    constructor (
        string memory name_, 
        string memory symbol_,
        address pool
    ) {
        name = name_;
        symbol = symbol_;
        POOL = pool;
    }

    modifier check() {
        require(msg.sender == POOL, "CoFiXAnchorToken: Only for CoFiXAnchorPool");
        _;
    }

    /// @dev Distribute xtoken
    /// @param to The address which xtoken distribute to
    /// @param amount Amount of xtoken
    function mint(
        address to, 
        uint amount
    ) external check returns (uint) {
        _mint(to, amount);
        return amount;
    }

    /// @dev Burn xtoken
    /// @param amount Amount of xtoken
    function burn(
        uint amount
    ) external { 
        _burn(msg.sender, amount);
    }
}