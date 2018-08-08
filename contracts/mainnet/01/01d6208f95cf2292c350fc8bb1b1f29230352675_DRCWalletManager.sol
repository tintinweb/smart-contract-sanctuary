pragma solidity ^0.4.13;

interface IDRCWalletMgrParams {
    function singleWithdrawMin() external returns (uint256); // min value of single withdraw
    function singleWithdrawMax() external returns (uint256); // Max value of single withdraw
    function dayWithdraw() external returns (uint256); // Max value of one day of withdraw
    function monthWithdraw() external returns (uint256); // Max value of one month of withdraw
    function dayWithdrawCount() external returns (uint256); // Max number of withdraw counting

    function chargeFee() external returns (uint256); // the charge fee for withdraw
    function chargeFeePool() external returns (address); // the address that will get the returned charge fees.
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Withdrawable is Ownable {
    event ReceiveEther(address _from, uint256 _value);
    event WithdrawEther(address _to, uint256 _value);
    event WithdrawToken(address _token, address _to, uint256 _value);

    /**
	 * @dev recording receiving ether from msn.sender
	 */
    function () payable public {
        emit ReceiveEther(msg.sender, msg.value);
    }

    /**
	 * @dev withdraw,send ether to target
	 * @param _to is where the ether will be sent to
	 *        _amount is the number of the ether
	 */
    function withdraw(address _to, uint _amount) public onlyOwner returns (bool) {
        require(_to != address(0));
        _to.transfer(_amount);
        emit WithdrawEther(_to, _amount);

        return true;
    }

    /**
	 * @dev withdraw tokens, send tokens to target
     *
     * @param _token the token address that will be withdraw
	 * @param _to is where the tokens will be sent to
	 *        _value is the number of the token
	 */
    function withdrawToken(address _token, address _to, uint256 _value) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_token != address(0));

        ERC20 tk = ERC20(_token);
        tk.transfer(_to, _value);
        emit WithdrawToken(_token, _to, _value);

        return true;
    }

    /**
     * @dev receive approval from an ERC20 token contract, and then gain the tokens, 
     *      then take a record
     *
     * @param _from address The address which you want to send tokens from
     * @param _value uint256 the amounts of tokens to be sent
     * @param _token address the ERC20 token address
     * @param _extraData bytes the extra data for the record
     */
    // function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
    //     require(_token != address(0));
    //     require(_from != address(0));
        
    //     ERC20 tk = ERC20(_token);
    //     require(tk.transferFrom(_from, this, _value));
        
    //     emit ReceiveDeposit(_from, _value, _token, _extraData);
    // }
}

contract TokenDestructible is Ownable {

  function TokenDestructible() public payable { }

  /**
   * @notice Terminate contract and refund to owner
   * @param tokens List of addresses of ERC20 or ERC20Basic token contracts to
   refund.
   * @notice The called token contracts could try to re-enter this contract. Only
   supply token contracts you trust.
   */
  function destroy(address[] tokens) onlyOwner public {

    // Transfer tokens to owner
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

    // Transfer Eth to owner and terminate contract
    selfdestruct(owner);
  }
}

contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract DepositWithdraw is Claimable, Withdrawable {
    using SafeMath for uint256;

    /**
     * transaction record
     */
    struct TransferRecord {
        uint256 timeStamp;
        address account;
        uint256 value;
    }
    
    /**
     * accumulated transferring amount record
     */
    struct accumulatedRecord {
        uint256 mul;
        uint256 count;
        uint256 value;
    }

    TransferRecord[] deposRecs; // record all the deposit tx data
    TransferRecord[] withdrRecs; // record all the withdraw tx data

    accumulatedRecord dayWithdrawRec; // accumulated amount record for one day
    accumulatedRecord monthWithdrawRec; // accumulated amount record for one month

    address wallet; // the binded withdraw address

    event ReceiveDeposit(address _from, uint256 _value, address _token, bytes _extraData);
    
    /**
     * @dev constructor of the DepositWithdraw contract
     * @param _wallet the binded wallet address to this depositwithdraw contract
     */
    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }

    /**
	 * @dev set the default wallet address
	 * @param _wallet the default wallet address binded to this deposit contract
	 */
    function setWithdrawWallet(address _wallet) onlyOwner public returns (bool) {
        require(_wallet != address(0));
        wallet = _wallet;

        return true;
    }

    /**
	 * @dev util function to change bytes data to bytes32 data
	 * @param _data the bytes data to be converted
	 */
    function bytesToBytes32(bytes _data) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(_data, 32))
        }
    }

    /**
     * @dev receive approval from an ERC20 token contract, take a record
     *
     * @param _from address The address which you want to send tokens from
     * @param _value uint256 the amounts of tokens to be sent
     * @param _token address the ERC20 token address
     * @param _extraData bytes the extra data for the record
     */
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) onlyOwner public {
        require(_token != address(0));
        require(_from != address(0));
        
        ERC20 tk = ERC20(_token);
        require(tk.transferFrom(_from, this, _value));
        bytes32 timestamp = bytesToBytes32(_extraData);
        deposRecs.push(TransferRecord(uint256(timestamp), _from, _value));
        emit ReceiveDeposit(_from, _value, _token, _extraData);
    }

    // function authorize(address _token, address _spender, uint256 _value) onlyOwner public returns (bool) {
    //     ERC20 tk = ERC20(_token);
    //     require(tk.approve(_spender, _value));

    //     return true;
    // }

    /**
     * @dev record withdraw into this contract
     *
     * @param _time the timstamp of the withdraw time
     * @param _to is where the tokens will be sent to
     * @param _value is the number of the token
     */
    function recordWithdraw(uint256 _time, address _to, uint256 _value) onlyOwner public {    
        withdrRecs.push(TransferRecord(_time, _to, _value));
    }

    /**
     * @dev check if withdraw amount is not valid
     *
     * @param _params the limitation parameters for withdraw
     * @param _value is the number of the token
     * @param _time the timstamp of the withdraw time
     */
    function checkWithdrawAmount(address _params, uint256 _value, uint256 _time) public returns (bool) {
        IDRCWalletMgrParams params = IDRCWalletMgrParams(_params);
        require(_value <= params.singleWithdrawMax());
        require(_value >= params.singleWithdrawMin());

        uint256 daysCount = _time.div(86400); // one day of seconds
        if (daysCount <= dayWithdrawRec.mul) {
            dayWithdrawRec.count = dayWithdrawRec.count.add(1);
            dayWithdrawRec.value = dayWithdrawRec.value.add(_value);
            require(dayWithdrawRec.count <= params.dayWithdrawCount());
            require(dayWithdrawRec.value <= params.dayWithdraw());
        } else {
            dayWithdrawRec.mul = daysCount;
            dayWithdrawRec.count = 1;
            dayWithdrawRec.value = _value;
        }
        
        uint256 monthsCount = _time.div(86400 * 30);
        if (monthsCount <= monthWithdrawRec.mul) {
            monthWithdrawRec.count = monthWithdrawRec.count.add(1);
            monthWithdrawRec.value = monthWithdrawRec.value.add(_value);
            require(monthWithdrawRec.value <= params.monthWithdraw());
        } else {            
            monthWithdrawRec.mul = monthsCount;
            monthWithdrawRec.count = 1;
            monthWithdrawRec.value = _value;
        }

        return true;
    }

    /**
	 * @dev withdraw tokens, send tokens to target
     *
     * @param _token the token address that will be withdraw
     * @param _params the limitation parameters for withdraw
     * @param _time the timstamp of the withdraw time
	 * @param _to is where the tokens will be sent to
	 *        _value is the number of the token
     *        _fee is the amount of the transferring costs
     *        _tokenReturn is the address that return back the tokens of the _fee
	 */
    function withdrawToken(address _token, address _params, uint256 _time, address _to, uint256 _value, uint256 _fee, address _tokenReturn) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_token != address(0));
        require(_value > _fee);
        // require(_tokenReturn != address(0));

        require(checkWithdrawAmount(_params, _value, _time));

        ERC20 tk = ERC20(_token);
        uint256 realAmount = _value.sub(_fee);
        require(tk.transfer(_to, realAmount));
        if (_tokenReturn != address(0) && _fee > 0) {
            require(tk.transfer(_tokenReturn, _fee));
        }

        recordWithdraw(_time, _to, realAmount);
        emit WithdrawToken(_token, _to, realAmount);

        return true;
    }

    /**
	 * @dev withdraw tokens, send tokens to target default wallet
     *
     * @param _token the token address that will be withdraw
     * @param _params the limitation parameters for withdraw
     * @param _time the timestamp occur the withdraw record
	 * @param _value is the number of the token
     *        _fee is the amount of the transferring costs
     *        —tokenReturn is the address that return back the tokens of the _fee
	 */
    function withdrawTokenToDefault(address _token, address _params, uint256 _time, uint256 _value, uint256 _fee, address _tokenReturn) public onlyOwner returns (bool) {
        return withdrawToken(_token, _params, _time, wallet, _value, _fee, _tokenReturn);
    }

    /**
	 * @dev get the Deposit records number
     *
     */
    function getDepositNum() public view returns (uint256) {
        return deposRecs.length;
    }

    /**
	 * @dev get the one of the Deposit records
     *
     * @param _ind the deposit record index
     */
    function getOneDepositRec(uint256 _ind) public view returns (uint256, address, uint256) {
        require(_ind < deposRecs.length);

        return (deposRecs[_ind].timeStamp, deposRecs[_ind].account, deposRecs[_ind].value);
    }

    /**
	 * @dev get the withdraw records number
     *
     */
    function getWithdrawNum() public view returns (uint256) {
        return withdrRecs.length;
    }
    
    /**
	 * @dev get the one of the withdraw records
     *
     * @param _ind the withdraw record index
     */
    function getOneWithdrawRec(uint256 _ind) public view returns (uint256, address, uint256) {
        require(_ind < withdrRecs.length);

        return (withdrRecs[_ind].timeStamp, withdrRecs[_ind].account, withdrRecs[_ind].value);
    }
}

contract OwnerContract is Claimable {
    Claimable public ownedContract;
    address internal origOwner;

    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function bindContract(address _contract) onlyOwner public returns (bool) {
        require(_contract != address(0));
        ownedContract = Claimable(_contract);
        origOwner = ownedContract.owner();

        // take ownership of the owned contract
        ownedContract.claimOwnership();

        return true;
    }

    /**
     * @dev change the owner of the contract from this contract address to the original one. 
     *
     */
    function transferOwnershipBack() onlyOwner public {
        ownedContract.transferOwnership(origOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }

    /**
     * @dev change the owner of the contract from this contract address to another one. 
     *
     * @param _nextOwner the contract address that will be next Owner of the original Contract
     */
    function changeOwnershipto(address _nextOwner)  onlyOwner public {
        ownedContract.transferOwnership(_nextOwner);
        ownedContract = Claimable(address(0));
        origOwner = address(0);
    }
}

contract DRCWalletManager is OwnerContract, Withdrawable, TokenDestructible {
    using SafeMath for uint256;
    
    /**
     * withdraw wallet description
     */
    struct WithdrawWallet {
        bytes32 name;
        address walletAddr;
    }

    /**
     * Deposit data storage
     */
    struct DepositRepository {
        // uint256 balance;
        uint256 frozen;
        WithdrawWallet[] withdrawWallets;
        // mapping (bytes32 => address) withdrawWallets;
    }

    mapping (address => DepositRepository) depositRepos;
    mapping (address => address) public walletDeposits;
    mapping (address => bool) public frozenDeposits;

    ERC20 public tk; // the token will be managed
    IDRCWalletMgrParams public params; // the parameters that the management needs
    
    event CreateDepositAddress(address indexed _wallet, address _deposit);
    event FrozenTokens(address indexed _deposit, bool _freeze, uint256 _value);
    // event ChangeDefaultWallet(address indexed _oldWallet, address _newWallet);

    /**
	 * @dev withdraw tokens, send tokens to target default wallet
     *
     * @param _token the token address that will be withdraw
     * @param _walletParams the wallet management parameters
	 */
    function bindToken(address _token, address _walletParams) onlyOwner public returns (bool) {
        require(_token != address(0));
        require(_walletParams != address(0));

        tk = ERC20(_token);
        params = IDRCWalletMgrParams(_walletParams);
        return true;
    }
    
    /**
	 * @dev create deposit contract address for the default withdraw wallet
     *
     * @param _wallet the binded default withdraw wallet address
	 */
    function createDepositContract(address _wallet) onlyOwner public returns (address) {
        require(_wallet != address(0));

        DepositWithdraw deposWithdr = new DepositWithdraw(_wallet); // new contract for deposit
        address _deposit = address(deposWithdr);
        walletDeposits[_wallet] = _deposit;
        WithdrawWallet[] storage withdrawWalletList = depositRepos[_deposit].withdrawWallets;
        withdrawWalletList.push(WithdrawWallet("default wallet", _wallet));
        // depositRepos[_deposit].balance = 0;
        depositRepos[_deposit].frozen = 0;

        // deposWithdr.authorize(address(tk), this, 1e27); // give authorization to owner contract

        emit CreateDepositAddress(_wallet, address(deposWithdr));
        return deposWithdr;
    }
    
    /**
	 * @dev get deposit contract address by using the default withdraw wallet
     *
     * @param _wallet the binded default withdraw wallet address
	 */
    // function getDepositAddress(address _wallet) onlyOwner public view returns (address) {
    //     require(_wallet != address(0));
    //     address deposit = walletDeposits[_wallet];

    //     return deposit;
    // }
    
    /**
	 * @dev get deposit balance and frozen amount by using the deposit address
     *
     * @param _deposit the deposit contract address
	 */
    function getDepositInfo(address _deposit) onlyOwner public view returns (uint256, uint256) {
        require(_deposit != address(0));
        uint256 _balance = tk.balanceOf(_deposit);
        uint256 frozenAmount = depositRepos[_deposit].frozen;
        // depositRepos[_deposit].balance = _balance;

        return (_balance, frozenAmount);
    }
    
    /**
	 * @dev get the number of withdraw wallet addresses bindig to the deposit contract address
     *
     * @param _deposit the deposit contract address
	 */
    function getDepositWithdrawCount(address _deposit) onlyOwner public view returns (uint) {
        require(_deposit != address(0));

        WithdrawWallet[] storage withdrawWalletList = depositRepos[_deposit].withdrawWallets;
        uint len = withdrawWalletList.length;

        return len;
    }
    
    /**
	 * @dev get the withdraw wallet addresses list binding to the deposit contract address
     *
     * @param _deposit the deposit contract address
     * @param _indices the array of indices of the withdraw wallets
	 */
    function getDepositWithdrawList(address _deposit, uint[] _indices) onlyOwner public view returns (bytes32[], address[]) {
        require(_indices.length != 0);

        bytes32[] memory names = new bytes32[](_indices.length);
        address[] memory wallets = new address[](_indices.length);
        
        for (uint i = 0; i < _indices.length; i = i.add(1)) {
            WithdrawWallet storage wallet = depositRepos[_deposit].withdrawWallets[_indices[i]];
            names[i] = wallet.name;
            wallets[i] = wallet.walletAddr;
        }
        
        return (names, wallets);
    }
    
    /**
	 * @dev change the default withdraw wallet address binding to the deposit contract address
     *
     * @param _oldWallet the previous default withdraw wallet
     * @param _newWallet the new default withdraw wallet
	 */
    function changeDefaultWithdraw(address _oldWallet, address _newWallet) onlyOwner public returns (bool) {
        require(_newWallet != address(0));
        
        address deposit = walletDeposits[_oldWallet];
        DepositWithdraw deposWithdr = DepositWithdraw(deposit);
        require(deposWithdr.setWithdrawWallet(_newWallet));

        WithdrawWallet[] storage withdrawWalletList = depositRepos[deposit].withdrawWallets;
        withdrawWalletList[0].walletAddr = _newWallet;
        // emit ChangeDefaultWallet(_oldWallet, _newWallet);

        return true;
    }
    
    /**
	 * @dev freeze the tokens in the deposit address
     *
     * @param _deposit the deposit address
     * @param _freeze to freeze or release
     * @param _value the amount of tokens need to be frozen
	 */
    function freezeTokens(address _deposit, bool _freeze, uint256 _value) onlyOwner public returns (bool) {
        require(_deposit != address(0));
        
        frozenDeposits[_deposit] = _freeze;
        if (_freeze) {
            depositRepos[_deposit].frozen = depositRepos[_deposit].frozen.add(_value);
        } else {
            require(_value <= depositRepos[_deposit].frozen);
            depositRepos[_deposit].frozen = depositRepos[_deposit].frozen.sub(_value);
        }

        emit FrozenTokens(_deposit, _freeze, _value);
        return true;
    }
    
    /**
	 * @dev withdraw the tokens from the deposit address to default wallet with charge fee
     *
     * @param _deposit the deposit address
     * @param _time the timestamp the withdraw occurs
     * @param _value the amount of tokens need to be frozen
	 */
    function withdrawWithFee(address _deposit, uint256 _time, uint256 _value, bool _check) onlyOwner public returns (bool) {    
        WithdrawWallet[] storage withdrawWalletList = depositRepos[_deposit].withdrawWallets;
        return withdrawWithFee(_deposit, _time, withdrawWalletList[0].name, withdrawWalletList[0].walletAddr, _value, _check);
    }
    
    /**
	 * @dev check if the wallet name is not matching the expected wallet address
     *
     * @param _deposit the deposit address
     * @param _name the withdraw wallet name
     * @param _to the withdraw wallet address
	 */
    function checkWithdrawAddress(address _deposit, bytes32 _name, address _to) public view returns (bool, bool) {
        uint len = depositRepos[_deposit].withdrawWallets.length;
        for (uint i = 0; i < len; i = i.add(1)) {
            WithdrawWallet memory wallet = depositRepos[_deposit].withdrawWallets[i];
            if (_name == wallet.name) {
                return(true, (_to == wallet.walletAddr));
            }
            if (_to == wallet.walletAddr) {
                return(true, true);
            }
        }

        return (false, true);
    }
    
    /**
	 * @dev withdraw tokens from this contract, send tokens to target withdraw wallet
     *
     * @param _deposWithdr the deposit contract that will record withdrawing
     * @param _time the timestamp occur the withdraw record
     * @param _to the address the token will be transfer to 
     * @param _value the token transferred value
	 */
    function withdrawFromThis(DepositWithdraw _deposWithdr, uint256 _time, address _to, uint256 _value) private returns (bool) {
        uint256 fee = params.chargeFee();
        uint256 realAmount = _value.sub(fee);
        address tokenReturn = params.chargeFeePool();
        if (tokenReturn != address(0) && fee > 0) {
            require(tk.transfer(tokenReturn, fee));
        }

        require (tk.transfer(_to, realAmount));
        _deposWithdr.recordWithdraw(_time, _to, realAmount);

        return true;
    }

    /**
	 * @dev withdraw tokens, send tokens to target withdraw wallet
     *
     * @param _deposit the deposit address that will be withdraw from
     * @param _time the timestamp occur the withdraw record
	 * @param _name the withdraw address alias name to verify
     * @param _to the address the token will be transfer to 
     * @param _value the token transferred value
     * @param _check if we will check the value is valid or meet the limit condition
	 */
    function withdrawWithFee(address _deposit, 
                             uint256 _time, 
                             bytes32 _name, 
                             address _to, 
                             uint256 _value, 
                             bool _check) onlyOwner public returns (bool) {
        require(_deposit != address(0));
        require(_to != address(0));

        uint256 _balance = tk.balanceOf(_deposit);
        if (_check) {
            require(_value <= _balance);
        }

        uint256 available = _balance.sub(depositRepos[_deposit].frozen);
        if (_check) {
            require(_value <= available);
        }

        bool exist;
        bool correct;
        WithdrawWallet[] storage withdrawWalletList = depositRepos[_deposit].withdrawWallets;
        (exist, correct) = checkWithdrawAddress(_deposit, _name, _to);
        if(!exist) {
            withdrawWalletList.push(WithdrawWallet(_name, _to));
        } else if(!correct) {
            return false;
        }

        DepositWithdraw deposWithdr = DepositWithdraw(_deposit);
        /**
         * if deposit address doesn&#39;t have enough tokens to withdraw, 
         * then withdraw from this contract. Record in deposit contract.
         */
        if (_value > available) {
            require(deposWithdr.checkWithdrawAmount(address(params), _value, _time));
            require(deposWithdr.withdrawToken(address(tk), this, available));
            
            require(withdrawFromThis(deposWithdr, _time, _to, _value));
            return true;
        }
        
        return (deposWithdr.withdrawToken(address(tk), address(params), _time, _to, _value, params.chargeFee(), params.chargeFeePool()));        
    }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}