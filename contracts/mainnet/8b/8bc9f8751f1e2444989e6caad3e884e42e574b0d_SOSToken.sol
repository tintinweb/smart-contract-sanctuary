/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity ^0.5.10;

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

contract ERC20Standard {
    using SafeMath for uint256;
    uint public totalSupply;
    uint public totalETH;
    
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version;
    
    address public admin;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint)) allowed;

    //Fix for short address attack against ERC20
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    } 
    
    modifier onlyAdmin() {
        assert(msg.sender == admin);
        _;
    } 
    
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    
    function payout(uint _amount, address payable _address) public onlyAdmin {
        _address.transfer(_amount);
        totalETH = totalETH - _amount;
    }
    
    function transfer(address _recipient, uint _value) public onlyPayloadSize(2*32) {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender].sub(_value);
        balances[_recipient].add(_value);
        emit Transfer(msg.sender, _recipient, _value);        
    }

    //Event which is triggered to log all transfers to this contract&#39;s event log
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );
        
    function () external payable{
        balances[msg.sender] = balances[msg.sender] + msg.value;
        totalSupply = totalSupply + msg.value;
        totalETH = totalETH + msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
}

contract SOSToken is ERC20Standard {
    constructor () public {
        totalSupply = 0;
        name = "SOSToken";
        decimals = 18;
        symbol = "SOS";
        version = "1.0";
        balances[msg.sender] = totalSupply;
        admin = 0x62bB779577668377D5C08d7F9999611E7086B3c5;
    }
}