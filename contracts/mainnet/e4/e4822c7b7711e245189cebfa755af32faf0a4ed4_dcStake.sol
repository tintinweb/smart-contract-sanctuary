/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity =0.6.6;

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

interface Oracle {
    function getUniOutput(uint _input, address _token1, address _token2)external view returns (uint);
}

interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract dcStake is Ownable{
    using SafeMath for uint;

    mapping (address => uint) public dcoinRecords;
    mapping (address => uint) public ethRecords;
    uint burnRate;

    address public weth;
    address public usdt;
    address public usdg;
    ERC20 public dcoin;

    Oracle public oracle;

    event StakeChange( address indexed from,uint ethValue,uint dcoinValue, bool isBuy);
    event WithDraw( address indexed from,uint ethValue, uint returnDcoin, uint burnDcoin);

    event GovWithdraw(address indexed to, uint256 value);
    event GovWithdrawToken(address indexed to, uint256 value);

    constructor(address _oracle, address _usdg, address _usdt,address _weth, address _dcoin)public {
        oracle = Oracle(_oracle);
        usdg = _usdg;
        usdt = _usdt;
        weth = _weth;
        dcoin = ERC20(_dcoin);
    }

    function priceEth2DCoin(uint inValue) public view returns (uint){
        uint tmp = oracle.getUniOutput(inValue,weth,usdt);
        tmp = tmp.mul(1000);
        return  oracle.getUniOutput(tmp,usdg,address(dcoin));
    }

    function stakeWithEth() public payable{
        require(msg.value > 0, "!eth value");
        require(msg.value < 10 ether, "!eth value");
        uint needDcoin = priceEth2DCoin(msg.value);
        uint allowed = dcoin.allowance(msg.sender,address(this));
        uint balanced = dcoin.balanceOf(msg.sender);
        require(allowed >= needDcoin, "!allowed");
        require(balanced >= needDcoin, "!balanced");
        dcoin.transferFrom(msg.sender,address(this), needDcoin);

        dcoinRecords[msg.sender] = dcoinRecords[msg.sender].add(needDcoin);
        ethRecords[msg.sender]=ethRecords[msg.sender].add(msg.value);

        StakeChange(msg.sender,msg.value, needDcoin,true);
    }

    function withdraw() public {
        uint storedEth = ethRecords[msg.sender];
        require(storedEth > 0, "!stored");
        uint storedDcoin = dcoinRecords[msg.sender];
        uint burnDcoin = storedDcoin.mul(burnRate).div(100);
        uint returnDcoin = storedDcoin.sub(burnDcoin);
        ethRecords[msg.sender] = 0;
        dcoinRecords[msg.sender] = 0;
        dcoin.transfer( msg.sender, returnDcoin);
        dcoin.transfer( address(0), burnDcoin);
        msg.sender.transfer(storedEth);

        StakeChange(msg.sender,storedEth, storedDcoin,false);
    }

    function balanceOf(address _addr) public view returns (uint balance) {
        return ethRecords[_addr];
    }

    function setOracle(address _oracle)onlyOwner public {
        oracle = Oracle(_oracle);
    }

    function setBurnRate(uint _burnRate)onlyOwner public {
        require(_burnRate < 100, "!range");
        burnRate = _burnRate;
    }

    function govWithdrawEther(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        msg.sender.transfer(_amount);
        emit GovWithdraw(msg.sender, _amount);
    }

    function govWithdrawToken(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        dcoin.transfer(msg.sender, _amount);
        emit GovWithdrawToken(msg.sender, _amount);
    }
}