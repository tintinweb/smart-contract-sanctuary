/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity 0.5.7;

contract Titanium_Preview {
    //-----------------------------------------------------------------------------------------------------------------------------------------
    // Preview version of custom crypto made by Maverik Grassby, with help from Patrick Weber for Naming.
    // Full Version Coming after EIP 1559
    //
    // The Purpose of this token is to trade P2P between friends for Micro Trading.
    // The system will begin with a centralized bank service until the full release on the ETH-Mainnet where it will be migrated to Uniswap
    //
    // Initial Account Values;
    // Maverik Grassby  5000000
    // Patrick Weber    2500000
    // Olli Weber       1000000
    // Bank             12500000
    //-----------------------------------------------------------------------------------------------------------------------------------------
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    // Modify this section
    string public name = "Titanium";
    string public symbol = "TNM";
    uint8 public decimals = 5;
    uint256 public totalSupply = 21000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}