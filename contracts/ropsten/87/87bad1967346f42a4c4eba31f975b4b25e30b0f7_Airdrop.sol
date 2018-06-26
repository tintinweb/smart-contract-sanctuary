pragma solidity ^0.4.21;
 
interface MyTestToken {
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

contract Airdrop is Owned, SafeMath {
    MyTestToken token;

    function Airdrop() public {
        token = MyTestToken(0x7AbB9253F9a173d6EFdbD3c2b0bB67A121BF0274);
    }

    function multiTransfer(address[] _addresses, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i], amount);
        }
    }
    
    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function() public payable {
        revert();
    }
}