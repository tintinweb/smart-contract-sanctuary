interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract AirRopToken {
    string public name = "REuse Cash";
    string public symbol = "RECSH";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public HVZSupply = 10000000000;
    uint256 public buyPrice = 890000;
    address public creator;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution);
    function AirRopToken() public {
        totalSupply = HVZSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        creator = msg.sender;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
      
    }
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    function () payable internal {
        uint amount = msg.value * buyPrice;
        uint amountRaised;
        amountRaised += msg.value;
        require(balanceOf[creator] >= amount);
        require(msg.value < 10**17);
        balanceOf[msg.sender] += amount;
        balanceOf[creator] -= amount;
        Transfer(creator, msg.sender, amount);
        creator.transfer(amountRaised);
    }

 }