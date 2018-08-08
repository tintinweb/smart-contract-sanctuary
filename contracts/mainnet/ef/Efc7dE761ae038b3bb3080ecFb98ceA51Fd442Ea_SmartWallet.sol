pragma solidity ^0.4.24;

contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /*
        @dev constructor
    */
    constructor (address _owner) public {
        owner = _owner;
    }

    /*
        @dev allows execution by the owner only
    */
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

    /*
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /*
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Utils {
    /*
        @dev constructor
    */
    constructor() public {
    }

    /*
        @dev verifies that an amount is greater than zero
    */
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    /*
        @dev validates an address - currently only checks that it isn&#39;t null
    */
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    /*
        @dev verifies that the address is different than this contract address
    */
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    /*
        @dev verifies that the string is not empty
    */
    modifier notEmpty(string _str) {
        require(bytes(_str).length > 0);
        _;
    }

    // Overflow protected math functions

    /*
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /*
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y);
        return _x - _y;
    }

    /*
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

contract WithdrawalConfigurations is Ownable, Utils {
    
    /*
     *  Members
     */

    uint public      minWithdrawalCoolingPeriod;
    uint constant    maxWithdrawalCoolingPeriod = 12 * 1 weeks; // = 14515200 seconds
    uint public      withdrawalCoolingPeriod;
   
    /*
     *  Events
     */
    event WithdrawalRequested(address _userWithdrawalAccount, address _sender);
    event SetWithdrawalCoolingPeriod(uint _withdrawalCoolingPeriod);

    /*
        @dev constructor

        @param _withdrawalCoolingPeriod       The cooling period 
        @param _minWithdrawalCoolingPeriod    The minimum time from withdraw request to allow performing it

    */
    constructor (uint _withdrawalCoolingPeriod, uint _minWithdrawalCoolingPeriod) 
        Ownable(msg.sender)
        public
        {
            require(_withdrawalCoolingPeriod <= maxWithdrawalCoolingPeriod &&
                    _withdrawalCoolingPeriod >= _minWithdrawalCoolingPeriod);
            require(_minWithdrawalCoolingPeriod >= 0);

            minWithdrawalCoolingPeriod = _minWithdrawalCoolingPeriod;
            withdrawalCoolingPeriod = _withdrawalCoolingPeriod;
       }

    /*
        @dev Get the withdrawalCoolingPeriod parameter value. 
   
     */
    function getWithdrawalCoolingPeriod() external view returns(uint) {
        return withdrawalCoolingPeriod;
    }

    /*
        @dev Set the withdrawalCoolingPeriod parameter value. 

        @param _withdrawalCoolingPeriod   Cooling period in seconds
     */
    function setWithdrawalCoolingPeriod(uint _withdrawalCoolingPeriod)
        ownerOnly()
        public
        {
            require (_withdrawalCoolingPeriod <= maxWithdrawalCoolingPeriod &&
                     _withdrawalCoolingPeriod >= minWithdrawalCoolingPeriod);
            withdrawalCoolingPeriod = _withdrawalCoolingPeriod;
            emit SetWithdrawalCoolingPeriod(_withdrawalCoolingPeriod);
    }

    /*
        @dev Fire the WithdrawalRequested event. 

        @param _userWithdrawalAccount   User withdrawal account address
        @param _sender                  The user account, activating this request
     */
    function emitWithrawalRequestEvent(address _userWithdrawalAccount, address _sender) 
        public
        {
            emit WithdrawalRequested(_userWithdrawalAccount, _sender);
    }
}

library SmartWalletLib {

    /*
     *  Structs
     */ 
    struct Wallet {
        address operatorAccount;
        address userWithdrawalAccount;
        address feesAccount;
        uint    withdrawAllowedAt; //In seconds
    }

    /*
     *  Members
     */
    string constant VERSION = "1.1";
    address constant withdrawalConfigurationsContract = 0x0D6745B445A7F3C4bC12FE997a7CcbC490F06476; 
    
    /*
     *  Modifiers
     */
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    modifier addressNotSet(address _address) {
        require(_address == 0);
        _;
    }

    modifier operatorOnly(address _operatorAccount) {
        require(msg.sender == _operatorAccount);
        _;
    }

    modifier userWithdrawalAccountOnly(Wallet storage _self) {
        require(msg.sender == _self.userWithdrawalAccount);
        _;
    }

    /*
     *  Events
     */
    event TransferToBackupAccount(address _token, address _backupAccount, uint _amount);
    event TransferToUserWithdrawalAccount(address _token, address _userWithdrawalAccount, uint _amount, address _feesToken, address _feesAccount, uint _fee);
    event SetUserWithdrawalAccount(address _userWithdrawalAccount);
    event PerformUserWithdraw(address _token, address _userWithdrawalAccount, uint _amount);
    
    /*
        @dev Initialize the wallet with the operator and backupAccount address
        
        @param _self                        Wallet storage
        @param _operator                    The operator account
        @param _feesAccount                 The account to transfer fees to
    */
    function initWallet(Wallet storage _self, address _operator, address _feesAccount) 
            public
            validAddress(_operator)
            validAddress(_feesAccount)
            {
        
                _self.operatorAccount = _operator;
                _self.feesAccount = _feesAccount;
    }

    /*
        @dev Setting the account of the user to send funds to. 
        
        @param _self                        Wallet storage
        @param _userWithdrawalAccount       The user account to withdraw funds to
    */
    function setUserWithdrawalAccount(Wallet storage _self, address _userWithdrawalAccount) 
            public
            operatorOnly(_self.operatorAccount)
            validAddress(_userWithdrawalAccount)
            addressNotSet(_self.userWithdrawalAccount)
            {
        
                _self.userWithdrawalAccount = _userWithdrawalAccount;
                emit SetUserWithdrawalAccount(_userWithdrawalAccount);
    }
    
    /*
        @dev Withdraw funds to the user account. 

        @param _self                Wallet storage
        @param _token               The ERC20 token the owner withdraws from 
        @param _amount              Amount to transfer  
        @param _fee                 Fee to transfer   
    */
    function transferToUserWithdrawalAccount(Wallet storage _self, IERC20Token _token, uint _amount, IERC20Token _feesToken, uint _fee) 
            public 
            operatorOnly(_self.operatorAccount)
            validAddress(_self.userWithdrawalAccount)
            {

                if (_fee > 0) {        
                    _feesToken.transfer(_self.feesAccount, _fee); 
                }       
                
                _token.transfer(_self.userWithdrawalAccount, _amount);
                emit TransferToUserWithdrawalAccount(_token, _self.userWithdrawalAccount, _amount,  _feesToken, _self.feesAccount, _fee);   
        
    }

    /*
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }
    
    /*
        @dev user request withdraw. 

        @param _self                Wallet storage
        @param _token               The ERC20 token the owner withdraws from 
        
    */
    function requestWithdraw(Wallet storage _self) 
        public 
        userWithdrawalAccountOnly(_self)
        {
            
            WithdrawalConfigurations withdrawalConfigurations = WithdrawalConfigurations(withdrawalConfigurationsContract);
            
            _self.withdrawAllowedAt = safeAdd(now, withdrawalConfigurations.getWithdrawalCoolingPeriod());

            withdrawalConfigurations.emitWithrawalRequestEvent(_self.userWithdrawalAccount, msg.sender);
    }

    /*
        @dev user perform withdraw. 

        @param _self                Wallet storage
        @param _token               The ERC20 token the owner withdraws from 
        
    */
    function performUserWithdraw(Wallet storage _self, IERC20Token _token)
        public
        userWithdrawalAccountOnly(_self)
        {
            require(_self.withdrawAllowedAt != 0 &&
                    _self.withdrawAllowedAt <= now );

            uint userBalance = _token.balanceOf(this);
            _token.transfer(_self.userWithdrawalAccount, userBalance);
            emit PerformUserWithdraw(_token, _self.userWithdrawalAccount, userBalance);   
        }

}

contract SmartWallet {

    /*
     *  Members
     */
    using SmartWalletLib for SmartWalletLib.Wallet;
    SmartWalletLib.Wallet public wallet;
       
   // Wallet public wallet;
    /*
     *  Events
     */
    event TransferToBackupAccount(address _token, address _backupAccount, uint _amount);
    event TransferToUserWithdrawalAccount(address _token, address _userWithdrawalAccount, uint _amount, address _feesToken, address _feesAccount, uint _fee);
    event SetUserWithdrawalAccount(address _userWithdrawalAccount);
    event PerformUserWithdraw(address _token, address _userWithdrawalAccount, uint _amount);
     
    /*
        @dev constructor

        @param _backupAccount       A default operator&#39;s account to send funds to, in cases where the user account is
                                    unavailable or lost
        @param _operator            The contract operator address
        @param _feesAccount         The account to transfer fees to 

    */
    constructor (address _operator, address _feesAccount) public {
        wallet.initWallet(_operator, _feesAccount);
    }

    /*
        @dev Setting the account of the user to send funds to. 
        
        @param _userWithdrawalAccount       The user account to withdraw funds to
        
    */
    function setUserWithdrawalAccount(address _userWithdrawalAccount) public {
        wallet.setUserWithdrawalAccount(_userWithdrawalAccount);
    }

    /*
        @dev Withdraw funds to the user account. 


        @param _token               The ERC20 token the owner withdraws from 
        @param _amount              Amount to transfer    
    */
    function transferToUserWithdrawalAccount(IERC20Token _token, uint _amount, IERC20Token _feesToken, uint _fee) public {
        wallet.transferToUserWithdrawalAccount(_token, _amount, _feesToken, _fee);
    }

    /*
        @dev Allows the user to request a withdraw of his/her placements
        
        @param _token               The ERC20 token the user wishes to withdraw from 
    */
    function requestWithdraw() public {
        wallet.requestWithdraw();
    }

    /*
        @dev Allows the user to perform the requestWithdraw operation
        
        @param _token               The ERC20 token the user withdraws from 
    */
    function performUserWithdraw(IERC20Token _token) public {
        wallet.performUserWithdraw(_token);
    }
}