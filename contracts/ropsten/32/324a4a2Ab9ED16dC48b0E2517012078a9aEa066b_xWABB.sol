/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

pragma solidity =0.6.6;

contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes memory data) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

contract WABB is IPancakeERC20, Ownable {
    using SafeMath for uint;

    string override public constant name = 'WABB token';
    string override public constant symbol = 'WABB';
    uint8 override public constant decimals = 18;
    uint override public totalSupply;
    mapping(address => uint) override public balanceOf;
    mapping(address => mapping(address => uint)) override public allowance;

    bytes32 override public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 override public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) override public nonces;

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

    function _mint(address to, uint value) public onlyOwner returns (bool) {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
        return true;
    }

    function _burn(address from, uint value) public onlyOwner returns (bool) {
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

contract xWABB is IPancakeERC20, Ownable {
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

    function _mint(address to, uint value) public onlyOwner returns (bool) {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
        return true;
    }

    function _burn(address from, uint value) public onlyOwner returns (bool) {
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

contract TokenLocker is Ownable {
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

    function lockTokens(uint amount, uint period) public onlyOwner
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

    function unlockAll() public onlyOwner returns (uint)
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
        return amount;
    }
}

contract Staking is Ownable
{
    using SafeMath for uint;
    address private wabb;
    address private xwabb;
    address private locker;
    uint private startBlock;
    uint private lockedPercent;
    uint private mintedPerBlock;

    event Mint(uint value);
    event EnterStaking(address user, uint value);
    event LeaveStaking(address user, uint amount, uint amountOut);
    
    constructor() public {
        wabb = address(0);
        xwabb = address(0);
        locker = address(0);
        startBlock = block.number;
        lockedPercent = 67;
        mintedPerBlock = 2;
    }

    function getWabb() public view returns (address)
    {
        return wabb;
    }

    function setWabb(address arg) public onlyOwner
    {
        wabb = arg;
    }

    function getxWabb() public view returns (address)
    {
        return xwabb;
    }

    function setXwabb(address arg) public onlyOwner
    {
        xwabb = arg;
    }

    function getLocker() public view returns (address)
    {
        return locker;
    }

    function setLocker(address arg) public onlyOwner
    {
        locker = arg;
    }

    function getLockedPercent() public view returns (uint)
    {
        return lockedPercent;
    }

    function getMinterPerBlock() public view returns (uint)
    {
        return mintedPerBlock;
    }

    function setLockedPercent(uint _arg) public onlyOwner
    {
        lockedPercent = _arg;
    }

    function setMinterPerBlock(uint _arg) public onlyOwner
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
        uint unlocked = TokenLocker(locker).unlockAll();
        WABB(wabb)._mint(address(this), unlocked);
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
        emit EnterStaking(msg.sender, _amount);
    }

    function leave(uint _amount) public 
    {
        uint totalWabb = WABB(wabb).balanceOf(address(this));
        uint totalShares = xWABB(xwabb).totalSupply();
        uint what = _amount.mul(totalWabb).div(totalShares);
        xWABB(xwabb)._burn(msg.sender, _amount);
        WABB(wabb).transfer(msg.sender, what);
        emit LeaveStaking(msg.sender, _amount, what);
    }

    function changeChildrenOwner(address newOwner) public onlyOwner
    {
        WABB(wabb).transferOwnership(newOwner);
        xWABB(xwabb).transferOwnership(newOwner);
        TokenLocker(locker).transferOwnership(newOwner);
    }
}