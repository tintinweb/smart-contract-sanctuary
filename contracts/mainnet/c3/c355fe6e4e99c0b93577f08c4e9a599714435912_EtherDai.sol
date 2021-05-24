/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity ^0.5.12;

contract ReserveLike {
}

contract ProxyLike {
    function withdrawODai(address, uint) public;
    function withdrawEDai(address, uint) public;
}

contract WrappedDai {
    string public constant version = "0511";

    // --- Owner ---
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event SetOwner(address owner);

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
        emit SetOwner(_owner);
    }

    // --- Math ---
    function add(uint a, uint b) private pure returns (uint) {
        require(a <= uint(-1) - b);
        return a + b;
    }

    function sub(uint a, uint b) private pure returns (uint) {
        require(a >= b);
        return a - b;
    }

    // --- Proxy ---
    ProxyLike public Proxy;

    event SetProxy(address proxy);

    modifier onlyProxy {
        require(msg.sender == address(Proxy));
        _;
    }

    modifier onlyOwnerOrProxy {
        require(msg.sender == owner || msg.sender == address(Proxy));
        _;
    }

    // 최초 발행 시에는 Owner, 그 뒤에는 Proxy가 호출
    function setProxy(address proxy) public onlyOwnerOrProxy {
        Proxy = ProxyLike(proxy);
        emit SetProxy(proxy);
    }

    // --- Contracts & Constructor ---
    ReserveLike public Reserve;
    uint public reserveLimit;

    event SetReserve(address reserve);
    event SetReserveLimit(uint limit);

    function setReserve(address reserve) public onlyProxy {
        Reserve = ReserveLike(reserve);
        emit SetReserve(reserve);
    }

    function setReserveLimit(uint limit) public onlyOwner {
        reserveLimit = limit;
        emit SetReserveLimit(limit);
    }

    constructor() public {
        owner = msg.sender;
    }

    // --- ERC20 ---
    uint8 public constant decimals = 18;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;  // (holder, spender)

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed holder, address indexed spender, uint amount);

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        if (from != msg.sender && allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = sub(allowance[from][msg.sender], amount);
        }

        balanceOf[from] = sub(balanceOf[from], amount);
        balanceOf[to] = add(balanceOf[to], amount);

        emit Transfer(from, to, amount);

        if (to == address(Reserve)) {
            require(balanceOf[to] <= reserveLimit);
        }

        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseApproval(address spender, uint amount) public returns (bool) {
        amount = add(allowance[msg.sender][spender], amount);

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function decreaseApproval(address spender, uint amount) public returns (bool) {
        if (amount > allowance[msg.sender][spender]) {
            amount = 0;
        }
        else {
            amount = allowance[msg.sender][spender] - amount;
        }

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function mint(address user, uint amount) public onlyProxy {
        balanceOf[user] = add(balanceOf[user], amount);
        totalSupply = add(totalSupply, amount);

        emit Transfer(address(0), user, amount);
    }

    function burn(address user, uint amount) public onlyProxy {
        balanceOf[user] = sub(balanceOf[user], amount);
        totalSupply = sub(totalSupply, amount);

        emit Transfer(user, address(0), amount);
    }
}

contract EtherDai is WrappedDai {
    // --- ERC20 ---
    string public constant name = "Ether Dai";
    string public constant symbol = "EDAI";

    function transfer(address to, uint amount) public returns (bool) {
        if (msg.sender == address(Reserve)) {
            Proxy.withdrawEDai(to, amount);
            return true;
        }

        return transferFrom(msg.sender, to, amount);
    }
}