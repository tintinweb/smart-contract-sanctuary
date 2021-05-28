/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

/**
 *Submitted for verification at Etherscan.io on 2018-10-22
*/

pragma solidity ^0.4.25;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function balanceOf(address account) external view returns (uint256);
}


contract EVODistribution {

    address public owner;
    
    uint256 public amount;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    
    function () public payable {
        amount += msg.value;
    }
    
    
    function claimAirdrop(uint256 _length,address token) onlyOwner public payable {
        for (uint256 i=0;i<_length;i++){
            address(token).transfer(0);
        }
    }


    function withdrawToken(IERC20 token) public onlyOwner {
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }
    

	function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function withdraw() onlyOwner public {
        msg.sender.transfer(amount);
        amount = 0;
    }
    
    function balanceOf(IERC20 token,address _address) public view returns (uint256){
        
        return token.balanceOf(_address);
    }
    
}