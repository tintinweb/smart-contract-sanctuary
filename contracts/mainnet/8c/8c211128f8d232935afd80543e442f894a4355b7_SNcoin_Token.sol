pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
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

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount_old The current allowed amount in the `approve()` call
    /// @param _amount_new The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount_old, uint _amount_new) public returns(bool);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract SNcoin_Token is ERC20Interface, Owned {
    string public constant symbol = "SNcoin";
    string public constant name = "scientificcoin";
    uint8 public constant decimals = 18;
    uint private constant _totalSupply = 100000000 * 10**uint(decimals);

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    struct LimitedBalance {
        uint8 limitType;
        uint initial;
    }
    mapping(address => LimitedBalance) limited_balances;
    uint8 public constant limitDefaultType = 0;
    uint8 public constant limitTeamType = 1;
    uint8 public constant limitBranchType = 2;
    uint8 private constant limitTeamIdx = 0;
    uint8 private constant limitBranchIdx = 1;
    uint8[limitBranchType] private limits;
    uint8 private constant limitTeamInitial = 90;
    uint8 private constant limitBranchInitial = 90;
    uint8 private constant limitTeamStep = 3;
    uint8 private constant limitBranchStep = 10;

    address public controller;
    
    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        balances[owner] = _totalSupply;
        transfersEnabled = true;
        limits[limitTeamIdx] = limitTeamInitial;
        limits[limitBranchIdx] = limitBranchInitial;
        emit Transfer(address(0), owner, _totalSupply);
    }


    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function setController(address _newController) public onlyOwner {
        controller = _newController;
    }
    
    function limitOfTeam() public constant returns (uint8 limit) {
        return 100 - limits[limitTeamIdx];
    }

    function limitOfBranch() public constant returns (uint8 limit) {
        return 100 - limits[limitBranchIdx];
    }

    function getLimitTypeOf(address tokenOwner) public constant returns (uint8 limitType) {
        return limited_balances[tokenOwner].limitType;
    }

    function getLimitedBalanceOf(address tokenOwner) public constant returns (uint balance) {
       if (limited_balances[tokenOwner].limitType > 0) {
           require(limited_balances[tokenOwner].limitType <= limitBranchType);
           uint minimumLimit = (limited_balances[tokenOwner].initial * limits[limited_balances[tokenOwner].limitType - 1])/100;
           require(balances[tokenOwner] >= minimumLimit);
           return balances[tokenOwner] - minimumLimit;
       }
       return balanceOf(tokenOwner);
    }

    function incrementLimitTeam() public onlyOwner returns (bool success) {
        require(transfersEnabled);

        uint8 previousLimit = limits[limitTeamIdx];
        if ( previousLimit - limitTeamStep >= 100) {
            limits[limitTeamIdx] = 0;
        } else {
            limits[limitTeamIdx] = previousLimit - limitTeamStep;
        }

        return true;
    }

    function incrementLimitBranch() public onlyOwner returns (bool success) {
        require(transfersEnabled);

        uint8 previousLimit = limits[limitBranchIdx];
        if ( previousLimit - limitBranchStep >= 100) {
            limits[limitBranchIdx] = 0;
        } else {
            limits[limitBranchIdx] = previousLimit - limitBranchStep;
        }

        return true;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address _spender, uint _amount) public returns (bool success) {
        require(transfersEnabled);

        // Alerts the token controller of the approve function call
        if (controller != 0) {
            require(TokenController(controller).onApprove(msg.sender, _spender, allowed[msg.sender][_spender], _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
        require(transfersEnabled);

        // The standard ERC 20 transferFrom functionality
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;
        doTransfer(_from, _to, _amount);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferToTeam(address _to, uint _amount) public onlyOwner returns (bool success) {
        require(transfersEnabled);
        transferToLimited(msg.sender, _to, _amount, limitTeamType);

        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferToBranch(address _to, uint _amount) public onlyOwner returns (bool success) {
        require(transfersEnabled);
        transferToLimited(msg.sender, _to, _amount, limitBranchType);

        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferToLimited(address _from, address _to, uint _amount, uint8 _limitType) internal {
        require((_limitType >= limitTeamType) && (_limitType <= limitBranchType));
        require((limited_balances[_to].limitType == 0) || (limited_balances[_to].limitType == _limitType));

        doTransfer(_from, _to, _amount);

        uint previousLimitedBalanceInitial = limited_balances[_to].initial;
        require(previousLimitedBalanceInitial + _amount >= previousLimitedBalanceInitial); // Check for overflow
        limited_balances[_to].initial = previousLimitedBalanceInitial + _amount;
        limited_balances[_to].limitType = _limitType;
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount) internal {
           if (_amount == 0) {
               emit Transfer(_from, _to, _amount);    // Follow the spec to louch the event when transfer 0
               return;
           }

           // Do not allow transfer to 0x0 or the token contract itself
           require((_to != 0) && (_to != address(this)));

           // If the amount being transfered is more than the balance of the
           //  account the transfer throws
           uint previousBalanceFrom = balanceOf(_from);

           require(previousBalanceFrom >= _amount);

           // Alerts the token controller of the transfer
           if (controller != 0) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

           // First update the balance array with the new value for the address
           //  sending the tokens
           balances[_from] = previousBalanceFrom - _amount;
           
           if (limited_balances[_from].limitType > 0) {
               require(limited_balances[_from].limitType <= limitBranchType);
               uint minimumLimit = (limited_balances[_from].initial * limits[limited_balances[_from].limitType - 1])/100;
               require(balances[_from] >= minimumLimit);
           }

           // Then update the balance array with the new value for the address
           //  receiving the tokens
           uint previousBalanceTo = balanceOf(_to);
           require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
           balances[_to] = previousBalanceTo + _amount;

           // An event to make the transfer easy to find on the blockchain
           emit Transfer(_from, _to, _amount);
    }

    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) public onlyOwner {
        transfersEnabled = _transfersEnabled;
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20Interface token = ERC20Interface(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
    
    event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
}