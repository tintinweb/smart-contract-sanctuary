/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

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

contract TransferProxy {
    address payable public owner;
    event ForwardBnb(address recipient, uint256 amount);
    event ForwardToken(address token, address recipient, uint256 amount);
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    function forward1(address tokenAddress, uint256 amount, address payable recipient) payable public {
        forwardToken(tokenAddress, recipient, amount);
        forwardBnb(recipient);
    }
    
    function forward2(address token0, uint256 amount0, address token1, uint256 amount1, address payable recipient) public payable {
        forwardToken(token0, recipient, amount0);
        forwardToken(token1, recipient, amount1);
        forwardBnb(recipient);
    }
    
    function forwardToken(address token, address recipient, uint256 amount) private {
        if(amount != 0) {
            IERC20 iERC20 = IERC20(token);
            require(amount <= iERC20.allowance(msg.sender, address(this)), "Not enough allowance");
            require(iERC20.transferFrom(msg.sender, recipient, amount), "Transfer failed!");
            emit ForwardToken(token, recipient, amount);
        }
    }
    
    function forwardBnb(address payable recipient) private {
        require(recipient.send(msg.value), "Forward BNB failed");
        emit ForwardBnb(recipient, msg.value);
    }
    
    function withdraw(address _token, uint256 _amount) external {
        require(msg.sender == owner);
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function withdrawBNB(uint256 _amount) external {
        require(msg.sender == owner);
        owner.transfer(_amount);
    }
}