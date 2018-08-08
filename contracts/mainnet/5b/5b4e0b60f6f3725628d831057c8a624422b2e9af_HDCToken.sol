pragma solidity ^0.4.18;

  // ----------------------------------------------------------------------------------------------
  // Sample fixed supply token contract
  // Enjoy. (c) BokkyPooBah 2017. The MIT Licence.
  // ----------------------------------------------------------------------------------------------

   // ERC Token Standard #20 Interface
  // https://github.com/ethereum/EIPs/issues/20
  contract ERC20Interface {
      // 获取总的支持量
      function totalSupply() constant public returns (uint256 _totalSupply);

      // 获取其他地址的余额
      function balanceOf(address _owner) constant public returns (uint256 balance);

      // 向其他地址发送token
      function transfer(address _to, uint256 _value) public returns (bool success);

      // 从一个地址想另一个地址发送余额
      function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

      //允许_spender从你的账户转出_value的余额，调用多次会覆盖可用量。某些DEX功能需要此功能
      function approve(address _spender, uint256 _value) public returns (bool success);

      // 返回_spender仍然允许从_owner退出的余额数量
      function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

      // token转移完成后出发
      event Transfer(address indexed _from, address indexed _to, uint256 _value);

      // approve(address _spender, uint256 _value)调用后触发
      event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  }

   //继承接口后的实例
   contract HDCToken is ERC20Interface {
      string public constant symbol = "HDCT"; //单位
      string public constant name = "Health Data Chain Token"; //名称
      uint8 public constant decimals = 18; //小数点后的位数
      uint256 _totalSupply = 10000000000000000000000000000; //发行总量

      // 智能合约的所有者
      address public owner;

      // 每个账户的余额
      mapping(address => uint256) balances;

      // 帐户的所有者批准将金额转入另一个帐户。从上面的说明我们可以得知allowed[被转移的账户][转移钱的账户]
      mapping(address => mapping (address => uint256)) allowed;

      // 只能通过智能合约的所有者才能调用的方法
      modifier onlyOwner() {
          require (msg.sender != owner);
          _;
      }

	  bool public paused = false;

      /**
       * @dev Modifier to make a function callable only when the contract is not paused.
       */
      modifier whenNotPaused() {
        require(!paused);
        _;
      }
    
      /**
       * @dev Modifier to make a function callable only when the contract is paused.
       */
      modifier whenPaused() {
        require(paused);
        _;
      }
    
      /**
       * @dev called by the owner to pause, triggers stopped state
       */
      function pause() onlyOwner whenNotPaused public {
        paused = true;
      }
    
      /**
       * @dev called by the owner to unpause, returns to normal state
       */
      function unpause() onlyOwner whenPaused public {
        paused = false;
      }
  
      // 构造函数
      constructor () public {
          owner = msg.sender;
          balances[owner] = _totalSupply;
      }

      function  totalSupply() public constant returns (uint256 totalSupplyRet) {
          totalSupplyRet = _totalSupply;
      }

      // 特定账户的余额
      function balanceOf(address _owner) public constant returns (uint256 balance) {
          return balances[_owner];
      }

      // 转移余额到其他账户
      function transfer(address _to, uint256 _amount) public whenNotPaused returns (bool success) {
          require(_to != address(0x0) );

          require (balances[msg.sender] >= _amount 
              && _amount > 0
              && balances[_to] + _amount > balances[_to]); 
              
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
      }

      //从一个账户转移到另一个账户，前提是需要有允许转移的余额
      function transferFrom(
          address _from,
          address _to,
          uint256 _amount
      ) public whenNotPaused returns (bool success) {
          require(_to != address(0x0) );
          
          require (balances[_from] >= _amount
              && allowed[_from][msg.sender] >= _amount
              && _amount > 0
              && balances[_to] + _amount > balances[_to]);
              
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
      }

      //允许账户从当前用户转移余额到那个账户，多次调用会覆盖
      function approve(address _spender, uint256 _amount) public whenNotPaused returns (bool success) {
          allowed[msg.sender][_spender] = _amount;
          emit Approval(msg.sender, _spender, _amount);
          return true;
      }

      //返回被允许转移的余额数量
      function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
      }
  }