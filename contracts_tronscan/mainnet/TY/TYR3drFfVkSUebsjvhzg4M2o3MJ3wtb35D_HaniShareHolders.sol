//SourceUnit: hani.sol

pragma solidity ^0.5.4;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner; 
    }
}


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
}

 
interface ITRC20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
}

contract HaniShareHolders is Ownable, ITRC20{
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals = 6;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    address payable [] private holders;
    mapping (address => uint256) public totalPaid;
    uint256 public head;
    uint256 public balanceTRX;
    event DivisionShare(address receiver, uint256 value);


    constructor() public {
        totalSupply = (18 * 10 ** 6) * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = "HaniShareHolders";
        symbol = "H20";
    }


    function divideMoney() public onlyOwner returns (uint256) {
        if (balanceOf[owner] == totalSupply)
            return 0;

        if (head == 0)
            balanceTRX = address(this).balance;

        uint256 start = head;
        head = head + 20 < holders.length ? head + 20 : holders.length;
        for (; start < head; start++) {
            address payable s = holders[start];
            uint256 eachShare = balanceTRX.mul(balanceOf[s]).div(totalSupply - balanceOf[owner]);
            if (eachShare > 0) {
                s.transfer(eachShare);
                totalPaid[s] += eachShare;
                emit DivisionShare(s, eachShare);
            }
        }
        uint256 remained = holders.length.sub(head);
        if (head == holders.length) 
            head = 0;
        return remained;
    }

    

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(head == 0);
        require(_to != address(0));
        require(_from != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        if (balanceOf[_to] == 0) 
            holders.push(address(uint160(_to)));
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
    }



    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);  
        _transfer(msg.sender, owner, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);   
        require(_value <= allowance[_from][msg.sender]);    
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);  
        _transfer(_from, owner, _value);
        return true;
    }

    function transferToOwner(address _from, uint256 _value) public onlyOwner returns(bool success) {
        _transfer(_from, owner, _value);
        return true;
    }
}