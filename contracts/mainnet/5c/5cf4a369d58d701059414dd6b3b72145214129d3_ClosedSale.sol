pragma solidity ^0.4.11;

contract ERC20Constant {
    function balanceOf( address who ) constant returns (uint value);
}
contract ERC20Stateful {
    function transfer( address to, uint value) returns (bool ok);
}
contract ERC20Events {
    event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Constant, ERC20Stateful, ERC20Events {}

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract ClosedSale is Owned {

    ERC20 public token;

    // Amount of Token received per ETH
    uint256 public tokenPerEth;

    // Address that can buy the Token
    address public buyer;

    // Forwarding address
    address public receiver;

    event LogWithdrawal(uint256 _value);
    event LogBought(uint _value);

    function ClosedSale (
        ERC20   _token,
        address _buyer,
        uint256 _tokenPerEth,
        address _receiver
    )
        Owned()
    {
        token       = _token;
        receiver    = _receiver;
        buyer       = _buyer;
        tokenPerEth = _tokenPerEth;
    }

    // Withdraw the token
    function withdrawToken(uint256 _value) onlyOwner returns (bool ok) {
        return ERC20(token).transfer(owner,_value);
        LogWithdrawal(_value);
    }

    function buy(address beneficiary) payable {
        require(beneficiary == buyer);

        uint orderInTokens = msg.value * tokenPerEth;
        token.transfer(beneficiary, orderInTokens);
        receiver.transfer(msg.value);

        LogBought(orderInTokens);
    }

    function() payable {
        buy(msg.sender);
    }
}