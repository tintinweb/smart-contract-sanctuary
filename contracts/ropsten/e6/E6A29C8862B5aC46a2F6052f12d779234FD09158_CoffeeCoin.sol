/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: UNLICENSED

contract CoffeeCoin {
    string private _token_name;
    string private _token_symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    address public ico_address;
    address public minter;
    bool public frozenTransactions;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        _token_name = "CoffeeWarCoin";
        _token_symbol = "CWC";
        _decimals = 18;
        _totalSupply = 8 * 10 ** (8 + 18);


        minter = msg.sender;
        ico_address =  msg.sender;
        frozenTransactions = true;

        balances[minter] = _totalSupply;
        emit Transfer(address(0), minter, _totalSupply);
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function frozeTransactions(bool status) external {
        require(msg.sender == minter || msg.sender == ico_address, "msg.sender == minter");
        frozenTransactions = status;
    }

    function setICOContractAddress(address _t) external {
        require(msg.sender == minter, "msg.sender == minter");
        ico_address = _t;

    }

    function name() public view returns (string memory){
        return _token_name;
    }
    function symbol() public  view returns (string memory) {
        return _token_symbol;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(frozenTransactions != true, "frozenTransactions != true");
        require(balances[msg.sender] >= tokens, "Check balance");
        require(tokens > 0, "tokens should be > 0");
        require(spender != msg.sender, "You can't approve coins to your account");

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(frozenTransactions != true, "frozenTransactions != true");
        require(balances[msg.sender] >= tokens, "Check balance");
        require(to != msg.sender, "You can't transfer coins to your account");
        require(tokens > 0, "tokens should be > 0");

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(frozenTransactions != true, "frozenTransactions != true");
        require(msg.sender != from, "Use Transfer for this");
        require(balances[from] >= tokens, "balances[from]>= tokens");
        require(allowed[from][msg.sender] >=  tokens, "allowed[from][msg.sender] >=  tokens");
        require(tokens > 0, "tokens > 0");

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter || msg.sender == ico_address,
        "ERC20: only the creator of the smart contract can add new tokens to the balance");
        require(amount > 0, "amount > 0");


         _totalSupply = safeAdd(_totalSupply, amount);
        balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
    }


    function burn(uint256 amount) public {
        require(balances[msg.sender] >= amount, "ERC20: balance[msg.sender] >= amount");
        require(amount > 0, "ERC20: amount > 0");

        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        _totalSupply = safeSub(_totalSupply, amount);
        emit Transfer(msg.sender, address(0), amount);

    }

    function safeAdd(uint a, uint b) private pure returns (uint c) {
        c = a + b;
//        require(c >= a);
    }
    function safeSub(uint a, uint b) private pure returns (uint c) {
//        require(b <= a);
        c = a - b; }


}

contract CoffeeICO {
    address public tokenAdress;  // адрес токена в блоке
    address public mintor;  // админ
    uint256 public tokenSoftcap;  // минимальное значение привлечённых средств для запуска проекта. При достижении этого значения проект гарантированно запускается и токены становятся активными.
    uint256 public tokenHardcap;  // максимальное значение привлечённых средств, после достижения которого продажа токенов прекращается и проект гарантированно запускается.
    uint256 public tokenPerWei;  // Курс токена к эфиру в вей
    address payable ethWallet; // Адрес кошелька
    bool public isOpen;  // Открыто ли ICO
    CoffeeCoin private Token;  // Токен
    uint256 public totalEarnedWei; // Всего потрачено Wei

    constructor(address baseTokenAdress, uint256 tokenPerWeiValue, uint256 softCap, uint256 hardCap){
        tokenAdress = baseTokenAdress;
        tokenSoftcap = softCap;
        tokenHardcap = hardCap;
        tokenPerWei = tokenPerWeiValue;
        mintor = msg.sender;
        isOpen = true;
        ethWallet = payable(mintor);
        Token = CoffeeCoin(tokenAdress);
        totalEarnedWei = 0;

    }

    function closeICO() public {
        require(msg.sender == mintor, "msg.sender == mintor");
        isOpen = false;
    }

    function contribute() external payable {
        require(msg.value>0, "msg.value>0");
        require(isOpen, "isOpen");

        uint256 amount = msg.value * tokenPerWei;
        ethWallet.transfer(msg.value);
        totalEarnedWei = safeAdd(totalEarnedWei, msg.value);
        Token.mint(msg.sender, amount);

        if (totalEarnedWei >= tokenSoftcap && Token.frozenTransactions() == true){
            Token.frozeTransactions(false);
        }

        if (totalEarnedWei >= tokenHardcap){
            isOpen = false;
        }

    }

        function safeAdd(uint a, uint b) private pure returns (uint c) {
                c = a + b;
//        require(c >= a);
    }



}