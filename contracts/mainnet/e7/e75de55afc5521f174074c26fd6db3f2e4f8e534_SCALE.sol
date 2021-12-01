/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC721 {

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

interface Token {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {

    address public owner;

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function changeOwnerForce(address _newOwner) public isOwner {
        require(_newOwner != owner);
        owner = _newOwner;
        emit OwnerUpdate(owner, _newOwner);
    }

}

contract Controlled is Owned {

    bool public transferEnable = true;

    bool public lockFlag = true;

    constructor() {
        setExclude(msg.sender);
    }

    mapping(address => bool) public locked;

    mapping(address => bool) public exclude;

    function enableTransfer(bool _enable) public isOwner{
        transferEnable = _enable;
    }

    function disableLock(bool _enable) public isOwner returns (bool success){
        lockFlag = _enable;
        return true;
    }

    function addLock(address _addr) public isOwner returns (bool success){
        require(_addr != msg.sender);
        locked[_addr] = true;
        return true;
    }

    function setExclude(address _addr) public isOwner returns (bool success){
        exclude[_addr] = true;
        return true;
    }

    function removeLock(address _addr) public isOwner returns (bool success){
        locked[_addr] = false;
        return true;
    }

    modifier transferAllowed(address _addr) {
        if (!exclude[_addr]) {
            assert(transferEnable);
            if(lockFlag){
                assert(!locked[_addr]);
            }
        }
        _;
    }

    modifier validAddress(address _addr) {
        assert(address(0x0) != _addr && address(0x0) != msg.sender);
        _;
    }
}

contract StandardToken is Token, Controlled {

    string public name = "";
    string public symbol = "";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    constructor (string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public override transferAllowed(msg.sender) validAddress(_to) returns (bool success) {
        require(_value > 0);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override transferAllowed(_from) validAddress(_to) returns (bool success) {
        require(_value > 0);
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public override transferAllowed(_spender) returns (bool success) {
        require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(totalSupply + amount > totalSupply);
        require(balances[account] + amount > balances[account]);

        balances[account] += amount;
        totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(totalSupply >= amount);
        require(balances[account] >= amount);

        totalSupply -= amount;
        balances[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

}

contract SCALE is StandardToken {

    ERC721 public lizardContract;
    ERC721 public dragonContract;

    uint256 public immutable PER_DAY_PER_LIZARD_REWARD = 10 ether;
    uint256 public immutable PER_DAY_PER_DRAGON_REWARD = 50 ether;
    uint256 private MINE_PERIOD = 86400;
    uint256 public GENESIS = 1635379200;

    bool public mineIsActive = true;

    mapping(address => uint256) public last;

    constructor(address lizard, address dragon) StandardToken("SCALE","SCALE"){
        lizardContract = ERC721(lizard);
        dragonContract = ERC721(dragon);
        _mint(address(0x008FA9C81e6b6184aEce369017E80569b8FC753fBc), 200 ether);
        _mint(address(0x00C36BCC133EDfe4E3BBe0D92aF330bD5Ca946A258), 600 ether);
        _mint(address(0x00f0a5043111c2a35fbd1acfb588c382e781ad6aef), 1350 ether);
        _mint(address(0x00e08163c2bab9d0f933cd67fa52ec8687df98a55c), 1860 ether);

        _mint(address(0x0034Cf7Ac942A815DDEDdF1319ce91dEa69Af46dCb), 4600 ether);
        _mint(address(0x00D8c88B8681B3F699d8DAe59ec239fB0925acC660), 400 ether);
        _mint(address(0x004B02b95F480FDD4d55c2aD7D5c6c70152cC5b8F9), 400 ether);
        _mint(address(0x00f8ae589B64890C4A844405d37D1918DfF9fC136d), 8000 ether);
        _mint(address(0x008FA9C81e6b6184aEce369017E80569b8FC753fBc), 200 ether);
    }

    function closeMineState() public isOwner {
        require(mineIsActive, "Mining is currently unavailable");
        mineIsActive = false;
    }

    function openMineState(uint256 timestamp) public isOwner {
        require(!mineIsActive, "Mining is currently on");
        mineIsActive = true;
        GENESIS = timestamp;
    }

    function claim(address user) external {
        require(mineIsActive, "Mining is currently unavailable");
        require(block.timestamp > GENESIS, "Mining is currently unavailable");
        uint256 owed = 0;
        uint256 total = lizardContract.balanceOf(user);
        uint256 minePeriods = minePeriod(last[user]);
        owed += (minePeriods * PER_DAY_PER_LIZARD_REWARD) * total;
        total = dragonContract.balanceOf(user);
        owed += (minePeriods * PER_DAY_PER_DRAGON_REWARD) * total;
        last[user] = block.timestamp;
        _mint(user, owed);
    }

    function getTotalClaimable(address user)  external view returns(uint256) {
        if (!mineIsActive) {
            return 0;
        }
        if (block.timestamp < GENESIS) {
            return 0;
        }
        uint256 owed = 0;
        uint256 total = lizardContract.balanceOf(user);
        uint256 minePeriods = minePeriod(last[user]);
        owed += (minePeriods * PER_DAY_PER_LIZARD_REWARD) * total;
        total = dragonContract.balanceOf(user);
        owed += (minePeriods * PER_DAY_PER_DRAGON_REWARD) * total;
        return owed;
    }

    function minePeriod(uint256 claimedTime) internal view returns (uint256) {
        uint256 lastTime = Math.max(claimedTime, GENESIS);
        return (block.timestamp - lastTime / MINE_PERIOD * MINE_PERIOD) / MINE_PERIOD;
    }

}