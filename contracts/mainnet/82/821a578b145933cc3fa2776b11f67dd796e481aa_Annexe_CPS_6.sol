pragma solidity 		^0.4.21	;							
												
		contract	Annexe_CPS_6		{							
												
			address	owner	;							
												
			function	Annexe_CPS_6		()	public	{				
				owner	= msg.sender;							
			}									
												
			modifier	onlyOwner	() {							
				require(msg.sender ==		owner	);					
				_;								
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / STRING / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			string	Compte_1	=	"	une premi&#232;re phrase			"	;	
												
			function	setCompte_1	(	string	newCompte_1	)	public	onlyOwner	{	
				Compte_1	=	newCompte_1	;					
			}									
												
			function	getCompte_1	()	public	constant	returns	(	string	)	{
				return	Compte_1	;						
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / STRING / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			string	Compte_2	=	"	une premi&#232;re phrase			"	;	
												
			function	setCompte_2	(	string	newCompte_2	)	public	onlyOwner	{	
				Compte_2	=	newCompte_2	;					
			}									
												
			function	getCompte_2	()	public	constant	returns	(	string	)	{
				return	Compte_2	;						
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / STRING / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			string	Compte_3	=	"	une premi&#232;re phrase			"	;	
												
			function	setCompte_3	(	string	newCompte_3	)	public	onlyOwner	{	
				Compte_3	=	newCompte_3	;					
			}									
												
			function	getCompte_3	()	public	constant	returns	(	string	)	{
				return	Compte_3	;						
			}									
												
												
												
		// IN DATA / SET DATA / GET DATA / STRING / PUBLIC / ONLY OWNER / CONSTANT										
												
												
			string	Compte_4	=	"	une premi&#232;re phrase			"	;	
												
			function	setCompte_4	(	string	newCompte_4	)	public	onlyOwner	{	
				Compte_4	=	newCompte_4	;					
			}									
												
			function	getCompte_4	()	public	constant	returns	(	string	)	{
				return	Compte_4	;						
			}									
												
												
												
												
//	Descriptif :											
//	Relev&#233; &#171;&#160;Teneur de Compte&#160;&#187; positions &#171;&#160;OTC-LLV&#160;&#187;											
//	Edition initiale :											
//	03.05.2018											
//												
//	Teneur de Compte Interm&#233;diaire :											
//	&#171;&#160;C****** * P******* S********** Soci&#233;t&#233; Autonome et d&#233;centralis&#233;e (D.A.C.)&#160;&#187;											
//	Titulaire des comptes (principal) / Groupe											
//	&#171;&#160;C****** * P******* S********** Soci&#233;t&#233; Autonome et d&#233;centralis&#233;e (D.A.C.)&#160;&#187;											
//												
//	-											
//	-											
//	-											
//	-											
//												
//	Place de march&#233; :											
//	&#171;&#160;LLV_v30_12&#160;&#187;											
//	Teneur de march&#233; (sans obligation contractuelle) :											
//	-											
//	Courtier / Distributeur :											
//	-											
//	Contrepartie centrale :											
//	&#171;&#160;LLV_v30_12&#160;&#187;											
//	D&#233;positaire :											
//	&#171;&#160;LLV_v30_12&#160;&#187;											
//	Teneur de compte (principal) / Holding :											
//	&#171;&#160;LLV_v30_12&#160;&#187;											
//	Garant :											
//	&#171;&#160;LLV_v30_12&#160;&#187;											
//	&#171;&#160;Chambre de Compensation&#160;&#187; :											
//	&#171;&#160;LLV_v30_12&#160;&#187;											
//	Op&#233;rateur &#171;&#160;R&#232;glement-Livraison&#160;&#187; :											
//	&#171;&#160;LLV_v30_12&#160;&#187;											
//												
//	Fonctions d&#39;&#233;dition de comptes :											
//	Input : [ _Compte_i ]											
//	Outputs : [ _Compte ; _Contrat ; _Cotation ; _Quantit&#233; ; _Notionnel ; _Deposit ]											
//												
//												
//	&#171;&#160;Compte&#160;&#187;											
//	Compte du groupe C****** * P*******, par titulaire et ayant-droit-&#233;conomique											
//	&#171;&#160;Contrat&#160;&#187;											
//	D&#233;nomination du contrat											
//	&#171;&#160;Cotation&#160;&#187;											
//	Cours initial lors de la souscription du contrat											
//	&#171;&#160;Quantit&#233;&#160;&#187;											
//	Nombre d&#39;unit&#233;s de compte en volume											
//	&#171;&#160;Notionnel&#160;&#187;											
//	Valeur notionnelle totale couverte											
//	&#171;&#160;Deposit&#160;&#187;											
//	Montant initial apport&#233; en garantie lors de la souscription du contrat											
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
//												
												
												
	}