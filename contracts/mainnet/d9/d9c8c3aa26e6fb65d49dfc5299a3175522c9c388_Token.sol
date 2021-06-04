/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

/**
 *Submitted for verification at Etherscan.io on 2017-05-06
*/

pragma solidity >=0.4.4;

// Copyright 2017 Alchemy Limited LLC, Do not distribute

contract Constants {
    uint DECIMALS = 8;
}


contract Owned {
    address public owner;

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    address newOwner;

    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

//from Zeppelin
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) throw;
    }
}



//Copyright 2017 Alchemy Limited LLC DO not distribute
//ERC20 token

contract Token is SafeMath, Owned, Constants {
    uint public currentSupply;
    uint public remainingOwner;
    uint public remainingAuctionable;
    uint public ownerTokensFreeDay;
    bool public launched = false;

    bool public remaindersSet = false;
    bool public mintingDone = false;

    address public controller;

    string public name;
    uint8 public decimals;
    string public symbol;

    modifier onlyController() {
        if (msg.sender != controller) throw;
        _;
    }

    modifier isLaunched() {
        assert(launched == true);
        _;
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    function Token() {
        owner = msg.sender;
        name = "Monolith RPT";
        decimals = uint8(DECIMALS);
        symbol = "RPT";
    }

    function Launch() onlyOwner {
        launched = true;
    }

    function setOwnerFreeDay(uint day) onlyOwner {
        if (ownerTokensFreeDay != 0) throw;

        ownerTokensFreeDay = day;
    }

    function totalSupply() constant returns(uint) {
        return currentSupply + remainingOwner;
    }

    function setRemainders(uint _remainingOwner, uint _remainingAuctionable) onlyOwner {
        if (remaindersSet) { throw; }

        remainingOwner = _remainingOwner;
        remainingAuctionable = _remainingAuctionable;
    }

    function finalizeRemainders() onlyOwner {
        remaindersSet = true;
    }

    function setController(address _controller) onlyOwner {
        controller = _controller;
    }

    function claimOwnerSupply() onlyOwner {
        if (now < ownerTokensFreeDay) throw;
        if (remainingOwner == 0) throw;
        if (!remaindersSet) throw; // must finalize remainders

        balanceOf[owner] = safeAdd(balanceOf[owner], remainingOwner);
        remainingOwner = 0;
    }

    function claimAuctionableTokens(uint amount) onlyController {
        if (amount > remainingAuctionable) throw;

        balanceOf[controller] = safeAdd(balanceOf[controller], amount);
        currentSupply = safeAdd(currentSupply, amount);
        remainingAuctionable = safeSub(remainingAuctionable,amount);

        Transfer(0, controller, amount);
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function mint(address addr, uint amount) onlyOwner onlyPayloadSize(2) {
        if (mintingDone) throw;

        balanceOf[addr] = safeAdd(balanceOf[addr], amount);

        currentSupply = safeAdd(currentSupply, amount);

        Transfer(0, addr, amount);
    }


    uint constant D160 = 0x0010000000000000000000000000000000000000000;

    // We don't use safe math in this function
    // because this will be called for the owner before the contract
    // is published and we need to save gas.
    function multiMint(uint[] data) onlyOwner {
        if (mintingDone) throw;

        uint supplyAdd;
        for (uint i = 0; i < data.length; i++ ) {
            address addr = address( data[i] & (D160-1) );
            uint amount = data[i] / D160;

            balanceOf[addr] += amount;
            supplyAdd += amount;
            Transfer(0, addr, amount);
        }
        currentSupply += supplyAdd;
    }

    function completeMinting() onlyOwner {
        mintingDone = true;
    }

    mapping(address => uint) public balanceOf;
    mapping(address => mapping (address => uint)) public allowance;

    function transfer(address _to, uint _value) isLaunched notPaused
    onlyPayloadSize(2)
    returns (bool success) {
        if (balanceOf[msg.sender] < _value) return false;
        if (_to == 0x0) return false;

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)  isLaunched notPaused
    onlyPayloadSize(3)
    returns (bool success) {
        if (_to == 0x0) return false;
        if (balanceOf[_from] < _value) return false;

        var allowed = allowance[_from][msg.sender];
        if (allowed < _value) return false;

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        allowance[_from][msg.sender] = safeSub(allowed, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value)
    onlyPayloadSize(2)
    returns (bool success) {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) {
            return false;
        }

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval (address _spender, uint _addedValue)
    onlyPayloadSize(2)
    returns (bool success) {
        uint oldValue = allowance[msg.sender][_spender];
        allowance[msg.sender][_spender] = safeAdd(oldValue, _addedValue);
        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue)
    onlyPayloadSize(2)
    returns (bool success) {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) returns (bool success) {
        if (!approve(_spender, _amount)) throw;

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    //Holds accumulated dividend tokens other than RPT
    TokenHolder public tokenholder;

    //once locked, can no longer upgrade tokenholder
    bool public lockedTokenHolder;

    function lockTokenHolder() onlyOwner {
        lockedTokenHolder = true;
    }

    function setTokenHolder(address _th) onlyOwner {
        if (lockedTokenHolder) throw;
        tokenholder = TokenHolder(_th);
    }

    function burn(uint _amount) notPaused returns (bool result)  {
        if (_amount > balanceOf[msg.sender]) return false;

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _amount);
        currentSupply  = safeSub(currentSupply, _amount);
        result = tokenholder.burn(msg.sender, _amount);
        if (!result) throw;
        Transfer(msg.sender, 0, _amount);
    }

    // Peterson's Law Protection
    event logTokenTransfer(address token, address to, uint amount);

    function claimTokens(address _token) onlyOwner {
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        Token token = Token(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        logTokenTransfer(_token, owner, balance);
    }

    // Pause mechanism

    bool public pausingMechanismLocked = false;
    bool public paused = false;

    modifier notPaused() {
        if (paused) throw;
        _;
    }

    function pause() onlyOwner {
        if (pausingMechanismLocked) throw;
        paused = true;
    }

    function unpause() onlyOwner {
        if (pausingMechanismLocked) throw;
        paused = false;
    }

    function neverPauseAgain() onlyOwner {
        pausingMechanismLocked = true;
    }
}

contract TokenHolder {
    function burn(address , uint )
    returns (bool result) {
        return false;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}