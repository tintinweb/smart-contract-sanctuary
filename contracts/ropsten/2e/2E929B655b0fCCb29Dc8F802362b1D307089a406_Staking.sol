/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity =0.6.6;

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
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
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

contract xWABB is IPancakeERC20 {
    using SafeMath for uint;

    string public override constant name = 'xWABB staking token';
    string public override constant symbol = 'xWABB';
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
        totalSupply = 0;
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

library TransferHelper {
    function _safeApprove(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x104e81ff, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: _APPROVE_FAILED');
    }
    
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        /*(bool success, bytes memory data) = */
        (bool success,) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success, 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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

contract Staking
{
    using SafeMath for uint;
    address private wabb;
    address private xwabb;
    address private locker;
    uint private startBlock;
    uint private lockedPercent;
    uint private mintedPerBlock;

    event Mint(uint value);
    
    constructor() public {
        wabb = address(0x34D5852C0f1637032f6F7a0eA3e7ed17B444fc39);
        xwabb = address(0x9534166cbabE50739c7c9Bb5a43857015961Ff0A);
        locker = address(0x2004F0b5eAf0357F80195733043A2A6a53A49fA6);
        startBlock = block.number;
        lockedPercent = 67;
        mintedPerBlock = 2;
    }

    function getLockedPercent() public view returns (uint)
    {
        return lockedPercent;
    }

    function getMinterPerBlock() public view returns (uint)
    {
        return mintedPerBlock;
    }

    function setLockedPercent(uint _arg) public
    {
        lockedPercent = _arg;
    }

    function setMinterPerBlock(uint _arg) public
    {
        mintedPerBlock = _arg;
    }

    function giveTestTokens(address to, uint value) public 
    {
        WABB(wabb)._mint(to, value);
    }

    function getCurrentBlockNumber() public view returns (uint)
    {
        return block.number;
    }

    function mintNewTokens(uint _period) public
    {
        uint _total = (block.number - startBlock) * mintedPerBlock;
        if (_total == 0)
        {
            return;
        }
        uint _locked = _total.div(100).mul(lockedPercent);
        uint _minted = _total.sub(_locked);
        TokenLocker(locker).lockTokens(_locked, _period);
        WABB(wabb)._mint(address(this), _minted);
        emit Mint(_minted);
    }

    function unlockAll() public 
    {
        TokenLocker(locker).unlockAll(wabb, address(this));
    }

    function enter(uint _amount) public 
    {
        uint totalWabb = WABB(wabb).balanceOf(address(this));
        uint totalShares = xWABB(xwabb).totalSupply();
        if (totalWabb == 0 || totalShares == 0)
        {
            xWABB(xwabb)._mint(msg.sender, _amount);
        }
        else
        {
            uint what = _amount.mul(totalShares).div(totalWabb);
            xWABB(xwabb)._mint(msg.sender, what);
        }
        // transfer tokens from sender
        WABB(wabb).transferFrom(msg.sender, address(this), _amount);
    }

    function leave(uint _amount) public 
    {
        uint totalWabb = WABB(wabb).balanceOf(address(this));
        uint totalShares = xWABB(xwabb).totalSupply();
        uint what = _amount.mul(totalWabb).div(totalShares);
        xWABB(xwabb)._burn(msg.sender, _amount);
        WABB(wabb).transfer(msg.sender, what);
    }
}