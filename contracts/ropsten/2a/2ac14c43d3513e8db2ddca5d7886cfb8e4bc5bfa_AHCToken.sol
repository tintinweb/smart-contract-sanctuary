pragma solidity 0.4.16;

contract AHCToken {
    string public name = &#39;AHC&#39;;
    string public symbol = &#39;AHC&#39;;
    uint8 public decimals = 18;  // decimals 可以有的小数点个数，最小的代币单位。18 是建议的默认值
    uint256 public totalSupply;
    address public owner;

    // 用mapping保存每个地址对应的余额
    mapping (address => uint256) public balanceOf;
    // 存储对账号的控制
    mapping (address => mapping (address => uint256)) public allowance;

    // 事件，用来通知客户端交易发生
    event Transfer(address  from, address  to, uint256 value);

    event Burn(address indexed from, uint256 value);
    
    /**
     * 初始化构造
     */
    function AHCToken() public {
        totalSupply = (1 * 10 ** 10 ) * 10 ** uint256(decimals);  // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
        balanceOf[msg.sender] = totalSupply;                // 创建者拥有所有的代币
        owner = msg.sender;
    }

    /**
     * 代币交易转移的内部实现
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // 检查发送者余额
        require(balanceOf[_from] >= _value);
        // 溢出检查
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }

    /**
     *  代币交易转移
     * 从自己（创建交易者）账号发送`_value`个代币到 `_to`账号
     *
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        if(balanceOf[_from] >= _value && balanceOf[_to] + _value >= balanceOf[_to] && allowance[_from][msg.sender] >= _value){
            balanceOf[_to] += _value;
            balanceOf[_from] -= _value;
            allowance[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else{

            revert();
        }
    }

    function approve(address _spender, uint256 _value) public  returns (bool success) {
        
        //require(_value == 0 || allowance[msg.sender][_spender] == 0);

        if(_value > 0){

            allowance[msg.sender][_spender] = _value;

            return true;
        } else{

            revert();
        }
    }

    function getBalanceOf(address _from) public view returns(uint){

       return (balanceOf[_from]);
    }

    function burn(uint256 _value) public returns (bool success) {
        if(balanceOf[msg.sender] >= _value){
            balanceOf[msg.sender] -= _value;
            totalSupply -= _value;
             Burn(msg.sender, _value);
            return true;
        }
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        if(balanceOf[_from] >= _value && _value <= allowance[_from][msg.sender]){
            balanceOf[_from] -= _value;
            allowance[_from][msg.sender] -= _value;
            totalSupply -= _value;
             Burn(_from, _value);
            return true;
        }
    }
}