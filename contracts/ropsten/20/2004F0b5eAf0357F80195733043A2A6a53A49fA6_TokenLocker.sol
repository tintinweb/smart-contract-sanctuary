/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity ^0.6.12;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract WABB is IPancakeERC20 {
    using SafeMath for uint;

    string public override constant name = 'WAB token';
    string public override constant symbol = 'WABB';
    uint8 public override constant decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public override constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        balanceOf[msg.sender] = 51000000 * (10 ** 18);
        totalSupply = 51000000 * (10 ** 18);
    }

    function _mint(address to, uint value) public returns (bool) {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
        return true;
    }

    function _burn(address from, uint value) public returns (bool) {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
        return true;
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
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
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'Pancake: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Pancake: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

contract TokenLocker {
    using SafeMath for uint;
    using SafeMath for uint256;

    struct LockInfo {
        uint256 _amount;
        uint256 _timestamp;
        uint256 _lockingPeriod;
    }

    mapping (uint => bool) public isClaimed;

    LockInfo[] public locks;

    constructor () public
    {

    }
    
    function getLocksLength() public view returns (uint)
    {
        return locks.length;
    }

    function lockTokens(uint amount, uint period) public
    {
        LockInfo memory l;
        l._amount = amount;
        l._timestamp = block.timestamp;
        l._lockingPeriod = period;
        locks.push(l);
    }

    function getTotalLockedAmount() public view returns (uint)
    {
        uint res = 0;
        uint i;
        for (i = 0; i < locks.length; i++)
        {
            if (locks[i]._amount > 0 && !isClaimed[i])
            {
                res += locks[i]._amount;
            }
        }
        return res;
    }

    function getAmountCanBeUnlocked() public view returns (uint)
    {
        uint res = 0;
        uint i;
        for (i = 0; i < locks.length; i++)
        {
            if (locks[i]._amount > 0 && !isClaimed[i] && (locks[i]._timestamp + locks[i]._lockingPeriod < block.timestamp))
            {
                res += locks[i]._amount;
            }
        }
        return res;
    }

    function unlockAll(address wabb, address to) public 
    {
        uint amount = getAmountCanBeUnlocked();
        uint i;
        for (i = 0; i < locks.length; i++)
        {
            if (locks[i]._amount > 0 && !isClaimed[i] && (locks[i]._timestamp + locks[i]._lockingPeriod < block.timestamp))
            {
                locks[i]._amount = 0;
                isClaimed[i] = true;
            }
        }
        WABB(wabb)._mint(to, amount);
    }
}