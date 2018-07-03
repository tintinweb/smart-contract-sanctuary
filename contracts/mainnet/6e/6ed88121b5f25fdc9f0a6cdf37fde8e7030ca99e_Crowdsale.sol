pragma solidity 0.4.21;

interface DreamToken {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function totalSupply() external constant returns (uint);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Crowdsale is Owned, SafeMath {
    address public escrowAddress;
    uint public totalEthInWei;
    
    uint amountPerEther = 750;
    uint minAmount = 1e16; // 0.01 ETH
    DreamToken token;

    function Crowdsale() public {
        escrowAddress = owner;
        token = DreamToken(0xBcd4012cECBbFc7a73EC4a14EBb39406D361a0f5);
    }

    function setEscrowAddress(address newAddress)
    public onlyOwner returns (bool success) {
        escrowAddress = newAddress;

        return true;
    }
    
    function setAmountPerEther(uint newAmount)
    public onlyOwner returns (bool success) {
        amountPerEther = newAmount;

        return true;
    }
    
    function() external payable {
        require(msg.value >= minAmount);
        totalEthInWei = totalEthInWei + msg.value;
        
        if (owner != msg.sender) {
            uint amount = safeDiv(msg.value, 1e10);
            amount = safeMul(amount, amountPerEther);
            token.transferFrom(owner, msg.sender, amount);
            
            //Transfer ether to fundsWallet
            escrowAddress.transfer(msg.value);
            //emit Transfer(msg.sender, _to, _value);
        }
    }
}