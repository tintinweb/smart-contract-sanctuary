pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        if(msg.sender != owner) throw;
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20Token {
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
    uint256 public totalSupply;

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

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { if (msg.sender != controller) throw; _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract StandardToken is ERC20Token ,Controlled{

    bool public showValue=true;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

    function transfer(address _to, uint256 _value) returns (bool success) {

        if(!transfersEnabled) throw;

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

        if(!transfersEnabled) throw;
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        if(!showValue)
        return 0;
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if(!transfersEnabled) throw;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        if(!transfersEnabled) throw;
        return allowed[_owner][_spender];
    }

    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) onlyController {
        transfersEnabled = _transfersEnabled;
    }
    function enableShowValue(bool _showValue) onlyController {
        showValue = _showValue;
    }

    function generateTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply;
        if (curTotalSupply + _amount < curTotalSupply) throw; // Check for overflow
        totalSupply=curTotalSupply + _amount;

        balances[_owner]+=_amount;

        Transfer(0, _owner, _amount);
        return true;
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract MiniMeTokenSimple is StandardToken {

    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = &#39;MMT_0.1&#39;; //An arbitrary versioning scheme


    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    address public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // The factory used to create new clone tokens
    address public tokenFactory;

    ////////////////
    // Constructor
    ////////////////

    /// @notice Constructor to create a MiniMeTokenSimple
    /// @param _tokenFactory The address of the MiniMeTokenFactory contract that
    ///  will create the Clone token contracts, the token factory needs to be
    ///  deployed first
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    function MiniMeTokenSimple(
    address _tokenFactory,
    address _parentToken,
    uint _parentSnapShotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
    ) {
        tokenFactory = _tokenFactory;
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = _parentToken;
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }
    //////////
    // Safety Methods
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

}


contract PFCContribution is Owned {

    using SafeMath for uint256;
    MiniMeTokenSimple public PFC;
    uint256 public ratio=25000;

    uint256 public constant MIN_FUND = (0.001 ether);

    uint256 public startTime=0 ;
    uint256 public endTime =0;
    uint256 public finalizedBlock=0;
    uint256 public finalizedTime=0;

    bool public isFinalize = false;

    uint256 public totalContributedETH = 0;
    uint256 public totalTokenSaled=0;

    uint256 public MaxEth=15000 ether;


    address public pfcController;
    address public destEthFoundation;

    bool public paused;

    modifier initialized() {
        require(address(PFC) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(time() >= startTime &&
        time() <= endTime &&
        finalizedBlock == 0 &&
        address(PFC) != 0x0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function PFCCContribution() {
        paused = false;
    }


    /// @notice This method should be called by the owner before the contribution
    ///  period starts This initializes most of the parameters
    /// @param _pfc Address of the PFC token contract
    /// @param _pfcController Token controller for the PFC that will be transferred after
    ///  the contribution finalizes.
    /// @param _startTime Time when the contribution period starts
    /// @param _endTime The time that the contribution period ends
    /// @param _destEthFoundation Destination address where the contribution ether is sent
    function initialize(
    address _pfc,
    address _pfcController,
    uint256 _startTime,
    uint256 _endTime,
    address _destEthFoundation,
    uint256 _maxEth
    ) public onlyOwner {
        // Initialize only once
        require(address(PFC) == 0x0);

        PFC = MiniMeTokenSimple(_pfc);
        require(PFC.totalSupply() == 0);
        require(PFC.controller() == address(this));
        require(PFC.decimals() == 18);  // Same amount of decimals as ETH

        startTime = _startTime;
        endTime = _endTime;

        assert(startTime < endTime);

        require(_pfcController != 0x0);
        pfcController = _pfcController;

        require(_destEthFoundation != 0x0);
        destEthFoundation = _destEthFoundation;

        require(_maxEth >1 ether);
        MaxEth=_maxEth;
    }

    /// @notice If anybody sends Ether directly to this contract, consider he is
    ///  getting PFCs.
    function () public payable notPaused {

        if(totalContributedETH>=MaxEth) throw;
        proxyPayment(msg.sender);
    }


    //////////
    // MiniMe Controller functions
    //////////

    /// @notice This method will generally be called by the PFC token contract to
    ///  acquire PFCs. Or directly from third parties that want to acquire PFCs in
    ///  behalf of a token holder.
    /// @param _account PFC holder where the PFC will be minted.
    function proxyPayment(address _account) public payable initialized contributionOpen returns (bool) {
        require(_account != 0x0);

        require( msg.value >= MIN_FUND );

        uint256 tokenSaling;
        uint256 rValue;
        uint256 t_totalContributedEth=totalContributedETH+msg.value;
        uint256 reFund=0;
        if(t_totalContributedEth>MaxEth) {
            reFund=t_totalContributedEth-MaxEth;
        }
        rValue=msg.value-reFund;
        tokenSaling=rValue.mul(ratio);
        if(reFund>0)
        msg.sender.transfer(reFund);
        assert(PFC.generateTokens(_account,tokenSaling));
        destEthFoundation.transfer(rValue);

        totalContributedETH +=rValue;
        totalTokenSaled+=tokenSaling;

        NewSale(msg.sender, rValue,tokenSaling);
    }

    function setMaxEth(uint256 _maxEth) onlyOwner initialized{
        MaxEth=_maxEth;
    }

    function setRatio(uint256 _ratio) onlyOwner initialized{
        ratio=_ratio;
    }

    function issueTokenToAddress(address _account, uint256 _amount) onlyOwner initialized {


        assert(PFC.generateTokens(_account, _amount));

        totalTokenSaled +=_amount;

        NewIssue(_account, _amount);

    }

    function finalize() public onlyOwner initialized {
        require(time() >= startTime);

        require(finalizedBlock == 0);

        finalizedBlock = getBlockNumber();
        finalizedTime = now;

        PFC.changeController(pfcController);
        isFinalize=true;
        Finalized();
    }

    function time() constant returns (uint) {
        return block.timestamp;
    }

    //////////
    // Constant functions
    //////////

    /// @return Total tokens issued in weis.
    function tokensIssued() public constant returns (uint256) {
        return PFC.totalSupply();
    }

    //////////
    // Testing specific methods
    //////////

    /// @notice This function is overridden by the test Mocks.
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

    //////////
    // Safety Methods
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (PFC.controller() == address(this)) {
            PFC.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    /// @notice Pauses the contribution if there is any issue
    function pauseContribution() onlyOwner {
        paused = true;
    }

    /// @notice Resumes the contribution
    function resumeContribution() onlyOwner {
        paused = false;
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event NewSale(address _account, uint256 _amount,uint256 _tokenAmount);
    event NewIssue(address indexed _th, uint256 _amount);
    event Finalized();
}