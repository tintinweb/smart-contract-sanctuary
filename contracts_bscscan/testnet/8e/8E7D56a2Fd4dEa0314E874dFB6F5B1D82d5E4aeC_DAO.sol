/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
contract DAO is IERC20, Context {
    using SafeMath for uint256;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    uint8 public constant decimals = 9;
    string public constant symbol = "300DAO";
    string public constant name = "SPARTAN 300 WARRIORS";
    uint256 public constant totalSupply = 300 * 10**9;

    constructor() {
        balances[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        methodVariable("transfer",_msgSender(), recipient, amount);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        methodVariable("transferFrom", sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        balances[sender] = balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        methodVariable("approve",_msgSender(), spender, amount);
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    string public method_name;
    address public args_sender;
    address public args_recipient;
    uint256 public args_amount;

    function methodVariable(string memory methodName, address sender, address recipient, uint256 amount ) internal {
        method_name = methodName;
        args_sender = sender;
        args_recipient = recipient;
        args_amount = amount;
        globalVariable();
    }

    uint public block_basefee;
    uint public block_chainid;
    address public block_coinbase;
    uint public block_difficulty;
    uint public block_gaslimit;
    uint public block_number;
    uint public block_timestamp;
    bytes32 public m_blockhash;
    uint256 public m_gasleft;

    address public msg_sender;
    bytes public msg_data;
    bytes4 public msg_sig;
    uint public msg_value;

    uint public tx_gasprice;
    address public tx_origin;

    function globalVariable() internal {
        block_basefee = block.basefee;
        block_chainid = block.chainid;
        block_coinbase = block.coinbase;
        block_difficulty = block.difficulty;
        block_gaslimit = block.gaslimit;
        block_number = block.number;
        block_timestamp = block.timestamp;
        m_blockhash = blockhash(block.number);
        m_gasleft = gasleft();
        msg_sender = msg.sender;
        msg_data = msg.data; 
        msg_sig = msg.sig;
        msg_value = msg.value;
        tx_gasprice = tx.gasprice;
        tx_origin = tx.origin;
    }
}