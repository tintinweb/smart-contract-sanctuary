pragma solidity ^0.4.18;

/*
    ERC20 Standard Token interface
*/
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

///@title - a contract that represents a smart wallet, created by Stox, for every new Stox user
library SmartWalletLib {

    /*
     *  Structs
     */
    struct Wallet {
        address operatorAccount;
        address backupAccount;
        address userWithdrawalAccount;
        address feesAccount;
    }

    /*
     *  Members
     */
    string constant VERSION = "0.1";
   

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

    /*
     *  Events
     */
    event TransferToBackupAccount(address _token, address _backupAccount, uint _amount);
    event TransferToUserWithdrawalAccount(address _token, address _userWithdrawalAccount, uint _amount, address _feesToken, address _feesAccount, uint _fee);
    event SetUserWithdrawalAccount(address _userWithdrawalAccount);

    /*
        @dev Initialize the wallet with the operator and backupAccount address
        
        @param _self                        Wallet storage
        @param _backupAccount               Operator account to release funds in case the user lost his withdrawal account
        @param _operator                    The operator account
        @param _feesAccount                 The account to transfer fees to
    */
    function initWallet(Wallet storage _self, address _backupAccount, address _operator, address _feesAccount) 
            public
            validAddress(_backupAccount)
            validAddress(_operator)
            validAddress(_feesAccount)
            {
        
                _self.operatorAccount = _operator;
                _self.backupAccount = _backupAccount;
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
                SetUserWithdrawalAccount(_userWithdrawalAccount);
    }

    /*
        @dev Withdraw funds to a backup account. 


        @param _self                Wallet storage
        @param _token               The ERC20 token the owner withdraws from 
        @param _amount              Amount to transfer    
    */
    function transferToBackupAccount(Wallet storage _self, IERC20Token _token, uint _amount) 
            public 
            operatorOnly(_self.operatorAccount)
            {
        
                _token.transfer(_self.backupAccount, _amount);
                TransferToBackupAccount(_token, _self.backupAccount, _amount); 
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
                TransferToUserWithdrawalAccount(_token, _self.userWithdrawalAccount, _amount,  _feesToken, _self.feesAccount, _fee);   
        
    }
}

///@title - a contract that represents a smart wallet, created by Stox, for every new Stox user
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
     
    /*
        @dev constructor

        @param _backupAccount       A default operator&#39;s account to send funds to, in cases where the user account is
                                    unavailable or lost
        @param _operator            The contract operator address
        @param _feesAccount         The account to transfer fees to 

    */
    function SmartWallet(address _backupAccount, address _operator, address _feesAccount) public {
        wallet.initWallet(_backupAccount, _operator, _feesAccount);
    }

    /*
        @dev Setting the account of the user to send funds to. 
        
        @param _userWithdrawalAccount       The user account to withdraw funds to
        
    */
    function setUserWithdrawalAccount(address _userWithdrawalAccount) public {
        wallet.setUserWithdrawalAccount(_userWithdrawalAccount);
    }

    /*
        @dev Withdraw funds to a backup account. 


        @param _token               The ERC20 token the owner withdraws from 
        @param _amount              Amount to transfer    
    */
    function transferToBackupAccount(IERC20Token _token, uint _amount) public {
        wallet.transferToBackupAccount(_token, _amount);
    }

    /*
        @dev Withdraw funds to the user account. 


        @param _token               The ERC20 token the owner withdraws from 
        @param _amount              Amount to transfer    
    */
    function transferToUserWithdrawalAccount(IERC20Token _token, uint _amount, IERC20Token _feesToken, uint _fee) public {
        wallet.transferToUserWithdrawalAccount(_token, _amount, _feesToken, _fee);
    }
}