pragma solidity ^0.4.24;

/**
 * 代幣智能合約
 *
 * Symbol       : PDI5
 * Name         : Wind Green Gain Token 5
 * Total supply : 2,160,000,000.000000000000000000
 * Decimals     : 18
 */


/**
 * Safe maths
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }


    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }


    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }


    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


/**
 * ERC 代幣標準 #20 Interface: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


/**
 * 一個函式即可取得核准並執行函式 (Borrowed from MiniMeToken)
 */
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


/**
 * 持有權
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);


    constructor() public {
        owner = msg.sender;
    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
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
}


/**
 * ERC20 相容代幣，定義(寫死)了全名、符號(縮寫)、精準度(小數點後幾位數)及固定(未來不可增額)的發行量。
 */
contract WindGreenGainToken5 is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    /**
     * Constructor
     */
    constructor() public {
        symbol = "PDI5";
        name = "Wind Green Gain Token 5";
        decimals = 18;
        _totalSupply = 2160000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    /**
     * 發行的供應量。
     */
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    /**
     * 從 `tokeOwner` 錢包地址取得代幣餘額。
     */
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    /**
     * 從代幣持有者的錢包轉 `tokens` 到 `to` 錢包地址。
     *  - 代幣持有者的錢包裡必須要有足夠的餘額
     *  - 交易額為 0 是可被允許的
     */
    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= (tokens * 10**uint(18)));            // 餘額夠不夠
        require(balances[to] + (tokens * 10**uint(18)) >= balances[to]);   // 防止異味

        balances[msg.sender] = balances[msg.sender].sub((tokens * 10**uint(18)));
        balances[to] = balances[to].add((tokens * 10**uint(18)));

        emit Transfer(msg.sender, to, (tokens * 10**uint(18)));

        return true;
    }


    /**
     * 代幣持有者用來核准 `spender` 從代幣持有者的錢包地址以 transferFrom(...) 函式使用 `tokens`。
     *
     * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md 中建議了不用檢查
     * 核准雙消費攻擊，因為這應該在 UI 中實作。
     */
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    /**
     * 從 `from` 錢包地址轉 `tokens` 到 `to` 錢包地址。
     *
     * 呼叫此函式者必須有足夠的代幣從 `from` 錢包地址使用代幣。
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    /**
     * 傳回代幣持有者核准 `spender` 錢包地址 可交易的代幣數量。
     */
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    /**
     * 代幣持有者可核准 `spender` 從代幣持有者的錢包地址以 transferFrom(...) 函式交易 `token`，然
     * 後執行 `spender` 的 `receiveApproval(...)` 合約函式。
     */
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    /**
     * 防止漏洞(不接受 ETH)。
     */
    function () public payable {
        revert();
    }


    /**
     * 持有者可轉出任何意外發送的 ERC20 代幣。
     */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}