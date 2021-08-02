//SourceUnit: cryptoDefi.sol

pragma solidity 0.5.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
   
contract CRYPTO_DEFI  {
    
    event Multisended(uint256 value , address indexed sender);
	event Registration(string  member_name, string  sponcer_id,address indexed sender,string  PType);
	event LevelUpgrade(string  member_name, string  current_level,string promoter,address indexed sender,string  PType);
	event MatrixUpgrade(string  member_name, string  matrix,string  promoter,string payment_promoter,address indexed sender,string  PType);
	event LevelPaymentEvent(string  member_name,uint256 current_level,string  PType);
	event MatrixPaymentEvent(string  member_name,uint256 matrix,string  PType);
	event AdminPaymentEvent(string  member_name,uint256 matrix,string payment_type,string  PType,uint fundValue);
	
    using SafeMath for uint256;
    address public owner;
   
	trcToken tokenId=1002000;
	

    constructor(address ownerAddress) public 
    {
        owner = ownerAddress;
        
     
    }
    
	
	function NewRegistration(string memory member_name, string memory sponcer_id,address payable[]  memory  _contributors, uint256[] memory _balances,string memory PType) public payable
	{
	    
		if(keccak256(bytes(PType)) == keccak256(bytes("TRX")))
		{
			multisendTRX(_contributors,_balances);
		}
		else if(keccak256(bytes(PType)) == keccak256(bytes("BTT")))
		{
			require(msg.tokenid==tokenId,"Only BTT Token");
			multisendBTT(_contributors,_balances);
		}
	
		emit Registration(member_name, sponcer_id,msg.sender,PType);
	}
	
		
	
	 function LevelPayment(string memory member_name,uint Level,address payable[]  memory  _contributors, uint256[] memory _balances,string memory PType) public payable
	{
		if(keccak256(bytes(PType)) == keccak256(bytes("TRX")))
		{
			multisendTRX(_contributors,_balances);
		}
		else if(keccak256(bytes(PType)) == keccak256(bytes("BTT")))
		{
			require(msg.tokenid==tokenId,"Only BTT Token");
			multisendBTT(_contributors,_balances);
		}
	
		emit LevelPaymentEvent(member_name, Level,PType);
	}
	function MatrixPayment(string memory member_name,uint matrix,address payable[]  memory  _contributors, uint256[] memory _balances,string memory PType) public payable
	{
		if(keccak256(bytes(PType)) == keccak256(bytes("TRX")))
		{
			multisendTRX(_contributors,_balances);
		}
		else if(keccak256(bytes(PType)) == keccak256(bytes("BTT")))
		{
			require(msg.tokenid==tokenId,"Only BTT Token");
			multisendBTT(_contributors,_balances);
		}
		
		emit MatrixPaymentEvent(member_name, matrix,PType);
	}
	function AdminPayment(string memory member_name,uint matrix,address payable[]  memory  _contributors, uint256[] memory _balances,string memory payment_type,string memory PType,uint fundValue) public payable
	{
		if(keccak256(bytes(PType)) == keccak256(bytes("TRX")))
		{
			multisendTRX(_contributors,_balances);
		}
		else if(keccak256(bytes(PType)) == keccak256(bytes("BTT")))
		{
			require(msg.tokenid==tokenId,"Only BTT Token");
			multisendBTT(_contributors,_balances);
		}
	
		
		emit AdminPaymentEvent(member_name, matrix,payment_type,PType,fundValue);
	}
	
	
	 function multisendBTT(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {       
        uint256 i = 0;
        for (i; i < _contributors.length; i++) 
		{
			_contributors[i].transferToken(_balances[i],tokenId);
        }
        emit Multisended(msg.value, msg.sender);
    }
	
    
	 function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }
	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }  
	function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(address(this).balance);
    }
	
	  function withdrawLostBTTFromBalance(address payable _sender,uint256 _amt) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transferToken(_amt,tokenId);
    }
    
}