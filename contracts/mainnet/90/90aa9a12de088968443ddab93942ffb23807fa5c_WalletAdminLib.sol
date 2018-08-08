pragma solidity 0.4.13;

/**
 * @title Wallet Admin Library
 * @author Majoolr.io
 *
 * version 1.0.0
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The Wallet Library family is inspired by the multisig wallets built by Consensys
 * at https://github.com/ConsenSys/MultiSigWallet and Parity at
 * https://github.com/paritytech/contracts/blob/master/Wallet.sol with added
 * functionality. Majoolr works on open source projects in the Ethereum
 * community with the purpose of testing, documenting, and deploying reusable
 * code onto the blockchain to improve security and usability of smart contracts.
 * Majoolr also strives to educate non-profits, schools, and other community
 * members about the application of blockchain technology. For further
 * information: majoolr.io, consensys.net, paritytech.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library WalletAdminLib {
  using WalletMainLib for WalletMainLib.WalletData;

  /*Events*/
  event LogTransactionConfirmed(bytes32 txid, address sender, uint confirmsNeeded);
  event LogOwnerAdded(address newOwner);
  event LogOwnerRemoved(address ownerRemoved);
  event LogOwnerChanged(address from, address to);
  event LogRequirementChange(uint newRequired);
  event LogThresholdChange(address token, uint newThreshold);
  event LogErrMsg(string msg);

  /*Checks*/

  /// @dev Validates arguments for changeOwner function
  /// @param _from Index of current owner removing
  /// @param _to Index of new potential owner, should be 0
  /// @return Returns true if check passes, false otherwise
  function checkChangeOwnerArgs(uint _from, uint _to) constant returns (bool) {
    if(_from == 0){
      LogErrMsg("Change from address is not an owner");
      return false;
    }
    if(_to != 0){
      LogErrMsg("Change to address is an owner");
      return false;
    }
    return true;
  }

  /// @dev Validates arguments for addOwner function
  /// @param _index Index of new owner, should be 0
  /// @param _length Current length of owner array
  /// @return Returns true if check passes, false otherwise
  function checkNewOwnerArgs(uint _index, uint _length, uint _max)
           constant returns (bool)
  {
    if(_index != 0){
      LogErrMsg("New owner already owner");
      return false;
    }
    if((_length + 1) > _max){
      LogErrMsg("Too many owners");
      return false;
    }
    return true;
  }

  /// @dev Validates arguments for removeOwner function
  /// @param _index Index of owner removing
  /// @param _length Current number of owners
  /// @param _min Minimum owners currently required to meet sig requirements
  /// @return Returs true if check passes, false otherwise
  function checkRemoveOwnerArgs(uint _index, uint _length, uint _min)
           constant returns (bool)
  {
    if(_index == 0){
      LogErrMsg("Owner removing not an owner");
      return false;
    }
    if(_length - 1 < _min){
      LogErrMsg("Must reduce requiredAdmin first");
      return false;
    }
    return true;
  }

  /// @dev Validates arguments for changing any of the sig requirement parameters
  /// @param _newRequired The new sig requirement
  /// @param _length Current number of owners
  /// @return Returns true if checks pass, false otherwise
  function checkRequiredChange(uint _newRequired, uint _length)
           constant returns (bool)
  {
    if(_newRequired == 0){
      LogErrMsg("Cant reduce to 0");
      return false;
    }
    if(_length - 1 < _newRequired){
      LogErrMsg("Making requirement too high");
      return false;
    }
    return true;
  }

  /*Utility Functions*/

  /// @dev Used later to calculate the number of confirmations needed for tx
  /// @param _required Number of sigs required
  /// @param _count Current number of sigs
  function calcConfirmsNeeded(uint _required, uint _count) constant returns (uint){
    return _required - _count;
  }

  /*Administrative Functions*/

  /// @dev Changes owner address to a new address
  /// @param self Wallet in contract storage
  /// @param _from Current owner address
  /// @param _to New address
  /// @param _confirm True if confirming, false if revoking confirmation
  /// @param _data Message data passed from wallet contract
  /// @return bool Returns true if successful, false otherwise
  /// @return bytes32 Returns the tx ID, can be used for confirm/revoke functions
  function changeOwner(WalletMainLib.WalletData storage self,
                       address _from,
                       address _to,
                       bool _confirm,
                       bytes _data)
                       returns (bool,bytes32)
  {
    bytes32 _id = sha3("changeOwner",_from,_to);
    uint _number = self.transactionInfo[_id].length;
    bool allGood;

    if(msg.sender != address(this)){
      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_number == 0 || self.transactionInfo[_id][_number - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkChangeOwnerArgs(self.ownerIndex[_from], self.ownerIndex[_to]);
          if(!allGood)
            return (false,0);

          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_number].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_number].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _number--;
          allGood = self.checkNotConfirmed(_id, _number);
          if(!allGood)
            return (false,_id);
        }
      }
      self.transactionInfo[_id][_number].confirmedOwners.push(uint256(msg.sender));
      self.transactionInfo[_id][_number].confirmCount++;
    } else {
      _number--;
    }

    if(self.transactionInfo[_id][_number].confirmCount ==
       self.transactionInfo[_id][_number].confirmRequired)
    {
      self.transactionInfo[_id][_number].success = true;
      uint i = self.ownerIndex[_from];
      self.ownerIndex[_from] = 0;
      self.owners[i] = _to;
      self.ownerIndex[_to] = i;
      delete self.transactionInfo[_id][_number].data;
      LogOwnerChanged(_from, _to);
    } else {
      if(self.transactionInfo[_id][_number].data.length == 0)
        self.transactionInfo[_id][_number].data = _data;

      uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                               self.transactionInfo[_id][_number].confirmCount);

      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }

    return (true,_id);
	}

  /// @dev Adds owner to wallet
  /// @param self Wallet in contract storage
  /// @param _newOwner Address for new owner
  /// @param _confirm True if confirming, false if revoking confirmation
  /// @param _data Message data passed from wallet contract
  /// @return bool Returns true if successful, false otherwise
  /// @return bytes32 Returns the tx ID, can be used for confirm/revoke functions
  function addOwner(WalletMainLib.WalletData storage self,
                    address _newOwner,
                    bool _confirm,
                    bytes _data)
                    returns (bool,bytes32)
  {
    bytes32 _id = sha3("addOwner",_newOwner);
    uint _number = self.transactionInfo[_id].length;
    bool allGood;

    if(msg.sender != address(this)){
      require(_newOwner != 0);

      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_number == 0 || self.transactionInfo[_id][_number - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkNewOwnerArgs(self.ownerIndex[_newOwner],
                                      self.owners.length,
                                      self.maxOwners);
          if(!allGood)
            return (false,0);

          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_number].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_number].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _number--;
          allGood = self.checkNotConfirmed(_id, _number);
          if(!allGood)
            return (false,_id);
        }
      }

      self.transactionInfo[_id][_number].confirmedOwners.push(uint(msg.sender));
      self.transactionInfo[_id][_number].confirmCount++;
    } else {
      _number--;
    }

    if(self.transactionInfo[_id][_number].confirmCount ==
       self.transactionInfo[_id][_number].confirmRequired)
    {
      self.transactionInfo[_id][_number].success = true;
      self.owners.push(_newOwner);
      self.ownerIndex[_newOwner] = self.owners.length - 1;
      delete self.transactionInfo[_id][_number].data;
      LogOwnerAdded(_newOwner);
    } else {
      if(self.transactionInfo[_id][_number].data.length == 0)
        self.transactionInfo[_id][_number].data = _data;

      uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                               self.transactionInfo[_id][_number].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }

    return (true,_id);
	}

  /// @dev Removes owner from wallet
  /// @param self Wallet in contract storage
  /// @param _ownerRemoving Address of owner to be removed
  /// @param _confirm True if confirming, false if revoking confirmation
  /// @param _data Message data passed from wallet contract
  /// @return bool Returns true if successful, false otherwise
  /// @return bytes32 Returns the tx ID, can be used for confirm/revoke functions
  function removeOwner(WalletMainLib.WalletData storage self,
                       address _ownerRemoving,
                       bool _confirm,
                       bytes _data)
                       returns (bool,bytes32)
  {
    bytes32 _id = sha3("removeOwner",_ownerRemoving);
    uint _number = self.transactionInfo[_id].length;
    bool allGood;

    if(msg.sender != address(this)){
      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_number == 0 || self.transactionInfo[_id][_number - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkRemoveOwnerArgs(self.ownerIndex[_ownerRemoving],
                                         self.owners.length,
                                         self.requiredAdmin);
          if(!allGood)
            return (false,0);

          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_number].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_number].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _number--;
          allGood = self.checkNotConfirmed(_id, _number);
          if(!allGood)
            return (false,_id);
        }
      }

      self.transactionInfo[_id][_number].confirmedOwners.push(uint(msg.sender));
      self.transactionInfo[_id][_number].confirmCount++;
    } else {
      _number--;
    }

    if(self.transactionInfo[_id][_number].confirmCount ==
       self.transactionInfo[_id][_number].confirmRequired)
    {
      self.transactionInfo[_id][_number].success = true;
      self.owners[self.ownerIndex[_ownerRemoving]] = self.owners[self.owners.length - 1];
      self.ownerIndex[self.owners[self.owners.length - 1]] = self.ownerIndex[_ownerRemoving];
      self.ownerIndex[_ownerRemoving] = 0;
      self.owners.length--;
      delete self.transactionInfo[_id][_number].data;
      LogOwnerRemoved(_ownerRemoving);
    } else {
      if(self.transactionInfo[_id][_number].data.length == 0)
        self.transactionInfo[_id][_number].data = _data;

      uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                               self.transactionInfo[_id][_number].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }

    return (true,_id);
	}

  /// @dev Changes required sigs to change wallet parameters
  /// @param self Wallet in contract storage
  /// @param _requiredAdmin The new signature requirement
  /// @param _confirm True if confirming, false if revoking confirmation
  /// @param _data Message data passed from wallet contract
  /// @return bool Returns true if successful, false otherwise
  /// @return bytes32 Returns the tx ID, can be used for confirm/revoke functions
  function changeRequiredAdmin(WalletMainLib.WalletData storage self,
                               uint _requiredAdmin,
                               bool _confirm,
                               bytes _data)
                               returns (bool,bytes32)
  {
    bytes32 _id = sha3("changeRequiredAdmin",_requiredAdmin);
    uint _number = self.transactionInfo[_id].length;

    if(msg.sender != address(this)){
      bool allGood;

      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_number == 0 || self.transactionInfo[_id][_number - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkRequiredChange(_requiredAdmin, self.owners.length);
          if(!allGood)
            return (false,0);

          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_number].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_number].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _number--;
          allGood = self.checkNotConfirmed(_id, _number);
          if(!allGood)
            return (false,_id);
        }
      }

      self.transactionInfo[_id][_number].confirmedOwners.push(uint(msg.sender));
      self.transactionInfo[_id][_number].confirmCount++;
    } else {
      _number--;
    }

    if(self.transactionInfo[_id][_number].confirmCount ==
      self.transactionInfo[_id][_number].confirmRequired)
    {
      self.transactionInfo[_id][_number].success = true;
      self.requiredAdmin = _requiredAdmin;
      delete self.transactionInfo[_id][_number].data;
      LogRequirementChange(_requiredAdmin);
    } else {
      if(self.transactionInfo[_id][_number].data.length == 0)
        self.transactionInfo[_id][_number].data = _data;

      uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                               self.transactionInfo[_id][_number].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }

    return (true,_id);
	}

  /// @dev Changes required sigs for major transactions
  /// @param self Wallet in contract storage
  /// @param _requiredMajor The new signature requirement
  /// @param _confirm True if confirming, false if revoking confirmation
  /// @param _data Message data passed from wallet contract
  /// @return bool Returns true if successful, false otherwise
  /// @return bytes32 Returns the tx ID, can be used for confirm/revoke functions
  function changeRequiredMajor(WalletMainLib.WalletData storage self,
                               uint _requiredMajor,
                               bool _confirm,
                               bytes _data)
                               returns (bool,bytes32)
  {
    bytes32 _id = sha3("changeRequiredMajor",_requiredMajor);
    uint _number = self.transactionInfo[_id].length;

    if(msg.sender != address(this)){
      bool allGood;

      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_number == 0 || self.transactionInfo[_id][_number - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkRequiredChange(_requiredMajor, self.owners.length);
          if(!allGood)
            return (false,0);

          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_number].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_number].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _number--;
          allGood = self.checkNotConfirmed(_id, _number);
          if(!allGood)
            return (false,_id);
        }
      }

      self.transactionInfo[_id][_number].confirmedOwners.push(uint(msg.sender));
      self.transactionInfo[_id][_number].confirmCount++;
    } else {
      _number--;
    }

    if(self.transactionInfo[_id][_number].confirmCount ==
       self.transactionInfo[_id][_number].confirmRequired)
    {
      self.transactionInfo[_id][_number].success = true;
      self.requiredMajor = _requiredMajor;
      delete self.transactionInfo[_id][_number].data;
      LogRequirementChange(_requiredMajor);
    } else {
      if(self.transactionInfo[_id][_number].data.length == 0)
        self.transactionInfo[_id][_number].data = _data;

      uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                               self.transactionInfo[_id][_number].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }

    return (true,_id);
	}

  /// @dev Changes required sigs for minor transactions
  /// @param self Wallet in contract storage
  /// @param _requiredMinor The new signature requirement
  /// @param _confirm True if confirming, false if revoking confirmation
  /// @param _data Message data passed from wallet contract
  /// @return bool Returns true if successful, false otherwise
  /// @return bytes32 Returns the tx ID, can be used for confirm/revoke functions
  function changeRequiredMinor(WalletMainLib.WalletData storage self,
                               uint _requiredMinor,
                               bool _confirm,
                               bytes _data)
                               returns (bool,bytes32)
  {
    bytes32 _id = sha3("changeRequiredMinor",_requiredMinor);
    uint _number = self.transactionInfo[_id].length;

    if(msg.sender != address(this)){
      bool allGood;

      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_number == 0 || self.transactionInfo[_id][_number - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkRequiredChange(_requiredMinor, self.owners.length);
          if(!allGood)
            return (false,0);

          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_number].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_number].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _number--;
          allGood = self.checkNotConfirmed(_id, _number);
          if(!allGood)
            return (false,_id);
        }
      }

      self.transactionInfo[_id][_number].confirmedOwners.push(uint(msg.sender));
      self.transactionInfo[_id][_number].confirmCount++;
    } else {
      _number--;
    }

    if(self.transactionInfo[_id][_number].confirmCount ==
       self.transactionInfo[_id][_number].confirmRequired)
    {
      self.transactionInfo[_id][_number].success = true;
      self.requiredMinor = _requiredMinor;
      delete self.transactionInfo[_id][_number].data;
      LogRequirementChange(_requiredMinor);
    } else {
      if(self.transactionInfo[_id][_number].data.length == 0)
        self.transactionInfo[_id][_number].data = _data;

      uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                               self.transactionInfo[_id][_number].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }

    return (true,_id);
	}

  /// @dev Changes threshold for major transaction day spend per token
  /// @param self Wallet in contract storage
  /// @param _token Address of token, ether is 0
  /// @param _majorThreshold New threshold
  /// @param _confirm True if confirming, false if revoking confirmation
  /// @param _data Message data passed from wallet contract
  /// @return bool Returns true if successful, false otherwise
  /// @return bytes32 Returns the tx ID, can be used for confirm/revoke functions
  function changeMajorThreshold(WalletMainLib.WalletData storage self,
                                address _token,
                                uint _majorThreshold,
                                bool _confirm,
                                bytes _data)
                                returns (bool,bytes32)
  {
    bytes32 _id = sha3("changeMajorThreshold", _token, _majorThreshold);
    uint _number = self.transactionInfo[_id].length;

    if(msg.sender != address(this)){
      bool allGood;

      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_number == 0 || self.transactionInfo[_id][_number - 1].success){
          require(self.ownerIndex[msg.sender] > 0);

          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_number].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_number].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _number--;
          allGood = self.checkNotConfirmed(_id, _number);
          if(!allGood)
            return (false,_id);
        }
      }

      self.transactionInfo[_id][_number].confirmedOwners.push(uint(msg.sender));
      self.transactionInfo[_id][_number].confirmCount++;
    } else {
      _number--;
    }

    if(self.transactionInfo[_id][_number].confirmCount ==
       self.transactionInfo[_id][_number].confirmRequired)
    {
      self.transactionInfo[_id][_number].success = true;
      self.majorThreshold[_token] = _majorThreshold;
      delete self.transactionInfo[_id][_number].data;
      LogThresholdChange(_token, _majorThreshold);
    } else {
      if(self.transactionInfo[_id][_number].data.length == 0)
        self.transactionInfo[_id][_number].data = _data;

      uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                               self.transactionInfo[_id][_number].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }

    return (true,_id);
	}
}

pragma solidity 0.4.13;

/**
 * @title Wallet Main Library
 * @author Majoolr.io
 *
 * version 1.0.0
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The Wallet Library family is inspired by the multisig wallets built by Consensys
 * at https://github.com/ConsenSys/MultiSigWallet and Parity at
 * https://github.com/paritytech/contracts/blob/master/Wallet.sol with added
 * functionality. Majoolr works on open source projects in the Ethereum
 * community with the purpose of testing, documenting, and deploying reusable
 * code onto the blockchain to improve security and usability of smart contracts.
 * Majoolr also strives to educate non-profits, schools, and other community
 * members about the application of blockchain technology. For further
 * information: majoolr.io, consensys.net, paritytech.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library WalletMainLib {
  using Array256Lib for uint256[];
  using BasicMathLib for uint;

  struct WalletData {
    uint maxOwners; //Maximum wallet owners, should be 50
    address[] owners; //Array of all owners
    uint requiredAdmin; //Number of sigs required for administrative changes
    uint requiredMajor; //Number of sigs required for major transactions
    uint requiredMinor; //Number of sigs required for minor transactions

    // The amount of a token spent per day, ether is at address mapping 0,
    // all other tokens defined by address. uint[0] corresponds to the current
    // day,  uint[1] is the spend amount
    mapping (address => uint[2]) currentSpend;
    //The day spend threshold for transactions to be major, ether at 0, all others by address
    mapping (address => uint) majorThreshold;
    //Array of transactions per day, uint is the day timestamp, bytes32 is the transaction id
    mapping (uint => bytes32[]) transactions;
    //Tracks the index of each owner in the owners Array
    mapping (address => uint) ownerIndex;
    //Array of Transaction&#39;s by id, new tx&#39;s with exact inputs as previous tx will add to array
    mapping (bytes32 => Transaction[]) transactionInfo;

  }

  struct Transaction {
    uint day; //Timestamp of the day initialized
    uint value; //Amount of ether being sent
    address tokenAdress; //Address of token transferred
    uint amount; //Amount of tokens transferred
    bytes data; //Temp location for pending transactions, erased after final confirmation
    uint256[] confirmedOwners; //Array of owners confirming transaction
    uint confirmCount; //Tracks the number of confirms
    uint confirmRequired; //Number of sigs required for this transaction
    bool success; //True after final confirmation
  }

  /*Events*/
  event LogRevokeNotice(bytes32 txid, address sender, uint confirmsNeeded);
  event LogTransactionFailed(bytes32 txid, address sender);
  event LogTransactionConfirmed(bytes32 txid, address sender, uint confirmsNeeded);
  event LogTransactionComplete(bytes32 txid, address target, uint value, bytes data);
  event LogContractCreated(address newContract, uint value);
  event LogErrMsg(string msg);

  /// @dev Constructor
  /// @param self The wallet in contract storage
  /// @param _owners Array of initial owners
  /// @param _requiredAdmin Set number of sigs for administrative tasks
  /// @param _requiredMajor Set number of sigs for major tx
  /// @param _requiredMinor Set number of sigs for minor tx
  /// @param _majorThreshold Set major tx threshold amount for ether
  /// @return Will return true when complete
  function init(WalletData storage self,
                address[] _owners,
                uint _requiredAdmin,
                uint _requiredMajor,
                uint _requiredMinor,
                uint _majorThreshold) returns (bool)
  {
    require(self.owners.length == 0);
    require(_owners.length >= _requiredAdmin && _requiredAdmin > 0);
    require(_owners.length >= _requiredMajor && _requiredMajor > 0);
    require(_owners.length >= _requiredMinor && _requiredMinor > 0);
    self.owners.push(0); //Leave index-0 empty for easier owner checks

    for (uint i=0; i<_owners.length; i++) {
      require(_owners[i] != 0);
      self.owners.push(_owners[i]);
      self.ownerIndex[_owners[i]] = i+1;
    }
    self.requiredAdmin = _requiredAdmin;
    self.requiredMajor = _requiredMajor;
    self.requiredMinor = _requiredMinor;
    self.maxOwners = 50; //Limits to 50 owners, should create wallet pools for more owners
    self.majorThreshold[0] = _majorThreshold; //Sets ether threshold at address 0

    return true;
  }

  /*Checks*/

  /// @dev Verifies a confirming owner has not confirmed already
  /// @param self Contract wallet in storage
  /// @param _id ID of the tx being checked
  /// @param _number Index number of this tx
  /// @return Returns true if check passes, false otherwise
  function checkNotConfirmed(WalletData storage self, bytes32 _id, uint _number)
           constant returns (bool)
  {
    require(self.ownerIndex[msg.sender] > 0);
    uint _txLen = self.transactionInfo[_id].length;

    if(_txLen == 0 || _number >= _txLen){
      LogErrMsg("Tx not initiated");
      LogTransactionFailed(_id, msg.sender);
      return false;
    }

    if(self.transactionInfo[_id][_number].success){
      LogErrMsg("Transaction already complete");
      LogTransactionFailed(_id, msg.sender);
      return false;
    }

    //Function from Majoolr.io array utility library
    bool found;
    uint index;
    (found, index) = self.transactionInfo[_id][_number].confirmedOwners.indexOf(uint(msg.sender), false);
    if(found){
      LogErrMsg("Owner already confirmed");
      LogTransactionFailed(_id, msg.sender);
      return false;
    }

    return true;
  }

  /*Utility Functions*/

  /// @dev Used later to calculate the number of confirmations needed for tx
  /// @param _required Number of sigs required
  /// @param _count Current number of sigs
  function calcConfirmsNeeded(uint _required, uint _count) constant returns (uint){
    return _required - _count;
  }

  /// @dev Used to check if tx is moving tokens and parses amount
  /// @param _txData Data for proposed tx
  /// @return bool True if transaction is moving tokens
  /// @return uint Amount of tokens involved, 0 if not spending tx
  function getAmount(bytes _txData) constant returns (bool,uint) {
    bytes32 getSig;
    bytes4 sig;
    bytes4 tSig = 0xa9059cbb; //transfer func signature
    bytes4 aSig = 0x095ea7b3; //approve func signature
    bytes4 tfSig = 0x23b872dd; //transferFrom func signature
    bool transfer;
    bytes32 _amountData;
    uint _amount;

    assembly { getSig := mload(add(_txData,0x20)) }
    sig = bytes4(getSig);
    if(sig ==  tSig || sig == aSig){
      transfer = true;
      assembly { _amountData := mload(add(_txData,0x44)) }
      _amount = uint(_amountData);
    } else if(sig == tfSig){
      transfer = true;
      assembly { _amountData := mload(add(_txData,0x64)) }
      _amount = uint(_amountData);
    }
    return (transfer,_amount);
  }

  /// @dev Retrieves sig requirement for spending tx
  /// @param self Contract wallet in storage
  /// @param _to Target address of transaction
  /// @param _value Amount of ether spend
  /// @param _isTransfer True if transferring other tokens, false otherwise
  /// @param _amount Amount of tokens being transferred, 0 if not a transfer tx
  /// @return uint The required sigs for tx
  function getRequired(WalletData storage self,
                       address _to,
                       uint _value,
                       bool _isTransfer,
                       uint _amount)
                       returns (uint)
  {
    bool err;
    uint res;
    bool major = true;
    //Reset spend if this is first check of the day
    if((now/ 1 days) > self.currentSpend[0][0]){
      self.currentSpend[0][0] = now / 1 days;
      self.currentSpend[0][1] = 0;
    }

    (err, res) = self.currentSpend[0][1].plus(_value);
    if(err){
      LogErrMsg("Overflow eth spend");
      return 0;
    }

    if(res < self.majorThreshold[0])
      major = false;

    if(_to != 0 && _isTransfer){
      if((now / 1 days) > self.currentSpend[_to][0]){
        self.currentSpend[_to][0] = now / 1 days;
        self.currentSpend[_to][1] = 0;
      }

      (err, res) = self.currentSpend[_to][1].plus(_amount);
      if(err){
        LogErrMsg("Overflow token spend");
        return 0;
      }
      if(res >= self.majorThreshold[_to])
        major = true;
    }

    return major ? self.requiredMajor : self.requiredMinor;
  }

  /// @dev Function to create new contract
  /// @param _txData Transaction data
  /// @param _value Amount of eth sending to new contract
  function createContract(bytes _txData, uint _value) {
    address _newContract;
    bool allGood;

    assembly {
      _newContract := create(_value, add(_txData, 0x20), mload(_txData))
      allGood := gt(extcodesize(_newContract),0)
    }
    require(allGood);
    LogContractCreated(_newContract, _value);
  }

  /*Primary Function*/

  /// @dev Create and execute transaction from wallet
  /// @param self Wallet in contract storage
  /// @param _to Address of target
  /// @param _value Amount of ether sending
  /// @param _txData Data for executing transaction
  /// @param _confirm True if confirming, false if revoking confirmation
  /// @param _data Message data passed from wallet contract
  /// @return bool Returns true if successful, false otherwise
  /// @return bytes32 Returns the tx ID, can be used for confirm/revoke functions
  function serveTx(WalletData storage self,
                   address _to,
                   uint _value,
                   bytes _txData,
                   bool _confirm,
                   bytes _data)
                   returns (bool,bytes32)
  {
    bytes32 _id = sha3("serveTx",_to,_value,_txData);
    uint _number = self.transactionInfo[_id].length;
    uint _required = self.requiredMajor;

    //Run checks if not called from generic confirm/revoke function
    if(msg.sender != address(this)){
      bool allGood;
      uint _amount;
      // if the owner is revoking his/her confirmation but doesn&#39;t know the
      // specific transaction id hash
      if(!_confirm) {
        allGood = revokeConfirm(self, _id);
        return (allGood,_id);
      } else { // else confirming the transaction
        //if this is a new transaction id or if a previous identical transaction had already succeeded
        if(_number == 0 || self.transactionInfo[_id][_number - 1].success){
          require(self.ownerIndex[msg.sender] > 0);

          //Reuse allGood due to stack limit
          if(_to != 0)
            (allGood,_amount) = getAmount(_txData);

          _required = getRequired(self, _to, _value, allGood,_amount);
          if(_required == 0)
            return (false, _id);

          // add this transaction to the wallets record and initialize the settings
          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_number].confirmRequired = _required;
          self.transactionInfo[_id][_number].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else { // else the transaction is already pending
          _number--; // set the index to the index of the existing transaction
          //make sure the sender isn&#39;t already confirmed
          allGood = checkNotConfirmed(self, _id, _number);
          if(!allGood)
            return (false,_id);
        }
      }

      // add the senders confirmation to the transaction
      self.transactionInfo[_id][_number].confirmedOwners.push(uint(msg.sender));
      self.transactionInfo[_id][_number].confirmCount++;
    }else {
      // else were calling from generic confirm/revoke function, set the
      // _number index to the index of the existing transaction
      _number--;
    }

    // if there are enough confirmations
    if(self.transactionInfo[_id][_number].confirmCount ==
       self.transactionInfo[_id][_number].confirmRequired)
    {
      // execute the transaction
      self.currentSpend[0][1] += _value;
      self.currentSpend[_to][1] += _amount;
      self.transactionInfo[_id][_number].success = true;

      if(_to == 0){
        //Failure is self contained in method
        createContract(_txData, _value);
      } else {
        require(_to.call.value(_value)(_txData));
      }
      delete self.transactionInfo[_id][_number].data;
      LogTransactionComplete(_id, _to, _value, _data);
    } else {
      if(self.transactionInfo[_id][_number].data.length == 0)
        self.transactionInfo[_id][_number].data = _data;

      uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                               self.transactionInfo[_id][_number].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }

    return (true,_id);
  }

  /*Confirm/Revoke functions using tx ID*/

  /// @dev Confirms a current pending tx, will execute if final confirmation
  /// @param self Wallet in contract storage
  /// @param _id ID of the transaction
  /// @return Returns true if successful, false otherwise
  function confirmTx(WalletData storage self, bytes32 _id) returns (bool){
    require(self.ownerIndex[msg.sender] > 0);
    uint _number = self.transactionInfo[_id].length;
    bool ret;

    if(_number == 0){
      LogErrMsg("Tx not initiated");
      LogTransactionFailed(_id, msg.sender);
      return false;
    }

    _number--;
    bool allGood = checkNotConfirmed(self, _id, _number);
    if(!allGood)
      return false;

    self.transactionInfo[_id][_number].confirmedOwners.push(uint256(msg.sender));
    self.transactionInfo[_id][_number].confirmCount++;

    if(self.transactionInfo[_id][_number].confirmCount ==
       self.transactionInfo[_id][_number].confirmRequired)
    {
      address a = address(this);
      require(a.call(self.transactionInfo[_id][_number].data));
    } else {
      uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                               self.transactionInfo[_id][_number].confirmCount);

      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
      ret = true;
    }

    return ret;
  }

  /// @dev Revokes a prior confirmation from sender, call with tx ID
  /// @param self Wallet in contract storage
  /// @param _id ID of the transaction
  /// @return Returns true if successful, false otherwise
  function revokeConfirm(WalletData storage self, bytes32 _id)
           returns (bool)
  {
    require(self.ownerIndex[msg.sender] > 0);
    uint _number = self.transactionInfo[_id].length;

    if(_number == 0){
      LogErrMsg("Tx not initiated");
      LogTransactionFailed(_id, msg.sender);
      return false;
    }

    _number--;
    if(self.transactionInfo[_id][_number].success){
      LogErrMsg("Transaction already complete");
      LogTransactionFailed(_id, msg.sender);
      return false;
    }

    //Function from Majoolr.io array utility library
    bool found;
    uint index;
    (found, index) = self.transactionInfo[_id][_number].confirmedOwners.indexOf(uint(msg.sender), false);
    if(!found){
      LogErrMsg("Owner has not confirmed tx");
      LogTransactionFailed(_id, msg.sender);
      return false;
    }
    self.transactionInfo[_id][_number].confirmedOwners[index] = 0;
    self.transactionInfo[_id][_number].confirmCount--;

    uint confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_number].confirmRequired,
                                             self.transactionInfo[_id][_number].confirmCount);
    //Transaction removed if all sigs revoked but id remains in wallet transaction list
    if(self.transactionInfo[_id][_number].confirmCount == 0)
      self.transactionInfo[_id].length--;

    LogRevokeNotice(_id, msg.sender, confirmsNeeded);
    return true;
  }
}

pragma solidity ^0.4.13;

/**
 * @title Array256 Library
 * @author Majoolr.io
 *
 * version 1.0.0
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The Array256 Library provides a few utility functions to work with
 * storage uint256[] types in place. Majoolr works on open source projects in
 * the Ethereum community with the purpose of testing, documenting, and deploying
 * reusable code onto the blockchain to improve security and usability of smart
 * contracts. Majoolr also strives to educate non-profits, schools, and other
 * community members about the application of blockchain technology.
 * For further information: majoolr.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library Array256Lib {

  /// @dev Sum vector
  /// @param self Storage array containing uint256 type variables
  /// @return sum The sum of all elements, does not check for overflow
  function sumElements(uint256[] storage self) constant returns(uint256 sum) {
    assembly {
      mstore(0x60,self_slot)

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        sum := add(sload(add(sha3(0x60,0x20),i)),sum)
      }
    }
  }

  /// @dev Returns the max value in an array.
  /// @param self Storage array containing uint256 type variables
  /// @return maxValue The highest value in the array
  function getMax(uint256[] storage self) constant returns(uint256 maxValue) {
    assembly {
      mstore(0x60,self_slot)
      maxValue := sload(sha3(0x60,0x20))

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        switch gt(sload(add(sha3(0x60,0x20),i)), maxValue)
        case 1 {
          maxValue := sload(add(sha3(0x60,0x20),i))
        }
      }
    }
  }

  /// @dev Returns the minimum value in an array.
  /// @param self Storage array containing uint256 type variables
  /// @return minValue The highest value in the array
  function getMin(uint256[] storage self) constant returns(uint256 minValue) {
    assembly {
      mstore(0x60,self_slot)
      minValue := sload(sha3(0x60,0x20))

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        switch gt(sload(add(sha3(0x60,0x20),i)), minValue)
        case 0 {
          minValue := sload(add(sha3(0x60,0x20),i))
        }
      }
    }
  }

  /// @dev Finds the index of a given value in an array
  /// @param self Storage array containing uint256 type variables
  /// @param value The value to search for
  /// @param isSorted True if the array is sorted, false otherwise
  /// @return found True if the value was found, false otherwise
  /// @return index The index of the given value, returns 0 if found is false
  function indexOf(uint256[] storage self, uint256 value, bool isSorted) constant
           returns(bool found, uint256 index) {
    assembly{
      mstore(0x60,self_slot)
      switch isSorted
      case 1 {
        let high := sub(sload(self_slot),1)
        let mid := 0
        let low := 0
        for { } iszero(gt(low, high)) { } {
          mid := div(add(low,high),2)

          switch lt(sload(add(sha3(0x60,0x20),mid)),value)
          case 1 {
             low := add(mid,1)
          }
          case 0 {
            switch gt(sload(add(sha3(0x60,0x20),mid)),value)
            case 1 {
              high := sub(mid,1)
            }
            case 0 {
              found := 1
              index := mid
              low := add(high,1)
            }
          }
        }
      }
      case 0 {
        for { let low := 0 } lt(low, sload(self_slot)) { low := add(low, 1) } {
          switch eq(sload(add(sha3(0x60,0x20),low)), value)
          case 1 {
            found := 1
            index := low
            low := sload(self_slot)
          }
        }
      }
    }
  }

  /// @dev Utility function for heapSort
  /// @param index The index of child node
  /// @return pI The parent node index
  function getParentI(uint256 index) constant private returns (uint256 pI) {
    uint256 i = index - 1;
    pI = i/2;
  }

  /// @dev Utility function for heapSort
  /// @param index The index of parent node
  /// @return lcI The index of left child
  function getLeftChildI(uint256 index) constant private returns (uint256 lcI) {
    uint256 i = index * 2;
    lcI = i + 1;
  }

  /// @dev Sorts given array in place
  /// @param self Storage array containing uint256 type variables
  function heapSort(uint256[] storage self) {
    uint256 end = self.length - 1;
    uint256 start = getParentI(end);
    uint256 root = start;
    uint256 lChild;
    uint256 rChild;
    uint256 swap;
    uint256 temp;
    while(start >= 0){
      root = start;
      lChild = getLeftChildI(start);
      while(lChild <= end){
        rChild = lChild + 1;
        swap = root;
        if(self[swap] < self[lChild])
          swap = lChild;
        if((rChild <= end) && (self[swap]<self[rChild]))
          swap = rChild;
        if(swap == root)
          lChild = end+1;
        else {
          temp = self[swap];
          self[swap] = self[root];
          self[root] = temp;
          root = swap;
          lChild = getLeftChildI(root);
        }
      }
      if(start == 0)
        break;
      else
        start = start - 1;
    }
    while(end > 0){
      temp = self[end];
      self[end] = self[0];
      self[0] = temp;
      end = end - 1;
      root = 0;
      lChild = getLeftChildI(0);
      while(lChild <= end){
        rChild = lChild + 1;
        swap = root;
        if(self[swap] < self[lChild])
          swap = lChild;
        if((rChild <= end) && (self[swap]<self[rChild]))
          swap = rChild;
        if(swap == root)
          lChild = end + 1;
        else {
          temp = self[swap];
          self[swap] = self[root];
          self[root] = temp;
          root = swap;
          lChild = getLeftChildI(root);
        }
      }
    }
  }
}

pragma solidity ^0.4.13;

/**
 * @title Basic Math Library
 * @author Majoolr.io
 *
 * version 1.1.0
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The Basic Math Library is inspired by the Safe Math library written by
 * OpenZeppelin at https://github.com/OpenZeppelin/zeppelin-solidity/ .
 * Majoolr works on open source projects in the Ethereum community with the
 * purpose of testing, documenting, and deploying reusable code onto the
 * blockchain to improve security and usability of smart contracts. Majoolr
 * also strives to educate non-profits, schools, and other community members
 * about the application of blockchain technology.
 * For further information: majoolr.io, openzeppelin.org
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library BasicMathLib {
  event Err(string typeErr);

  /// @dev Multiplies two numbers and checks for overflow before returning.
  /// Does not throw but rather logs an Err event if there is overflow.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is overflow
  /// @return res The product of a and b, or 0 if there is overflow
  function times(uint256 a, uint256 b) constant returns (bool err,uint256 res) {
    assembly{
      res := mul(a,b)
      switch or(iszero(b), eq(div(res,b), a))
      case 0 {
        err := 1
        res := 0
      }
    }
    if (err)
      Err("times func overflow");
  }

  /// @dev Divides two numbers but checks for 0 in the divisor first.
  /// Does not throw but rather logs an Err event if 0 is in the divisor.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if `b` is 0
  /// @return res The quotient of a and b, or 0 if `b` is 0
  function dividedBy(uint256 a, uint256 b) constant returns (bool err,uint256 res) {
    assembly{
      switch iszero(b)
      case 0 {
        res := div(a,b)
        mstore(add(mload(0x40),0x20),res)
        return(mload(0x40),0x40)
      }
    }
    Err("tried to divide by zero");
    return (true, 0);
  }

  /// @dev Adds two numbers and checks for overflow before returning.
  /// Does not throw but rather logs an Err event if there is overflow.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is overflow
  /// @return res The sum of a and b, or 0 if there is overflow
  function plus(uint256 a, uint256 b) constant returns (bool err, uint256 res) {
    assembly{
      res := add(a,b)
      switch and(eq(sub(res,b), a), or(gt(res,b),eq(res,b)))
      case 0 {
        err := 1
        res := 0
      }
    }
    if (err)
      Err("plus func overflow");
  }

  /// @dev Subtracts two numbers and checks for underflow before returning.
  /// Does not throw but rather logs an Err event if there is underflow.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is underflow
  /// @return res The difference between a and b, or 0 if there is underflow
  function minus(uint256 a, uint256 b) constant returns (bool err,uint256 res) {
    assembly{
      res := sub(a,b)
      switch eq(and(eq(add(res,b), a), or(lt(res,a), eq(res,a))), 1)
      case 0 {
        err := 1
        res := 0
      }
    }
    if (err)
      Err("minus func underflow");
  }
}