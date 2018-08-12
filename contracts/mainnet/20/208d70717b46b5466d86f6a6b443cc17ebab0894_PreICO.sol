pragma solidity ^0.4.24;

// File: contracts/ERC223ReceivingContract.sol

contract ERC223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

// File: contracts/ERC20Interface.sol

contract ERC20Interface {
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool ok);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool ok);
    function approve(address _spender, uint256 _value) public returns (bool ok);
    function allowance(address _owner, address _spender) public constant returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/SafeMath.sol

/**
 * Math operations with safety checks
 */
library SafeMath {
    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

// File: contracts/StandardToken.sol

contract StandardToken is ERC20Interface {
    using SafeMath for uint256;

    /* Actual balances of token holders */
    mapping(address => uint) balances;
    /* approve() allowances */
    mapping (address => mapping (address => uint)) allowed;

    /**
     *
     * Fix for the ERC20 short address attack
     *
     * http://vessenes.com/the-erc20-short-address-attack-explained/
     */
    modifier onlyPayloadSize(uint256 size) {
        require(msg.data.length == size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool ok) {
        require(_to != address(0));
        require(_value > 0);
        uint256 holderBalance = balances[msg.sender];
        require(_value <= holderBalance);

        balances[msg.sender] = holderBalance.subtract(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool ok) {
        require(_to != address(0));
        uint256 allowToTrans = allowed[_from][msg.sender];
        uint256 balanceFrom = balances[_from];
        require(_value <= balanceFrom);
        require(_value <= allowToTrans);

        balances[_from] = balanceFrom.subtract(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowToTrans.subtract(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool ok) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        //    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
        //    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * Atomic increment of approved spending
     *
     * Works around https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     */
    function increaseApproval(address _spender, uint256 _addedValue) onlyPayloadSize(2 * 32) public returns (bool ok) {
        uint256 oldValue = allowed[msg.sender][_spender];
        allowed[msg.sender][_spender] = oldValue.add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    /**
     * Atomic decrement of approved spending.
     *
     * Works around https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) onlyPayloadSize(2 * 32) public returns (bool ok) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.subtract(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

}

// File: contracts/BurnableToken.sol

contract BurnableToken is StandardToken {
    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _holder, uint256 _value) internal {
        require(_value <= balances[_holder]);

        balances[_holder] = balances[_holder].subtract(_value);
        totalSupply = totalSupply.subtract(_value);

        emit Burn(_holder, _value);
        emit Transfer(_holder, address(0), _value);
    }

    event Burn(address indexed _burner, uint256 _value);
}

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);

        owner = newOwner;
        newOwner = address(0);

        emit OwnershipTransferred(owner, newOwner);
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);
}

// File: contracts/ERC223Interface.sol

contract ERC223Interface is ERC20Interface {
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool ok);

    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes indexed _data);
}

// File: contracts/Standard223Token.sol

contract Standard223Token is ERC223Interface, StandardToken {
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool ok) {
        if (!super.transfer(_to, _value)) {
            revert();
        }
        if (isContract(_to)) {
            contractFallback(msg.sender, _to, _value, _data);
        }

        emit Transfer(msg.sender, _to, _value, _data);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool ok) {
        return transfer(_to, _value, new bytes(0));
    }

    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool ok) {
        if (!super.transferFrom(_from, _to, _value)) {
            revert();
        }
        if (isContract(_to)) {
            contractFallback(_from, _to, _value, _data);
        }

        emit Transfer(_from, _to, _value, _data);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool ok) {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

    function contractFallback(address _origin, address _to, uint256 _value, bytes _data) private {
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(_origin, _value, _data);
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }

        return (length > 0);
    }
}

// File: contracts/ICOToken.sol

// ----------------------------------------------------------------------------
// ICO Token contract
// ----------------------------------------------------------------------------
contract ICOToken is BurnableToken, Ownable, Standard223Token {
    string public name;
    string public symbol;
    uint8 public decimals;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;

        balances[owner] = totalSupply;

        emit Mint(owner, totalSupply);
        emit Transfer(address(0), owner, totalSupply);
        emit MintFinished();
    }

    function () public payable {
        revert();
    }

    event Mint(address indexed _to, uint256 _amount);
    event MintFinished();
}

// File: contracts/PreICO.sol

contract PreICO is Ownable, ERC223ReceivingContract {
    using SafeMath for uint256;

    struct DatePeriod {
        uint256 start;
        uint256 end;
    }

    struct Beneficiary {
        address wallet;
        uint256 transferred;
        uint256 toTransfer;
    }

    uint256 public price = 0.002 ether / 1e3;
    uint256 public minPurchase = 0.01 ether;
    // Tokens sold for ether
    uint256 public totalSold = 0;
    // Tokens for sale for ether
    uint256 public forSale = 350000e3; // 350,000.000
    DatePeriod public salePeriod;

    ICOToken internal token;
    Beneficiary[] internal beneficiaries;

    constructor(ICOToken _token, uint256 _startTime, uint256 _endTime) public {
        token = _token;
        salePeriod.start = _startTime;
        salePeriod.end = _endTime;

        addBeneficiary(0x7ADCE5a8CDC22b65A07b29Fb9F90ebe16F450aB1, 200 ether);
        addBeneficiary(0xa406b97666Ea3D2093bDE9644794F8809B0F58Cc, 300 ether);
        addBeneficiary(0x3Be990A4031D6A6a9f44c686ccD8B194Bdeea790, 200 ether);
    }

    function () public isRunning payable {
        require(msg.value >= minPurchase);

        uint256 unsold = forSale.subtract(totalSold);
        uint256 paid = msg.value;
        uint256 purchased = paid.divide(price);
        if (purchased > unsold) {
            purchased = unsold;
        }
        uint256 toReturn = paid.subtract(purchased.multiply(price));
        uint256 reward = purchased.multiply(30).divide(100); // 30% bonus reward

        if (toReturn > 0) {
            msg.sender.transfer(toReturn);
        }
        token.transfer(msg.sender, purchased.add(reward));
        allocateFunds();
        totalSold = totalSold.add(purchased);
    }

    modifier isRunning() {
        require(now >= salePeriod.start);
        require(now <= salePeriod.end);
        _;
    }

    modifier afterEnd() {
        require(now > salePeriod.end);
        _;
    }

    function burnUnsold() public onlyOwner afterEnd {
        uint256 unsold = token.balanceOf(address(this));
        token.burn(unsold);
    }

    function changeStartTime(uint256 _startTime) public onlyOwner {
        salePeriod.start = _startTime;
    }

    function changeEndTime(uint256 _endTime) public onlyOwner {
        salePeriod.end = _endTime;
    }

    // Inside a tokenFallback function msg.sender is a token-contract.
    function tokenFallback(address _from, uint256 _value, bytes _data) public {
        // Accept only ours token
        if (msg.sender != address(token)) {
            revert();
        }
        // Only contract owner can deposit tokens
        if (_from != owner) {
            revert();
        }
    }

    function withdrawFunds(address wallet) public onlyOwner afterEnd {
        uint256 balance = address(this).balance;
        require(balance > 0);

        wallet.transfer(balance);
    }

    function allocateFunds() internal {
        uint256 balance = address(this).balance;
        uint length = beneficiaries.length;
        uint256 toTransfer = 0;

        for (uint i = 0; i < length; i++) {
            Beneficiary storage beneficiary = beneficiaries[i];
            toTransfer = beneficiary.toTransfer.subtract(beneficiary.transferred);
            if (toTransfer > 0) {
                if (toTransfer > balance) {
                    toTransfer = balance;
                }
                beneficiary.wallet.transfer(toTransfer);
                beneficiary.transferred = beneficiary.transferred.add(toTransfer);
                break;
            }
        }
    }

    function addBeneficiary(address _wallet, uint256 _toTransfer) internal {
        beneficiaries.push(Beneficiary({
            wallet: _wallet,
            transferred: 0,
            toTransfer: _toTransfer
            }));
    }
}