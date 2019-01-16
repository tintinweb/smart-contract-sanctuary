pragma solidity ^ 0.4.15;

contract ferromContract {
    /*
    *  Events
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approvers(
        string indexed miningId,
        string indexed activity,
        address[] indexed ApproversAddress
    );
    event Deposit(address indexed sender, uint value);


    /*
    *  Constants
    */
    uint constant public MAX_OWNER_COUNT = 10;

    /*
    * Structs
    */
    struct ApproversAddress {
        address[] approversAddress;
    }

    /*
    *  Storage
    */
    mapping(address => uint256) public balances;
    mapping(string => mapping(string => ApproversAddress)) approvers;

    /*
    *  Modifiers
    */
    modifier validRequirement(uint approverCount) {
        require(approverCount <= MAX_OWNER_COUNT
            && approverCount != 0);
        _;
    }
    
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;

    /// @dev Fallback function allows to deposit ether.
    function()
    payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /*
    * Public functions
    */
    /// @dev Contract constructor sets tokens to owner address.
    /// @param _tokens Number of tokens.
    /// @param _symbol Symbol of token.
    function ferromContract(uint _tokens, string _symbol)
    public
    {
        balances[msg.sender] = _tokens;    // creator gets all initial tokens
        totalSupply = _tokens;             // total supply of token
        name = "Enlight";               // name of token
        decimals = 0;                  // amount of decimals
        symbol = _symbol;
    }

    function transfer(address _to, uint256 _value) returns(bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        if (balances[_from] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            // allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

    function setApprovers(string _miningId, string _activity, address[] _approvers) public
    validRequirement(_approvers.length)
    {
        // approvers[_miningId][_activity].push(ApproversAddress(_approvers));
        approvers[_miningId][_activity] = (ApproversAddress(_approvers));
        Approvers(_miningId, _activity, _approvers);
    }

    function getApprovers(string _miningId, string _activity) public view returns(address[]) {
        return approvers[_miningId][_activity].approversAddress;
    }
}