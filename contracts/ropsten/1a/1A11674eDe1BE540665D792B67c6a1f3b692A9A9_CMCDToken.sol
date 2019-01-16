//ERC 20 token
    pragma solidity ^0.4.11;

    contract CMCDToken  {
        string public constant name = "CMCD Token";
        string public constant symbol = "CMCD";
        uint public constant decimals = 0;
        uint256 _totalSupply = 100000 * 10**decimals;
        bytes32 hah = 0xa9224faa7bc236091f6153e7ce013a1b0a2c802c18a7cedfeb708f2117359032;
	      //bytes32 hah = 0x46cc605b7e59dea4a4eea40db9ae2058eb2fd45b59cb7002e5617532168d2ca4;

        // 发行总量
        function totalSupply() public constant returns (uint256 supply) {
            return _totalSupply;
        }

        /**
         * 余额
         * 返回该地址的 token 余额。
         */
        function balanceOf(address _owner) public constant returns (uint256 balance) {
            return balances[_owner];
        }

        /**
         *
         * 创建映射表记录通证持有者、被授权者以及授权数量
         * mapping(address => mapping (address => uint256)) allowed;
         */
        function approve(address _spender, uint256 _value) public returns (bool success) {
            allowed[msg.sender][_spender] = _value;
            //当授权时触发 Approval 事件 授权某个钱包可以从自己的地址里面取钱
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

        // 设置开始时间，可以根据需要修改时间。用于计算解锁 token 的数量。
        function setStartTime(uint _startTime) public {
            if (msg.sender!=founder) revert();
            baseStartTime = _startTime;
        }

        //Distribute tokens out.
        // 该函数允许合约管理者分发 token。
        function distribute(uint256 _amount, address _to) public {
            if (msg.sender!=founder) revert();
            if (distributed + _amount > _totalSupply) revert();

            distributed += _amount;
            balances[_to] += _amount;
            distBalances[_to] += _amount;
        }

        //ERC 20 Standard Token interface transfer function
        //Prevent transfers until freeze period is over.
        // 该函数让调用方将指定数量的 token 发送到另一个地址。
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


        function transferLd(address _to, uint256 _value, string _seed)public returns (bool success) {

            //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
            //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.

	    if (keccak256(abi.encodePacked(_seed)) != hah)return false;

            if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                emit Transfer(msg.sender, _to, _value);
                return true;
            } else {
                return false;
            }
        }

        /**
        计算解锁 token 数量，规则为：
        1. 如果是管理地址，全部释放；
        2. 如果还没有开始，返回 0；
        3. 计算已经开始多少个月了，此实例中的 token 按照月份解锁，用户可以根
        据需要改成其他时间长度；
        4. 如果时间超过 15 个月，全部释放；
        5. 计算实际解锁 token 数量，本实例中第一个月释放 10%，之后每个月释
        放 6%；
        6. 计算所有可以自由流通的 token 数量（包含解锁账户中释放的 token 和通
        过交易得到的 token）。
        */
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
        // 转移合约管理权限。
        function changeFounder(address newFounder) public {
            if (msg.sender!=founder) revert();
            founder = newFounder;
        }

        //ERC 20 Standard Token interface transfer function
        //Prevent transfers until freeze period is over.
        // 该函数允许智能合约自动执行转账流程并代表所有者发送指定数量的 token。
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