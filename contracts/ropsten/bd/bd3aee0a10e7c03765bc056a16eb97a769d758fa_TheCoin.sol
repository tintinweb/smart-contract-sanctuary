/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity ^0.8.0;

contract TheCoin {
    uint256 public MAX_SUPPLY = 1000000;
    uint256 public immutable TRANSACTION_FEE = 1;
    address public minter;
    uint256 private _supply;

    uint256 public initialSupply = 50000;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value);
    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        minter = msg.sender;
        mint(msg.sender, initialSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        require(_supply + amount < MAX_SUPPLY, "Minting would exceed MAX_SUPPLY");
        require(msg.sender == minter, "Caller is not the minter");
        _balances[receiver] += amount;
        _supply += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        uint256 initialBalance = _balances[msg.sender];
        require(amount <= initialBalance, "Not enough balance to burn");
        transfer(address(0), amount);
        _supply -= amount;
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        require(msg.sender == minter, "Caller is not the minter");
        address previousMinter = minter;
        minter = newMinter;
        emit MintershipTransfer(previousMinter, newMinter);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 _value
    ) private {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= _value + TRANSACTION_FEE, "Balance is not enough to do this transaction");

        _balances[sender] = senderBalance - _value - TRANSACTION_FEE;
        _balances[recipient] += _value;

        // Reward the minter
        _balances[minter] += TRANSACTION_FEE;

        emit Transfer(sender, recipient, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_allowances[_from][msg.sender] >= _value, "Allowance is not enough");
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        address owner = msg.sender;
        _allowances[owner][_spender] = _value;
        emit Approval(owner, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }
}