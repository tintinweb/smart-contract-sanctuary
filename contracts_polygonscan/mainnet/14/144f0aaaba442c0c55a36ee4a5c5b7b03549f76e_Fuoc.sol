/**
 *Submitted for verification at polygonscan.com on 2021-10-31
*/

// SPDX-License-Identifier: GNU GPLv3

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Using compiler version 0.8.7 or higher

pragma solidity ^0.8.7;

// Extension contract for FUT contract
abstract contract Math
{
    function add(uint x, uint y) internal pure returns (uint z)
    {
        require((z = x + y) > x);
    }
    
    function sub(uint x, uint y) internal pure returns (uint z)
    {
        require((z = x - y) < x);
    }
}

abstract contract Admin
{
    address private admin;
    
    constructor(address guy)
    {
        admin = guy;
    }
    
    modifier onlyAdmin
    {
        require(msg.sender == admin, 'Not allowed');
        _;
    }
    
    function transferAdmin(address guy) public onlyAdmin returns (bool)
    {
        admin = guy;
        
        return true;
    }

}

contract ERC20 is Math
{
    
    mapping(address => uint256) private $balances;
    mapping(address => mapping(address => uint256)) private $allowances;
    
    uint256 private $totalSupply;
    
    string private $name;
    string private $symbol;
    
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Approval(address indexed src, address indexed guy, uint256 wad);
    
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;
    
    mapping(address => uint) public nonces;
    
    constructor(string memory _name, string memory _symbol)
    {
        
        $name = _name;
        $symbol = _symbol;
        
        uint chainId = block.chainid;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        
    }
    
    // return string of name of the token
    function name() public view virtual returns (string memory)
    {
        return $name;
    }
    
    // return string of symbol of the Token
    function symbol() public view virtual returns (string memory)
    {
        return $symbol;
    }
    
    // return uin8 of decimals applied to Token
    function decimals() public view virtual returns(uint8)
    {
        return 18;
    }
    
    // Get the value of $totalSupply
    function totalSupply() public view virtual returns (uint256)
    {
        return $totalSupply;
    }
    
    // Get total balance of target address
    function balanceOf(address guy) public view virtual returns (uint256)
    {
        return $balances[guy];
    }
    
    // Mint a value of Token
    function $mint(address guy, uint256 wad) internal returns (bool)
    {
        uint guywad = $balances[guy];
        $balances[guy] = add(guywad, wad);
        $totalSupply = add(totalSupply(), wad);
        emit Transfer(address(0), guy, wad);
        
        return true;
    }
    
    // ability to burn a token
    function burn(address src,uint256 wad) public virtual returns (bool)
    {
        require(balanceOf(src) >= wad, 'Insufficient balance');
        if (src != msg.sender)
        {
            require(allowance(src, msg.sender) >= wad, 'Not allowed');
            $allowances[src][msg.sender] = sub(allowance(src, msg.sender), wad);
        }
        $totalSupply = sub($totalSupply, wad);
        $balances[src] = sub($balances[src], wad);
        
        emit Transfer(src, address(0), wad);
        
        return true;
    }
    
    // Get $allowances
    function allowance(address src,address guy) public view virtual returns (uint256)
    {
        return $allowances[src][guy];
    }
    
    function $transfer(address src, address dst, uint256 wad) internal virtual returns (bool)
    {
        // prevent transfer from/to zero address
        require(src != address(0), 'Transfer from zero address');
        require(dst != address(0), 'Transfer to zero address');
        // checking if the balance of sender enough for transaction
        uint256 srcWad = balanceOf(src);
        require(srcWad >= wad, 'Insufficient balance');
        // Check and verify if src not an msg.sender and if not check if the executor was allowed
        if (src != msg.sender)
        {
            require(allowance(src, msg.sender) >= wad, 'Not allowed');
            $allowances[src][msg.sender] = sub(allowance(src, msg.sender), wad);
        }
        $balances[src] = sub($balances[src], wad);
        $balances[dst] = add($balances[dst], wad);
        
        emit Transfer(src, dst, wad);
        
        return true;
        
    }
    
    // transfer function for move balence to another destination
    function transfer(address dst, uint256 wad) public virtual returns (bool)
    {
        return $transfer(msg.sender, dst, wad);
    }
    
    // transfer from specific address to other destination
    function transferFrom(address src, address dst, uint256 wad) public virtual returns (bool)
    {
        return $transfer(src, dst, wad);
    }
    
    // allow specific address to spend balances
    function $approve(address src, address guy, uint256 wad) internal virtual returns (bool)
    {
        require(guy != address(0), 'zero address');
        $allowances[src][guy] = wad;
        return true;
    }
    
    function approve(address guy, uint256 wad) public virtual returns (bool)
    {
        return $approve(msg.sender, guy, wad);
    }
    
    // Approve by signature
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        $approve(owner, spender, value);
    }
    
}

contract Fuoc is ERC20, Admin
{
    constructor() ERC20('FUOC Token', 'FUOCT') Admin(msg.sender)
    {
        $mint(msg.sender, 100000 ether);
    }
    
    function mint(address guy, uint256 wad) public virtual onlyAdmin returns (bool)
    {
        return $mint(guy, wad);
    }
    
}