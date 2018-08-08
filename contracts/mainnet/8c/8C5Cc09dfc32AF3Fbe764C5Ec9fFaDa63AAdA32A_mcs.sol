pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    // 本token的公共变量
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18位小数点，尽量不修改
    uint256 public totalSupply;

    // 余额数组
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance; //2维数组限额

    //Token转移事件 This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 蒸发某个账户的token This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * 初始化 合约 Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // 小数变整数 乘18个0   Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // 初始token数量 Give the creator all initial tokens
        name = tokenName;                                   // 设置token名称  Set the name for display purposes
        symbol = tokenSymbol;                               // 设置token符号 Set the symbol for display purposes
    }

    /**
     * 赠送货币 Internal transfer, only can be called by this contract
 	付款地址，收款地址，数量
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // 确定收款地址存在  Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // 检查付款地址是否有足够的余额 Check if the sender has enough
        require(balanceOf[_from] >= _value);
        //检查收款地址收到的金额是否是负数  Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        //收款地址和付款地址的总额  Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // 付款地址中的余额-付款金额  Subtract from the sender
        balanceOf[_from] -= _value;
        // 收款地址中的余额+付款金额 Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // 判断付款行为后两个账户的总额是否发生变化   Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *从当前账户向其他账户发送token
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // 检查限额 Check allowance
        allowance[_from][msg.sender] -= _value;  //减少相应的限额
        _transfer(_from, _to, _value);  //调用调用交易，完成交易
        return true;
    }

    /**
     * 设置账户限额  Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 设置其他账户限额 Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *蒸发自己的token
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   //判断使用者的余额是否充足 Check if the sender has enough
        balanceOf[msg.sender] -= _value;            //减掉token Subtract from the sender
        totalSupply -= _value;                      //减掉总taoken数 Updates totalSupply
        emit Burn(msg.sender, _value);              //触发Burn事件
        return true;
    }

    /**
     * Destroy tokens from other account
     *蒸发别人的token
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // 检查别人的余额是否充足  Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // 检查限额是否充足 Check allowance
        balanceOf[_from] -= _value;                         // 蒸发token Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // 去除限额 Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // 减掉总taoken数Update totalSupply
        emit Burn(_from, _value);			    //触发Burn事件
        return true;
    }
}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


 contract mcs is owned, TokenERC20{

    bool public freeze=true;

    function mcs() TokenERC20(600000000, "Magicstonelink", "MCS") public {}

    function _transfer(address _from, address _to, uint _value) internal {
        require (freeze);
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
	    uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // 付款地址中的余额-付款金额  Subtract from the sender
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
        // 判断付款行为后两个账户的总额是否发生变化   Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function setfreeze(bool state) onlyOwner public{
        freeze=state;
    }
 }