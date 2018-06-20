pragma solidity ^0.4.23;

library SafeMath{
    // Multiples 2 numbers, throws on overflow is detected.
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256 result){
        if(_y == 0){
            return 0;
        }
        result = _x*_y;
        assert(_x == result/_y);
        return result;
    }
    //Divides 2 numbers, solidity automatically throws if _y is 0.
    function div(uint256 _x, uint256 _y) internal pure returns (uint256 result){
        result = _x / _y;
        return result;
    }
    //Adds 2 numbers, throws on overflow.
    function add(uint256 _x, uint256 _y) internal pure returns (uint256 result){
        result = _x + _y;
        assert(result >= _x);
        return result;
    }
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256 result){
        assert(_x >= _y);
        result = _x - _y;
        return result;
    }
}
interface ReceiverContract{
    function tokenFallback(address _sender, uint256 _amount, bytes _data) external;
}


contract ERC20Interface {
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);

    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract Ownable{
    address public owner;
    event ownerTransfer(address indexed oldOwner, address indexed newOwner);
    event ownerGone(address indexed oldOwner);

    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address _newOwner) public onlyOwner{
        require(_newOwner != address(0x0));
        emit ownerTransfer(owner, _newOwner);
        owner = _newOwner;
    }
    function deleteOwner() public onlyOwner{
        emit ownerGone(owner);
        owner = 0x0;
    }
}
contract Haltable is Ownable{
    bool public paused;
    event ContractPaused(address by);
    event ContractUnpaused(address by);
    constructor(){
        paused = false;
    }
    function pause() public onlyOwner {
        paused = true;
        emit ContractPaused(owner);
    }
    function unpause() public onlyOwner {
        paused = false;
        emit ContractUnpaused(owner);
    }
    modifier stopOnPause(){
        require(paused == false);
        _;
    }
}
contract ERC223Interface is Haltable, ERC20Interface{
    function transfer(address _to, uint _amount, bytes _data) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens, bytes data);
    event BalanceBurned(address indexed from, uint amount);
}


contract ABIO is ERC223Interface{
    using SafeMath for uint256;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    //Getter functions are defined automatically for the following variables.
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address ICOAddress;
    address PICOAddress;

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _supply) public{
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply;
        balances[msg.sender] = totalSupply;
    }

    function supplyPICO(address _preIco) onlyOwner{
        require(_preIco != 0x0 && PICOAddress == 0x0);
        PICOAddress = _preIco;
    }
    function supplyICO(address _ico) onlyOwner{
        require(_ico != 0x0 && ICOAddress == 0x0);
        ICOAddress = _ico;
    }
    function burnMyBalance() public {
        require(msg.sender != 0x0);
        require(msg.sender == ICOAddress || msg.sender == PICOAddress);
        uint b = balanceOf(msg.sender);
        totalSupply = totalSupply.sub(b);
        balances[msg.sender] = 0;
        emit BalanceBurned(msg.sender, b);
    }
    /**
     * @notice Underlying transfer function; it is called by public functions later.
     * @dev This architecture saves >30000 gas as compared to having two independent public functions
     *      for transfer with and without `_data`.
     **/
    function _transfer(address _from, address _to, uint256 _amount, bytes _data) internal returns (bool success){
        require(_to != 0x0);
        require(_amount <= balanceOf(_from));

        uint256 initialBalances = balanceOf(_from).add(balanceOf(_to));

        balances[_from] = balanceOf(_from).sub(_amount);
        balances[_to] = balanceOf(_to).add(_amount);

        if(isContract(_to)){
            ReceiverContract receiver = ReceiverContract(_to);
            receiver.tokenFallback(_from, _amount, _data);
        }
        assert(initialBalances == balanceOf(_from).add(balanceOf(_to)));
        return true;
    }

    /**
     * @notice Transfer with addidition data.
     * @param _data will be sent to tokenFallback() if receiver is a contract.
     **/
    function transfer(address _to, uint256 _amount, bytes _data) stopOnPause public returns (bool success){
        if (_transfer(msg.sender, _to, _amount, _data)){
            emit Transfer(msg.sender, _to, _amount, _data);
            return true;
        }
        return false;
    }

    /**
     * @notice Transfer without additional data.
     * @dev An empty `bytes` instance will be created and sent to `tokenFallback()` if receiver is a contract.
     **/
    function transfer(address _to, uint256 _amount) stopOnPause public returns (bool success){
        bytes memory empty;
        if (_transfer(msg.sender, _to, _amount, empty)){
            emit Transfer(msg.sender , _to, _amount);
            return true;
        }
        return false;
    }


    /**
     * @notice Transfers `_amount` from `_from` to `_to` without additional data.
     * @dev Only if `approve` has been called before!
     * @param _data will be sent to tokenFallback() if receiver is a contract.
     **/
    function transferFrom(address _from, address _to, uint256 _amount, bytes _data) stopOnPause public returns (bool success){
        require(_from != 0x0);
        require(allowance(_from, msg.sender) >= _amount);


        allowed[_from][msg.sender] = allowance(_from, msg.sender).sub(_amount);
        assert(_transfer(_from, _to, _amount, _data));
        emit Transfer(_from, _to, _amount, _data);
        return true;
    }

    /**
     * @notice Transfers `_amount` from `_from` to `_to` with additional data.
     * @dev Only if `approve` has been called before!
     * @dev An empty `bytes` instance will be created and sent to `tokenFallback()` if receiver is a contract.
     **/
    function transferFrom(address _from, address _to, uint256 _amount) stopOnPause  public returns (bool success){
        require(_from != 0x0);
        require(allowance(_from, msg.sender) >= _amount);

        bytes memory empty;
        allowed[_from][msg.sender] = allowance(_from, msg.sender).sub(_amount);
        assert(_transfer(_from, _to, _amount, empty));
        emit Transfer(_from, _to, _amount, empty);
        return true;
    }

    /**
     * @notice gives `_spender` allowance to spend `amount` from sender&#39;s balance.
     **/
    function approve(address _spender, uint256 _amount) stopOnPause public returns (bool success){
        require(_spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


    /**
     * @notice Checks how much a certain user allowed to a different one.
     **/
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    /**
     * @notice Checks if a contract is behind an address.
     * @dev Does it by checking if it has ANY code.
     **/
    function isContract(address _addr) public view returns(bool is_contract){
        uint length;
        assembly {
            //retrieve the code length/size on target address
            length := extcodesize(_addr)
        }
      return (length>0);
    }

    /**
     * @notice Returns balance of an address.
     * @dev Returns `0` the address was never seen before.
     **/
    function balanceOf(address _addr) public view returns (uint256){
        return balances[_addr];
    }
}