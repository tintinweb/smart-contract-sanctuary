//   __    __ _         _                   _____      _
//  / / /\ \ (_)___  __| | ___  _ __ ___   /__   \___ | | _____ _ __
//  \ \/  \/ / / __|/ _` |/ _ \| '_ ` _ \    / /\/ _ \| |/ / _ \ '_ \
//   \  /\  /| \__ \ (_| | (_) | | | | | |  / / | (_) |   <  __/ | | |
//    \/  \/ |_|___/\__,_|\___/|_| |_| |_|  \/   \___/|_|\_\___|_| |_|
//
//  Author: Grzegorz Kucmierz
//  Source: https://github.com/gkucmierz/wisdom-token
//    Docs: https://gkucmierz.github.io/wisdom-token
//

pragma solidity ^0.7.2;

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) private allowed;
    function _transfer(address sender, address recipient, uint256 amount) internal virtual returns (bool) {
        require(balanceOf[sender] >= amount);
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }
    function allowance(address holder, address spender) public view returns (uint256) {
        return allowed[holder][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(allowed[sender][msg.sender] >= amount);
        _transfer(sender, recipient, amount);
        allowed[sender][msg.sender] -= amount;
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value);
}

contract Ownable {
    address owner;
    address newOwner;

    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwner() public {
        require(newOwner == msg.sender);
        owner = msg.sender;
        emit TransferOwnership(msg.sender);
    }

    event TransferOwnership(address newOwner);
}

interface IERC667Receiver {
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external;
}

contract ERC667 is ERC20 {
    function transferAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
        bool success = _transfer(msg.sender, recipient, amount);
        if (success){
            IERC667Receiver(recipient).onTokenTransfer(msg.sender, amount, data);
        }
        return success;
    }
}

contract Pausable is Ownable {
    bool public paused = true;
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused() {
        require(paused);
        _;
    }
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }

    event Pause();
    event Unpause();
}

contract Issuable is ERC20, Ownable {
    bool locked = false;
    modifier whenUnlocked() {
        require(!locked);
        _;
    }
    function issue(address[] memory addr, uint256[] memory amount) public onlyOwner whenUnlocked {
        require(addr.length == amount.length);
        uint8 i;
        uint256 sum = 0;
        for (i = 0; i < addr.length; ++i) {
            balanceOf[addr[i]] = amount[i];
            emit Transfer(address(0x0), addr[i], amount[i]);
            sum += amount[i];
        }
        totalSupply += sum;
    }
    function lock() internal onlyOwner whenUnlocked {
        locked = true;
    }
}

contract WisdomToken is ERC667, Pausable, Issuable {
    constructor() {
        name = 'Experty Wisdom Token';
        symbol = 'WIS';
        decimals = 18;
        totalSupply = 0;
    }
    function _transfer(address sender, address recipient, uint256 amount)
        internal whenNotPaused override returns (bool) {
        return super._transfer(sender, recipient, amount);
    }
    function alive(address _newOwner) public {
        lock();
        unpause();
        changeOwner(_newOwner);
    }
}