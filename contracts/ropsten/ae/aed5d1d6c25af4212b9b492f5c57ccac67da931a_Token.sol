pragma solidity ^0.4.18;

interface IToken {

    function distribute(address _to, uint _amount) external returns (bool success);

    function dispossess(address _owner, uint _amount) external returns (bool success);

    function lock(address _owner, uint _amount) external returns (bool success);

    function unlock(address _owner, uint _amount) external returns (bool success);

    function suspend(bool _suspended) external;

    function mint(address _to, uint _amount) external returns (bool success);

    function burn(address _owner, uint _amount) external returns (bool success);

    event Created(address indexed _owner, string _name, string _symbol);

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

interface ITokenFactory {
    function create(
        address _project,
        string _name,
        string _symbol,
        uint8 _decimals,
        uint _fixedTotalSupply
    ) external returns (IToken);
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract Token is IToken, ERC20Interface{

    address private host;
    address private project;
    bool private suspended;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) private freeBalances;
    mapping(address => uint) private lockedBalances;
    mapping(address => mapping(address => uint)) private allowed;

    function Token(
        address _project,
        string _name,
        string _symbol,
        uint8 _decimals,
        uint _initialSupply
    )
        public
    {
        host = tx.origin;
        project = _project;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply = _initialSupply;
        freeBalances[host] = _initialSupply;
        Transfer(0x0000000000000000000000000000000000000000, host, _initialSupply);
    }

    function totalSupply() public constant returns (uint) {
        return totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        balance = freeBalances[_owner] + lockedBalances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        if (suspended) return false;
        if (freeBalances[msg.sender] < _value) return false;

        freeBalances[msg.sender] -= _value;
        freeBalances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        if (suspended) return false;
        if (freeBalances[_from] < _value) return false;
        if (allowed[_from][msg.sender] < _value) return false;

        freeBalances[_from] -= _value;
        freeBalances[_to] += _value;

        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        if (suspended) return false;
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function() public payable {
        revert();
    }

    /**
     * @dev Host의 계좌로부터 토큰을 배포한다. lock 토큰으로 배포한다.
     * @param _to 토큰을 받을 대상
     * @param _amount 토큰 수
     */
    function distribute(address _to, uint _amount) external returns (bool success) {
        require(project == msg.sender || host == msg.sender);

        if (freeBalances[host] < _amount) return false;

        lockedBalances[_to] += _amount;
        freeBalances[host] -= _amount;
        Transfer(host, _to, _amount);
        return true;
    }

    /**
     * @dev 배포된 lock 토큰을 반환 받는다. 환불이 발생할 때, 이미 배포된 lock 토큰을 반환 받는다.
     * @param _owner 토큰 주인
     * @param _amount 토큰 수
     */
    function dispossess(address _owner, uint _amount) external returns (bool success) {
        require(project == msg.sender || host == msg.sender);

        if (lockedBalances[_owner] < _amount) return false;

        lockedBalances[_owner] -= _amount;
        freeBalances[host] += _amount;
        Transfer(_owner, host, _amount);
        return true;
    }

    /**
     * @dev 배포된 transfer 가능한 토큰을 lock 한다.
     * @param _owner 토큰 주인
     * @param _amount 토큰 수
     */
    function lock(address _owner, uint _amount) external returns (bool success) {
        require(project == msg.sender || host == msg.sender);

        if (freeBalances[_owner] < _amount) return false;

        freeBalances[_owner] -= _amount;
        lockedBalances[_owner] += _amount;
        Lock(_owner, _amount);
        return true;
    }

    /**
     * @dev 배포된 lock 토큰을 transfer 가능하도록 unlock 한다.
     * @param _owner 토큰 주인
     * @param _amount 토큰 수
     */
    function unlock(address _owner, uint _amount) external returns (bool success) {
        require(project == msg.sender || host == msg.sender);

        if (lockedBalances[_owner] < _amount) return false;

        freeBalances[_owner] += _amount;
        lockedBalances[_owner] -= _amount;
        Unlock(_owner, _amount);
        return true;
    }

    /**
     * @dev 토큰의 모든 transfer 를 중지한다.
     * @param _suspended 중지 여부
     */
    function suspend(bool _suspended) external {
        require(host == msg.sender);
        suspended = _suspended;
        Suspend(_suspended);
    }

    /**
     * @dev 새로 토큰을 추가 배포한다.
     * @param _to 토큰을 받을 대상
     * @param _amount 토큰 수
     */
    function mint(address _to, uint _amount) external returns (bool success) {
        require(project == msg.sender || host == msg.sender);
        lockedBalances[_to] += _amount;
        totalSupply += _amount;
        Mint(_to, _amount);
        return true;
    }

    /**
     * @dev 배포된 transfer 가능한 토큰을 없앤다.
     * @param _owner 토큰 주인
     * @param _amount 토큰 수
     */
    function burn(address _owner, uint _amount) external returns (bool success) {
        require(project == msg.sender || host == msg.sender);
        freeBalances[_owner] -= _amount;
        totalSupply -= _amount;
        Burn(_owner, _amount);
        return true;
    }

    function close() public {
        require(host == msg.sender);

        selfdestruct(msg.sender);
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);

    event Lock(address indexed _owner, uint _amount);

    event Unlock(address indexed _owner, uint _amount);

    event Mint(address indexed _to, uint _amount);

    event Burn(address indexed _owner, uint _amount);

    event Suspend(bool _suspended);


}