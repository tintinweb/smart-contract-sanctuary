pragma solidity ^0.4.24;

//*************** SafeMath ***************

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

//*************** Ownable *************** 

contract Ownable {
    address public owner;
    address public admin;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    function transferOwnership(address newOwner)public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    function setAdmin(address _admin)public onlyOwner {
        admin = _admin;
    }

}

//************* ERC20 *************** 

contract ERC20 {
  
    function balanceOf(address who)public view returns (uint256);
    function transfer(address to, uint256 value)public returns (bool);
    function transferFrom(address from, address to, uint256 value)public returns (bool);
    function allowance(address owner, address spender)public view returns (uint256);
    function approve(address spender, uint256 value)public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//************* BlackList *************
contract BlackList is Ownable {

    function getBlackListStatus(address _address) external view returns (bool) {
        return isBlackListed[_address];
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList(address _evilUser) public onlyOwnerAdmin {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwnerAdmin {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

}

//************* WhiteList *************
// White list of free-of-fee.

contract WhiteList is Ownable {

    function getWhiteListStatus(address _address) external view returns (bool) {
        return isWhiteListed[_address];
    }

    mapping (address => bool) public isWhiteListed;
    
    function addWhiteList(address _User) public onlyOwnerAdmin {
        isWhiteListed[_User] = true;
        emit AddedWhiteList(_User);
    }

    function removeWhiteList(address _User) public onlyOwnerAdmin {
        isWhiteListed[_User] = false;
        emit RemovedWhiteList(_User);
    }

    event AddedWhiteList(address _user);
    event RemovedWhiteList(address _user);

}

//************* KYC ********************

contract KYC is Ownable {
    bool public needVerified = false;

    mapping (address => bool) public verifiedAccount;

    event VerifiedAccount(address target, bool Verified);
    event Error_No_Binding_Address(address _from, address _to);
    event OpenKYC();
    event CloseKYC();

    function openKYC() onlyOwnerAdmin public {
        needVerified = true;
        emit OpenKYC();
    }

    function closeKYC() onlyOwnerAdmin public {
        needVerified = false;
        emit CloseKYC();
    }

    function verifyAccount(address _target, bool _Verify) onlyOwnerAdmin public {
        require(_target != address(0));
        verifiedAccount[_target] = _Verify;
        emit VerifiedAccount(_target, _Verify);
    }

    function checkIsKYC(address _from, address _to)public view returns (bool) {
        return (!needVerified || (needVerified && verifiedAccount[_from] && verifiedAccount[_to]));
    }
}

//************* TWDT Token *************

contract TWDTToken is ERC20,Ownable,KYC,BlackList,WhiteList {
    using SafeMath for uint256;

	// Token Info.
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public constant decimals = 6;

    //Wallet address.
    address public blackFundsWallet;
    address public redeemWallet;
    address public feeWallet;

    //Transaction fees.
    uint256 public feeRate = 0;
    uint256 public minimumFee = 0;
    uint256 public maximumFee = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public frozenAccountSend;

    event FrozenFunds(address target, bool frozen);
    event FrozenFundsSend(address target, bool frozen);
    event Logs(string log);

    event TransferredBlackFunds(address _blackListedUser, uint256 _balance);
    event Redeem(uint256 amount);

    event Fee(uint256 feeRate, uint256 minFee, uint256 maxFee);

    constructor() public {
        name = "Taiwan Digital Token";
        symbol = "TWDT-ETH";
        totalSupply = 100000000000*(10**decimals);
        balanceOf[msg.sender] = totalSupply;	
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balanceOf[_who];
    }

    function _transferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        // require(balanceOf[_from] >= _value);
        // require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(!frozenAccount[_from]);                  
        require(!frozenAccount[_to]); 
        require(!frozenAccountSend[_from]);
        require(!isBlackListed[_from]);
        if(checkIsKYC(_from, _to)){
            //Round down.
            uint256 fee = (((_value.mul(feeRate)).div(10000)).div(10**(decimals))).mul(10**(decimals));
            if(isWhiteListed[_from] || isWhiteListed[_to]){
                fee = 0;
            }else if(fee != 0){
                if (fee > maximumFee) {
                    fee = maximumFee;
                } else if (fee < minimumFee){
                    fee = minimumFee;
                }
            }
            
            //_value must be equal to or larger than minimumFee, otherwise it will fail.
            uint256 sendAmount = _value.sub(fee);
            balanceOf[_from] = balanceOf[_from].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(sendAmount);
            if (fee > 0) {
                balanceOf[feeWallet] = balanceOf[feeWallet].add(fee);
                emit Transfer(_from, feeWallet, fee);
            }
            emit Transfer(_from, _to, sendAmount);
            return true;
        } else {
            //If not pass KYC, throw the event.
            emit Error_No_Binding_Address(_from, _to);
            return false;
        }
    }
	
    function transfer(address _to, uint256 _value) public returns (bool){	    
        return _transferFrom(msg.sender,_to,_value);
    }
    function transferLog(address _to, uint256 _value,string logs) public returns (bool){
        bool _status = _transferFrom(msg.sender,_to,_value);
        emit Logs(logs);
        return _status;
    }
	
    function () public {
        revert();
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require(_spender != address(0));
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
	
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(_value > 0);
        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require(allowed[_from][msg.sender] >= _value);
        // require(balanceOf[_from] >= _value);
        // require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(!frozenAccountSend[_from]);
        require(!isBlackListed[_from]); 
        if(checkIsKYC(_from, _to)){
            //Round down.
            uint256 fee = (((_value.mul(feeRate)).div(10000)).div(10**(decimals))).mul(10**(decimals));
            if(isWhiteListed[_from] || isWhiteListed[_to]){
                fee = 0;
            }else if(fee != 0){
                if (fee > maximumFee) {
                    fee = maximumFee;
                } else if (fee < minimumFee){
                    fee = minimumFee;
                }
            }
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            //_value must be equal to or larger than minimumFee, otherwise it will fail.
            uint256 sendAmount = _value.sub(fee);

            balanceOf[_from] = balanceOf[_from].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(sendAmount);
            if (fee > 0) {
                balanceOf[feeWallet] = balanceOf[feeWallet].add(fee);
                emit Transfer(_from, feeWallet, fee);
            }
            emit Transfer(_from, _to, sendAmount);
            return true;
        } else {
            // If not pass KYC, throw the event.
            emit Error_No_Binding_Address(_from, _to);
            return false;
        }
    }
        
    function freezeAccount(address _target, bool _freeze) onlyOwnerAdmin public {
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

    function freezeAccountSend(address _target, bool _freeze) onlyOwnerAdmin public {
        require(_target != address(0));
        frozenAccountSend[_target] = _freeze;
        emit FrozenFundsSend(_target, _freeze);
    }

    // Transfer of illegal funds.
    // It can transfer tokens to blackFundsWallet only.
    function transferBlackFunds(address _blackListedUser) public onlyOwnerAdmin {
        require(blackFundsWallet != address(0));
        require(isBlackListed[_blackListedUser]);
        uint256 dirtyFunds = balanceOf[_blackListedUser];
        balanceOf[_blackListedUser] = 0;
        balanceOf[blackFundsWallet] = balanceOf[blackFundsWallet].add(dirtyFunds);
        emit Transfer(_blackListedUser, blackFundsWallet, dirtyFunds);
        emit TransferredBlackFunds(_blackListedUser, dirtyFunds);
    }

    // Burn tokens when user stops rent.
    // It can burn tokens from redeemWallet only.
    function redeem(uint256 amount) public onlyOwnerAdmin {
        require(redeemWallet != address(0));
        require(totalSupply >= amount);
        require(balanceOf[redeemWallet] >= amount);

        totalSupply = totalSupply.sub(amount);
        balanceOf[redeemWallet] = balanceOf[redeemWallet].sub(amount);
        emit Transfer(redeemWallet, address(0), amount);
        emit Redeem(amount);
    }

    // Mint a new amount of tokens.
    function mintToken(address _target, uint256 _mintedAmount) onlyOwner public {
        require(_target != address(0));
        require(_mintedAmount > 0);
        require(!frozenAccount[_target]);
        // require(totalSupply + _mintedAmount > totalSupply);
        // require(balanceOf[_target] + _mintedAmount > balanceOf[_target]);
        balanceOf[_target] = balanceOf[_target].add(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        emit Transfer(address(0), this, _mintedAmount);
        emit Transfer(this, _target, _mintedAmount);
    }

    // Set the illegal fund wallet.
    function setBlackFundsWallet(address _target) onlyOwner public {
        blackFundsWallet = _target;
    }

    // Set the redeem wallet.
    function setRedeemWallet(address _target) onlyOwner public {
        redeemWallet = _target;
    }

    // Set the fee wallet.
    function setFeeWallet(address _target) onlyOwner public {
        feeWallet = _target;
    }

    // Set the token transfer fee.
    // The maximum of feeRate is 0.1%.
    // The maximum of fee is 100 TWDT.
    function setFee(uint256 _feeRate, uint256 _minimumFee, uint256 _maximumFee) onlyOwner public {
        require(_feeRate <= 10);
        require(_maximumFee <= 100);
        require(_minimumFee <= _maximumFee);

        feeRate = _feeRate;
        minimumFee = _minimumFee.mul(10**decimals);
        maximumFee = _maximumFee.mul(10**decimals);

        emit Fee(feeRate, minimumFee, maximumFee);
    }
}