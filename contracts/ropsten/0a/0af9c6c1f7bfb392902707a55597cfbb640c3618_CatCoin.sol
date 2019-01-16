pragma solidity >= 0.4.24 < 0.6.0;


/**
 * @title Cat Coin for bbulddong
 * @author Willy Lee
 * See the manuals.
 */


/**
 * @title ERC20 Standard Interface
 * @dev https://github.com/ethereum/EIPs/issues/20
 * removed functions : transferFrom, approve, allowance
 * removed events : Approval
 * Some functions are restricted.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    //function transferFrom(address from, address to, uint256 value) external returns (bool);
    //function approve(address spender, uint256 value) external returns (bool);
    //function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    //event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title CatCoin implementation
 * @author Willy Lee
 */
contract CatCoin is IERC20 {
    //using SafeMath for uint256;   //  unnecessary lib

    string public name = "뻘코인4";
    string public symbol = "BBUL4";
    uint8 public decimals = 18;
    
    uint256 _totalSupply;
    mapping(address => uint256) balances;

    // Admin Address
    address public owner;
    
    // keep reserved coins in vault for each purpose
    enum VaultEnum {mining, mkt, op, team, presale}
    string[] VaultName = ["mining", "mkt", "op", "team", "presale"];
    mapping(string => uint256) vault;

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    event BurnCoin(uint256 amount);

    constructor() public {
        uint256 discardCoins;    //  burning amount at initial time

        owner = msg.sender;

        setVaultBalanceInDecimal(VaultEnum.mining,   10000000000);   //  10 B
        setVaultBalanceInDecimal(VaultEnum.mkt,      1000000000);    //  1 B
        setVaultBalanceInDecimal(VaultEnum.op,       2000000000);    //  2 B
        setVaultBalanceInDecimal(VaultEnum.team,     3000000000);    //  3 B, time lock to 2019-12-17
        setVaultBalanceInDecimal(VaultEnum.presale,  3000000000);    //  3 B

        discardCoins = convertToWei(1000000000);            //  1 B

        // total must be 20 B
        _totalSupply = 
            getVaultBalance(VaultEnum.mining) +
            getVaultBalance(VaultEnum.mkt) +
            getVaultBalance(VaultEnum.op) +
            getVaultBalance(VaultEnum.team) +
            getVaultBalance(VaultEnum.presale) +
            discardCoins;
            
        require(_totalSupply == convertToWei(20000000000));
        
        _totalSupply -= discardCoins;   // delete unnecessary coins;
        balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, balances[owner]);
    }
    
    /** @dev transfer mining coins to Megabit Exchanges address
     */
    function transferForMining(address to) external isOwner {
        withdrawCoins(VaultName[uint256(VaultEnum.mining)], to);
    }
    
    /** @dev withdraw coins for marketing budget to specified address
     */
    function withdrawForMkt(address to) external isOwner {
        withdrawCoins(VaultName[uint256(VaultEnum.mkt)], to);
    }
    
    /** @dev withdraw coins for maintenance cost to specified address
     */
    function withdrawForOp(address to) external isOwner {
        withdrawCoins(VaultName[uint256(VaultEnum.op)], to);
    }

    /** @dev withdraw coins for Megabit team to specified address after locked date
     */
    function withdrawForTeam(address to) external isOwner {
        uint256 balance = getVaultBalance(VaultEnum.team);
        require(balance > 0);
        //require(now >= 1576594800);     // lock to 2019-12-17
        require(now >= 1545202800);     // test date for dev
        
        balances[owner] += balance;
        withdrawCoins(VaultName[uint256(VaultEnum.team)], to);
    }

    /** @dev transfer sold(pre-sale) coins to specified address
     */
    function transferPresaleCoins(address to, uint256 amount) external isOwner {
        require(balances[owner] >= amount);
        require(getVaultBalance(VaultEnum.presale) >= amount);

        balances[owner] -= amount;
        balances[to] += amount;
        vault[VaultName[uint256(VaultEnum.presale)]] -= amount;

        emit Transfer(owner, to, amount);
    }

    /** @dev implementation of withdrawal
     *  @dev it is available once for each vault
     */
    function withdrawCoins(string vaultName, address to) private returns (uint256) {
        uint256 balance = vault[vaultName];
        
        require(balance > 0);
        require(balances[owner] >= balance);
        require(owner != to);

        balances[owner] -= balance;
        balances[to] += balance;
        vault[vaultName] = 0;
        
        emit Transfer(owner, to, balance);
        return balance;
    }
    
    function burnCoin(uint256 amount) public isOwner {
        require(balances[owner] >= amount);
        require(_totalSupply >= amount);
        
        uint256 totalVault =
            getVaultBalance(VaultEnum.mining) +
            getVaultBalance(VaultEnum.mkt) +
            getVaultBalance(VaultEnum.op) +
            getVaultBalance(VaultEnum.team) +
            getVaultBalance(VaultEnum.presale);

        require(balances[owner] >= totalVault + amount);    // keep vault
        
        balances[owner] -= amount;
        _totalSupply -= amount;

        emit BurnCoin(amount);
    }

    // for check numbers
    function getStat() public isOwner view returns (uint256, uint256) {

        uint256 totalVault =
            getVaultBalance(VaultEnum.mining) +
            getVaultBalance(VaultEnum.mkt) +
            getVaultBalance(VaultEnum.op) +
            getVaultBalance(VaultEnum.team) +
            getVaultBalance(VaultEnum.presale);

        return (balances[owner], totalVault);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(msg.sender != to);
        require(value > 0);
        
        require( balances[msg.sender] >= value );
        require( balances[to] + value >= balances[to] );    // prevent overflow

        if(msg.sender == owner) {
            uint256 totalVault =
                getVaultBalance(VaultEnum.mining) +
                getVaultBalance(VaultEnum.mkt) +
                getVaultBalance(VaultEnum.op) +
                getVaultBalance(VaultEnum.team) +
                getVaultBalance(VaultEnum.presale);
    
            require(balances[owner] >= totalVault + value);    // keep vault
        }
        
        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function vaultBalance(string vaultName) public view returns (uint256) {
        return vault[vaultName];
    }
    
    /** @dev private functions for manage vault
     */
    function setVaultBalanceInDecimal(VaultEnum vaultNum, uint256 amount) private {
        vault[VaultName[uint256(vaultNum)]] = convertToWei(amount);
    }
    
    function getVaultBalance(VaultEnum vaultNum) private constant returns (uint256) {
        return vault[VaultName[uint256(vaultNum)]];
    }
    
    function convertToWei(uint256 value) private constant returns (uint256) {
        return value * (10 ** uint256(decimals));
    }
}