/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

pragma solidity ^ 0.4.21;

/**
 * @title A contract for batch transfer
 * @author [email protected]
 * @dev You can batch transfer Eth and ERC20 Tokens to multiple addresses with same or different value
 */

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}

contract ERC20Basic {
    uint public totalSupply;

    function balanceOf(address who) public constant returns (uint);

    function transfer(address to, uint value) public;

    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);

    function transferFrom(address from, address to, uint value) public;

    function approve(address spender, uint value) public;

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint;
    mapping(address => uint) balances;

    function transfer(address _to, uint _value) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }
}

contract StandardToken is BasicToken, ERC20 {
    mapping(address => mapping(address => uint)) allowed;

    function transferFrom(address _from, address _to, uint _value) public {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract BatchTransfer is Ownable {
    using SafeMath for uint;

    function _ethSendSameValue(address[] _to, uint _value) internal {
        require(_to.length <= 255);

        for (uint8 i = 0; i < _to.length; i++) {
            require(_to[i].send(_value * (10 ** 9)));
        }
    }

    function _ethSendDifferentValue(address[] _to, uint[] _value) internal {
        require(_to.length == _value.length);
        require(_to.length <= 255);

        for (uint8 i = 0; i < _to.length; i++) {
            require(_to[i].send(_value[i] * (10 ** 9)));
        }

    }

    function _coinSendSameValue(address _tokenAddress, address[] _to, uint _value) internal {
        require(_to.length <= 255);

        address from = msg.sender;

        StandardToken token = StandardToken(_tokenAddress);
        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(from, _to[i], _value * (10 ** 9));
        }
    }

    function _coinSendDifferentValue(address _tokenAddress, address[] _to, uint[] _value) internal {
        require(_to.length == _value.length);
        require(_to.length <= 255);

        StandardToken token = StandardToken(_tokenAddress);

        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(msg.sender, _to[i], _value[i] * (10 ** 9));
        }
    }

    // @dev Transfer Eth with the different value
    function transferEthWithDifferentValue(address[] _to, uint[] _value) payable public {
        _ethSendDifferentValue(_to, _value);
    }

    // @dev Transfer Eth with the same value
    function transferEthWithSameValue(address[] _to, uint _value) payable public {
        _ethSendSameValue(_to, _value);
    }

    // @dev Transfer token with the same value
    function transferTokenWithSameValue(address _tokenAddress, address[] _to, uint _value) payable public {
        _coinSendSameValue(_tokenAddress, _to, _value);
    }

    // @dev Transfer token with the different value, this method can save some fee.
    function transferTokenWithDifferentValue(address _tokenAddress, address[] _to, uint[] _value) payable public {
        _coinSendDifferentValue(_tokenAddress, _to, _value);
    }

    // @dev Withdraw ETH from Contract
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}