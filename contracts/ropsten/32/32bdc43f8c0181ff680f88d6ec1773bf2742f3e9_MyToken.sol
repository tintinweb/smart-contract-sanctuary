pragma solidity ^0.4.20;

    contract MyToken {
        string public name;
        string public symbol;
        uint8 public decimals;
        
        /* This creates an array with all balances */
        mapping (address => uint256) public balanceOf;
        
        event Transfer(address indexed _from, address indexed to, uint256 value);
        
        /* Contract creator set the initial supply tokens */
        constructor () public {
            balanceOf[msg.sender] = 1000;
            name = &#39;DFMcoin&#39;;
            symbol = &#39;DFMc&#39;;
            decimals = 2;
        }
        
        /* Send coins */
        function transfer(address _to, uint256 _value) public {
            /* Check if sender has balance and for overflows */
            require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
    
            /* Add and subtract new balances */
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            
            /* Notify anyone listening that this transfer took place */
            emit Transfer(msg.sender, _to, _value);
        }
    }