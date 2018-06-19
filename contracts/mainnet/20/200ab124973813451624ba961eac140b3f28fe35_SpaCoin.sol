pragma solidity ^0.4.0;

contract SpaCoin {
    int64 constant TOTAL_UNITS = 100000 ;
    int64 outstanding_coins ;
    address owner ;
    mapping (address => int64) holdings ;
    
    function SpaCoin() payable {
        outstanding_coins = TOTAL_UNITS ;
        owner = msg.sender ;
    }
    
    event CoinAllocation(address holder, int64 number, int64 remaining) ;
    event CoinMovement(address from, address to, int64 v) ;
    event InvalidCoinUsage(string reason) ;

    function getOwner()  constant returns(address) {
        return owner ;
    }

    function allocate(address newHolder, int64 value)  payable {
        if (msg.sender != owner) {
            InvalidCoinUsage(&#39;Only owner can allocate coins&#39;) ;
            return ;
        }
        if (value < 0) {
            InvalidCoinUsage(&#39;Cannot allocate negative value&#39;) ;
            return ;
        }

        if (value <= outstanding_coins) {
            holdings[newHolder] += value ;
            outstanding_coins -= value ;
            CoinAllocation(newHolder, value, outstanding_coins) ;
        } else {
            InvalidCoinUsage(&#39;value to allocate larger than outstanding coins&#39;) ;
        }
    }
    
    function move(address destination, int64 value)  {
        address source = msg.sender ;
        if (value <= 0) {
            InvalidCoinUsage(&#39;Must move value greater than zero&#39;) ;
            return ;
        }
        if (holdings[source] >= value) {
            holdings[destination] += value ;
            holdings[source] -= value ;
            CoinMovement(source, destination, value) ;
        } else {
            InvalidCoinUsage(&#39;value to move larger than holdings&#39;) ;
        }
    }
    
    function myBalance() constant returns(int64) {
        return holdings[msg.sender] ;
    }
    
    function holderBalance(address holder) constant returns(int64) {
        if (msg.sender != owner) return ;
        return holdings[holder] ;
    }

    function outstandingValue() constant returns(int64) {
        if (msg.sender != owner) return ;
        return outstanding_coins ;
    }
    
}