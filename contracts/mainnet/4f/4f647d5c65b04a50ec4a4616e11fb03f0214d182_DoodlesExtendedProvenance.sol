/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                      +
+                                                                                                                      +
.                                                                                                                      .
.                                                    ####-                                                             .
.                                        :*##:   .###-...:##                                                           .
.                                        +#.:# :#+:........+#####+                                                     .
.                                       .:#..#*=.................:#.                                                   .
.                                     .#..*:.........:.........=-.-#                                                   .
.                                      :+#-....:+**+^^+***__=**#:.*#                                                   .
.                                      .#:.....:#              ^#.#                                                    .
.                                      #:....-#^                 #                                                     .
.                                      #-.....#    ++             +   ++                                               .
.                                      .#.....+   +##+            .* +##+                                              .
.                                       #.....#    ++  .######**.  #  ++                                               .
.                                       #*  ^#^       *####--  ##. #                                                   .
.                                      #:  #.         *####--  #*  #                                                   .
.                                      #.   # :.       .###--  -# .+                                                   .
.                                       #.   .#          ###--  # #                                                    .
.                                        ^##^  #       .###--  =# *                                                    .
.                                            #**#.     ###--  -*+**#                                                   .
.                                            #***####**###--  +#****#                                                  .
.                                           .##*********###--  #**##.                                                  .
.                                          #************###--  #*****#                                                 .
.                    ..:..                #*****#*******###--  #**#****###* *###                                       .
.               .####*^^^^*###.          ##*****#******###--  #***#***#  :# #  :#                                      .
.              :*             =#.        #******#*******##--  #***#***#  .# #  .#                 .####.               .
.               ++#   ######.   #-  .*#####*****#*########--  #***#####  .# #  .#   .#######.   #*^   .^#+             .
.                +#   #::::..#   #.#^^      ^#**#^       ^#- #**#^       .# #  .# +#^       ^# #+        #+            .
.                .#   #      #   ##    .##.  .##.   .##.   # *#   .##.   .# #  .##.   -+#+.  # #   :######:            .
.                .#   #     .#   #    #:::#   #.   #:::#   ###   #::::#  .# #  .##  :#####+  #.##     :...             .
.                .#   #    .#.  :#   #   .#  .#   #    #   ##    #^   #  .# #  .##  .^     .##. *#+:.    .#            .
.                .#   #####^    ##   #  :#.  .#   #  .#    ##    #   #.  .# #  .##   .=*######..##+###.   .#           .
.                .#   ..      .###.   ###   .%#.   ###    *#-#    ###     # #  .##*   .      ####   ^     .#           .
.                 #.   ..:-#####* #.      .*#  ##.      .##. :#._     _### ##.  #**#.     .:##. ##.     -##            .
.                  ############*   =########    :########-     +#######^ ### ##### ^######++#^   ^#######+             .
.                    ^*######*^      ^*##*^       ^*##*^         ^*###*^ ^##^ ^###^  ^*####*^      ^*##*^              .
+                                                                                                                      +
+                                                                                                                      +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - ++ - - - - - - - - - - - - - - - - - - - - - - - - - - + + +

This smart contract introduces human readable provenance for Doodles transfers.
Authored by NateAlex & Poopie
*/

interface DoodlesNFT {
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) external;
}

contract DoodlesExtendedProvenance {

    DoodlesNFT private doodlesNFT = DoodlesNFT(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e);

    constructor() {
    }

    event TransferNotes(string provenanceDetails); 

    function gm(address _from, address _to, uint256 _tokenId, string memory _provenanceDetails) public {

        doodlesNFT.safeTransferFrom(_from, _to,  _tokenId, bytes(_provenanceDetails));

        emit TransferNotes(_provenanceDetails);
    }

}