pragma solidity 		^0.4.8	;						
											
		contract	Ownable		{						
			address	owner	;						
											
			function	Ownable	() {						
				owner	= msg.sender;						
			}								
											
			modifier	onlyOwner	() {						
				require(msg.sender ==		owner	);				
				_;							
			}								
											
			function 	transfertOwnership		(address	newOwner	)	onlyOwner	{	
				owner	=	newOwner	;				
			}								
		}									
											
											
											
		contract	BIPOOH_DAO_32_b				is	Ownable	{		
											
			string	public	constant	name =	"	BIPOOH_DAO_32_b		"	;
			string	public	constant	symbol =	"	BIPI		"	;
			uint32	public	constant	decimals =		18			;
			uint	public		totalSupply =		0			;
											
			mapping (address => uint) balances;								
			mapping (address => mapping(address => uint)) allowed;								
											
			function mint(address _to, uint _value) onlyOwner {								
				assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);							
				balances[_to] += _value;							
				totalSupply += _value;							
			}								
											
			function balanceOf(address _owner) constant returns (uint balance) {								
				return balances[_owner];							
			}								
											
			function transfer(address _to, uint _value) returns (bool success) {								
				if(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {							
					balances[msg.sender] -= _value; 						
					balances[_to] += _value;						
					return true;						
				}							
				return false;							
			}								
											
			function transferFrom(address _from, address _to, uint _value) returns (bool success) {								
				if( allowed[_from][msg.sender] >= _value &&							
					balances[_from] >= _value 						
					&& balances[_to] + _value >= balances[_to]) {						
					allowed[_from][msg.sender] -= _value;						
					balances[_from] -= _value;						
					balances[_to] += _value;						
					Transfer(_from, _to, _value);						
					return true;						
				}							
				return false;							
			}								
											
			function approve(address _spender, uint _value) returns (bool success) {								
				allowed[msg.sender][_spender] = _value;							
				Approval(msg.sender, _spender, _value);							
				return true;							
			}								
											
			function allowance(address _owner, address _spender) constant returns (uint remaining) {								
				return allowed[_owner][_spender];							
			}								
											
			event Transfer(address indexed _from, address indexed _to, uint _value);								
			event Approval(address indexed _owner, address indexed _spender, uint _value);								
											
											
											
//	1	Annexe -1 &#171;&#160;PI_2_1&#160;&#187; ex-post &#233;dition &#171;&#160;BIPOOH_DAO_32&#160;&#187; 									
//	2	-									
//	3	Droits rattach&#233;s, non-publi&#233;s (Contrat&#160;; Nom&#160;; Symbole)									
//	4	&#171;&#160;BIPOOH_DAO_32_b&#160;&#187; ; &#171;&#160;BIPOOH_DAO_32_b&#160;&#187; ; &#171;&#160;BIPI&#160;&#187;									
//	5	Meta-donnees, premier rang									
//	6	&#171;&#160;BIPOOH_DAO_32_b&#160;&#187; ; &#171;&#160;BIPOOH_DAO_32_b&#160;&#187; ; &#171;&#160;BIPI_i&#160;&#187;									
//	7	Meta-donnees, second rang									
//	8	&#171;&#160;BIPOOH_DAO_32_b&#160;&#187; ; &#171;&#160;BIPOOH_DAO_32_b&#160;&#187; ; &#171;&#160;BIPI_j&#160;&#187;									
//	9	Meta-donnees, troisi&#232;me rang									
//	10	&#171;&#160;BIPOOH_DAO_32_b&#160;&#187; ; &#171;&#160;BIPOOH_DAO_32_b&#160;&#187; ; &#171;&#160;BIPI_k&#160;&#187;									
//	11	Droits rattach&#233;s, non-publi&#233;s (Contrat&#160;; Nom&#160;; Symbole)									
//	12	&#171;&#160;BIPOOH_DAO_32_c&#160;&#187; ; &#171;&#160;BIPOOH_DAO_32_c&#160;&#187; ; &#171;&#160;BIPII&#160;&#187;									
//	13	Meta-donnees, premier rang									
//	14	&#171;&#160;BIPOOH_DAO_32_c&#160;&#187; ; &#171;&#160;BIPOOH_DAO_32_c&#160;&#187; ; &#171;&#160;BIPII_i&#160;&#187;									
//	15	Meta-donnees, second rang									
//	16	&#171;&#160;BIPOOH_DAO_32_c&#160;&#187; ; &#171;&#160;BIPOOH_DAO_32_c&#160;&#187; ; &#171;&#160;BIPII_j&#160;&#187;									
//	17	Meta-donnees, troisi&#232;me rang									
//	18	&#171;&#160;BIPOOH_DAO_32_c&#160;&#187; ; &#171;&#160;BIPOOH_DAO_32_c&#160;&#187; ; &#171;&#160;BIPII_k&#160;&#187;									
//	19										
//	20										
//	21										
//	22										
//	23										
//	24										
//	25										
//	26										
//	27										
//	28										
//	29										
//	30										
//	31										
//	32										
//	33										
//	34										
//	35										
//	36										
//	37										
//	38										
//	39										
//	40										
//	41										
//	42										
//	43										
//	44										
//	45										
//	46										
//	47										
//	48										
//	49										
//	50										
//	51										
//	52										
//	53										
//	54										
//	55										
//	56										
//	57										
//	58										
//	59										
//	60										
//	61										
//	62										
//	63										
//	64										
//	65										
//	66										
//	67										
//	68										
//	69										
//	70										
//	71										
//	72										
//	73										
//	74										
//	75										
//	76										
//	77										
//	78										
											
											
		}