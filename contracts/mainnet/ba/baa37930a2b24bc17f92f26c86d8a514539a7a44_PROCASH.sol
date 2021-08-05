/**
 *Submitted for verification at Etherscan.io on 2020-08-12
*/

pragma solidity  >= 0.5.0< 0.7.0;

contract PROCASH {
    
    address owner;
    address  payable donde;
    uint[] ident;
    mapping(uint => username)  usuarios;
    
    struct username{
           uint id;
           string name;
           address payable dir;
    }

    modifier valida_user(uint _id){
	    require(usuarios[_id].id != _id);
	    _;
	}
	
  	constructor() public{
  	    owner = msg.sender;
    }
  	
  	event RegisterUserEvent(address indexed _dire, string  indexed name , uint time);
  	event Recarga_pay(address indexed user, uint indexed amount, uint time);
    event set_transfer(address indexed user,address indexed referrer,uint indexed amount, uint time);
  
    function fondos_contract(uint256 amount) public payable{
            require(msg.value == amount);
            emit Recarga_pay(msg.sender, amount, now);
    }
    
   	function Register(uint _id, address payable dire,  string memory _name ) payable public valida_user(_id){
	     	ident.push(_id);
			usuarios[_id] = username({
			    id: _id,
				name: _name,
				dir: dire
 			});
    	    emit  RegisterUserEvent( dire , _name ,  now );
	}
	
	
	function update_register(uint _id, address payable dire,  string memory _name) public payable{
	      require(owner == msg.sender);
	      	usuarios[_id] = username({
			    id: _id,
			    name: _name,
				dir: dire
 			});
	       
	}
	
	
	function pay_now(uint[] memory valor, uint256[] memory monto) public payable {
	    uint i;
	    uint256 pagar;

      for ( i = 0; i < valor.length ; i++)
         {
            donde  = usuarios[valor[i]].dir;
            pagar  =    monto[i];
             pagar_cuenta(donde, pagar);
         } 
    
    }
    
    function pagar_cuenta(address payable _dire, uint256 _monto)  payable public {
             require(owner == msg.sender);
            _dire.transfer(_monto);
             emit set_transfer(msg.sender, _dire, _monto, now ); 
    }
    
    function total_register() public view returns(uint){
         require(owner == msg.sender);
         return ident.length;
    } 
    
    function mi_user(uint  valor) public view returns(string memory) {
         return usuarios[valor].name;
    }
 
    function mi_wallet(uint  valor) public view returns(address payable) {
         return usuarios[valor].dir;
    }
    
}