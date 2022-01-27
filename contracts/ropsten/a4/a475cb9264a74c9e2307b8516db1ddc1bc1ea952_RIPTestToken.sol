// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./ripLibrary.sol";

contract RIPTestToken is /*IERC20, IERC20Metadata,*/ Ownable  {
    uint8 private m_decimals;
    uint private m_total_supply;
    // m_allowances[token_holder][spender] = allowance;
    mapping(address => mapping (address => uint)) private m_allowances;

    string private m_name = "RIP TestToken";
    string private m_symbol = "RTT";
    mapping(address => uint) private m_balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() Ownable() {
        m_decimals = 0;
        m_total_supply = 0;
    }

    /*function renounceOwnership() public pure override {
        revert("Doesn't make sense to renounce ownership");
    }*/

    function destroySmartContract(address payable i_to) public onlyOwner {
        selfdestruct(i_to);
    }

    function withdraw(address payable i_to, uint256 i_amount) public onlyOwner {
        require(address(this).balance >= i_amount, "Insufficient Funds");
        i_to.transfer(i_amount);
    }

    function deposit() public payable {
        require (msg.value > 0, "you have to put some money in the contract, facciadicazzo!");
        uint num_tickets = msg.value/(10**15);
        uint r = rand(100)+1;
        _mint(msg.sender, r*num_tickets);
    }

    fallback() external payable {}
    receive() external payable {}

    function name() public view /*override*/ returns (string memory) {
        return m_name;
    }

    function symbol() public view /*override*/ returns (string memory) {
        return m_symbol;
    }

    function decimals() public view /*override*/ returns (uint8) {
        return m_decimals;
    }

    function totalSupply() public view /*override*/ returns (uint256) {
        return m_total_supply;
    }

    function balanceOf(address i_who) public view /*override*/ returns (uint256 balance) {
        return m_balances[i_who];
    }

    function transfer(address i_to, uint256 i_value) public /*override*/ returns (bool success) {
        return _transfer(msg.sender, i_to, i_value);
    }

    function transferFrom(address i_from, address i_to, uint256 i_value) public /*override*/ returns (bool success) {
        require(m_allowances[i_from][msg.sender] >= i_value, "Not enough allowance for the spender");
        require(m_balances[i_from] >= i_value, "insufficient funds");
        unchecked {
            m_allowances[i_from][msg.sender] -= i_value;
        }
        emit Approval(i_from, msg.sender, m_allowances[i_from][msg.sender]);
        return _transfer(i_from, i_to, i_value);
    }

    function approve(address i_spender, uint256 i_value) public /*override*/ returns (bool success) {
        m_allowances[msg.sender][i_spender] = i_value;
        emit Approval(msg.sender, i_spender, i_value);
        return true; // why is this function returning a boolean? How can it fail? 
    }

    function allowance(address i_owner, address i_spender) public /*override*/ view returns (uint256 remaining){
        return m_allowances[i_owner][i_spender];
    }

    function _transfer(address i_from, address i_to, uint256 i_value) private returns(bool) {
        require(i_to != address(0), "invalid transfer to the zero address");
        require(i_from != address(0), "invalid transfer from the zero address");
        require(m_balances[i_from] >= i_value, "Insufficient Funds");
        unchecked {
            m_balances[i_from] -= i_value;
            m_balances[i_to] += i_value;
        }
        emit Transfer(i_from, i_to, i_value);
        return true; // why is this function returning a boolean? How can it fail (and not Revert)?
    }

    function mint(address i_to, uint256 i_amount) public onlyOwner {
        _mint(i_to, i_amount);
    }

    // Private functions

    function rand(uint i_max_value) private view returns(uint) {
        uint r = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, m_total_supply, owner())));
        return r%i_max_value;
    }

    function _mint(address i_to, uint256 i_amount) private {
        m_balances[i_to] += i_amount;
        m_total_supply += i_amount;
        emit Transfer(address(0), i_to, i_amount);
    }
}