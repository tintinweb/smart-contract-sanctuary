/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-02-04
*/

pragma solidity ^0.4.17;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

/**
ERC Token Standard #20 Interface
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
*/
contract IERC20 {
    function totalSupply() public constant returns (uint256);

    function balanceOf(address tokenOwner)
        public
        constant
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        constant
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

/**
Contract function to receive approval and execute function in one call
Borrowed from MiniMeToken
*/
contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes data
    ) public;
}

/**
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract SEINToken is IERC20, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
// ------------------------------------------------------------------------ 
////For Mobile view low dot art. You can see mobile browser when you sellect as view normal website  
//
//                                                                     vU       
//                                                                   .BBu       
//                                                                  rBQB        
//                                                                 iBggB        
//                                                                 BgEZB        
//                                       ...::i:iiiii::..         KBEPZB.       
//                                 .:iiririiii:i:i:i:i:iirii::    QQPbbBK       
//                             .:iriiii::::::::::.......::::iiri. QgdPdBB       
//                         .:iiiii::::::::::::::..:rvvri...:::::::MBbEDBL       
//                      .:rii::::::::::::::::::.rqRgMggMd7..:::::.7QBRBr        
//                   .:rii:::::i:i:i::::::::::.YRDbdPbPdZQ1.::::::  7Iv         
//                 .iii:::::::::....:::::::::.:QgPPKPqPqbdQi.:::i.  rLv:i       
//               .ir:i::::::::.........::::::.iQEPqPqPKqPEMv.:::.  .uJ7.:r      
//              :ii:::::::::............:::::..PMdbqPqPPEDM..:::.. i2sv.:ii     
//            .ri:::::::::::.............:::::..SRDDEZdgMb:.:::i::.u1Is.:ii     
//           :r:::::::::::::............:::::::..iuqdbPur..::::v7ivq5PY.:i:     
//         .ii:::::::::::::i............::::::::.. ......::::.iKsvIEPM:.:r      
//        .ri::::.:.::::::::i:.........::::::::::::::.:::::::.vP5UgDQP.:r       
//       :ii::.::rii::.::::::i::.....::::::::::::::::::::::::.1SJ2EDB7.i        
//      :r::::vsjsJYJYr.::::::::i:i:i:::::::::::::::::::::::::qUJSgDR::         
//     .i::::jsY7v7v7Ysv::::::::::::::::::::::::::::::::::::.rq1sdEBS.          
//    .i:::.Lsv7v777v7LJr.::::::::::::::::::::::::::::::::::.LqJ2ZgQ:           
//    ii::::YY7v7v7v7v7Jr:::::::::::::::::::::::::::::::::::.X5JXDQE            
//   :r::::.rJL7v7v7v7Ysi::::::::::::::::::::::::::::::::::.:qUsdEB:            
//   r::::::.rYJYYvYYuvi.::::::::::::::::::::::::::::::::::.rPJ2ZRQ             
//  .i:::::::.:i77L77i:.:::::::::::::::::::::::::::::::::::.U5jSDQX             
//  ii::::::::.....:.:::::::::::::::::::::::::::::::::::::.:S2sEEBr.::....      
//  r::::::::......::::::::::::::::::::::::::::::::::::::::idj2ZRD..:iiiiiiiri. 
//  i:::::....:::...:::::::::::::::::::::::::::::::::::ii. ibuXgBU.::::::::i:ir 
//  r::::..vdgQRQDX:..:::::::::::::::::::::::::::::::::i   UqsEgB .::::::::::ir 
//  ii::.:ZBgDbZEgRBs..:::::::::::::::::::::::::::::::::   D12DB5 .i:::::::::7. 
//  ii:..bBddPPqbqdDBr.:::::::::::::::::::::::::::::::i:  :D1KMB. ::::::::::7i  
//  .r::.BDdKPKPPPPEBI.::::::::::::::::::::::::::::::::i. YRSQBQ .:::::::::r7   
//   ii..PBbbPPqPPbZBr.:::::::::::::::::::::::::::::::::i.7s2bbr.:::::::::77    
//   .i:.:ZBgDdEdgRBs..:::.:.:::::::::::::::::::::::::::::......:::::::::Yr     
//    ii:..7bMQRQDS:..:.........:::::::::.:::::.:.:::::::::::::::::::::iu:      
//     i::....:::......:LXqbq5v:.:::::::.r7LLsLvr:.:::::::::::::::::::vL        
//      r::::.....:::.jZZPPKPPgEv.::::::vJYvv7vvjsr.::::::::::::::::7Y:         
//       ii:::::::::.sMq55I5ISSPg7.:::.vsv777v7v7LJi::::::::::::::rsi           
//        iii:::::::.PE55I5I52SSDI.::::LL777777777jr::::::::::::7vi             
//         .ii::::::.XZXI5I5I5IKgs.:::.vsv7v777v7vJi.::::::::irv:               
//           :rii:::.:dEPSK5XXPZK..:::::LsY7v7vvssr.:::::..:7r.                 
//             iri:::..JqZZZEDqv..::::::.r7YYsYY7:.::::..:rP.                   
//              .:77r:...:rri:..:::::::::.:::::...::iiii7XBM                    
//                 .i777i:.....:.:::::::::.::::ir7vvi..bSQB:                    
//                     .:rvvYvL7777rrr77v7vvLv7i:.    iPXQB                     
//                           ..::iii:i::...           IXPBs                     
//                                                    Z2MB.                     
//                                                   :bXBg                      
//                                                   LPPBi                      
//                                                   PIQB          .Qi    .J    
//                                                  .ZqBK           XQB  PB1    
//                                                  :ggB              PBBJ      
//                                                  .QBr              KBMBu     
//                                                   rr              BB   QB7   
//                                                                   i      r   
//                                                                   
//                                                                   
// This part of art creation is just available view on desktop "Full Hd Resolution"
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------
//                                                                                                                                                                        
//                                                                                                                                                     sBB                
//                                                                                                                                                   1BBB5                
//                                                                                                                                                 :BQdPB:                
//                                                                                                                                                uBZPXEQ               
//                                                                                                                                               PBPqSqZd                 
//                                                                                                                                              DBqqSKXQ1                 
//                                                                                                                                             DBKK5KXPQ7                 
//                                                                                                                                            XBqKSXSKKBi                 
//                                                                                                                                           7BqK5KSXSPQr                 
//                                                                                                                                           Bdq5XSXSXKQr                 
//                                                                                            ......:.:.:.:......                           KQPXXSKSK5qMU                 
//                                                                                   ..::iiiiiiiii:i:i:i:i:i:iiiiiiiii::..                  BdXX5XSKSXSDE                 
//                                                                            ..::iiiii:::::::::::::::::::::::::::::::iiiiii:..            iBqKXXSK5XSqqB.                
//                                                                       ..:iiii:::::::::::::::::::::::::::::::::::::::::::::iiii:.        1RqXKSX5K5KSqgb                
//                                                                  ..iiiii:::::::::::::::::::::::::::::::::::::::::::::::::::::::iii:.    jRXK5KSKSXSKSZB                
//                                                              .::iii:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::iii:. jMK5KSKSX5XSKPB                
//                                                          ..iii::::::::::::::::::::::::::::::::::::::::::.........::::::::::::::::::::i:.UgKKSKSXSK5XKZB                
//                                                       .:iii::::::::::::::::::::::::::::::::::::::::::.. ..:::::.....:::::::::::::::::::.vMPXKSKSKSKXPB1                
//                                                    ::i:i::::::::::::::::::::::::::::::::::::::::::.. :r1SddDdDdb5ji. ..::::::::::::::::.iQPKSKXXSKXbQD                 
//                                                .:ii::::::::::::::::::::::::::::::::::::::::::::::..:UdEPPKqXqKqqbPEd1:..:::::::::::::::..dBbPXKSqqZBb                  
//                                             .:ii::::::::::::::::::::::::::::::::::::::::::::::::..jDPPXK5XSS5S5XSKXPPDY..:::::::::::::::..uQQgdEdZE:                   
//                                           :ii::::::::::::::::::::::::::::::::::::::::::::::::::.:PdqKSXIXIS5XISISIS5XqES..::::::::::::::.   :jSJL77                    
//                                        .:i::::::::::::::::::::::::::::::::::::::::::::::::::::..PdXXIX5XIS5XISIXISISIXXdX..:::::::::::::     .rri7r::.                 
//                                      .ii::::::::::::::::::::::::::::::::::::::::::::::::::::::.JEXXISISIXIXIS5S5SIX5XIKKZ7.:::::::::::i....  LL77v7.:ii                
//                                    .ii:::::::::::::::::::::i::............:::::::::::::::::::..ZqK5S5S5SIS5S5X5SIS5SIXIKPP..::::::::::. ..  .1777Yr.:::r.              
//                                  .ii:::::::::::::::::::::::.................:::::::::::::::::.:ZqSXIXIXISIX5XIXISIXISIS5PE:.::::::::::. ... rs7r7Lr.::::r.             
//                                .:i::::::::::::::::::::::::....................:i:::::::::::::.:DqX5X5SIX5S5X5SIS5SIS5X5Xqd..:::::::::. . . .LL777Yr.:::::r             
//                               :ii:::::::::::::::::::::::........................:::::::::::::..SbXSIS5S5X5S5X5SIX5S5SISXdU..:::::::::   .  .J77r7vr.:::::::            
//                             .i:::::::::::::::::::::::::..........................:::::::::::::.iEPSSISISIS5S5S5SISISISSbD:.:::::::::::.... rJvr7rsi.::::::i            
//                            :i::::::::::::::::::::::::::..........................:::::::::::::: vZPXX5X5XISISISIX5XIXSbZr.:::::::::.:::::.:1ULsLs1r.::::::i.           
//                          :ii::::::::::::::::::::::::::...........................:::::::::::::.. rZdqKSX5S5S5S5S5X5Kqdbi .:::::::.i:......:UvLvvv1i.::::::i.           
//                         i:::::::::::::::::::::::::::::............................:::::::::::::::.:uDPPqPSK5KSXSqKPbDs. :::::::::.vvi::::.7JLvv7LXr.::::::i            
//                       .i:::::::::::::::::::::::::::::i...........................:::::::::::::::::...vSZddPdPdPZdEI7...:::::::::.:777vvv77SSU21UId:.::::::i            
//                      :i::::::::::::::::::::::::::::::::..........................::::::::::::::::::.....irYsusLri.....::::::::::.i7irrrri7S1U1U1Ks..:::::i:            
//                    .ii:::::::::::::::::::::::::::::::::..........................:::::::::::::::::::::...... ......:::::::::::::.ju7rrrr:sUjsjsUbi.::::::i             
//                   .i::::::::::::::::::::::::::::::::::::........................:::::::::::::::::::::::::.:::.:::::::::::::::::..2512u1YJPPSXIXPZ..:::::i.             
//                  :i::::::::::::::::::::::::::::::::::::::......................:::::::::::::::::::::::::::::::::::::::::::::::..:Kj1jujJUdqPKPPQY..::::i.              
//                 :::::::::::::::::::::::::::::::::::::::::::...................:::::::::::::::::::::::::::::::::::::::::::::::::.75usuYjvXPKXKSbg:.::::i:               
//                i::::::::::::.:.......:.::::::::::::::::::::::..............:::::::::::::::::::::::::::::::::::::::::::::::::::..sIsusJLJqqSKXqZq ::::i:                
//               i::::::::::...:irr777rrii:..:::::::::::::::::::::::.......::i:::::::::::::::::::::::::::::::::::::::::::::::::::..SjusjYL1bXKXKqQr.:::i:                 
//              i::::::::::.:rvvYvL7v7L7LLvri.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.i51sJsJvSPKSKXdE..::i.                  
//             i::::::::..:7LL7777r7r7r7777Lvv:..:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::..vXJJsJLsKPXKSqg1 ::i.                   
//            i:::::::::.iLv7r7r7r7r7r7r7r7r77sr:.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::..21jsJJLubXKSKKR:.:i                     
//           ii::::::::.is77r7r7r7r7r7r7r777r77sr..:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.:SusjYJvXPKXKSDq.::                      
//          :i::::::::::s77r7r7r7r7r7r7r7r7r7r77Yi..::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.rXjjsJLsKPSKSPRY..                       
//         .i:::::::::.7v77777r777r7r7r7r7r7r7r77v.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.J2usJsY1bKKSKPQ:                         
//         i:::::::::.:7vr7r7r7r7r7r7r7r7r7r7r777v:.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.:21sJsJvXPKSKKQS                          
//        ::::::::::::.v77r7r7r7r7r7r7r7r7r7r7r77Y:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.:KJusJLJKPXKXPB.                          
//       .i::::::::::::rL7777r7r7r7r7r777r7r7r77v7:.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.vIususYjbXKXqZD                           
//       i::::::::::::.:Lv77r7r777r7r7r7r7r7r777Lr.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::..u2JjYJLXPqSqqBr                           
//      :::::::::::::::.rL777r77777r777r777r7r7v7.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.:5jJJjYJqPSqXdB                            
//      i:::::::::::::::.rvv77r7r7r7r7r777r777L7.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.r5usuYL1PKKSPRS                            
//     :i::::::::::::::::.i7Yvvr777r777r7777s7r.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::..LIsjJsvXqXXKKB.                            
//     i::::::::::::::::::.::7vLvv777v7LvLv7i:.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::..IuusJLsKqSqXEg                             
//    .i:::::::::::::::::::.:.::rr77v77rri:...:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.:5usjsYuPXqSqg2..                           
//    :i::::::::::::::::::::::.:.....:.....::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.rXJussvXqKSKqQ:.:ii:..                      
//    i::::::::::::::::::::::::::.:::.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.uUjJJLJKqSKXDP..::i:iiiii::.:....           
//    i:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.:I1JJYLubSKXqR7 ::::::::::::i:i:iiiiii:.     
//   .i:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::i:.iqJJJsvXqqSqPg...::::::::::::::::::::i:ii.   
//   :::::::::::::::::::::::.:.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::i:. rXjsJYJqqXKKM2..::::::::::::::::::::::::ii   
//   :i::::::::::::::::...............:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    uSJjsY1PXKSPRi.::::::::::::::::::::::::::i.  
//   :::::::::::::::.....r712XI5jLi:...:.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::i.     dujJsvSPqXqEE.:::::::::::::::::::::::::::i.  
//   :i::::::::::::...7XgggDZdZEggMEK7....:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::i.     :d1JjLsKPSKKB: :::::::::::::::::::::::::::r   
//   .::::::::::::..vDgDPqSKXKXKSqXPdMEL...:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      LPJuYLudXqXEQ  .::::::::::::::::::::::::.ii   
//   .i::::::::::.:qRPqSK5K5XSXSX5X5qXdgP...::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::i.      KUJssvXqKSPQ5   i::::::::::::::::::::::.:v    
//   .i:::::::::..EgKqSKSK5XSKSK5XSKSKXqZD...::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      .d1sjvJKqXqqB.   i:::::::::::::::::::::.:v:    
//    i::::::::..XMXKSXSXSX5X5XSKSXSXSXSqgq.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::i.     idsuYL1dXqXDg    i::::::::::::::::::::::7r     
//    :i:::::::.iQKKSXSX5X5X5X5X5X5XSKSX5Pgi.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::i     25usJLXqKSqBv   :::::::::::::::::::::.:7Y      
//    .i:::::::.sgqSX5XSXSXSXSXSK5XSXSK5KXMY.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::    PIjjLJqPXqPB   .i:::::::::::::::::::.:rj       
//     i::::::..sgSX5K5K5K5KSX5K5X5KSK5KSqgj.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::i:  .D1jsY1dKPKQ5  .i:::::::::::::::::::.:rJ        
//     :i::::::.rMPSX5XSK5X5XSXSX5X5KSXSXqRr.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::ii 7dKI2jdDgZRB: :::::::::::::::::::::.:7J.        
//      i::::::..ZEqSXSXSXSXSX5K5X5XSX5XXDb..:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::rvLuPbSIYr.:::::::::::::::::::::.i7J.         
//      :i:::::..iQPqSX5XSXSX5X5XSXSXSXXEMi.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::...........:::::::::::::::::::::.rLY           
//       i::::::..iMDPXKSXSX5X5X5XSKXqKggr :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.:.:.:.::::::::::::::::::::.:rLv            
//       .r::::::..:XggqPSKXK5KSKSKXPZRS:..::::::::::::.:.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.::vYr             
//        :i::::::.. i2gggdEPPqdPEZMZIi..::::::::::..........:.:::::::::::::::::::::::::::.........:.:::::::::::::::::::::::::::::::::::::::::::::::::.:iYY:              
//         :i::::::.:...rYSqdEDbP5ji. ..:::::::.....::iirii:....:.:::::::::::::::::::::.::iirrrrrii:...::::::::::::::::::::::::::::::::::::::::::::::.irJ7.               
//          i:::::::::............ ..:.:::::::...rY5KPPPPbqP51r:...:::::::::::::::::..:i7LvL7v7LvLvv7r:..:::::::::::::::::::::::::::::::::::::::::..:rvs:                 
//           i:::::::::::.:.......:::::::::::..7qPPSS2IUI2I2SXdqj:..:::::::::::::::.:rvv777r7r7r7r7r7vYr:.:::::::::::::::::::::::::::::::::::::::.:ivL7                   
//           .i::::::::::::::::::::::::::::..rXPIIUUu21U1U1U1215Kd7..:::::::::::::.i7L77r7r7r7r7rrrrr7rvvi.:::::::::::::::::::::::::::::::::::::.irYL:                    
//            .i:::::::::::::::::::::::::::.vPXU212uUuUuU12uUu21I2d1..:::::::::::.iLvr7r7r7r7r7r7rrr7r7r7Lr.:::::::::::::::::::::::::::::::::.::rLJi                      
//             .i:::::::::::::::::::::::::.rdSU2uU1U1U1U1Uu21Uu2u22ds..:::::::::.:v7r7rrr7r7r7r7r7r7r7r7r7Li.:::::::::::::::::::::::::::::::.:ivsr                        
//               ii::::::::::::::::::::::..KK1212u21UuUuUuUuUuUu21UIEi.:::::::::.rYrrrrr7r7r7r7r7r7r7r7r7rv7:::::::::::::::::::::::::::::.::ivJr.                         
//                :i:::::::::::::::::::::.ibUUuU1Uu21UuU1U1U1U121UuIPs.:::::::::.v77rrr7r7r7rrr7r7r7r7r7r7rL:.::::::::::::::::::::::::::.:iLsr                            
//                 .i::::::::::::::::::::.7PIuU1UuU1UuU12uU1U1UuU1UUqu.::::::::.:7vr7r7r7r7r7r7r7r7r7r7r7r7v:.::::::::::::::::::::::::::rvji.                             
//                  .i:::::::::::::::::::.idUUuUuUuUuUu21UuUuU1Uu212qs.:::::::::.7v7rrr7r7r7r7r7r7rrr7r7r77v.:::::::::::::::::::::::.:rYsi                                
//                    :i:::::::::::::::::..KKUUuU1U1U121UuUuUuUuU122Ei.:::::::::.:Yr7r7r7r7r7r7r7rrr7r7r7rsi.::::::::::::::::::::.::rYs:                                  
//                     .ii::::::::::::::::.rd5UU12121UuU1UuU1UuU1UUbj..:::::::::..rY77r7r7r7rrr7r7r7rrr7rL7:.:::::::::::::::::.::i7J7.                                    
//                       .ii:::::::::::::::.LbS1U121U1U1U1U12u212IdU..:::::::::::..rs77r7r7r7r7r7rrr7r7rs7:.:::::::::::::::...:rYYr                                       
//                         :ii:::::::::::::..rPb5I1U12uUuUu21215KdL..:::::::::::::..ivv7r7r7r7r7r7r777vYi:.:::::::::::::...::irr.                                         
//                           :r:::::::::::::..:LPPqS5UIU2UIISXPqU:..:::::::::::::::...i7LLv7v777v7vvY7r:..:::::::::::...::::iU1                                           
//                             irr::.:.:::::::...rJKqbPPPPPPXU7:...:::::::::::::::::::.::ir77v7v77rr::.:::::::::::...::i:irUEB:                                           
//                               :777i:::.:::::.....:irrrii:....:::::::::::::::::::::::.:...:.:::...:.:::::::...::::iiiivPgDQg                                            
//                                 .iLLvri::...:.:.............:::::::::::::::::::::::::::::.:.:.:::::::.:.:::ir7Y7rrvsjXDKPBv                                            
//                                    .:7Ys77ii::.:...:.:::.:::::::::::::::::::::::::::::::::::.:.:...::::rrvYJvr. sXUusPKqbB                                             
//                                        .i7ssY77ii:i::.:...:.:.:::::.:::::::::::::::::.:.:...::::iir7vLJY7i:     PUjLuqqXR5                                             
//                                            .:r7sssvv77rrii:i::::.:.:.:.:.:.:.:.:.:.:.::::iirrvvsYsL7i:.        :P1sL2PXbQ:                                             
//                                                 .:r7vvsLsvL7v77rrrrrrrririririrrrr77vvYLJsJvvri..              uXsJvPKqER                                              
//                                                        .:iir7v7LvsLYLsYsYsLJvsLsvv77ri::.                      d1JvJqqKBY                                              
//                                                                     . ... .                                   :b1sL1bXbB.                                              
//                                                                                                               vqssvqqPDd                                               
//                                                                                                               K2uL1qPqBi                                               
//                                                                                                               PUsYUPXEQ                                                
//                                                                                                              idjsvqKPQ1                                                
//                                                                                                              1XjLuPPqB.                                                
//                                                                                                              q2JY2bKgZ                                                 
//                                                                                                             .djsLPKPBr                                                 
//                                                                                                             vqjvjqPPB                       dP.               .        
//                                                                                                             5SsL2bKQ5                       IBBBi         iRBBi        
//                                                                                                            .EjJLqqPB:                        rBQBQ      7BBBd.         
//                                                                                                            rPuvuPPDQ                           PBBBJ  .QBBS.           
//                                                                                                            7PJv2PPBr                            .QBQBSBBU              
//                                                                                                            7PjYPPQP                                BQBQJ               
//                                                                                                            :Es1bMB                                LgBBBQQ              
//                                                                                                             dIKQB:                              .BQBv .BQBg            
//                                                                                                             vgBB:                              :BBBr    iBBBP          
//                                                                                                             .                               iBBB:       :BBBL        
//                                                                                                                                              .BBg           :BBP       
//                                                                                                                                              .::               i       
//
//-----------------------------------------------------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "SEIN";
        name = "SEIN";
        decimals = 18;
        _totalSupply =12345689* (uint256(10) ** decimals);
        balances[0x7777777777777777777777777777777777777777] = _totalSupply;
        emit Transfer(
            address(0xfdB23348d36B38b56899Aaec1578F043A1641Fa7),
           0xfdB23348d36B38b56899Aaec1578F043A1641Fa7,
            _totalSupply
        );
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(
        address spender,
        uint256 tokens,
        bytes data
    ) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            tokens,
            this,
            data
        );
        return true;
    }

    // ------------------------------------------------------------------------
    // accept ETH
    // ------------------------------------------------------------------------
    function() public payable {
        revert();
    }
}