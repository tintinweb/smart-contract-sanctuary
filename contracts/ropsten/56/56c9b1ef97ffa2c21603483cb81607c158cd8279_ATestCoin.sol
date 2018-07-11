//  
//  sdSS_SSSSSSbs    sSSs    sSSs  sdSS_SSSSSSbs    sSSs    sSSs_sSSs     .S   .S_sSSs    
//  YSSS~S%SSSSSP   d%%SP   d%%SP  YSSS~S%SSSSSP   d%%SP   d%%SP~YS%%b   .SS  .SS~YS%%b   
//       S%S       d%S&#39;    d%S&#39;         S%S       d%S&#39;    d%S&#39;     `S%b  S%S  S%S   `S%b  
//       S%S       S%S     S%|          S%S       S%S     S%S       S%S  S%S  S%S    S%S  
//       S&S       S&S     S&S          S&S       S&S     S&S       S&S  S&S  S%S    S&S  
//       S&S       S&S_Ss  Y&Ss         S&S       S&S     S&S       S&S  S&S  S&S    S&S  
//       S&S       S&S~SP  `S&&S        S&S       S&S     S&S       S&S  S&S  S&S    S&S  
//       S&S       S&S       `S*S       S&S       S&S     S&S       S&S  S&S  S&S    S&S  
//       S*S       S*b        l*S       S*S       S*b     S*b       d*S  S*S  S*S    S*S  
//       S*S       S*S.      .S*P       S*S       S*S.    S*S.     .S*S  S*S  S*S    S*S  
//       S*S        SSSbs  sSS*S        S*S        SSSbs   SSSbs_sdSSS   S*S  S*S    S*S  
//       S*S         YSSP  YSS&#39;         S*S         YSSP    YSSP~YSSY    S*S  S*S    SSS  
//       SP                             SP                               SP   SP          
//       Y                              Y                                Y    Y           

pragma solidity ^0.4.24;

contract ATestCoin{
    
    using SafeMath for uint;
    
    address public owner;
    address public newOwner;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    mapping(address => uint) balances;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        symbol = &quot;TeC5&quot;;
        name = &quot;TestCoin5&quot;;
        decimals = 8;
        _totalSupply = 10000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function () public payable {
        revert();
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}