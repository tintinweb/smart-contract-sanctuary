pragma solidity 		^0.4.21	;							
												
		interface IERC20Token {										
			function totalSupply() public constant returns (uint);									
			function balanceOf(address tokenlender) public constant returns (uint balance);									
			function allowance(address tokenlender, address spender) public constant returns (uint remaining);									
			function transfer(address to, uint tokens) public returns (bool success);									
			function approve(address spender, uint tokens) public returns (bool success);									
			function transferFrom(address from, address to, uint tokens) public returns (bool success);									
												
			event Transfer(address indexed from, address indexed to, uint tokens);									
			event Approval(address indexed tokenlender, address indexed spender, uint tokens);									
		}										
												
		contract	ANHUI_ANNUITY_DAO_33		{							
												
			address	owner	;							
												
			function	ANHUI_ANNUITY_DAO_33		()	public	{				
				owner	= msg.sender;							
			}									
												
			modifier	onlyOwner	() {							
				require(msg.sender ==		owner	);					
				_;								
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			uint256	Sinistre	=	1000	;					
												
			function	setSinistre	(	uint256	newSinistre	)	public	onlyOwner	{	
				Sinistre	=	newSinistre	;					
			}									
												
			function	getSinistre	()	public	constant	returns	(	uint256	)	{
				return	Sinistre	;						
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			uint256	Sinistre_effectif	=	1000	;					
												
			function	setSinistre_effectif	(	uint256	newSinistre_effectif	)	public	onlyOwner	{	
				Sinistre_effectif	=	newSinistre_effectif	;					
			}									
												
			function	getSinistre_effectif	()	public	constant	returns	(	uint256	)	{
				return	Sinistre_effectif	;						
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			uint256	Realisation	=	1000	;					
												
			function	setRealisation	(	uint256	newRealisation	)	public	onlyOwner	{	
				Realisation	=	newRealisation	;					
			}									
												
			function	getRealisation	()	public	constant	returns	(	uint256	)	{
				return	Realisation	;						
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			uint256	Realisation_effective	=	1000	;					
												
			function	setRealisation_effective	(	uint256	newRealisation_effective	)	public	onlyOwner	{	
				Realisation_effective	=	newRealisation_effective	;					
			}									
												
			function	getRealisation_effective	()	public	constant	returns	(	uint256	)	{
				return	Realisation_effective	;						
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			uint256	Ouverture_des_droits	=	1000	;					
												
			function	setOuverture_des_droits	(	uint256	newOuverture_des_droits	)	public	onlyOwner	{	
				Ouverture_des_droits	=	newOuverture_des_droits	;					
			}									
												
			function	getOuverture_des_droits	()	public	constant	returns	(	uint256	)	{
				return	Ouverture_des_droits	;						
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / UINT 256 / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			uint256	Ouverture_effective	=	1000	;					
												
			function	setOuverture_effective	(	uint256	newOuverture_effective	)	public	onlyOwner	{	
				Ouverture_effective	=	newOuverture_effective	;					
			}									
												
			function	getOuverture_effective	()	public	constant	returns	(	uint256	)	{
				return	Ouverture_effective	;						
			}									
												
												
												
			address	public	User_1		=	msg.sender				;
			address	public	User_2		;//	_User_2				;
			address	public	User_3		;//	_User_3				;
			address	public	User_4		;//	_User_4				;
			address	public	User_5		;//	_User_5				;
												
			IERC20Token	public	Police_1		;//	_Police_1				;
			IERC20Token	public	Police_2		;//	_Police_2				;
			IERC20Token	public	Police_3		;//	_Police_3				;
			IERC20Token	public	Police_4		;//	_Police_4				;
			IERC20Token	public	Police_5		;//	_Police_5				;
												
			uint256	public	Standard_1		;//	_Standard_1				;
			uint256	public	Standard_2		;//	_Standard_2				;
			uint256	public	Standard_3		;//	_Standard_3				;
			uint256	public	Standard_4		;//	_Standard_4				;
			uint256	public	Standard_5		;//	_Standard_5				;
												
			function	Admissibilite_1				(				
				address	_User_1		,					
				IERC20Token	_Police_1		,					
				uint256	_Standard_1							
			)									
				public	onlyOwner							
			{									
				User_1		=	_User_1		;			
				Police_1		=	_Police_1		;			
				Standard_1		=	_Standard_1		;			
			}									
												
			function	Admissibilite_2				(				
				address	_User_2		,					
				IERC20Token	_Police_2		,					
				uint256	_Standard_2							
			)									
				public	onlyOwner							
			{									
				User_2		=	_User_2		;			
				Police_2		=	_Police_2		;			
				Standard_2		=	_Standard_2		;			
			}									
												
			function	Admissibilite_3				(				
				address	_User_3		,					
				IERC20Token	_Police_3		,					
				uint256	_Standard_3							
			)									
				public	onlyOwner							
			{									
				User_3		=	_User_3		;			
				Police_3		=	_Police_3		;			
				Standard_3		=	_Standard_3		;			
			}									
												
			function	Admissibilite_4				(				
				address	_User_4		,					
				IERC20Token	_Police_4		,					
				uint256	_Standard_4							
			)									
				public	onlyOwner							
			{									
				User_4		=	_User_4		;			
				Police_4		=	_Police_4		;			
				Standard_4		=	_Standard_4		;			
			}									
												
			function	Admissibilite_5				(				
				address	_User_5		,					
				IERC20Token	_Police_5		,					
				uint256	_Standard_5							
			)									
				public	onlyOwner							
			{									
				User_5		=	_User_5		;			
				Police_5		=	_Police_5		;			
				Standard_5		=	_Standard_5		;			
			}									
			//									
			//									
												
			function	Indemnisation_1				()	public	{		
				require(	msg.sender == User_1			);				
				require(	Police_1.transfer(User_1, Standard_1)			);				
				require(	Sinistre == Sinistre_effectif			);				
				require(	Realisation == Realisation_effective			);				
				require(	Ouverture_des_droits == Ouverture_effective			);				
			}									
												
			function	Indemnisation_2				()	public	{		
				require(	msg.sender == User_2			);				
				require(	Police_2.transfer(User_1, Standard_2)			);				
				require(	Sinistre == Sinistre_effectif			);				
				require(	Realisation == Realisation_effective			);				
				require(	Ouverture_des_droits == Ouverture_effective			);				
			}									
												
			function	Indemnisation_3				()	public	{		
				require(	msg.sender == User_3			);				
				require(	Police_3.transfer(User_1, Standard_3)			);				
				require(	Sinistre == Sinistre_effectif			);				
				require(	Realisation == Realisation_effective			);				
				require(	Ouverture_des_droits == Ouverture_effective			);				
			}									
												
			function	Indemnisation_4				()	public	{		
				require(	msg.sender == User_4			);				
				require(	Police_4.transfer(User_1, Standard_4)			);				
				require(	Sinistre == Sinistre_effectif			);				
				require(	Realisation == Realisation_effective			);				
				require(	Ouverture_des_droits == Ouverture_effective			);				
			}									
												
			function	Indemnisation_5				()	public	{		
				require(	msg.sender == User_5			);				
				require(	Police_5.transfer(User_1, Standard_5)			);				
				require(	Sinistre == Sinistre_effectif			);				
				require(	Realisation == Realisation_effective			);				
				require(	Ouverture_des_droits == Ouverture_effective			);				
			}									
												
												
												
												
//	1	Descriptif										
//	2	Pool de mutualisation d’assurances sociales										
//	3	Forme juridique										
//	4	Pool pair &#224; pair d&#233;ploy&#233; dans un environnement TP/SC-CDC (*)										
//	5	D&#233;nomination										
//	6	&#171;&#160;ANHUI ANNUITY DAO&#160;&#187; G&#233;n&#233;ration 3.3.										
//	7	Statut										
//	8	&#171;&#160;D.A.O.&#160;&#187; (Organisation autonome et d&#233;centralis&#233;e)										
//	9	Propri&#233;taires & responsables implicites										
//	10	Les Utilisateurs du pool										
//	11	Juridiction (i)										
//	12	Ville de Huaibei, Province d’Anhui, R&#233;publique Populaire de Chine										
//	13	Juridiction (ii)										
//	14	Ville de Baotou, Province de Mongolie-Int&#233;rieure, R&#233;publique Populaire de Chine										
//	15	Instrument mon&#233;taire de r&#233;f&#233;rence (i)										
//	16	&#171;&#160;ethcny&#160;&#187; / &#171;&#160;ethrmb&#160;&#187;										
//	17	Instrument mon&#233;taire de r&#233;f&#233;rence (ii)										
//	18	&#171;&#160;ethchf&#160;&#187;										
//	19	Instrument mon&#233;taire de r&#233;f&#233;rence (iii)										
//	20	&#171;&#160;ethsgd&#160;&#187;										
//	21	Devise de r&#233;f&#233;rence (i)										
//	22	&#171;&#160;CNY&#160;&#187; / &#171;&#160;RMB&#160;&#187;										
//	23	Devise de r&#233;f&#233;rence (ii)										
//	24	&#171;&#160;CHF&#160;&#187;										
//	25	Devise de r&#233;f&#233;rence (iii)										
//	26	&#171;&#160;SGD&#160;&#187;										
//	27	Date de d&#233;ployement initial										
//	28	15/06/2017										
//	29	Environnement de d&#233;ployement initial										
//	30	(1&#160;: 15.06.2017-01.08.2017) OTC (Luzern)&#160;; (2&#160;: 01.08.2017-29.04.2018) suite protocolaire sur-couche &#171;&#160;88.2&#160;&#187; 										
//	31	Objet principal (i)										
//	32	Pool de mutualisation										
//	33	Objet principal (ii)										
//	34	Gestionnaire des encaissements / Agent de calcul										
//	35	Objet principal (iii)										
//	36	Distributeur / Agent payeur										
//	37	Objet principal (iv)										
//	38	D&#233;positaire / Garant										
//	39	Objet principal (v)										
//	40	Administrateur des d&#233;l&#233;gations relatives aux missions de gestion d‘actifs										
//	41	Objet principal (vi)										
//	42	M&#233;tiers et fonctions suppl&#233;mentaires&#160;: confer annexes (**)										
//	43	@ de communication additionnelle (i)										
//	44	0xa24794106a6be5d644dd9ace9cbb98478ac289f5										
//	45	@ de communication additionnelle (ii)										
//	46	0x8580dF106C8fF87911d4c2a9c815fa73CAD1cA38										
//	47	@ de publication additionnelle (protocole PP, i)										
//	48	0xf7Aa11C7d092d956FC7Ca08c108a1b2DaEaf3171										
//	49	Entit&#233; responsable du d&#233;veloppement										
//	50	Programme d’apprentissage autonome &#171;&#160;KYOKO&#160;&#187; / MS (sign)										
//	51	Entit&#233; responsable de l’&#233;dition										
//	52	Programme d’apprentissage autonome &#171;&#160;KYOKO&#160;&#187; / MS (sign)										
//	53	Entit&#233; responsable du d&#233;ployement initial										
//	54	Programme d’apprentissage autonome &#171;&#160;KYOKO&#160;&#187; / MS (sign)										
//	55	(*) Environnement technologique protocolaire / sous-couche de type &#171;&#160;Consensus Distribu&#233; et Chiffr&#233;&#160;&#187;										
//	56	(**) @ Annexes et formulaires&#160;: <<<< --------------------------------- >>>> (confer&#160;: points 43 &#224; 48)										
//	57	-										
//	58	Annexe -1 &#171;&#160;PI_3_1&#160;&#187; ex-post &#233;dition &#171;&#160;ANHUI_ANNUITY_DAO_33&#160;&#187;										
//	59	-										
//	60	Droits rattach&#233;s, non-publi&#233;s (Contrat&#160;; Nom&#160;; Symbole)										
//	61	&#171;&#160;ANHUI_ANNUITY_DAO_33_b&#160;&#187; ; &#171;&#160;ANHUI_ANNUITY_DAO_33_b&#160;&#187; ; &#171;&#160;AAI&#160;&#187;										
//	62	Meta-donnees, premier rang										
//	63	&#171;&#160;ANHUI_ANNUITY_DAO_33_b&#160;&#187; ; &#171;&#160;ANHUI_ANNUITY_DAO_33_b&#160;&#187; ; &#171;&#160;AAI_i&#160;&#187;										
//	64	Meta-donnees, second rang										
//	65	&#171;&#160;ANHUI_ANNUITY_DAO_33_b&#160;&#187; ; &#171;&#160;ANHUI_ANNUITY_DAO_33_b&#160;&#187; ; &#171;&#160;AAI_j&#160;&#187;										
//	66	Meta-donnees, troisi&#232;me rang										
//	67	&#171;&#160;ANHUI_ANNUITY_DAO_33_b&#160;&#187; ; &#171;&#160;ANHUI_ANNUITY_DAO_33_b&#160;&#187; ; &#171;&#160;AAI_k&#160;&#187;										
//	68	Droits rattach&#233;s, publi&#233;s (Contrat&#160;; Nom&#160;; Symbole)										
//	69	&#171;&#160;ANHUI_ANNUITY_DAO_33_c&#160;&#187; ; &#171;&#160;ANHUI_ANNUITY_DAO_33_c&#160;&#187; ; &#171;&#160;AAII&#160;&#187;										
//	70	Meta-donnees, premier rang										
//	71	&#171;&#160;ANHUI_ANNUITY_DAO_33_c&#160;&#187; ; &#171;&#160;ANHUI_ANNUITY_DAO_33_c&#160;&#187; ; &#171;&#160;AAII_i&#160;&#187;										
//	72	Meta-donnees, second rang										
//	73	&#171;&#160;ANHUI_ANNUITY_DAO_33_c&#160;&#187; ; &#171;&#160;ANHUI_ANNUITY_DAO_33_c&#160;&#187; ; &#171;&#160;AAII_j&#160;&#187;										
//	74	Meta-donnees, troisi&#232;me rang										
//	75	&#171;&#160;ANHUI_ANNUITY_DAO_33_c&#160;&#187; ; &#171;&#160;ANHUI_ANNUITY_DAO_33_c&#160;&#187; ; &#171;&#160;AAII_k&#160;&#187;										
//	76	-										
//	77	-										
//	78	-										
//	79	-										
												
												
												
//	1	&#171; Sans franchise / Plafond (min-max.) de (x_1)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_1)&#160;&#187; &#171; Assurance-ch&#244;mage / Assurance compl&#233;mentaire-ch&#244;mage&#160;&#187;										
//	2	&#171; Sans franchise / Plafond (min-max.) de (x_2)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_2)&#160;&#187; &#171; Garantie d’acc&#232;s &#224; la formation / Prise en charge des frais de formation&#160;&#187;										
//	3	&#171; Sans franchise / Plafond (min-max.) de (x_3)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_3)&#160;&#187; &#171; Prise en charge des frais de transport / Prise en charge des frais de repas&#160;&#187;										
//	4	&#171; Sans franchise / Plafond (min-max.) de (x_4)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_4)&#160;&#187; &#171; Assurance compl&#233;mentaire-ch&#244;mage pour ch&#244;meurs de longue dur&#233;e&#160;&#187;										
//	5	&#171; Sans franchise / Plafond (min-max.) de (x_5)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_5)&#160;&#187; &#171; Compl&#233;mentaire ch&#244;mage sans prestation de ch&#244;mage de base&#160;&#187;										
//	6	&#171; Sans franchise / Plafond (min-max.) de (x_6)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_6)&#160;&#187; &#171; Travailleur en attente du premier emploi, compl. sans prestation de base&#160;&#187;										
//	7	&#171; Sans franchise / Plafond (min-max.) de (x_7)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_7)&#160;&#187; &#171; Garantie de replacement, police souscrite par le salari&#233;&#160;&#187;										
//	8	&#171; Sans franchise / Plafond (min-max.) de (x_8)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_8)&#160;&#187; &#171; Garantie de replacement, police souscrite par l’employeur&#160;&#187;										
//	9	&#171; Sans franchise / Plafond (min-max.) de (x_9)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_9)&#160;&#187; &#171; Garantie de formation dans le cadre d’un replacement professionnel&#160;&#187;										
//	10	&#171; Sans franchise / Plafond (min-max.) de (x_10)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_10)&#160;&#187; &#171; Prise en charge des frais de transport / Prise en charge des frais de repas&#160;&#187;										
//	11	&#171; Sans franchise / Plafond (min-max.) de (x_11)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_11)&#160;&#187; &#171; Couverture m&#233;dicale / Couverture m&#233;dicale compl&#233;mentaire&#160;&#187;										
//	12	&#171; Sans franchise / Plafond (min-max.) de (x_12)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_12)&#160;&#187; &#171; Extension aux enfants de la police des parents / extension famille&#160;&#187;										
//	13	&#171; Sans franchise / Plafond (min-max.) de (x_13)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_13)&#160;&#187; &#171; Couverture, base et compl&#233;mentaire des frais li&#233;s &#224; la pr&#233;vention&#160;&#187;										
//	14	&#171; Sans franchise / Plafond (min-max.) de (x_14)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_14)&#160;&#187; &#171; Rabais sur primes si conditions de pr&#233;vention standard valid&#233;es&#160;&#187;										
//	15	&#171; Sans franchise / Plafond (min-max.) de (x_15)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_15)&#160;&#187; &#171; Sp&#233;icalit&#233;s (Yeux, Dents, Ou&#239;e, Coeur, autres, selon annexes **)&#160;&#187;										
//	16	&#171; Sans franchise / Plafond (min-max.) de (x_16)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_16)&#160;&#187; &#171; Couverture, base et compl&#233;mentaire, relatives aux maladies chroniques&#160;&#187;										
//	17	&#171; Sans franchise / Plafond (min-max.) de (x_17)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_17)&#160;&#187; &#171; Couverture, base et compl&#233;mentaire, relatives aux maladies orphelines&#160;&#187;										
//	18	&#171; Sans franchise / Plafond (min-max.) de (x_18)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_18)&#160;&#187; &#171; Couverture, base et compl&#233;mentaire, charge ambulatoire&#160;&#187;										
//	19	&#171; Sans franchise / Plafond (min-max.) de (x_19)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_19)&#160;&#187; &#171; Couverture, base et compl&#233;mentaire, cliniques (cat. 1-3)&#160;&#187;										
//	20	&#171; Sans franchise / Plafond (min-max.) de (x_20)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_20)&#160;&#187; &#171; Incapacit&#233;s de travail partielle et temporaire&#160;&#187;										
//	21	&#171; Sans franchise / Plafond (min-max.) de (x_21)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_21)&#160;&#187; &#171; Incapacit&#233;s de travail part. et temp. pour cause d’accident professionnel&#160;&#187;										
//	22	&#171; Sans franchise / Plafond (min-max.) de (x_22)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_22)&#160;&#187; &#171; Incapacit&#233; de travail partielle et d&#233;finitive&#160;&#187;										
//	23	&#171; Sans franchise / Plafond (min-max.) de (x_23)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_23)&#160;&#187; &#171; Incapacit&#233; de travail part. et d&#233;finitive pour cause d’accident professionnel&#160;&#187;										
//	24	&#171; Sans franchise / Plafond (min-max.) de (x_24)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_24)&#160;&#187; &#171; Incapacit&#233; de travail, totale et temporaire&#160;&#187;										
//	25	&#171; Sans franchise / Plafond (min-max.) de (x_25)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_25)&#160;&#187; &#171; Incapacit&#233; de travail, totale et temp. pour cause d’accident professionnel&#160;&#187;										
//	26	&#171; Sans franchise / Plafond (min-max.) de (x_26)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_26)&#160;&#187; &#171; Incapacit&#233; de travail, totale et d&#233;finitive&#160;&#187;										
//	27	&#171; Sans franchise / Plafond (min-max.) de (x_27)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_27)&#160;&#187; &#171; Incapacit&#233; de travail, totale et d&#233;finitive pour cause d’accident professionnel&#160;&#187;										
//	28	&#171; Sans franchise / Plafond (min-max.) de (x_28)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_28)&#160;&#187; &#171; Rente en cas d’invalidit&#233; / Rente compl&#233;mentaire&#160;&#187;										
//	29	&#171; Sans franchise / Plafond (min-max.) de (x_29)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_29)&#160;&#187; &#171; Caisses de pension et prestations retraite&#160;&#187;										
//	30	&#171; Sans franchise / Plafond (min-max.) de (x_30)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_30)&#160;&#187; &#171; Caisses de pension et prestations retraite compl&#233;mentaires&#160;&#187;										
//	31	&#171; Sans franchise / Plafond (min-max.) de (x_31)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_31)&#160;&#187; &#171; Garantie d’acc&#232;s, maison de retraite et instituts semi-m&#233;dicalis&#233;s (cat. 1-3)&#160;&#187;										
//	32	&#171; Sans franchise / Plafond (min-max.) de (x_32)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_32)&#160;&#187; &#171; Maison de retraite faisant l’objet d’un partenariat, public ou priv&#233;&#160;&#187;										
//	33	&#171; Sans franchise / Plafond (min-max.) de (x_33)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_33)&#160;&#187; &#171; Assurance-vie, capitalisation&#160;&#187;										
//	34	&#171; Sans franchise / Plafond (min-max.) de (x_34)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_34)&#160;&#187; &#171; Assurance-vie, mutualisation&#160;&#187;										
//	35	&#171; Sans franchise / Plafond (min-max.) de (x_35)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_35)&#160;&#187; &#171; Assurance-vie mixte, capitalisation et mutualisation&#160;&#187;										
//	36	&#171; Sans franchise / Plafond (min-max.) de (x_36)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_36)&#160;&#187; &#171; Couverture contre r&#232;glement d’assurance-vie&#160;&#187;										
//	37	&#171; Sans franchise / Plafond (min-max.) de (x_37)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_37)&#160;&#187; &#171; Constitution d’un capital en vue de donations&#160;&#187;										
//	38	&#171; Sans franchise / Plafond (min-max.) de (x_38)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_38)&#160;&#187; &#171; Couverture I & T sur donations&#160;&#187;										
//	39	&#171; Sans franchise / Plafond (min-max.) de (x_39)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_39)&#160;&#187; &#171; Couverture sur &#233;volution I & T sur donations, approche mutuailste&#160;&#187;										
//	40	&#171; Sans franchise / Plafond (min-max.) de (x_40)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_40)&#160;&#187; &#171; Frais d’obs&#232;que / Location / Entretien des places et / ou des strctures&#160;&#187;										
//	41	&#171; Sans franchise / Plafond (min-max.) de (x_41)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_41)&#160;&#187; &#171; Garantie d’&#233;tablissement, groupe UE / non-groupe UE&#160;&#187;										
//	42	&#171; Sans franchise / Plafond (min-max.) de (x_42)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_42)&#160;&#187; &#171; Garantie de r&#233;sidence, groupe UE / non-groupe UE&#160;&#187;										
//	43	&#171; Sans franchise / Plafond (min-max.) de (x_43)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_43)&#160;&#187; &#171; Couvertures relatives aux risques d’&#233;tablissement, zones sp&#233;ciales (**)&#160;&#187;										
//	44	&#171; Sans franchise / Plafond (min-max.) de (x_44)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_44)&#160;&#187; &#171; Rente famille monoparentale, enfant(s) survivant(s)&#160;&#187;										
//	45	&#171; Sans franchise / Plafond (min-max.) de (x_45)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_45)&#160;&#187; &#171; Rente famille non-monoparentale, enfant(s) survivant(s)&#160;&#187;										
//	46	&#171; Sans franchise / Plafond (min-max.) de (x_46)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_46)&#160;&#187; &#171; R. pour proches parents si prise en charge et tutelle des enfants survivants&#160;&#187;										
//	47	&#171; Sans franchise / Plafond (min-max.) de (x_47)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_47)&#160;&#187; &#171; Couverture m&#233;dicale, base et compl&#233;mentaire&#160;&#187;										
//	48	&#171; Sans franchise / Plafond (min-max.) de (x_48)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_48)&#160;&#187; &#171; Constitution et pr&#233;servation d’un capital / fideicommis&#160;&#187;										
//	49	&#171; Sans franchise / Plafond (min-max.) de (x_49)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_49)&#160;&#187; &#171; Couverture compl&#233;mentaire / Allocation grossesse / Maternit&#233;&#160;&#187;										
//	50	&#171; Sans franchise / Plafond (min-max.) de (x_50)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_50)&#160;&#187; &#171; Couverture compl&#233;mentaire / Allocation de naissance&#160;&#187;										
//	51	&#171; Sans franchise / Plafond (min-max.) de (x_51)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_51)&#160;&#187; &#171; Couverture compl&#233;mentaire / Naissances multiples&#160;&#187;										
//	52	&#171; Sans franchise / Plafond (min-max.) de (x_52)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_52)&#160;&#187; &#171; Couverture compl&#233;mentaire / Allocations familiales&#160;&#187;										
//	53	&#171; Sans franchise / Plafond (min-max.) de (x_53)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_53)&#160;&#187; &#171; Frais de garde d’enfants, structure individuelle / structure collective&#160;&#187;										
//	54	&#171; Sans franchise / Plafond (min-max.) de (x_54)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_54)&#160;&#187; &#171; Hospitalisation d’un enfant de moins de huit ans, d&#232;s le premier jour (i) -&#160;&#187;										
//	55	&#171; Sans franchise / Plafond (min-max.) de (x_55)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_55)&#160;&#187; &#171; Hospitalisation d’un enfant de moins de huit ans, d&#232;s le cinqui&#232;me jour (ii) -&#160;&#187;										
//	56	&#171; Sans franchise / Plafond (min-max.) de (x_56)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_56)&#160;&#187; &#171; Pour un parent, &#224; d&#233;faut un membre de la famille proche -&#160;&#187;										
//	57	&#171; Sans franchise / Plafond (min-max.) de (x_57)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_57)&#160;&#187; &#171; A d&#233;faut, un tiers d&#233;sign&#233; par le ou les tuteurs l&#233;gaux -&#160;&#187;										
//	58	&#171; Sans franchise / Plafond (min-max.) de (x_58)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_58)&#160;&#187; &#171; Transport / repas / domicile / lieu d’hospitalisation&#160;&#187;										
//	59	&#171; Sans franchise / Plafond (min-max.) de (x_59)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_59)&#160;&#187; &#171; H&#233;bergement directement sur le lieu d’hospitalisation&#160;&#187;										
//	60	&#171; Sans franchise / Plafond (min-max.) de (x_60)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_60)&#160;&#187; &#171; Frais relatifs &#224; la prise en charge des autres enfants&#160;&#187;										
//	61	&#171; Sans franchise / Plafond (min-max.) de (x_61)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_61)&#160;&#187; &#171; Garde de jour / garde de nuit des autres enfants / Perte partielle ou totale de revenus&#160;&#187;										
//	62	&#171; Sans franchise / Plafond (min-max.) de (x_62)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_62)&#160;&#187; &#171; Enfants + soins sp&#233;cifiques &#224; domicile - (confer annexe **)&#160;&#187;										
//	63	&#171; Sans franchise / Plafond (min-max.) de (x_63)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_63)&#160;&#187; &#171; Garantie de revenus / Compl&#233;mentaire revenus&#160;&#187;										
//	64	&#171; Sans franchise / Plafond (min-max.) de (x_64)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_64)&#160;&#187; &#171; Couverture pour incapacit&#233; de paiement / dont I & T (approche mutualiste)&#160;&#187;										
//	65	&#171; Sans franchise / Plafond (min-max.) de (x_65)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_65)&#160;&#187; &#171; Financement pour paiement / dont I & T (approche capitalisation)&#160;&#187;										
//	66	&#171; Sans franchise / Plafond (min-max.) de (x_66)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_66)&#160;&#187; &#171; Garantie d’acc&#232;s &#224; la propri&#233;t&#233; et / ou acquisition fonci&#232;re / Apport / Financement / Couverture de taux&#160;&#187;										
//	67	&#171; Sans franchise / Plafond (min-max.) de (x_67)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_67)&#160;&#187; &#171; Garantie relative au prix d’acquisition / dont &#171;&#160;&#224; terme&#160;&#187;&#160;&#187;										
//	68	&#171; Sans franchise / Plafond (min-max.) de (x_68)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_68)&#160;&#187; &#171; Garantie de la valeur du bien / Garantie de non-saisie&#160;&#187;										
//	69	&#171; Sans franchise / Plafond (min-max.) de (x_69)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_69)&#160;&#187; &#171; Garantie d’acc&#232;s au march&#233; locatif / plafonnement des loyers / Acc&#232;s aux aides pr&#233;vues pour les locataires&#160;&#187;										
//	70	&#171; Sans franchise / Plafond (min-max.) de (x_70)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_70)&#160;&#187; &#171; Garantie de remise de bail / Acc&#232;s caution de tiers&#160;&#187;										
//	71	&#171; Sans franchise / Plafond (min-max.) de (x_71)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_71)&#160;&#187; &#171; Enl&#232;vements - (confer annexe **)&#160;&#187;										
//	72	&#171; Sans franchise / Plafond (min-max.) de (x_72)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_72)&#160;&#187; &#171; Maison / Trasnports - (confer annexe **)&#160;&#187;										
//	73	&#171; Sans franchise / Plafond (min-max.) de (x_73)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_73)&#160;&#187; &#171; Responsabilit&#233; envers les tiers - (confer annexe **)&#160;&#187;										
//	74	&#171; Sans franchise / Plafond (min-max.) de (x_74)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_74)&#160;&#187; &#171; Moyens de communication - (confer annexe **)&#160;&#187;										
//	75	&#171; Sans franchise / Plafond (min-max.) de (x_75)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_75)&#160;&#187; &#171; Liquidit&#233;s - (confer annexe **)&#160;&#187;										
//	76	&#171; Sans franchise / Plafond (min-max.) de (x_76)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_76)&#160;&#187; &#171; Acc&#232;s au r&#233;seau bancaire / r&#233;seau des paiements / Acc&#232;s aux moyens de paiement / Emetteurs cartes de cr&#233;dits&#160;&#187;										
//	77	&#171; Sans franchise / Plafond (min-max.) de (x_77)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_77)&#160;&#187; &#171; Acc&#232;s au cr&#233;dit / octroie de caution&#160;&#187;										
//	78	&#171; Sans franchise / Plafond (min-max.) de (x_78)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_78)&#160;&#187; &#171; (***) Frais d’&#233;colage&#160;; formation annexe&#160;&#187;										
//	79	&#171; Sans franchise / Plafond (min-max.) de (x_79)* indemnisation de base, &#224; d&#233;faut, Forfait (min-max.) de (y_79)&#160;&#187; &#171; Frais d’&#233;colage&#160;: bourses d’&#233;tude / Baisse du revenu / Acc&#232;s au financement / Octroie de caution / Capitalisation&#160;&#187;										
												
												
												
//	1	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.1&#160;&#187;					&#171; 4Y188Ik558fxS05nD6vL4r35lo7hOm3t227z2j1i7VK56u33EwK4IYxE0GCPHP76&#160;&#187;					
//	2	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.2&#160;&#187;					&#171; aZ6k95T6YVpPETU80sa8vrSPja3AKc6CPxcwW2F37EbmTErEkZ23KDqt5oISCjPX&#160;&#187;					
//	3	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.3&#160;&#187;					&#171; hEKQDJ0rxcGVb55Zjp9u96M776dOkR47b877fKGNiBh6EzMl5wIemr9dhROi576a&#160;&#187;					
//	4	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.4&#160;&#187;					&#171; wEltTzjYwz1c8JL0R5Za0XIoT72V6I5k14709Gbtga6oP08SfwDu09I40on66H7K&#160;&#187;					
//	5	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.5&#160;&#187;					&#171; KGcr4mlGIO3sn4TNmYh2477k7n3Z5jr4meJe71oee2C68Jbvygco36NO9zOS9335&#160;&#187;					
//	6	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.6&#160;&#187;					&#171; dZT4GS758Z1T7xfF156i77UWzIn0rdUegdVVc4rLs2oR1MkN5ByyS03o59p9zKn7&#160;&#187;					
//	7	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.7&#160;&#187;					&#171; 22BwZBb0wBPnk74kNS8S3lzSiNgUhx848OM8724DqbumbElR4X5JXFIwVy761W27&#160;&#187;					
//	8	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.8&#160;&#187;					&#171; q8L5sz61BX8tgjCNwQO17F197M9rwO58NjXs0791jTqiptIrkhwzHAc15J887Q66&#160;&#187;					
//	9	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.9&#160;&#187;					&#171; eawfPO50O4s6ydiWzPeJ2fwS8VrjXq9u59em1ODTegsuDne680r303H5UzlEhZZp&#160;&#187;					
//	10	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.10&#160;&#187;					&#171; Tia22Y5e519BoPjG9149Cf22D2C2D0CT8M3yBXrj5064aW2NI2fYcN117Z2llvjL&#160;&#187;					
//	11	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.11&#160;&#187;					&#171; 6mfdiG37e5fN5Mlwh6gLDBXM6cCN9Pa6Nst9a25s5SZS4v3dD7u7s6jG93if1Xn4&#160;&#187;					
//	12	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.12&#160;&#187;					&#171; 8jU283TOljQ9307bZY8J7CmR1jW1G2y7e392g335Rf3OU5dO9bR2I6w98ZYV9miC&#160;&#187;					
//	13	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.13&#160;&#187;					&#171; w38YS8w5zmV6097hchmXu4x1Ugyp1Q8lHcF56J5VB0rlcdC51klZVKyCMkBT2xhr&#160;&#187;					
//	14	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.14&#160;&#187;					&#171; vH4aoNYLKxa5cgKQ4tHj9P59q361jM1qJJ2D165M61m9ywh9RR31ENauFDi6YVPJ&#160;&#187;					
//	15	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.15&#160;&#187;					&#171; 475wRmu5C79enX8p0bBVx4ZHOH1zk1fEAOo0ZeCZ7Y6zubqF5pfEfSOm6MA9K6lz&#160;&#187;					
//	16	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.16&#160;&#187;					&#171; S0c9n5huh0l01L213ol8v30UtHLSFGOhR87yy3E58NN18v6UCAemkUkiY7Yps54F&#160;&#187;					
//	17	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.17&#160;&#187;					&#171; mft7HcCTn6D4Yq52p3Pgp37iAaTpA79HU82CIM7hkZ1q9ZhU7IJ7v16Xh47e6k9E&#160;&#187;					
//	18	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.18&#160;&#187;					&#171; 5jBw8rJPkMXHGn7C5y9HU7AZ2mYk8785446Oz9Wh6PL7eF0VhPkE8i010qPx29V6&#160;&#187;					
//	19	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.19&#160;&#187;					&#171; s2gyvl7dYU0Ke6n0jr8uGRQVV7kKNdLs3g6Rh2eF9v7QUj8wzhAfWKt5T2LDzZJ0&#160;&#187;					
//	20	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.20&#160;&#187;					&#171; 04beaSBCpJ6B3oM3VTlxJ79m80o1M67KWWBhik4gNdDgq9iAPkAgP0m9Q0PXS8lP&#160;&#187;					
//	21	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.21&#160;&#187;					&#171; yvhzC9W68rQM8wN8F4nCT6MW849hNYrmB3Qq45z1v5xB1eeg6T7H31739j6o7Y9a&#160;&#187;					
//	22	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.22&#160;&#187;					&#171; FF5zdHPa4I33se4sH1GH4U3Dh2H8F19b10EkSkC3F1dHB372C6kNwiC3h7qC95XN&#160;&#187;					
//	23	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.23&#160;&#187;					&#171; e3il277xGt1RpYQiNoN109FaX4QS32iC9AvBHGdN9Fz71q4pMW4OMf2plZaM16v9&#160;&#187;					
//	24	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.24&#160;&#187;					&#171; 4nz8048ubGH9dcZ82CqEhU5EbenWi6L2d2P3hpxb1TQP301USbLRV9TtY3hdp255&#160;&#187;					
//	25	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.25&#160;&#187;					&#171; x65PzxSV3iC6j7VF13KZABR843sWn1h1Xl8NL5coh13Pn7mkImvLkkEBd1XpAz0E&#160;&#187;					
//	26	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.26&#160;&#187;					&#171; dm8FnY66Oa7EQmo2t1I93LCM57wsWrJR5DU81O24C4fvXn261UAzmFuFA9TE8u34&#160;&#187;					
//	27	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.27&#160;&#187;					&#171; 3YAiBBhcbbY0K3jd6t8npEOwTgbqNSrwek3k354fMEmqmeQqMQk7mut8655lVWaI&#160;&#187;					
//	28	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.28&#160;&#187;					&#171; K3xmQoq98w6Ou5egNtuWeGSTKI3KEWrUzvFlZ1xeqsK6QAT9Ia3EknpfFIED3Exr&#160;&#187;					
//	29	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.29&#160;&#187;					&#171; 755iA4fapMqlQy3593UMT8ICH36l6olMTvZU0p0b0lG0rTW4D43NdQvI33JckPO5&#160;&#187;					
//	30	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.30&#160;&#187;					&#171; KlFZnzFKfUgogX0r61GBRMuKR5QLj71jB79J9Nrv88Cc7a6g004tq78BZze96WET&#160;&#187;					
//	31	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.31&#160;&#187;					&#171; R9o1P0D43u13Dk0UiAehKVczKBUdtI4tbIf0NvE7N65s8VW9CO77tZMGomsqd3ns&#160;&#187;					
//	32	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.32&#160;&#187;					&#171; J9n3rDqsXC757Nh0hu67brKekPxIMD88i6K7leKWV9p9H5b8fEmo8h6b208ZSIV3&#160;&#187;					
//	33	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.33&#160;&#187;					&#171; iu26vbF25JJ9bSWcqKGW2cT9wtz5Zt13WU9s7dO5KrJuXm7514WwdBtjii292IZ4&#160;&#187;					
//	34	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.34&#160;&#187;					&#171; G9zy69Js1ZBLL98zVOY3zVM82p0X3XCu60gMBMSVM6UYN66DPOu8J2I39jX0GjcB&#160;&#187;					
//	35	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.35&#160;&#187;					&#171; NBE8I5ikpq800Brr0eKJM63XTsFY40LO1hCgLqn1yQjQZe6G82N6ZLOyXI9qDNuu&#160;&#187;					
//	36	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.36&#160;&#187;					&#171; h22Wg3O601Yi3M7x27AkJH95AZLui8z08i8DtRDZ7Qe4o7A7d4g49NDFFs5lxbT7&#160;&#187;					
//	37	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.37&#160;&#187;					&#171; DVQ0DaanngyPzzJ8F0SGaz8r676S5wA91zdi3xmjZ758D7fcrV1gsvP90L5h7lEp&#160;&#187;					
//	38	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.38&#160;&#187;					&#171; mpF3or8r456116X04a8B8P1ja1e085S00Xbnenvhz0m7c6LbzYj4CwYJMdh6GB11&#160;&#187;					
//	39	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.39&#160;&#187;					&#171; 25a17XkzeTpwe6V6ZR3BCuFKhi7zXD715zqwa00GW85P4b7zI43WPMARz7SgmA30&#160;&#187;					
//	40	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.40&#160;&#187;					&#171; xM50F03y5LD27Uw986EJs5h6e7aKYs6aEYFc8sLM5g4l6FhEJH0txalN63zxf89w&#160;&#187;					
//	41	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.41&#160;&#187;					&#171; Z4N59EGYT0OR068KqLaI2adiwWUr29cm3f0WYzLsjwbV2kk2bR0Gr9cY97EM857n&#160;&#187;					
//	42	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.42&#160;&#187;					&#171; D5etkujJp64Ds79kh482K85hdtHHW6iR7RIcd4V0JtxOyx5lpO4olw2SI9p3F869&#160;&#187;					
//	43	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.43&#160;&#187;					&#171; DhyR4QI0Q7na79U4v2h1449Nw75rguS0J6rp159O8bOeN94gCY40Cs0mcKV7D63P&#160;&#187;					
//	44	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.44&#160;&#187;					&#171; TzxELmlh1GdR7h81k4YY27Fv7PN8DkG9bQc4Y7k3xk1lX81Ae9BD7BlexfpKzL70&#160;&#187;					
//	45	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.45&#160;&#187;					&#171; 4w62t9686370E129iB0OcrKj55TAIZ7QK4ZMqK3T4CXzyChH593RLmVCj3aGfPFs&#160;&#187;					
//	46	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.46&#160;&#187;					&#171; UouWiJFS293NA0oI1jSek19GDJCY6jZLJICvyS13LAb9XkuV6f0jZz19Eu2omccZ&#160;&#187;					
//	47	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.47&#160;&#187;					&#171; 4510vR0V1w0Yu1DY243UfWhbRAvG5tWXR39l1hdWtAtO4hCwne4145b8woSybE55&#160;&#187;					
//	48	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.48&#160;&#187;					&#171; vlzK0aoz0sHnDy02ZF2QDbk5bGF6Osu0Qai3f6Z0N9sfW03WbCC620QQBs1oO965&#160;&#187;					
//	49	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.49&#160;&#187;					&#171; cBB269s21mdOFU3xh5FhRx81VO5xuuTrZ8BI121Ynl421jzy1w43ZQDGEFUc2CCh&#160;&#187;					
//	50	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.50&#160;&#187;					&#171; 6x4dP56qPs0lQZm4wxPNj7N6J51xDhTE8J7cHKwrtjlJdAp7pdR0W3Gfjs6Y6y9R&#160;&#187;					
//	51	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.51&#160;&#187;					&#171; a3hGFnx2KL88c7EgwuF65Z5yg76llub9gp6k5gbbQUfZ6lqO35f68NlMoT69SwrE&#160;&#187;					
//	52	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.52&#160;&#187;					&#171; 3WuCfj87JoU101S8ErUMPv6eUJB0KU95IZ7faKc770DY1Qdbh9T9N53aY6rdbKnv&#160;&#187;					
//	53	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.53&#160;&#187;					&#171; KR534Md6gTDt1qBORm593nm6lk07x1K7b1C4r97WJXSC222qi53B3jpD39TFh8XM&#160;&#187;					
//	54	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.54&#160;&#187;					&#171; uR20HpnpPEp1j8PlS6BR6T29Jh84hkwtk9xCiK0Ox2AdB9FYumha4KcT6r7F1qtJ&#160;&#187;					
//	55	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.55&#160;&#187;					&#171; wxD7Y7zVBMd58DjWGG2X23D4rc60g79n9c7NCtq0dqg0uzYME82i7945ZMgngb4A&#160;&#187;					
//	56	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.56&#160;&#187;					&#171; Hj06BiSAW7Ff1VXrMGLBS2a0vE26tLg2Tz6J3l1Pf1Pt75DPIQiY1J7b1Grp9G11&#160;&#187;					
//	57	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.57&#160;&#187;					&#171; F1TUAx6QM9Js462kC7azd24JUnW695tdNyd06yhc2E21E837HEK7G4r37fp1S96z&#160;&#187;					
//	58	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.58&#160;&#187;					&#171; ibxUszWW3F9wazJqU2YA7Zm11mX1X4l23dfh0h1Vuo48Is6bmEmQXu7knrSeC0Zl&#160;&#187;					
//	59	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.59&#160;&#187;					&#171; GJSQP2c9FG7lGO5tyX07kk68ArSR8i0hFa3rwa8ZXXHLrJdsFw4gjxMyD2ddNGqI&#160;&#187;					
//	60	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.60&#160;&#187;					&#171; M0xIT10i5LFZ4cJ4285x27NuK0LF805PdSD6YgWH1Kj582hQj2Gnxq2Q754HnXOn&#160;&#187;					
//	61	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.61&#160;&#187;					&#171; Ow9XBEuW0j76Z981V6BbLU6Pqq8Ey2zK3g4JcmkGwdX51AEIt2gD8qufC819l05a&#160;&#187;					
//	62	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.62&#160;&#187;					&#171; ee754BI89uvh2Qk5AspiE1kn5L3M3QuxIc7m5A7KV0i9ueNf8LS38lfUo3iwQ38m&#160;&#187;					
//	63	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.63&#160;&#187;					&#171; 2GLmaNI3S0X4a3W5UHNuL377qr7bG8oTqY0qs6b51kve345g1NqA9v7owbHqA9YP&#160;&#187;					
//	64	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.64&#160;&#187;					&#171; E3t36a13K8R4mXg9yQQ85qiQ6mdfsb2ea3LC3MSW1oHa2742dW6CTLmmk58eK692&#160;&#187;					
//	65	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.65&#160;&#187;					&#171; ASxHFGXd629l2p6M9rdrw88KYJjxF3tih8A709K302WC6xsiAR5DWn75D57Dg5uJ&#160;&#187;					
//	66	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.66&#160;&#187;					&#171; wRA74L7go10B6LM5YY8NA6TO3DOMceEoPO6JF2PrbiTkQaexL23uijh9Vp9l4aZj&#160;&#187;					
//	67	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.67&#160;&#187;					&#171; 9eOTPY3kQ2u2IlP0cz42du2e7x7ItS0Py6l0gnQVD197psRt6g7R6t9Wcjyg3BSm&#160;&#187;					
//	68	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.68&#160;&#187;					&#171; Mbn8a4DlZYT1fPM6dC3NIGYstBG45KYHZOhUWug1fK2UATw04LRu064Lz92828gz&#160;&#187;					
//	69	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.69&#160;&#187;					&#171; kuno50r50m9D6ZpBOYU2L9CCYe6J6vw7ddi1uQyU78m38W8g9067qae89f27QW5q&#160;&#187;					
//	70	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.70&#160;&#187;					&#171; 5f8G4TqkLPWEFa2L0C28274c2Jd2CJfVKK09Udwr9Sshf0kH9Ifpod4Nq96C9lhV&#160;&#187;					
//	71	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.71&#160;&#187;					&#171; 4r268bn2D2WH0L6769BEZo1o6nof2hKF36glNxn25Z9IuFphbFqRw7qkI0v5fJZ3&#160;&#187;					
//	72	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.72&#160;&#187;					&#171; NBoIqn6d67pi8iT0ABqaPs80O69ND2T615fyP0aibGiyvcLze32xHRx5o1F2102P&#160;&#187;					
//	73	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.73&#160;&#187;					&#171; xCNPrJshcf4NO1wf0vQ1ss2muAQLlK2zVEIJI9r11B44sfclTfp16nVInS61Lh6R&#160;&#187;					
//	74	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.74&#160;&#187;					&#171; ozlRTvz02nx1cf8ZM38IUuC1q05iTeDbxX5Ci5j3C92hZ6586VvRl1q6C6SWM8yk&#160;&#187;					
//	75	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.75&#160;&#187;					&#171; wjB1wXp62Xkld2Y013W2dYR4qOvmBDR9B61T9jiud40z8mi4RVLZS430MI02kn8q&#160;&#187;					
//	76						&#171; &#160;&#187;					
//	77	TOTAL INTERMEDIAIRE = 75 Pools de 100 Utilisateurs &#171;&#160;payeurs de primes&#160;&#187;, &#171;&#160;payeurs partiels&#160;&#187;, &#171;&#160;preneurs d’assurances subventionn&#233;es&#160;&#187;.										
//	78	Soit 75 Pools de 400 Utilisateurs &#171;&#160;assur&#233;s&#160;&#187;, &#171;&#160;b&#233;n&#233;ficiaires&#160;&#187;.										
												
												
												
												
//	1	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.1&#160;&#187;					&#171; CxQdW3kj4BQ03vJ39c56Sv78McN4e170853cHbK4BH8sy4RXfZ3Rg653U13Udjkx&#160;&#187;					
//	2	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.2&#160;&#187;					&#171; J277msVTY4x6A4lOW7IDrk4zzcdJpU04e5veaL96qmRQ5TdyBu3B83K9Pxd54mkp&#160;&#187;					
//	3	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.3&#160;&#187;					&#171; Kd0J89l9Bn5610gt6sf1D8g02hDD5HC6kAp40l0I5G11XP99QqU1ukaCU9R4K9Iu&#160;&#187;					
//	4	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.4&#160;&#187;					&#171; 6jv6ltI923Xhq966fF4VbbFp84D6T4aEPoWZ572r65w67fqlyLdpw3L69N58muE2&#160;&#187;					
//	5	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.5&#160;&#187;					&#171; W4zhvvfX60G5pWh5V2x2S7rNTm12bx1076UxqmO9Hp57VYRuL24itjYvTo3En7UY&#160;&#187;					
//	6	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.6&#160;&#187;					&#171; 9Vg4V9a4BJwi7Sd4rIyF4n2WY66CS1vFXQJpQ8676Bc5vnP6q7G2342WZx3uqw86&#160;&#187;					
//	7	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.7&#160;&#187;					&#171; 0c9e45d77RhA6W03QNFCqPu35rlCMbfTl1f62S9vnQ76i1m22fWE48y9EEzH598A&#160;&#187;					
//	8	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.8&#160;&#187;					&#171; 84GCUq2w0rbfu05zCO9WDqQhoBsV0o53Q5tG124279Dgv7034uy8v26IOw2LmGC9&#160;&#187;					
//	9	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.9&#160;&#187;					&#171; 1mx08l2203lG1639kTAlJ36ZN3A3yvR1zLY3qClfHXN6WN87OKKkyEBSIs1NFrJ8&#160;&#187;					
//	10	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.10&#160;&#187;					&#171; q7T4057Xi3ihVe6LS3DhIKU7a8so99f2scZes4bu1nd89J364gXG093W373HX86p&#160;&#187;					
//	11	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.11&#160;&#187;					&#171; 5m88wm6bBD4n7dEVszEt4Hk9cyi5B4DR8e3jYZo1suJlCLk3dDi3w30cyQ8K29Pt&#160;&#187;					
//	12	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.12&#160;&#187;					&#171; Vv2nIJFgu38Sra2PN7NjWptg41O4U0YpdNufbaE94nrZ13e4sf5IB5p1kv7fiMfz&#160;&#187;					
//	13	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.13&#160;&#187;					&#171; 1q6GAXbJsV97Bk0vZ4b5T5ecXQb339U648N9Q1m1t3fmP7egse8I34iENi8x3B6s&#160;&#187;					
//	14	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.14&#160;&#187;					&#171; sCSsNAz9oMbPknm1U3wB12UVB7ZHvJlitKkd1LiMie5duhzdH7xR9Z5x8M63221n&#160;&#187;					
//	15	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.15&#160;&#187;					&#171; e1byM2f7vtD2KZ1ye86BmtuJv4nv27V7UJPRJ21rI8O0FGF8Hf0cy2Zq3P7ML9PX&#160;&#187;					
//	16	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.16&#160;&#187;					&#171; 62QAbtAw695uTFJmj0rn08q44OSEt3DfaHm5E4560lwqAN8r0PedOB1sKFhFqRrs&#160;&#187;					
//	17	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.17&#160;&#187;					&#171; 8ng2gF5ULYI83198YFetFR19tirovH5tn58edzGbND33Urm37aHlrFNKViW0y5ZI&#160;&#187;					
//	18	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.18&#160;&#187;					&#171; m8Xtzb5rUB1c8P5a0xb0YFJ7g4cy89gijL7AhbYFNBL451ohL5K2F8QpgEZ3pzbv&#160;&#187;					
//	19	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.19&#160;&#187;					&#171; B5i3vA1DCasTIAg9KFGyUNSs91tVM5mPnb5L0b25B7QZZ53JA7EZa78FppXF4q1P&#160;&#187;					
//	20	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.20&#160;&#187;					&#171; 52tPnhTkzj5P26TSMuJMePQfr4681ho6K6MP1xiwyDNQp6hINddvR6aBb7ff279N&#160;&#187;					
//	21	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.21&#160;&#187;					&#171; SnLS3C1787ObRneZdMyB7bT37B0hOlT85p2eo6c9V14QB91343XB8961ZUpjKY1q&#160;&#187;					
//	22	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.22&#160;&#187;					&#171; JIxiF76nXvra4L0k4MspoCcYi24146yt82Q6G274nleT57ldYdDNTiP4c80s2kX4&#160;&#187;					
//	23	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.23&#160;&#187;					&#171; UuS0240xz95eTU6Afcjp3l3sOaEiyH14Jp9Xoem4lh08UTfVMVoSrjx9r570fYQM&#160;&#187;					
//	24	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.24&#160;&#187;					&#171; DGW9Z45tUQeKOfry80GZCs0OKBPPos3PoGE1xFBix2RMZbR7z2SYUbc48JPhTsxJ&#160;&#187;					
//	25	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.25&#160;&#187;					&#171; 2BrSUf77R676kq30w141GKQ2ojwbqyoWY4F3ranT3ge1hBkhtI3WTNQHiw1j67v1&#160;&#187;					
//	26	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.26&#160;&#187;					&#171; T3JmZGbCl78fDme7P2CoI04Y9xZ138JntZ4J8WF2pei113QsTJ16OfcHeckKhCBy&#160;&#187;					
//	27	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.27&#160;&#187;					&#171; C2EEWl511ALyI9vCCllA1yyAz41S3aFyzxyuyG84HK1XT6563Z2E5K8Zqr1sr9c2&#160;&#187;					
//	28	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.28&#160;&#187;					&#171; 20EgVaPZ9YuCjQcFwtTDl6p719Xcn9493I5rJSELmMtt1tioVN02Kvgxh3J000q7&#160;&#187;					
//	29	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.29&#160;&#187;					&#171; qaM54DrjSxfh1GHVRRB2Y9Rg3Lyh1K7VBhOoo5X345AP82QeM7TE9ayfNFU7GZla&#160;&#187;					
//	30	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.30&#160;&#187;					&#171; AB1NPP3Wmx5z7yw2M4wqoRPf6ryIWDyfLCqL7W3F19TsJbJysoy255DLDj6U5xhr&#160;&#187;					
//	31	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.31&#160;&#187;					&#171; ZqoI7KTY9XKwj9U37dxrqbiPv5UqXGb5u2W5TolB5bH2rZU28OudyKg1kYj42FuG&#160;&#187;					
//	32	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.32&#160;&#187;					&#171; 7ASRje2ADn61hC46u03R82Ks9I6EB7m5Z4aPpDKwoc40q0yk8fEbGXxG6C7xt5gV&#160;&#187;					
//	33	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.33&#160;&#187;					&#171; t3e95XBB7WQfGamaieoI6wzP8VYb6lwOTA8UzB0gJ175o715aEh12K594u5o6248&#160;&#187;					
//	34	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.34&#160;&#187;					&#171; tb3yN94CM0Ow2dyv6ZMbIDCrBp0WvAJ1JDn2L9K9F1h3u0J53547OeQzpq3h5dNy&#160;&#187;					
//	35	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.35&#160;&#187;					&#171; 996HABRCcu16L2846HY2s2WSr9H7uieSj0m67993R5X2BEtHaxCP1AH8mp0M96a9&#160;&#187;					
//	36	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.36&#160;&#187;					&#171; yi62S5GT95xZtQtpHV7DDgOc12zM9233Ex21Tbar9B37WjO8yNiyYzoDY4vS65SD&#160;&#187;					
//	37	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.37&#160;&#187;					&#171; 398566MTb3Ttgd5IRvl6ItIUDNCk55X05tLQw4YKj0450uQ7s290de8M04bA1cRQ&#160;&#187;					
//	38	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.38&#160;&#187;					&#171; GRs5J5K0C649vXBWw5dgc6Gxy6CFf4W6mssHHLoA7rguLy55gT1wR055L3uEp771&#160;&#187;					
//	39	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.39&#160;&#187;					&#171; J24n8s4gODmO1BFM0mXAd8Z33pGCc5LyELp9D4R91sHbY7LU19FrU5PkstzH4nai&#160;&#187;					
//	40	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.40&#160;&#187;					&#171; aWTPID7853F08FYy7Z3VY5vDNNiwjx9Ez0cSq3sxmifB9CBNhzJ55PggLNK07bvO&#160;&#187;					
//	41	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.41&#160;&#187;					&#171; 6zAF57xYxangb9Utwo3kLpC6hJj42m4li09Op5jUYxd0m4MB5bx7mru9rV7VwZ2X&#160;&#187;					
//	42	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.42&#160;&#187;					&#171; R8lyocNdHB5P1YAwnNi5iobvG9zkh1qMXKwSj1ka8S6B2cLh2vkv2AycYFo68NX8&#160;&#187;					
//	43	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.43&#160;&#187;					&#171; 4sD0BpW2agE08d62IqBFSiYv46NMtDv7pUFAAm0KvwTGaBIxBNFhrDzzcmwyNvh5&#160;&#187;					
//	44	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.44&#160;&#187;					&#171; HW790rPa0ef4o3CmsST4V3M67nfMEWnV2je8Z2FWK4B5f420gBn3ghiTAFo14nR3&#160;&#187;					
//	45	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.45&#160;&#187;					&#171; xYKNwMZ788nWB0011r5AR4u8PyHsk5jqlGK67vDLYh677i4D0Zab5ay9Z1S5AJv9&#160;&#187;					
//	46	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.46&#160;&#187;					&#171; w24WHe9k68UtlsYeY123MKz9nv2k2AtivJbt5fZ197r9iR4n4AGzs2U76Vd3zfV1&#160;&#187;					
//	47	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.47&#160;&#187;					&#171; c9t9o80Og3X9hCYoKSPaiMFLMws5Iih6TXb34Z7v8sqLTHj8EaTfnVteHF625XZ2&#160;&#187;					
//	48	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.48&#160;&#187;					&#171; KZuQOBudZdZDSOTrkeXvJuRbcYZNyAHkM2hJ7qrYpf9jof3S9h779SSXrsD0PbVN&#160;&#187;					
//	49	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.49&#160;&#187;					&#171; wP5VhZ1CtoJv1hxz246aBolp14OBJJPy1Zb3ShGMxqbQbYn27a5gxfq542jWHF06&#160;&#187;					
//	50	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.50&#160;&#187;					&#171; 4FnLRc7y07Ee2fC0JUyrN7lm0CZa5rQq0aDGuo4Cs717LYs9cid55ROF9ETeCSMk&#160;&#187;					
//	51	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.51&#160;&#187;					&#171; 6754R8064Jm0IljEZ17uhNO0GVf3181YopT038d5nusx1BpuwRbgS25Ba99BL45A&#160;&#187;					
//	52	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.52&#160;&#187;					&#171; m25Mnnj771gPakU61xeZK79CH2cl2bgUt5d2u8t211ZuMi6VfJ2kkaaZR613lPca&#160;&#187;					
//	53	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.53&#160;&#187;					&#171; FOIGEZ1s5JD9Zl0yiE24b7PlMMYBut5lo39Oi2AQF30Kve7q58889ti4x8c7qD74&#160;&#187;					
//	54	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.54&#160;&#187;					&#171; GL5exGFTyhkxEt53RLwHRGDJi5D0V7TkK232W03P9Zbt9x0556uZ8uZFSMZlQ42x&#160;&#187;					
//	55	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.55&#160;&#187;					&#171; mKR01Dh7FU6ncJx8qUdS8W3x38wKDB2ECnUu49f97M3q2lN608c6q92geJtetMwj&#160;&#187;					
//	56	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.56&#160;&#187;					&#171; 57WXx4ryVt353UN9656p5HXs2864YP0ErJ9bS9O04tmvblkJkZ4n5n16fhPcgyb1&#160;&#187;					
//	57	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.57&#160;&#187;					&#171; 05X8bCBi7UOkXlqXIt963pqb2nr5V2S2m3GEM3o4slmgOT3bz0YY2Sqry7T1s82p&#160;&#187;					
//	58	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.58&#160;&#187;					&#171; Kg6ibEN5t4E4c9Gu2D9E4e6EWPH03fB3dEfJhPP4Chmtu3BErCCYS17L5DIq35q5&#160;&#187;					
//	59	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.59&#160;&#187;					&#171; cN635gNxjvQ3jqYB5820B3ivJ5VmLfbAGu6Vnjdxz9utYaT153T7R90385sz9qVh&#160;&#187;					
//	60	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.60&#160;&#187;					&#171; Zw95uhsEup3kjlqC8Unze102833cgaWnPJs3oqcQ2zs2Yh18txpc408aE4j535H4&#160;&#187;					
//	61	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.61&#160;&#187;					&#171; OQb2r43006EZ011KW27t1N1sE0gxE73wn2Y5CBzbAgHVG9BqUVJKjdJee5F5Epiw&#160;&#187;					
//	62	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.62&#160;&#187;					&#171; QYpjE6H9l9q13A7e4uDji19wO75uUC32t8a2HAFvs2o3a3jdNyyCQ0hI75o9Y1UW&#160;&#187;					
//	63	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.63&#160;&#187;					&#171; Q5CC9SqBkP5X4g3I52D5Hvu0M7mn8ZgHR556E5q22McsO9y7GT11a0KD1Y2R94NE&#160;&#187;					
//	64	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.64&#160;&#187;					&#171; k0sLBHJHkoAd92BT4UB97Wj0067P4Z5F33h0VPwT67BcsTDIyzJs10fL8jMrE1C0&#160;&#187;					
//	65	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.65&#160;&#187;					&#171; a4LB75072t127P4O3q3RxQHINSgp2Wg8W8lks7Ctl9uTvak0A3o4n11Jv0L0yg5s&#160;&#187;					
//	66	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.66&#160;&#187;					&#171; nkC85mDC3x5AN8i49h3AeU0g654Dg18cwora6Y2rBM0B45rn9q2kt90Bv7QIn2jJ&#160;&#187;					
//	67	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.67&#160;&#187;					&#171; l673fsboPk9qjR4kyYEsjGSn95IzHGPK72CrH239ZrRD2159Ool2v5LEZ8GT66qd&#160;&#187;					
//	68	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.68&#160;&#187;					&#171; 0W03sI2O2oFhkmU3I4T0UKMz1ezN29p2Y5R1De3BA98ARtZhUmrT8rKn6mh32DmH&#160;&#187;					
//	69	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.69&#160;&#187;					&#171; nsW3H28Pskiij6aeZp3m9mPqSnDnFQ07076541jkK98dWvT6jBToGu3ESN5V93F3&#160;&#187;					
//	70	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.70&#160;&#187;					&#171; Z6Iv5m46Med245T9cu25M4tID1Asg2xBnSxnKWbBBjE47P7o9217d0x5j9o0Q0cQ&#160;&#187;					
//	71	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.71&#160;&#187;					&#171; hqfVPve65zl514397T8ADOwr49sYlMk8r5Y0jVn4Roh0BHH4U8KSHzNOrZ2PbJb1&#160;&#187;					
//	72	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.72&#160;&#187;					&#171; qqSTQ5n7Z4035Xw6nkub29tO0BfVD6ofCd83HUq15F4KaLenv4e182Nu20oZM04O&#160;&#187;					
//	73	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.73&#160;&#187;					&#171; zCBM6j5xP160jhG93T4mf7Q29agMbUQ53I795Bt1I3l17QzIex1Z7u2qq890uLe3&#160;&#187;					
//	74	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.74&#160;&#187;					&#171; 5bp0iCrp69rDKpxPV3z1k51oiD06T8Pc52u46cudr7LLIgBz2WVwAxuh5pkf1o3R&#160;&#187;					
//	75	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.75&#160;&#187;					&#171; POV21bzXG2PQ8KYg35dj1I6RH0ne5h4I7X2G6d4tnJhv0fA1tH0fa46Jdl0tTmT1&#160;&#187;					
//	76						&#171; &#160;&#187;					
//	77	TOTAL INTERMEDIAIRE = 75 Pools de 100 Utilisateurs &#171;&#160;payeurs de primes&#160;&#187;, &#171;&#160;payeurs partiels&#160;&#187;, &#171;&#160;preneurs d’assurances subventionn&#233;es&#160;&#187;.										
//	78	Soit 75 Pools de 400 Utilisateurs &#171;&#160;assur&#233;s&#160;&#187;, &#171;&#160;b&#233;n&#233;ficiaires&#160;&#187;.										
												
												
												
												
//	1	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.1&#160;&#187;					&#171; 7Rb2d5yZcOVr2Q79C3u9l06bc402lfrnVt2f573W77Y32DaLQPusiW4bU4t53p1h&#160;&#187;					
//	2	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.2&#160;&#187;					&#171; AESN2OAIWYqp98t973zC2CaP060l0dF37ZQvQwVWkLpnoEE9e9F468Q33whh7094&#160;&#187;					
//	3	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.3&#160;&#187;					&#171; j8PI4Lozdii1jnYdyW2b1PYpH6afgNOF4jOLzCiB8B4RsfLfs6d8v6Hz3Tu8Yko6&#160;&#187;					
//	4	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.4&#160;&#187;					&#171; PQ265j8u0Fwb3uDe72KZ2G9c2SY2hK5cKY5FH0w48N3x3c4F3mus8RN4pB1riljY&#160;&#187;					
//	5	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.5&#160;&#187;					&#171; 5XKqy3eKcl425Dg9mc99sATX2uJKUwmtvL5ut7rQLWjLp9ya91AbM7zx17DnTgMY&#160;&#187;					
//	6	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.6&#160;&#187;					&#171; aYleWRmAq7X6wrbffRgS8p258T4zM840r6vTfA8ILUT0I52wC5NGPcO18rRtb8dF&#160;&#187;					
//	7	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.7&#160;&#187;					&#171; 4HsC3tO13Ho2xwZx4hAKGcvf0Pb99oNpA5K7Nz0eoX3Ut162461RHcYsFLbAbuiF&#160;&#187;					
//	8	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.8&#160;&#187;					&#171; 8sKXX2bMGRoJ9Y7CEH44ZI3o14y0dbgk7veytBi423o9CglG2rZAzoR618llFCWD&#160;&#187;					
//	9	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.9&#160;&#187;					&#171; I0983Dtc5OSSQ49FjNX0T5WENH0AiPwL9s651qiXMFZ5np4H3Qmts4sFD2h8tb3a&#160;&#187;					
//	10	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.10&#160;&#187;					&#171; 5c65K7hd3K25H6h5Z1LDN0tw4TnZ9LLFI4GyKOAbe8DadyPkeU8KD93ZGlHn5JU3&#160;&#187;					
//	11	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.11&#160;&#187;					&#171; 73C1s2AMLvV2RVag1iI19Z8gz5Vs6M14Bt9Ju4nGDEI1Xb09238Y098B1sfV1D47&#160;&#187;					
//	12	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.12&#160;&#187;					&#171; w36qDxTwUNZeigmQw5e75HMTnW4047ceuJQkwQFMz667cAz0I15tBllEV1onVBH4&#160;&#187;					
//	13	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.13&#160;&#187;					&#171; Zv14amyHDFW1O02TOA8N09LWkZCd8Qq0EvsR1tHqre8986314Wx164Jr6yo0HHBE&#160;&#187;					
//	14	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.14&#160;&#187;					&#171; b1S2jd8mnz8C332VkMg8E6ZDII1g2R56jlcnqRfktqu4wXrHULZHPe6D0CdfOj7j&#160;&#187;					
//	15	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.15&#160;&#187;					&#171; fEz6jQWG49zhLj089FYJyqh5pzOCoYSv20u6hAbTyVO3IU7pfqO3R32j9fcVijy6&#160;&#187;					
//	16	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.16&#160;&#187;					&#171; iu4w9h71jQ14vX4cB7Yp9284Kf1mH5F8VMF46ku25237PQ6ELa37ou95D1AEWTC4&#160;&#187;					
//	17	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.17&#160;&#187;					&#171; DBiF78SaO41Q15hK7v3E9s1v3ESQxUne6Ih8k4dMgwINsRQilLrNi1O8gYZi90fG&#160;&#187;					
//	18	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.18&#160;&#187;					&#171; w6mpOGq95tHNlCoVyS4Le0De273tJXM8m4a25xOr0048uwPkEvbVyoRxn920UiZX&#160;&#187;					
//	19	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.19&#160;&#187;					&#171; y5ps4EvfcUH8u5b3eA7EFYO48vhU2Wk25P5aY8PB6CSbtCyo9C5FkbnGzQK15Hmb&#160;&#187;					
//	20	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.20&#160;&#187;					&#171; 3CqvhJZTqYr292Q1Qqfgqc1UuTVh8y0IzSNiXGTl5lo2EwgrYO2i5VXLFm68G450&#160;&#187;					
//	21	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.21&#160;&#187;					&#171; 9i2Im06k2082rzFK0t9MBIYmA8VM2r807BZDTY0k4D3P63Qh3nKC76r6SgiyCQCW&#160;&#187;					
//	22	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.22&#160;&#187;					&#171; 6266s0UNPV4jmtkGcu3XRFUtR7f1B1W77L0jvy0c8X0D84Zh74dLuS5fv6Brnwz5&#160;&#187;					
//	23	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.23&#160;&#187;					&#171; WlbbnVCe5qp751lKfq2WvZIc98Y6X2b80d3ejq01NeaG9e2u1gDE2av4hSX6Y9Lu&#160;&#187;					
//	24	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.24&#160;&#187;					&#171; QOLjN6wq0RiF406zYkmi2lIAcsYXYSJwWVL0yBLIWFc99LEs9q6N7jac0w1qA5W6&#160;&#187;					
//	25	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.25&#160;&#187;					&#171; 765sY3itj6vPnUC3093ul6e0mJ5kZII663a2EKY9wyDyOJ0CmZ6vVEParEh2C51G&#160;&#187;					
//	26	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.26&#160;&#187;					&#171; 1ShT6wzJUb3oposq963cyYTZ55AuER03g95I7GBKgGdjR5SLyRytCG2LcRQ057K1&#160;&#187;					
//	27	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.27&#160;&#187;					&#171; eL5r71jXdhKBY5M1m8s5089pwW2FLyCRaX93prIt3xk5jHOC41mK7TF1H2kRhQ06&#160;&#187;					
//	28	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.28&#160;&#187;					&#171; m3enB3B58gLIQHw00jAktp5Umn6S0O6O9yp8e7m4bL1LBg389vQc9VKq9v92mqa5&#160;&#187;					
//	29	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.29&#160;&#187;					&#171; DtT75r4eM00cT7O86LEvc42H0652W2iI0qAC2baySl9vN4L01fT0cDd86nsSYo40&#160;&#187;					
//	30	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.30&#160;&#187;					&#171; 8jKkkc42Ca0YmyQ0MjJazOVyU1kIW6JaTSmi3DLzSd6ZvDmEB81G30966NaWosf7&#160;&#187;					
//	31	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.31&#160;&#187;					&#171; QA2mvl41xOi08fL9w6nN7A9t6Iwt4Nt62fBno61GN6e2kP1vLzYibN3KXQq939hh&#160;&#187;					
//	32	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.32&#160;&#187;					&#171; tYaSm4eXn6QB78d3cY7V2tUoEg4iXuBot2rgwhjnXUxOLWiuT65a4f769l7xLRXL&#160;&#187;					
//	33	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.33&#160;&#187;					&#171; 6TM7Qu4N3rT716l1V1Q1dJlxSrfLXsQQ3Wd9T19QkaE8nYz60CDFHJeIPgN4s4RJ&#160;&#187;					
//	34	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.34&#160;&#187;					&#171; 84U77LHkHnb4Z07Js1g8ShXKlPfBzBzWKs78z8x89fH3jDCzr1RawTdCPotO68FW&#160;&#187;					
//	35	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.35&#160;&#187;					&#171; Ur9exQPsWO13M9fW8o8sGZZ7Zt9F8569v9455GS0T1h542IWcXEzZsJEikC67ORn&#160;&#187;					
//	36	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.36&#160;&#187;					&#171; 54823yVd4oJQAR2m4dm6BMyJ319g44FGg5xMu8VKYY761o80Y9GPd0njtz5u8M3q&#160;&#187;					
//	37	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.37&#160;&#187;					&#171; M8H7itWG14KAnV05grH5219EnDfiYXwwT3q5K4U39Q0K7NynpUxNBh6T33eXDBgD&#160;&#187;					
//	38	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.38&#160;&#187;					&#171; L9W1Pk7P44lW5ZQFxy1YOz9Vchrrvt51XY37mYp6LND0692EJW0DSjfRh3kx9Oa9&#160;&#187;					
//	39	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.39&#160;&#187;					&#171; Wbja66DFkspd9ooWuP8nmIvZT71AX83tsf8aPtvDpmQlaR96t6ZTbS0JJ8LC2Oz7&#160;&#187;					
//	40	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.40&#160;&#187;					&#171; 1f66NQQ03Z8iJ88E095sR678MllC3UxILwQ7BZ72l3N8i1HZNE89WbswijjWuaQU&#160;&#187;					
//	41	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.41&#160;&#187;					&#171; 0l0prW0x2z06VL3s9bWxs6sYU0eLyR61o6wi6AYIz7t242l0RB325Z2l8jtn0qcf&#160;&#187;					
//	42	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.42&#160;&#187;					&#171; l54Kiv70QR38lHYJvL77Alj5K4R7Q12Sf3lVd9PUE7EtN95IgNNi7sIOu0w7iNH7&#160;&#187;					
//	43	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.43&#160;&#187;					&#171; U4jQACE7lQwQRpcwI9o80nNA32q4M906QfsWK88F92562iN54k1e83ezVGs6o7EB&#160;&#187;					
//	44	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.44&#160;&#187;					&#171; 55G19zP42uAw4Z4ji6jnhZQp0X366gG0I2Z17M4vSfKc9GedR3B313i1OI178k4z&#160;&#187;					
//	45	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.45&#160;&#187;					&#171; 3jKpr5p2b53lD1dm4q2d9Ow5w8SpS17z06W0YUZA5UI0W4m68063o5777t5E1x4o&#160;&#187;					
//	46	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.46&#160;&#187;					&#171; gWy3OgU2VU9TS33s620zx97vMi5Kb44E5xw4PJq1sjOjxJ96a74TW0NXU6LBBC52&#160;&#187;					
//	47	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.47&#160;&#187;					&#171; LghA8gxNNrsH076K5VqfxlYxVB9AAQFUE57W2KfjxM5cfi1wdK081fys62AZPm2p&#160;&#187;					
//	48	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.48&#160;&#187;					&#171; 4iDaLIQd4ttM04ZN4Q7c8V4TEf426fSv6PbqinUY2wFh6gv05A6vNr45SJY822yl&#160;&#187;					
//	49	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.49&#160;&#187;					&#171; 4Zq3y62n489Oy2I0tzICxH3SxVqZ4D97hB3600Q2rEK3PjYZvjHR2AQD41eyYIOs&#160;&#187;					
//	50	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.50&#160;&#187;					&#171; 9HR12lIBXbW0KXwA02LS9MoCN0Qv20y2UyI19ijVNnoOlE4bZ42Mseu3hxAHDS0z&#160;&#187;					
//	51	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.51&#160;&#187;					&#171; t70BQ34Dmxg7z46r8521u9QWtkS9HnX17JVD9nByi2NNpsaob50pO2YPE2A7KrCy&#160;&#187;					
//	52	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.52&#160;&#187;					&#171; 13MvmK3vE42r85UEVh3ONAboW0E2V8nkGPa8V5m1FYpfkCj2l56cAkndr8X6A425&#160;&#187;					
//	53	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.53&#160;&#187;					&#171; EiSm3kTbD51oW8TEno6UNRhqk523yCHjhplo5T92gA4n16v6cY9evA0jd3gQlSA8&#160;&#187;					
//	54	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.54&#160;&#187;					&#171; zK15Hm0nB620nSu5iB7gs00HC4G3Z9e4EpWdFPpxeu5cHK18GdBnkL74Fuu6vc22&#160;&#187;					
//	55	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.55&#160;&#187;					&#171; gZ7X9T6RJ969Wu7K9OaqKW31Dy6SF8fGWIVkYJMAp9A4ejx3aVzi2LxT6Y47apqC&#160;&#187;					
//	56	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.56&#160;&#187;					&#171; vh1QGmwaL2EgDCD5PGBl4ximLchF871M734zotSJF1fNj5bKeed41Mmj57uQB4bt&#160;&#187;					
//	57	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.57&#160;&#187;					&#171; jBz746G0R6VcqNhSp2hqPEd9qD7N1zHwxH1DuQjz24vi9usO5SvPHtV1bF4df512&#160;&#187;					
//	58	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.58&#160;&#187;					&#171; 0A1NzXPlX9q8UIqX707sy85VBdwPjG0f3q25KaHy3Ikyabnx9DWFzpS8BwzA0zJS&#160;&#187;					
//	59	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.59&#160;&#187;					&#171; 5GsmGI3S6VA2Z5YOmQIHMz4P7pBi7QxuzQThYlH3sQFMy0Ml5dHpMy7XxZ6hb5v3&#160;&#187;					
//	60	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.60&#160;&#187;					&#171; 4ROTsCugZ57pTWS98gHm42RGH8j336o939rHXVb5w2P71ul1M22nVM7r7lD9g1XC&#160;&#187;					
//	61	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.61&#160;&#187;					&#171; c1wwp8Gyr0uJ2sR3pR8q7W6QFpZ8St9uLCKf3308Z7JxY52k22FA2R02ROf0SIRZ&#160;&#187;					
//	62	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.62&#160;&#187;					&#171; 3yyz99o9cZE2I7p5zX03lRje1Nog0DSSyyTBKmdI9w0dkFlcpf3URus10Px86DC5&#160;&#187;					
//	63	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.63&#160;&#187;					&#171; Y7U1Yp7Fwp0d08g9p3q2S3sDWEd786adF4aYHK78qkk50qDc8Eba9x84ODpwxG2A&#160;&#187;					
//	64	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.64&#160;&#187;					&#171; Bi74m725C428319l5HQR36p2YA11w6O9Cn065eJw8Lg926pQ6f3A87vfV1XiKFHF&#160;&#187;					
//	65	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.65&#160;&#187;					&#171; 34ztMebme52PmPncQ2383E7rY2qX4KvQ7jpcl161CJ16rwq2fo46HnM8SFZ727KQ&#160;&#187;					
//	66	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.66&#160;&#187;					&#171; 1THuuc82P69Q0Y7cXdFdqHo8zY4icBVrZGF1CRHp70Yr7lkx9rm9P019q7Yp6j78&#160;&#187;					
//	67	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.67&#160;&#187;					&#171; S1qNYoXUg6qyYwCh89GkZryFEkX22oA8dDCD7xFuQ2abLxmfz0Z0AqPhS6QSh9J6&#160;&#187;					
//	68	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.68&#160;&#187;					&#171; 9n3LE7m9rmy76R7PoX30CsdVT11hIEwGHQJXAL6y5jyzDm13aoso924NVjr2O42C&#160;&#187;					
//	69	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.69&#160;&#187;					&#171; n456P0mWOZYbhwQUBm1iyvXdwWd113kTUAeji5yQ59nZ7gOX2qFrvw5X3RW5pde2&#160;&#187;					
//	70	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.70&#160;&#187;					&#171; C23E7QEBoAqHm74m22c7hj6L4WzB5iIAvgQ2J8j28Lw2xR8F04Z8M57N1a813f7K&#160;&#187;					
//	71	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.71&#160;&#187;					&#171; 9U2C98r1YXA231Z52dbnYMvq1CQKC02SBH44GeqQo386N5D744hDGkNCIy55lf19&#160;&#187;					
//	72	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.72&#160;&#187;					&#171; 0y1R47T5nX4j016o5I0lvVqflVtrC0gFm5CK0B66l0Pw9Py7Lv98moI2TKKZSIZQ&#160;&#187;					
//	73	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.73&#160;&#187;					&#171; l94amVOXD1yr7ebTvL5rKVg8kulgfP2612h6IHdC2HvheCLXv7A2m6R6u761zlxY&#160;&#187;					
//	74	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.74&#160;&#187;					&#171; RX3K4XzkW5n6hR6M1VywQEu16277vNIJ416z44zN7crKHjB009g81WfhO5u4HNr9&#160;&#187;					
//	75	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.75&#160;&#187;					&#171; H1HMu4gOw60XH7ysTD886dl1UeSv0bzwK047Seil20UYwH3qa21731zT6G2sxIue&#160;&#187;					
//	76						&#171; &#160;&#187;					
//	77	TOTAL INTERMEDIAIRE = 75 Pools de 100 Utilisateurs &#171;&#160;payeurs de primes&#160;&#187;, &#171;&#160;payeurs partiels&#160;&#187;, &#171;&#160;preneurs d’assurances subventionn&#233;es&#160;&#187;.										
//	78	Soit 75 Pools de 400 Utilisateurs &#171;&#160;assur&#233;s&#160;&#187;, &#171;&#160;b&#233;n&#233;ficiaires&#160;&#187;.										
												
												
												
												
//	1	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.1&#160;&#187;					&#171; jRdQ06K24dQw0758iotV5ASNwuLewcLaJYFFMpFbf848Xq62IRdYu8sA2Up15S8O&#160;&#187;					
//	2	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.2&#160;&#187;					&#171; 5VKlQNP8Zvz1440Zzmc99MFZi76ifB901qK6S4vx06nCFMCQqEXS2Bgv8157qRVX&#160;&#187;					
//	3	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.3&#160;&#187;					&#171; nySY8toZ72zQ7ebV8GhPk4z7OzU83124LV35e4682ZO77Zp15SyjtP80Tu898555&#160;&#187;					
//	4	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.4&#160;&#187;					&#171; 1i15AqqvjT21KVs39KkIerBR6L24d8f97Sa4uBAdUBh5q9z5mdKgW5vN50WmPqFd&#160;&#187;					
//	5	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.5&#160;&#187;					&#171; 7m706Qi2yrgiX8j385n30UQ1iN41Wz46LXWhjLCn1ElP4y0v331iBuAA2698s4jx&#160;&#187;					
//	6	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.6&#160;&#187;					&#171; MCS29873kdVbYCu2eiQ1i3MRM9k9S46AFpTt52anm53Dytn5PCqpJiU8jbZoCvgE&#160;&#187;					
//	7	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.7&#160;&#187;					&#171; MbyLUM7G4et7aV590Xy1R9PNd6Og37t6alWT3vH3fW85MlX1RKXUm3QIFeGBIsRp&#160;&#187;					
//	8	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.8&#160;&#187;					&#171; DWgj1ys9MTJ191w9VZ1vRFGN9wOUjftX1Vxyphq6m6jVO489a10QqE6f3HSWw1lf&#160;&#187;					
//	9	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.9&#160;&#187;					&#171; 71Z7YLtQmiXH27B3D1RJLoTNgD5zt149EC3xA5S0VfVEXPNGiRtRANbSTB0HK56g&#160;&#187;					
//	10	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.10&#160;&#187;					&#171; uXj1u687W2bnIyQG8bGQ1tjO124K60Mf0FGzFXp5sp0E6Z0Ym3Vjrskxq06m9VPc&#160;&#187;					
//	11	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.11&#160;&#187;					&#171; 4s00pWB4rqrUbI108YIxh04BG7R7ls86Z1vwS46tcfnDTD21kfz798XHnQnR9y6n&#160;&#187;					
//	12	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.12&#160;&#187;					&#171; hfYK73AAWh2J76QkeRejG5ExGlSWTlcQ7Zwh3K37qv6Ur5ygRh4QxrpKB5t4S9hJ&#160;&#187;					
//	13	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.13&#160;&#187;					&#171; 6Md4l6MY0hV8O8sXmRg157Gb95i00l49Q49JU031hiPb2Oyq676Wt49PM09ePG8u&#160;&#187;					
//	14	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.14&#160;&#187;					&#171; xb73hby7xlI4p3QXfAjU60Y3Fk0XU9jQJ0s997FFOEzY2U2XE0qNUw9y5tvb7075&#160;&#187;					
//	15	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.15&#160;&#187;					&#171; c3WsD79l6GO978Wjg2z1m6e9tl7TWnPDw6gJ04vcl2Em62t0wPn99X2NwVny6C96&#160;&#187;					
//	16	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.16&#160;&#187;					&#171; mwy492GVt16BhINo2ryYJS1f5U89n1875z9T055IjIOJ17076d2l8IF7ye89Lm1m&#160;&#187;					
//	17	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.17&#160;&#187;					&#171; 86pKAy9OZ925ghWXC4NCuEBhhcH3rJi4Q3lj43I3D1318TM3406Uk6m0As9Q9GuF&#160;&#187;					
//	18	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.18&#160;&#187;					&#171; 21jW6XfD4ebsL0hs1TgKu3939YCCq4S7nOYG1E1vI5OzijOladE51Fl98Tqfk5gM&#160;&#187;					
//	19	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.19&#160;&#187;					&#171; ONQJDhm3GOR6nR5g67MVxR7jtBy41T5hn6HxS6GJ9gRn2DzQeIXaC5tx5FzjkDz0&#160;&#187;					
//	20	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.20&#160;&#187;					&#171; vcC8cF8pYQ8dC0RxAGL598nEtL0b5Ar7U2K92y9Nk58939VMOxxR4825Sd75bVR3&#160;&#187;					
//	21	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.21&#160;&#187;					&#171; oR3Uq0oHBkSi42qf5r15olU7I6j0Lw0ua9W3yPW80F07fsJFkiJ83dqWK8KF8W4Q&#160;&#187;					
//	22	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.22&#160;&#187;					&#171; Rm7mu2POLEDJ48p5533OsyizGWJl9EBTh6YjpI872siXjE2Z4yuuglazyqN3u8rY&#160;&#187;					
//	23	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.23&#160;&#187;					&#171; 222996W9ZJIigZmrFSVOG9rR2qoi0XPQj8Q5pKGPw7I99B4E87d974IZsN4jKW15&#160;&#187;					
//	24	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.24&#160;&#187;					&#171; 172t1i97srlGI4M42kJ8e7gdWh61u9gZFiE195a9jtuZni4PpdznTdcEzZPc2Vz8&#160;&#187;					
//	25	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.25&#160;&#187;					&#171; 289s1psuo1B6QbRBHgR231MPi472b8PxV0MSQ1TZo670kbBZeLE9djHDPPpN8c79&#160;&#187;					
//	26	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.26&#160;&#187;					&#171; HEg542whe3eG8vMnIkEH0t4YN3QS7TGtM5Y91K2G6P0Lo9V40X04SHhD65Sv57D1&#160;&#187;					
//	27	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.27&#160;&#187;					&#171; F6jagB5LoDKStQTy2IMb4oBS9M6G801763o8HGs9S27TP3QfEupkV4WZ5wE6r67x&#160;&#187;					
//	28	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.28&#160;&#187;					&#171; vfyb77M8IoJ8KrPL9XlM4344593GfCI4LG5353xx1w0XA20V410K3yQ8rihrB8js&#160;&#187;					
//	29	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.29&#160;&#187;					&#171; UHBedTcq4H94QLPVM196t98e90v5a51YxmM70E7jeIA2N8yd2osmn5ulMm2JakI2&#160;&#187;					
//	30	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.30&#160;&#187;					&#171; 7Xc2t7QI7P9caJ64wDqZsM5PWBTA09dWfQGh2q76Pg1EX3ZQ1OHImmB7044AKu51&#160;&#187;					
//	31	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.31&#160;&#187;					&#171; Jej5X0L2k50o0Ho7rDb7Kr5G51Y56D17b8a6MvzdcZhYKdf68pygR08t74Wm0xhE&#160;&#187;					
//	32	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.32&#160;&#187;					&#171; MZw4U9h5aV26Jo3ED3kgnGgCEft5dB51igf9O4z7tSgSe7o4SO34QGZh17X2jRg6&#160;&#187;					
//	33	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.33&#160;&#187;					&#171; L7pe8rUO3gYH6A05n38U1w4tsM9fqsJhF2srq9w0K232o53cRrrQ4nRzeOQG9aHu&#160;&#187;					
//	34	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.34&#160;&#187;					&#171; 3215Ujucr63g8fS8UCA45AZduHZjC6N74d7T96745d93Y407bTudC783G0joHUHl&#160;&#187;					
//	35	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.35&#160;&#187;					&#171; yUI6hAqi4iw6i5dVK2W91nx0sC7A932Q8YY8oTN5BmXQ52LXlF1y6m0W8tS6Q74K&#160;&#187;					
//	36	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.36&#160;&#187;					&#171; oBv1Qjqad73twNX606SO5S6SWiY8eeX16xJTLEy8yg79Q23f8BAX6mUC1OpklcHF&#160;&#187;					
//	37	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.37&#160;&#187;					&#171; HpGdLhBk0eCylnkvswUz0p2rb3X767zxtC7iUWq4eRNa8Q1wT1NMQQ28Z38pnHO0&#160;&#187;					
//	38	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.38&#160;&#187;					&#171; V3R04SYn3S5xQqIplH349pL8SNJE81e7DHi1Q8pu4Tsb6xhBnzkq01Vu6ynPNFUE&#160;&#187;					
//	39	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.39&#160;&#187;					&#171; 693ALj9C73W92Clip5W9kQeFk9ZV8QCK3YDUGY4FOBDHJOPyBl01o1Ls0vJa9eDc&#160;&#187;					
//	40	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.40&#160;&#187;					&#171; 600v2H6A0vCOBr9D0F4xMq77L35EPQJOG3E9qW4f1d1IQ7h0hV6hSQMlDm1sv6q3&#160;&#187;					
//	41	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.41&#160;&#187;					&#171; 2pdF427p5OD73F9C2rjn2D69v937ASs7If7xfOr2Tl3q3UlfC2b5B284ZD7j8Bk1&#160;&#187;					
//	42	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.42&#160;&#187;					&#171; H4imrwIbP43630tBw2AXME85HNngXz46DPj49SXj7Q7329172nlV23FJ6ijc9h9V&#160;&#187;					
//	43	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.43&#160;&#187;					&#171; fb31p1csB298kGrn5AnHFW8i6p1M9CHgH69oDjF9sS1kY2FZ920QygYxf6BcR9K8&#160;&#187;					
//	44	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.44&#160;&#187;					&#171; tN3VB7JGlVOx6N3YJkqcbMnNdmhMuF52LJnmR0954XBBvZm4lS9v1AmJ4S7nN8A3&#160;&#187;					
//	45	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.45&#160;&#187;					&#171; 3Aj3vQ95inRtZAEDmquk7c9fzk863gLk4WEq0J1bk58S1ta8KOs6740VrYUN47DI&#160;&#187;					
//	46	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.46&#160;&#187;					&#171; wLv7qn3NJg3hsq0aVo9vOQAfoi0e3DPA5G2dUOi05cc0RSlnvzZ5cp0kNN8BUkmB&#160;&#187;					
//	47	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.47&#160;&#187;					&#171; 2xty26p32Ts4ESEX90RVOcEbcCMTviGD5xpJ70k8HvGeetnQkrgHGynaj2U7d86j&#160;&#187;					
//	48	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.48&#160;&#187;					&#171; L35Ei9v5gGILO4cA7s772YMEP72w4c0LDO8bv7IkIq6TRF0734F1wN6jl316gIMi&#160;&#187;					
//	49	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.49&#160;&#187;					&#171; FPr818t7L1TE0iXDNI3vhdTblyNHtxkPuEdFNNDkczE9QAa7vCe8aeLO39c3GTxy&#160;&#187;					
//	50	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.50&#160;&#187;					&#171; 81Q5Bq6c60111wb6nK7C2GhT324MFz6y1h6eHc3h7Ew0q8s0G91cE20BWIG48b6X&#160;&#187;					
//	51	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.51&#160;&#187;					&#171; d00L2iL1eK6yiiJpCtLHMCkMQz0x6Y6C68L92CA448id5X28SXyi1Sq3eA7Rt529&#160;&#187;					
//	52	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.52&#160;&#187;					&#171; g2sPolE3uP71e163jy4e1vPUjdQmmgOWmiIVpL4OM8i4Xkg2upkI4I0doR8kg6la&#160;&#187;					
//	53	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.53&#160;&#187;					&#171; KtNi56z67Ea7dQD2kE1D5y6H6Vr38AXmwNDLKJ8RlO2v630QBzt8Gs31dC7Yj494&#160;&#187;					
//	54	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.54&#160;&#187;					&#171; tzL8Dh7Imqs8878DEx204kzeNW4dA0fmO9veIPwou4uw9icJSBAx3rjB1X5L5YzF&#160;&#187;					
//	55	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.55&#160;&#187;					&#171; ig85Q79ejT0ue02A9Oi5j90Rk8k3VuoZWg1BH459X0QjOBv9bq2KvFQpdy7l51N3&#160;&#187;					
//	56	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.56&#160;&#187;					&#171; Oe7OGKM5313JZ9ZK0PozTTgo3iX06Wo51kL0ZgtNgsLVo0EaU2lPqfe9029ykN4q&#160;&#187;					
//	57	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.57&#160;&#187;					&#171; tZs2CvHqwL6x22QGLAN36Ac1ytJr0O7648qXI38Ykf73ro8O0LAP7tKs0gXcXCcw&#160;&#187;					
//	58	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.58&#160;&#187;					&#171; 6y46EsOi1OyuoF9Kuu0F05hluzmPe098h0T0s2H8lNj88kt2TNk14mdO3F6KL1YY&#160;&#187;					
//	59	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.59&#160;&#187;					&#171; r8iLiZ7893RZmaKr42AyBYiD4QSYHg6icep20IJ14Y5SNgn6vfgCPy00bRV643O9&#160;&#187;					
//	60	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.60&#160;&#187;					&#171; 23bPurb0oqm266pGONlYCfXQ5Th6xQ7zYb63K1jX94833q4c50782UXN2wd8mxmc&#160;&#187;					
//	61	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.61&#160;&#187;					&#171; 1jpiy41H907tLiXQa46441KA8RY5791eI47nD2I45bqhi13Ck4lPc7TbWU6Ty3lA&#160;&#187;					
//	62	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.62&#160;&#187;					&#171; zPeo8E6n1nq60botT1G4O3K1pukn62C7DBR0U01koR0hB08kk4KPCkIvaOfqN5vw&#160;&#187;					
//	63	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.63&#160;&#187;					&#171; lzvMO0p1S5311XbJ9I581ULt7uDF2lMrt38h57z3S46wS8RD8HAMq6x5cqKv78s3&#160;&#187;					
//	64	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.64&#160;&#187;					&#171; O9bz4IH487Sj365H6buu3rzIa41Uj0Yw764i9mF1G9uw878W95yRjq5J604g138E&#160;&#187;					
//	65	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.65&#160;&#187;					&#171; 4PLyd808EmX9DMsfehR34p0K377u52C1grzzvxFgP3UgjZCX5oQQ705219FH3lkE&#160;&#187;					
//	66	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.66&#160;&#187;					&#171; 27l1YA9wr5o566n3EHcBvkEYpF9231QmHi2BO8dd38PEi9PCzU08372iM4soRcb1&#160;&#187;					
//	67	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.67&#160;&#187;					&#171; 6Vy485thmOt5mH8R51h5266YmXcbagUc1id7lXpW338ZT8Tc9Rt0363RA5W4J6Ic&#160;&#187;					
//	68	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.68&#160;&#187;					&#171; fOEznL0OV0lDdbXQqM4Myn3Ka3Bk116p1wsb6K1QSl6A0ri44Szc2pbbhDpK1LDV&#160;&#187;					
//	69	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.69&#160;&#187;					&#171; r841Chyp33G8CWR1poztV49gjP1vR0b0CCaY73g7i1bk8Anx1OIPcVycn54TLMPU&#160;&#187;					
//	70	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.70&#160;&#187;					&#171; w7fsuKY7z3Xh7Pc4yV5603r6F87Ka1haWCQP89iGG8XH3ctVQZGRkD81SDZ06E94&#160;&#187;					
//	71	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.71&#160;&#187;					&#171; h3FXEYgL7v21efAGSaSg2c1rG5R3af4Sbu4Y6X888iq1IejZB4WT2BIvbn3fEN1i&#160;&#187;					
//	72	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.72&#160;&#187;					&#171; UNby5g8Ji8s9iS0wE6pvAfUKurHTbx104Q3N2pkj6u99HyhYZ9YT6ORnX4g5giEj&#160;&#187;					
//	73	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.73&#160;&#187;					&#171; GuJ1VhNu3ta48YIFcmNIeSvj10aHlm6LfW3zXVvgVLadM2IsZ89Y9c5Ku3kis102&#160;&#187;					
//	74	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.74&#160;&#187;					&#171; 6nKjV24P1B16r9yvI0S7GEspQoBZldSAFFX7HR8ot7rUW31qUAg2y90X27LJ841Y&#160;&#187;					
//	75	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.75&#160;&#187;					&#171; mJ8T43l9iXL8LX75xluilvW076yXyZbM2r5ohOe7o9JpS3ieNVLT81cN5P8bGOxA&#160;&#187;					
//	76						&#171; &#160;&#187;					
//	77	TOTAL INTERMEDIAIRE = 75 Pools de 100 Utilisateurs &#171;&#160;payeurs de primes&#160;&#187;, &#171;&#160;payeurs partiels&#160;&#187;, &#171;&#160;preneurs d’assurances subventionn&#233;es&#160;&#187;.										
//	78	Soit 75 Pools de 400 Utilisateurs &#171;&#160;assur&#233;s&#160;&#187;, &#171;&#160;b&#233;n&#233;ficiaires&#160;&#187;.										
												
												
												
												
//	1	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.1&#160;&#187;					&#171; 2buEJx1d7LX0Z6BAdu8bu2Fk9ZDPm110124VFO8c0c1V538o5R63gfUv5BZ8x6bL&#160;&#187;					
//	2	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.2&#160;&#187;					&#171; 8SrB5X194iCdgj444RKjSXasX3lt6OoXq0KEA4GK00e426a479kN9q2DO4Cgos27&#160;&#187;					
//	3	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.3&#160;&#187;					&#171; n9c357Qlq26rC53zOW35N6LAjKXmeLq6s0mBbZAT3nyj9xw8J0o2oC1Vo62C3iZR&#160;&#187;					
//	4	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.4&#160;&#187;					&#171; dEwX6XTKhuc7z222P633MNE08qM6wA9kgYzKvW48jSQOm161Zd81X7inOwCOrrDg&#160;&#187;					
//	5	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.5&#160;&#187;					&#171; yXJpdx7Q24IHkfJ9XESj1LMzC81ZC3qB5n670t1dCfVC3mwZ2lQvA4ZgI6j2v5fy&#160;&#187;					
//	6	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.6&#160;&#187;					&#171; g5wBHBPDJ3ty57onM279qCV6eu0tUC2q0x73qG832i3pUSiK03462mc32X1BU8pP&#160;&#187;					
//	7	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.7&#160;&#187;					&#171; 8TrL5tgwXU1Mv3kvhUz8gQUFI78Zu1S98Rtt3KKKb87yXu7m9mv9y15Cn9FB4q8z&#160;&#187;					
//	8	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.8&#160;&#187;					&#171; 6jWUrvxrPTfoqZzyTQ24s9TYr6l8NyjfU1vNIBOw2d6RWd0fHwXn4W2yj7F8m57m&#160;&#187;					
//	9	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.9&#160;&#187;					&#171; yd2M2718nTVMd4otu2J7F63BmG2PI5g02G1pN0u4Nisgax4WtriSiX9g6c1tHFj2&#160;&#187;					
//	10	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.10&#160;&#187;					&#171; 5Of9867wOwjs656Ab0zRlK8ygYmTo4dAlUG38ldD3w97P9F3o6FWB871NdgGXAaN&#160;&#187;					
//	11	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.11&#160;&#187;					&#171; w479hft0tDv1y05V5N2PR8R7WQcG3gD5yvi66BWCA4srvF7Q6pWQz1I46W04vz1N&#160;&#187;					
//	12	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.12&#160;&#187;					&#171; i0CCSL71jz67s3F6sql8zlEZLI00QWBx0uyM2FFUt4TNQBnGD7I66k769x28L8gj&#160;&#187;					
//	13	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.13&#160;&#187;					&#171; c51e5jP4QFbMVBbl88Buy711cxEU51TTy8k4AGByddwTWdWeY8iO1A93V8Mjx7j4&#160;&#187;					
//	14	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.14&#160;&#187;					&#171; 9b69L3TejJO60gBqj4Bc1qnRt8AQhrMbA5L3y89V5MCVnF7ikvr3H42Z37zh403n&#160;&#187;					
//	15	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.15&#160;&#187;					&#171; pj1005qlQh8Zr2S1M57yF27k3zSO2CEb4VS73luLT8MR0o2S4w2pxzJ4Si1LHHa8&#160;&#187;					
//	16	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.16&#160;&#187;					&#171; 1ei4VY1Z39b7p0M36csKk3FFi6tb971X5z82IRqY1nl10r5D57mC41h6nIH5ELT0&#160;&#187;					
//	17	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.17&#160;&#187;					&#171; a0FU3duyqT589Wj6925058QSf2XTEw2Hsdr6t5a53VMoJMuk2e34p3CWhTw8U24o&#160;&#187;					
//	18	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.18&#160;&#187;					&#171; DvIj17lN7tm6bQO4PU1GA597Z1GpO3njUtY6ncCFZm62y3NOYMxJ7W1P4jqQuOkf&#160;&#187;					
//	19	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.19&#160;&#187;					&#171; 8IsdGRC8YApezzM1272dmc18610d4RN7ZX2cyS7cwl761d4xPzbrqrv13sIS8xdq&#160;&#187;					
//	20	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.20&#160;&#187;					&#171; 8xqI09Z24o4vPHXE3kUnbt139v6MKn0zx55w2gyC4H4X7serhX3f87ZhrN9VwWQb&#160;&#187;					
//	21	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.21&#160;&#187;					&#171; S7Ir1vB96X7giC1GFMWTCTb8SikIjwn572zy815L3ejtphQHgIWL7Lp8Ic3im5W6&#160;&#187;					
//	22	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.22&#160;&#187;					&#171; 84KTq057j81Krx5fAwFa62w7zJ9H1w38GgjrjUTMF0gseDijF0xPvuY1H19416tx&#160;&#187;					
//	23	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.23&#160;&#187;					&#171; QkhXrbmh2V2Mox4yo18DDeVw4gdL91T6hXATul9Tu3rW4Q5LlS3V8APc1XJU1wt6&#160;&#187;					
//	24	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.24&#160;&#187;					&#171; T1VhkWfQCsAhg869vlr2bzq1v6Sm9289rB8342h8f5WdxYT468LPI3cGA731A5T8&#160;&#187;					
//	25	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.25&#160;&#187;					&#171; r9qHg0s5trnCp22YRSwQ01CUwMHBa3uC676ygi1L6wO4jCBISMDuSFatJB0gMK3L&#160;&#187;					
//	26	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.26&#160;&#187;					&#171; 95S06Q4O6aq39u6assz72k15e5usRwkpmcezVQ1DjjDhf5yNA2xcHPX5n5SrXYmz&#160;&#187;					
//	27	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.27&#160;&#187;					&#171; 43R5iL3tLaS6FI1a696W2Q1Je20X3YInu5A2EREI9GS7B92ZeAz2G6rt6cE2I57c&#160;&#187;					
//	28	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.28&#160;&#187;					&#171; h9R0v263V7WoqxV9g3SFIQp6L9vs2k3Mp0SP96z533sdr2f6xxv41hFzy1obMn2G&#160;&#187;					
//	29	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.29&#160;&#187;					&#171; Di2cTp81zxoA5Gb70KDfmdoc1HNu5BMmMELf6c4uvs720myS4t6Qn3jr4M7286Fk&#160;&#187;					
//	30	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.30&#160;&#187;					&#171; 4iyPXw9O07LJKC1ce1iP227vi25dMfl8b8KyBh5Nv8hZ981a2ih73Jiv9dKMs41n&#160;&#187;					
//	31	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.31&#160;&#187;					&#171; v5GxvXCdk596NU6899NEtEmFulyry3B870LM8aHV2XV3727y6hpuJEd800QponAm&#160;&#187;					
//	32	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.32&#160;&#187;					&#171; kk3kU48Xvrn3VdmI9qMCsJBAhqLjS7pP442LP3uiY8vK0pSzMplMKE0IS1kli98Q&#160;&#187;					
//	33	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.33&#160;&#187;					&#171; BI75q26T33RG4Tq7ZO3xV0SRTo6PsO572z0DfWcne0taxtHBMP28Mu61J7X5EmWM&#160;&#187;					
//	34	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.34&#160;&#187;					&#171; cD956zGi274w9CBSD20s002n59aCIbZ9b7deXW2gnVPlNhX1yA96zQ21AQcRf605&#160;&#187;					
//	35	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.35&#160;&#187;					&#171; Xhx9nugz5JDaIxelLVrV83V163u5GiVV5Lh1wUi01j9Pp60t09XpXc10U3eb2SYf&#160;&#187;					
//	36	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.36&#160;&#187;					&#171; PKPTrer7oRDFi82oCGrVhX4Co396D8ri3EY83luURqqLJyHKqU8B79XqD9470ovA&#160;&#187;					
//	37	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.37&#160;&#187;					&#171; 6371KqauMFP50Rn9kH1fd8qQyG57AKZcx4hD4Qp14AfZA83NrX9WIVH2cT7149WR&#160;&#187;					
//	38	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.38&#160;&#187;					&#171; 81JvjTTs3Vw8zc7sZ6a4RLwGWZK1j5qe1f7AS423E817Vr56W31K80LpdCd5dAS3&#160;&#187;					
//	39	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.39&#160;&#187;					&#171; Yt775tUQJrIuHmMF8yv0Qv73dgWXW2xvpGQhPY220c4C046hv3Lv7VUrx444x9Iz&#160;&#187;					
//	40	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.40&#160;&#187;					&#171; riBh8ybzGjBg7ZoAsq0QeS7eS2LPI4F4ZEFLVby83BZ0qC613907b85MC0aKe2Ex&#160;&#187;					
//	41	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.41&#160;&#187;					&#171; UAZkhCz8oZ5jL97Pj91eZhDmY5x556dJ4mP1J0103EL28Sk9LQlitWIK0DJZZj0q&#160;&#187;					
//	42	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.42&#160;&#187;					&#171; 1JQRj5JED41Hk698g0EEatVI5T45013en6D7BTDGRBxM7ZO24CzaIsZXo0pJJZlz&#160;&#187;					
//	43	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.43&#160;&#187;					&#171; 342DbGhG769Yys63G5tuclre715du4BKFtp0pQG8wy40ZNXB6o09165gLA757hrj&#160;&#187;					
//	44	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.44&#160;&#187;					&#171; 7ig85y5q4x08pFO9mZ6rnpuHQO40O6od6y75i244ezCPGx9SglOxQJbe7xwI2rUi&#160;&#187;					
//	45	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.45&#160;&#187;					&#171; VS31k5ubfHE76t0pknKw24I78a3572fg7r6rH8w5s9yjew0gROYyYgcdR3K6ENj5&#160;&#187;					
//	46	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.46&#160;&#187;					&#171; LzR3w0TC74704NpyOu7IU7680xo43lv74HHLfjg1DOa6AHHE7vceThvvjo6kj2jo&#160;&#187;					
//	47	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.47&#160;&#187;					&#171; w3UVEXmbjSP0vB831QEHibuOs1l6Qt7ZYTzNqQ2U4zm6Zzy8tgr63vy2m65DrzNf&#160;&#187;					
//	48	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.48&#160;&#187;					&#171; 1j7O6eUcQV966BQ4SH701pSP5Yd24d1cq40248QeQAeUCNs97I7OP0h1tokpVbXb&#160;&#187;					
//	49	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.49&#160;&#187;					&#171; 376i91z9NfJLX8rAaTlVS93QV0R55m2y9SjS7efbEUO06AYpmyPw8EKl7sWImrIt&#160;&#187;					
//	50	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.50&#160;&#187;					&#171; ZUR0ZY7w7ur0wg0fh3Nn2UU4YICbJ8nL8755CIw82JA0Wrv9GK4y5VPLYY4X04gH&#160;&#187;					
//	51	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.51&#160;&#187;					&#171; 9z0onLf5U455kbhsvL8o94329sy5ZKgYMSrdCfjn0Qh59ELZ9Vj72NhDi42n7ySI&#160;&#187;					
//	52	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.52&#160;&#187;					&#171; 5fYMoYn1inV5Lh8AD9G0Te4Wju0kFtUwvYXZCo9E9s18Alaw3SIBI170Fl2ij3Ij&#160;&#187;					
//	53	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.53&#160;&#187;					&#171; Er84MQYeWZIML9Wy9QbKA3x201Y89BvW0xqOZ1KEntTlnbT4l4gJ9d0s9EHIOUH1&#160;&#187;					
//	54	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.54&#160;&#187;					&#171; hoHtAtI73vl3E5pAw45Qn50IsJb40Tr144uH58bHT3Spk5UXTK9WuH44wqKy7J4Q&#160;&#187;					
//	55	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.55&#160;&#187;					&#171; 9q8B18A70xkk1489Q8d5J93C3Rraf07bm771DHEOE1lvRaw0555PLnDp30mztVUu&#160;&#187;					
//	56	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.56&#160;&#187;					&#171; E1haNuw5k1Ym3CQjX8723ykZHe4Y82Xv1G3Mf68zW5Q94P1DutYjeIv0lwEOiuBg&#160;&#187;					
//	57	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.57&#160;&#187;					&#171; 5FN6S66iJaJCJ4IMdkX837vhK69D0TP9h29my57n1KNN0t5t4hva4Yul7yUeV421&#160;&#187;					
//	58	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.58&#160;&#187;					&#171; WPe6y869o02tcJux1kl4ZHb5qE6TjaN0SiR1Y0uk807XU5Hy63724353Vk6N35Yq&#160;&#187;					
//	59	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.59&#160;&#187;					&#171; MYbcievizjPE7CfDpej4q7XOugHkh5oD8lWi613d2a6x362m1TFTN7lR5N94H1v3&#160;&#187;					
//	60	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.60&#160;&#187;					&#171; p7HNpR5BfBgbl55ldz2Q5Bv5UB6ZG4Zt8iCa1X5Hx7x0bfkTj7240AZsjCP904tv&#160;&#187;					
//	61	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.61&#160;&#187;					&#171; TCzJX5X6qPvro3736fHw0r68x9GGIcvMun31GJb2M93pB475071V83M7X7d4n1ZX&#160;&#187;					
//	62	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.62&#160;&#187;					&#171; OKDA623ZUQR2Av0hYkoNO6JBIu5gsZM62KjD6b5nJNW5191Em9Z4Jw436RS6hIMh&#160;&#187;					
//	63	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.63&#160;&#187;					&#171; GD0F47teGS82c3Y55VbN0qM1hzJGn1Dq3pmen06AEE49R0m2C61WQv7CBblP4Y10&#160;&#187;					
//	64	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.64&#160;&#187;					&#171; 11XsPblI3dxi3WL06pTDJMeL6bcTY6iM59UI280vIBSw50FB8zT8Rvl6sCBVNyJE&#160;&#187;					
//	65	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.65&#160;&#187;					&#171; AAZ0wuRb5s9LcRboIpEW8WMwXff2sDo0TC1Pp75gKdkaLuPB8AMnfZ00aay0IW4L&#160;&#187;					
//	66	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.66&#160;&#187;					&#171; YJ65Q9obO8E3OiVU124NJ43VmpqZo7JiOC2jL3n7vV7aardzg824wK3yZ27fDDj9&#160;&#187;					
//	67	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.67&#160;&#187;					&#171; xIwaZ1KFNw3s07gZ6p5Ja29czBy9XnU44ml82L605tL5TUctC5jd0HHpyNmc1mv8&#160;&#187;					
//	68	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.68&#160;&#187;					&#171; g4t71wHho97ws2q4Nl4A2bph266EJ5J5999CjXK5zKK08OL6xYiwmL6CvHB6Gu9i&#160;&#187;					
//	69	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.69&#160;&#187;					&#171; 04G09HfitY7iQPJ3Q2MAK5NX0hd8ule3BIX5mxP5MzVA8fbMFe6GrNEMcG3h7JV6&#160;&#187;					
//	70	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.70&#160;&#187;					&#171; q3lwk5m8C8xu1qGQ0w8t74Ub4IqosFMaE2e8SI4AkU77gw4381Ut27ZrpnrypXb8&#160;&#187;					
//	71	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.71&#160;&#187;					&#171; AwvT60S6p81O1n36ZWUFqD67sEt7BRe7UHjR0t44PZpsaa3h2GlJBNJbbm0SuK40&#160;&#187;					
//	72	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.72&#160;&#187;					&#171; kOtKhreLzg42Pf27NF6619Fxo2y0x941RBd10G1l8u17JZ4Ga30MoJGQTBBG6nHm&#160;&#187;					
//	73	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.73&#160;&#187;					&#171; fa9z6JFqJ50yOtRKBd84m8P4r2Avd4K701tfC2gZeCjxr0f088gZ1S6j6VqTA8v8&#160;&#187;					
//	74	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.74&#160;&#187;					&#171; 7iu7062xA56nG8m48cMZ545x08s5RE97O88Th6G9Noyc8SUKSY0j3eQ51wQTb092&#160;&#187;					
//	75	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.75&#160;&#187;					&#171; 74i3096FR6L55DASc3TyLZmbGPNM7iSSi600Q6X9g2fUQqbK0A1E9NCJ8Z742YgM&#160;&#187;					
//	76						&#171; &#160;&#187;					
//	77	TOTAL INTERMEDIAIRE = 75 Pools de 100 Utilisateurs &#171;&#160;payeurs de primes&#160;&#187;, &#171;&#160;payeurs partiels&#160;&#187;, &#171;&#160;preneurs d’assurances subventionn&#233;es&#160;&#187;.										
//	78	Soit 75 Pools de 400 Utilisateurs &#171;&#160;assur&#233;s&#160;&#187;, &#171;&#160;b&#233;n&#233;ficiaires&#160;&#187;.										
												
												
												
												
//	1	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.1&#160;&#187;					&#171; vreE3929f4Ix4KY0P3EME93g9q9R8evs3wZp7E1kK6YmYFrY7B3S1tGn6m8dOSAu&#160;&#187;					
//	2	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.2&#160;&#187;					&#171; v947Ya199avpyXdiYm300FAqDlSs5004YGW6j9133ea6iA0jl0hHbdBK810qZc3c&#160;&#187;					
//	3	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.3&#160;&#187;					&#171; I8IM5vqTd0emYDP2v5W5WG6yiF56C98nC7LXzp8u8Lwp3GVPDHPwwEq1T90Xs7tl&#160;&#187;					
//	4	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.4&#160;&#187;					&#171; rQbjeIQk0KIL79KbJL4F6Oh81PR6ym5FSxmFJCf1A662PZyzHVOg6sPmgm291thD&#160;&#187;					
//	5	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.5&#160;&#187;					&#171; 2o1aEwdWZ05wBtUb2yb8fU9C7B3Au9YCE135Tlx9DNBSLsMqW3mF21Zhms8X5vzG&#160;&#187;					
//	6	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.6&#160;&#187;					&#171; JZvC33AjLR9GCZAMxh3wb5q38H2H7aSI1x2f9CG45Uylqa2U15q5T99ZXLa9Hsdn&#160;&#187;					
//	7	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.7&#160;&#187;					&#171; QW1w61GDWf9H6M274ws49Ou4x48AxfD1450n4GLsPRwJtQXscAwQpZwSfZ6nDH13&#160;&#187;					
//	8	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.8&#160;&#187;					&#171; 13Wrl23D9rrwteCL4CoVQTsb66PC51k60Z2SL9TP7L47A2UARaomeNj0232MIrbK&#160;&#187;					
//	9	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.9&#160;&#187;					&#171; E3VRKWW3zmXImlj1GFCR7ZXo9343Al73xO913s859IYLvdDPDvhPX9v530Xr1OgH&#160;&#187;					
//	10	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.10&#160;&#187;					&#171; hS2i6Y2T1PQ5GFP51jb81XP075gA87x22XymH33LBEi29813FMPe2f3V4hYAPhYF&#160;&#187;					
//	11	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.11&#160;&#187;					&#171; HNVp81iV0R4asJx05I2RBG7W139t8DiL9y31q22P2H4Pj0dmv0eD3R51Mfdzs0qS&#160;&#187;					
//	12	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.12&#160;&#187;					&#171; 2xfQYB7w08296Y3pyV1Bs108Rx5E6PyX8P0bcFc0L1QRZF90OE994XR8cr06tfrH&#160;&#187;					
//	13	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.13&#160;&#187;					&#171; kYZfE8gTdT6N74jHl259SCWj5zUK20vC7kF6mn6cVR9Jn314VINo4AF1mFzsov98&#160;&#187;					
//	14	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.14&#160;&#187;					&#171; Jq5Wq5701EXlXc4eIEj99AglZQ774B35As66L28LfCIghGL5M94433C0Jz985AP5&#160;&#187;					
//	15	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.15&#160;&#187;					&#171; T0UKVtS0b2WyfG5O7zaEW7Weeu016BcmN3WG6KrGHUx8882cH5WwM3905W4wF4l5&#160;&#187;					
//	16	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.16&#160;&#187;					&#171; cdB6L66edqbhyY3zWG6huf71468RnHI0c493Su9s0p8uUurLuslA9UnBssEkPQ1u&#160;&#187;					
//	17	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.17&#160;&#187;					&#171; ZWPRdmfY088M4E7cHXF9L4f8iF151r2g4f58n3IQuyZe4UFJpt3fj2RvElZ0FNnS&#160;&#187;					
//	18	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.18&#160;&#187;					&#171; O8vhY5ar21cHvjPvYJIug1ORJ9dmCyNT90gs61a0W75fR99FdrlqGY53UVw4vdKH&#160;&#187;					
//	19	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.19&#160;&#187;					&#171; 3NmXx7oaDTGo1B9V8y4uer901OtRCJbVG27mJ8wmK2NwTXYm8OnBz4RREyGhVMkL&#160;&#187;					
//	20	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.20&#160;&#187;					&#171; y8z32uAzX1611lxe3udv74lx22UCfAwP7r7YYOwB5dpnEyQ1249Xw2N8T5YeQZQj&#160;&#187;					
//	21	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.21&#160;&#187;					&#171; 9pK3m41OsJ9P8Px4wCw0Z0vHK85Di8r92XyIw1GVv0N4Iw2x713Qi5G7O1Bf6QoN&#160;&#187;					
//	22	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.22&#160;&#187;					&#171; 7aTjilo2bb9to5WLNSGMA6guy9f6Oa5927u45OQNJLpxb65Z97E93Kj0M7nlMZA3&#160;&#187;					
//	23	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.23&#160;&#187;					&#171; L08UdizqNkm0cYD396RM974aEDA96KbWRPXO9YLj9c33UL4qPY8D61al93B2njzB&#160;&#187;					
//	24	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.24&#160;&#187;					&#171; Ra97RlPBH143f019H0ZQw1W3JZS2YZrO76D32ba1f3PLQcX8VVP8KA8aJ8S2JS2q&#160;&#187;					
//	25	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.25&#160;&#187;					&#171; TwWYmcojXI9oO27Qtz6H0v5vUY1iEFYAo7u8te692bf658YWDY60zX42e73IoBi5&#160;&#187;					
//	26	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.26&#160;&#187;					&#171; 9JIldI2Cvqa3hdF46CIT9eijsQQkKXa5BL7Nwkc9zn3qr0eYEHz0uL1Cl40V9S9X&#160;&#187;					
//	27	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.27&#160;&#187;					&#171; V3Sg19p5mCG32LK1zk3m5uTKp8a84TAk9m3O4JdERjZ85oZHWv80tHT0AP4Oo9SV&#160;&#187;					
//	28	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.28&#160;&#187;					&#171; u63ux0PS71tIoWZ9eFfgMHhS24BuQ59BA9xA0INK7OgqLPcaRPlrOg8e14s4SSpA&#160;&#187;					
//	29	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.29&#160;&#187;					&#171; 395A4LLc87QkAkd7CW542XP5Lv773uG5Otpse2LV6aBYsytFy08u624uDI1V3PJz&#160;&#187;					
//	30	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.30&#160;&#187;					&#171; m1Ov8Q2s8cJrK2KIDjpBJrA9Qz4p6nPz0W3H7EqtEwnjuMQTU3Nve4t3uqy1pMu7&#160;&#187;					
//	31	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.31&#160;&#187;					&#171; tGaf8VMx0s0IaBe1ZI6u5bSs1YgnRlhOXfBGZ3HK85TCA3Rni32NAB5yvS63jwWL&#160;&#187;					
//	32	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.32&#160;&#187;					&#171; HoH76LBNH7lSzpT1VPzDbDm53tzZObBBP195EmJ0zUShx3Ad01cK5pv9MS8IHcxl&#160;&#187;					
//	33	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.33&#160;&#187;					&#171; 4zjicFBJzb4AXimmj1446hrEfKIIEeSTdO9KEOmUhB4M1Ca8n2Z7X9n8v00whT23&#160;&#187;					
//	34	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.34&#160;&#187;					&#171; 46G2s1a4pL58Z80VpYfX8rdvo10SCg0jlBEz4x61UvW0Qx42vdBTBjQzVrDJQf4D&#160;&#187;					
//	35	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.35&#160;&#187;					&#171; 1475qMa7nR6ISY63Uh3eJM97NgT583MY9G42Nyg54U0Ml6M9Ex57ifFdJB5v3whv&#160;&#187;					
//	36	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.36&#160;&#187;					&#171; w6PuoVDA0362Y28Ec60039hv8l4CggiQ7CYRaE4frjv7ryRwr04NVt39ZyHIy2N7&#160;&#187;					
//	37	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.37&#160;&#187;					&#171; T7yYMFnT7zPrmT3CC321XSl61tl36b70fD309m1baGK65ws0ynzOgu4gc0gIy55y&#160;&#187;					
//	38	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.38&#160;&#187;					&#171; j1U2k55g6jOuC45zJKnTLN75YQ40o5hsUFsTMWJa77XFN3ttqi84x19vWOZdNU9J&#160;&#187;					
//	39	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.39&#160;&#187;					&#171; 7I51LTBEm06q3LjI29D0139W1KkDz551823q1870nr5r3TZ33iEJP9RHFiK8l08K&#160;&#187;					
//	40	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.40&#160;&#187;					&#171; G8Atl6Yjq39l57Vq2NG4yZv60ztjvI8Gqgq5s3775x368k3h4DpfUk8BV9341ttQ&#160;&#187;					
//	41	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.41&#160;&#187;					&#171; 60A8SyoG93z496H3s6Rtp361hUrLaazAnYb25601r72S22fOu28NhN3A8156F5qq&#160;&#187;					
//	42	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.42&#160;&#187;					&#171; 6D04n9h9lYSmc12a6yH90GRumjZ3s9v53i6tQw3LwzL73pBoC5oXXz6I25MTwkAu&#160;&#187;					
//	43	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.43&#160;&#187;					&#171; 6N5q73tcU07a588Sp2MwQ9bk3ZWFb2Z5ndKy8J6AX0BXUD1Gur5COR1Lp3qe2v9Y&#160;&#187;					
//	44	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.44&#160;&#187;					&#171; 579q6HJ4XJDM9ydEQV0Mp4CoJLfc0S92G5Sf4ZaHWsRq044f36922p69UGuvY23V&#160;&#187;					
//	45	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.45&#160;&#187;					&#171; A9j23K2wp61cN7MR30f6Jd2Jq64Jl3y0K9hWofz1IgUL1C0Z6m5TUH0hRnW3g4JV&#160;&#187;					
//	46	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.46&#160;&#187;					&#171; AdaZ0q4xFJSZkYciXE3yIT8x26eYcw59zqQFu45iHSZT1VC38x5NXvkUF2C0d5DS&#160;&#187;					
//	47	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.47&#160;&#187;					&#171; bN9UBqL8U1X5Re467ezsa2hA8paR4Yiw4oxCdGcTFj55LiMKhar7b3AQ2x301zWH&#160;&#187;					
//	48	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.48&#160;&#187;					&#171; 4g4pku92RYUDBsR66Y12iChky2b6vGI4liPdaDX4arkw8Nm19UJrwwu78K4V7HH9&#160;&#187;					
//	49	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.49&#160;&#187;					&#171; iv1z399TfvPNVo0r17Z6cy9OXJB4q70qCFzLzd8Ij8RxSla9N50UfYqyge5U64GM&#160;&#187;					
//	50	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.50&#160;&#187;					&#171; aDTZ0L003c3sl5PmzXCd2EtqHL0N8HbU7h8u5yNG9tkTihcQLpkwxqS0996sVX7f&#160;&#187;					
//	51	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.51&#160;&#187;					&#171; T01ju2cYs71PhQHhz9pRcMJi62hy4e526Fq28B3tDd2Px4utEMaWNREx4j4ltWoM&#160;&#187;					
//	52	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.52&#160;&#187;					&#171; yx382k0P9OdcZsr10Z29eh065Q1y2Q1d3X97m8TDRasJ1L42x70jLVHQLzY9WGqw&#160;&#187;					
//	53	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.53&#160;&#187;					&#171; 50ErhHrCmt88mntJ1gLsUfex19bY9nUw8gmgC5iT08Ns7su7jQb2CO1xm1o98ekp&#160;&#187;					
//	54	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.54&#160;&#187;					&#171; VW0v9aX464rQBanD4XK7Te2feBbhdR7U87xq1F976u494LW3f4C0S1R3X2Rr0X98&#160;&#187;					
//	55	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.55&#160;&#187;					&#171; pM5mgIk1f8LQ75gEOkjWhMgC9Z8JpzLQ4PJxF9BqO1XNarxT35u17Vifttsb924o&#160;&#187;					
//	56	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.56&#160;&#187;					&#171; nw4hL42UVhz2WR1uc4ezWctv1XphG203612jgKeAp0KcP6Bik7oj6p17MQd1j9y5&#160;&#187;					
//	57	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.57&#160;&#187;					&#171; JD7ljH8qVl7o3b7Tfirp7OXdAXBk0PsbT63tlHr9z8WqgCUrGSXq5u7X3u9doUiH&#160;&#187;					
//	58	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.58&#160;&#187;					&#171; KoSbG933ueY8Qim00Is5Z3WI62601FJchoVLayyle8xc8HrKB0bI5CMlzJXZS98T&#160;&#187;					
//	59	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.59&#160;&#187;					&#171; B2R064fhLLa4D05qaD97LSZjIvoPYcaJ511QyROAzSZM6NJcZ0R4Zz60B12HETSh&#160;&#187;					
//	60	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.60&#160;&#187;					&#171; FM6vay056CqJhoGq033D8PkmBs5x3vDVt93B30DyOdY6s4Y3O0bCnL7EYIQV051k&#160;&#187;					
//	61	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.61&#160;&#187;					&#171; 83K53nxo3EUVQiH59ts06C3VjQ13bNQev5D9N10LMVeG6NpngvM1B72orCKE6axc&#160;&#187;					
//	62	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.62&#160;&#187;					&#171; Solva6vX7Vx5nY0Ec5h65140q0Ows7BRz3k478a3md4HmUriQTJ4hBxd32q1sj66&#160;&#187;					
//	63	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.63&#160;&#187;					&#171; 7LU1ER1WbgBhZ7clDdP5pyTaATW8S530179L0PA06o6AgE32LJfjBy9i45u4rF6n&#160;&#187;					
//	64	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.64&#160;&#187;					&#171; NzHt5vp9muK8OloU84Coq9B2mk87uo5UEGs42kIY8k6W1iSu6sDO1fzS7w446y4K&#160;&#187;					
//	65	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.65&#160;&#187;					&#171; 1r83BeeC23vt1uM3Bgn9SX13P861Jjs3b5T75TSllJIxQ6NR79Ge8182Ivdw59b0&#160;&#187;					
//	66	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.66&#160;&#187;					&#171; ZF7c0CZ99gSkwDF39iP2FPiGwsh94VZsazOSFEB50ViIckAjCpoN3g95f1C0SKdM&#160;&#187;					
//	67	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.67&#160;&#187;					&#171; 6JLgLNnR9DO6o9dF98k326Wl8n2R325mx1I6sR9Gtu5kduZ4w2k3244LX5uJH3ee&#160;&#187;					
//	68	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.68&#160;&#187;					&#171; mOh2415sTX62eN7AsI7VmamKg76ZV9Gs312sky7L4u711qdd31X3774Kx7a3hFGl&#160;&#187;					
//	69	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.69&#160;&#187;					&#171; 0Jl0NVdGhD9RnYhsJ56xMxp6J7QvlfwpEMi502u3Cx657L89g0PcgTOGVk848tk2&#160;&#187;					
//	70	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.70&#160;&#187;					&#171; 3e3omblWa6v2R9ODSAxg0fYEC5LA0RsE2Cx7H413uVYN7K5pNQ7IwLhi1GX0HP1o&#160;&#187;					
//	71	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.71&#160;&#187;					&#171; 0fNSCjVT02W6262W8s2k6kbT5I9YN7C7bGGViTHw45cqe5oHOMt2Zbdb834Tcr8H&#160;&#187;					
//	72	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.72&#160;&#187;					&#171; 90e47P70Zv0HM8G3oag1kncp05V844f6333RJV2i0tMaA2sSJb25XMo4W78FPYw2&#160;&#187;					
//	73	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.73&#160;&#187;					&#171; leHF4k93pcxOMCN8WLViYcy0lQ8gk1MgBI09i0qjbzVA51umX25jS9N1x0N528v2&#160;&#187;					
//	74	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.74&#160;&#187;					&#171; H5F56uy1CK3D4zoo07Pi9l3GSrj5w6DN6aT64eXc9JtaO53Uh74M95sUiUbE52G5&#160;&#187;					
//	75	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.75&#160;&#187;					&#171; 1447UQO06mdX66SV0w6780Gx64xYKBS92vzaOULhOEAYaQncEt6q17qcv8b1kC75&#160;&#187;					
//	76						&#171; &#160;&#187;					
//	77	TOTAL INTERMEDIAIRE = 75 Pools de 100 Utilisateurs &#171;&#160;payeurs de primes&#160;&#187;, &#171;&#160;payeurs partiels&#160;&#187;, &#171;&#160;preneurs d’assurances subventionn&#233;es&#160;&#187;.										
//	78	Soit 75 Pools de 400 Utilisateurs &#171;&#160;assur&#233;s&#160;&#187;, &#171;&#160;b&#233;n&#233;ficiaires&#160;&#187;.										
												
												
												
												
//	1	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.1&#160;&#187;					&#171; O7O9XUl1Z25gtiJVGud547T7fE5M0N9QjLI907L2gbrgg3XzzRUK6C9vrw2Zkc63&#160;&#187;					
//	2	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.2&#160;&#187;					&#171; 1ow07CXCO1mpe7BOuOG7Bk48jD5KSGYPqQTK1j50jAoX3QDe1zB80nW9NkFp6exp&#160;&#187;					
//	3	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.3&#160;&#187;					&#171; N5eJj0J1Op9w7YBFdBt65HiK61mp8U71dxsQm3guNzcsPl2vtUG9dvN5mM27j65C&#160;&#187;					
//	4	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.4&#160;&#187;					&#171; g70M7uw3jP51p175v3UJy46IPzLSd9ZQy9mq1UBs91d8J2373xU5J61SlTsM6M59&#160;&#187;					
//	5	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.5&#160;&#187;					&#171; nfLNbn7Sw07IpT96JaR0h29rReBwJ6Pggqv1Lav9r1OqpNe9JkkRj7tRLB2323eM&#160;&#187;					
//	6	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.6&#160;&#187;					&#171; GfCYw0vcwF7S12N56Qg6C65Bo03gj52Y85R8EImEveS47ZEd05jBgOdwVHWU2NyB&#160;&#187;					
//	7	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.7&#160;&#187;					&#171; 1Oy1EoVez8P53Tl8bB2xMt2irfRXTB91Z56gzBJ8R394EI19G455901F9BceQoPR&#160;&#187;					
//	8	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.8&#160;&#187;					&#171; 53Sim3s9gy6X2vF70aUYgQE39BTb01SYm53HJjt0ODW0Mg81m81bXYzMXopG47k4&#160;&#187;					
//	9	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.9&#160;&#187;					&#171; q9621R8tyjxlOO8ZW77TgkzEvR8sZD5ayyfePI4S5ZFS3T1Xv3J2F5782usgfJ9v&#160;&#187;					
//	10	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.10&#160;&#187;					&#171; 74UBNclHp3W4Hmag6Id7275ae0mClYG9n7RMzOsrVE6AbXng0tMYCNPJ3JSJRQNJ&#160;&#187;					
//	11	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.11&#160;&#187;					&#171; S69k34iea6KakbUic6ikfpNL8jHVP1K39h9Zx1EIRpVIJttrG59m8rGc362H04CJ&#160;&#187;					
//	12	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.12&#160;&#187;					&#171; YNG2875ofPJ14Ku1mUdiSshgKYE597A03O0p6KTnv1V3VogsEUpult8SyNmFFykQ&#160;&#187;					
//	13	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.13&#160;&#187;					&#171; 0y67Ual7599RhVFFEzWvG7471Enmlt273z6uv76Rauu7wUvhyYq25k4WcoKdoYTB&#160;&#187;					
//	14	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.14&#160;&#187;					&#171; 1l7c5w57esBuVNWP5kfMK4rqUbyWb22mx7197nrv5tZS3V1z5rzeEFMN8rUsf667&#160;&#187;					
//	15	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.15&#160;&#187;					&#171; 3wuYqcaW3ldxX47h6P4jX95sbCaUsq5au5F9nJ7hUG7V8K19AA8718BD0xP689cY&#160;&#187;					
//	16	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.16&#160;&#187;					&#171; bgE71rbU98mlFv8N2WYOWd09PL6dlKGiqN1GxG20bJ1Ry2xu7z0ZOF6cmr2e1w7b&#160;&#187;					
//	17	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.17&#160;&#187;					&#171; qUuX070yz3k3GJM5HoqbizSFdrsFI09t24VR2jm59beKLdC3p2M55JlWe0DSTt1p&#160;&#187;					
//	18	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.18&#160;&#187;					&#171; 42OVVRuyGLMF596hN6681H91r0g5pOwDAvD3xa2aGlvsk17vy7F1acfh724dE4Ir&#160;&#187;					
//	19	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.19&#160;&#187;					&#171; nkGWtyJr4BD16N7I3o7PoUVchabWS88q99k60Ix1v60j3d51mZi85h8T1Ujvo9cX&#160;&#187;					
//	20	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.20&#160;&#187;					&#171; 31327PHZj1FYK5Tbxd3rc8rn0fy2oS5Dc23Ok5lmA2Jt4f9Z130YoNL7292D39W5&#160;&#187;					
//	21	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.21&#160;&#187;					&#171; MB2bH20CI13eV4LyDZP0fUg2QvReS845vdqR7d455IsccMMacrg5e4t8uc9067qh&#160;&#187;					
//	22	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.22&#160;&#187;					&#171; V4DT2NGJ76M28NEa50s0rCisa5yaD169s2i3nK7uHfq9pFB4wZ6A5LAv6lzc7UQw&#160;&#187;					
//	23	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.23&#160;&#187;					&#171; 8B21vGWZLHdVV7KsL5Rj53gBl6VNYet428S1zNb06eDm8hc5Ov3b1pFErGIp92kC&#160;&#187;					
//	24	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.24&#160;&#187;					&#171; B9f09BRB3d39ETC442KdOiVLs6i7L7I3roQR66jp8CORV7C8jJyzfnCQL3hEww2X&#160;&#187;					
//	25	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.25&#160;&#187;					&#171; D7caxo8mgOaPr5Gf9ckg88p9q0eFufkncet0lW821hh9I5e74WyezaY7Df2v768A&#160;&#187;					
//	26	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.26&#160;&#187;					&#171; itWO6deBGmATKG57yUB3Pn8oJ3PEhyD4XC9569c07Q2o17Hq22KQGg4gharl58w1&#160;&#187;					
//	27	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.27&#160;&#187;					&#171; 4V23QKFa9158r076xy28389i6A8ad4rqaE068Bn8ScoYvc6EWgPzfn57Xs7MdmaB&#160;&#187;					
//	28	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.28&#160;&#187;					&#171; 9S94DzKGlAIIR40VCNDsjUDc9b0445A7M397bkN93ov1nEvUo2pR08zx9jHnJkcL&#160;&#187;					
//	29	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.29&#160;&#187;					&#171; 8eigaGzd261GqMvb2Zrd9G1it1jS6lUzB3K2Y4GKSOl01cnXf3pA0sxkZOXLvGLA&#160;&#187;					
//	30	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.30&#160;&#187;					&#171; 5Y9CkXW7p7rXTD1R8an31fcP2xqqkCo1eoxHmrOn35qNp851192KDGyepxHFngHl&#160;&#187;					
//	31	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.31&#160;&#187;					&#171; H63OuWgLcOw6vEr58s79ZKK5kMwD3P3T7hNpC6YDYIB5Bt0ZG0PLUj1lr3tzPv1v&#160;&#187;					
//	32	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.32&#160;&#187;					&#171; zhDWq81b68tphV8FrM397h67qfC4HKTW764BdlaEC784Hl94tw8OfcBif7iKrBy7&#160;&#187;					
//	33	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.33&#160;&#187;					&#171; j8MM8Lp6WqDP9GyJH9WI8145Wck2gcwoqkM4GKQ3Cs5m1X3Ly5Y3Bd2uTJ3BLP03&#160;&#187;					
//	34	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.34&#160;&#187;					&#171; f0Lr8Q9Ih8v9BmZ9F6d21VGbql8jQu3sUn88po3AtgcH983F7YwR4Riek1lG2131&#160;&#187;					
//	35	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.35&#160;&#187;					&#171; 4N3XLp81Bpsl1Bo3GHN2f7ff6g229Y812RWs05Tmz94i4qQxE1mhcVdK92lln638&#160;&#187;					
//	36	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.36&#160;&#187;					&#171; QOF6L5HqGUvCxX1jTWH64tZR11W3ob5SR0cGzw4H6Wd694HV0aNpW4lT90lL0cR8&#160;&#187;					
//	37	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.37&#160;&#187;					&#171; 0YPYp0dMd6gk6JQ1pX4GrT35pa4n26WHEtW3Ro29hkL85K5ZVnX8t15n0ySt0Uw5&#160;&#187;					
//	38	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.38&#160;&#187;					&#171; GW8Iv8QBUU2rR4xmYNRm495Uz9m5YE47ggu3235r1qYE44zj2xC0r041Ian9ZE1h&#160;&#187;					
//	39	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.39&#160;&#187;					&#171; siVvQ88Bd267wA8BlWkEn6D0IF4y4Ot6c44MIqTIlah8S95vIUUQgSJE5ndQWa0b&#160;&#187;					
//	40	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.40&#160;&#187;					&#171; 4mz27ODxYjwwzzVN1s3iKE8fU1l0c3KMoqnOab1Js0ac26S6KqeOr9gZ0ur9ZZj2&#160;&#187;					
//	41	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.41&#160;&#187;					&#171; sP878Rl27Nr54P4PK96238C0js8kNO27panlqI2zVwkSTMTZGZ1641WBp6GlZo9I&#160;&#187;					
//	42	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.42&#160;&#187;					&#171; 2427A7Fg120N0yCmyO9Mg67L09X600RNAuJ1RsQfZmkXDAWYExs42BP3m6sbpmpE&#160;&#187;					
//	43	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.43&#160;&#187;					&#171; 37A3z60zj25yeUuba0rJr2JnEIQhucacUB2MMhRf0K3FrVdw682T54i8534jg7Jf&#160;&#187;					
//	44	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.44&#160;&#187;					&#171; JEj08oWL0gmgWI27J4Wj9W0z9g1W0e77dNT4YAF9a2DCXgO8XA5hZj12fooYT4H7&#160;&#187;					
//	45	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.45&#160;&#187;					&#171; a7Mc00t4A12x4rI0X5DRr5rhcLD4CHQ1yDd5zDf69ONTVSiNnD15qFKAMf92GCwV&#160;&#187;					
//	46	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.46&#160;&#187;					&#171; liL4MtU9c8eZCU8b6iZ6YS8w4b63nEK73b3R7pFmhZ93wlj1TnC3Lg40i9Kv6c2a&#160;&#187;					
//	47	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.47&#160;&#187;					&#171; A4mzqecI78eP0WY4iHY21bv9A27x9vW0TNNCsTJtN3V7RXGiFvwmzStV61VXnUiB&#160;&#187;					
//	48	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.48&#160;&#187;					&#171; BRayS1yBmKQ6dtxEnLeJZ7n7DgdZl99t3EL2QMmvRaC11kwdl53NgEE7ZMGx3UW8&#160;&#187;					
//	49	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.49&#160;&#187;					&#171; 1dih6RTd5TWMMpThNAomcUxrDZwM4OqTyJI4pL63tXW29XWPHZz04LSV2Rv8Xr6g&#160;&#187;					
//	50	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.50&#160;&#187;					&#171; YM12A02z1BT1JmfR7p3t44zr0bE6h0KqKus1z39o4Q9nlOaRb5p0wgVPY4fqmLc4&#160;&#187;					
//	51	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.51&#160;&#187;					&#171; Fc7PNEX9783TZpUUJ204cN5bTrA6fy905Kb3FDMyX61Wpn4sdk7Y5TpOAMxe3y31&#160;&#187;					
//	52	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.52&#160;&#187;					&#171; lWB87GrJ5CMvZLSoC6980M7vyI3742OENz4w0sc69b3NLkoy7Pbk9QQv8O9ksKWT&#160;&#187;					
//	53	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.53&#160;&#187;					&#171; K68N8baF08x9yX7XyFUr99BAw93Z25b99Y9p4tUlmRJRP02frwgyY25t89jrn9qU&#160;&#187;					
//	54	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.54&#160;&#187;					&#171; 791Sx7X277u14V8cM3jhUtyj0v43SxvPKreBCzX16tH96MWvKCZz309Em19V6N7D&#160;&#187;					
//	55	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.55&#160;&#187;					&#171; 3TDYPTv2zEbYO52X7Y8m01Du50bWlEk54aAdImQyiJ7r1M83wACgG5zre9Dg9WZv&#160;&#187;					
//	56	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.56&#160;&#187;					&#171; gs5C1XU3PkBTyDL84q60Nrh37EFjpIg54EU41Ydvw6765p5M9wk0a18279w0JDgx&#160;&#187;					
//	57	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.57&#160;&#187;					&#171; jM73a2l8x5A3rGIPu6Dd7F9m30106ht7D755QwK606J810T61P8BhX0X5lW7up9t&#160;&#187;					
//	58	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.58&#160;&#187;					&#171; r809mc0Z0f0juTaEnaUeNW0r7FeSgv39pMA49j9hnR4682ueZgbWvcMkPA7N8pqA&#160;&#187;					
//	59	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.59&#160;&#187;					&#171; SjRTU2GXToNt8B37L0GzuKCGpZ6EP199ELs5JWA7U3lw627pBYaPq8PF9bImj3V7&#160;&#187;					
//	60	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.60&#160;&#187;					&#171; qq2qbg3qhE70vg77p2r35XLEJcGcfr4D5z66uW05k748R3JkOLLPc0o186bQS8ju&#160;&#187;					
//	61	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.61&#160;&#187;					&#171; 8k01H2ln2dySFotwxAk0H5a8Izjz0095R3O82hbjD1SKvFrX4x9qUzcTI8yVDXOC&#160;&#187;					
//	62	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.62&#160;&#187;					&#171; HQE49ts9W7hmntcQIqPyd3sd1yq2hlgAE62WU8D92N3PW5249jhNYw69p8cV0eaf&#160;&#187;					
//	63	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.63&#160;&#187;					&#171; 7srPsU64hmKWLolk1PNUnMy0eUCOSr1KWOMb56a5sDXtT3cUQ3848iodK1S58uR9&#160;&#187;					
//	64	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.64&#160;&#187;					&#171; EOxVj8UwPl3vxR36uU86p823wwoVVHAWttrqwa92uAE69XWRZ94Q6zR0y2682761&#160;&#187;					
//	65	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.65&#160;&#187;					&#171; lu4N2qs4B0fGOtB6ulDhoAGKn67ErV3O1MV07yflwYe492sVec0waWUyHi3r1NeX&#160;&#187;					
//	66	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.66&#160;&#187;					&#171; 0QekL88u06GqP5Il53a8FHG9W7B6T77HKTjjq2sy3KvQ9t9QJC5giu8ryINn4cov&#160;&#187;					
//	67	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.67&#160;&#187;					&#171; E1ryodP8iN85im3E2off6WsuNjGpeYxcDq45UVcI64O5XSUPgn3nO75pK9XQqA6c&#160;&#187;					
//	68	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.68&#160;&#187;					&#171; H272gpV0zCT3DrfKaEnozpkBX3ku96Xa2eeZtb1tPeN8V44MwXMXW02MPMDVqK9y&#160;&#187;					
//	69	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.69&#160;&#187;					&#171; SAq5g7Vb5Pf13uT6Oq1p7YBh9pA9r951mUbi8MPOgKF4j437482KdmRIyCPM4MQl&#160;&#187;					
//	70	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.70&#160;&#187;					&#171; 1ElBD7183zUl0f5hJ2kz63cpX5sAb5dzkY228zc44om6Ekp06Rzu4MV1AL1C90xQ&#160;&#187;					
//	71	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.71&#160;&#187;					&#171; 61270F9CxAo16OM9HQi9z9wb73nYeS7JWZ5ILnVdmTJTmHj0ogo0O8jgBK6flYN7&#160;&#187;					
//	72	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.72&#160;&#187;					&#171; 3WW63Rb6nQ21AKzoC114S7vaV6Gv3D0a3zjmZa7xel23qlLFkrNvlFKE04XG2UwR&#160;&#187;					
//	73	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.73&#160;&#187;					&#171; JB4T3bW5k3nuja4MCC2vs5669WWs6e372ND9n262f18HqWG23HBFz8U3FHV46kl3&#160;&#187;					
//	74	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.74&#160;&#187;					&#171; OYfK280M81X75WqC7hzv7c0Rav1Z3Gim3af9N2wsaufV6AlQ7zpW7vq7E5ta26iT&#160;&#187;					
//	75	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.75&#160;&#187;					&#171; lXb7P37hUkxJ83mg90mPC4ydEyOlyRcr59b7lZmRO33sZLws0Ri8K8trhqZ08usq&#160;&#187;					
//	76						&#171; &#160;&#187;					
//	77	TOTAL INTERMEDIAIRE = 75 Pools de 100 Utilisateurs &#171;&#160;payeurs de primes&#160;&#187;, &#171;&#160;payeurs partiels&#160;&#187;, &#171;&#160;preneurs d’assurances subventionn&#233;es&#160;&#187;.										
//	78	Soit 75 Pools de 400 Utilisateurs &#171;&#160;assur&#233;s&#160;&#187;, &#171;&#160;b&#233;n&#233;ficiaires&#160;&#187;.										
												
												
												
												
//	1	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.1&#160;&#187;					&#171; 75j5yGT2oHz5L240tqEf4ic61Gz77KuHE7kN7kh2sLyqPuoqk6FIVD13LMfCI107&#160;&#187;					
//	2	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.2&#160;&#187;					&#171; j90FRqy0a1Zqj0NA7Ae0xvdP9U5wF0Q78gU6My4w11EhuJW9Sp0Y19XS58h7076I&#160;&#187;					
//	3	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.3&#160;&#187;					&#171; T10tfeCj87mDc2w58kX3pVqibWKVq29nYaN1yGa6c6E2Q6jdA6rlds60DeS27CKt&#160;&#187;					
//	4	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.4&#160;&#187;					&#171; O9DYZIdvu2dUJpfZ57SVZ8i9QhdQAALj5Q7LBWzu0Cmo7LRP3fJ955KGXPBBjN38&#160;&#187;					
//	5	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.5&#160;&#187;					&#171; 8nyZ87OrxU489NPzV4pF4jZRjTdAz697SpXP872246tDV68ev346J4QKArS2N0u7&#160;&#187;					
//	6	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.6&#160;&#187;					&#171; 9K2L3PwWe92IaPT9p0FSXz89zj2UGemT0o19B0YChQKAvu7V3iY6gK2khHgCoKpI&#160;&#187;					
//	7	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.7&#160;&#187;					&#171; qlgp87EXh2D94kV8rGLKp4Z486k91564g561ad1l0F2Oz001lS19XjxF3946CxoZ&#160;&#187;					
//	8	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.8&#160;&#187;					&#171; Nv5omcd9jIAjGj99h23y45BaE1JJ4uy5lQiw4woQ1DWgr1Z1Un788xiJw0F6zIug&#160;&#187;					
//	9	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.9&#160;&#187;					&#171; 902h7jl35y4U84YL4Ee5mVlU3q7gE44c7qn40vAV2WxR310Q67zxBsKxgdNb32iF&#160;&#187;					
//	10	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.10&#160;&#187;					&#171; 16Ds0UCyTeLZf6jRmojGd838uJ6DTE4i92aDzmbaNDg53MH52UABoohgoc935mYC&#160;&#187;					
//	11	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.11&#160;&#187;					&#171; 4wFae2TGd5z5853IJhWO3eZ18nKS2kc448a1U6zXX631RGetg6Q0D25YW35Jrs35&#160;&#187;					
//	12	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.12&#160;&#187;					&#171; rq4EEWU65Z9LPi9z9FXC7f0kv15TDobu46i7447UHZ7z2MVuVn7UbI58om48IWKz&#160;&#187;					
//	13	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.13&#160;&#187;					&#171; Jr4Iuae41jKvkpnxJAlRfztB0IZmC7Kf3rk2ndQXUN2q33Yjv7b4J78K8y825B1L&#160;&#187;					
//	14	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.14&#160;&#187;					&#171; I27x8jVe4MBeYSR7Z1k644p5Bsml1MDS3oCfQ5D5qPZ19S5X3VK5D20KGKoKXrfx&#160;&#187;					
//	15	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.15&#160;&#187;					&#171; 0Lnx9eFEfMkXxEI6slBLEW446lAY2i95l00LgsBs0trN3MKQm8opz519Sg0TemWr&#160;&#187;					
//	16	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.16&#160;&#187;					&#171; M8kwo8Fc2Ood7AW7h9wU384Z7R0htg3awK7Qq7JvLYPixYD9tYXvO1d9dh77v1Bq&#160;&#187;					
//	17	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.17&#160;&#187;					&#171; jSgDcO3nKCFxKRfs159oLY36Na0KtU1w1jgZ5B9Q4MO3f7ay4wI7UjM4lU3JFkve&#160;&#187;					
//	18	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.18&#160;&#187;					&#171; 9M7eF42i8y214o05K1seHnlILkqCUHnU2xUAL0m22wH7l2c240Sgh4S6dTSqSsr0&#160;&#187;					
//	19	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.19&#160;&#187;					&#171; DJ7ggN36xEZzeODm409fVOV2F9TUfBQ1YSEAi4qVzb1nAJnpDz9rxgN30uLpZXne&#160;&#187;					
//	20	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.20&#160;&#187;					&#171; Q216oU8CeP8i5x25h1IE182gD02lbTjRYTBgC19w9ld8r0xkrxDhbITvLkC08Ec4&#160;&#187;					
//	21	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.21&#160;&#187;					&#171; g3iZ0M0L2l0pcf4n1d4e0Ol8F6O5x9q215Yi2sPSDfG214TD2nYRfuQKNMmIXL7O&#160;&#187;					
//	22	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.22&#160;&#187;					&#171; 9KWqfFvP0gA37QUIdDtMiaO17xAmv3vSB76751DVIvre83yNGU2H1GGJ0pgA5C44&#160;&#187;					
//	23	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.23&#160;&#187;					&#171; W8mUh0LOmUo2Y26Eh8tJQ1NZp3Qk01EVNjaGIadfsV37H84Tq81269qUUDy9J41I&#160;&#187;					
//	24	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.24&#160;&#187;					&#171; d27u3fL563o6hQwGF69vjlNtue45w14hP3n3aX5zaOsTbADBW57Y90Ex7TBv396l&#160;&#187;					
//	25	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.25&#160;&#187;					&#171; mj3PAHqIK16CFunCRyDPYPcB4ge2dKFJL95Fw6nG55625L35bEjgjhhwTV105b68&#160;&#187;					
//	26	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.26&#160;&#187;					&#171; FgyJ4fN4iEz6M2x0zx0jH12IMdGprdD0l6i9wo3Ya80853InvKqoO9t17xkYnWbw&#160;&#187;					
//	27	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.27&#160;&#187;					&#171; 1PJzJO5Opq9n02K2TfkUFrv9NK75I2rcx2dzy46Jua6frpWYkDdziOPDPx39tKVQ&#160;&#187;					
//	28	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.28&#160;&#187;					&#171; 0T1rgfCn7quaI0e6M2U8K1dWqv0p1Q16Ol47Dyw75zZJ51gQpA6mqt1dz99MV8UI&#160;&#187;					
//	29	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.29&#160;&#187;					&#171; 7vL5D9tD66v0yNbBwO2HkCCRlUxc9x9UWtXxMmz4Fq2DnXnjx307W29R2BVy76zr&#160;&#187;					
//	30	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.30&#160;&#187;					&#171; 1162waqV4S428qo4bYA87fMg0ySmEDlb7369z0271U719VhZ1r3mVOZ9TukL3drS&#160;&#187;					
//	31	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.31&#160;&#187;					&#171; xE7nyS4hbyMskV7b5d66FOl529k3y3Xgl57m90R31c2043Yip1q58xFMwJ0h27QL&#160;&#187;					
//	32	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.32&#160;&#187;					&#171; 696K86nzzcF5274n2Ta4M9Fp4BXlUL77v95IN7IK06dI6wpuuB6YB1qjISYczaIa&#160;&#187;					
//	33	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.33&#160;&#187;					&#171; B9jqc105er8NywiiG7scUX88e6oU2o82fdjRp8GB45px4MqA41v95LZlPv0k30Vm&#160;&#187;					
//	34	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.34&#160;&#187;					&#171; 1Mmf2fv4c917UZQ0q08Mc89vhB5IiwNOMbcnA1rlXiPbv4P6naqf5hVtR6PP2wxt&#160;&#187;					
//	35	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.35&#160;&#187;					&#171; WPF4ZYL0kqLZSO9u54Bx9wgxlM0afEY7R21d9y4ilscY2kDnn6T2qLbgsi8tZbXU&#160;&#187;					
//	36	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.36&#160;&#187;					&#171; 5hQ1KAw0vOwCS4QbM57l3LcAN8IEr9tIQBrr3om7V4jDqz8hp472b0u2RMA6myw4&#160;&#187;					
//	37	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.37&#160;&#187;					&#171; e8UcC0Zt2fx1F061JmlxjSQZhl2egrPzm77f55D3sZAlr8J3FNbCe94UU9vpPEoT&#160;&#187;					
//	38	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.38&#160;&#187;					&#171; x32rQ5n1Ps6I8Pqf5206h5Fs9y9ZrCuepdx4k8zCtsf5b2ojDHprB158L74Bfby3&#160;&#187;					
//	39	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.39&#160;&#187;					&#171; 14YBI816G0gnCOTMfU4PB6L8X90eNzhvu8e96okPaOq04KM5SA61uIfF3H6Sq55B&#160;&#187;					
//	40	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.40&#160;&#187;					&#171; QA61XKB2CD6K0yG06cSuJ6Bu3I15N89sG1iAQhNg7uyF15646RyT26RG37K1rlGM&#160;&#187;					
//	41	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.41&#160;&#187;					&#171; 9cL74Bx65g7y434tj97GQSkjly0mVipDy42XEmoI59HaPZ9Bs26Gf445RiAdPbrU&#160;&#187;					
//	42	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.42&#160;&#187;					&#171; 13hAoMLZyUd08ud2Pd1tW9byJu1m418y0fGi49lG078eK7iZYGV9bCMe7cF8z0j3&#160;&#187;					
//	43	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.43&#160;&#187;					&#171; Eot3isxhgYuqQsRD2FD13h1QtRP3iBT4IGKPgg1EPO2r742BXWD8SZI00I8fJ458&#160;&#187;					
//	44	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.44&#160;&#187;					&#171; g8LLiXl4873D788NO5zprQhU6nJDv34o6AFTvY5EQ5S1u9Srk13A0zLM6tznx038&#160;&#187;					
//	45	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.45&#160;&#187;					&#171; 48KKnXDQ7icJ2T8GPOO333VM9F53CjUVlrzl44c79G2wBBtkA0ICOl9o43Dp1f02&#160;&#187;					
//	46	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.46&#160;&#187;					&#171; 9b7bA85D0xYC6Ii939BA10DoCyT4WwN9JxD0WPDrrd1MbXY00s1T21MDA3h4W0Uh&#160;&#187;					
//	47	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.47&#160;&#187;					&#171; 5Ug1ECf9hRR9PRTufzi752329rKk5H9gltzQx7VaAE7Qyv99U0oR33jCOWV1oYgj&#160;&#187;					
//	48	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.48&#160;&#187;					&#171; hzWM8A8ErrwY3pZImgTCiEfTmzp3NP1x4YKgfBCu1X7Lwb287AAyt6iU829023Rq&#160;&#187;					
//	49	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.49&#160;&#187;					&#171; OfnA880Gx7HVsxe33bD7slhF282cuf0Noy2j4gCGRGVR7vRh9igkcWbMN17wbazW&#160;&#187;					
//	50	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.50&#160;&#187;					&#171; 04b7X7EV6CIqFbAUr2V0aG1V159JV7k48SNcVeIa359XHp7962kBGHta20lgwH2S&#160;&#187;					
//	51	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.51&#160;&#187;					&#171; 12Qv6w4A8C1xYn209jJcM0Peq43ZjCc77gsT1j58dklB97gf98246b8e2yuPt76S&#160;&#187;					
//	52	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.52&#160;&#187;					&#171; 0E3XfpMBbZ935Tw3A7rVPN49Vn6T2f14rNg3Hdu18qwvx8PvBvF25XtuMp4lCJnj&#160;&#187;					
//	53	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.53&#160;&#187;					&#171; Uz8g59Y7wWaB26Kt53nq9e7h4e07Ok4pU5s656hV6TZyil49M54iJJv6IMRYknf3&#160;&#187;					
//	54	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.54&#160;&#187;					&#171; i9b596T6T78w6iDq9JPf2EY541J456E132W8Qf58OS7pQzDbBwfnloiI0bBpXD29&#160;&#187;					
//	55	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.55&#160;&#187;					&#171; 14yYbqRKbztqC2ea80Na7k397kCaZIaiQ97JW9gHhP3W67Ht5WK5nOS52ph5508x&#160;&#187;					
//	56	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.56&#160;&#187;					&#171; E3kEVJ32UwyFhIi0t58aKYS550i3qAW8Qr5QEI0K75O7QJVzay5j5027bZ21yh5P&#160;&#187;					
//	57	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.57&#160;&#187;					&#171; YQZQzp14wVqOfe8m820k52bf8EdNqt44xqcgX3046q79LwmAcudH7tUhz2A3N1Bl&#160;&#187;					
//	58	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.58&#160;&#187;					&#171; p3IG2E83Q4ED2o9u0dPn30Vv5Fvj4fU1m2a8y2F8iNRKff8385EL5y6OAqEI5nc6&#160;&#187;					
//	59	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.59&#160;&#187;					&#171; iJN5axd1ZxgQ1QRI1xF81x6VX073N34xdMd3U54M7bJn71vDNmkZvFr01t42mA1N&#160;&#187;					
//	60	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.60&#160;&#187;					&#171; jp4ZOk3ugZ4ME02rQttM11MaX1y2G6Ajcm56O506tnz1yc4ouD5oq3o48Xs7sGET&#160;&#187;					
//	61	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.61&#160;&#187;					&#171; jbhUS853xe5R782Is3MhCp4u7PK26Vot9F80E77G4oCD7UjK0Tz7zpPCEw7a1O0b&#160;&#187;					
//	62	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.62&#160;&#187;					&#171; Owf62JSpv2Ec1XW3o7i8M79PKyGGFFY4nEIEXLj3u565diull4173ZVRwoE1uZbg&#160;&#187;					
//	63	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.63&#160;&#187;					&#171; ysncWL0J2OD9gDB59ZH0rBtDcLTh3dYEAOW3lE5HgPpXgcuWbRbGNzCKBlTClR3o&#160;&#187;					
//	64	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.64&#160;&#187;					&#171; L49NWx204knU83ibUb45q2ivKw9ZDs0hilb1LPj307jl9SxvebZtnEWOlF05yH9e&#160;&#187;					
//	65	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.65&#160;&#187;					&#171; m7rAM8S8RYkC3ws1673iR7bgO7oOh8Smk79xED02nWQX45LN0n0bvOMnnd5Q88OB&#160;&#187;					
//	66	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.66&#160;&#187;					&#171; eh6FezF8UJ5qZovzQ961WNzx0N85MLHyt48G0f7N861TH6kKPr5c4wcC939IyQ4g&#160;&#187;					
//	67	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.67&#160;&#187;					&#171; ydAiQu1FZ247Io2h0geCWDIGZ3p4Hcg9C5m15L79uWeX3G1Ih83nhy1n69049I18&#160;&#187;					
//	68	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.68&#160;&#187;					&#171; 25Ls7KLvuxtEjqM2VOdJZTiDHMYngNk5I5yzV3yy0TTk2RYQ47j31b1LJ4223J7t&#160;&#187;					
//	69	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.69&#160;&#187;					&#171; XBETqN2ulqV650zZ8GXb1u1Kg523JBi4TTTXHrYnmH19SGG8AOs7z9S9xq4v8Pof&#160;&#187;					
//	70	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.70&#160;&#187;					&#171; tBoXt0U4T9545s3M0w222tL5WJO4U0eta4gCX21BG24QLj9X8q1633QVrmwGOLiw&#160;&#187;					
//	71	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.71&#160;&#187;					&#171; Dl3vS2g2a0B38lvM2X3H409p61E98gr3Zm8Oj3D5Yn5uSou0K4m0M2hYCHvm1pHx&#160;&#187;					
//	72	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.72&#160;&#187;					&#171; 2260pxrplGK6ZjeJ03pX70ls5c39rll6SObrPq50VVHM57d8736mL91lT6jqtTUg&#160;&#187;					
//	73	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.73&#160;&#187;					&#171; dEWWID4171V6jv1MblC7t19uLjd9q3W4kPessAN6w7Q5K3yxJp974IBbQ3N20Q1Z&#160;&#187;					
//	74	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.74&#160;&#187;					&#171; yy6659L5V4Ndoo1300RH46d4Z55N4qmGt6KoaPsjWAlA8fErs280GUy6XeyA172S&#160;&#187;					
//	75	&#171; Adresse / Pool ID de 100 Utilisateurs / 400 Utilisateurs.75&#160;&#187;					&#171; C424T29Gdp8VB99d31hB8IJgh757Rs2rGm9kwi2CKID6965KC2lFV8Iu6n06mxi4&#160;&#187;					
//	76						&#171; &#160;&#187;					
//	77	TOTAL INTERMEDIAIRE = 75 Pools de 100 Utilisateurs &#171;&#160;payeurs de primes&#160;&#187;, &#171;&#160;payeurs partiels&#160;&#187;, &#171;&#160;preneurs d’assurances subventionn&#233;es&#160;&#187;.										
//	78	Soit 75 Pools de 400 Utilisateurs &#171;&#160;assur&#233;s&#160;&#187;, &#171;&#160;b&#233;n&#233;ficiaires&#160;&#187;.										
												
												
		}