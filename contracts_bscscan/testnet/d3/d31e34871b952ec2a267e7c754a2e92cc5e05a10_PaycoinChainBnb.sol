/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaycoinChainBnb {
    
    using SafeMath for uint256;

    address payable private _owner;  
    uint constant internal DEFAULT_DECIMALS = 2; 
    uint constant internal BNB_DECIMALS = 18;
    uint public FEE_PERCENT = percent(1, BNB_DECIMALS); // 1%
  
  
    struct ClientProject {   address payable[] clientAddr;   uint256[] splitFee;  bool[] modeIsPercent; }
    struct Transact { 
        address contractId; 
        address sender; 
        string txnId; 
        uint256 fee; 
        uint256 amount;  
        uint date;    
        address payable[] receiverAddr;  
        uint256[] receiverAmt; 
    }  
    struct ContractFee {  uint decimals;  uint feePercent;   }
    mapping(address => ContractFee) internal contractsFee; //decimals, feePercent note: feePercent is In DEFAULT_DECIMALS decimals
    mapping(string => ClientProject) internal clientProjects;
    mapping(string => Transact[]) internal deposits;
    mapping(string => Transact[]) internal payouts;  
   
    event NewDeposit(string indexed projectid, Transact deposit);
    event NewPayout(string indexed projectid, Transact payout);
    event NewProject(string indexed projectid);
  
  
    modifier ownerOnly() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
         _owner = payable(msg.sender); //address payable owner
    }
  
    fallback() external payable {}
    event Received(address, uint256);
    event Withdrawn(address, uint256); 

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }    
    function withdraw(address payable recipient, uint256 amount) external payable ownerOnly {
        recipient.transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    function getBalance() external view ownerOnly returns(uint256) {
        return address(this).balance;
    }

    function getContractBalance(address contractAddress) external view ownerOnly returns(uint256) {
        IERC20 coin = IERC20(contractAddress);
        return coin.balanceOf(msg.sender);
    }
        
    function setFee(uint fee) public ownerOnly {
        FEE_PERCENT = percent(fee, BNB_DECIMALS);
    }

    function setContractFee(address contractAddress, uint _decimal, uint _feePercent) external ownerOnly {
        contractsFee[contractAddress] = ContractFee(_decimal, _feePercent);
    }
    
     //5% = 5/100;  but 5% based on 4decimals => 5* 10**4 / (100 * 10**4)
    function percent(uint numb, uint decimals) pure internal returns (uint){
        if(numb == 0){
            return 0;
        }
  
        uint _percentValu = power10(decimals.sub(DEFAULT_DECIMALS));
        return  (numb.mul(_percentValu)).div(_percentValu.mul(100));
    }

    function amountToUnits(uint256 amount, uint decimals) pure internal returns (uint256){
        uint256 amtInWei = amount.mul(power10(decimals.sub(DEFAULT_DECIMALS)));
        return amtInWei;
    }
    
    function power10(uint256 numb) pure internal returns (uint256){
        return 10 ** numb;
    }

  
    function getProjectDeposits(string memory _projectId) external view returns (Transact[] memory)
    {
        return deposits[_projectId];
    }

    function getProjectPayouts(string memory _projectId) external view returns (Transact[] memory)
    {
        return payouts[_projectId];
    }
 
    function addProject(string memory _projectId, address payable[] memory _recipients, 
                uint256[] memory _splitAmount, bool[] memory _modeIsPercent) external {
        require(_recipients.length == _splitAmount.length, 'recipient & fees must be same length');
        
        clientProjects[_projectId] = ClientProject(_recipients, _splitAmount, _modeIsPercent);	  
        emit NewProject(_projectId);
    }


        
/*   struct ClientProject {   address payable[] clientAddr;   uint256[] splitFee;  bool[] modeIsPercent; }
    mapping(string => ClientProject) internal clientProjects; */
     
    function depositFund(string memory _projectId, string memory _paymentId) external payable {
            require(msg.value > 0);

        ClientProject memory cProj = clientProjects[_projectId]; 
         
        uint256 feeAmount = msg.value * FEE_PERCENT;
        uint256 clientAmount = msg.value - feeAmount;
        
        uint256[] memory _amtsToPay;
        for(uint i =0; i < cProj.clientAddr.length; i++) {  
            uint256 splitPayAmt = 0;
            if(cProj.modeIsPercent[i]){
                splitPayAmt = amountToUnits(cProj.splitFee[i], BNB_DECIMALS); 
            } else { 
                splitPayAmt = amountToUnits(clientAmount.mul(percent(cProj.splitFee[i], BNB_DECIMALS)), BNB_DECIMALS);  
            } 
                                               
            require(clientAmount >= splitPayAmt);
            clientAmount = clientAmount.sub(splitPayAmt); 
            _amtsToPay[i] = splitPayAmt; 
        }

        //send the amount to clients 
        for(uint i=0; i<cProj.clientAddr.length; i++){ 
            cProj.clientAddr[i].transfer(_amtsToPay[i]); 
        }
      
        address contractId; 
        payouts[_projectId].push(Transact(contractId, msg.sender, _paymentId, feeAmount, msg.value, block.timestamp, cProj.clientAddr, _amtsToPay));
        emit NewPayout(_projectId, Transact(contractId, msg.sender, _paymentId, feeAmount, msg.value, block.timestamp, cProj.clientAddr, _amtsToPay));
    }
    

    function depositContractToken(address contractAddress, string memory _projectId, string memory _paymentId) external payable {
        require(msg.value > 0);

        IERC20 coin = IERC20(contractAddress);
        
        ContractFee memory contrFee = contractsFee[contractAddress]; 
        ClientProject memory cProj = clientProjects[_projectId]; 
        
        //deduct the fee from the amount first
        uint256 feeAmount = msg.value * percent(contrFee.feePercent, contrFee.decimals);  
        uint256 clientAmount = msg.value - feeAmount;
        
        uint256[] memory _amtsToPay;
        for(uint i =0; i < cProj.clientAddr.length; i++) { 
            uint256 splitPayAmt = 0;
            if(cProj.modeIsPercent[i]){
                splitPayAmt = amountToUnits(cProj.splitFee[i], contrFee.decimals); 
            } else { 
                splitPayAmt = amountToUnits(clientAmount.mul(percent(cProj.splitFee[i], contrFee.decimals)), contrFee.decimals);  
            }  
            
            require(clientAmount >= splitPayAmt);
            clientAmount = clientAmount.sub(splitPayAmt); 
            _amtsToPay[i] = splitPayAmt; 
        }

        //send the amount to clients  
        for(uint i=0; i<cProj.clientAddr.length; i++) {  
            coin.transfer(cProj.clientAddr[i], _amtsToPay[i]);  
        }
        
        payouts[_projectId].push(Transact(contractAddress, msg.sender, _paymentId, feeAmount, msg.value, block.timestamp, cProj.clientAddr, _amtsToPay));
        emit NewPayout(_projectId, Transact(contractAddress, msg.sender, _paymentId, feeAmount, msg.value, block.timestamp, cProj.clientAddr, _amtsToPay));
    }
	//END PROJECT SETUP

    //Manual Process ===========
  function sendFund(string memory _projectId, string memory _paymentId, uint256 _feeAmount, uint256 _clientAmount, 
            address payable[] memory _toAddrs, uint256[] memory _amounts) external payable ownerOnly  {
        require(_toAddrs.length == _amounts.length, ' must be same length as amount');
     
        //send the amount to clients  
        for(uint i=0; i < _toAddrs.length; i++) { 
            _toAddrs[i].transfer(_amounts[i]);  
        }

        address contractId;
        payouts[_projectId].push(Transact(contractId, msg.sender, _paymentId, _feeAmount, _clientAmount, block.timestamp, _toAddrs, _amounts));
        emit NewPayout(_projectId, Transact(contractId, msg.sender, _paymentId, _feeAmount, _clientAmount, block.timestamp, _toAddrs, _amounts));
  }
 
  function sendContractToken(address contractAddress, string memory _projectId, 
            string memory _paymentId, uint256 _feeAmount, uint256 _clientAmount, 
            address payable[] memory _toAddrs, uint256[] memory _tokens)  external payable ownerOnly
   {
         require(_toAddrs.length == _tokens.length, ' must be same length as amount');

        IERC20 coin = IERC20(contractAddress); 
        
        //send the amount to clients  
        for(uint i=0; i < _toAddrs.length; i++) {
             coin.transfer(_toAddrs[i], _tokens[i]);  
        }
 
        payouts[_projectId].push(Transact(contractAddress, msg.sender, _paymentId, _feeAmount, _clientAmount, block.timestamp, _toAddrs, _tokens));
        emit NewPayout(_projectId, Transact(contractAddress, msg.sender, _paymentId, _feeAmount, _clientAmount, block.timestamp, _toAddrs, _tokens));
  }
 
 
}

interface IERC20 { 
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}
 
 
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b; 
        return c;
    }
}