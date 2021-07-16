//SourceUnit: pe1game.sol

pragma solidity ^ 0.5.9;
contract CTST{
    function balanceOf(address _owner) public view returns (uint256 val);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

contract CtstGame {
    address private TRC20_ADDR = 0x8Fc28203Fc259aEF95f45c92636003B8C441Eeeb;
    address constant private ADMIN_ADDR = 0xcA06858A940094E09c4E19Cc8a94e59CFb273863;
    address private op_addr = 0xA5d57DC64aF74fe5aBbC7853e2F79642eF8031eC;
    CTST private token;
    event ev_withdraw(address indexed addr, uint256 _value);
    modifier onlyAdmin() {
        require(msg.sender == ADMIN_ADDR);
        _;
    }
    modifier onlyOperator() {
        require(msg.sender == op_addr);
        _;
    }
    constructor() public {
        token = CTST(TRC20_ADDR);
    }
    function setOperator(address opAddr) public onlyAdmin{
        op_addr = opAddr;
    }
    function withdraw(address to, uint _amt) public onlyOperator {
        token.transfer(to, _amt);
        emit ev_withdraw(to, _amt);
    }

    function balance() public view returns (uint256 val){
        return token.balanceOf(address(this));
    }
    
    function setTRC20addr(address _newAddr) public onlyAdmin{
        TRC20_ADDR = _newAddr;
        token = CTST(TRC20_ADDR);
    }
    function getaddr() public view returns(address,address,address){
        return (TRC20_ADDR,msg.sender,op_addr);
    }
}