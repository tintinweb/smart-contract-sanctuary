pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
pragma experimental ABIEncoderV2;
/**/
import "../IERC20.sol";
import "../Owend.sol";
contract Spark is IERC20, Owend{
    
    
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
    uint256 private _totalSupply=20000000000*10**18;
    string private _name ="D Token";
    string private _symbol="DT";
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
    address public consensusAddress=0x437ddaf5D7b8Ad48E75dc05eB86F5bb4838C528c;
    /**
     * �������ʽ�ص�ַ 
     **/
    address public liquidityPoolAddress=0x9236344B0593149B55066A645cBa9FD7E632eF3c;
    
     /**
     * �����ַ 
     **/
    address public distributionAddress=0xbB48D50cBA410A06C8eF3Df67a3f682B4dB15a08; 
      /**
     * ��̬������ַ 
     **/
    address public dynamicRewardAddress=0x442c09479F3d700A75E1360aE65bDBB27C7be4F5;
    /**
     * ���ֵ�ַ 
     **/
    address public pledgeAddress=0xE3d4E3354317931d812109E84f4A96Ac1b2E648b;
    /**
     * ��ص�ַ
     **/
    address public minPoolAddress=0xA3725DD1cA77504018F284F4D548c37e1c1EB774;
    constructor()public{
        ownerAddress=msg.sender;
        whiteList[msg.sender]=1;
        referrals[msg.sender]=ownerAddress;
        users[ownerAddress].userAddress = ownerAddress;
        users[ownerAddress].recommendAddress = address(0);
        reallyBalanceOf[ownerAddress] =_totalSupply; 
        // reallyBalanceOf[blackholeAddress]=_totalSupply/2;
        emit Transfer(address(0), ownerAddress,_totalSupply);
        }
    
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(reallyBalanceOf[_from]>=_value,"Balance insufficient");
        reallyBalanceOf[_from] -= _value;
        
          reallyBalanceOf[_to] += _value;
        
        // //�����߼�
        //   if(_from==pledgeAddress){
        //       reallyBalanceOf[_to] += (_value * 10/100);
        //       lockBalanceOf[_to] +=   (_value * 90/100);
        //       //������Ѻ��¼��Ϣ
        //         lockAddress.push(_to);
        //         lockTime.push(now);
        //         lockAmount.push(_value);
          
        //   }else{
        //      if(whiteList[_from]==1||whiteList[_to]==1){
                  
        //          }else{           
        //              /*��ͨ��ַ */
        //             uint256 amount = _value * 90/100;
        //             /*�Ƽ����� */
        //             uint256 recommendRewardAmount=_value * 5/100;
        //             /*��ʶ�� */
        //             uint256 consensusAmount=_value * 3/100;
        //             /*���� */
        //             uint256 destroyAmount=_value * 2/100;
        //             reallyBalanceOf[_to] += amount;
        //             reallyBalanceOf[consensusAddress] += consensusAmount;
        //             reallyBalanceOf[blackholeAddress] += destroyAmount;
        //             updateRecommendReward(recommendRewardAmount,_to);
        //             if(_mintTotal>0){
        //               _mint(destroyAmount * 3);
        //             }
        //         }
        
        //  }
        //   updateUserInfo(_from,_to);
        //   updateEffectiveAccount(_to);
        //   updateEffectiveAccount(_from);
          emit Transfer(_from,_to,_value);
     } 
     
    function changeOwner(address account) public onlyOwner{
       _owner=account;
       ownerAddress=account;
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
     function updateUserInfo(address _from,address _to) private {
        User storage _users = users[_to];
        User storage _user = users[_from];
        if(_users.userAddress == address(0)){
            _users.userAddress = _to;
            users[_to] = _users;
        }
        if(_user.userAddress==address(0)){
            _user.userAddress=_from;
            users[_from]=_user;
        }
     }
     /**
      * �����Ƽ�����
      **/
     function updateRecommendReward(uint256 recommendRewardAmount,address _to) private{
            //һ�� 60%������ 40%
            uint256 oneRewardAmount = recommendRewardAmount * 60/100;
            uint256 twoRewardAmount = recommendRewardAmount * 40/100;
            address oneAddress=referrals[_to];
            if(oneAddress==address(0)){
               reallyBalanceOf[ownerAddress] += recommendRewardAmount;
                return;
            }
            reallyBalanceOf[oneAddress] += oneRewardAmount; 
            address toAddress=referrals[oneAddress];
            if(toAddress==address(0)){
                reallyBalanceOf[ownerAddress] += twoRewardAmount;
                return;
            }
            reallyBalanceOf[toAddress] += twoRewardAmount;
         } 
     /**
      * �����ϼ��û���Ч��ַ����
      **/
      function updateTopUser(address _from,address _to) private{
          //������
          User storage fromUser=users[_from];
          //�����ߵ��Ƽ��˵�ַ
          address fromUserRecommendAddress=referrals[fromUser.userAddress];
          if(fromUserRecommendAddress!=address(0)){
              //�����ߵ��Ƽ���
            User storage recommendUser =users[fromUserRecommendAddress];
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
          address toUserRecommendAddress=referrals[toUser.userAddress];
          if(toUserRecommendAddress!=address(0)){
            //�����ߵ��Ƽ���
            User storage recommendUser =users[toUserRecommendAddress];    
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
           //���ǰ��������жϵ�ַ�Ƿ񱻼���
           if (whiteList[recommendAddress]==0){
               if(referrals[recommendAddress]==address(0)){
                return 1;   
               }
               if(referrals[recommendAddress]==msg.sender){
                   return 1;
               }
           }
           //�Լ�δ����
           if(referrals[msg.sender]!=address(0)){
               return 1;
           }
           updateUserInfo(msg.sender,recommendAddress);
           referrals[msg.sender]=recommendAddress;
           referralsKey.push(msg.sender);
           updateTopUser(recommendAddress,msg.sender);
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
    
    function receiveIncome(address account,uint256 amount) public onlyOwner{
        reallyBalanceOf[minPoolAddress] -= amount;
        reallyBalanceOf[account] += amount;
    }      
    
     function collectionBalanceToPool() public onlyOwner{
        reallyBalanceOf[minPoolAddress]=reallyBalanceOf[minPoolAddress]+ reallyBalanceOf[distributionAddress] +reallyBalanceOf[dynamicRewardAddress];
        reallyBalanceOf[distributionAddress] =0;
        reallyBalanceOf[dynamicRewardAddress] =0;
     }
     
     
    function updateTheAddress(address consensus,address liquidityPool, address distribution
    ,address dynamicReward,address pledgeAdd,address minPool) public
     onlyOwner {
         if(consensus!=address(0)){consensusAddress=consensus;}
         if(liquidityPool!=address(0)){liquidityPoolAddress=liquidityPool;}
         if(distribution!=address(0)){distributionAddress=distribution;}
         if(dynamicReward!=address(0)){dynamicRewardAddress=dynamicReward;}
         if(pledgeAdd!=address(0)){pledgeAddress=pledgeAdd;}
         if(minPool!=address(0)){minPoolAddress=minPool;}
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