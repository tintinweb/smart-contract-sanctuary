// SPDX-License-Identifier: UNLICENSED

/*

    syyhhdddhhhh+             `oyyyyyyyyyyy/
     +yyhddddddddy.          -yhhhhhhhhhhy- 
      :ysyhdddddddh:       `+hhhhhhhhhhho`  
       .yosyhhhddddh.     .shhhhhhhhhhh/    
        `ososyhhhhy-     /hhhhhhhhhhhs.     
          /s+osyyo`    `ohhhhhhhhhhh+`      
           -s+os:     -yhhhhhhhhhhy:        
            .o+.    `/yyyyyhhhhhho.         
                   .+sssyyyyyhhy/`          
                  -+ooosssyyyys-            
                `:++++oossyyy+`             
               .///+++ooosss:               
             `-/////+++ooso.    `.          
            `:///////++oo/     .sh/         
           .::///////++o-     :yhhdo`       
         `::::://////+/`    `+yhhdddy-      
        .:::::://///+-     .oyhhhddddd+     
       -::::::::///+.      /syhhhddddmmy.   
     `:::::::::://:         -oyhhddddmmmd:  
    -////////////.           `+yhdddddmmmmo 

*/

pragma solidity ^0.8.6;

// Third-party contract imports.
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// Third-party library imports.
import "./Address.sol";
import "./EnumerableSet.sol";
import "./SafeBEP20.sol";
import "./SafeMath.sol";


// A Vault contract that allows users to place their tokens into one or more
// term deposits. Deposited tokens will be locked for a fixed period of time,
// but upon reaching maturity, are able to be released with an added reward
// proportional to the duration of the term.
contract Vault is Ownable, ReentrancyGuard
{
    // Local aliasing of imported assets.
    using Address       for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeBEP20     for IBEP20;
    using SafeMath      for uint256;
    
    // A safe deposit box to track the user's deposited principal, when the
    // deposit reaches maturity, and the reward upon reaching maturity.
    struct SafeDepositBox
    {
        uint256 end_time;
        uint256 principal;
        uint256 reward;
    }
    
    // A term for which a deposit is made and a mapping of all existing
    // deposits with that term length. Each term deposit has a duration, a
    // minimum required deposit, a numerator and denominator which set the
    // yield rate, and a list of safe deposit boxes being held under this
    // term.
    struct TermDeposit
    {
        uint256 duration;
        uint256 minimum_deposit;
        uint256 yield_numerator;
        uint256 yield_denominator;
        uint256 number_of_accounts;
        EnumerableSet.AddressSet accounts;
        mapping(address => SafeDepositBox) deposits;
    }
    
    // Determines the token to be accepted and handled by the vault and any
    // additional values necessary for properly handling supplies of it.
    IBEP20 immutable vault_token;
    address public vault_token_address;
    uint256 public vault_token_decimals;
    uint256 private vault_token_scale_factor;
    
    // Maps a unique duration in seconds to the safe deposit boxes associated
    // with those terms.
    uint256 public number_of_terms = 0;
    mapping(uint256 => TermDeposit) private deposit_terms;
    
    // Tracks the total number of tokens currently held on behalf of users.
    uint256 public current_vault_holdings = 0;
    uint256 public pending_vault_rewards  = 0;
    
    // A Unix timestamp which, if greater than the current block timestamp,
    // prevents the contract owner from withdrawing vault tokens.
    uint256 public owner_withdrawal_locked_until = 0;
    
    // Events that the contract can emit.
    event OwnerBNBRecovery(uint256 amount);
    event OwnerTokenRecovery(address token_recovered, uint256 amount);
    event OwnerWithdrawal(uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event PrematureWithdrawal(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event CreateTerm(
        uint256 duration,
        uint256 minimum_deposit,
        uint256 yield_numerator,
        uint256 yield_denominator
    );
    
    // Instantiates the Vault contract.
    //
    // @param _original_owner:
    //  - An address to specify the contract owner on contract creation.
    constructor(
        address _original_owner,
        address _vault_token_address
    ) Ownable(_original_owner)
    {
        // Configures the token that the vault will handle.
        vault_token              = IBEP20(_vault_token_address);
        vault_token_address      = _vault_token_address;
        vault_token_decimals     = IBEP20(vault_token_address).decimals();
        vault_token_scale_factor = 10 ** vault_token_decimals;
        
        // Defines a deposit of at least 10 million tokens with a term of
        // 7 days which returns a 0.5% yield upon maturity.
        createTerm(7 days, toEther(10 ** 7), 5, 1000);
        
        // Defines a deposit of at least 100 million tokens with a term of
        // 30 days which returns a 3.0% yield upon maturity.
        createTerm(30 days, toEther(10 ** 8), 30, 1000);
        
        // Defines a deposit of at least 1 billion tokens with a term of
        // 90 days which returns a 10.0% yield upon maturity.
        createTerm(90 days, toEther(10 ** 9), 100, 1000);
        
        // Defines a deposit of at least 10 billion tokens with a term of
        // 180 days which returns a 22.0% yield upon maturity.
        createTerm(180 days, toEther(10 ** 10), 220, 1000);
    }
    
    // A modifier to validate a term ID parameter of a function.
    modifier validTermID(uint256 _term_id)
    {
        // Requires that a term matching the chosen ID exists.
        require(_term_id <= (number_of_terms - 1), "Invalid term ID");
        
        // Executes the modified function.
        _;
    }
    
    // Allows this contract to receive and handle BNB.
    receive() external payable
    {}
    
    // Allows the contract owner to recover BNB sent to the contract.
    function recoverBNB() public onlyOwner
    {
        // Identifies how much BNB is held by the contract.
        uint256 contract_balance = address(this).balance;
        
        // Requires that the amount of BNB being recovered is greater than
        // zero.
        require(contract_balance > 0, "Contract BNB balance is zero");
        
        // Transfers all BNB in the contract to the contract owner.
        payable(owner()).transfer(contract_balance);
        
        // Emits a BNB recovery event.
        emit OwnerBNBRecovery(contract_balance);
    }
    
    // Releases a random token sent to this contract to the contract owner.
    //
    // Blocks attempts to release the token stored in and rewarded by the vault
    // to protect the holdings of its users.
    //
    // @param token_address:
    //  - The address of the token being recovered.
    function recoverTokens(address token_address) public onlyOwner
    {
        // Requires that the token being recoverd is not the same token that
        // protected by the vault.
        require(
            token_address != vault_token_address,
            "Cannot recover the vault protected token with this function"
        );
        
        // Interfaces with the token being recovered.
        IBEP20 token = IBEP20(token_address);
        
        // Identifies how much of the token is held by the contract.
        uint256 contract_balance = token.balanceOf(address(this));
        
        // Requires that the amount of the token being recovered is greater
        // than zero.
        require(contract_balance > 0, "Contract token balance is zero");
        
        // Transfers the full balance of the token held by the contract to the
        // contract owner.
        token.safeTransfer(owner(), contract_balance);
        
        // Emits a token recovery event.
        emit OwnerTokenRecovery(token_address, contract_balance);
    }
    
    // Releases vault tokens to the contract owner.
    //
    // This function can be time-locked for the security of the vault users.
    //
    // @param _amount:
    //  - The number of tokens to recover in fixed point format.
    function recoverVaultTokens(uint256 _amount) public onlyOwner
    {
        // Requires that owner recovery of vault tokens not be protected under
        // a current time-lock.
        require(
            owner_withdrawal_locked_until <= block.timestamp,
            "The vault protected token is currently locked"
        );
        
        // Identifies how much of the vault token is held by the contract.
        uint256 contract_balance = vault_token.balanceOf(address(this));
        
        // Requires that the amount of tokens held by the contract matches or
        // exceeds the amount being recovered.
        require(
            contract_balance >= _amount,
            "Cannot withdraw more tokens than are held by the contract"
        );
        
        // Transfers the full balance of the token held by the contract to the
        // contract owner.
        vault_token.safeTransfer(owner(), _amount);
        
        // Emits a token recovery event.
        emit OwnerWithdrawal(_amount);
    }
    
    // Sets or extends a time-lock on the recovery of vault protected tokens by
    // the contract owner.
    //
    // @param _release_time;
    //  - The Unix timestamp that owner vault token recovery is locked until.
    function lockOwnerWithdrawal(uint256 _release_time) public onlyOwner
    {
        // Requires that the release time be a future time.
        require(
            _release_time > block.timestamp,
            "The lock release timestamp must be greater than the current timestamp"
        );
        
        // Requires the new release time to exceed any existing release time.
        require(
            _release_time > owner_withdrawal_locked_until,
            "The new lock release time must be greater than the current one"
        );
        
        // Sets a new time-lock release time.
        owner_withdrawal_locked_until = _release_time;
    }
    
    // Converts the token amount from fixed point representation to the
    // floating point representation that most users are accustomed to.
    //
    // @param _amount:
    //  - The number of tokens to deposit in fixed point representation.
    function toEther(uint256 _amount) public view returns(uint256)
    {
        // Returns the amount scaled to the floating point representation
        // according to the number of decimals utilized by the token.
        return _amount.mul(vault_token_scale_factor);
    }
    
    // Creates a possible term option for a vault deposit.
    //
    // The ID number associated with a given term is determined by the order
    // in which it was created. IDs start at zero and increment from there.
    //
    // @param _duration:
    //  - The duration of the term in seconds.
    //
    // @param _minimum_deposit:
    //  - The minimum allowed deposit for this term given in expanded integer
    //    form.
    //
    // @param _yield_numerator:
    //  - The numerator used to calculate the yield percentage.
    //
    // @param _yield_denominator:
    //  - The denominator used to calculate the yield percentage.
    function createTerm(
        uint256 _duration,
        uint256 _minimum_deposit,
        uint256 _yield_numerator,
        uint256 _yield_denominator
    ) public onlyOwner
    {
        // Requires that the duration of the deposit term be longer than zero.
        require(_duration > 0, "The duration of the term cannot be zero");
        
        // Creates a new term deposit and increments the tracker of the number
        // of term deposits that have been created.
        TermDeposit storage _term = deposit_terms[number_of_terms++];
        
        // Sets the attributes of the newly created term.
        _term.duration           = _duration;
        _term.minimum_deposit    = _minimum_deposit;
        _term.yield_numerator    = _yield_numerator;
        _term.yield_denominator  = _yield_denominator;
        _term.number_of_accounts = 0;
        
        // Emits a term creation event.
        emit CreateTerm(
            _duration,
            _minimum_deposit,
            _yield_numerator,
            _yield_denominator
        );
    }
    
    // Calculates the reward owed upon term deposit maturity.
    //
    // @param _principal:
    //  - The amount of principal deposited.
    //
    // @param _yield_numerator:
    //  - The numerator used to calculate the yield percentage.
    //
    // @param _yield_denominator:
    //  - The denominator used to calculate the yield percentage.
    function calculateReward(
        uint256 _principal,
        uint256 _yield_numerator,
        uint256 _yield_denominator
    ) public pure returns(uint256)
    {
        return _principal.mul(_yield_numerator).div(_yield_denominator);
    }
    
    // Allows an account to make a deposit to a specific term.
    //
    // @param _term_id:
    //  - An integer identifier associated with one of the existing terms.
    //
    // @param _amount:
    //  - The number of tokens to recover in fixed point format.
    function deposit(
        uint256 _term_id,
        uint256 _amount
    ) public nonReentrant validTermID(_term_id)
    {
        // Requires that the amount deposited is greater than zero.
        require(_amount > 0, "The amount to deposit cannot be zero");
        
        // Loads the deposit term associated with the given term ID.
        TermDeposit storage _term = deposit_terms[_term_id];
        
        // Requires one deposit per account per term.
        require(
            !_term.accounts.contains(_msgSender()),
            "A deposit already exists for this account and term"
        );
        
        // Requires that the deposited amount match or exceed the minimum
        // requirement.
        require(
            _amount >= _term.minimum_deposit,
            "Deposit is below the minimum principal required for this term"
        );
        
        // Adds the user to the list of accounts for this term.
        _term.accounts.add(_msgSender());
        _term.number_of_accounts++;
        
        // Creates a safe deposit box in the vault for this user.
        SafeDepositBox storage _deposit = _term.deposits[_msgSender()];
        
        // Transfers the amount deposited to the contract.
        vault_token.safeTransferFrom(
            address(_msgSender()),
            address(this),
            _amount
        );
        
        // Sets the attributes of the box.
        _deposit.end_time  = block.timestamp + _term.duration;
        _deposit.principal = _amount;
        _deposit.reward    = calculateReward(
            _amount,
            _term.yield_numerator,
            _term.yield_denominator
        );
        
        // Increments the current holdings and pending reward trackers.
        current_vault_holdings = current_vault_holdings.add(_deposit.principal);
        pending_vault_rewards  = pending_vault_rewards.add(_deposit.reward);
        
        // Emits a deposit event.
        emit Deposit(_msgSender(), _amount);
    }
    
    // Allows an account to make a withdrawal from a specific term.
    //
    // @param _term_id:
    //  - An integer identifier associated with one of the existing terms.
    function withdraw(uint256 _term_id) public nonReentrant validTermID(_term_id)
    {
        // Loads the deposit term associated with the given term ID.
        TermDeposit storage _term = deposit_terms[_term_id];
        
        // Requires that an account has made a deposit for this term.
        require(
            _term.accounts.contains(_msgSender()),
            "No deposit exists for this account and term"
        );
        
        // Accesses the safe deposit box in the vault for this user.
        SafeDepositBox storage _deposit = _term.deposits[_msgSender()];
        
        // Requires that the deposit for this term be mature to withdraw.
        require(
            _deposit.end_time <= block.timestamp,
            "Cannot withdraw deposit before it reaches maturity"
        );
        
        // The amount to be withdrawn, calculated as the original deposit plus
        // the earned reward.
        uint256 _amount = _deposit.principal + _deposit.reward;
        
        // Checks how many tokens are currently held by the contract.
        uint256 contract_balance = vault_token.balanceOf(address(this));
        
        // Requires that the contract contain enough tokens to withdraw.
        require(
            contract_balance >= _amount,
            "Contract contains insufficient tokens to match this withdrawal attempt"
        );
        
        // Withdraws the tokens.
        vault_token.safeTransfer(_msgSender(), _amount);
        
        // Decrements the current holdings and pending reward trackers.
        current_vault_holdings = current_vault_holdings.sub(_deposit.principal);
        pending_vault_rewards  = pending_vault_rewards.sub(_deposit.reward);
        
        // Closes the account's safe deposit box for this term.
        _term.accounts.remove(_msgSender());
        delete _term.deposits[_msgSender()];
        _term.number_of_accounts--;
        
        // Emits a withdrawal event.
        emit Withdrawal(msg.sender, _amount);
    }
    
    // Allows an account to make a premature withdrawal.
    //
    // @param _term_id:
    //  - An integer identifier associated with one of the existing terms.
    function withdrawPrematurely(uint256 _term_id) public nonReentrant validTermID(_term_id)
    {
        // Loads the deposit term associated with the given term ID.
        TermDeposit storage _term = deposit_terms[_term_id];
        
        // Requires that an account has made a deposit for this term.
        require(
            _term.accounts.contains(_msgSender()),
            "No deposit exists for this account and term"
        );
        
        // Accesses the safe deposit box in the vault for this user.
        SafeDepositBox storage _deposit = _term.deposits[_msgSender()];
        
        // The amount of principal being prematurely withdrawn.
        uint256 _amount = _deposit.principal;
        
        // Checks how many tokens are currently held by the contract.
        uint256 contract_balance = vault_token.balanceOf(address(this));
        
        // Requires that the contract contain enough tokens to withdraw.
        require(
            contract_balance >= _amount,
            "Contract contains insufficient tokens to match this withdrawal attempt"
        );
        
        // Withdraws the tokens.
        vault_token.safeTransfer(_msgSender(), _amount);
        
        // Decrements the current holdings and pending reward trackers.
        current_vault_holdings = current_vault_holdings.sub(_deposit.principal);
        pending_vault_rewards  = pending_vault_rewards.sub(_deposit.reward);
        
        // Closes the account's safe deposit box for this term.
        _term.accounts.remove(_msgSender());
        delete _term.deposits[_msgSender()];
        _term.number_of_accounts--;
        
        // Emits a premature withdrawal event.
        emit PrematureWithdrawal(msg.sender, _amount);
    }
    
    // Determines the number of tokens available to pay out from the vault.
    function vaultBalance() public view returns(uint256)
    {
        // Returns the current token balance in the contract.
        return vault_token.balanceOf(address(this));
    }
    
    // Determines how many tokens would be owed by the vault to holders if all
    // of them were eligible to withdraw their principal and interest
    // immediately.
    function vaultDebt() public view returns(uint256)
    {
        return current_vault_holdings + pending_vault_rewards;
    }
    
    // Retrieves information about a term.
    //
    // @param _term_id:
    //  - An integer identifier associated with one of the existing terms.
    function getTermInfo(
        uint256 _term_id
    ) public view validTermID(_term_id) returns(
        uint256 duration,
        uint256 minimum_deposit,
        uint256 yield_numerator,
        uint256 yield_denominator,
        uint256 number_of_accounts
    )
    {
        // Loads the deposit term associated with the given term ID.
        TermDeposit storage _term = deposit_terms[_term_id];
        
        // Populates the return values with information about the loaded term.
        duration           = _term.duration;
        minimum_deposit    = _term.minimum_deposit;
        yield_numerator    = _term.yield_numerator;
        yield_denominator  = _term.yield_denominator;
        number_of_accounts = _term.number_of_accounts;
    }
    
    // Retrieves information about a safe deposit box.
    //
    // @param _term_id:
    //  - An integer identifier associated with one of the existing terms.
    function getDepositInfo(
        uint256 _term_id,
        address _account
    ) public view validTermID(_term_id) returns(
        uint256 end_time,
        uint256 principal,
        uint256 reward
    )
    {
        // Loads the deposit term associated with the given term ID.
        TermDeposit storage _term = deposit_terms[_term_id];
        
        // Requires that an account has made a deposit for this term.
        require(
            _term.accounts.contains(_account),
            "No deposit exists for this account and term"
        );
        
        // Accesses the safe deposit box in the vault for this user.
        SafeDepositBox storage _deposit = _term.deposits[_account];
        
        // Populates the return values with information about the loaded
        // safe deposit box.
        end_time  = _deposit.end_time;
        principal = _deposit.principal;
        reward    = _deposit.reward;
    }
}