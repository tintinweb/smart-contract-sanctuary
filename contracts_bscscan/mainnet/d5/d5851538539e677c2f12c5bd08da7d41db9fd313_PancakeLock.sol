pragma solidity =0.6.6;

import "./IERC20.sol";

contract PancakeLock {

    address internal constant PancakeRouter = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    uint256 number;
    
    address private _owner;
    
    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "PERMISSION_DENIED"
        );
        _;
    }

    
    constructor() public {
        _owner = msg.sender;
    }
    
    
    function lockToPancake(
        address token,
        uint amountBNBDesired,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountBNBMin
    ) external payable{
        IERC20 erc20 = IERC20(token);
        require(address(this).balance >= amountBNBDesired, "INSUFFICIENT_BNB_AMOUNT");
        require(erc20.balanceOf(address(this)) >= amountTokenDesired, "INSUFFICIENT_TOKEN_AMOUNT");
        (bool success,) = PancakeRouter.call{value: amountBNBDesired, gas: 9999999}(
            abi.encodeWithSelector(
                0xf305d719, 
                token, 
                amountTokenDesired, 
                amountTokenMin, 
                amountBNBMin, 
                address(this), 
                block.timestamp + 1200));
        require(success, 'LOCK_FAILED');
    }
    
    
    function receiverBack(address token) external onlyOwner {
        IERC20 erc20 = IERC20(token);
        address self = address(this);
        uint balance = erc20.balanceOf(self);
        if(balance > 0) {
            erc20.transfer(msg.sender, balance);
        }
    }
    
    
    function receiverBackBNB() external onlyOwner {
        uint balance = address(this).balance;
        if(balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }
    
    function approve(address token, uint value) external onlyOwner returns (bool){
        IERC20 erc20 = IERC20(token);
        return erc20.approve(PancakeRouter, value);
    }
    
    
    receive() external payable {
        
    }
    
}