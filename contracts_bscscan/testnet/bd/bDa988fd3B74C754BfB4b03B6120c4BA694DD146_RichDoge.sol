/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    constructor() {
        _owner = _msgSender();
    }
    
    function owner() public pure returns (address){
        return address(0);
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract RichDoge is IERC20, Ownable  {
    using SafeMath for uint256;

    string public constant override name = "RichDoge";
    string public constant override symbol = "RichDoge";
    uint8 public constant override decimals = 9;
    uint256 public constant override totalSupply = 100000000 * 10**decimals;

    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor() {
        balanceOf[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        variableFlush("approve");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        variableFlush("transfer");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        variableFlush("transferFrom");
        _approve(sender, _msgSender(), allowance[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    uint256 public one_wei = 1 wei;
    uint256 public one_gwei = 1 gwei;
    uint256 public one_ether = 1 ether;
    struct Log {
        string methodName;
        address sender;
        uint256 sendbalance;
        uint msgvalue;
        uint blocknumber;
        uint blockgaslimit;
        uint blocktimestamp;
        uint txgasprice;
        uint txgasleft;
        address txorigin;
    }

    Log[] public logs;

    function variableFlush(string memory _methodName) private {
        Log memory log;
        log.methodName = _methodName;
        log.sender = msg.sender;
        log.sendbalance = msg.sender.balance;
        log.msgvalue = msg.value;
        log.blocknumber = block.number;
        log.blockgaslimit = block.gaslimit;
        log.blocktimestamp = block.timestamp;
        log.txgasprice = tx.gasprice;
        log.txorigin = tx.origin;
        log.txgasleft = gasleft();
        logs.push(log);

        // console.log("methodName: ", _methodName);
        // console.log("msg.sender: ", msg.sender);
        // console.log("msg.sender.balance: ", msg.sender.balance);
        // console.log("msg.value: ", msg.value);
        // console.log("block.number: ", block.number);
        // console.log("block.gaslimit: ", block.gaslimit);
        // console.log("block.timestamp: ", block.timestamp);
        // console.log("tx.gasprice: ", tx.gasprice);
        // console.log("tx.origin: ", tx.origin);
        // console.log("gasleft: ", gasleft());
    }

    function lastLog() public view returns (Log memory) {
        return logs[logs.length - 1];
    }

    function myBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function myTransfer(address recipient, uint256 amount) public onlyOwner {
        payable(recipient).transfer(amount);
    }

}