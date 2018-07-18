pragma solidity ^0.4.21;

// File: contracts/ERC20Basic.sol

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/ERC20.sol

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Ownable.sol

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require((msg.sender == owner) || (tx.origin == owner));
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/AssignRevenue.sol

contract AssignRevenue is Ownable {
    ERC20 public APPROVE_CONTRACT;
    address public APPROVE_OWNER;

    event RevenueAssign(address indexed beneficiary, address revenue_contract, uint256 amount);

    function setContract(ERC20 _contract, address _owner) external onlyOwner {
        APPROVE_CONTRACT = _contract; 
        APPROVE_OWNER = _owner;
    }

    function transferRevenue(address _address, uint256 _amount) external onlyOwner {
        APPROVE_CONTRACT.transferFrom(APPROVE_OWNER,_address, _amount);
        emit RevenueAssign(
            msg.sender,
            APPROVE_CONTRACT,
            _amount
        );
    }
}