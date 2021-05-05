/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract USDCFaucet {
    IERC20 usdc;
    
    mapping(address => bool) hasClaimed;
    
     constructor(IERC20 _usdc)
    {
        usdc = _usdc;
    }

    function claim() public {
        require(usdc.balanceOf(address(this)) >= 10000e6, "faucet drained");
        require(hasClaimed[msg.sender] == false, "address already claimed");
        hasClaimed[msg.sender] = true;
        usdc.transfer(msg.sender, 10000e6);
    }
}