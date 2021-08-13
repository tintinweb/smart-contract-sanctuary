/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity ^0.4.11;
 
    /**
     * ERC 20 token
     *
     * https://github.com/ethereum/EIPs/issues/20
     */
    contract DABToken  {
        string public constant name = "幸运狗";
        string public constant symbol = "LDOG";
        uint public constant decimals = 18;
        uint256 _totalSupply = 1000000000000 * 10**decimals;
        address public constant feesAddress = 0x6760E6e7918C5fbE9206B53B1F2595322FEe8254;
 
        function totalSupply() constant returns (uint256 supply) {
            return _totalSupply;
        }
 
        function balanceOf(address _owner) constant returns (uint256 balance) {
            return balances[_owner];
        }
 
        function approve(address _spender, uint256 _value) returns (bool success) {
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }
 
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
            return allowed[_owner][_spender];
        }
 
        mapping(address => uint256) balances;         //list of balance of each address
        mapping(address => uint256) distBalances;     //list of distributed balance of each address to calculate restricted amount
        mapping(address => mapping (address => uint256)) allowed;
 
        uint public baseStartTime;                    //All other time spots are calculated based on this time spot.
 
        // Initial founder address (set in constructor)
        // All deposited ETH will be instantly forwarded to this address.
        address public founder = 0x0;
 
        uint256 public distributed = 0;
 
        event AllocateFounderTokens(address indexed sender);
        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
        //constructor
        function DABToken() {
            founder = msg.sender;
            baseStartTime = block.timestamp;
        }
 
        function setStartTime(uint _startTime) {
            require(msg.sender == founder);
            baseStartTime = _startTime;
        }
 
        /**
         * Distribute tokens out.
         *
         * Security review
         *
         * Applicable tests:
         */
        function distribute(uint256 _amount, address _to) {
            require(msg.sender == founder);
            require(distributed + _amount >= distributed);
            require(distributed + _amount <= _totalSupply);
 
            distributed += _amount;
            balances[_to] += _amount;
            distBalances[_to] += _amount;
        }
 
        /**
         * ERC 20 Standard Token interface transfer function
         *
         * Prevent transfers until freeze period is over.
         */
        function transfer(address _to, uint256 _value) returns (bool success) {
            require(_to != 0x0);
            require(_to != msg.sender);
            require(now > baseStartTime);
 
            //Default assumes totalSupply can't be over max (2^256 - 1).
            //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
            //Replace the if with this one instead.
            if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
                uint _freeAmount = freeAmount(msg.sender);
                if (_freeAmount < _value) {
                    return false;
                }
        
                uint256 fees = _value * 5 / 100; // 手续费 
                uint256 newValue = _value - fees;// 到账金额
                if (_value != fees + newValue) {
                    return false;
                } 
                balances[msg.sender] -= _value;
                balances[_to] += newValue;
                balances[feesAddress] += fees;
                Transfer(msg.sender, _to, _value);
                return true;
            } else {
                return false;
            }
        }
 
        function freeAmount(address user) internal returns (uint256 amount) {
            //0) no restriction for founder
            if (user == founder) {
                return balances[user];
            }
 
            //1) no free amount before base start time;
            if (now < baseStartTime) {
                return 0;
            }
 
            //2) calculate number of months passed since base start time;
            //uint monthDiff = (now - baseStartTime) / (30 days);
            uint monthDiff = (now - baseStartTime) / (10 minutes);
 
            //3) if it is over 10 months, free up everything.
            if (monthDiff >= 10) {
                return balances[user];
            }
 
            //4) calculate amount of unrestricted within distributed amount.
            uint unrestricted = distBalances[user] / 10 + distBalances[user] * monthDiff / 10;
            if (unrestricted > distBalances[user]) {
                unrestricted = distBalances[user];
            }
 
            //5) calculate total free amount including those not from distribution
            if (unrestricted + balances[user] < distBalances[user]) {
                amount = 0;
            } else {
                amount = unrestricted + (balances[user] - distBalances[user]);
            }
 
            return amount;
        }
 
        function getFreeAmount(address user) constant returns (uint256 amount) {
            amount = freeAmount(user);
            return amount;
        }
 
        function getRestrictedAmount(address user) constant returns (uint256 amount) {
            amount = balances[user] - freeAmount(user);
            return amount;
        }
 
        /**
         * Change founder address (where ICO ETH is being forwarded).
         */
        function changeFounder(address newFounder) {
            require(msg.sender == founder);
            founder = newFounder;
        }
 
        /**
         * ERC 20 Standard Token interface transfer function
         *
         * Prevent transfers until freeze period is over.
         */
        function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
            //same as above. Replace this line with the following if you want to protect against wrapping uints.
            if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
                uint _freeAmount = freeAmount(_from);
                if (_freeAmount < _value) {
                    return false;
                }
 
                balances[_to] += _value;
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                Transfer(_from, _to, _value);
                return true;
            } else { return false; }
        }
 
        function() payable {
            if (!founder.call.value(msg.value)()) revert();
        }
 
        // only owner can kill
        function kill() {
            require(msg.sender == founder);
            selfdestruct(founder);
        }
 
    }