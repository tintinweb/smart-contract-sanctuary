// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)
import "./SafeMath.sol";
import "./Utils.sol";

pragma solidity ^ 0.8.0;

// ERC20-Tokenstandard nach OpenZeppelin https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
interface IERC20 {
    // Anzahl der existierenden Token
    function totalSupply() external view returns(uint256);

    // Gibt die Anzahl der Token von Adresse {account} zurück
    function balanceOf(address account) external view returns(uint256);

    // Sendet die Token des aufrufenden Accounts an die Adresse {recipient} in Höhe von {amount} Token 
    function transfer(address recipient, uint256 amount) external returns(bool);

    // Gibt die Nummer der Token zurück, welche der Account {owner} für Account {spender} versenden darf
    function allowance(address owner, address spender) external view returns(uint256);

    // Erlaubt dem Account {spender} das Senden der Token vom aufrufenden Account in Höhe von {amount} Token 
    function approve(address spender, uint256 amount) external returns(bool);

    // Sendet die Token vom Sender {sender} an den Empfänger {recipient} in Höhe von {amount} Token
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);

    // Eventaufruf: Transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Eventaufruf: Approval
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {
    // Ersteller des Smart Contract
    address public owner;

    // Eventaufruf: OwnershipTransferred
    event OwnershipTransferred(address indexed _from, address indexed _to);

    // Constructor: Setzt den Besitzer {owner} des Smart Contract
    constructor() {
        owner = msg.sender;
    }

    // Modifier: Lässt nur dem Besitzer {owner} das aufrufen jener Funktion mit Modifikator zu
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

abstract contract TokenERC20 is IERC20, Owned {
    using SafeMath for uint;
    using Utils for string;

    string public ISIN;
    string public WKN;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint totalTokenSupply;

    // Token-Balanz je Nutzer
    mapping(address => uint) balances;
    
    // Status der Blacklist je Nutzer
    mapping(address => bool) blacklist;
    
    // Ausgabe Nutzer erlauben
    mapping(address => mapping(address => uint)) allowed;
    
    // Timelock mit Zeitlimit
    mapping(address => uint) timelocks;
    uint timelockLimit = 1 minutes;
    

    constructor() {}
    
    // Init-Funktion für Parameter
    function init(string memory _symbol, string memory _name, 
                string memory _ISIN, string memory _WKN, uint8 _decimals, uint _totalSupply) internal {
        ISIN = checkValidityISIN(_ISIN.checkLength(12));
        WKN = checkValidityWKN(_WKN.checkLength(6));
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        totalTokenSupply = _totalSupply * (10 ** decimals);
        balances[owner] = totalTokenSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    // Überprüfung der International Security Identification Number
    function checkValidityISIN(string memory _ISIN) pure internal returns(string memory) {
        require(_ISIN.checkAlphanumeric(), "ERC20: ISIN not alphanumeric");
        /* Weiteren Code ggf. einfuegen */
        return _ISIN;
    }
    
    // Überprüfung der Wertpapierkennnummer
    function checkValidityWKN(string memory _WKN) pure internal returns(string memory) {
        require(_WKN.checkAlphanumeric(), "ERC20: WKN not alphanumeric");
        /* Weiteren Code ggf. einfuegen */
        return _WKN;
    }

    // Anzahl aller existierenden Token
    function totalSupply() public view override returns(uint) {
        return totalTokenSupply.sub(balances[address(0)]);
    }

    // Gibt die Anzahl der Token des Nutzers wieder
    function getBalance() public view returns(uint) {
        return balanceOf(msg.sender);
    }

    // Aufruf: Balanz des Nutzers {tokenOwner}
    function balanceOf(address tokenOwner) public view override returns(uint balance) {
        return balances[tokenOwner];
    }

    // Transfer Token von Sender nach Empfänger {to} in Höhe von {tokens}
    function transfer(address to, uint tokens)public override blacklistCheck timelockCheck returns(bool success) {

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns(bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) blacklistCheck timelockCheck public override returns(bool success) {

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns(uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    // Neue Token hinzufügen
    function mint(uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: mint to the zero address");
        totalTokenSupply = totalTokenSupply.add(amount);
        balances[msg.sender] = totalTokenSupply.add(amount);
    }
    
    // Token entfernen
   function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        require(balances[account] <= amount, "ERC20: burn amount exceeds balance");
        totalTokenSupply = totalTokenSupply.sub(amount);
    }

    // Zeitlimit überprüfen
    modifier timelockCheck() {
        if((timelocks[msg.sender] != 0) && (msg.sender != owner)) {
            require(timelocks[msg.sender] + timelockLimit > block.timestamp);
        }
        _;
    }
    
    // Blacklist überprüfen
    modifier blacklistCheck() {
        require(!blacklist[msg.sender]);
        _;
    }
    
    // 
    function setTimelockLimit(uint _timelockLimit) public onlyOwner {
        require(_timelockLimit > 0, "ERC20: Timelock invalid!");
        timelockLimit = _timelockLimit;
    }
    
    function setBlacklist(address _address, bool _state) public onlyOwner {
        blacklist[_address] = _state;
    }

}


contract STBAToken is TokenERC20 {

    // Raum für weitere Attribute und Methoden

    constructor(string memory _symbol, string memory _name, string memory _ISIN, string memory _WKN, uint8 _decimals, uint _totalSupply) { 
       
        init(_symbol, 
            _name, 
            _ISIN,
            _WKN,
            _decimals, 
            _totalSupply);
    }
}