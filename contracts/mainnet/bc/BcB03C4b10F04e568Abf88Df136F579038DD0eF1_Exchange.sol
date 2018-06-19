pragma solidity ^0.4.11;

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}


// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    //uint256 public totalSupply;
    function totalSupply() constant returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Exchange is Owned {

    event onExchangeTokenToEther(address who, uint256 tokenAmount, uint256 etherAmount);

    using SafeMath for uint256;

    Token public token = Token(0xD850942eF8811f2A866692A623011bDE52a462C1);

    // 1 ether = ? tokens
    uint256 public rate = 4025;

    // quota of token for every account that can be exchanged to ether
    uint256 public tokenQuota = 402500 ether;

    // quota of ether for every account that can be exchanged to token
    // uint256 public etherQuota = 100 ether;

    bool public tokenToEtherAllowed = true;
    // bool public etherToTokenAllowed = false;

    // uint256 public totalReturnedCredit;             //returned ven  


    // struct QuotaUsed {
    //     uint128 tokens;
    //     uint128 ethers;
    // }
    mapping(address => uint256) accountQuotaUsed;

    function Exchange() {
    }

    function () payable {
    }


    function withdrawEther(address _address,uint256 _amount) onlyOwner {
        require(_address != 0);
        _address.transfer(_amount);
    }

    function withdrawToken(address _address, uint256 _amount) onlyOwner {
        require(_address != 0);
        token.transfer(_address, _amount);
    }

    function quotaUsed(address _account) constant returns(uint256 ) {
        return accountQuotaUsed[_account];
    }

    //tested
    function setRate(uint256 _rate) onlyOwner {
        rate = _rate;
    }

    //tested
    function setTokenQuota(uint256 _quota) onlyOwner {
        tokenQuota = _quota;
    }

    // function setEtherQuota(uint256 _quota) onlyOwner {
    //     etherQuota = _quota;
    // }

    //tested    
    function setTokenToEtherAllowed(bool _allowed) onlyOwner {
        tokenToEtherAllowed = _allowed;
    }

    // function setEtherToTokenAllowed(bool _allowed) onlyOwner {
    //     etherToTokenAllowed = _allowed;
    // }

    function receiveApproval(address _from, uint256 _value, address /*_tokenContract*/, bytes /*_extraData*/) {
        exchangeTokenToEther(_from, _value);
    }

    function exchangeTokenToEther(address _from, uint256 _tokenAmount) internal {
        require(tokenToEtherAllowed);
        require(msg.sender == address(token));
        require(!isContract(_from));

        uint256 quota = tokenQuota.sub(accountQuotaUsed[_from]);                

        if (_tokenAmount > quota)
            _tokenAmount = quota;
        
        uint256 balance = token.balanceOf(_from);
        if (_tokenAmount > balance)
            _tokenAmount = balance;

        require(_tokenAmount>0);    //require the token should be above 0

        //require(_tokenAmount > 0.01 ether);
        require(token.transferFrom(_from, this, _tokenAmount));        

        accountQuotaUsed[_from] = _tokenAmount.add(accountQuotaUsed[_from]);
        
        uint256 etherAmount = _tokenAmount / rate;
        require(etherAmount > 0);
        _from.transfer(etherAmount);

        // totalReturnedCredit+=_tokenAmount;

        onExchangeTokenToEther(_from, _tokenAmount, etherAmount);
    }


    //exchange EtherToToken放到fallback函数中
    //TokenToEther
    //    function exchangeEtherToToken() payable {
    //       require(etherToTokenAllowed);
    //        require(!isContract(msg.sender));
    //
    //        uint256 quota = etherQuota.sub(accountQuotaUsed[msg.sender].ethers);

    //        uint256 etherAmount = msg.value;
    //        require(etherAmount >= 0.01 ether && etherAmount <= quota);
    //        
    //        uint256 tokenAmount = etherAmount * rate;

    //        accountQuotaUsed[msg.sender].ethers = etherAmount.add(accountQuotaUsed[msg.sender].ethers).toUINT128();

    //        require(token.transfer(msg.sender, tokenAmount));

    //        onExchangeEtherToToken(msg.sender, tokenAmount, etherAmount);                                                        
    //    }

    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0)
            return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}