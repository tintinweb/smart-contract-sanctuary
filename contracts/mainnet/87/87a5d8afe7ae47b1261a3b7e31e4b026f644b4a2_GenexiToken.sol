pragma solidity ^0.4.21;

/// @title SafeMath
/// @dev Math operations with safety checks that throw on error
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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

/// @title ERC20 Standard Token interface
contract IERC20Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
}

/// @title ERC20 Standard Token implementation
contract ERC20Token is IERC20Token {

    using SafeMath for uint256;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    modifier validAddress(address _address) {
        require(_address != 0x0);
        require(_address != address(this));
        _;
    }

    function _transfer(address _from, address _to, uint _value) internal validAddress(_to) {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        _transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public validAddress(_spender) returns (bool success) {
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Owned {

    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        require(_address != address(this));
        _;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public validAddress(_newOwner) onlyOwner {
        require(_newOwner != owner);

        owner = _newOwner;
    }
}

/// @title Genexi contract - crowdfunding code for Genexi Project
contract GenexiToken is ERC20Token, Owned {

    using SafeMath for uint256;

    string public constant name = "GEN";
    string public constant symbol = "GEN";
    uint32 public constant decimals = 18;

    // SET current initial token supply
    uint256 public initialSupply = 7000000000;
    // 
    bool public fundingEnabled = true;
    // The maximum tokens available for sale
    uint256 public maxSaleToken;
    // Total number of tokens sold
    uint256 public totalSoldTokens;
    // Total number of tokens for Genexi Project
    uint256 public totalProjectToken;
    // Funding wallets, which allowed the transaction during the crowdfunding
    address[] private wallets;
    // The flag indicates if the Genexi contract is in enable / disable transfers
    bool public transfersEnabled = true; 

    // List wallets to allow transactions tokens
    uint[256] private nWallets;
    // Index on the list of wallets to allow reverse lookup
    mapping(uint => uint) private iWallets;

    // Date end of lock Project Token 
    uint256 public endOfLockProjectToken;
    // Lock token on account Genexi Project 
    mapping (address => uint256) private lock;

    event Finalize();
    event DisableTransfers();

    /// @notice Genexi Project
    /// @dev Constructor
    function GenexiToken() public {

        initialSupply = initialSupply * 10 ** uint256(decimals);

        totalSupply = initialSupply;
        // Initializing 70% of tokens for sale
        // maxSaleToken = initialSupply * 70 / 100 (70% this is maxSaleToken & 100% this is initialSupply)
        // totalProjectToken will be calculated in function finalize()
        // 
        // |---------maxSaleToken---------totalProjectToken|
        // |===============70%============|======30%=======|
        // |------------------totalSupply------------------|
        maxSaleToken = totalSupply.mul(70).div(100);
        // Give all the tokens to a COLD wallet
        balances[msg.sender] = maxSaleToken;
        // SET HOT wallets to allow transactions tokens
        wallets = [
                0x559E3e6DD71E7a1942e921596e85A61178b5c4db, // HOT #1
                0x84E1d9DB4Aa98672286FA619b6b102DCfC9EF629, // HOT #2
                0x459B06b6b526193fFbEf93700B8fe6AF45b374D5, // HOT #3
                0xfb430a30F739Edb98E5FBCcD12DB1088e6fc44a2 // HOT #4
            ];
        // Add COLD wallet (owner) to allow transactions tokens
        nWallets[1] = uint(msg.sender);
        iWallets[uint(msg.sender)] = 1;

        for (uint index = 0; index < wallets.length; index++) {
            nWallets[2 + index] = uint(wallets[index]);
            iWallets[uint(wallets[index])] = index + 2;
        }
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);
        require(_address != address(this));
        _;
    }

    modifier transfersAllowed(address _address) {
        if (fundingEnabled) {
            uint index = iWallets[uint(_address)];
            assert(index > 0);
        }

        require(transfersEnabled);
        _;
    }

    function transfer(address _to, uint256 _value) public transfersAllowed(msg.sender) returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed(_from) returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function lockOf(address _account) public constant returns (uint256 balance) {
        return lock[_account];
    }

    function _lockProjectToken() private {

        endOfLockProjectToken = now + 365 days;

        // SET distribution of tokens for Genexi
        // 10% of totalSupply transfer to Company
        lock[0xa04768C11576F84712e27a76B4700992d6645180] = totalSupply.mul(10).div(100);
        // 15% of totalSupply transfer to Team
        lock[0x7D082cE8F5FA1e7D6D39336ECFCd8Ae419ea9777] = totalSupply.mul(15).div(100);
        // 5% of totalSupply transfer to Advisors
        lock[0x353DeCDd78a923c4BA2eB455B644a44110BbA65e] = totalSupply.mul(5).div(100);
    }

    function unlockProjectToken() external {
        require(lock[msg.sender] > 0);
        require(now > endOfLockProjectToken);

        balances[msg.sender] = balances[msg.sender].add(lock[msg.sender]);

        lock[msg.sender] = 0;

        emit Transfer(0, msg.sender, lock[msg.sender]);
    }

    function finalize() external onlyOwner {
        require(fundingEnabled);

        uint256 soldTokens = maxSaleToken;

        for (uint index = 1; index < nWallets.length; index++) {
            if (balances[address(nWallets[index])] > 0) {
                // Get total sold tokens on the funding wallets
                // totalSoldTokens is 70% of the total number of tokens
                soldTokens = soldTokens.sub(balances[address(nWallets[index])]);

                emit Burn(address(nWallets[index]), balances[address(nWallets[index])]);
                // Burning tokens on funding wallet
                balances[address(nWallets[index])] = 0;
            }
        }

        totalSoldTokens = soldTokens;

        // totalProjectToken = totalSoldTokens * 30 / 70 (30% this is Genexi Project & 70% this is totalSoldTokens)
        //
        // |-------totalSoldTokens--------totalProjectToken|
        // |===============70%============|======30%=======|
        // |totalSupply=(totalSoldTokens+totalProjectToken)|
        totalProjectToken = totalSoldTokens.mul(30).div(70);

        totalSupply = totalSoldTokens.add(totalProjectToken);
        
        _lockProjectToken();

        fundingEnabled = false;

        emit Finalize();
    }

    function disableTransfers() external onlyOwner {
        require(transfersEnabled);

        transfersEnabled = false;

        emit DisableTransfers();
    }
}