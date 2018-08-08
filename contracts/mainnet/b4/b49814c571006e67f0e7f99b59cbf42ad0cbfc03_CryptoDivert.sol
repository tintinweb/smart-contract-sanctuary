/**
 * @title CryptoDivert DAPP
 * @dev Implementation of the CryptoDivert Smart Contract.
 * @version 2018.04.05 
 * @copyright All rights reserved (c) 2018 Cryptology ltd, Hong Kong.
 * @author Cryptology ltd, Hong Kong.
 * @disclaimer CryptoDivert DAPP provided by Cryptology ltd, Hong Kong is for illustrative purposes only. 
 * 
 * The interface for this contract is running on https://CryptoDivert.io 
 * 
 * You can also use the contract in https://www.myetherwallet.com/#contracts. 
 * With ABI / JSON Interface:
 * [{"constant":true,"inputs":[],"name":"showPendingAdmin","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_password","type":"string"},{"name":"_originAddress","type":"address"}],"name":"Retrieve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"ping","outputs":[{"name":"","type":"string"},{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"whoIsAdmin","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newAdmin","type":"address"}],"name":"setAdmin","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_originAddressHash","type":"bytes20"},{"name":"_releaseTime","type":"uint256"},{"name":"_privacyCommission","type":"uint16"}],"name":"SafeGuard","outputs":[{"name":"","type":"bool"}],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[{"name":"_originAddressHash","type":"bytes20"}],"name":"AuditSafeGuard","outputs":[{"name":"_safeGuarded","type":"uint256"},{"name":"_timelock","type":"uint256"},{"name":"_privacypercentage","type":"uint16"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"AuditBalances","outputs":[{"name":"","type":"uint256"},{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"confirmAdmin","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"RetrieveCommissions","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":false,"name":"pendingAdmin","type":"address"},{"indexed":false,"name":"currentAdmin","type":"address"}],"name":"ContractAdminTransferPending","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"newAdmin","type":"address"},{"indexed":false,"name":"previousAdmin","type":"address"}],"name":"NewContractAdmin","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"value","type":"uint256"}],"name":"CommissionsWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"hash","type":"bytes20"},{"indexed":false,"name":"value","type":"uint256"},{"indexed":false,"name":"comissions","type":"uint256"}],"name":"SafeGuardSuccess","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"value","type":"uint256"}],"name":"RetrieveSuccess","type":"event"}]
 * 
 * ABOUT
 * This Distributed Application (DAPP) provides private (pseudo-anonymous) transactions on the ETH blockchain.
 * A forensic expert will be able to trace these transaction with some time and effort. If you don&#39;t do
 * anything illegal where time and effort will be spend to trace you down this should be providing you enough privacy. 
 * You can create public and private transfers (public: anybody with the password can retrieve, private: only a specific address can retrieve).
 * For private transfers there will be no direct link between safeguarding and retrieving the funds, only an indirect link
 * where a forensic investigator would have to trial and error hashing all retrieved password/address combinations 
 * until he stumbles upon the one you used to safeguard the ETH. The more usage this DAPP gets, the more private it becomes.
 *
 * You can check our FAQ at https://cryptodivert.io/faq for details.
 * 
 * This software is supplied "AS IS" without any warranties and support. 
 * Cryptology ltd assumes no responsibility or liability for the use of the software, 
 * conveys no license or title under any patent, copyright, or mask work right to the product. 
 * Cryptology ltd make no representation or warranty that such application will be suitable for 
 * the specified use without further testing or modification.
 * 
 * To the maximum extent permitted by applicable law, in no event shall Cryptology ltd be liable for 
 * any direct, indirect, punitive, incidental, special, consequential damages or any damages 
 * whatsoever including, without limitation, damages for loss of use, data or profits, arising 
 * out of or in any way connected with the use or performance of the CryptoDivert DAPP, with the delay 
 * or inability to use the CryptoDivert DAPP or related services, the provision of or failure to 
 * provide services, or for any information obtained through the CryptoDivert DAPP, or otherwise arising out 
 * of the use of the CryptoDivert DAPP, whether based on contract, tort, negligence, strict liability 
 * or otherwise, even if Cryptology ltd has been advised of the possibility of damages. 
 * Because some states/jurisdictions do not allow the exclusion or limitation of liability for 
 * consequential or incidental damages, the above limitation may not apply to you. 
 * If you are dissatisfied with any portion of the CryptoDivert DAPP, or with any of these terms of 
 * use, your sole and exclusive remedy is to discontinue using the CryptoDivert DAPP.
 * 
 * DO NOT USE THIS DAPP IN A WAY THAT VIOLATES ANY LAW, WOULD CREATE LIABILITY OR PROMOTES
 * ILLEGAL ACTIVITIES. 
 */
 
pragma solidity ^0.4.21;

contract CryptoDivert {
    using SafeMath for uint256; // We don&#39;t like overflow errors.
    
    // ETH address of the admin.
    // Some methods from this contract can only be executed by the admin address.
    address private admin;
    
    // Used to confirm a new Admin address. The current admin sets this variable 
    // when he wants to transfer the contract. The change will only be implemented 
    // once the new admin ETH address confirms the address is correct.
    address private pendingAdmin; 
    
    // 0x ETH address, we check input against this address.
    address private constant NO_ADDRESS = address(0);
    
    // Store the originating addresses for every SafeGuard. These will be used to 
    // verify the bytes20 hash when a safeguard is retrieved.
    mapping (bytes20 => address) private senders;
    
    // Allow a SafeGuard to be locked until a certain time (e.g. can`t be retrieved before).
    mapping (bytes20 => uint256) private timers;
    
    // Allow a maximum deviation of the amount by x% where x/100 is x * 1%
    mapping (bytes20 => uint16) private privacyDeviation;
    
    // Store the value of every SafeGuard.
    mapping (bytes20 => uint256) private balances;
    
    // Keep balance administrations. 
    uint256 private userBalance; // The total value of all outstanding safeguards combined.
    
    // Create additional privacy (only for receiver hashed transfers)
    uint256 private privacyFund;
    
    /// EVENTS ///
    event ContractAdminTransferPending(address pendingAdmin, address currentAdmin);
    event NewContractAdmin(address newAdmin, address previousAdmin);
    event SafeGuardSuccess(bytes20 hash, uint256 value, uint256 comissions);
    event RetrieveSuccess(uint256 value);
    
    
    /// MODIFIERS ///
    /**
     * @dev Only allow a method to be executed if &#39;_who&#39; is not the 0x address
     */
    modifier isAddress(address _who) {
        require(_who != NO_ADDRESS);
        _;
    }
    
    /**
     * @dev Only allow a method the be executed if the input hasn&#39;t been messed with.
     */
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size +4); // +4 because the 4 bytes of the method.
        _;
    }
    
    /**
     * @dev Only allow a method to be executed if &#39;msg.sender&#39; is the admin.
     */
    modifier OnlyByAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    /**
     * @dev Only allow a method to be executed if &#39;_who&#39; is not the admin.
     */
    modifier isNotAdmin(address _who) {
        require(_who != admin);
        _;
    }

    /// PUBLIC METHODS ///    
    function CryptoDivert() public {
        // We need to define the initial administrator for this DAPP.
        // This should be transferred to the permanent administrator after the contract
        // has been created on the blockchain.
        admin = msg.sender;
    }
    
    /**
     * @dev Process users sending ETH to this contract.
     * Don&#39;t send ETH directly to this contract, use the SafeGuard method to 
     * safeguard your ETHs; then again we don&#39;t mind if you like to 
     * buy us a beer (or a Lambo). In that case thanks for the ETH! 
     * We&#39;ll assume you actually intended to tip us.
     */
    function() public payable {
    }
    
    /// EXTERNAL VIEW METHODS ///
    /**
     * @dev Test for web3js interface to see if contract is correctly initialized.
     */
    function ping() external view returns(string, uint256) {
        return ("CryptoDivert version 2018.04.05", now);
    }
    
    
    /**
     * @dev Shows who is the pending admin for this contract
     * @return &#39;pendingAdmin&#39;
     */
    function showPendingAdmin() external view 
    OnlyByAdmin()
    returns(address) 
    {
        require(pendingAdmin != NO_ADDRESS);
        return pendingAdmin;
    }
    
    /**
     * @dev Shows who is the admin for this contract
     * @return &#39;admin&#39;
     */
    function whoIsAdmin() external view 
    returns(address) 
    {
        return admin;
    }
    
    /**
     * @dev Check if the internal administration is correct. The safeguarded user balances added to the 
     * un-retrieved admin commission should be the same as the ETH balance of this contract.
     * 
     * @return uint256 The total current safeguarded balance of all users &#39;userBalance&#39; + &#39;privacyfund&#39;.
     * @return uint256 The outstanding admin commissions &#39;commissions&#39;.
     */
    function AuditBalances() external view returns(uint256, uint256) {
        assert(address(this).balance >= userBalance);
        uint256 pendingBalance = userBalance.add(privacyFund);
        uint256 commissions = address(this).balance.sub(pendingBalance);
        
        return(pendingBalance, commissions);
    }
    
    /**
     * @dev Check the remaining balance for a safeguarded transaction
     *
     * @param _originAddressHash The RIPEMD160 Hash (bytes20) of a password and the originating ETH address.
     * @return uint256 The remaining value in Wei for this safeguard.
     */
    function AuditSafeGuard(bytes20 _originAddressHash) external view 
    returns(uint256 _safeGuarded, uint256 _timelock, uint16 _privacypercentage)
    {
        // Only by the address that uploaded the safeguard to make it harder for prying eyes to track.
        require(msg.sender == senders[_originAddressHash] || msg.sender == admin);
         
        _safeGuarded = balances[_originAddressHash];
        _timelock = timers[_originAddressHash];
        _privacypercentage = privacyDeviation[_originAddressHash];
        
        return (_safeGuarded, _timelock, _privacypercentage);
    }
    
    
    /// EXTERNAL METHODS ///
    /**
     * @dev Safeguard a value in Wei. You can retreive this after &#39;_releaseTime&#39; via any ETH address 
     * by callling the Retreive method with your password and the originating ETH address.
     * 
     * To prevent the password from being visible in the blockchain (everything added is visible in the blockchain!)
     * and allow more users to set the same password, you need to create a RIPEMD160 Hash from your password
     * and your originating (or intended receiver) ETH address: e.g. if you choose password: &#39;secret&#39; and transfer balance 
     * from (or to) ETH address (ALL LOWERCASE!) &#39;0x14723a09acff6d2a60dcdf7aa4aff308fddc160c&#39; you should RIPEMD160 Hash:
     * &#39;secret0x14723a09acff6d2a60dcdf7aa4aff308fddc160c&#39;.
     * http://www.md5calc.com/ RIPEMD160 gives us the 20 bytes Hash: &#39;602bc74a8e09f80c2d5bbc4374b8f400f33f2683&#39;.
     * If you manually transfer value to this contract make sure to enter the hash as a bytes20 &#39;0x602bc74a8e09f80c2d5bbc4374b8f400f33f2683&#39;.
     * Before you transfer any value to SafeGuard, test the example above and make sure you get the same hash, 
     * then test a transfer (and Retreive!) with a small amount (minimal 1 finney) before SafeGuarding a larger amount. 
     * 
     * IF YOU MAKE AN ERROR WITH YOUR HASH, OR FORGET YOUR PASSWORD, YOUR FUNDS WILL BE SAFEGUARDED FOREVER.
     * 
     * @param _originAddressHash The RIPEMD160 Hash (bytes20) of a password and the msg.sender or intended receiver ETH address.
     * @param _releaseTime The UNIX time (uint256) until when this balance is locked up.
     * @param _privacyCommission The maximum deviation (up or down) that you are willing to use to make tracking on the amount harder.
     * @return true Usefull if this method is called from a contract.
     */
    function SafeGuard(bytes20 _originAddressHash, uint256 _releaseTime, uint16 _privacyCommission) external payable
    onlyPayloadSize(3*32)
    returns(bool)
    {
        // We can only SafeGuard anything if there is value transferred.
        // Minimal value is 1 finney, to prevent SPAM and any errors with the commissions calculations.
        require(msg.value >= 1 finney); 
        
        // Prevent Re-usage of a compromised password by this address; Check that we have not used this before. 
        // In case we have used this password, but haven&#39;t retrieved the amount, the password is still 
        // uncompromised and we can add this amount to the existing amount.
        // A password/ETH combination that was used before will be known to the blockchain (clear text) 
        // after the Retrieve method has been called and can&#39;t be used again to prevent others retrieving you funds.
        require(senders[_originAddressHash] == NO_ADDRESS || balances[_originAddressHash] > 0);
       
        // We don&#39;t know your password (Only you do!) so we can&#39;t possible check wether or not 
        // you created the correct hash, we have to assume you did. Only store the first sender of this hash
        // to prevent someone uploading a small amount with this hash to gain access to the AuditSafeGuard method 
        // or reset the timer.
        if(senders[_originAddressHash] == NO_ADDRESS) {
            
            senders[_originAddressHash] = msg.sender;
            
            // If you set a timer we check if it&#39;s in the future and add it to this SafeGuard.
            if (_releaseTime > now) {
                timers[_originAddressHash] = _releaseTime;
            } else {
                timers[_originAddressHash] = now;
            }
            
            // if we have set a privacy deviation store it, max 100% = 10000.
            if (_privacyCommission > 0 && _privacyCommission <= 10000) {
                privacyDeviation[_originAddressHash] = _privacyCommission;
            }
        }    
        
        // To pay for our servers (and maybe a beer or two) we charge a 0.8% fee (that&#39;s 80cents per 100$).
        uint256 _commission = msg.value.div(125); //100/125 = 0.8
        uint256 _balanceAfterCommission = msg.value.sub(_commission);
        balances[_originAddressHash] = balances[_originAddressHash].add(_balanceAfterCommission);
        
        // Keep score of total user balance 
        userBalance = userBalance.add(_balanceAfterCommission);
        
        // Double check that our administration is correct.
        // The administration can only be incorrect if someone found a loophole in Solidity or in our programming.
        // The assert will effectively revert the transaction in case someone is cheating.
        assert(address(this).balance >= userBalance); 
        
        // Let the user know what a great success.
        emit SafeGuardSuccess(_originAddressHash, _balanceAfterCommission, _commission);
        
        return true;
    } 
    
    /**
     * @dev Retrieve a safeguarded value to the ETH address that calls this method.
     * 
     * The safeguarded value can be retrieved by any ETH address, including the originating ETH address and contracts.
     * All you need is the (clear text) password and the originating ETH address that was used to transfer the 
     * value to this contract. This method will recreate the RIPEMD160 Hash that was 
     * given to the SafeGuard method (this will only succeed when both password and address are correct).
     * The value can only be retrieved after the release timer for this SafeGuard (if any) has expired.
     * 
     * This Retrieve method can be traced in the blockchain via the input field. 
     * We can create additional anonimity by hashing the receivers address instead of the originating address
     * in the SafeGuard method. By doing this we render searching for the originating address 
     * in the input field useless. To make the tracement harder, we will charge an addition random 
     * commission between 0 and 5% so the outgoing value is randomized. This will still not create 
     * 100% anonimity because it is possible to hash every password and receiver address combination and compare it
     * to the hash that was originally given when safeguarding the transaction. 
     * 
     * @param _password The password that was originally hashed for this safeguarded value.
     * @param _originAddress The address where this safeguarded value was received from.
     * @return true Usefull if this method is called from a contract.
     */ 
    function Retrieve(string _password, address _originAddress) external 
    isAddress(_originAddress) 
    onlyPayloadSize(2*32)
    returns(bool)
    {
        
        // Re-create the _originAddressHash that was given when transferring to this contract.
        // Either the sender&#39;s address was hashed (and allows to retrieve from any address) or 
        // the receiver&#39;s address was hashed (more private, but only allows to retrieve from that address).
        bytes20 _addressHash = _getOriginAddressHash(_originAddress, _password); 
        bytes20 _senderHash = _getOriginAddressHash(msg.sender, _password); 
        bytes20 _transactionHash;
        uint256 _randomPercentage; // used to make a receiver hashed transaction more private.
        uint256 _month = 30 * 24 * 60 * 60;
        
        // Check if the given &#39;_originAddress&#39; is the same as the address that transferred to this contract.
        // We do this to prevent people simply giving any hash.
        if (_originAddress == senders[_addressHash]) { // Public Transaction, hashed with originating address.
            
            // Anybody with the password and the sender&#39;s address
            _transactionHash = _addressHash;
            
        } 
        else if (msg.sender == senders[_addressHash] && timers[_addressHash].add(_month) < now ) { // Private transaction, retrieve by sender after a month delay. 
            
            // Allow a sender to retrieve his transfer, only a month after the timelock expired 
            _transactionHash = _addressHash;
            
        }
        else { // Private transaction, hashed with receivers address
            
            // Allow a pre-defined receiver to retrieve.
            _transactionHash = _senderHash;
        }
        
        // Check if the _transactionHash exists and this balance hasn&#39;t been received already.
        // We would normally do this with a require(), but to keep it more private we need the 
        // method to be executed also if it will not result.
        if (balances[_transactionHash] == 0) {
            emit RetrieveSuccess(0);
            return false;    
        }
        
        // Check if this SafeGuard has a timelock and if it already has expired.
        // In case the transaction was sent to a pre-defined address, the sender can retrieve the transaction 1 month after it expired.
        // We would normally do this with a require(), but to keep it more private we need the 
        // method to be executed also if it will not result.
        if (timers[_transactionHash] > now ) {
            emit RetrieveSuccess(0);
            return false;
        }
        
        // Prepare to transfer the balance out.
        uint256 _balance = balances[_transactionHash];
        balances[_transactionHash] = 0;
        
        // Check if the sender allowed for a deviation (up or down) of the value to make tracking harder.
        // To do this we need to randomize the balance a little so it
        // become less traceable: To make the tracement harder, we will calculate an 
        // additional random commission between 0 and the allowed deviation which can be added to or substracted from 
        // this transfer&#39;s balance so the outgoing value is randomized.
        if (privacyDeviation[_transactionHash] > 0) {
             _randomPercentage = _randomize(now, privacyDeviation[_transactionHash]);
        }
        
        if(_randomPercentage > 0) {
            // Calculate the privacy commissions amount in wei.
            uint256 _privacyCommission = _balance.div(10000).mul(_randomPercentage);
            
            // Check integrity of privacyFund
            if (userBalance.add(privacyFund) > address(this).balance) {
                privacyFund = 0;
            }
            
            // Check if we have enough availability in the privacy fund to add to this Retrieve
            if (_privacyCommission <= privacyFund) {
                // we have enough funds to add
                 privacyFund = privacyFund.sub(_privacyCommission);
                 userBalance = userBalance.add(_privacyCommission);
                _balance = _balance.add(_privacyCommission);
               
            } else {
                // the privacy fund is not filled enough, you will contribute to it.
                _balance = _balance.sub(_privacyCommission);
                userBalance = userBalance.sub(_privacyCommission);
                privacyFund = privacyFund.add(_privacyCommission);
            }
        }
        
        // Keep score of total user balance 
        userBalance = userBalance.sub(_balance);
        
        // Transfer the value.
        msg.sender.transfer(_balance);
        
        // Double check that our admin is correct. If not then revert this transaction.
        assert(address(this).balance >= userBalance);
        
        emit RetrieveSuccess(_balance);
        
        return true;
    }
    
    /**
     * @dev Retrieve commissions to the Admin address. 
     */
    function RetrieveCommissions() external OnlyByAdmin() {
        // The fees are the remainder of the contract balance after the userBalance and privacyFund
        // reservations have been substracted. 
        uint256 pendingBalance = userBalance.add(privacyFund);
        uint256 commissions = address(this).balance.sub(pendingBalance);
        
        // Transfer the commissions.
        msg.sender.transfer(commissions);
        
        // Double check that our admin is correct.
        assert(address(this).balance >= userBalance);
    } 
    
    /**
     * @dev Approve a new admin for this contract. The new admin will have to 
     * confirm that he is the admin. 
     * @param _newAdmin the new owner of the contract.
     */
    function setAdmin(address _newAdmin) external 
    OnlyByAdmin() 
    isAddress(_newAdmin)
    isNotAdmin(_newAdmin)
    onlyPayloadSize(32)
    {
        pendingAdmin = _newAdmin;
        emit ContractAdminTransferPending(pendingAdmin, admin);
    }
    
    /**
     * @dev Let the pending admin confirm his address and become the new admin.
     */ 
    function confirmAdmin() external
    {
        require(msg.sender==pendingAdmin);
        address _previousAdmin = admin;
        admin = pendingAdmin;
        pendingAdmin = NO_ADDRESS;
        
        emit NewContractAdmin(admin, _previousAdmin);
    }
    
    
    /// PRIVATE METHODS ///
    /**
     * @dev Create a (semi) random number.
     * This is not truely random, as that isn&#39;t possible in the blockchain, but 
     * random enough for our purpose.
     * 
     * @param _seed Randomizing seed.
     * @param _max Max value.
     */
    function _randomize(uint256 _seed, uint256 _max) private view returns(uint256 _return) {
        _return = uint256(keccak256(_seed, block.blockhash(block.number -1), block.difficulty, block.coinbase));
        return _return % _max;
    }
    
    function _getOriginAddressHash(address _address, string _password) private pure returns(bytes20) {
        string memory _addressString = toAsciiString(_address);
        return ripemd160(_password,"0x",_addressString);
    }
    
    function toAsciiString(address x) private pure returns (string) {
    bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(byte b) private pure returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}