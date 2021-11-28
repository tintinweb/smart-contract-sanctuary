/**
 *Submitted for verification at BscScan.com on 2021-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

// Token
contract Token { 
    
    // Variables
    string  public  name        = "Elon Mars";
    string  public  symbol      = "MARS";
    uint256 public  decimal     = 0;
    uint256 public  totalSupply = 400000000000000;
    address private ownerAddress;

    // Events
    event Transfer(address sender, address to, uint256 amount);
    event Approval(address from, address spender, uint256 amount);
    event OwnershipTransfer(address indexed previousOwner, address indexed newOwner);

    // Maps
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;
    
    // Constructor
    constructor(){

        balanceOf[msg.sender] = totalSupply;
        ownerAddress = msg.sender;
    
    }
    
    // Functions
    function owner() public view returns (address) {
        return ownerAddress;
    }

    function transfer(address _to, uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "You have not enough balance");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
    }
    
    function approve(address _spender, uint256 _amount) public {
        allowance[msg.sender][_spender] += _amount;
        emit Approval(msg.sender, _spender, _amount);
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public {
        require(balanceOf[_from] >= _amount, "User from which money has to deducted does not have enough balance");
        require(allowance[_from][msg.sender] >= _amount, "Spender does not have required allowance");
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        allowance[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);
        emit Approval(_from, msg.sender, _amount);
    }

    // Leaves the contract without owner.
    function renounceOwnership() public {
        require(ownerAddress == msg.sender, "Ownable: caller is not the owner");
        emit OwnershipTransfer(ownerAddress, address(0));
        ownerAddress = address(0);
    }

    // Transfers ownership of the contract to a new account (`newOwner`).
    function transferOwnership(address newOwnerAddress) public {
        require(newOwnerAddress != address(0), "Ownable: new owner is the zero address");
        require(ownerAddress == msg.sender, "Ownable: caller is not the owner");
        emit OwnershipTransfer(ownerAddress, newOwnerAddress);
        ownerAddress = newOwnerAddress;
    }

    // Burn 
    function burn(uint256 _amount) public {
        require(msg.sender != address(0), "BEP20: burn from the zero address");
        require(balanceOf[msg.sender] >= _amount, "BEP20: burn amount exceeds balance");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }
}