/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

pragma solidity ^0.4.0;

/**
 * @title Distributor, support ETH and ERC20 Tokens
 */

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + (a % b));
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * @title Distributor, support ETH and ERC20 Tokens
 */

contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public;

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public;

    function approve(address spender, uint256 value) public;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Distributor, support ETH and ERC20 Tokens
 */

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[_owner];
    }
}

/**
 * @title Distributor, support ETH and ERC20 Tokens
 */

contract StandardToken is BasicToken, ERC20 {
    mapping(address => mapping(address => uint256)) allowed;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}

/**
 * @title Distributor, support ETH and ERC20 Tokens
 */

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title Distributor, support ETH and ERC20 Tokens
 */

contract Distributor is Ownable {
    using SafeMath for uint256;

    event LogTokenMultiSent(address token, uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);
    address public receiverAddress;

    /*
     *  get balance
     */
    function getBalance(address _tokenAddress) public onlyOwner {
        address _receiverAddress = getReceiverAddress();
        if (_tokenAddress == address(0)) {
            require(_receiverAddress.send(address(this).balance));
            return;
        }
        StandardToken token = StandardToken(_tokenAddress);
        uint256 balance = token.balanceOf(this);
        token.transfer(_receiverAddress, balance);
        emit LogGetToken(_tokenAddress, _receiverAddress, balance);
    }

    /*
     * set receiver address
     */
    function setReceiverAddress(address _addr) public onlyOwner {
        require(_addr != address(0));
        receiverAddress = _addr;
    }

    /*
     * get receiver address
     */
    function getReceiverAddress() public view onlyOwner returns (address) {
        if (receiverAddress == address(0)) {
            return owner;
        }

        return receiverAddress;
    }

    function ethSendDifferentValue(address[] _to, uint256[] _value) internal {
        uint256 sendAmount = 0;
        for (uint8 i = 0; i < _value.length; i++) {
            sendAmount = sendAmount.add(_value[i]);
        }
        uint256 remainingValue = msg.value;

        require(remainingValue >= sendAmount);

        require(_to.length == _value.length);
        require(_to.length <= 255);

        for (i = 0; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value[i]);
            require(_to[i].send(_value[i]));
        }
        emit LogTokenMultiSent(
            0x000000000000000000000000000000000000bEEF,
            msg.value
        );
    }

    function coinSendDifferentValue(
        address _tokenAddress,
        address[] _to,
        uint256[] _value
    ) internal {

        require(_to.length == _value.length);
        require(_to.length <= 255);

        uint256 sendAmount = 0;
        for (uint8 i = 0; i < _value.length; i++) {
            sendAmount = sendAmount.add(_value[i]);
        }
        StandardToken token = StandardToken(_tokenAddress);

        for (i = 0; i < _to.length; i++) {
            token.transfer(_to[i], _value[i]);
        }
        emit LogTokenMultiSent(_tokenAddress, sendAmount);
    }

    /*
        Send ether with the different value by a explicit call method
    */
    function multisend(address[] _to, uint256[] _value) public onlyOwner payable {
        ethSendDifferentValue(_to, _value);
    }

    /*
        Send coin with the different value by a explicit call method
    */
    function multisendToken(
        address _tokenAddress,
        address[] _to,
        uint256[] _value
    ) public onlyOwner payable {
        coinSendDifferentValue(_tokenAddress, _to, _value);
    }
}