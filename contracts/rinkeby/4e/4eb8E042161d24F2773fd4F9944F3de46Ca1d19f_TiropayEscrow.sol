/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity 0.5.16; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_


                                                          

=== 'Escrow'  contract with following features ===
    => Ownership management 
    => Signer, a sub-owner wallet will process manual escrow 
    => USDT will be used as escrow fund
    => While starting escrow, USDT will be transferred from owner wallet to smart contract
    => And while releasing escrow, USDT will be transferred to owner wallet again and user will get fiat currency from the web application


============= Independant Audit of the code ============
    => Multiple Freelancers Auditors


-------------------------------------------------------------------
 Copyright (c) 2020 onwards  EtherAuthority ( https://EtherAuthority.io )
 Contract designed with ❤ by EtherAuthority ( https://EtherAuthority.io )
-------------------------------------------------------------------
*/ 


interface USDT{
    function transfer(address _to, uint256 _value) external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
}

contract owned {
    address public owner;
    address internal newOwner;

    /**
        Signer is deligated admin wallet, which can do sub-owner functions.  Signer calls following  function:
            => MintTokens
    */
    address public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'caller must be owner');
        _;
    }

    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }

    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner, 'Invalid owner address');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract TiropayEscrow is owned{
    
    mapping (address => uint256) public buyerBalance;
    //uint balance;
    
    mapping(address => address) public Deal;
    
    mapping(address => bool) public buyer;
    mapping(address => bool) public seller;
    
    mapping(address => bool) public _cbuyer;
    mapping(address => bool) public _cseller;
    
    address payable escrow;
    uint private start;
    
    
    struct escrowDetail {
        address buyer;
        address seller;
        uint256 amount;
        bool status;
    }
    
    mapping (uint256 => escrowDetail) public escrowMap;
    
    event startEscrow(uint256 _escrowID, address indexed _buyer,address indexed _seller, uint256 _amount);
    event releaseEscrow(uint256 _escrowID, address indexed _buyer,address indexed _seller, uint256 _amount);
    
    address public usdtadd;
    address public usdtHolder;
    
    
    constructor() public {
        escrow = msg.sender;
        start = now; //now is an alias for block.timestamp, not really "now"
    }
    
    function startTrade(address _buyer, address _seller) public{
        
        require(Deal[_buyer]!=_seller,"Pending");
        Deal[_buyer]=_seller;
        
    }
   
    function () payable external{}
    
    function accept(address _buyer, address payable _seller) public {
        
        require(Deal[_buyer]==_seller,"Deal Not Exist");
        if (msg.sender == _buyer){
            buyer[_buyer] = true;
        } else if (msg.sender == _seller){
            seller[_seller] = true;
        }
        if (buyer[_buyer] && seller[_seller]){
            payBalance(_buyer,_seller);
        } else if (buyer[_buyer] && !seller[_seller] && now > start + 30 days) {
            // Freeze 30 days before release to buyer. The customer has to remember to call this method after freeze period.
            //selfdestruct(_buyer);
        }
    }
    
    function payBalance(address _buyer, address payable _seller) private {
        
        require(Deal[_buyer]==_seller,"Not Possible");
        // we are sending ourselves (contract creator) a fee
        escrow.transfer(address(this).balance / 100);
        // send seller the balance
        if (_seller.send(address(this).balance)) {
            buyerBalance[_buyer] = 0;
        } else {
            revert();
        }
    }
    
    
    function deposit(address _buyer) public payable {
        if (msg.sender == _buyer) {
            buyerBalance[_buyer] += msg.value;
        }
    }
    
    function cancel(address payable _buyer, address _seller) public {
        
        require(Deal[_buyer]==_seller,"Deal Not Exist");
         
        if (msg.sender == _buyer){
            _cbuyer[_buyer] = true;
        } else if (msg.sender == _seller){
            _cseller[_seller] = true;
        }
        // if both buyer and seller would like to cancel, money is returned to buyer 
        if (_cbuyer[_buyer] && _cseller[_seller]){
            _buyer.transfer(address(this).balance);
        }
    }
    
     
    
    function addUsdt(address _usdtadd,address _usdtOwner) public{
        usdtadd=_usdtadd;
        usdtHolder=_usdtOwner;
    }
    
    function startEscrowSigner(address _buyer,address _seller, uint256 _amount, uint256 _escrowID) public onlySigner returns(bool) {
        
        require(!escrowMap[_escrowID].status,"record already exists");
        
        escrowDetail memory startStruct;
        
        startStruct=escrowDetail({
            buyer:_buyer,
            seller:_seller,
            amount:_amount,
            status:true
            
        });
        
        escrowMap[_escrowID]=startStruct;
        
        USDT(usdtadd).transferFrom(usdtHolder,address(this),_amount);
        emit startEscrow(_escrowID, _buyer,_seller,_amount);
        
    }
    
    
    function releaseEscrowSigner(uint256 _escrowID) public onlySigner returns(bool){
        
        require(escrowMap[_escrowID].status,"record does not exist");
    
        escrowMap[_escrowID].status=false;
        
        USDT(usdtadd).transfer(usdtHolder,escrowMap[_escrowID].amount);
        emit releaseEscrow(_escrowID,escrowMap[_escrowID].buyer,escrowMap[_escrowID].seller,escrowMap[_escrowID].amount);
    }
    
    
    
    
    
    
}