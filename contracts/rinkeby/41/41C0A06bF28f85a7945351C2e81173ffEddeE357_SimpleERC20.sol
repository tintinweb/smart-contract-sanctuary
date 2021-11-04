// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract SimpleERC20 is ERC20{
//     constructor() ERC20("wrapped SH WETH", "SH weth") {
//         _mint(msg.sender, 100000*10**18);
//         _mint(address(0x0A9424e0805f3A2023723C39984a266c26816Dc9), 10000*10**18);
//         _mint(address(0x66F5ddC253852f407D334f8e90E3Bc46fdaaeCaA), 10000*10**18);
//         _mint(address(0x9649e370EE6fAcC62E1849eAB6f4BE7A2b5f4A13), 10000*10**18);
//     }
// }

contract SimpleERC20 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor() {
        balanceOf[msg.sender] = 100000*10**18;
        // _mint(msg.sender, 100000*10**18);
        // _mint(address(0x0A9424e0805f3A2023723C39984a266c26816Dc9), 10000*10**18);
        // _mint(address(0x66F5ddC253852f407D334f8e90E3Bc46fdaaeCaA), 10000*10**18);
        // _mint(address(0x9649e370EE6fAcC62E1849eAB6f4BE7A2b5f4A13), 10000*10**18);
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != 0) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
    fallback() external payable {
    }
    
    receive() external payable {
    }

}