//SourceUnit: tronScore.sol

pragma solidity ^0.5.4;

contract TronScore {
      uint256 public latestReferrerCode;
    
    address payable private adminAccount_;

    address payable private savingAccount_;
 
    mapping(uint256=>address) public idToAddress;
    mapping(address=>uint256) public addresstoUid;
    


    event Registration(string waddress,address investor,uint256 investorId,address referrer,uint256 referrerId,address promoter,uint256 promoterId);
    event Deposit(address investor,uint256 investorId,uint256 amount,uint8 _type,uint8 is_member_count);
    
  
    constructor(address payable _saving,address payable _admin) public 
    {
        adminAccount_=_admin;
        savingAccount_=_saving;
        latestReferrerCode++;
        idToAddress[latestReferrerCode]=_admin;
        addresstoUid[_admin]=latestReferrerCode;
    }

  
    
    function setAdminAccount(address payable _newAccount,address payable _saving) public  {
        require(_newAccount != address(0) && msg.sender==adminAccount_);
        adminAccount_ = _newAccount;
        savingAccount_=_saving;
    }
    
  
    
    function withdrawLostTRXFromBalance(address payable _sender,uint256 _amt) public {
        require(msg.sender == adminAccount_, "onlyOwner");
        _sender.transfer(_amt*1e6);
    }
    
  

    function getBalance() public view returns (uint256) 
    {
        return address(this).balance;
    }


    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        require(msg.sender==adminAccount_,"Only Owner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);            
        }
    }


    function _invest(string memory _user,uint256 _referrerCode) public payable
    {
       // require(msg.value==500 trx || msg.value==1000 trx || msg.value==2500 trx || msg.value==5000 trx,"Invalid Amount");
        require(idToAddress[_referrerCode]!=address(0),"Invalid Referrer ID");
        if(addresstoUid[msg.sender]==0)
        {
            latestReferrerCode++;
            idToAddress[latestReferrerCode]=msg.sender;
            addresstoUid[msg.sender]=latestReferrerCode;
            emit Registration(_user,msg.sender,latestReferrerCode,idToAddress[_referrerCode],_referrerCode,idToAddress[latestReferrerCode-1],latestReferrerCode-1);
        }
         address(uint160(savingAccount_)).transfer(address(this).balance);
         emit Deposit(msg.sender,addresstoUid[msg.sender], msg.value,1,0);
    }

      function reinvest(string memory _user) public payable
    {
        //require(msg.value==500 trx || msg.value==1000 trx || msg.value==2500 trx || msg.value==5000 trx,"Invalid Amount");
        require(addresstoUid[msg.sender]>0,"Register first");
        address(uint160(savingAccount_)).transfer(address(this).balance);
        emit Deposit(msg.sender,addresstoUid[msg.sender], msg.value,1,1);
    }

}