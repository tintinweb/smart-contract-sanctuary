/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity ^0.4.15;

// ERC20 Interface
contract ERC20 {
    function transfer(address _to, uint _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint balance);
}

contract PresalePool {
    address public owner;
    mapping (address => bool) public whitelist;
    bool whitelistAll;
    mapping (address => uint) public balances;
    bool public closed;
    uint public totalDeposits;
    ERC20 public token;

    event Deposit(
        address indexed _from,
        uint _value
    );
    event Payout(
        address indexed _to,
        uint _value
    );
    event Refund(
        address indexed _to,
        uint _value
    );

    function PresalePool() payable {
        owner = msg.sender;
        deposit(owner, msg.value);
    }

    function included(address buyer) internal constant returns (bool ok) {
        return whitelistAll || whitelist[buyer];
    }
    
    function refund(address buyer) internal {
        uint amount = balances[buyer];
        // if the buyer is not included in the pool
        // then the buyer's contribution is not included
        // in totalDeposits, so we only need to update
        // totalDeposits if the buyer is refunding their funds
        // while the pool is open
        if (!closed) {
            totalDeposits -= amount;
        }
        balances[buyer] = 0;
        buyer.transfer(amount);
        Refund(buyer, amount);
    }

    function deposit(address buyer, uint amount) internal {
        require(!closed);
        balances[buyer] += amount;
        totalDeposits += amount;
        Deposit(buyer, amount);
    }

    function payoutTokens(address buyer) internal {
        uint tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0);
        uint buyerDeposit = balances[buyer];
        uint buyerShare = (buyerDeposit * tokenBalance) / totalDeposits;
        totalDeposits -= buyerDeposit;
        balances[buyer] = 0;
        require(token.transfer(buyer, buyerShare));
        Payout(buyer, buyerShare);
    }

    function close(address presaleAddress, address[] _whitelist) public {
        require(msg.sender == owner);
        require(!closed);
        closed = true;
        totalDeposits = balances[owner];
        whitelist[owner] = true;
        for (uint i = 0; i < _whitelist.length; i++) {
            address addr = _whitelist[i];
            whitelist[addr] = true;
            totalDeposits += balances[addr];
        }
        presaleAddress.transfer(totalDeposits);
    }

    function closeAllowAll(address presaleAddress) public {
        require(msg.sender == owner);
        require(!closed);
        closed = true;
        whitelistAll = true;
        presaleAddress.transfer(totalDeposits);
    }

    function setToken(address tokenAddress) public {
        require(msg.sender == owner);
        token = ERC20(tokenAddress);
    }

    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

    function () payable {
        // to deposits send > 1 finney, to refund or payout send 0 eth
        if (msg.value <= 1 finney) {
            // refund deposits if the sale isn't closed
            // or the buyer was not included in the sale's whitelist
            if (!closed || !included(msg.sender)) {
                refund(msg.sender);
                return;
            }
            payoutTokens(msg.sender);
        } else {
            deposit(msg.sender, msg.value);
        }
    }
}