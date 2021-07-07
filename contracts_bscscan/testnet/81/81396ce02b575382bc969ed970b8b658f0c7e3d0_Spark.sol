pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
pragma experimental ABIEncoderV2;
/**/
import "../IERC20.sol";
import "../Owend.sol";
contract Spark is IERC20, Owend{
    
    event LockRecord(address,uint,uint256); 
    
     event LockRelease(address,uint,uint256); 
    
    struct User{
        address userAddress;
        address recommendAddress;
        //��Ч�Ƽ��û�
        address[] effectiveAddresss;
       }
       
     
     address [] private lockAddress;
     uint [] private lockTime;
     uint256 [] private lockAmount;
        
    
    address[] private pledgeAddresss;


    mapping(address=>bool) public isEffective;
    mapping (address => uint256) public whiteList;
    mapping(address => address) public referrals;
    address[] private referralsKey;
    mapping(address => User) private users;
    mapping (address => mapping (address => uint256)) private _allowances;
    /**
     * ��ʵ��� 
     **/
    mapping (address => uint256) public reallyBalanceOf;
    /**
     * ���ֽ��
     **/
    mapping (address => uint256) public lockBalanceOf;
    /**
     * ��Ѻ���
     **/
    mapping (address => uint256) public pledgeBalanceOf;
    
 
    //��Ѻ��С�������   
    uint8 public pledgeMinLimit=50;
    //��Ѻ����ֱ����Ч����
    uint8 public minRecommends=5;
    uint256 private minEffectiveAmount=10*10**18;
    uint256 private _mintTotal=105000*10**18;
    uint256 private mintSupplyTotal=0;
    uint256 private _totalSupply=210000*10**18;
    string private _name ="Spark Token";
    string private _symbol="SPK";
    uint256 private _decimals = 18;
    uint8 public teamNumber = 30; 
    address public ownerAddress;
    
    /**
     * �ڶ���ַ 
     */
    address public blackholeAddress = 0x0000000000000000000000000000000000000000;
 
    /**
     * ��ʶ�ߵ�ַ  
     **/
    address public consensusAddress=0x848600d29E588aB042fDFe5aC050BA71949fdcc9;
    /**
     * �������ʽ�ص�ַ 
     **/
    address public liquidityPoolAddress=0x40c1799b2e62A6CA3f37B8716B6F872d9De191f4;
    
     /**
     * �����ַ 
     **/
    address public distributionAddress=0x6Ac391Cb23B5EB7868b7498f48Be21Ede38f7B4B; 
      /**
     * ��̬������ַ 
     **/
    address public dynamicRewardAddress=0x41F43cAd91f0b9fCe000D10332A9a98B67FE3dB9;
    /**
     * ���ֵ�ַ 
     **/
    address public pledgeAddress=0x1eED0c09E1531089728340ac2a801db17D294B81;
    
    constructor()public{
        ownerAddress=msg.sender;
        whiteList[msg.sender]=1;
        referrals[msg.sender]=ownerAddress;
        users[ownerAddress].userAddress = ownerAddress;
        users[ownerAddress].recommendAddress = address(0);
        reallyBalanceOf[ownerAddress] =_totalSupply/2; 
        // reallyBalanceOf[blackholeAddress]=_totalSupply/2;
        emit Transfer(address(0), ownerAddress,_totalSupply/2);
        }
    
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(reallyBalanceOf[_from]>=_value,"Balance insufficient");
        reallyBalanceOf[_from] -= _value;
        //�����߼�
           if(_from==pledgeAddress){
               
               
               reallyBalanceOf[_to] += (_value * 10/100);
               lockBalanceOf[_to] +=   (_value * 90/100);
               //������Ѻ��¼��Ϣ
                lockAddress.push(_to);
                lockTime.push(now);
                lockAmount.push(_value);
               emit LockRecord(_to,now,_value);
          }else{
                if(referrals[_to]==address(0)&&_to!=ownerAddress){
                    referrals[_to]=_from;
                    referralsKey.push(_to);
                }
                updateRecommendRelationship(_from,_to);
                if(whiteList[_from]==1||whiteList[_to]==1){
                    reallyBalanceOf[_to] += _value;
                 }else{           
                     /*��ͨ��ַ */
                    uint256 amount = _value * 90/100;
                    /*�Ƽ����� */
                    uint256 recommendRewardAmount=_value * 5/100;
                    /*��ʶ�� */
                    uint256 consensusAmount=_value * 3/100;
                    /*���� */
                    uint256 destroyAmount=_value * 2/100;
                    reallyBalanceOf[_to] += amount;
                    reallyBalanceOf[consensusAddress] += consensusAmount;
                    reallyBalanceOf[blackholeAddress] += destroyAmount;
                    updateRecommendReward(recommendRewardAmount,_from);
                    if(_mintTotal>0){
                       _mint(destroyAmount * 3);
                    }
                }
                updateTopUser(_from,_to);
         }
          updateEffectiveAccount(_to);
          updateEffectiveAccount(_from);
          emit Transfer(_from,_to,_value);
     } 
     
    function updateEffectiveAccount(address account) private{
        if(pledgeBalanceOf[account]+reallyBalanceOf[account]>minEffectiveAmount){
            isEffective[account]=true;
        }else{
            isEffective[account]=false;
        }
    }
     
     function getLockRecordByAccount() view public returns(address[] memory add,uint[] memory   time,uint256 [] memory amount){
         return(lockAddress,lockTime,lockAmount);
     }
     
     /**
      * �����Ƽ���ϵ
      **/
     function updateRecommendRelationship(address _from,address _to) private {
        User storage _users = users[_to];
        User storage _user = users[_from];
        if(_users.userAddress == address(0)){
            _users.userAddress = _to;
            _users.recommendAddress = _from;
            users[_to] = _users;
        }
        if(_user.userAddress==address(0)){
            _user.userAddress=_from;
            _user.recommendAddress=address(0);
            users[_from]=_user;
        }
     }
     /**
      * �����Ƽ�����
      **/
     function updateRecommendReward(uint256 recommendRewardAmount,address _from) private{
            //һ�� 60%������ 40%
   
            User storage _user = users[_from];
           //���㽱�� 
            uint256 oneRewardAmount = recommendRewardAmount * 60/100;
            uint256 twoRewardAmount = recommendRewardAmount * 40/100;
            User storage _oneUser = users[_user.recommendAddress];
            if(_oneUser.userAddress != address(0)){
                 reallyBalanceOf[_oneUser.userAddress] += oneRewardAmount; 
                
            }else{
                 reallyBalanceOf[ownerAddress] += oneRewardAmount;
            }
            if(_oneUser.userAddress!=address(0)){
               User storage _twoUser = users[_oneUser.recommendAddress];
              if(_twoUser.userAddress != address(0)){
                     reallyBalanceOf[_twoUser.userAddress] += twoRewardAmount; 
                }else{
                     reallyBalanceOf[ownerAddress] += oneRewardAmount;
              }
            }else{
                reallyBalanceOf[ownerAddress] += oneRewardAmount;
            }
         } 
     /**
      * �����ϼ��û���Ч��ַ����
      **/
      function updateTopUser(address _from,address _to) private{
          //������
          User storage fromUser=users[_from];
          //�����ߵ��Ƽ��˵�ַ
          if(fromUser.recommendAddress!=address(0)){
              //�����ߵ��Ƽ���
            User storage recommendUser =users[fromUser.recommendAddress];
            if(recommendUser.effectiveAddresss.length>0){
                uint index=findIndexByValue(recommendUser.effectiveAddresss,_from);
                //δ�ҵ������������������
                if(index==recommendUser.effectiveAddresss.length){
                     recommendUser.effectiveAddresss.push(_from);
                }
            }else{
                recommendUser.effectiveAddresss.push(_from);
            }
              
          }
          //������
          User storage toUser=users[_to];
          if(toUser.recommendAddress!=address(0)){
            //�����ߵ��Ƽ���
            User storage recommendUser =users[toUser.recommendAddress];    
                if(recommendUser.effectiveAddresss.length>0){
                    uint index=findIndexByValue(recommendUser.effectiveAddresss,_to);
                         //δ�ҵ������������������
                    if(index==recommendUser.effectiveAddresss.length){
                        recommendUser.effectiveAddresss.push(_to);
                        
                    }
                }else{
                    recommendUser.effectiveAddresss.push(_to);
                
                }
              }
      }
      
      
      
      
      /**
       * �ֶ�����
       **/
       function activiteAccount(address recommendAddress)  public returns(uint code){
           if(msg.sender==recommendAddress){
               return 1;
           }
           if(referrals[recommendAddress]==address(0)){
            return 1;   
           }
           if(referrals[recommendAddress]==msg.sender){
               return 1;
           }
           if(referrals[msg.sender]!=address(0)){
               return 1;
           }
           User storage _users=users[msg.sender];
           if(_users.recommendAddress!=address(0)){
              return 1; 
           }
           if(_users.userAddress==address(0)){
              _users.userAddress = msg.sender;
              _users.recommendAddress = recommendAddress;
              users[msg.sender] = _users;
           }
           referrals[msg.sender]=recommendAddress;
           referralsKey.push(msg.sender);
           return 0;
       }
       /**
        * ��ȡ�ϼ���ַ
        **/
       function getUpAddress(address account) view public returns(address,bool){
           bool isNode=false;
           if(pledgeBalanceOf[account]>=pledgeMinLimit && getEffectiveAddresssSize(account)>=minRecommends){
            isNode=true;
           }
           return (referrals[account],isNode);
       }
        
        function getEffectiveAddresssSize(address account) view public returns(uint ){
            uint count=0;
            User storage _user=users[account];
            for (uint i=0;i<_user.effectiveAddresss.length;i++){
                if(isEffective[_user.effectiveAddresss[i]]){
                    count++;
                }
            }
            return count;
        }
        /**
        * ��ȡ�¼�ֱ����Ч�û�
        **/
        function getEffectiveAddresss(address account) view public returns(address [] memory effectiveList){
             uint count=getEffectiveAddresssSize(account);
             effectiveList=new address[](count);
             uint index=0;    
             User storage _user=users[account];
              for (uint i=0;i<_user.effectiveAddresss.length;i++){
                  if(isEffective[_user.effectiveAddresss[i]]){
                    effectiveList[index]=_user.effectiveAddresss[i];
                    index++;
                  }
            }
            return effectiveList;
        }
       
       
      /**
       * ��ȡ�Ƽ���ϵ
       **/
       function getReferralsByAddress()view public   returns(address[] memory referralsKeyList,address [] memory referralsList){
        address [] memory values=new address[](referralsKey.length);  
         for(uint i=0;i<referralsKey.length;i++){
             address key=referralsKey[i];
             address addr=referrals[key];
             values[i]=addr;
         }  
         return(referralsKey,values);
       }
       
       /**
        *  ��ȡ���нڵ��ַ
        * 
        **/
       function getNodeAddresss()public view returns(address [] memory nodeAddressList){
        uint length=0;
           for(uint i=0;i<pledgeAddresss.length;i++){
                if(pledgeBalanceOf[pledgeAddresss[i]]>=pledgeMinLimit&&getEffectiveAddresssSize(pledgeAddresss[i])>=minRecommends){
                    length++;
                  }
              
            }
         nodeAddressList=new address[](length);
         uint index=0;
         for(uint i=0;i<pledgeAddresss.length;i++){
            if(pledgeBalanceOf[pledgeAddresss[i]]>=pledgeMinLimit &&getEffectiveAddresssSize(pledgeAddresss[i])>=minRecommends){
                nodeAddressList[index]=pledgeAddresss[i];
                index++;
                if(index==length){
                break;
                }
            }
         }
         
        return nodeAddressList ;
       }
     function assignNodeRewardsList(address[] memory nodeList)  onlyOwner public returns(bool){
         if(nodeList.length==0){
             return false;
         }
         uint256 nodeRewards= reallyBalanceOf[consensusAddress];
         if(nodeRewards==0){
             return false;
         }
        uint256 eachReward=nodeRewards/nodeList.length;
         for(uint i=0;i<nodeList.length;i++){
             reallyBalanceOf[nodeList[i]] += eachReward;
         }
        reallyBalanceOf[consensusAddress]-=nodeRewards;
         return true;
     }  
       
      
     /**
      *  ����ڵ㽱��
      **/
     function assignNodeRewards() public  onlyOwner returns(bool){    
   
         address [] memory tempAddress= getNodeAddresss();
         if(tempAddress.length==0){
             return false;
         }
         uint256 nodeRewards= reallyBalanceOf[consensusAddress];
         if(nodeRewards==0){
             return false;
         }
         
         uint256 eachReward=nodeRewards/tempAddress.length;
         for(uint i=0;i<tempAddress.length;i++){
             reallyBalanceOf[tempAddress[i]] += eachReward;
         }
         reallyBalanceOf[consensusAddress]-=nodeRewards;
         return true;
 
     }
     
     function setPledgeMinLimit(uint8 min) public onlyOwner returns( bool){
         if(min<=0){
             return false;
         }
         pledgeMinLimit=min;
         return true;
     }
     function setMinRecommends(uint8 min)public onlyOwner returns(bool){
         minRecommends=min;
         return true;
     }
     function setMinEffectiveAmount(uint256 min) public onlyOwner returns(bool){
         minEffectiveAmount=min;
         return true;
     }
    
     /**
      * ��Ѻ  
      **/
    function pledge(uint256 amount)  public returns(bool){
      if(reallyBalanceOf[msg.sender]<amount){
          return false;
      }
      reallyBalanceOf[msg.sender] -= amount;
      pledgeBalanceOf[msg.sender] += amount;
      uint index =findIndexByValue(pledgeAddresss,msg.sender);
      if(index==pledgeAddresss.length){
        pledgeAddresss.push(msg.sender);
      }
      updateEffectiveAccount(msg.sender);
      return true;
    }
    /**
     * ��Ѻ�ͷ� 
     **/
    function pledgeRelease(uint256 amount)  public returns(bool){
        if(pledgeBalanceOf[msg.sender]<amount){
            return false;
        }
        pledgeBalanceOf[msg.sender] -= amount;
        reallyBalanceOf[msg.sender] += amount;
        updateEffectiveAccount(msg.sender);
        return true;
     }
     
         /**
           * �����߼� 
           **/ 
        function lockAccount(address account,uint256 amount) public onlyOwner returns(bool){
            if(reallyBalanceOf[pledgeAddress]<amount){
                return false;
            }
            if(account==address(0)){
                return false;
            }
            reallyBalanceOf[pledgeAddress] -= amount;
            lockBalanceOf[account] += amount;
            emit LockRecord(account,now,amount);
            return true;
          }   
          /**
           * �����ͷ� ��Լӵ���ߵ���
           **/
        function lockRelease(address account,uint256 amount)public onlyOwner returns(bool){
             if(lockBalanceOf[account]<amount){
                 return false;
             }
             if(account==address(0)){
                 return false;
             }
             lockBalanceOf[account] -= amount;
             reallyBalanceOf[account] += amount;
             emit LockRelease(account,now,amount);
             return true;
             
         }
  
     
     
    function pledgeReleaseUseManager(address account,uint256 amount) public onlyOwner{
        require(pledgeBalanceOf[account]>=amount,"Balance insufficient");
        pledgeBalanceOf[account] -= amount;
        reallyBalanceOf[account] += amount;
    }
    
    
    
    /**
     * ����ֵѰ���±꣬�ҵ��򷵻��±꣬δ�ҵ��򷵻����鳤��
     **/
    function findIndexByValue(address[] storage list,address account) private view returns(uint index){
       for (uint i = 0; i<list.length; i++){
           if(account==list[i]){
            return i;   
           }
        }
        return list.length;
    }
   
   
    //�ݹ�֪ͨ��һ��
    function updateRecommendNumber(address _recommendAddress,uint number) private{
        User storage recommendUser = users[_recommendAddress];
        if(recommendUser.userAddress != address(0) && number <= teamNumber){
       
            number+=1;
            updateRecommendNumber(recommendUser.recommendAddress,number);
        }
    }
    
    function addWhite(address account) public onlyOwner returns(bool){
        whiteList[account]=1;
        referrals[account]=ownerAddress;
        return true;
    }
    
    function removeWhite(address account) public onlyOwner returns(bool){
        whiteList[account]=0;
        return true;
    }
    
      
    /*���ٷ�����*/
    function _burn( uint256 amount)  public onlyOwner returns (bool) {
        require(reallyBalanceOf[msg.sender]>=amount,"Balance insufficient");
        reallyBalanceOf[msg.sender] -=  amount;
        _totalSupply -=  amount;
      
        return true;
    }
    /*���ӷ��� */
   function _mint(uint256 amount) internal {
        require(ownerAddress != address(0), "BEP20: mint to the zero address");
        mintSupplyTotal += amount;
        /*20%�����������ʽ�� */
        uint256 liquidityPoolAmount=amount * 20/100;
        /*30%��������гֱ��û�*/
        uint256 distributionAmount=amount * 30/100;
        /*50%���붯̬����*/
        uint256 dynamicRewardAmount=amount * 50/100;
        
        reallyBalanceOf[liquidityPoolAddress] += liquidityPoolAmount;
        reallyBalanceOf[distributionAddress] += distributionAmount;
        reallyBalanceOf[dynamicRewardAddress] += dynamicRewardAmount;
        _mintTotal -= amount;
    
   }
     
    function updateTheAddress(address consensus,address liquidityPool, address distribution
    ,address dynamicReward,address pledgeAdd) public
     onlyOwner {
         consensusAddress=consensus;
         liquidityPoolAddress=liquidityPool;
         distributionAddress=distribution;
         dynamicRewardAddress=dynamicReward;
         pledgeAddress=pledgeAdd;
     }
 
        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

    
    /**
    * ��ȡ�����ܶ�
    **/
    function getMintTotal() view public returns(uint256) {
        return mintSupplyTotal;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

   function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return (reallyBalanceOf[account] + lockBalanceOf[account]+pledgeBalanceOf[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
             
}