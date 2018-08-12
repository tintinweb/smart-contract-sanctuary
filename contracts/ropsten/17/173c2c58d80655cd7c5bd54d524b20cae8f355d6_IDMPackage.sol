pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// IDM ERC20 Token
// ----------------------------------------------------------------------------
contract IDMToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

// ----------------------------------------------------------------------------
// IDM Package
// ----------------------------------------------------------------------------
contract IDMPackage {
    using SafeMath for uint;

    address  owner;

    uint     lockedFund;
    IDMToken idmToken;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    event Withdraw(address indexed to, uint tokens);


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _contract, address _owner) public {
        owner    = _owner;
        idmToken = IDMToken(_contract);
    }


    function totalBalance() public constant returns (uint) {
        return idmToken.balanceOf(this);
    }


    function totalLockedFund() public constant returns (uint) {
        return lockedFund;
    }


    function totalWithdrawable() public constant returns (uint) {
        return totalBalance().sub(totalLockedFund());
    }


    function lockFund(uint amount) public onlyOwner returns (bool) {
        require(amount <= totalBalance());
        lockedFund = amount;
        return true;
    }


    function withdraw(address to, uint amount) public onlyOwner returns (bool) {
        require(amount <= totalWithdrawable());

        idmToken.transfer(to, amount);

        emit Withdraw(to, amount);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}