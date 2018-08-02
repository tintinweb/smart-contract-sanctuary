pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Data is Ownable {

    // node => its parent
    mapping (address => address) private parent;

    // node => its status
    mapping (address => uint8) public statuses;

    // node => sum of all his child deposits in USD cents
    mapping (address => uint) public referralDeposits;

    // client => balance in wei*10^(-6) available for withdrawal
    mapping(address => uint256) private balances;

    // investor => balance in wei*10^(-6) available for withdrawal
    mapping(address => uint256) private investorBalances;

    function parentOf(address _addr) public constant returns (address) {
        return parent[_addr];
    }

    function balanceOf(address _addr) public constant returns (uint256) {
        return balances[_addr] / 1000000;
    }

    function investorBalanceOf(address _addr) public constant returns (uint256) {
        return investorBalances[_addr] / 1000000;
    }

    /**
     * @dev The Data constructor to set up the first depositer
     */
    constructor() public {
        // DirectorOfRegion - 7
        statuses[msg.sender] = 7;
    }

    function addBalance(address _addr, uint256 amount) onlyOwner public {
        balances[_addr] += amount;
    }

    function subtrBalance(address _addr, uint256 amount) onlyOwner public {
        require(balances[_addr] >= amount);
        balances[_addr] -= amount;
    }

    function addInvestorBalance(address _addr, uint256 amount) onlyOwner public {
        investorBalances[_addr] += amount;
    }

    function subtrInvestorBalance(address _addr, uint256 amount) onlyOwner public {
        require(investorBalances[_addr] >= amount);
        investorBalances[_addr] -= amount;
    }

    function addReferralDeposit(address _addr, uint256 amount) onlyOwner public {
        referralDeposits[_addr] += amount;
    }

    function subtrReferralDeposit(address _addr, uint256 amount) onlyOwner public {
        referralDeposits[_addr] -= amount;
    }

    function setStatus(address _addr, uint8 _status) onlyOwner public {
        statuses[_addr] = _status;
    }

    function setParent(address _addr, address _parent) onlyOwner public {
        parent[_addr] = _parent;
    }

}