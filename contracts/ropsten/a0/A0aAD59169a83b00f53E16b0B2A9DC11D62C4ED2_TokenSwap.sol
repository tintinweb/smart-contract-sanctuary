/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity ^0.5.16;

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

contract TokenSwap {
    IERC20 public tokenContract;
    address public ownerAddress;
    
    constructor () public {
        tokenContract = IERC20(address(0x722dd3F80BAC40c951b51BdD28Dd19d435762180));
        ownerAddress = address(0xFb09a3262f72A1fFe5E21f01BD5f08Ef641E6092);
    }

    function swapview(uint amount) public view returns (uint){
        //require(msg.sender == my || msg.sender == owner2, "Not authorized");
        require(
            tokenContract.allowance(ownerAddress, address(this)) >= amount,
            "Allowance too low"
        );
       
       return 1;
    }
    
    function swap(uint amount) public returns (uint){
        //require(msg.sender == my || msg.sender == owner2, "Not authorized");
        require(
            tokenContract.allowance(ownerAddress, address(this)) >= amount,
            "Allowance too low"
        );
        
       _safeTransferFrom(tokenContract, ownerAddress, msg.sender, amount);
       
       return 1;
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint amount
    ) public  {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }
}