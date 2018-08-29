pragma solidity ^0.4.24;				// 0.4.24+commit.e67f0147.Emscripten.clang					// 0.4.24+commit.e67f0147.Emscripten.clang																		
																												
	contract		LifeSet_006	{	// CPS88 Life Settlement beta 6																							
//																												
//																												
		// part.I_fixe.../.../.../.../.../																										
//																												
		uint256	public	deathFactor_i					;		/*	i	*/															
		uint256	public	deathFactor_ii					;		/*	ii	*/															
		uint256	public	deathFactor_iii					;		/*	iii	*/															
		uint256	public	deathFactor_iv					;		/*	iv	*/															
		uint256	public	deathFactor_v					;		/*	v	*/															
		uint256	public	lifeFactor_i					;		/*	i	*/															
		uint256	public	lifeFactor_ii					;		/*	ii	*/															
		uint256	public	lifeFactor_iii					;		/*	iii	*/															
		uint256	public	lifeFactor_iv					;		/*	iv	*/															
		uint256	public	lifeFactor_v					;		/*	v	*/															
		uint256	public	lastBlock_f0					;		/*	0	*/															
		uint256	public	lastBlock_f1					;		/*	1	*/															
		uint256	public	lastBlock_f2					;		/*	2	*/															
		uint256	public	lastBlock_f3					;		/*	3	*/															
		uint256	public	lastBlock_f4					;		/*	4	*/															
		uint256	public	lastBlock_f5					;		/*	5	*/															
		uint256	public	lastBlock_f6					;		/*	6	*/															
		uint256	public	lastBlock_f7					;		/*	7	*/															
		uint256	public	lastBlock_f8					;		/*	8	*/															
		uint256	public	lastBlock_f9					;		/*	9	*/															
		uint256	public	lastBlock_f10					;		/*	10	*/															
		uint256	public	lastBlock_f11					;		/*	11	*/															
		uint256	public	lastBlock_f12					;		/*	12	*/															
		uint256	public	lastBlock_f13					;		/*	13	*/															
		uint256	public	lastBlock_f14					;		/*	14	*/															
		uint256	public	lastBlock_f15					;		/*	15	*/															
		uint256	public	lastBlock_f16					;		/*	16	*/															
		uint256	public	lastBlock_f17					;		/*	17	*/															
		uint256	public	lastBlock_f18					;		/*	18	*/															
		uint256	public	lastBlock_f19					;		/*	19	*/															
		uint256	public	lastBlock_f0Hash_uint256					;		/*	0	*/															
		uint256	public	lastBlock_f1Hash_uint256					;		/*	1	*/															
		uint256	public	lastBlock_f2Hash_uint256					;		/*	2	*/															
		uint256	public	lastBlock_f3Hash_uint256					;		/*	3	*/															
		uint256	public	lastBlock_f4Hash_uint256					;		/*	4	*/															
		uint256	public	lastBlock_f5Hash_uint256					;		/*	5	*/															
		uint256	public	lastBlock_f6Hash_uint256					;		/*	6	*/															
		uint256	public	lastBlock_f7Hash_uint256					;		/*	7	*/															
		uint256	public	lastBlock_f8Hash_uint256					;		/*	8	*/															
		uint256	public	lastBlock_f9Hash_uint256					;		/*	9	*/															
		uint256	public	lastBlock_f10Hash_uint256					;		/*	10	*/															
		uint256	public	lastBlock_f11Hash_uint256					;		/*	11	*/															
		uint256	public	lastBlock_f12Hash_uint256					;		/*	12	*/															
		uint256	public	lastBlock_f13Hash_uint256					;		/*	13	*/															
		uint256	public	lastBlock_f14Hash_uint256					;		/*	14	*/															
		uint256	public	lastBlock_f15Hash_uint256					;		/*	15	*/															
		uint256	public	lastBlock_f16Hash_uint256					;		/*	16	*/															
		uint256	public	lastBlock_f17Hash_uint256					;		/*	17	*/															
		uint256	public	lastBlock_f18Hash_uint256					;		/*	18	*/															
		uint256	public	lastBlock_f19Hash_uint256					;		/*	19	*/															
		uint256	public	deathData_f0					;		/*	0	*/															
		uint256	public	deathData_f1					;		/*	1	*/															
		uint256	public	deathData_f2					;		/*	2	*/															
		uint256	public	deathData_f3					;		/*	3	*/															
		uint256	public	deathData_f4					;		/*	4	*/															
		uint256	public	deathData_f5					;		/*	5	*/															
		uint256	public	deathData_f6					;		/*	6	*/															
		uint256	public	deathData_f7					;		/*	7	*/															
		uint256	public	deathData_f8					;		/*	8	*/															
		uint256	public	deathData_f9					;		/*	9	*/															
		uint256	public	deathData_f10					;		/*	10	*/															
		uint256	public	deathData_f11					;		/*	11	*/															
		uint256	public	deathData_f12					;		/*	12	*/															
		uint256	public	deathData_f13					;		/*	13	*/															
		uint256	public	deathData_f14					;		/*	14	*/															
		uint256	public	deathData_f15					;		/*	15	*/															
		uint256	public	deathData_f16					;		/*	16	*/															
		uint256	public	deathData_f17					;		/*	17	*/															
		uint256	public	deathData_f18					;		/*	18	*/															
		uint256	public	deathData_f19					;		/*	19	*/															
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
		// part.II_variable.../.../.../.../.../																										
//																												
//		uint256	public	deathFactor_i					;		/*	i	*/															
//		uint256	public	deathFactor_ii					;		/*	ii	*/															
//		uint256	public	deathFactor_iii					;		/*	iii	*/															
//		uint256	public	deathFactor_iv					;		/*	iv	*/															
//		uint256	public	deathFactor_v					;		/*	v	*/															
//		uint256	public	lifeFactor_i					;		/*	i	*/															
//		uint256	public	lifeFactor_ii					;		/*	ii	*/															
//		uint256	public	lifeFactor_iii					;		/*	iii	*/															
//		uint256	public	lifeFactor_iv					;		/*	iv	*/															
//		uint256	public	lifeFactor_v					;		/*	v	*/															
		uint256	public	lastBlock_v0					;		/*	0	*/															
		uint256	public	lastBlock_v1					;		/*	1	*/															
		uint256	public	lastBlock_v2					;		/*	2	*/															
		uint256	public	lastBlock_v3					;		/*	3	*/															
		uint256	public	lastBlock_v4					;		/*	4	*/															
		uint256	public	lastBlock_v5					;		/*	5	*/															
		uint256	public	lastBlock_v6					;		/*	6	*/															
		uint256	public	lastBlock_v7					;		/*	7	*/															
		uint256	public	lastBlock_v8					;		/*	8	*/															
		uint256	public	lastBlock_v9					;		/*	9	*/															
		uint256	public	lastBlock_v10					;		/*	10	*/															
		uint256	public	lastBlock_v11					;		/*	11	*/															
		uint256	public	lastBlock_v12					;		/*	12	*/															
		uint256	public	lastBlock_v13					;		/*	13	*/															
		uint256	public	lastBlock_v14					;		/*	14	*/															
		uint256	public	lastBlock_v15					;		/*	15	*/															
		uint256	public	lastBlock_v16					;		/*	16	*/															
		uint256	public	lastBlock_v17					;		/*	17	*/															
		uint256	public	lastBlock_v18					;		/*	18	*/															
		uint256	public	lastBlock_v19					;		/*	19	*/															
		uint256	public	lastBlock_v0Hash_uint256					;		/*	0	*/															
		uint256	public	lastBlock_v1Hash_uint256					;		/*	1	*/															
		uint256	public	lastBlock_v2Hash_uint256					;		/*	2	*/															
		uint256	public	lastBlock_v3Hash_uint256					;		/*	3	*/															
		uint256	public	lastBlock_v4Hash_uint256					;		/*	4	*/															
		uint256	public	lastBlock_v5Hash_uint256					;		/*	5	*/															
		uint256	public	lastBlock_v6Hash_uint256					;		/*	6	*/															
		uint256	public	lastBlock_v7Hash_uint256					;		/*	7	*/															
		uint256	public	lastBlock_v8Hash_uint256					;		/*	8	*/															
		uint256	public	lastBlock_v9Hash_uint256					;		/*	9	*/															
		uint256	public	lastBlock_v10Hash_uint256					;		/*	10	*/															
		uint256	public	lastBlock_v11Hash_uint256					;		/*	11	*/															
		uint256	public	lastBlock_v12Hash_uint256					;		/*	12	*/															
		uint256	public	lastBlock_v13Hash_uint256					;		/*	13	*/															
		uint256	public	lastBlock_v14Hash_uint256					;		/*	14	*/															
		uint256	public	lastBlock_v15Hash_uint256					;		/*	15	*/															
		uint256	public	lastBlock_v16Hash_uint256					;		/*	16	*/															
		uint256	public	lastBlock_v17Hash_uint256					;		/*	17	*/															
		uint256	public	lastBlock_v18Hash_uint256					;		/*	18	*/															
		uint256	public	lastBlock_v19Hash_uint256					;		/*	19	*/															
		uint256	public	deathData_v0					;		/*	0	*/															
		uint256	public	deathData_v1					;		/*	1	*/															
		uint256	public	deathData_v2					;		/*	2	*/															
		uint256	public	deathData_v3					;		/*	3	*/															
		uint256	public	deathData_v4					;		/*	4	*/															
		uint256	public	deathData_v5					;		/*	5	*/															
		uint256	public	deathData_v6					;		/*	6	*/															
		uint256	public	deathData_v7					;		/*	7	*/															
		uint256	public	deathData_v8					;		/*	8	*/															
		uint256	public	deathData_v9					;		/*	9	*/															
		uint256	public	deathData_v10					;		/*	10	*/															
		uint256	public	deathData_v11					;		/*	11	*/															
		uint256	public	deathData_v12					;		/*	12	*/															
		uint256	public	deathData_v13					;		/*	13	*/															
		uint256	public	deathData_v14					;		/*	14	*/															
		uint256	public	deathData_v15					;		/*	15	*/															
		uint256	public	deathData_v16					;		/*	16	*/															
		uint256	public	deathData_v17					;		/*	17	*/															
		uint256	public	deathData_v18					;		/*	18	*/															
		uint256	public	deathData_v19					;		/*	19	*/															
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
		// part.III_active.../.../.../.../.../																										
//																												
//		uint256	public	deathFactor_i					;		/*	i	*/															
//		uint256	public	deathFactor_ii					;		/*	ii	*/															
//		uint256	public	deathFactor_iii					;		/*	iii	*/															
//		uint256	public	deathFactor_iv					;		/*	iv	*/															
//		uint256	public	deathFactor_v					;		/*	v	*/															
//		uint256	public	lifeFactor_i					;		/*	i	*/															
//		uint256	public	lifeFactor_ii					;		/*	ii	*/															
//		uint256	public	lifeFactor_iii					;		/*	iii	*/															
//		uint256	public	lifeFactor_iv					;		/*	iv	*/															
//		uint256	public	lifeFactor_v					;		/*	v	*/															
		uint256	public	lastBlock_a0					;		/*	0	*/															
		uint256	public	lastBlock_a1					;		/*	1	*/															
		uint256	public	lastBlock_a2					;		/*	2	*/															
		uint256	public	lastBlock_a3					;		/*	3	*/															
		uint256	public	lastBlock_a4					;		/*	4	*/															
		uint256	public	lastBlock_a5					;		/*	5	*/															
		uint256	public	lastBlock_a6					;		/*	6	*/															
		uint256	public	lastBlock_a7					;		/*	7	*/															
		uint256	public	lastBlock_a8					;		/*	8	*/															
		uint256	public	lastBlock_a9					;		/*	9	*/															
		uint256	public	lastBlock_a10					;		/*	10	*/															
		uint256	public	lastBlock_a11					;		/*	11	*/															
		uint256	public	lastBlock_a12					;		/*	12	*/															
		uint256	public	lastBlock_a13					;		/*	13	*/															
		uint256	public	lastBlock_a14					;		/*	14	*/															
		uint256	public	lastBlock_a15					;		/*	15	*/															
		uint256	public	lastBlock_a16					;		/*	16	*/															
		uint256	public	lastBlock_a17					;		/*	17	*/															
		uint256	public	lastBlock_a18					;		/*	18	*/															
		uint256	public	lastBlock_a19					;		/*	19	*/															
		uint256	public	lastBlock_a0Hash_uint256					;		/*	0	*/															
		uint256	public	lastBlock_a1Hash_uint256					;		/*	1	*/															
		uint256	public	lastBlock_a2Hash_uint256					;		/*	2	*/															
		uint256	public	lastBlock_a3Hash_uint256					;		/*	3	*/															
		uint256	public	lastBlock_a4Hash_uint256					;		/*	4	*/															
		uint256	public	lastBlock_a5Hash_uint256					;		/*	5	*/															
		uint256	public	lastBlock_a6Hash_uint256					;		/*	6	*/															
		uint256	public	lastBlock_a7Hash_uint256					;		/*	7	*/															
		uint256	public	lastBlock_a8Hash_uint256					;		/*	8	*/															
		uint256	public	lastBlock_a9Hash_uint256					;		/*	9	*/															
		uint256	public	lastBlock_a10Hash_uint256					;		/*	10	*/															
		uint256	public	lastBlock_a11Hash_uint256					;		/*	11	*/															
		uint256	public	lastBlock_a12Hash_uint256					;		/*	12	*/															
		uint256	public	lastBlock_a13Hash_uint256					;		/*	13	*/															
		uint256	public	lastBlock_a14Hash_uint256					;		/*	14	*/															
		uint256	public	lastBlock_a15Hash_uint256					;		/*	15	*/															
		uint256	public	lastBlock_a16Hash_uint256					;		/*	16	*/															
		uint256	public	lastBlock_a17Hash_uint256					;		/*	17	*/															
		uint256	public	lastBlock_a18Hash_uint256					;		/*	18	*/															
		uint256	public	lastBlock_a19Hash_uint256					;		/*	19	*/															
		uint256	public	deathData_a0					;		/*	0	*/															
		uint256	public	deathData_a1					;		/*	1	*/															
		uint256	public	deathData_a2					;		/*	2	*/															
		uint256	public	deathData_a3					;		/*	3	*/															
		uint256	public	deathData_a4					;		/*	4	*/															
		uint256	public	deathData_a5					;		/*	5	*/															
		uint256	public	deathData_a6					;		/*	6	*/															
		uint256	public	deathData_a7					;		/*	7	*/															
		uint256	public	deathData_a8					;		/*	8	*/															
		uint256	public	deathData_a9					;		/*	9	*/															
		uint256	public	deathData_a10					;		/*	10	*/															
		uint256	public	deathData_a11					;		/*	11	*/															
		uint256	public	deathData_a12					;		/*	12	*/															
		uint256	public	deathData_a13					;		/*	13	*/															
		uint256	public	deathData_a14					;		/*	14	*/															
		uint256	public	deathData_a15					;		/*	15	*/															
		uint256	public	deathData_a16					;		/*	16	*/															
		uint256	public	deathData_a17					;		/*	17	*/															
		uint256	public	deathData_a18					;		/*	18	*/															
		uint256	public	deathData_a19					;		/*	19	*/															
//																												
//																												
//																												
//																												
//																												
//																												
		function	LifeSet_006		() 	public	{																					
			deathFactor_i					=	57896044618658097711785492504343953926634992332820282019728792003956564819968																;	/*	i	*/
			deathFactor_ii					=	40000178836041700000000000000																;	/*	ii	*/
			deathFactor_iii					=	60546676427403100000000000000																;	/*	iii	*/
			deathFactor_iv					=	43362577589695700000000000000																;	/*	iv	*/
			deathFactor_v					=	88960652252000600000000000000																;	/*	v	*/
			lifeFactor_i					=	80101181956101000000000000000																;	/*	i	*/
			lifeFactor_ii					=	46625760121298700000000000000																;	/*	ii	*/
			lifeFactor_iii					=	91732772130849400000000000000																;	/*	iii	*/
			lifeFactor_iv					=	29996282331272100000000000000																;	/*	iv	*/
			lifeFactor_v					=	66979570169647300000000000000																;	/*	v	*/
			lastBlock_f0					=	(block.number)										;							/*	0	*/
			lastBlock_f1					=	(block.number-1)										;							/*	1	*/
			lastBlock_f2					=	(block.number-2)										;							/*	2	*/
			lastBlock_f3					=	(block.number-3)										;							/*	3	*/
			lastBlock_f4					=	(block.number-4)										;							/*	4	*/
			lastBlock_f5					=	(block.number-5)										;							/*	5	*/
			lastBlock_f6					=	(block.number-6)										;							/*	6	*/
			lastBlock_f7					=	(block.number-7)										;							/*	7	*/
			lastBlock_f8					=	(block.number-8)										;							/*	8	*/
			lastBlock_f9					=	(block.number-9)										;							/*	9	*/
			lastBlock_f10					=	(block.number-10)										;							/*	10	*/
			lastBlock_f11					=	(block.number-11)										;							/*	11	*/
			lastBlock_f12					=	(block.number-12)										;							/*	12	*/
			lastBlock_f13					=	(block.number-13)										;							/*	13	*/
			lastBlock_f14					=	(block.number-14)										;							/*	14	*/
			lastBlock_f15					=	(block.number-15)										;							/*	15	*/
			lastBlock_f16					=	(block.number-16)										;							/*	16	*/
			lastBlock_f17					=	(block.number-17)										;							/*	17	*/
			lastBlock_f18					=	(block.number-18)										;							/*	18	*/
			lastBlock_f19					=	(block.number-19)										;							/*	19	*/
			lastBlock_f0Hash_uint256					=	uint256(block.blockhash(block.number))										;							/*	0	*/
			lastBlock_f1Hash_uint256					=	uint256(block.blockhash(block.number-1))										;							/*	1	*/
			lastBlock_f2Hash_uint256					=	uint256(block.blockhash(block.number-2))										;							/*	2	*/
			lastBlock_f3Hash_uint256					=	uint256(block.blockhash(block.number-3))										;							/*	3	*/
			lastBlock_f4Hash_uint256					=	uint256(block.blockhash(block.number-4))										;							/*	4	*/
			lastBlock_f5Hash_uint256					=	uint256(block.blockhash(block.number-5))										;							/*	5	*/
			lastBlock_f6Hash_uint256					=	uint256(block.blockhash(block.number-6))										;							/*	6	*/
			lastBlock_f7Hash_uint256					=	uint256(block.blockhash(block.number-7))										;							/*	7	*/
			lastBlock_f8Hash_uint256					=	uint256(block.blockhash(block.number-8))										;							/*	8	*/
			lastBlock_f9Hash_uint256					=	uint256(block.blockhash(block.number-9))										;							/*	9	*/
			lastBlock_f10Hash_uint256					=	uint256(block.blockhash(block.number-10))										;							/*	10	*/
			lastBlock_f11Hash_uint256					=	uint256(block.blockhash(block.number-11))										;							/*	11	*/
			lastBlock_f12Hash_uint256					=	uint256(block.blockhash(block.number-12))										;							/*	12	*/
			lastBlock_f13Hash_uint256					=	uint256(block.blockhash(block.number-13))										;							/*	13	*/
			lastBlock_f14Hash_uint256					=	uint256(block.blockhash(block.number-14))										;							/*	14	*/
			lastBlock_f15Hash_uint256					=	uint256(block.blockhash(block.number-15))										;							/*	15	*/
			lastBlock_f16Hash_uint256					=	uint256(block.blockhash(block.number-16))										;							/*	16	*/
			lastBlock_f17Hash_uint256					=	uint256(block.blockhash(block.number-17))										;							/*	17	*/
			lastBlock_f18Hash_uint256					=	uint256(block.blockhash(block.number-18))										;							/*	18	*/
			lastBlock_f19Hash_uint256					=	uint256(block.blockhash(block.number-19))										;							/*	19	*/
			deathData_f0					=	uint256(block.blockhash(block.number)) / deathFactor_i										;							/*	0	*/
			deathData_f1					=	uint256(block.blockhash(block.number-1)) / deathFactor_i										;							/*	1	*/
			deathData_f2					=	uint256(block.blockhash(block.number-2)) / deathFactor_i										;							/*	2	*/
			deathData_f3					=	uint256(block.blockhash(block.number-3)) / deathFactor_i										;							/*	3	*/
			deathData_f4					=	uint256(block.blockhash(block.number-4)) / deathFactor_i										;							/*	4	*/
			deathData_f5					=	uint256(block.blockhash(block.number-5)) / deathFactor_i										;							/*	5	*/
			deathData_f6					=	uint256(block.blockhash(block.number-6)) / deathFactor_i										;							/*	6	*/
			deathData_f7					=	uint256(block.blockhash(block.number-7)) / deathFactor_i										;							/*	7	*/
			deathData_f8					=	uint256(block.blockhash(block.number-8)) / deathFactor_i										;							/*	8	*/
			deathData_f9					=	uint256(block.blockhash(block.number-9)) / deathFactor_i										;							/*	9	*/
			deathData_f10					=	uint256(block.blockhash(block.number-10)) / deathFactor_i										;							/*	10	*/
			deathData_f11					=	uint256(block.blockhash(block.number-11)) / deathFactor_i										;							/*	11	*/
			deathData_f12					=	uint256(block.blockhash(block.number-12)) / deathFactor_i										;							/*	12	*/
			deathData_f13					=	uint256(block.blockhash(block.number-13)) / deathFactor_i										;							/*	13	*/
			deathData_f14					=	uint256(block.blockhash(block.number-14)) / deathFactor_i										;							/*	14	*/
			deathData_f15					=	uint256(block.blockhash(block.number-15)) / deathFactor_i										;							/*	15	*/
			deathData_f16					=	uint256(block.blockhash(block.number-16)) / deathFactor_i										;							/*	16	*/
			deathData_f17					=	uint256(block.blockhash(block.number-17)) / deathFactor_i										;							/*	17	*/
			deathData_f18					=	uint256(block.blockhash(block.number-18)) / deathFactor_i										;							/*	18	*/
			deathData_f19					=	uint256(block.blockhash(block.number-19)) / deathFactor_i										;							/*	19	*/
//																												
//																												
		}	
	}