pragma solidity ^0.4.13;

contract EInterface { 
   	  
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) { }
    function transferFrom(address _from, address _to, uint256 _value)  {}
}


contract BidAskX {  
   
    //--------------------------------------------------------------------------EInterface
    function allow_spend(address _coin) private returns(uint){  
        EInterface pixiu = EInterface(_coin);
        uint allow = pixiu.allowance(msg.sender, this);
        return allow;
        
    }
             
    function transferFromTx(address _coin, address _from, address _to, uint256 _value) private {
        EInterface pixiu = EInterface(_coin); 
        pixiu.transferFrom(_from, _to, _value);
    }     
    
    //--------------------------------------------------------------------------event
    event Logs(string); 
    event Log(string data, uint value, uint value1); 
    event Println(address _address,uint32 number, uint price, uint qty, uint ex_qty, bool isClosed,uint32 n32);
    event Paydata(address indexed payer, uint256 value, bytes data, uint256 balances);
        
    //--------------------------------------------------------------------------admin
    mapping (address => AdminType) admins;  
    address[] adminArray;   
    enum AdminType { none, normal, agent, admin, widthdraw }

    //--------------------------------------------------------------------------member
    struct Member {
        bool isExists;                                    
        bool isWithdraw;                                  
        uint deposit;
        uint withdraw;
        uint balances;
        uint bid_amount;
        uint tx_amount;
        uint ask_qty;
        uint tx_qty;
        address agent;
    }
    mapping (address => Member) public members;  
    address[] public memberArray;

    //--------------------------------------------------------------------------order
    uint32 public order_number=1;
    struct OrderSheet {
        bool isAsk;
        uint32 number;
        address owner;
        uint price;
        uint qty;
        uint amount;
        uint exFee;
        uint ex_qty;
        bool isClosed;
    }
    address[] public tokensArray; 
    mapping (address => bool) tokens; 
    mapping (address => uint32[]) public token_ask; 
    mapping (address => uint32[]) public token_bid; 
    mapping (address => mapping(address => uint32[])) public token_member_order;
    mapping (address => mapping(uint32 => OrderSheet)) public token_orderSheet;  

    //--------------------------------------------------------------------------public
    bool public isPayable = true;
    bool public isWithdrawable = true;
    bool public isRequireData = false;
	uint public MinimalPayValue = 0;
	uint public exFeeRate = 1000;
	uint public exFeeTotal = 0;
    

    function BidAskX(){  
        
        adminArray.push(msg.sender); 
        admins[msg.sender]=AdminType.widthdraw;
        //ask(this);
        
    }

    function list_token_ask(address _token){
        uint32[] storage numbers = token_ask[_token];
        for(uint i=0;i<numbers.length;i++){
            uint32 n32 = numbers[i];
            OrderSheet storage oa = token_orderSheet[_token][n32];
            Println(oa.owner, oa.number, oa.price, oa.qty, oa.ex_qty, oa.isClosed,n32);
        }
    }
    
    function list_token_bid(address _token){
        uint32[] storage numbers = token_bid[_token];
        for(uint i=0;i<numbers.length;i++){
            uint32 n32 = numbers[i];
            OrderSheet storage oa = token_orderSheet[_token][n32];
            Println(oa.owner, oa.number, oa.price, oa.qty, oa.ex_qty, oa.isClosed,n32);
        }
    }
     
    function tokens_push(address _token) private {
        if(tokens[_token]!=true){
            tokensArray.push(_token);
            tokens[_token]=true;
        }
    }
    
    function token_member_order_pop(address _token, address _sender, uint32 _number) private {
        for(uint i=0;k<token_member_order[_token][_sender].length-1;i++){
            if(token_member_order[_token][_sender][i]==_number){
                for(uint k=i;k<token_member_order[_token][_sender].length-2;k++){
                    token_bid[_token][k]=token_bid[_token][k+1];
                }
                token_member_order[_token][_sender].length-=1;
                break;
            }
        }
    }
 
    function members_push(address _address) private {
        if (members[_address].isExists != true) {
            members[_address].isExists = true;
            members[_address].isWithdraw = true; 
            members[msg.sender].deposit=0;
            members[msg.sender].withdraw=0;
            members[msg.sender].balances =0;
            members[msg.sender].tx_amount=0;
            members[msg.sender].bid_amount=0;
            members[msg.sender].ask_qty=0;
            members[msg.sender].tx_qty=0;
            members[msg.sender].agent=address(0);
            memberArray.push(_address); 
        }
    }
        
    function cancel( address _token,uint32 _number){ 
        OrderSheet storage od = token_orderSheet[_token][_number];
        if(od.owner==msg.sender){
            uint i;
            uint k;
            if(od.isAsk){
                
                for(i=0; i<token_ask[_token].length;i++){
                    if(token_ask[_token][i]==_number){
                        od.isClosed = true;
                        members[msg.sender].ask_qty - od.qty + od.ex_qty;
                        for(k=i;k<token_ask[_token].length-2;k++){
                            token_ask[_token][k]=token_ask[_token][k+1];
                        }
                        token_ask[_token].length-=1;
                        break;
                    }
                }
                
            } else {
            
                for(i=0; i<token_bid[_token].length;i++){
                    if(token_bid[_token][i]==_number){
                        od.isClosed = true;
                        members[msg.sender].bid_amount - od.amount + od.price*od.ex_qty;
                        for(k=i;k<token_bid[_token].length-2;k++){
                            token_bid[_token][k]=token_bid[_token][k+1];
                        }
                        token_bid[_token].length-=1;
                        break;
                    }
                }
                
            }
            token_member_order_pop(_token, msg.sender, _number);
        } else {
            Logs("The order owner not match");
        }
    }
    
    function bid( address _token, uint _qty, uint _priceEth, uint _priceWei){ 
        tokens_push(_token); 
        uint256 _price = _priceEth *10**18 + _priceWei;
        uint exFee = (_qty * _price) / exFeeRate;
        uint amount = (_qty * _price)+exFee;
        
        uint unclose = members[msg.sender].bid_amount - members[msg.sender].tx_amount;
        uint remaining = members[msg.sender].balances - unclose;
        if(remaining >= amount){
            OrderSheet memory od;
            od.isAsk = false;
            od.number = order_number;
            od.owner = msg.sender;
            od.price = _price;
            od.qty = _qty;
            od.ex_qty=0;
            od.exFee = (_price * _qty)/exFeeRate;
            od.amount = (_price * _qty) + od.exFee;
            od.isClosed=false; 
            token_orderSheet[_token][order_number]=od; 
            members[msg.sender].bid_amount+=amount;
            token_member_order[_token][msg.sender].push(order_number);
            bid_match(_token,token_orderSheet[_token][order_number],token_ask[_token]); 
            if(token_orderSheet[_token][order_number].isClosed==false){
                token_bid[_token].push(order_number);   
                Println(od.owner, od.number, od.price, od.qty, od.ex_qty, od.isClosed,777);
            }
            order_number++;
        } else {
            Log("You need more money for bid", remaining, amount);
        }
    }
    
    function ask( address _token, uint _qty, uint _priceEth, uint _priceWei){ 
        tokens_push(_token); 
        uint256 _price = _priceEth *10**18 + _priceWei;
        uint unclose = members[msg.sender].ask_qty - members[msg.sender].tx_qty;
        uint remaining = allow_spend(_token) - unclose;
        uint exFee = (_price * _qty)/exFeeRate;
        if(members[msg.sender].balances < exFee){
            Log("You need to deposit ether to acoount befor ask", exFee, members[msg.sender].balances);
        } else if(remaining >= _qty){
            members_push(msg.sender);
            OrderSheet memory od;
            od.isAsk = true;
            od.number = order_number;
            od.owner = msg.sender;
            od.price = _price;
            od.qty = _qty;
            od.ex_qty=0;
            od.exFee = exFee;
            od.amount = (_price * _qty) - exFee;
            od.isClosed=false; 
            token_orderSheet[_token][order_number]=od; 
            members[msg.sender].ask_qty+=_qty;
            token_member_order[_token][msg.sender].push(order_number);
            ask_match(_token,token_orderSheet[_token][order_number],token_bid[_token]);
            if(od.isClosed==false){
                token_ask[_token].push(order_number);  
                Log("Push order number to token_ask",order_number,0);
            }
            order_number++;
        } else {
            Log("You need approve your token for transfer",0,0);
        }
    }
     
    function ask_match(address _token, OrderSheet storage od, uint32[] storage token_match) private { 
        for(uint i=token_match.length;i>0 && od.qty>od.ex_qty;i--){
            uint32 n32 = token_match[i-1];
            OrderSheet storage oa = token_orderSheet[_token][n32];
            uint qty = oa.qty-oa.ex_qty;
            if(oa.isClosed==false && qty>0){
                uint ex_qty = (qty>od.qty?od.qty:qty);
                uint ex_price = oa.price;
                uint exFee = (ex_qty * ex_price) / exFeeRate;
                uint amount = (ex_qty * ex_price);
                Println(oa.owner, oa.number, oa.price, oa.qty, oa.ex_qty, oa.isClosed,n32);
                
                if(members[oa.owner].balances >= amount && od.price <= oa.price){
                    od.ex_qty += ex_qty;
                    if(oa.ex_qty+ex_qty>=oa.qty){
                        token_orderSheet[_token][n32].isClosed = true; 
                        for(uint k=i-1;k<token_match.length-2;k++){
                            token_match[k]=token_match[k+1];
                        }
                    }
                    token_orderSheet[_token][n32].ex_qty += ex_qty; 
                    transferFromTx(_token,  msg.sender, oa.owner, ex_qty); 
                    
                    members[oa.owner].balances -= (amount+exFee);
                    members[oa.owner].tx_amount += (amount+exFee);
                    members[oa.owner].tx_qty += ex_qty;

                    members[msg.sender].balances += (amount-exFee);
                    members[msg.sender].tx_amount += (amount-exFee);
                    members[msg.sender].tx_qty += ex_qty;
                    
                    if(od.ex_qty+ex_qty>=od.qty){
                        od.isClosed = true; 
                    } 
                    exFeeTotal += exFee;
                }
            }
        } 
    }
    
    function bid_match(address _token, OrderSheet storage od, uint32[] storage token_match) private { 
        for(uint i=token_match.length;i>0 && od.qty>od.ex_qty;i--){
            uint32 n32 = token_match[i-1];
            OrderSheet storage oa = token_orderSheet[_token][n32];
            uint qty = oa.qty-oa.ex_qty;
            if(oa.isClosed==false && qty>0){
                uint ex_qty = (qty>od.qty?od.qty:qty);
                uint ex_price = oa.price;
                uint exFee = (ex_qty * ex_price) / exFeeRate;
                uint amount = (ex_qty * ex_price);
                Println(oa.owner, oa.number, oa.price, oa.qty, oa.ex_qty, oa.isClosed,222); 
                if(members[msg.sender].balances >= amount && oa.price <= od.price){
                    od.ex_qty += ex_qty;
                    if(oa.ex_qty+ex_qty>=oa.qty){
                        token_orderSheet[_token][n32].isClosed = true; 
                        for(uint k=i-1;k<token_match.length-2;k++){
                            token_match[k]=token_match[k+1];
                        }
                    }
                    token_orderSheet[_token][n32].ex_qty += ex_qty; 
                    //transferFromTx(_token, oa.owner, msg.sender, ex_qty); 
                    members[od.owner].balances += (amount-exFee);
                    members[od.owner].tx_amount += (amount-exFee); 
                    members[od.owner].tx_qty += ex_qty; 

                    members[msg.sender].balances -= (amount+exFee);
                    members[msg.sender].tx_amount += (amount+exFee);
                    members[msg.sender].tx_qty += ex_qty;
                    
                    if(od.ex_qty+ex_qty>=od.qty){
                        od.isClosed = true; 
                    }
                    exFeeTotal += exFee;
                } 
            }
        } 
    }
    
  
    //--------------------------------------------------------------------------member function
    function withdraw(uint _eth, uint _wei) {
        
        for(uint i=0;i<tokensArray.length-1;i++){
            address token = tokensArray[i];
            uint32[] storage order = token_member_order[token][msg.sender];
            for(uint j=0;j<order.length-1;j++){
                cancel( token,order[j]);
            }
        }
        
        uint balances = members[msg.sender].balances;
        uint withdraws = _eth*10**18 + _wei;
        require( balances >= withdraws);
        require( this.balance >= withdraws);
        require(isWithdrawable);
        require(members[msg.sender].isWithdraw);
        msg.sender.transfer(withdraws);
        members[msg.sender].balances -= withdraws;
        members[msg.sender].withdraw += withdraws;  

    }
            
    function get_this_balance() constant returns(uint256 _eth,uint256 _wei){
      
        _eth = this.balance / 10**18 ;
        _wei = this.balance - _eth * 10**18 ;
      
    }
    
    
    function pay() public payable returns (bool) {
        
        require(msg.value > MinimalPayValue);
        require(isPayable);
        
        
        if(admins[msg.sender] == AdminType.widthdraw){

        }else{
            
            if(isRequireData){
                require(admins[address(msg.data[0])] > AdminType.none);   
            }
        
            members_push(msg.sender);
            members[msg.sender].balances += msg.value;
            members[msg.sender].deposit += msg.value;
            if(admins[address(msg.data[0])]>AdminType.none){
                members[msg.sender].agent = address(msg.data[0]);
            }

    		Paydata(msg.sender, msg.value, msg.data, members[msg.sender].balances);
		
        }
        
        return true;
    
    }

   
  

    //--------------------------------------------------------------------------admin function
    
    modifier onlyAdmin() {
        require(admins[msg.sender] > AdminType.agent);
        _;
    }

    function admin_list() onlyAdmin constant returns(address[] _adminArray){
        
        _adminArray = adminArray; 
        
    }    
    
    function admin_typeOf(address admin) onlyAdmin constant returns(AdminType adminType){
          
        adminType= admins[admin];
        
    }
    
    function admin_add_modify(address admin, AdminType adminType) onlyAdmin {
        
        require(admins[admin] > AdminType.agent);
        if(admins[admin] < AdminType.normal){
            adminArray.push(admin);
        }
        admins[admin]=AdminType(adminType);
        
    }
    
    function admin_del(address admin) onlyAdmin {
        
        require(admin!=msg.sender);
        require(admins[admin] > AdminType.agent);
        if(admins[admin] > AdminType.none){
            admins[admin] = AdminType.none;
            for (uint i = 0; i < adminArray.length - 1; i++) {
                if (adminArray[i] == admin) {
                    adminArray[i] = adminArray[adminArray.length - 1];
                    adminArray.length -= 1;
                    break;
                }
            }
        }
        
    }

    function admin_withdraw(uint _eth, uint _wei) onlyAdmin {

        require(admins[msg.sender] > AdminType.admin);
        uint256 amount = _eth * 10**18 + _wei;
		require(this.balance >= amount);
		msg.sender.transfer(amount); 
        
    }
        

	function admin_exFeeRate(uint _rate) onlyAdmin {
	    
	    exFeeRate = _rate;
	    
	}
     	
    function admin_MinimalPayValue(uint _eth, uint _wei) onlyAdmin {
	    
	    MinimalPayValue = _eth*10*18 + _wei;
	    
	}
     
    function admin_isRequireData(bool _requireData) onlyAdmin{
    
        isRequireData = _requireData;
        
    }
    
    function admin_isPayable(bool _payable) onlyAdmin{
    
        isPayable = _payable;
        
    }
    
    function admin_isWithdrawable(bool _withdrawable) onlyAdmin{
        
        isWithdrawable = _withdrawable;
        
    }
    
    function admin_member_isWithdraw(address _member, bool _withdrawable) onlyAdmin {
        if(members[_member].isExists == true) {
            members[_member].isWithdraw = _withdrawable;
        } else {
            Logs("member not existes");
        }
    }
    
    
}