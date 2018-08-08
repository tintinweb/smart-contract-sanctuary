pragma solidity ^0.4.21;
/**
 * Overflow aware uint math functions.
 *
 * Inspired by https://github.com/MakerDAO/maker-otc/blob/master/contracts/simple_market.sol
 */
contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Burn(address indexed _from, uint256 _value);
}




/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is SafeMath {

    /**
     * Reviewed:
     * - Interger overflow = OK, checked
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(_to != 0X0);

        // 如果 from 地址中 没有那么多的 token， 停止交易
        // 如果 这个转账 数量 是 负数， 停止交易
        if (balances[msg.sender] >= _value && balances[msg.sender] - _value < balances[msg.sender]) {

            // sender的户头 减去 对应token的数量， 使用 safemath 交易
            balances[msg.sender] = super.safeSub(balances[msg.sender], _value);
            // receiver的户头 增加 对应token的数量， 使用 safemath 交易
            balances[_to] = super.safeAdd(balances[_to], _value);

            emit Transfer(msg.sender, _to, _value);//呼叫event
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(_to != 0X0);

        // 如果 from 地址中 没有那么多的 token， 停止交易
        // 如果 from 地址的owner， 给这个msg.sender的权限没有这么多的token，停止交易
        // 如果 这个转账 数量 是 负数， 停止交易
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_from] - _value < balances[_from]) {

            // 该 交易sender 对 from账户的可用权限 减少 相对应的 数量， 使用 safemath 交易
            allowed[_from][msg.sender] = super.safeSub(allowed[_from][msg.sender], _value);
            // from的户头 减去 对应token的数量， 使用 safemath 交易
            balances[_from] = super.safeSub(balances[_from], _value);
            // to的户头 增加 对应token的数量， 使用 safemath 交易
            balances[_to] = super.safeAdd(balances[_to], _value);

            emit Transfer(_from, _to, _value);//呼叫event
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // 该交易的 msg.sender 可以设置 别的spender地址权限
        // 允许spender地址可以使用 msg.sender 地址下的一定数量的token
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      // 查看 spender 能控制 多少个 owner 账户下的token
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
}










/*******************************************************************************
 *
 * Artchain Token  智能合约.
 *
 * version 15, 2018-05-28
 *
 ******************************************************************************/
contract ArtChainToken is StandardToken {

    // 我们token的名字， 部署以后不可更改
    string public constant name = "Artchain Global Token";

    // 我们token的代号， 部署以后不可更改
    string public constant symbol = "ACG";

    // 我们的 contract 部署的时候 之前已经有多少数量的 block
    uint public startBlock;

    //支持 小数点后8位的交易。 e.g. 最小交易量 0.00000001 个 token
    uint public constant decimals = 8;

    // 我们的 token 的总共的数量 (不用在意 *10**uint(decimals))
    uint256 public totalSupply = 3500000000*10**uint(decimals); // 35亿


    // founder账户 - 地址可以更改
    address public founder = 0x3b7ca9550a641B2bf2c60A0AeFbf1eA48891e58b;
    // 部署该合约时，founder_token = founder
    // 相对应的 token 被存入(并根据规则锁定)在这个账户中
    // 更改 founder 地址， token 将保留在 founder_token 地址的中，不会被转移
    // 该 founder_token 的地址在合约部署后将不能被更改，该地址下的token只能按照既定的规则释放
    address public constant founder_token = 0x3b7ca9550a641B2bf2c60A0AeFbf1eA48891e58b;// founder_token=founder;


    // 激励团队poi账户 - 地址可以更改
    address public poi = 0x98d95A8178ff41834773D3D270907942F5BE581e;
    // 部署该合约时，poi_token = poi
    // 相对应的 token 被存入(并根据规则锁定)在这个账户中
    // 更改 poi 地址， token 将保留在 poi_token 地址的中，不会被转移
    // 该 poi_token 的地址在合约部署后将不能被更改， 该地址下的token只能按照既定的规则释放
    address public constant poi_token = 0x98d95A8178ff41834773D3D270907942F5BE581e; // poi_token=poi


    // 用于私募的账户, 合约部署后不可更改，但是 token 可以随意转移 没有限制
    address public constant privateSale = 0x31F2F3361e929192aB2558b95485329494955aC4;


    // 用于冷冻账户转账/交易
    // 大概每14秒产生一个block， 根据block的数量， 确定冷冻的时间，
    // 产生 185143 个 block 大约需要一个月时间
    uint public constant one_month = 185143;// ----   时间标准
    uint public poiLockup = super.safeMul(uint(one_month), 7);  // poi 账户 冻结的时间 7个月

    // 用于 暂停交易， 只能 founder 账户 才可以更改这个状态
    bool public halted = false;



    /*******************************************************************
     *
     *  部署合约的 主体
     *
     *******************************************************************/
    function ArtChainToken() public {
    //constructor() public {

        // 部署该合约的时候  startBlock等于最新的 block的数量
        startBlock = block.number;

        // 给founder 20% 的 token， 35亿的 20% 是7亿  (不用在意 *10**uint(decimals))
        balances[founder] = 700000000*10**uint(decimals); // 7亿

        // 给poi账户 40% 的 token， 35亿的 40% 是14亿
        balances[poi] = 1400000000*10**uint(decimals);   // 14亿

        // 给私募账户 40% 的 token， 35亿的 40% 是14亿
        balances[privateSale] = 1400000000*10**uint(decimals); // 14亿
    }


    /*******************************************************************
     *
     *  紧急停止所有交易， 只能 founder 账户可以运行
     *
     *******************************************************************/
    function halt() public returns (bool success) {
        if (msg.sender!=founder) return false;
        halted = true;
        return true;
    }
    function unhalt() public returns (bool success) {
        if (msg.sender!=founder) return false;
        halted = false;
        return true;
    }


    /*******************************************************************
     *
     * 修改founder/poi的地址， 只能 “现founder” 可以修改
     *
     * 但是 token 还是存在 founder_token 和 poi_token下
     *
     *******************************************************************/
    function changeFounder(address newFounder) public returns (bool success){
        // 只有 "现founder" 可以更改 Founder的地址
        if (msg.sender!=founder) return false;
        founder = newFounder;
        return true;
    }
    function changePOI(address newPOI) public returns (bool success){
        // 只有 "现founder" 可以更改 poi的地址
        if (msg.sender!=founder) return false;
        poi = newPOI;
        return true;
    }




    /********************************************************
     *
     *  转移 自己账户中的 token （需要满足 冻结规则的 前提下）
     *
     ********************************************************/
    function transfer(address _to, uint256 _value) public returns (bool success) {

      // 如果 现在是 ”暂停交易“ 状态的话， 拒绝交易
      if (halted==true) return false;

      // poi_token 中的 token， 判断是否在冻结时间内 冻结时间为一年， 也就是 poiLockup 个block的时间
      if (msg.sender==poi_token && block.number <= startBlock + poiLockup)  return false;

      // founder_token 中的 token， 根据规则分为48个月释放（初始状态有7亿）
      if (msg.sender==founder_token){
        // 前6个月 不能动 founder_token 账户的 余额 要维持 100% (7亿的100% = 7亿)
        if (block.number <= startBlock + super.safeMul(uint(one_month), 6)  && super.safeSub(balanceOf(msg.sender), _value)<700000000*10**uint(decimals)) return false;
        // 6个月到12个月  founder_token 账户的 余额 至少要 85% (7亿的85% = 5亿9千5百万)
        if (block.number <= startBlock + super.safeMul(uint(one_month), 12) && super.safeSub(balanceOf(msg.sender), _value)<595000000*10**uint(decimals)) return false;
        // 12个月到18个月 founder_token 账户的 余额 至少要 70% (7亿的70% = 4亿9千万)
        if (block.number <= startBlock + super.safeMul(uint(one_month), 18) && super.safeSub(balanceOf(msg.sender), _value)<490000000*10**uint(decimals)) return false;
        // 18个月到24个月 founder_token 账户的 余额 至少要 57.5% (7亿的57.5% = 4亿0千2百5十万)
        if (block.number <= startBlock + super.safeMul(uint(one_month), 24) && super.safeSub(balanceOf(msg.sender), _value)<402500000*10**uint(decimals)) return false;
        // 24个月到30个月 founder_token 账户的 余额 至少要 45% (7亿的45% = 3亿1千5百万)
        if (block.number <= startBlock + super.safeMul(uint(one_month), 30) && super.safeSub(balanceOf(msg.sender), _value)<315000000*10**uint(decimals)) return false;
        // 30个月到36个月 founder_token 账户的 余额 至少要 32.5% (7亿的32.5% = 2亿2千7百5十万)
        if (block.number <= startBlock + super.safeMul(uint(one_month), 36) && super.safeSub(balanceOf(msg.sender), _value)<227500000*10**uint(decimals)) return false;
        // 36个月到42个月 founder_token 账户的 余额 至少要 20% (7亿的20% = 1亿4千万)
        if (block.number <= startBlock + super.safeMul(uint(one_month), 42) && super.safeSub(balanceOf(msg.sender), _value)<140000000*10**uint(decimals)) return false;
        // 42个月到48个月 founder_token 账户的 余额 至少要 10% (7亿的10% = 7千万)
        if (block.number <= startBlock + super.safeMul(uint(one_month), 48) && super.safeSub(balanceOf(msg.sender), _value)< 70000000*10**uint(decimals)) return false;
        // 48个月以后 没有限制
      }

      //其他情况下， 正常进行交易
      return super.transfer(_to, _value);
    }

    /********************************************************
     *
     *  转移 别人账户中的 token （需要满足 冻结规则的 前提下）
     *
     ********************************************************/
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // 如果 现在是 ”暂停交易“ 状态的话， 拒绝交易
        if (halted==true) return false;

        // poi_token 中的 token， 判断是否在冻结时间内 冻结时间为一年， 也就是 poiLockup 个block的时间
        if (_from==poi_token && block.number <= startBlock + poiLockup) return false;

        // founder_token 中的 token， 根据规则分为48个月释放（初始状态有7亿）
        if (_from==founder_token){
          // 前6个月 不能动 founder_token 账户的 余额 要维持 100% (7亿的100% = 7亿)
          if (block.number <= startBlock + super.safeMul(uint(one_month), 6)  && super.safeSub(balanceOf(_from), _value)<700000000*10**uint(decimals)) return false;
          // 6个月到12个月  founder_token 账户的 余额 至少要 85% (7亿的85% = 5亿9千5百万)
          if (block.number <= startBlock + super.safeMul(uint(one_month), 12) && super.safeSub(balanceOf(_from), _value)<595000000*10**uint(decimals)) return false;
          // 12个月到18个月 founder_token 账户的 余额 至少要 70% (7亿的70% = 4亿9千万)
          if (block.number <= startBlock + super.safeMul(uint(one_month), 18) && super.safeSub(balanceOf(_from), _value)<490000000*10**uint(decimals)) return false;
          // 18个月到24个月 founder_token 账户的 余额 至少要 57.5% (7亿的57.5% = 4亿0千2百5十万)
          if (block.number <= startBlock + super.safeMul(uint(one_month), 24) && super.safeSub(balanceOf(_from), _value)<402500000*10**uint(decimals)) return false;
          // 24个月到30个月 founder_token 账户的 余额 至少要 45% (7亿的45% = 3亿1千5百万)
          if (block.number <= startBlock + super.safeMul(uint(one_month), 30) && super.safeSub(balanceOf(_from), _value)<315000000*10**uint(decimals)) return false;
          // 30个月到36个月 founder_token 账户的 余额 至少要 32.5% (7亿的32.5% = 2亿2千7百5十万)
          if (block.number <= startBlock + super.safeMul(uint(one_month), 36) && super.safeSub(balanceOf(_from), _value)<227500000*10**uint(decimals)) return false;
          // 36个月到42个月 founder_token 账户的 余额 至少要 20% (7亿的20% = 1亿4千万)
          if (block.number <= startBlock + super.safeMul(uint(one_month), 42) && super.safeSub(balanceOf(_from), _value)<140000000*10**uint(decimals)) return false;
          // 42个月到48个月 founder_token 账户的 余额 至少要 10% (7亿的10% = 7千万)
          if (block.number <= startBlock + super.safeMul(uint(one_month), 48) && super.safeSub(balanceOf(_from), _value)< 70000000*10**uint(decimals)) return false;
          // 48个月以后 没有限制
        }

        //其他情况下， 正常进行交易
        return super.transferFrom(_from, _to, _value);
    }









    /***********************************************************、、
     *
     * 销毁 自己账户内的 tokens
     *
     ***********************************************************/
    function burn(uint256 _value) public returns (bool success) {

      // 如果 现在是 ”暂停交易“ 状态的话， 拒绝交易
      if (halted==true) return false;

      // poi_token 中的 token， 判断是否在冻结时间内 冻结时间为 poiLockup 个block的时间
      if (msg.sender==poi_token && block.number <= startBlock + poiLockup) return false;

      // founder_token 中的 token， 不可以被销毁
      if (msg.sender==founder_token) return false;


      //如果 该账户 不足 输入的 token 数量， 终止交易
      if (balances[msg.sender] < _value) return false;
      //如果 要销毁的 _value 是负数， 终止交易
      if (balances[msg.sender] - _value > balances[msg.sender]) return false;


      // 除了以上的 情况， 下面进行 销毁过程

      // 账户token数量减小， 使用 safemath
      balances[msg.sender] = super.safeSub(balances[msg.sender], _value);
      // 由于账户token数量 被销毁， 所以 token的总数量也会减少， 使用 safemath
      totalSupply = super.safeSub(totalSupply, _value);

      emit Burn(msg.sender, _value); //呼叫event

      return true;

    }




    /***********************************************************、、
     *
     * 销毁 别人账户内的 tokens
     *
     ***********************************************************/
    function burnFrom(address _from, uint256 _value) public returns (bool success) {

      // 如果 现在是 ”暂停交易“ 状态的话， 拒绝交易
      if (halted==true) return false;

      // 如果 要销毁 poi_token 中的 token，
      // 需要判断是否在冻结时间内 （冻结时间为 poiLockup 个block的时间）
      if (_from==poi_token && block.number <= startBlock + poiLockup) return false;

      // 如果要销毁 founder_token 下的 token， 停止交易
      // founder_token 中的 token， 不可以被销毁
      if (_from==founder_token) return false;


      //如果 该账户 不足 输入的 token 数量， 终止交易
      if (balances[_from] < _value) return false;
      //如果 该账户 给这个 msg.sender 的权限不足 输入的 token 数量， 终止交易
      if (allowed[_from][msg.sender] < _value) return false;
      //如果 要销毁的 _value 是负数， 终止交易
      if (balances[_from] - _value > balances[_from]) return false;


      // 除了以上的 情况， 下面进行 销毁过程

      // from账户中 msg.sender可以支配的 token数量 也减少， 使用 safemath
      allowed[_from][msg.sender] = super.safeSub(allowed[_from][msg.sender], _value);
      // 账户token数量减小， 使用 safemath
      balances[_from] = super.safeSub(balances[_from], _value);
      // 由于账户token数量 被销毁， 所以 token的总数量也会减少， 使用 safemath
      totalSupply = super.safeSub(totalSupply, _value);

      emit Burn(_from, _value); //呼叫 event

      return true;
  }
}