pragma solidity ^0.4.13;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
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
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract LoggedERC20 is Ownable {
    /* Structures */
    struct LogValueBlock {
    uint256 value;
    uint256 block;
    }

    /* Public variables of the token */
    string public standard = &#39;LogValueBlockToken 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    LogValueBlock[] public loggedTotalSupply;

    bool public locked;

    uint256 public creationBlock;

    /* This creates an array with all balances */
    mapping (address => LogValueBlock[]) public loggedBalances;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function LoggedERC20(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    bool transferAllSupplyToOwner,
    bool _locked
    ) {
        LogValueBlock memory valueBlock = LogValueBlock(initialSupply, block.number);

        loggedTotalSupply.push(valueBlock);

        if(transferAllSupplyToOwner) {
            loggedBalances[msg.sender].push(valueBlock);
        }
        else {
            loggedBalances[this].push(valueBlock);
        }

        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        locked = _locked;
    }

    function valueAt(LogValueBlock [] storage valueBlocks, uint256 block) internal returns (uint256) {
        if(valueBlocks.length == 0) {
            return 0;
        }

        LogValueBlock memory prevLogValueBlock;

        for(uint256 i = 0; i < valueBlocks.length; i++) {

            LogValueBlock memory valueBlock = valueBlocks[i];

            if(valueBlock.block > block) {
                return prevLogValueBlock.value;
            }

            prevLogValueBlock = valueBlock;
        }

        return prevLogValueBlock.value;
    }

    function setBalance(address _address, uint256 value) internal {
        loggedBalances[_address].push(LogValueBlock(value, block.number));
    }

    function totalSupply() returns (uint256) {
        return valueAt(loggedTotalSupply, block.number);
    }

    function balanceOf(address _address) returns (uint256) {
        return valueAt(loggedBalances[_address], block.number);
    }

    function transferInternal(address _from, address _to, uint256 value) internal returns (bool success) {
        uint256 balanceFrom = valueAt(loggedBalances[msg.sender], block.number);
        uint256 balanceTo = valueAt(loggedBalances[_to], block.number);

        if(value == 0) {
            return false;
        }

        if(frozenAccount[_from] == true) {
            return false;
        }

        if(balanceFrom < value) {
            return false;
        }

        if(balanceTo + value <= balanceTo) {
            return false;
        }

        loggedBalances[_from].push(LogValueBlock(balanceFrom - value, block.number));
        loggedBalances[_to].push(LogValueBlock(balanceTo + value, block.number));

        Transfer(_from, _to, value);

        return true;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        require(locked == false);

        bool status = transferInternal(msg.sender, _to, _value);

        require(status == true);
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) returns (bool success) {
        if(locked) {
            return false;
        }

        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        if(locked) {
            return false;
        }

        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if(locked) {
            return false;
        }

        bool _success = transferInternal(_from, _to, _value);

        if(_success) {
            allowance[_from][msg.sender] -= _value;
        }

        return _success;
    }
}

contract LoggedDividend is Ownable, LoggedERC20 {
    /* Structs */
    struct Dividend {
    uint256 id;

    uint256 block;
    uint256 time;
    uint256 amount;

    uint256 claimedAmount;
    uint256 transferedBack;

    uint256 totalSupply;
    uint256 recycleTime;

    bool recycled;

    mapping (address => bool) claimed;
    }

    /* variables */
    Dividend [] public dividends;

    mapping (address => uint256) dividendsClaimed;

    /* Events */
    event DividendTransfered(uint256 id, address indexed _address, uint256 _block, uint256 _amount, uint256 _totalSupply);
    event DividendClaimed(uint256 id, address indexed _address, uint256 _claim);
    event UnclaimedDividendTransfer(uint256 id, uint256 _value);
    event DividendRecycled(uint256 id, address indexed _recycler, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply);

    function LoggedDividend(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    bool transferAllSupplyToOwner,
    bool _locked
    ) LoggedERC20(initialSupply, tokenName, decimalUnits, tokenSymbol, transferAllSupplyToOwner, _locked) {

    }

    function addDividend(uint256 recycleTime) payable onlyOwner {
        require(msg.value > 0);

        uint256 id = dividends.length;
        uint256 _totalSupply = valueAt(loggedTotalSupply, block.number);

        dividends.push(
        Dividend(
        id,
        block.number,
        now,
        msg.value,
        0,
        0,
        _totalSupply,
        recycleTime,
        false
        )
        );

        DividendTransfered(id, msg.sender, block.number, msg.value, _totalSupply);
    }

    function claimDividend(uint256 dividendId) public returns (bool) {
        if(dividends.length - 1 < dividendId) {
            return false;
        }

        Dividend storage dividend = dividends[dividendId];

        if(dividend.claimed[msg.sender] == true) {
            return false;
        }

        if(dividend.recycled == true) {
            return false;
        }

        if(now >= dividend.time + dividend.recycleTime) {
            return false;
        }

        uint256 balance = valueAt(loggedBalances[msg.sender], dividend.block);

        if(balance == 0) {
            return false;
        }

        uint256 claim = balance * dividend.amount / dividend.totalSupply;

        dividend.claimed[msg.sender] = true;

        dividend.claimedAmount = dividend.claimedAmount + claim;

        if (claim > 0) {
            msg.sender.transfer(claim);
            DividendClaimed(dividendId, msg.sender, claim);

            return true;
        }

        return false;
    }

    function claimDividends() public {
        require(dividendsClaimed[msg.sender] < dividends.length);
        for (uint i = dividendsClaimed[msg.sender]; i < dividends.length; i++) {
            if ((dividends[i].claimed[msg.sender] == false) && (dividends[i].recycled == false)) {
                dividendsClaimed[msg.sender] = i + 1;
                claimDividend(i);
            }
        }
    }

    function recycleDividend(uint256 dividendId) public onlyOwner returns (bool success) {
        if(dividends.length - 1 < dividendId) {
            return false;
        }

        Dividend storage dividend = dividends[dividendId];

        if(dividend.recycled) {
            return false;
        }

        dividend.recycled = true;

        return true;
    }

    function refundUnclaimedEthers(uint256 dividendId) public onlyOwner returns (bool success) {
        if(dividends.length - 1 < dividendId) {
            return false;
        }

        Dividend storage dividend = dividends[dividendId];

        if(dividend.recycled == false) {
            if(now < dividend.time + dividend.recycleTime) {
                return false;
            }
        }

        uint256 claimedBackAmount = dividend.amount - dividend.claimedAmount;

        dividend.transferedBack = claimedBackAmount;

        if(claimedBackAmount > 0) {
            owner.transfer(claimedBackAmount);

            UnclaimedDividendTransfer(dividendId, claimedBackAmount);

            return true;
        }

        return false;
    }
}

contract LoggedPhaseICO is LoggedDividend {
    uint256 public icoSince;
    uint256 public icoTill;

    uint256 public collectedEthers;

    Phase[] public phases;

    struct Phase {
    uint256 price;
    uint256 maxAmount;
    }

    function LoggedPhaseICO(
    uint256 _icoSince,
    uint256 _icoTill,
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol,
    uint8 precision,
    bool transferAllSupplyToOwner,
    bool _locked
    ) LoggedDividend(initialSupply, tokenName, precision, tokenSymbol, transferAllSupplyToOwner, _locked) {
        standard = &#39;LoggedPhaseICO 0.1&#39;;

        icoSince = _icoSince;
        icoTill = _icoTill;
    }

    function getIcoTokensAmount(uint256 collectedEthers, uint256 value) returns (uint256) {
        uint256 amount;

        uint256 newCollectedEthers = collectedEthers;
        uint256 remainingValue = value;

        for (uint i = 0; i < phases.length; i++) {
            Phase storage phase = phases[i];

            if(phase.maxAmount > newCollectedEthers) {
                if (newCollectedEthers + remainingValue > phase.maxAmount) {
                    uint256 diff = phase.maxAmount - newCollectedEthers;

                    amount += diff * 1 ether / phase.price;

                    remainingValue -= diff;
                    newCollectedEthers += diff;
                }
                else {
                    amount += remainingValue * 1 ether / phase.price;

                    newCollectedEthers += remainingValue;

                    remainingValue = 0;
                }
            }

            if (remainingValue == 0) {
                break;
            }
        }

        if (remainingValue > 0) {
            return 0;
        }

        return amount;
    }

    function buy(address _address, uint256 time, uint256 value) internal returns (bool) {
        if (locked == true) {
            return false;
        }

        if (time < icoSince) {
            return false;
        }

        if (time > icoTill) {
            return false;
        }

        if (value == 0) {
            return false;
        }

        uint256 amount = getIcoTokensAmount(collectedEthers, value);

        if(amount == 0) {
            return false;
        }

        uint256 selfBalance = valueAt(loggedBalances[this], block.number);
        uint256 holderBalance = valueAt(loggedBalances[_address], block.number);

        if (selfBalance < amount) {
            return false;
        }

        if (holderBalance + amount < holderBalance) {
            return false;
        }

        setBalance(_address, holderBalance + amount);
        setBalance(this, selfBalance - amount);

        collectedEthers += value;

        Transfer(this, _address, amount);

        return true;
    }

    function () payable {
        bool status = buy(msg.sender, now, msg.value);

        require(status == true);
    }
}

contract Cajutel is LoggedPhaseICO {
    function Cajutel(
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol,
    address founder1,
    address founder2,
    address marketing,
    uint256 icoSince,
    uint256 icoTill
    ) LoggedPhaseICO(icoSince, icoTill, initialSupply, tokenName, tokenSymbol, 18, false, false) {
        standard = &#39;Cajutel 0.1&#39;;

        phases.push(Phase(0.05 ether, 500 ether));
        phases.push(Phase(0.075 ether, 750 ether + 500 ether));
        phases.push(Phase(0.1 ether, 10000 ether + 750 ether + 500 ether));
        phases.push(Phase(0.15 ether, 30000 ether + 10000 ether + 750 ether + 500 ether));
        phases.push(Phase(0.2 ether, 80000 ether + 30000 ether + 10000 ether + 750 ether + 500 ether));

        uint256 founder1Tokens = 900000000000000000000000;
        uint256 founder2Tokens = 100000000000000000000000;
        uint256 marketingTokens = 60000000000000000000000;

        setBalance(founder1, founder1Tokens);

        Transfer(this, founder1, founder1Tokens);

        setBalance(founder2, founder2Tokens);

        Transfer(this, founder2, founder2Tokens);

        setBalance(marketing, marketingTokens);

        Transfer(this, marketing, marketingTokens);

        setBalance(this, initialSupply - founder1Tokens - founder2Tokens - marketingTokens);
    }

    function transferEthers() onlyOwner {
        owner.transfer(this.balance);
    }

    function setLocked(bool _locked) onlyOwner {
        locked = _locked;
    }

    function setIcoDates(uint256 _icoSince, uint256 _icoTill) onlyOwner {
        icoSince = _icoSince;
        icoTill = _icoTill;
    }
}