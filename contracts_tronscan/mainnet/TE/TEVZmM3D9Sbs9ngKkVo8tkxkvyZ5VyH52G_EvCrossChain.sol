//SourceUnit: EvCrossChain.sol

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.12;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

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

contract EvCrossChain is Ownable {
    using SafeMath for uint256;
    IERC20 public token;

    uint256 public fee = 1 * 10 ** 6;

    string public name;

    mapping(address => bool) private executors;

    uint256 private feeRate = 100;

    uint256 private serviceFee = 0;

    address private teamAddress;

    bool public pause;

    uint256 public minAmount = 100000000000 * 10 ** 6;

    constructor() public {
        token = IERC20(0x41d774fd99c7072ec1e55a24228b12a1ac88ad21b2);
        name = "EV CROSS CHAIN";
        teamAddress = address(msg.sender);
        executors[msg.sender] = true;
    }

//    function updateMinAmount(uint256 min) onlyOwner public returns (bool){
//        minAmount = min;
//        return true;
//    }

    modifier onlyExecutor() {
        require(executors[msg.sender], "not executor");
        _;
    }


    function updateTeamAddress(address newAddress) public onlyOwner returns (bool){
        teamAddress = newAddress;
        return true;
    }

    function addExecutor(address executor) public onlyOwner returns (bool){
        executors[executor] = true;
        return true;
    }

    function removeExecutor(address executor) public onlyOwner returns (bool){
        executors[executor] = false;
        return true;
    }


    function updateFee(uint256 _fee) public onlyOwner returns (bool){
        fee = _fee;
        return true;
    }

    function sendToken(address to, uint256 amount) public onlyExecutor returns (bool){
        token.transfer(to, amount);
        return true;
    }

    function sendFee(address payable to, uint256 amount) public onlyExecutor returns (bool){
        to.transfer(amount);
        return true;
    }

    function getFeeData() public returns (uint256 _rate, uint256 _fee){
        _rate = feeRate;
        _fee = serviceFee;
    }

    function updateRate(uint256 _rate) public onlyOwner returns (bool){
        feeRate = _rate;
        return true;
    }

    function updateSFee(uint256 _sFee) public onlyOwner returns (bool){
        serviceFee = _sFee;
        return true;
    }

    function updatePause(bool _pause) public onlyOwner returns (bool){
        pause = _pause;
        return true;
    }

    function exchange(uint256 amount, string memory _address) public payable returns (string memory){
        require(msg.value >= fee, "fee not enough");
        require(amount >= minAmount, "min amount error");
        require(!pause, "operate error");
        address sender = address(msg.sender);
        uint256 teamAmount = amount.mul(feeRate).div(10000).add(serviceFee);
        uint256 cAmount = amount.sub(teamAmount);
        token.transferFrom(sender, teamAddress, teamAmount);
        token.transferFrom(sender, address(this), cAmount);
        return _address;
    }
}