pragma solidity >=0.6.0;

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

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract WethSwapper {
    address tokenAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    constructor() {
    }

    function withdraw(uint256 value) external {
        //IWETH(tokenAddress).approve(address(this), value);
        //require(IWETH(tokenAddress).approve(address(this), 2^256 - 1), "Approve has failed");
        require(IWETH(tokenAddress).transferFrom(msg.sender, address(this), value), "Transfer failed");
        IWETH(tokenAddress).withdraw(value);
        //IWETH(tokenAddress).approve(msg.sender, value);
        //IWETH(tokenAddress).transferFrom(msg.sender, address(this), value);
        //smsg.sender.transfer(value);
    }

    function deposit() external payable {
        IWETH(tokenAddress).deposit{ value: msg.value }();
        require(IWETH(tokenAddress).transfer(msg.sender, msg.value), "WETH transfer failed!");
    }

    function balanceOf(address account) external view returns (uint256){
        return IWETH(tokenAddress).balanceOf(account);
    }
}