//SourceUnit: MythToken.sol

pragma solidity ^0.4.25;


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

    contract MythToken {

        string public name;

        string public symbol;

        uint8 public decimals;

        uint public totalSupply;

        uint public supplied;

        address owner;

        address mainAddr;

        mapping(address => uint) public balanceOf;

        mapping(address => mapping(address => uint)) public allowance;

        constructor(
            string _name,
            string _symbol,
            uint _totalSupply
        )  public {
            name = _name;
            symbol = _symbol;
            decimals = 6;
            totalSupply = _totalSupply * (10 ** uint256(decimals));
            balanceOf[msg.sender] = 30000000 * (10 ** uint256(decimals));
            owner = msg.sender;
            supplied = balanceOf[msg.sender];
        }
        
        function () public payable {
        }

        event Transfer(address indexed from, address indexed to,uint value);

        event Approval(address indexed owner, address indexed spender, uint256 value);

        modifier validDestination(address _to) {

            require(_to != address(0x0), "address cannot be 0x0");
            _;
        }

        function setMainAddr(address addr) external {
            require(owner == msg.sender, "Insufficient permissions");
            mainAddr = addr;
        }

        function gainMythToken(uint value) external {
            require(msg.sender == mainAddr, "Insufficient permissions");
            require(SafeMath.add(supplied, value) <= totalSupply, "Insufficient balance");
            supplied = SafeMath.add(supplied, value);
            balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], value);
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
              allowance[msg.sender][spender] = value;
              emit Approval(msg.sender, spender, value);
        }


        function transferFrom(address from, address to, uint value) public validDestination(to) {
            require(value >= 0, "Incorrect transfer amount");
            require(balanceOf[from] >= value, "Insufficient balance");
            require(balanceOf[to] + value >= balanceOf[to], "Transfer failed");
            if(msg.sender != mainAddr){
                require(value <= allowance[from][msg.sender], "The transfer amount is higher than the available amount");
                allowance[from][msg.sender] = SafeMath.sub(allowance[from][msg.sender], value);
            }

            balanceOf[from] = SafeMath.sub(balanceOf[from], value);
            balanceOf[to] = SafeMath.add(balanceOf[to], value);

            emit Transfer(from, to, value);
        }

        function burn(address addr, uint value) public {
            require(msg.sender == mainAddr, "Insufficient permissions");
            require(balanceOf[addr] >= value, "Insufficient balance");

            balanceOf[addr] = SafeMath.sub(balanceOf[addr], value);
            balanceOf[address(0x0)] = SafeMath.add(balanceOf[address(0x0)], value);

            emit Transfer(addr, address(0x0), value);
        }

    }