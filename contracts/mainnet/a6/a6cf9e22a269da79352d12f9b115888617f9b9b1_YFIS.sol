pragma solidity ^0.4.21;

         contract  IYFIS {

            uint256 public totalSupply;


            function balanceOf(address _owner) public view returns (uint256 balance);


            function transfer(address _to, uint256 _value) public returns (bool success);


            function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);


            function approve(address _spender, uint256 _value) public returns (bool success);


            function allowance(address _owner, address _spender) public view returns (uint256 remaining);


            event Transfer(address indexed _from, address indexed _to, uint256 _value);
            event Approval(address indexed _owner, address indexed _spender, uint256 _value);
        }

        library SafeMath {


            function mul(uint256 a, uint256 b) internal pure returns (uint256) {

                if (a == 0) {
                    return 0;
                }

                uint256 c = a * b;
                require(c / a == b);
                return c;
            }


            function div(uint256 a, uint256 b) internal pure returns (uint256) {
                require(b > 0);
                uint256 c = a / b;
                return c;
            }



            function sub(uint256 a, uint256 b) internal pure returns (uint256) {
                require(b <= a);
                uint256 c = a - b;
                return c;
            }


            function add(uint256 a, uint256 b) internal pure returns (uint256) {
                uint256 c = a + b;
                require(c >= a);
                return c;
            }


            function mod(uint256 a, uint256 b) internal pure returns (uint256) {
                require(b != 0);
                return a % b;
            }
        }


        contract YFIS is IYFIS {
            using SafeMath for uint256;

            mapping (address => uint256) public balances;
            mapping (address => mapping (address => uint256)) public allowed;

            string public name;
            uint8 public decimals;
            string public symbol;

            function YFIS(
                uint256 _initialAmount,
                string _tokenName,
                uint8 _decimalUnits,
                string _tokenSymbol
                ) public {
                balances[msg.sender] = _initialAmount;
                totalSupply = _initialAmount;
                name = _tokenName;
                decimals = _decimalUnits;
                symbol = _tokenSymbol;
            }

            function transfer(address _to, uint256 _value) public returns (bool success) {
            require(_to != address(0));
            require(balances[msg.sender] >= _value);

            balances[msg.sender] = balances[msg.sender].sub(_value);

            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }

        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            uint256 allowance = allowed[_from][msg.sender];
            require(balances[_from] >= _value && allowance >= _value);
            require(_to != address(0));

            balances[_to] = balances[_to].add(_value);

            balances[_from] = balances[_from].sub(_value);

            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

            emit Transfer(_from, _to, _value);
            return true;
        }

        function balanceOf(address _owner) public view returns (uint256 balance) {
            return balances[_owner];
        }

        function approve(address _spender, uint256 _value) public returns (bool success) {
            require(_spender != address(0));
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }

        function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
            require(_spender != address(0));
            return allowed[_owner][_spender];
        }
    }