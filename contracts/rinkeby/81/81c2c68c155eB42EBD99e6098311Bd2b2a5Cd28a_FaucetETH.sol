/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

pragma solidity ^0.8.6;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract FaucetETH {

    uint256 public withdrawLimit;
    mapping(address => bool) public addressLimit;
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WithdrawETH(address user, uint256 amount);
    
    constructor() {
        owner = msg.sender;
        withdrawLimit = 0.3 ether;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function setWithdrawLimit(uint256 num) public onlyOwner {
        withdrawLimit = num;
    }
    
    
    function withdrawETH () public {
        require(!addressLimit[msg.sender], 'done');
        
        addressLimit[msg.sender] = true;
        payable(msg.sender).transfer(withdrawLimit);
        emit WithdrawETH(msg.sender, withdrawLimit);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner{
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function withdrawAllETH (uint256 vault) public onlyOwner  {
        payable(owner).transfer(vault);
        emit WithdrawETH(owner, vault);
    }

    function addETH() public payable {

    }
}