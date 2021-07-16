//SourceUnit: FMTOKEN.sol

pragma solidity 0.4.25;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

    contract FMToken {

        string public name;

        string public symbol;

        uint8 public decimals;

        uint public totalSupply;

        uint public supplied;

        uint public surplusSupply;

        uint public salesAmount;

        uint Frequency = 0;

        address owner;

        uint public usdtPrice = 5000;

        address gameAddr;


        mapping(address => uint) public balanceOf;


        mapping(address => mapping(address => uint)) public allowance;

        constructor(
            string _name,
            string _symbol,
            uint _totalSupply
        )  public {
            name = _name;
            symbol = _symbol;
            decimals = 8;
            totalSupply = _totalSupply * (10 ** uint256(decimals));
            owner = msg.sender;
            balanceOf[msg.sender] = 500000 * (10 ** uint256(decimals));
            surplusSupply = SafeMath.sub(totalSupply, balanceOf[msg.sender]);
        }
        
        function () public payable {
        }

        event Transfer(address indexed from, address indexed to,uint value);

        event Approval(address indexed owner, address indexed spender, uint256 value);

        modifier validDestination(address _to) {

            require(_to != address(0x0), "address cannot be 0x0");
            _;
        }


        function setGameAddr(address addr) external {
            require(owner == msg.sender, "Insufficient permissions");
            gameAddr = addr;
        }


        function calculationNeedFM(uint usdtVal) external view returns(uint) {
            uint fmCount = SafeMath.div(SafeMath.div(SafeMath.mul(usdtVal, 10 ** 8), 10), usdtPrice);
            return fmCount;
        }
            
		
        function riseUsdt(uint index, uint count) internal returns(uint) {
            if(count > index) {
                for(uint i = index; i < count; i++) {
                    usdtPrice = SafeMath.add(usdtPrice, SafeMath.div(usdtPrice, 100));
                }
            }
            return count;
        }


        function gainFMToken(uint value, bool isCovert) external {
            require(msg.sender == gameAddr, "Insufficient permissions");
            require(value <= surplusSupply, "FM tokens are larger than the remaining supply");
			require(value <= balanceOf[this], "FM tokens are larger than the remaining balance");
			
            surplusSupply = SafeMath.sub(surplusSupply, value);

			salesAmount = SafeMath.add(salesAmount, value);

            if(isCovert) {
                uint number = SafeMath.div(salesAmount, 10 ** 12);
				
                if(number <= 10000) {
                    uint count = 0;
                    if(usdtPrice <= 100 * 10 ** 8) {
                        count = SafeMath.div(number, 5);
                        Frequency = riseUsdt(Frequency, count);
                    }
                }
            }
			
            balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], value);
			balanceOf[this] = SafeMath.sub(balanceOf[this], value);
        }


        function transfer(address to, uint value) public validDestination(to) {
            require(value >= 0, "Incorrect transfer amount");
            require(balanceOf[msg.sender] >= value, "Insufficient balance");
            require(balanceOf[to] + value >= balanceOf[to], "Transfer failed");

            balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], value);
            balanceOf[to] = SafeMath.add(balanceOf[to], value);

            emit Transfer(msg.sender, to, value);
        }


        function approve(address spender, uint value) public {
              require((value == 0) || (allowance[msg.sender][spender] == 0), "Authorized tokens are not used up");
              allowance[msg.sender][spender] = value;
              emit Approval(msg.sender, spender, value);
        }


        function transferFrom(address from, address to, uint value) public validDestination(to) {
            require(value >= 0, "Incorrect transfer amount");
            require(balanceOf[from] >= value, "Insufficient balance");
            require(balanceOf[to] + value >= balanceOf[to], "Transfer failed");
            require(value <= allowance[from][msg.sender], "The transfer amount is higher than the available amount");

            balanceOf[from] = SafeMath.sub(balanceOf[from], value);
            balanceOf[to] = SafeMath.add(balanceOf[to], value);
            allowance[from][msg.sender] = SafeMath.sub(allowance[from][msg.sender], value);

            emit Transfer(from, to, value);
        }


        function burn(address addr, uint value) public {
            require(msg.sender == gameAddr, "Insufficient permissions");
            require(balanceOf[addr] >= value, "Insufficient balance");

            balanceOf[addr] = SafeMath.sub(balanceOf[addr], value);
            balanceOf[address(0x0)] = SafeMath.add(balanceOf[address(0x0)], value);
			
		    uint tValue = SafeMath.mul(value, 3);
    
			supplied = SafeMath.add(supplied, tValue);
			balanceOf[this] = SafeMath.add(balanceOf[this], tValue);

            emit Transfer(addr, address(0x0), value);
        }

    }