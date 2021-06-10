/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.5.0;

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

contract Swap {
    address private constant CONST_BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    address public OWNER;
    address public NEW_TOKEN_ADDRESS;
    address[] public OLD_TOKEN_ADDRESS;
    uint256[] public CONVERSION_RATE_PER_MILLE;
    
    event TokenSwapped (address requestor, address inputToken, uint256 inputQuantity, uint256 outputQuantity);
    
    constructor (address owner, address newTokenAddress, address[] memory oldTokenAddress, uint256[] memory conversionRatePerMille) public {
        OWNER = owner;
        NEW_TOKEN_ADDRESS = newTokenAddress;
        OLD_TOKEN_ADDRESS = oldTokenAddress;
        CONVERSION_RATE_PER_MILLE = conversionRatePerMille;
    }

    function checkResult (uint256 oldTokenIndex, uint256 inputQuantity) public view returns (uint256) {
        uint256 conversionRate = CONVERSION_RATE_PER_MILLE[oldTokenIndex];
        return (conversionRate * inputQuantity) / 1000;
    }

    function doSwap (uint256 oldTokenIndex, uint256 inputQuantity) public {
        require(inputQuantity > 0, "Invalid input quantity");
        require(oldTokenIndex < OLD_TOKEN_ADDRESS.length, "Out of index");
        
        IERC20 oldTokenObj = IERC20(OLD_TOKEN_ADDRESS[oldTokenIndex]);
        IERC20 newTokenObj = IERC20(NEW_TOKEN_ADDRESS);
        
        uint256 outputQuantity = checkResult(oldTokenIndex, inputQuantity);
        require(newTokenObj.balanceOf(address(this)) >= outputQuantity, "New token isnt ready");

        uint256 balanceBefore = oldTokenObj.balanceOf(CONST_BURN_ADDRESS);
        oldTokenObj.transferFrom(msg.sender, CONST_BURN_ADDRESS, inputQuantity);
        uint256 balanceAfter = oldTokenObj.balanceOf(CONST_BURN_ADDRESS);
        require(balanceBefore + inputQuantity == balanceAfter, "Old token isnt arrived");
        
        newTokenObj.transfer(msg.sender, outputQuantity);
        emit TokenSwapped (msg.sender, OLD_TOKEN_ADDRESS[oldTokenIndex], inputQuantity, outputQuantity);
    }
    
    function drawToken (address token, uint256 quantity, address to) public {
        require (msg.sender == OWNER, "Only Owner can do");
        
        IERC20 tokenObj = IERC20(token);
        require (tokenObj.balanceOf(address(this)) >= quantity, "Balance insufficient");
        
        tokenObj.transfer(to, quantity);
    }
}