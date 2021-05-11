/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.4.0;

/**
 * @title Multi Sender, support ETH and ERC20 Tokens
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
 * @title Multi Sender, support ETH and ERC20 Tokens
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
 * @title Multi Sender, support ETH and ERC20 Tokens
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
 * @title Multi Sender, support ETH and ERC20 Tokens
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
 * @title Multi Sender, support ETH and ERC20 Tokens
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
 * @title Multi Sender, support ETH and ERC20 Tokens
 */

contract MultiSender is Ownable {
    using SafeMath for uint256;

    event LogTokenMultiSent(address token, uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);
    address public receiverAddress;
    uint256 public txFee = 0.01 ether;
    uint256 public VIPFee = 1 ether;

    /* VIP List */
    mapping(address => bool) public vipList;

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
     *  Register VIP
     */
    function registerVIP() public payable {
        require(msg.value >= VIPFee);
        address _receiverAddress = getReceiverAddress();
        require(_receiverAddress.send(msg.value));
        vipList[msg.sender] = true;
    }

    /*
     *  Register VIP
     */
    function registerFreeVIP(address _vip) public onlyOwner {
        vipList[_vip] = true;
    }

    /*
     *  VIP list
     */
    function addToVIPList(address[] _vipList) public onlyOwner {
        for (uint256 i = 0; i < _vipList.length; i++) {
            vipList[_vipList[i]] = true;
        }
    }

    /*
     * Remove address from VIP List by Owner
     */
    function removeFromVIPList(address[] _vipList) public onlyOwner {
        for (uint256 i = 0; i < _vipList.length; i++) {
            vipList[_vipList[i]] = false;
        }
    }

    /*
     * Check isVIP
     */
    function isVIP(address _addr) public view returns (bool) {
        return _addr == owner || vipList[_addr];
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

    /*
     * set vip fee
     */
    function setVIPFee(uint256 _fee) public onlyOwner {
        VIPFee = _fee;
    }

    /*
     * set tx fee
     */
    function setTxFee(uint256 _fee) public onlyOwner {
        txFee = _fee;
    }

    function ethSendSameValue(address[] _to, uint256 _value) internal {
        uint256 sendAmount = _to.length.mul(_value);
        uint256 remainingValue = msg.value;

        bool vip = isVIP(msg.sender);
        if (vip) {
            require(remainingValue >= sendAmount);
        } else {
            require(remainingValue >= sendAmount.add(txFee));
        }
        require(_to.length <= 255);

        for (uint8 i = 0; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value);
            require(_to[i].send(_value));
        }

        emit LogTokenMultiSent(
            0x000000000000000000000000000000000000bEEF,
            msg.value
        );
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

    function coinSendSameValue(
        address _tokenAddress,
        address[] _to,
        uint256 _value
    ) internal {
        uint256 sendValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (!vip) {
            require(sendValue >= txFee);
        }
        require(_to.length <= 255);

        address from = msg.sender;
        uint256 sendAmount = _to.length.mul(_value);

        StandardToken token = StandardToken(_tokenAddress);
        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(from, _to[i], _value);
        }

        emit LogTokenMultiSent(_tokenAddress, sendAmount);
    }

    function coinSendDifferentValue(
        address _tokenAddress,
        address[] _to,
        uint256[] _value
    ) internal {
        uint256 sendValue = msg.value;
        bool vip = isVIP(msg.sender);
        if (!vip) {
            require(sendValue >= txFee);
        }

        require(_to.length == _value.length);
        require(_to.length <= 255);

        uint256 sendAmount = 0;
        for (uint8 i = 0; i < _value.length; i++) {
            sendAmount = sendAmount.add(_value[i]);
        }
        StandardToken token = StandardToken(_tokenAddress);

        for (i = 0; i < _to.length; i++) {
            token.transferFrom(msg.sender, _to[i], _value[i]);
        }
        emit LogTokenMultiSent(_tokenAddress, sendAmount);
    }

    /*
        Send ether with the same value by a explicit call method
    */

    function sendEth(address[] _to, uint256 _value) public payable {
        ethSendSameValue(_to, _value);
    }

    /*
        Send ether with the different value by a explicit call method
    */
    function multisend(address[] _to, uint256[] _value) public payable {
        ethSendDifferentValue(_to, _value);
    }

    /*
        Send ether with the different value by a implicit call method
    */

    function mutiSendETHWithDifferentValue(address[] _to, uint256[] _value)
        public
        payable
    {
        ethSendDifferentValue(_to, _value);
    }

    /*
        Send ether with the same value by a implicit call method
    */

    function mutiSendETHWithSameValue(address[] _to, uint256 _value)
        public
        payable
    {
        ethSendSameValue(_to, _value);
    }

    /*
        Send coin with the same value by a implicit call method
    */

    function mutiSendCoinWithSameValue(
        address _tokenAddress,
        address[] _to,
        uint256 _value
    ) public payable {
        coinSendSameValue(_tokenAddress, _to, _value);
    }

    /*
        Send coin with the different value by a implicit call method, this method can save some fee.
    */
    function mutiSendCoinWithDifferentValue(
        address _tokenAddress,
        address[] _to,
        uint256[] _value
    ) public payable {
        coinSendDifferentValue(_tokenAddress, _to, _value);
    }

    /*
        Send coin with the different value by a explicit call method
    */
    function multisendToken(
        address _tokenAddress,
        address[] _to,
        uint256[] _value
    ) public payable {
        coinSendDifferentValue(_tokenAddress, _to, _value);
    }

    /*
        Send coin with the same value by a explicit call method
    */
    function drop(
        address _tokenAddress,
        address[] _to,
        uint256 _value
    ) public payable {
        coinSendSameValue(_tokenAddress, _to, _value);
    }
}