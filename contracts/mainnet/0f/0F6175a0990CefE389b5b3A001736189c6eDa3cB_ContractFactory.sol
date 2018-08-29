pragma solidity ^0.4.13;

/**
 * @title Ownable
 * @dev 本可拥有合同业主地址，并提供基本的权限控制功能，简化了用户的权限执行”。
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner {
    selfdestruct(_recipient);
  }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }

  /**
  * @dev withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }
}

contract Generatable{
    function generate(
        address token,
        address contractOwner,
        uint256 cycle
    ) public returns(address);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function decimals() public view returns (uint8);  //代币单位
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20 _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}


contract ContractFactory is Destructible,PullPayment{
    using SafeERC20 for ERC20;
    uint256 public diviRate;
    uint256 public developerTemplateAmountLimit;
    address public platformWithdrawAccount;


	struct userContract{
		uint256 templateId;
		uint256 orderid;
		address contractAddress;
		uint256 incomeDistribution;
		uint256 creattime;
		uint256 endtime;
	}

	struct contractTemplate{
		string templateName;
		address contractGeneratorAddress;
		string abiStr;
		uint256 startTime;
		uint256 endTime;
		uint256 startUp;
		uint256 profit;
		uint256 quota;
		uint256 cycle;
		address token;
	}

    mapping(address => userContract[]) public userContractsMap;
    mapping(uint256 => contractTemplate) public contractTemplateAddresses;
    mapping(uint256 => uint256) public skipMap;

    event ContractCreated(address indexed creator,uint256 templateId,uint256 orderid,address contractAddress);
    event ContractTemplatePublished(uint256 indexed templateId,address  creator,string templateName,address contractGeneratorAddress);
    event Log(address data);
    event yeLog(uint256 balanceof);
    function ContractFactory(){
        //0~10
        diviRate=5;
        platformWithdrawAccount=0xc645eadc9188cb0bad4e603f78ff171dabc1b18b;
        developerTemplateAmountLimit=500000000000000000;
    }

    function generateContract(uint256 templateId,uint256 orderid) public returns(address){

        //根据支付金额找到相应模板
        contractTemplate storage ct = contractTemplateAddresses[templateId];
        if(ct.contractGeneratorAddress!=0x0){
            address contractTemplateAddress = ct.contractGeneratorAddress;
            string templateName = ct.templateName;
            require(block.timestamp >= ct.startTime);
            require(block.timestamp <= ct.endTime);
            //找到相应生成器并生产目标合约
            Generatable generator = Generatable(contractTemplateAddress);
            address target = generator.generate(ct.token,msg.sender,ct.cycle);
            //记录用户合约
            userContract[] storage userContracts = userContractsMap[msg.sender];
            userContracts.push(userContract(templateId,orderid,target,1,now,now.add(uint256(1 days))));
            ContractCreated(msg.sender,templateId,orderid,target);
            return target;
        }else{
            revert();
        }
    }

    function returnOfIncome(address user,uint256 _index) public{
        require(msg.sender == user);
        userContract[] storage ucs = userContractsMap[user];
        if(ucs[_index].contractAddress!=0x0 && ucs[_index].incomeDistribution == 1){
            contractTemplate storage ct = contractTemplateAddresses[ucs[_index].templateId];
            if(ct.contractGeneratorAddress!=0x0){
                //如果大于激活时间1天将不能分红
                if(now > ucs[_index].creattime.add(uint256(1 days))){
                     revert();
                }

                ERC20 token = ERC20(ct.token);
                uint256 balanceof = token.balanceOf(ucs[_index].contractAddress);

               uint8 decimals = token.decimals();
                //需要大于起投价
                if(balanceof < ct.startUp) revert();
                //大于限额的按限额上线计算收益
                uint256 investment = 0;
                if(balanceof > ct.quota.mul(10**decimals)){
                    investment = ct.quota.mul(10**decimals);
                } else {
                    investment = balanceof;
                }

                //需要转给子合约的收益
                uint256 income = ct.profit.mul(ct.cycle).mul(investment).div(36000);


                if(!token.transfer(ucs[_index].contractAddress,income)){
        			revert();
        		} else {
        		    ucs[_index].incomeDistribution = 2;
        		}
            }else{
                revert();
            }
        }else{
            revert();
        }
    }

    /**
    *生成器实现Generatable接口,并且合约实现了ownerable接口，都可以通过此函数上传（TODO：如何校验？）
    * @param templateId   模版Id
    * @param _templateName   模版名称
    * @param _contractGeneratorAddress   模版名称模版名称莫
    * @param _abiStr   abi接口
    * @param _startTime  开始时间
    * @param _endTime   结束时间
    * @param _profit  收益
    * @param _startUp 起投
    * @param _quota   限额
    * @param _cycle   周期
    * @param _token   代币合约
    */
    function publishContractTemplate(
        uint256 templateId,
        string _templateName,
        address _contractGeneratorAddress,
        string _abiStr,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _profit,
        uint256 _startUp,
        uint256 _quota,
        uint256 _cycle,
        address _token
    )
        public
    {
         //非owner，不允许发布模板
         if(msg.sender!=owner){
            revert();
         }

         contractTemplate storage ct = contractTemplateAddresses[templateId];
         if(ct.contractGeneratorAddress!=0x0){
            revert();
         }else{

            ct.templateName = _templateName;
            ct.contractGeneratorAddress = _contractGeneratorAddress;
            ct.abiStr = _abiStr;
            ct.startTime = _startTime;
            ct.endTime = _endTime;
            ct.startUp = _startUp;
            ct.profit = _profit;
            ct.quota = _quota;
            ct.cycle = _cycle;
            ct.token = _token;
            ContractTemplatePublished(templateId,msg.sender,_templateName,_contractGeneratorAddress);
         }
    }

    function queryPublishedContractTemplate(
        uint256 templateId
    )
        public
        constant
    returns(
        string,
        address,
        string,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) {
        contractTemplate storage ct = contractTemplateAddresses[templateId];
        if(ct.contractGeneratorAddress!=0x0){
            return (
                ct.templateName,
                ct.contractGeneratorAddress,
                ct.abiStr,
                ct.startTime,
                ct.endTime,
                ct.profit,
                ct.startUp,
                ct.quota,
                ct.cycle,
                ct.token
            );
        }else{
            return (&#39;&#39;,0x0,&#39;&#39;,0,0,0,0,0,0,0x0);
        }
    }


    function queryUserContract(address user,uint256 _index) public constant returns(
        uint256,
        uint256,
        address,
        uint256,
        uint256,
        uint256
    ){
        require(msg.sender == user);
        userContract[] storage ucs = userContractsMap[user];
        contractTemplate storage ct = contractTemplateAddresses[ucs[_index].templateId];
        ERC20 tokens = ERC20(ct.token);
        uint256 balanceofs = tokens.balanceOf(ucs[_index].contractAddress);
        return (
            ucs[_index].templateId,
            ucs[_index].orderid,
            ucs[_index].contractAddress,
            ucs[_index].incomeDistribution,
            ucs[_index].endtime,
            balanceofs
        );
    }

    function queryUserContractCount(address user) public constant returns (uint256){
        require(msg.sender == user);
        userContract[] storage ucs = userContractsMap[user];
        return ucs.length;
    }

    function changeDiviRate(uint256 _diviRate) external onlyOwner(){
        diviRate=_diviRate;
    }

    function changePlatformWithdrawAccount(address _platformWithdrawAccount) external onlyOwner(){
        platformWithdrawAccount=_platformWithdrawAccount;
    }

    function changeDeveloperTemplateAmountLimit(uint256 _developerTemplateAmountLimit) external onlyOwner(){
        developerTemplateAmountLimit=_developerTemplateAmountLimit;
    }
    function addSkipPrice(uint256 price) external onlyOwner(){
        skipMap[price]=1;
    }

    function removeSkipPrice(uint256 price) external onlyOwner(){
        skipMap[price]=0;
    }
}