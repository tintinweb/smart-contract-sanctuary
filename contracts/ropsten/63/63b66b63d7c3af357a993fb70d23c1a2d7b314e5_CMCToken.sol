//ERC 20 token
    pragma solidity ^0.4.11;
    contract CMCToken  {
        string public constant name = "CMC Token";
        string public constant symbol = "CMC";
        uint public constant decimals = 18;
        uint256 _totalSupply = 1000 * 10**decimals;

        function totalSupply() public constant returns (uint256 supply) {
            return _totalSupply;
        }

        function balanceOf(address _owner) public constant returns (uint256 balance) {
            return balances[_owner];
        }

        function approve(address _spender, uint256 _value) public returns (bool success) {
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }

        function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
        }

        mapping(address => uint256) balances;         //list of balance of each address
        mapping(address => uint256) distBalances;     //list of distributed balance of each address to calculate restricted amount
        mapping(address => mapping (address => uint256)) allowed;

        uint public baseStartTime; //All other time spots are calculated based on this time spot.

        // Initial founder address (set in constructor)
        // All deposited will be instantly forwarded to this address.

        address public founder;
        uint256 public distributed = 0;

        event AllocateFounderTokens(address indexed sender);
        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);

        //constructor
        constructor () public {
            founder = msg.sender;
        }

        function setStartTime(uint _startTime) public {
            if (msg.sender!=founder) revert();
            baseStartTime = _startTime;
        }

        //Distribute tokens out.
        function distribute(uint256 _amount, address _to) public {
            if (msg.sender!=founder) revert();
            if (distributed + _amount > _totalSupply) revert();

            distributed += _amount;
            balances[_to] += _amount;
            distBalances[_to] += _amount;
        }

        //ERC 20 Standard Token interface transfer function
        //Prevent transfers until freeze period is over.
        function transfer(address _to, uint256 _value)public returns (bool success) {
            if (now < baseStartTime) revert();

            //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
            //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
            if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
                uint _freeAmount = freeAmount(msg.sender);
                if (_freeAmount < _value) {
                    return false;
                } 

                balances[msg.sender] -= _value;
                balances[_to] += _value;
                emit Transfer(msg.sender, _to, _value);
                return true;
            } else {
                return false;
            }
        }

        function freeAmount(address user) public view returns (uint256 amount) {
            //0) no restriction for founder
            if (user == founder) {
                return balances[user];
            }

            //1) no free amount before base start time;
            if (now < baseStartTime) {
                return 0;
            }

            //2) calculate number of months passed since base start time;
            uint monthDiff = (now - baseStartTime) / (30 days);

            //3) if it is over 15 months, free up everything.
            if (monthDiff > 15) {
                return balances[user];
            }

            //4) calculate amount of unrestricted within distributed amount.
            uint unrestricted = distBalances[user] / 10 + distBalances[user] * 6 / 100 * monthDiff;
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

        //Change founder address (where ICO is being forwarded).
        function changeFounder(address newFounder) public {
            if (msg.sender!=founder) revert();
            founder = newFounder;
        }

        //ERC 20 Standard Token interface transfer function
        //Prevent transfers until freeze period is over.         
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            if (msg.sender != founder) revert();

            //same as above. Replace this line with the following if you want to protect against wrapping uints.
            if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
                uint _freeAmount = freeAmount(_from);
                if (_freeAmount < _value) {
                    return false;
                } 

                balances[_to] += _value;
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                emit Transfer(_from, _to, _value);
                return true;
            } else { return false; }
        }

        function() payable public {
            if (!founder.call.value(msg.value)()) revert(); 
        }
    }