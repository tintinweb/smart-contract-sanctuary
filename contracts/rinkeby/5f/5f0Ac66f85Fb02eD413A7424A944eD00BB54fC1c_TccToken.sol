// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./ERC721.sol";
import "./Ownable.sol";
contract TccToken is ERC721,Ownable {
    
    // using Strings for string;
    address public witContract;
    
    uint8 public constant witDecimals = 18;
    
    uint public overdueDay =3;
    
    string public coinName;
    string public symbolName;
    string public baseUrl;
    struct Repayment {

        uint repaymenId; //期数
        uint amount; //应收金额
        uint plantDate; //应收日期
        uint status; //回款状态: 0-未回款,1-已回款
        uint actualDate; //回款实际时间
        address payee; //收款人
        address payer; //付款人

    }


    /*
    租约的详细信息info由json字符串组成，并经过js的encodeURIComponent()转换编码后再存入
    info: {
    "landlord":"张三",//房东姓名
    "province":"广东省",//省
    "city":"深圳市",//市
    "region":"南山区",//区
    "street":"月亮湾路",//街道
    "address":"海边大厦13号",//地址
    "operator":"科技公司",//运营商
    "huxing":"三室一厅",//户型
    "area":"100", //面积
    "depositAmount":"10000",//押金金额
    "rentAmount":"10000",//托管租金
    "rentStarDate":"2018-08-05",//托管开始日期
    "rentEndDate":"2019-08-05",//托管结束日期
    "loanAmount":"10000",//贷款金额
    "loanStarDate":"2018-08-05",//贷款开始日期
    "loanEndDate":"2019-08-05"//贷款结束日期
    }
    */

  struct Tenancy {
        string contractNo; //合同编号
        string info; //租约信息
        uint totalAmount; //租约总金额
        uint balance; //未兑付金额
        uint repaymentNum; //回款总期数
       // Repayment [] repayments; //回款列表 
        mapping(uint => Repayment)  repayments;
    }
  
  Tenancy[] tenancys;
   
   
  uint[] amount = [14,16,17,15,16];
  uint[] time = [1626089019452,1626089019452,1626089019452,1626089019452,1626089019452];
   
  constructor(address _witContract) public
  {
       witContract = _witContract;
       coinName = "Ycc_test_nft";
       symbolName = "YTN";
       baseUrl = "https://test.vaults.com/";
  }
  
    
    function setBaseUrl (string _baseUrl) public onlyOwner{
        baseUrl = _baseUrl;
    }
   function totalSupply() external view returns (uint) {
        return tenancys.length;
    }
    function name() external view returns (string) {
        return coinName;
    }
    function symbol() external view returns (string) {
        return symbolName;
    }
    function tokenURI(uint _tokenId) external view returns (string) {
        string memory tokenId_str = uint2str(_tokenId);
        return strConcat(baseUrl,tokenId_str);
        
    }
    function uint2str(uint i) internal pure returns (string c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        c = string(bstr);
    }
    function strConcat(string _a, string _b) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }
   function mintTenancy (string _contractNo, string _info,uint _totalAmount, uint[] _repayAmounts,  uint[] _repayDates) public onlyOwner returns(uint)  {
    
    require(_repayAmounts.length == _repayDates.length);
    
    uint _repaymentNum= _repayAmounts.length;
    
    Tenancy memory _tenancyObj = Tenancy({
        contractNo : _contractNo,
        info : _info,
        totalAmount : _totalAmount, 
        balance : _totalAmount,
        repaymentNum : _repaymentNum
    });
    
     uint256 newTenancyId = tenancys.push(_tenancyObj) - 1;
        
     for (uint i=0; i< _repaymentNum; i++) {
          Repayment memory _repayment = Repayment({
             repaymenId : i+1 ,
             amount: _repayAmounts[i] ,
             plantDate: _repayDates[i] ,
             status : 0, 
             actualDate : 0, 
             payee : address(0), 
             payer : address(0) 
         });
         
        tenancys[newTenancyId].repayments[i] = _repayment;
     }
    
    _mint(msg.sender, newTenancyId);
    
    emit MintTenancy(msg.sender, newTenancyId);

    return newTenancyId;
  }
  
  
  event MintTenancy(address owner, uint tokenId);

  
  
  
  function burnNft(uint256 tokenId) public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    _burn(ownerOf(tokenId), tokenId);
  }
  
  

      
  function getTenancyInfo(uint _tokenId) external view returns (string _contractNo,string _info, 
           uint _totalAmount,uint _balance, uint _repaymentNum, address owner, bool overdue, bool finish)
    {
        Tenancy memory obj  = tenancys[_tokenId];
        _contractNo = obj.contractNo;
        _info = obj.info;
        _totalAmount = obj.totalAmount;
        _balance = obj.balance;
        _repaymentNum = obj.repaymentNum;
        owner =ownerOf(_tokenId);
        overdue =isOverdue(_tokenId);
        finish =isFinish(_tokenId);
  }
  
  
  
  //判断是否有逾期,未兑付的Repayment中, 如果 (当前时间 - 应收日期) > overdueDay *1 days ,判断为逾期
  function isOverdue(uint _tokenId) internal view returns (bool) {
       
        uint _repaymentNum =getRepaymentNum(_tokenId);
         for (uint i=0; i< _repaymentNum; i++) {
          Repayment  memory _repayment = getRepayment(_tokenId,i);
          
          if(_repayment.status == 0 && (now - _repayment.plantDate > overdueDay * 1 days)){
              return true;
          }
       }

      return false;
  }
  
  

  function isFinish(uint _tokenId) internal view returns (bool) {
      
      uint _repaymentNum =getRepaymentNum(_tokenId);
         for (uint i=0; i< _repaymentNum; i++) {
          Repayment  memory _repayment = getRepayment(_tokenId,i);
          
          if(_repayment.status == 0){
              return false;
          }
       }

      return true;
  }
  


    function getRepaymentInfo(uint _tokenId) external view returns (uint[] repaymenIds,uint[] amounts, 
           uint[] plantDates,uint[] statues)
    {
        
        uint _repaymentNum =getRepaymentNum(_tokenId);
       
        uint[] memory _repaymenIds = new uint[](_repaymentNum);
        uint[] memory _amounts = new uint[](_repaymentNum);
        uint[] memory _plantDates = new uint[](_repaymentNum);
        uint[] memory _statues = new uint[](_repaymentNum);
    
      for (uint i=0; i< _repaymentNum; i++) {
          _repaymenIds[i] =i+1;
          
          Repayment  memory _repayment = getRepayment(_tokenId,i);
          _amounts[i] =_repayment.amount;
          _plantDates[i] =_repayment.plantDate;
          _statues[i]=_repayment.status;
        }
       
       repaymenIds=_repaymenIds;
       amounts=_amounts;
       plantDates=_plantDates;
       statues=_statues;
    }
    
    
   function getRepaymentDetails(uint _tokenId) external view returns (uint[] repaymenIds,uint[] statues,
        uint[] actualDates, address[] payees, address[] payers)
    {
    
        uint _repaymentNum =getRepaymentNum(_tokenId);
       
        uint[] memory _repaymenIds = new uint[](_repaymentNum);
        uint[] memory _statues = new uint[](_repaymentNum);
        uint[] memory _actualDates = new uint[](_repaymentNum);
        address[] memory _payees = new address[](_repaymentNum);
        address[] memory _payers = new address[](_repaymentNum);
    
     for (uint i=0; i< _repaymentNum; i++) {
          _repaymenIds[i] =i+1;
          
          Repayment  memory _repayment = getRepayment(_tokenId,i);
          _statues[i]=_repayment.status;
          _actualDates[i]=_repayment.actualDate;
          _payees[i]=_repayment.payee;
          _payers[i]=_repayment.payer;
        }
       
       repaymenIds = _repaymenIds;
       statues = _statues;
       actualDates = _actualDates;
       payees = _payees;
       payers = _payers;
    }
    
    
    
    function getRepaymentNum(uint _tokenId) internal view returns (uint repaymentNum) {
         
            return  tenancys[_tokenId].repaymentNum;
     }
    
     function getRepayment(uint _tokenId,uint repaymenId) internal view returns (Repayment repayment ) {
         
            return  tenancys[_tokenId].repayments[repaymenId];
     }
  

    function getOwnerTokens(address _owner) external view returns (uint256 [] tokens) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory _tokens = new uint[](tokenCount);
        
        uint j = 0;
        for(uint i=0; i < tenancys.length ; i++) {
         if( ownerOf(i)==_owner){
             _tokens[j]=i;
             j++;
         }
        }
        return _tokens;
  }
  

    /*
  
   function cashToken(uint256 _tokenId) public returns(bool) {
      
      NFT memory obj  = allNFTs[_tokenId];
      require(block.timestamp >= obj.cashTime);
      require(0 == obj.cashState);
      
      uint cashAmount = obj.cashAmount.mul(uint(10)**witDecimals);
      
      // 从调用者处转移代币给token的持有者(调用者先要授权给tcc合约足够的wit)
      assert(IERC20Token(witContract).transferFrom(msg.sender, ownerOf(_tokenId), cashAmount));
      
      obj.cashState= 1 ;
      
      allNFTs[_tokenId] = obj;
      
      return true;
  }*/
  
  
}