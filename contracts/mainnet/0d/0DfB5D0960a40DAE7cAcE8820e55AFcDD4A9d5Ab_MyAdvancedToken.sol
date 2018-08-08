pragma solidity ^0.4.13; 

contract owned {
    address public owner;
    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    /* 管理者的权限可以转移 */
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
  }
contract tokenRecipient {
     function receiveApproval(address from, uint256 value, address token, bytes extraData); 
}
contract token {
    /*Public variables of the token */
    string public name; string public symbol; uint8 public decimals; uint256 public totalSupply;
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function token() {
    balanceOf[msg.sender] = 10000000000000000; // 给创建者所有初始令牌
    totalSupply = 10000000000000000; // 更新总量
    name = "BBC"; // 设置显示的名称
    symbol =  "฿"; // 为显示设置符号
    decimals = 8; // 显示的小数量
    }
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0); // 防止转移到0x0地址. Use burn() instead
        require (balanceOf[_from] > _value); // 检测余额是否足够
        require (balanceOf[_to] + _value > balanceOf[_to]); // 检查溢出
        balanceOf[_from] -= _value; // 从发件人中减去
        balanceOf[_to] += _value; // 给收件人添加
        Transfer(_from, _to, _value);
    }
    /// @notice Send `_value` tokens to `_to` from your account
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }
    /// @notice Send `_value` tokens to `_to` in behalf of `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (_value < allowance[_from][msg.sender]); // 检测手续费
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    ///让另一个合同，为你花一些令牌
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    ///批准并在一个TX中传递批准的合同
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
        }
    }
    /// @notice Remove `_value` tokens from the system irreversibly
    /// @param _value the amount of money to burn
    function burn(uint256 _value) returns (bool success) {
        require (balanceOf[msg.sender] > _value); // Check if the sender has enough
        balanceOf[msg.sender] -= _value; // Subtract from the sender
        totalSupply -= _value; // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        require(balanceOf[_from] >= _value); // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        balanceOf[_from] -= _value; // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value; // Subtract from the sender&#39;s allowance
        totalSupply -= _value; // Update totalSupply
        Burn(_from, _value);
        return true;
      }
   }

contract MyAdvancedToken is owned, token {
    mapping (address => bool) public frozenAccount;
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    /* 初始化合约 */
    function MyAdvancedToken() token () {}
    /* 代币转移 */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0); // 防止转移到0x0地址
        // 发送方和接收方应该不同
        require(msg.sender != _to);
        require (balanceOf[_from] > _value); // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // 检查溢出    
        require(!frozenAccount[_from]); // Check if sender is frozen
        require(!frozenAccount[_to]); // Check if recipient is frozen
        balanceOf[_from] -= _value; // Subtract from the sender
        balanceOf[_to] += _value; // Add the same to the recipient
        Transfer(_from, _to, _value);
    }
    /* 冻结账户 */
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    }