/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract EIP712 {
     bytes32 private constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
     bytes32 public DOMAIN_SEPARATOR;
     mapping (address => uint) private _nonces;
     constructor(string memory name, string memory version) {
        uint chainId = getChainId();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }
    function getChainId() private pure returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    function nonces(address account) public view returns (uint) {
        return _nonces[account];
    }
    function incrementNonce(address account) public returns (uint) {
        return _nonces[account]++;
    }
    function getDigest(bytes32 structHash) public view returns (bytes32) {
            return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );
    }
    function recover(bytes32 digest, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0), "ERC712: invalid signature");
        return recoveredAddress;
    }   
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC20Optionals {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract ERC20Optionals is EIP712, IERC20, IERC20Optionals {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _cap = 2**96-1;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory tokenName, string memory tokenSymbol, uint256 tokenCap) {
        require(tokenCap > 0);
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = 18;
        _cap = tokenCap;
    }
    function cap() public view returns (uint256) {
        return _cap;
    }
    function totalSupply() public view override virtual returns (uint256) {
        return _totalSupply;
    }    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");   
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual {}
    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        require(_totalSupply <= _cap, "ERC20Capped: cap exceeded");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");   
        _beforeTokenTransfer(account, address(0), amount);
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function name() public view override returns (string memory) {
        return _name;
    }
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
}

interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract HBG is ERC20Optionals, IERC20Permit, Ownable {
    using SafeMath for uint256;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    constructor()
        ERC20Optionals("HarborBcg", "HBG", 1000000000 * 10**18)
        EIP712("HarborBcg", "1") {
    }
    function mintTo(address account, uint amount) external onlyOwner returns (bool)  {
        _mint(account, amount);
        return true;
    }
    function burn(uint amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    function burnFrom(address account, uint amount) external returns (bool) {
        uint256 allowance = allowance(account, msg.sender);
        uint256 decreasedAllowance = allowance.sub(amount);
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
        return true;
    }
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, "ERC20Permit: expired");
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, incrementNonce(owner), deadline));
        bytes32 digest = getDigest(structHash);
        address recoveredAddress = recover(digest, v, r, s);
        require(recoveredAddress == owner, "ERC20Permit: invalid signature");
        _approve(owner, spender, value);
    }
}