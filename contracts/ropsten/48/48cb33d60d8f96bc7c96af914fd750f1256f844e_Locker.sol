pragma solidity ^0.4.24;

contract RHEM {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Owner {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner`
     * of the contract to the sender account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the current owner
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Locker is Owner {
    RHEM rhem;
    mapping(address => uint256) lockedBalances;
    bool _isLocked = true;
    uint256 totalLockedBalance;

    event Add(address to, uint256 value);
    event Unlock();

    constructor(address _t) public {
        rhem = RHEM(_t);
    }

    /**
     * @dev get Rhem Balance of Contract Address
     */
    function getContractRhemBalance() public view returns (uint256 balance) {
        return rhem.balanceOf(address(this));
    }

    /**
     * @dev Add Address with Lock Rhem Token
     */
    function addLockAccount(address _addr, uint256 _value) public onlyOwner returns (bool success) {
        require(_addr != address(0));
        require(_value > 0);

        uint256 amount = lockedBalances[_addr];
        amount += _value;
        require(amount > 0);

        uint256 currentBalance = getContractRhemBalance();
        totalLockedBalance += _value;
        require(totalLockedBalance > 0);
        require(totalLockedBalance <= currentBalance);

        lockedBalances[_addr] = amount;
        emit Add(_addr, _value);

        return true;
    }

    /**
     * @dev Unlock
     */
    function unlock() public onlyOwner {
        _isLocked = false;

        emit Unlock();
    }

    /**
     * @dev Check if locked
     */
    function isLocked() public view returns (bool) {
        return _isLocked;
    }

    /**
     * @dev Get Lock Balance of Specific address
     */
    function lockedBalanceOf(address _addr) public view returns (uint256 lockedBalance) {
        return lockedBalances[_addr];
    }

    /**
     * @dev Release Lock Rhem Token of the sender
     */
    function release() public returns(bool success) {
        require(!_isLocked);
        require(lockedBalances[msg.sender] > 0);

        rhem.transfer(msg.sender, lockedBalances[msg.sender]);
        delete lockedBalances[msg.sender];

        return true;
    }
}