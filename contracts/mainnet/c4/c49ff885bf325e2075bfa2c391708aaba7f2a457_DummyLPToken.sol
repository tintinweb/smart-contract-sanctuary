/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// File: contracts/DummyLPToken.sol



/// @notice The (older) MasterChef contract gives out a constant number of DRINK tokens per block.
/// MasterChef the only address with minting rights for DRINK.
/// The idea for this contract is therefore to be the dummy LP token that is deposited into the MasterChef V1 (MCV1) contract.
/// The allocation point for this pool on MCV1 is the total allocation point for all pools that receive incentives on L2.

pragma solidity 0.6.12;

contract DummyLPToken {
    uint256 public immutable totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// _mintTo         Address to which entire supply is to be minted
    /// _totalSupply    Total supply
    constructor(address _mintTo, uint256 _totalSupply) public {
        balanceOf[_mintTo] = _totalSupply;
        totalSupply = _totalSupply;
    }

    function transfer(address to, uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount, "ERC20: balance too low");
        // The following check is pretty much in all ERC20 contracts, but this can only fail if totalSupply >= 2^256
        require(balanceOf[to] + amount >= balanceOf[to], "ERC20: overflow detected");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        require(balanceOf[from] >= amount, "ERC20: balance too low");
        require(allowance[from][msg.sender] >= amount, "ERC20: allowance too low");
        // The following check is pretty much in all ERC20 contracts, but this can only fail if totalSupply >= 2^256
        require(balanceOf[to] + amount >= balanceOf[to], "ERC20: overflow detected");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}