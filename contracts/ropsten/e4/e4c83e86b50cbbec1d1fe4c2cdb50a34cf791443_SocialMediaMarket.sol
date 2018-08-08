pragma solidity ^0.4.24;
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who)public constant returns (uint256);
    function transfer(address to, uint256 value)public returns (bool);
    function transferFrom(address from, address to, uint256 value)public returns (bool);
    function allowance(address owner, address spender)public constant returns (uint256);
    function approve(address spender, uint256 value)public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event ExchangeTokenPushed(address indexed buyer, uint256 amount);
    event TokenPurchase(address indexed purchaser, uint256 value,uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract SocialMediaToken is ERC20,Ownable {
    using SafeMath for uint256;

        // Token Info.
    string public name;
    string public symbol;

    uint8 public constant decimals = 18;

    address[] private walletArr;
    uint walletIdx = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) allowed;

    event TokenPurchase(address indexed purchaser, uint256 value,uint256 amount);
    event FundTransfer(address fundWallet, uint256 amount);

    function SocialMediaToken(


    ) public {
        balanceOf[msg.sender] = 500000000000000000000000000;
        totalSupply = 500000000000000000000000000;
        name = "SocialMedia";
        symbol =" SMT";

        walletArr.push(0xd4b8C9Adaf7Cd401d72F9507fd869499B7FcEb60);
    }

    function balanceOf(address _who)public constant returns (uint256 balance) {
        return balanceOf[_who];
    }

    function _transferFrom(address _from, address _to, uint256 _value)  internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool){
        _transferFrom(msg.sender,_to,_value);
        return true;
    }

    function push(address _buyer, uint256 _amount) public onlyOwner {
        uint256 val=_amount*(10**18);
        _transferFrom(msg.sender,_buyer,val);
        ExchangeTokenPushed(_buyer, val);
    }

    function ()public payable {
        _tokenPurchase( msg.value);
    }

    function _tokenPurchase( uint256 _value) internal {

        require(_value >= 0.1 ether);

        address wallet = walletArr[walletIdx];
        walletIdx = (walletIdx+1) % walletArr.length;

        wallet.transfer(msg.value);
        FundTransfer(wallet, msg.value);
    }

    function supply()  internal constant  returns (uint256) {
        return balanceOf[owner];
    }

    function getCurrentTimestamp() internal view returns (uint256){
        return now;
    }

    function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value)public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)public returns (bool) {
        var _allowance = allowed[_from][msg.sender];

        require (_value <= _allowance);

        _transferFrom(_from,_to,_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
}

contract MyToken is SocialMediaToken {}

contract SocialMediaMarket {

    MyToken private _token;

    address public owner;
    address public platform;
    uint8 public decimals;
    uint8 public percent;

    struct Item {
        uint256 amount;
        address adv_address;
        address inf_address;
        int8 status;
    }

    mapping(uint64 => Item) public items;

    event InitiatedEscrow(uint64 indexed id, uint256 _amount, address adv_address, address inf_address, uint256 _time);
    event Withdraw(uint64 indexed id, uint256 _amount, address _person, address _platform, uint8 _percent, uint256 _time);
    event Payback(uint64 indexed id, uint256 _amount, address _person, uint256 _time);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address tokenAddress, address platformAddress, uint8 percentPayout) public {
        owner = msg.sender;
        platform = platformAddress;
        percent = percentPayout;

        _token = MyToken(tokenAddress);
        decimals = _token.decimals();
    }

    function initiateEscrow(uint64 id, uint256 amount, address adv_address, address inf_address) onlyOwner public returns (bool success) {
        if (items[id].amount > 0) {
            return false;
        }
        if (_token.allowance(adv_address, address(this)) < amount) {
            return false;
        }
        require(_token.transferFrom(adv_address, address(this), amount));

        items[id] = Item(amount, adv_address, inf_address, 0);

        emit InitiatedEscrow(id, amount, adv_address, inf_address, block.timestamp);
        return true;
    }

    function withdraw(uint64 id) onlyOwner public returns (bool success) {
        if (items[id].amount > 0) {
            if (items[id].status == 0) {
                require(_token.transfer(items[id].inf_address, items[id].amount * (100 - percent) / 100));
                require(_token.transfer(platform, items[id].amount * percent / 100));
                items[id].status = 1;

                emit Withdraw(id, items[id].amount, items[id].inf_address, platform, percent, block.timestamp);
                return true;
            }
        }

        return false;
    }

    function payback(uint64 id) onlyOwner public returns (bool success) {
        if (items[id].amount > 0) {
            if (items[id].status == 0) {
                require(_token.transfer(items[id].adv_address, items[id].amount));
                items[id].status = - 1;

                emit Payback(id, items[id].amount, items[id].adv_address, block.timestamp);
                return true;
            }
        }
        return false;
    }

    function changePlatform(address platformAddress) onlyOwner public returns (bool success) {
        if (platformAddress == platform) {
            return false;
        }
        else if (platformAddress != 0x0) {
            return false;
        }
        platform = platformAddress;
        return true;
    }
}