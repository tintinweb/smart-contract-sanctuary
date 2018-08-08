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
											
											
											
		contract	YUZHURALZOLOTO_FORM_01				is	Ownable	{		
											
			string	public	constant	name =	"	YUZHURALZOLOTO_FORM_01		"	;
			string	public	constant	symbol =	"	UZU_01		"	;
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
										
											
											
											
//	1	Possible 1.1 &#171; cr&#233;dit&#160;&#187;					&#171; D&#233;faut obligataire, obilgation (i), nominal&#160;&#187;				
//	2	Possible 1.2 &#171; cr&#233;dit&#160;&#187;					&#171; D&#233;faut obligataire, obilgation (i), int&#233;r&#234;ts&#160;&#187;				
//	3	Possible 1.3 &#171; cr&#233;dit&#160;&#187;					&#171; D&#233;faut obligataire, obilgation (iI), nominal&#160;&#187;				
//	4	Possible 1.4 &#171; cr&#233;dit&#160;&#187;					&#171; D&#233;faut obligataire, obilgation (ii), int&#233;r&#234;ts&#160;&#187;				
//	5	Possible 1.5 &#171; cr&#233;dit&#160;&#187;					&#171; Assurance-cr&#233;dit, support = police (i)&#160;&#187;				
//	6	Possible 1.6 &#171; cr&#233;dit&#160;&#187;					&#171; Assurance-cr&#233;dit, support = portefeuille de polices (j)&#160;&#187;				
//	7	Possible 1.7 &#171; cr&#233;dit&#160;&#187;					&#171; Assurance-cr&#233;dit, support = indice de polices (k)&#160;&#187;				
//	8	Possible 1.8 &#171; cr&#233;dit&#160;&#187;					&#171; Assurance-cr&#233;dit export, support = police (i)&#160;&#187;				
//	9	Possible 1.9 &#171; cr&#233;dit&#160;&#187;					&#171; Assurance-cr&#233;dit export, support = portefeuille de polices (j)&#160;&#187;				
//	10	Possible 1.10 &#171; cr&#233;dit&#160;&#187;					&#171; Assurance-cr&#233;dit export, support = indice de polices (k)&#160;&#187;				
//	11	Possible 2.1 &#171; liquidit&#233;&#160;&#187;					&#171; Tr&#233;sorerie libre&#160;&#187;				
//	12	Possible 2.2 &#171; liquidit&#233;&#160;&#187;					&#171; Capacit&#233; temporaire &#224; g&#233;n&#233;rer des flux de tr&#233;sorerie libre&#160;&#187;				
//	13	Possible 2.3 &#171; liquidit&#233;&#160;&#187;					&#171; Capacit&#233;s structurelles &#224; g&#233;n&#233;rer ces flux&#160;&#187;				
//	14	Possible 2.4 &#171; liquidit&#233;&#160;&#187;					&#171; Acc&#232;s aux d&#233;couverts &#224; court terme&#160;&#187;				
//	15	Possible 2.5 &#171; liquidit&#233;&#160;&#187;					&#171; Acc&#232;s aux d&#233;couverts &#224; moyen terme&#160;&#187;				
//	16	Possible 2.6 &#171; liquidit&#233;&#160;&#187;					&#171; Acc&#232;s aux financements&#160;bancaires &#187;				
//	17	Possible 2.7 &#171; liquidit&#233;&#160;&#187;					&#171; Acc&#232;s aux financements&#160;institutionnels non-bancaires &#187;				
//	18	Possible 2.8 &#171; liquidit&#233;&#160;&#187;					&#171; Acc&#232;s aux financements&#160;de pools pair &#224; pair &#187;				
//	19	Possible 2.9 &#171; liquidit&#233;&#160;&#187;					&#171; IP-Matrice entit&#233;s&#160;&#187;				
//	20	Possible 2.10 &#171; liquidit&#233;&#160;&#187;					&#171; IP-Matrice juridictions&#160;&#187;				
//	21	Possible 3.1 &#171; solvabilit&#233;&#160;&#187;					&#171; Niveau du ratio de solvabilit&#233; &#187;				
//	22	Possible 3.2 &#171; solvabilit&#233;&#160;&#187;					&#171; Restructuration &#187;				
//	23	Possible 3.3 &#171; solvabilit&#233;&#160;&#187;					&#171; Redressement &#187;				
//	24	Possible 3.4 &#171; solvabilit&#233;&#160;&#187;					&#171; Liquidation &#187;				
//	25	Possible 3.5 &#171; solvabilit&#233;&#160;&#187;					&#171; D&#233;claration de faillite, statut (i) &#187;				
//	26	Possible 3.6 &#171; solvabilit&#233;&#160;&#187;					&#171; D&#233;claration de faillite, statut (ii) &#187;				
//	27	Possible 3.7 &#171; solvabilit&#233;&#160;&#187;					&#171; D&#233;claration de faillite, statut (iii) &#187;				
//	28	Possible 3.8 &#171; solvabilit&#233;&#160;&#187;					&#171; Faillite effective / de fait &#187;				
//	29	Possible 3.9 &#171; solvabilit&#233;&#160;&#187;					&#171; IP-Matrice entit&#233;s&#160;&#187;				
//	30	Possible 3.10 &#171; solvabilit&#233;&#160;&#187;					&#171; IP-Matrice juridictions&#160;&#187;				
//	31	Possible 4.1 &#171; &#233;tats financiers&#160;&#187;					&#171; Chiffres d&#39;affaires &#187;				
//	32	Possible 4.2 &#171; &#233;tats financiers&#160;&#187;					&#171; Taux de rentabilit&#233; &#187;				
//	33	Possible 4.3 &#171; &#233;tats financiers&#160;&#187;					&#171; El&#233;ments bilantiels &#187;				
//	34	Possible 4.4 &#171; &#233;tats financiers&#160;&#187;					&#171; El&#233;ments relatifs aux ngagements hors-bilan &#187;				
//	35	Possible 4.5 &#171; &#233;tats financiers&#160;&#187;					&#171; El&#233;ments relatifs aux engagements hors-bilan : assurances sociales &#187;				
//	36	Possible 4.6 &#171; &#233;tats financiers&#160;&#187;					&#171; El&#233;ments relatifs aux engagements hors-bilan : prestations de rentes &#187;				
//	37	Possible 4.7 &#171; &#233;tats financiers&#160;&#187;					&#171; Capacit&#233;s de titrisation &#187;				
//	38	Possible 4.8 &#171; &#233;tats financiers&#160;&#187;					&#171; Simulations &#233;l&#233;ments OBS (i) &#187;				
//	39	Possible 4.9 &#171; &#233;tats financiers&#160;&#187;					&#171; Simulations &#233;l&#233;ments OBS (ii) &#187;				
//	40	Possible 4.10 &#171; &#233;tats financiers&#160;&#187;					&#171; Simulations &#233;l&#233;ments OBS (iii) &#187;				
//	41	Possible 5.1 &#171; fonctions march&#233;s&#160;&#187;					&#171; Ressources informationnelles brutes &#187;				
//	42	Possible 5.2 &#171; fonctions march&#233;s&#160;&#187;					&#171; Ressources prix indicatifs &#187;				
//	43	Possible 5.3 &#171; fonctions march&#233;s&#160;&#187;					&#171; Ressources prix fermes &#187;  / &#171; Carnets d&#39;ordres &#187;				
//	44	Possible 5.4 &#171; fonctions march&#233;s&#160;&#187;					&#171; Routage &#187;				
//	45	Possible 5.5 &#171; fonctions march&#233;s&#160;&#187;					&#171; N&#233;goce &#187;				
//	46	Possible 5.6 &#171; fonctions march&#233;s&#160;&#187;					&#171; Places de march&#233; &#187;				
//	47	Possible 5.7 &#171; fonctions march&#233;s&#160;&#187;					&#171; Infrastructures mat&#233;rielles &#187;				
//	48	Possible 5.8 &#171; fonctions march&#233;s&#160;&#187;					&#171; Infrastructures logicielles &#187;				
//	49	Possible 5.9 &#171; fonctions march&#233;s&#160;&#187;					&#171; Services de maintenance &#187;				
//	50	Possible 5.10 &#171; fonctions march&#233;s&#160;&#187;					&#171; Solutions de renouvellement &#187;				
//	51	Possible 6.1 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s contrepartie centrale &#187;				
//	52	Possible 6.2 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s garant &#187;				
//	53	Possible 6.3 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s d&#233;positaire &#187; / &#171; Acc&#232;s d&#233;positaire-contrepartie centrale&#160;&#187;				
//	54	Possible 6.4 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s chambre de compensation&#160;&#187;				
//	55	Possible 6.5 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s op&#233;rateur de r&#232;glement-livraison&#160;&#187;				
//	56	Possible 6.6 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s teneur de compte&#160;&#187;				
//	57	Possible 6.7 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s march&#233;s pr&#234;ts-emprunts de titres&#160;&#187;				
//	58	Possible 6.8 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s r&#233;mun&#233;ration des comptes de devises en d&#233;p&#244;t&#160;&#187;				
//	59	Possible 6.9 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s r&#233;mun&#233;ration des comptes d&#39;actifs en d&#233;p&#244;t&#160;&#187;				
//	60	Possible 6.10 &#171; m&#233;tiers post-march&#233;s&#160;&#187;					&#171; Acc&#232;s aux m&#233;canismes de d&#233;p&#244;t et appels de marge&#160;&#187;				
//	61	Possible 7.1 &#171; services financiers annexes&#160;&#187;					&#171; Syst&#232;me international de notation&#160;/ sph&#232;re (i) &#187;				
//	62	Possible 7.2 &#171; services financiers annexes&#160;&#187;					&#171; Syst&#232;me international de notation&#160;/ sph&#232;re (ii) &#187;				
//	63	Possible 7.3 &#171; services financiers annexes&#160;&#187;					&#171; Ressources informationnelles : &#233;tudes et recherches&#160;/ sph&#232;re (i) &#187;				
//	64	Possible 7.4 &#171; services financiers annexes&#160;&#187;					&#171; Ressources informationnelles : &#233;tudes et recherches&#160;/ sph&#232;re (ii) &#187;				
//	65	Possible 7.5 &#171; services financiers annexes&#160;&#187;					&#171; Eligibilit&#233;, groupe (i) &#187;				
//	66	Possible 7.6 &#171; services financiers annexes&#160;&#187;					&#171; Eligibilit&#233;, groupe (ii) &#187;				
//	67	Possible 7.7 &#171; services financiers annexes&#160;&#187;					&#171; Identifiant syst&#232;me de pr&#233;l&#232;vements programmables &#187;				
//	68	Possible 7.8 &#171; services financiers annexes&#160;&#187;					&#171; Ressources actuarielles &#187;				
//	69	Possible 7.9 &#171; services financiers annexes&#160;&#187;					&#171; Services fiduciaires &#187;				
//	70	Possible 7.10 &#171; services financiers annexes&#160;&#187;					&#171; Standards de pr&#233;vention et remise sur primes de couverture &#187;				
//	71	Possible 8.1 &#171; services financiers annexes&#160;&#187;					&#171; N&#233;goce / front &#187;				
//	72	Possible 8.2 &#171; services financiers annexes&#160;&#187;					&#171; N&#233;goce / OTC &#187;				
//	73	Possible 8.3 &#171; services financiers annexes&#160;&#187;					&#171; Contr&#244;le / middle &#187;				
//	74	Possible 8.4 &#171; services financiers annexes&#160;&#187;					&#171; Autorisation / middle &#187;				
//	75	Possible 8.5 &#171; services financiers annexes&#160;&#187;					&#171; Comptabilit&#233; / back &#187;				
//	76	Possible 8.6 &#171; services financiers annexes&#160;&#187;					&#171; R&#233;vision interne &#187;				
//	77	Possible 8.7 &#171; services financiers annexes&#160;&#187;					&#171; R&#233;vision externe &#187;				
//	78	Possible 8.8 &#171; services financiers annexes&#160;&#187;					&#171; Mise en conformit&#233; &#187;				
											
											
											
											
//	79	Possible 9.1 &#171; syst&#232;me bancaire&#160;&#187;					&#171; National&#160;&#187;				
//	80	Possible 9.2 &#171; syst&#232;me bancaire&#160;&#187;					&#171; International&#160;&#187;				
//	81	Possible 9.3 &#171; syst&#232;me bancaire&#160;&#187;					&#171; Holdings-filiales-groupes&#160;&#187;				
//	82	Possible 9.4 &#171; syst&#232;me bancaire&#160;&#187;					&#171; Syst&#232;me de paiement sph&#232;re (i = pro)&#160;&#187;				
//	83	Possible 9.5 &#171; syst&#232;me bancaire&#160;&#187;					&#171; Syst&#232;me de paiement sph&#232;re (ii = v)&#160;&#187;				
//	84	Possible 9.6 &#171; syst&#232;me bancaire&#160;&#187;					&#171; Syst&#232;me de paiement sph&#232;re (iii = neutre)&#160;&#187;				
//	85	Possible 9.7 &#171; syst&#232;me bancaire&#160;&#187;					&#171; Syst&#232;me d&#39;encaissement sph&#232;re (i = pro)&#160;&#187;				
//	86	Possible 9.8 &#171; syst&#232;me bancaire&#160;&#187;					&#171; Syst&#232;me d&#39;encaissement sph&#232;re (ii = v)&#160;&#187;				
//	87	Possible 9.9 &#171; syst&#232;me bancaire&#160;&#187;					&#171; Syst&#232;me d&#39;encaissement sph&#232;re (iii = neutre)&#160;&#187;				
//	88	Possible 9.10 &#171; syst&#232;me bancaire&#160;&#187;					&#171; Confer <fonctions march&#233;> (*)&#160;&#187;				
//	89	Possible 10.1 &#171; syst&#232;me financier&#160;&#187;					&#171; Confer <m&#233;tiers post-march&#233;> (**)&#160;&#187;				
//	90	Possible 10.2 &#171; syst&#232;me financier&#160;&#187;					&#171; Configuration sp&#233;cifique Mikola&#239;ev&#160;&#187;				
//	91	Possible 10.3 &#171; syst&#232;me financier&#160;&#187;					&#171; Configuration sp&#233;cifique Donetsk&#160;&#187;				
//	92	Possible 10.4 &#171; syst&#232;me financier&#160;&#187;					&#171; Configuration sp&#233;cifique Louhansk&#160;&#187;				
//	93	Possible 10.5 &#171; syst&#232;me financier&#160;&#187;					&#171; Configuration sp&#233;cifique S&#233;bastopol&#160;&#187;				
//	94	Possible 10.6 &#171; syst&#232;me financier&#160;&#187;					&#171; Configuration sp&#233;cifique Kharkiv&#160;&#187;				
//	95	Possible 10.7 &#171; syst&#232;me financier&#160;&#187;					&#171; Configuration sp&#233;cifique Makhachkala&#160;&#187;				
//	96	Possible 10.8 &#171; syst&#232;me financier&#160;&#187;					&#171; Configuration sp&#233;cifique Apraksin Dvor&#160;&#187;				
//	97	Possible 10.9 &#171; syst&#232;me financier&#160;&#187;					&#171; Configuration sp&#233;cifique Chelyabinsk&#160;&#187;				
//	98	Possible 10.10 &#171; syst&#232;me financier&#160;&#187;					&#171; Configuration sp&#233;cifique Oziorsk&#160;&#187;				
//	99	Possible 11.1 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; Flux de revenus et transferts courants&#160;&#187; / &#171; IP&#160;&#187;				
//	100	Possible 11.2 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; Flux de revenus et transferts courants&#160;&#187; / &#171; OP&#160;&#187;				
//	101	Possible 11.3 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; Changes, devise (i)&#160;&#187;				
//	102	Possible 11.4 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; Changes, devise (ii)&#160;&#187;				
//	103	Possible 11.5 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; Instruments mon&#233;taires d&#233;riv&#233;s&#160;&#187;				
//	104	Possible 11.6 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; swaps&#160;&#187;				
//	105	Possible 11.7 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; swaptions&#160;&#187;				
//	106	Possible 11.8 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; solutions crois&#233;es chiffr&#233;es-fiat&#160;&#187;				
//	107	Possible 11.9 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; solutions de ponts inter-cha&#238;nes&#160;&#187;				
//	108	Possible 11.10 &#171; syst&#232;me mon&#233;taire&#160;&#187;					&#171; solutions de sauvegarde inter-cha&#238;nes&#160;&#187;				
//	109	Possible 12.1 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; Juridique&#160;&#187;				
//	110	Possible 12.2 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; Responsabilit&#233; envers les tiers&#160;&#187;				
//	111	Possible 12.3 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; Sanctions&#160;&#187;				
//	112	Possible 12.4 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; G&#233;opolitique&#160;&#187;				
//	113	Possible 12.5 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; Expropriations&#160;&#187;				
//	114	Possible 12.6 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; Compte s&#233;questre&#160;&#187;				
//	115	Possible 12.7 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; Acc&#232;s r&#233;seau de courtage&#160;&#187;				
//	116	Possible 12.8 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; Acc&#232;s titrisation&#160;&#187;				
//	117	Possible 12.9 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; Acc&#232;s syndicats&#160;&#187;				
//	118	Possible 12.10 &#171; march&#233; assurantiel&#160;& r&#233;assurantiel &#187;					&#171; Acc&#232;s pools mutuels de pair &#224; pair&#160;&#187;				
//	119	Possible 13.1 &#171; instruments financiers &#187;					&#171; Matrice : march&#233; primaire / march&#233; secondaire / pools&#160;&#187;				
//	120	Possible 13.2 &#171; instruments financiers &#187;					&#171; Sch&#233;ma de march&#233; non-r&#233;gul&#233;&#160;&#187;				
//	121	Possible 13.3 &#171; instruments financiers &#187;					&#171; Sch&#233;ma de march&#233; non-organis&#233;&#160;&#187;				
//	122	Possible 13.4 &#171; instruments financiers &#187;					&#171; Sch&#233;ma de march&#233; non-syst&#233;matique&#160;&#187;				
//	123	Possible 13.5 &#171; instruments financiers &#187;					&#171; Sch&#233;ma de march&#233; contreparties institutionnelles&#160;&#187;				
//	124	Possible 13.6 &#171; instruments financiers &#187;					&#171; Sch&#233;ma de chiffrement financier - Finance&#160;/ &#233;tats financiers &#187;				
//	125	Possible 13.7 &#171; instruments financiers &#187;					&#171; Sch&#233;ma de chiffrement financier - Banque&#160;/ ratio de cr&#233;dit&#187;				
//	126	Possible 13.8 &#171; instruments financiers &#187;					&#171; Sch&#233;ma de chiffrement financier - Assurance / provisions&#160;&#187;				
//	127	Possible 13.9 &#171; instruments financiers &#187;					&#171; Sch&#233;ma de d&#233;consolidation&#160;&#187;				
//	128	Possible 13.10 &#171; instruments financiers &#187;					&#171; Actions&#160;&#187;				
//	129	Possible 13.11 &#171; instruments financiers &#187;					&#171; Certificats&#160;&#187;				
//	130	Possible 13.12 &#171; instruments financiers &#187;					&#171; Droits associ&#233;s&#160;&#187;				
//	131	Possible 13.13 &#171; instruments financiers &#187;					&#171; Obligations&#160;&#187;				
//	132	Possible 13.14 &#171; instruments financiers &#187;					&#171; Coupons&#160;&#187;				
//	133	Possible 13.15 &#171; instruments financiers &#187;					&#171; Obligations convertibles&#160;&#187;				
//	134	Possible 13.16 &#171; instruments financiers &#187;					&#171; Obligations synth&#233;tiques&#160;&#187;				
//	135	Possible 13.17 &#171; instruments financiers &#187;					&#171; Instruments financiers d&#233;riv&#233;s classiques&#160;/ <plain vanilla> &#187;				
//	136	Possible 13.18 &#171; instruments financiers &#187;					&#171; Instruments financiers d&#233;riv&#233;s sur-mesure, n&#233;goci&#233;s de gr&#233; &#224; gr&#233;&#160;&#187;				
//	137	Possible 13.19 &#171; instruments financiers &#187;					&#171; Produits structur&#233;s&#160;&#187;				
//	138	Possible 13.20 &#171; instruments financiers &#187;					&#171; Garanties&#160;&#187;				
//	139	Possible 13.21 &#171; instruments financiers &#187;					&#171; Cov-lite&#160;&#187;				
//	140	Possible 13.22 &#171; instruments financiers &#187;					&#171; Contrats adoss&#233;s &#224; des droits financiers&#160;&#187;				
//	141	Possible 13.23 &#171; instruments financiers &#187;					&#171; Contrats de permutation du risque d&#39;impay&#233; / cds&#160;&#187;				
//	142	Possible 13.24 &#171; instruments financiers &#187;					&#171; Contrats de rehaussement&#160;&#187;				
//	143	Possible 13.25 &#171; instruments financiers &#187;					&#171; Contrats commerciaux&#160;&#187;				
//	144	Possible 13.26 &#171; instruments financiers &#187;					&#171; Indices&#160;&#187;				
//	145	Possible 13.27 &#171; instruments financiers &#187;					&#171; Indices OP&#160;&#187;				
//	146	Possible 13.28 &#171; instruments financiers &#187;					&#171; Financements (i)&#160;&#187;				
//	147	Possible 13.29 &#171; instruments financiers &#187;					&#171; Financements (ii)&#160;&#187;				
//	148	Possible 13.30 &#171; instruments financiers &#187;					&#171; Financements (iii)&#160;&#187;				
//	149	Empreinte 1.1 &#171; document annexe &#187;					&#171; Couverture relative aux clauses &#233;ventuelles de non-r&#233;exportation&#160;&#187;				
//	150	Empreinte 1.2 &#171; document annexe &#187;					&#171; Couverture SDNs&#160;&#187;				
//	151	Empreinte 1.3 &#171; document annexe &#187;					&#171; Couverture investigations du r&#233;gulateur&#160;&#187;				
//	152	Empreinte 1.4 &#171; document annexe &#187;					&#171; Couverture investigations priv&#233;es&#160;&#187;				
//	153	Empreinte 1.5 &#171; document annexe &#187;					&#171; Couverture renseignement civil&#160;&#187;				
//	154	Empreinte 1.6 &#171; document annexe &#187;					&#171; Couverture renseignement militaire&#160;&#187;				
//	155	Empreinte 1.7 &#171; document annexe &#187;					&#171; Programmes d&#39;apprentissage&#160;&#187;				
//	156	Empreinte 1.8 &#171; document annexe &#187;					&#171; Programmes d&#39;apprentissage autonomes en intelligence &#233;conomique&#160;&#187;				
											
}