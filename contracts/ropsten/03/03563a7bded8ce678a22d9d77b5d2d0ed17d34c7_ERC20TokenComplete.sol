pragma solidity ^0.4.24; 

contract ERC20TokenComplete {
    string public constant name = &quot;KDS Token1&quot;;
    string public constant symbol = &quot;KDS&quot;;
    uint8 public constant decimals = 18;

    uint256 public totalSupply ;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    address owner; // 토큰 발행자

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function ERC20TokenComplete(
        uint256 _totalSupply
    ) public {
        owner = msg.sender;
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        Transfer(address(this), msg.sender, totalSupply);
        assert(true);
    }

    function transfer(address to, uint amount)  public {
        require(balanceOf[msg.sender] >= amount); // 보내는 사람의 보유량 확인
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        Transfer(msg.sender, to, amount);
    }
}