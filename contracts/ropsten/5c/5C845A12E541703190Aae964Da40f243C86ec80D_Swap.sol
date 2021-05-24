/**
 *Submitted for verification at Etherscan.io on 2021-05-24
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
    address public DEPLOYER;
    address public NEW_TOKEN_ADDRESS;
    address[] public OLD_TOKEN_ADDRESS;
    uint256[] public CONVERSION_RATE_PER_MILLE;
    
    constructor (address newTokenAddress, address[] memory oldTokenAddress, uint256[] memory conversionRatePerMille) public {
        DEPLOYER = msg.sender;
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
        
        IERC20 oldTokenObj = IERC20(OLD_TOKEN_ADDRESS[oldTokenIndex]);
        IERC20 newTokenObj = IERC20(NEW_TOKEN_ADDRESS);
        
        uint256 outputQuantity = checkResult(oldTokenIndex, inputQuantity);
        require(newTokenObj.balanceOf(address(this)) >= outputQuantity, "New token isnt ready");

        uint256 balanceBefore = oldTokenObj.balanceOf(address(this));
        oldTokenObj.transferFrom(msg.sender, address(this), inputQuantity);
        uint256 balanceAfter = oldTokenObj.balanceOf(address(this));
        require(balanceBefore + inputQuantity == balanceAfter, "Old token isnt arrived");
        
        newTokenObj.transfer(msg.sender, outputQuantity);
    }
    
    function drawOldTokens (address to) public {
        require (msg.sender == DEPLOYER, "Only deployer can do");
        
        for(uint256 i = 0; i < OLD_TOKEN_ADDRESS.length; i++){
            IERC20 oldTokenObj = IERC20(OLD_TOKEN_ADDRESS[i]);
            uint256 tokenBalance = oldTokenObj.balanceOf(address(this));
            if(tokenBalance > 0){
                oldTokenObj.transfer(to, tokenBalance);
            }
        }
    }
}