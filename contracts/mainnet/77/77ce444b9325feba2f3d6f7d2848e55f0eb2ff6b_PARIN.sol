// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Parin Heidari
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                            (y' ,,,,,,`   .                                                                  //
//                                                                                                     :GGS##################m, `                                                              //
//                                                                                                 .;GQs##########################m, ~                                                         //
//                                                                                               :jS#######@###########################m#p                                                     //
//                                                                                             ;s############@#Nm############################m,                                                //
//                                                                                           /;#############@###@###############################b                                              //
//                                                                                           D############@######################Q##@#############                                             //
//                                                                                          ]####@#####################################Q###########p                                           //
//                                                                                         #######@########################################Q#########                                          //
//                                                                                         #@##@########@################################@[email protected]##Q#@######                                        //
//                                                                                        [email protected]####@#@#####################################@###############b                                      //
//                                                                                      ^ ############################[email protected]##########@@###########@#########b                                     //
//                                                                                       @######################################@########################@b                                    //
//                                                                                      `-"[email protected]#############Q################################################N                                   //
//                                                                                        ,-%#bbGQ#W"777coGo|799bWWWWWWWWWWWW###############@@####Q38#@####@#N,                                //
//                                                                                       ,^  ~|aGGS**********^                   7J5#####WW##@@######7>wJ29Qb##Q                               //
//                                                                                       0"""""bGGC***                       ^     \@##@#@sQ*4=eJ,4"(**I%`^^` |   -                            //
//                                                                                       j  .  pC**ooGGG                       ^     V7####p    , *%#\   p~  *j|  ~j                           //
//                                                                                      fj^ 'ppMp**C**^                              ^ |@NQ#acj ' '[email protected] '.\;^32b | #                           //
//                                                                                     ] 8   pb0*p*                      ,.s<y<,       [email protected]#bl`[j   [email protected]#  ^.. *.j|*y#p                          //
//                                                                                     ! b   b~b)Qp ..             ,sQ##2M"7||||\       [email protected]##QbGp b  **p`     ' j} S##N                         //
//                                                                                     Mj    b #*@TGWGNwspy       1#kC,,[email protected]`  ^  !|[email protected]##NNbO9GG*9"    ^   [email protected]@##b                        //
//                                                                                     T[    @ b^^@&psW*WW-,v        Cjj,I.<.;#^ ^  ' .c}|##@bQ#*^`?.o         j*C#####b                       //
//                                                                                    !|b   ,  [  |Ck.`..>C>|p    t;.7mmQs##b|      [o**^[email protected]@###   *C*        :|[email protected]####b[                      //
//                                                                                    [Sp/  .,.b    "###bW4  b    [email protected]|^.`||        .GGGo:$'8#Qb    [email protected]       :^G)@###@##j                      //
//                                                                                    [d    ?CGb9   .        b    @j!G            ,GGCC}b. %@b~    '[email protected]      :**,@####@##D!                     //
//                                                                                    f j    G?bC9   \       |    ^pQGo          ;CGOC/^ ^  !/        c    :**.]###[email protected]####~                     //
//                                                                                   ,  `    'CGCG}   `      @     |**|YG       fCG'Gf` '/ . j        ^,  .** ##@##[email protected]#@NTL                     //
//                                                                                  /  j      **CCG     \    @p       z|      :f*^ .` ! '`/`!/         b  o*j#######%[email protected]#~                     //
//                                                                                       jV.  '**.   s###QN   `"~-eb          :^  *  // ^[  !~         \ .Go#G#####b ,*^C                      //
//                                                                              ,        ^*G77bp'  ,#######Np      l  ,   ,s^^| *`  /.   b  !p          \'?Q7*^";[email protected]#                      //
//                                                                             .          :*.s"    @#@#@####@Np'@##s#87NJQ#b       * L  \b   '.-         ^JLb ^[/ /lGbGGG$`~.                  //
//                                                                            /          *^$f  ,,  @##Q##@Q##@#N 75#pNjS>"`      .  ^Cb        \          ?b*^  ;s#G9bGGG# ,,  ,`              //
//                                                                           '         .oyb",S#GGG##[email protected]$##b *"`|.^`     ;  (*` b         |          jp^,#GGGSbQ#8GGpG#M  '\             //
//                                                                         /          :*/Z`#GGGGSS#S##QGQbQ#  /f[b\   !.p    ,,~7|    b       sGp         .-^lb8SGGGGGGGGG#GGb   }             //
//                                                                       ,           :*Zb;#G#lG#bGG$Q###@##[email protected]`|[email protected]:  `"^``J-^,>^    /j .| ( .#G#S    .<hspN#GGGSG8p#GGGGZ#GGGGG# ^             //
//                                                              QQs~`  ,^           :*j\#GGbQ#QQ#[email protected]##[email protected]#GG~*jbo**  ^ ,,@^|      | |  :;.)Q#bQQ,@N#####[email protected]# }            //
//                                                             #b8Gbp#@###ws,,,,    G;Z#GG#Q#[email protected]#Q8#@##Q#@G# *@***    Gjoj.       |-ppb?,.GQs#l###Q#####GGGGGGGGGG8pG9$GGGGGGGGGb!            //
//                                                             #S##G#8#S##[email protected]#$##@###GGGGSGQ#@SGNG$S###@bGbb.*#Go*,,|`?WpG8   ,.,a#bC* ^;#8S######Q####[email protected]#GbGGGGGGGQ~u           //
//                                                          V ][email protected]###S$########N#@[email protected]$#QG##@bGbS+jIC*      GSC*GZpsGCGG^  Q;[email protected]#@#Q#@G######pGGSGGGGGGGG8pG#GGGGGGZG '           //
//                                                            T8SGGGGGG#[email protected]########$#[email protected]##[email protected]@#G#b#@#GbS*{G*C       |GGGGy^GG^  *L{[email protected]#Q#b########QSSGSGGGGGGGG8QGGGSGG#GGb [          //
//                                                          /,#GSG$GGGGGG##########QG#GQ#bSSQQQGG#G##[email protected]##G8SjbG*           'fb     j {[email protected]########Q##GGGGSb$GSG$GGG8NGGG#GGGG !          //
//                                                        /h~^GSGGGGGGGGGWQ#######@#bSQ9NGQGSQQQ######G8#QbGb$GCC           Oj      [email protected]########Q#Q##QSG$p####GGGGGG8##GGGGG j          //
//                                                      ib"I#GQ#GGGGGGS####QQ##$N#[email protected]$QQ#[email protected]#####GG$#8Q#QbGC            `    . [email protected]##########@#GS############GGGGQGGGGG j          //
//                                                    ,[email protected]########[email protected]#G$QGN#SQQ#Q$b#####GSGG##8S#G*C                  / #[email protected]#######$#b############8TGGGGGGGQSGGG            //
//                                                   #GGGGGGGG#G#9#G88##8##[email protected]#@[email protected]@b##S##bQG9G###GbCo~                 ).{GGGGGG#$GGGQ###S############TGGGSGGGGGGGGGGbGGS            //
//                                                 ,@GGGGGGGS#GN;##[email protected],QG8$G8GG####@G#@@#GQ#G##G###G#GGG$##[email protected]                  b #[email protected]#@bGGGb#lQ#########$GGGGGGGGGGGGGGGGG#^GGG |          //
//                                                [email protected]####$,#S# #GGQ#[email protected]######@#G####G####[email protected]                  bjGGG$#WG##GGG8G####@##$GQGGGGGSQGGGSSGGGGG#@QbGGGb[          //
//                                               Q#GGGGGGQGS##SQ##b#b#G# #GGG##S##[email protected]#@#@#@@##GS###[email protected]                  @'@Z$GGS###GS#[email protected]##$##GGQQQQGGSGGGGGGSGQG#SbG#GGGGp          //
//                                             ,@bGGGGGGGG###[email protected]#b#G# [email protected]###[email protected]###b#b#[email protected]##GGSGGlGGGb8bC                  '.,[email protected]#GGG8GG#####GGQQQQGQGGGGGQGGQ#G##[email protected]#GGb          //
//                                             4bGGGGGGGG###@Q##GS#$QS {QSb]#####[email protected]#@@bGGGGGGGGSQbGQG#@GG#G8bCo                    #[email protected]@#GbSGGGGG######GSQQ$GQGGGGGSGS#b##[email protected]@GG          //
//                                             $GGGGGGGG###$QG#GGG#GGb,QQb ##Gb#[email protected]@#bSGQGGGQG#b#GG#N#[email protected]|                   {GSGGS##@pGGGGGQ#$G###GSGGQGGQGGGGGG####GGG8GGQ3GGl         //
//                                            ][email protected]##$b##[email protected],#Gb ##@bGb#[email protected]@SGGSGGGG#[email protected]##QS##S#[email protected]                 /.GGGG$Q##@GGGGGGG#@###[email protected]         //
//                                            $GGGG9GG9##$b#bGGQbGQS######QQ$Gb$GG#@@#[email protected]#bS##GbGGGSWGGG                ] #GGGS##@sb#GG#GGG8#N###[email protected]@GGGbpp        //
//                                            bGGGGGG######GS$G$##QS#[email protected]#Q#NbG#GGGy#Q$bbSSGGG8Q###G##[email protected]*               [{GGGG$Q#@GGGGGbGGG##@###GGGGSGGQGGGGG$QQS!GGGSSG8pG8b[        //
//                                           !bGGGGS####G#SQ####SS#####@###@#[email protected]@GGGGGSGG#$b####[email protected]$bGGGo               uSGGGGS#[email protected]@[email protected]@GQSGGGGGGGGQQG'GGGGSGG8GGb|        //
//                                           [email protected]###S#G#bQ##S####Q#S####@QGG#T$GG#G$GQGGG$GQ#@S#Q#  @GGG$WGGGC*        .    [email protected]@N##[email protected],[email protected]#bN#        //
//                                            [email protected]#[email protected]#bSl#G##$#bS$#Qb#[email protected]#b# #[email protected]#b#SbG,,@GQGQ#CGGCG*.      j ^  [email protected]##bGGGGQ##@##bGS8QGb,[email protected]##@@G9        //
//                                            bGSGGQbG##b$######S####Q#Q###bGb #G$#SbGbGGGGGG#@@$###SGGGGGGbb*GCCCC* )    o\* ]Q#[email protected]#bGGS#######@##GGGQ#GGSGGGGQGGG$QQQSGGGG#@#$#Qd        //
//                                            GGGGGGG#@G#Q###[email protected]$#[email protected]#Q#Q##G#`,#G##GGGGbGGGGS##G#####GGGGGGGbbGGCooC^)b   ^CGk @#GQQ#[email protected]#####bG#@###@GGSSGGSGGGGSSGGQQGGGGGG#GQ#8Sb        //
//                                            'C"@GWGGGGQG$G##8Q#@Q#@#SGG#^ [email protected]#[email protected]##b##@#GGGGGGG8`bGGoCOG;b#,   'C*W#G#GGG$#@##G9#######[email protected]@###SGGGSGGSGGQGGQGGQQQGGGG####S#Qbp       //
//                                              '.!GGGbGGGGQQQ#GQGGGGGGW`;#S#$GG8#]GGGGSGGS###G###@GGGG8GG9.!GGCCjG*jjC     `[email protected]#####S#####Sb###@###@@[email protected]##$Q##GQp       //
//                                                 "<38WGGQ#bGGQGQQGGG#QSGGGGGGQ#L#GG$SGGQ###GSb###bGGS$GGSjGGGC;bCGb$  ^    @[email protected]####b#####[email protected]####@##bSSQGGGGGSGGQQGGSQQQGSS#Q#G####8b       //
//                                                      Tjj*"%SSSSSGGbGW*8Qk""|`,#GGGGQGQ###[email protected]###[email protected] [email protected]$#@@######[email protected]#b#S#@##@##QSSQGGGQQQGG#[email protected]#G#S#####b       //
//                                                        `    ^^`              @bGG#GGG###[email protected]##bbGGGGGGbLGGCGGGjbGb      @bG#GGG8##@#####[email protected]@#[email protected]#[email protected]#####QQGGGQQQQGSQQQ#Q#$##b###$#Qb       //
//                                                                              #GG#GQG###[email protected]#b##bbGGGGGGb!GGG*  L /       #bGGSGGG #@####S###bQ###GG`@##@b#Q#QQQGGQSQQG$###$#[email protected]##GG#S        //
//                                                                             jGGG$SG$##bG9###Q##G8GGGGGGbSGG~  !  `      .GbGbGGGb #@#######[email protected]#QbGb @$#[email protected]#@QSGGGQQQQ#[email protected]###7W##bGGQb        //
//                                                                             f"j.SSG###GG#G#Q####[email protected]/!GG   b j       jGb9GGGG  #@#######GG###GG~ SG9GG###S#[email protected]##bb   GS#[email protected]~        //
//                                                                               b$SQ$##[email protected]##@###SQSSSGWb ?GC   b |       @[email protected]@GGGG [email protected]######[email protected]#GGGG #[email protected]$######Q#QS!SGGGGGb  @8#[email protected]         //
//                                                                            { / [email protected]##[email protected]###$###[email protected]@b **o   b |        j8$G$GG #G$GS###SbS##bGGb#[email protected]####Q#N##QSS$###NS#S##8         //
//                                                                            | ~{SQQ$##@b###QQ###b$SQSSSb *C    L b         8$#@GGjQGGG###S9G##@GGG#[email protected]###@##@#8#@Q###Q#####p        //
//                                                                            ~! #[email protected]###bS###@GQQQGGb|:*C    | .         @[email protected]#####$9##bQGS###GG$QSG [email protected]##[email protected]##N###########b        //
//                                                                           . [email protected]####GS##[email protected]!**C    j/         [email protected][email protected]@GQQ####9G### GG####GGbQQ# [email protected]#################b        //
//                                                                           [! #[email protected]#####[email protected]##G$#SGQGQbj***     `         [email protected]#bQ###[email protected]#@b{G####[email protected]~ QGQ8pGQGG$$$bbGGQ####N###        //
//                                                                           `b$GQQQ####Q##bQ#b#G$bSGQGQ~ b*                !##SGGQGG9S##G9G###[email protected]####bGG$QQS  GGQS8GGGG$GGGQGS#####j###        //
//                                                                          {].QSGG########[email protected]#[email protected] :b*                [email protected]#@Gb#####GQGbQQb  GGQQG8GGG$GGQ8#8#S###j###b       //
//                                                                          L~#[email protected]########[email protected]@#[email protected]# (b*           ^    {GGGGSGGG8 @GGb###G#####[email protected] [email protected]$GGSQGQG'##b####|       //
//                                                                          b$GGQQ#####S###S#@#GG#QGGGGb @**                @GGGGQGGG8.GGGN##[email protected]#####GGG$GGGp  GGQGGGGbGSGGlQQGN #######j       //
//                                                                         /pQGQQGGS##[email protected]##[email protected]#@[email protected] b*                 GGGGGGGGGS#[email protected]###S#####GGGGbGGGb jGGSGGGGG8pGGGQQGGbQ###G$#@       //
//                                                                         [email protected]##[email protected]##G##8# @bSG$GGbj.*                ] GGGGGGGG$SGG$#S#######[email protected] [email protected]#[email protected]$#@G      //
//                                                                         #GGQbQQG##b#@##$##b` @GQG$GGb|**               .` GGGGGGGGGQGS#Q####@##[email protected] @[email protected];}    //
//                                                                        @GGQ#%[email protected]##NG###@##^  $QGGGGGb8**          ^    b  [email protected]@S###b####[email protected]^GGb GGQGGGGGGGGQQG8pQGGGbGGGN#8bLC    //
//                                                                       !8GbO ][email protected]##@G#####b  !QQGGGGG~b*^              .   GGGQGGS8pG#####b {@#SGG |   SGb!GGQGGGGGGGjQQGSGQGSG QGGGbYWb     //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
//                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PARIN is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
            abi.encodeWithSignature("initialize()")
        );
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}