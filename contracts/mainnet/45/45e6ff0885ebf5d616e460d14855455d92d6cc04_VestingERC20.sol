pragma solidity 0.4.18;



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath64 {
  function mul(uint64 a, uint64 b) internal constant returns (uint64) {
    uint64 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint64 a, uint64 b) internal constant returns (uint64) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint64 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint64 a, uint64 b) internal constant returns (uint64) {
    assert(b <= a);
    return a - b;
  }

  function add(uint64 a, uint64 b) internal constant returns (uint64) {
    uint64 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title VestingERC20
 * @dev VestingERC20 is a contract for managing vesting of ERC20 Token.
 * @dev The tokens are unlocked continuously to the vester.
 * @dev The contract host the tokens that are locked for the vester.
 */
contract VestingERC20 {
    using SafeMath for uint256;
    using SafeMath64 for uint64;

    struct Grant {
        uint256 vestedAmount;
        uint64 startTime;
        uint64 cliffTime;
        uint64 endTime;
        uint256 withdrawnAmount;
    }

    // list of the grants (token => granter => vester => Grant).
    mapping(address => mapping(address => mapping(address => Grant))) public grantPerTokenGranterVester;

    // Ledger of the tokens hodled (this not a typo ;) ) in this contract (token => user => balance).
    mapping(address => mapping(address => uint256)) private balancePerPersonPerToken;


    event NewGrant(address granter, address vester, address token, uint256 vestedAmount, uint64 startTime, uint64 cliffTime, uint64 endTime);
    event GrantRevoked(address granter, address vester, address token);
    event Deposit(address token, address granter, uint amount, uint balance);
    event TokenReleased(address token, address granter, address vester, uint amount);
    event Withdraw(address token, address user, uint amount);

    /**
     * @dev Create a vesting to an ethereum address.
     *
     * If there is not enough tokens available on the contract, an exception is thrown.
     *
     * @param _token The ERC20 token contract address.
     * @param _vester The address where the token will be sent.
     * @param _vestedAmount The amount of tokens to be sent during the vesting period.
     * @param _startTime The time when the vesting starts.
     * @param _grantPeriod The period of the grant in sec.
     * @param _cliffPeriod The period in sec during which time the tokens cannot be withraw.
     */
    function createVesting(
        address _token, 
        address _vester,  
        uint256 _vestedAmount,
        uint64 _startTime,
        uint64 _grantPeriod,
        uint64 _cliffPeriod) 
        external
    {
        require(_token != 0);
        require(_vester != 0);
        require(_cliffPeriod <= _grantPeriod);
        require(_vestedAmount != 0);
        require(_grantPeriod==0 || _vestedAmount * _grantPeriod >= _vestedAmount); // no overflow allow here! (to make getBalanceVestingInternal safe).

        // verify that there is not already a grant between the addresses for this specific contract.
        require(grantPerTokenGranterVester[_token][msg.sender][_vester].vestedAmount==0);

        var cliffTime = _startTime.add(_cliffPeriod);
        var endTime = _startTime.add(_grantPeriod);

        grantPerTokenGranterVester[_token][msg.sender][_vester] = Grant(_vestedAmount, _startTime, cliffTime, endTime, 0);

        // update the balance
        balancePerPersonPerToken[_token][msg.sender] = balancePerPersonPerToken[_token][msg.sender].sub(_vestedAmount);

        NewGrant(msg.sender, _vester, _token, _vestedAmount, _startTime, cliffTime, endTime);
    }

    /**
     * @dev Revoke a vesting
     *
     * The vesting is deleted and the tokens already released are sent to the vester.
     *
     * @param _token The address of the token.
     * @param _vester The address of the vester.
     */
    function revokeVesting(address _token, address _vester) 
        external
    {
        require(_token != 0);
        require(_vester != 0);

        Grant storage _grant = grantPerTokenGranterVester[_token][msg.sender][_vester];

        // verify if the grant exists
        require(_grant.vestedAmount!=0);

        // send token available
        sendTokenReleasedToBalanceInternal(_token, msg.sender, _vester);

        // unlock the tokens reserved for this grant
        balancePerPersonPerToken[_token][msg.sender] = 
            balancePerPersonPerToken[_token][msg.sender].add(
                _grant.vestedAmount.sub(_grant.withdrawnAmount)
            );

        // delete the grants
        delete grantPerTokenGranterVester[_token][msg.sender][_vester];

        GrantRevoked(msg.sender, _vester, _token);
    }

    /**
     * @dev Send the released token to the user balance and eventually withdraw
     *
     * Put the tokens released to the user balance.
     * If _doWithdraw is true, send the whole balance to the user.

     * @param _token The address of the token.
     * @param _granter The address of the granter.
     * @param _doWithdraw bool, true to withdraw in the same time.
     */
    function releaseGrant(address _token, address _granter, bool _doWithdraw) 
        external
    {
        // send token to the vester
        sendTokenReleasedToBalanceInternal(_token, _granter, msg.sender);

        if(_doWithdraw) {
            withdraw(_token);           
        }

        // delete grant if fully withdrawn
        Grant storage _grant = grantPerTokenGranterVester[_token][_granter][msg.sender];
        if(_grant.vestedAmount == _grant.withdrawnAmount) 
        {
            delete grantPerTokenGranterVester[_token][_granter][msg.sender];
        }
    }

    /**
     * @dev Withdraw tokens avaibable
     *
     * The tokens are sent to msg.sender and his balancePerPersonPerToken is updated to zero.
     * If there is the token transfer fail, the transaction is revert.
     *
     * @param _token The address of the token.
     */
    function withdraw(address _token) 
        public
    {
        uint amountToSend = balancePerPersonPerToken[_token][msg.sender];
        balancePerPersonPerToken[_token][msg.sender] = 0;
        Withdraw(_token, msg.sender, amountToSend);
        require(ERC20(_token).transfer(msg.sender, amountToSend));
    }

    /**
     * @dev Send the token released to the balance address
     *
     * The token released for the address are sent and his withdrawnAmount are updated.
     * If there is nothing the send, return false.
     * 
     * @param _token The address of the token.
     * @param _granter The address of the granter.
     * @param _vester The address of the vester.
     * @return true if tokens have been sent.
     */
    function sendTokenReleasedToBalanceInternal(address _token, address _granter, address _vester) 
        internal
    {
        Grant storage _grant = grantPerTokenGranterVester[_token][_granter][_vester];
        uint256 amountToSend = getBalanceVestingInternal(_grant);

        // update withdrawnAmount
        _grant.withdrawnAmount = _grant.withdrawnAmount.add(amountToSend);

        TokenReleased(_token, _granter, _vester, amountToSend);

        // send tokens to the vester&#39;s balance
        balancePerPersonPerToken[_token][_vester] = balancePerPersonPerToken[_token][_vester].add(amountToSend); 
    }

    /**
     * @dev Calculate the amount of tokens released for a grant
     * 
     * @param _grant Grant information.
     * @return the number of tokens released.
     */
    function getBalanceVestingInternal(Grant _grant)
        internal
        constant
        returns(uint256)
    {
        if(now < _grant.cliffTime) 
        {
            // the grant didn&#39;t start 
            return 0;
        }
        else if(now >= _grant.endTime)
        {
            // after the end of the grant release everything
            return _grant.vestedAmount.sub(_grant.withdrawnAmount);
        }
        else
        {
            //  token available = vestedAmount * (now - startTime) / (endTime - startTime)  - withdrawnAmount
            //  => in other words : (number_of_token_granted_per_second * second_since_grant_started) - amount_already_withdraw
            return _grant.vestedAmount.mul( 
                        now.sub(_grant.startTime)
                    ).div(
                        _grant.endTime.sub(_grant.startTime) 
                    ).sub(_grant.withdrawnAmount);
        }
    }

    /**
     * @dev Get the amount of tokens released for a vesting
     * 
     * @param _token The address of the token.
     * @param _granter The address of the granter.
     * @param _vester The address of the vester.
     * @return the number of tokens available.
     */
    function getVestingBalance(address _token, address _granter, address _vester) 
        external
        constant 
        returns(uint256) 
    {
        Grant memory _grant = grantPerTokenGranterVester[_token][_granter][_vester];
        return getBalanceVestingInternal(_grant);
    }

    /**
     * @dev Get the token balance of the contract
     * 
     * @param _token The address of the token.
     * @param _user The address of the user.
     * @return the balance of tokens on the contract for _user.
     */
    function getContractBalance(address _token, address _user) 
        external
        constant 
        returns(uint256) 
    {
        return balancePerPersonPerToken[_token][_user];
    }

    /**
     * @dev Make a deposit of tokens on the contract
     *
     * Before using this function the user needs to do a token allowance from the user to the contract.
     *
     * @param _token The address of the token.
     * @param _amount Amount of token to deposit.
     * 
     * @return the balance of tokens on the contract for msg.sender.
     */
    function deposit(address _token, uint256 _amount) 
        external
        returns(uint256) 
    {
        require(_token!=0);
        require(ERC20(_token).transferFrom(msg.sender, this, _amount));
        balancePerPersonPerToken[_token][msg.sender] = balancePerPersonPerToken[_token][msg.sender].add(_amount);
        Deposit(_token, msg.sender, _amount, balancePerPersonPerToken[_token][msg.sender]);

        return balancePerPersonPerToken[_token][msg.sender];
    }
}