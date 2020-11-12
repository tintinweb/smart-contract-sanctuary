pragma solidity ^0.5.16;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract JTN is Ownable{
    using SafeMath for uint;
    uint256 public totalStake;
    uint256 public totalVipStake;
    uint32 public currentVipCount;
    uint32 public currentUserCount;
    uint8  public governanceRate = 0;

    mapping (uint32  => address) public userList;
    mapping (address => bool) public vipMap;
    mapping (address => uint256) private _balances;
    mapping (address => address) public levelToUp;
    mapping (address => address[]) public levelToDown;
    mapping (address => uint) public vipProfit;

    event NewVip(address indexed from, uint256 amount);
    event Deposit(address indexed from, uint256 amount);
    event AddAdviser(address indexed down, address indexed up);
    event Withdraw(address indexed to, uint256 value);
    event GovWithdraw(address indexed to, uint256 value);


    uint constant private minInvestmentLimit = 10 finney;
    uint constant private vipBasePrice = 1 ether;
    uint constant private vipLevelLimit = 100;

    constructor()public {
    }

    function buyVip() public payable{
        uint cost = vipPrice();
        require(msg.value == cost, "vip cost mismatch");
        require(!vipMap[msg.sender], "vip already");
        vipMap[msg.sender] = true;
        uint balance = balanceOf(msg.sender);
        if(balance > 0){
            totalVipStake = totalVipStake.add(balance);
        }
        currentVipCount++;
        emit NewVip(msg.sender, msg.value);
    }
    function depositWithAdviser(address _adviser) public payable{
        require(_adviser != address(0) , "zero address input");
        if(_balances[msg.sender] == 0){
            address upper = levelToUp[msg.sender];
            if( upper == address(0) && _adviser != msg.sender && isVip(_adviser)){
                levelToUp[msg.sender] = _adviser;
                levelToDown[_adviser].push(msg.sender);
            }
        }

        deposit();
        emit AddAdviser(msg.sender,_adviser);
    }

    function deposit() private {
        if(_balances[msg.sender] == 0){
            require(msg.value >= minInvestmentLimit,"!deposit limit");
            userList[currentUserCount] = msg.sender;
            currentUserCount++;
        }
        require(msg.value > 0, "!value");
        address upper = levelToUp[msg.sender];

        totalStake = totalStake.add(msg.value);
        if(isVip(msg.sender)){
            totalVipStake = totalVipStake.add(msg.value);
        }

        if(upper != address(0)){
            uint profit = msg.value.div(100);
            _balances[upper] = _balances[upper].add(profit);
            vipProfit[upper] = vipProfit[upper].add(profit);
        }
        _balances[msg.sender] = _balances[msg.sender].add(msg.value);
        emit Deposit(msg.sender,msg.value);
    }

    function withdraw(uint256 _amount) public {
        require(_amount > 0, "!value");
        uint reduceAmount = _amount.mul(100).div(100-governanceRate);
        require(reduceAmount <= _balances[msg.sender], "!balance limit");
        _balances[msg.sender] = _balances[msg.sender].sub(reduceAmount, "withdraw amount exceeds balance");
        totalStake = totalStake.sub(reduceAmount);
        if(isVip(msg.sender)){
            totalVipStake = totalVipStake - reduceAmount;
        }
        msg.sender.transfer(_amount);
        emit Withdraw(msg.sender, _amount);
    }

    function govWithdrawEther(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        msg.sender.transfer(_amount);
        emit GovWithdraw(msg.sender, _amount);
    }

    function changeRate(uint8 _rate)onlyOwner public {
        require(100 > _rate, "governanceRate big than 100");
        governanceRate = _rate;
    }

    function() external payable {
        deposit();
    }

    function vipPrice() public view returns (uint) {
        uint difficult = currentVipCount/vipLevelLimit+1;
        return difficult.mul(vipBasePrice);
    }
    function isVip(address account) public view returns (bool) {
        return vipMap[account];
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function subCountOf(address account) public view returns (uint) {
        return levelToDown[account].length;
    }

    function profitOf(address account) public view returns (uint) {
        return vipProfit[account];
    }

}