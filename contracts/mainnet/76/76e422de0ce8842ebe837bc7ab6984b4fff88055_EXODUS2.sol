pragma solidity ^0.5.0;

import "./ERC721Full.sol";
import "./strings.sol";
/*

       `-+ooo/:::://+oo` .:+ooo/-       .:oo+-`    `-::://+o+:`     .-ooo+/:::///:.      .:ooo+-`        .:ooo-.   ----:/+s+:`    /ooooooooo/         
         -MM+        -m     /NM+         `y:    `/s/`       .omh/     +MM-      `-odh/`    oMM-            oM/   +y.      `oM/  `ymMNNNNNNNMMm:       
         .MM:         /      .dMy`      /o`    /No            `yMm-   :MM`          /NN/   /MM`            /M-  sM`         s-     `       hMMo       
         .MM:                  sMm.   `s:     sMy               hMN.  :MM`           -MMo  /MM`            /M-  dM+         .`             hMMo       
         .MM:                   :NN/ /o`     :MM.               .MMh  :MM`            sMM. /MM`            /M-  :NMd+.                     hMMo       
         .MM+::::::/s/           .dMd/       yMN                 mMM  :MM`            :MM+ /MM`            /M-   `+hNMmy+-       ./ssss.sssmMMo       
         .MM:`````.:s:            /dMm.      hMN                 dMM  :MM`            -MM/ :MM`            /M-       -/smMNh/   oMMNmmd/dmmdy+.       
         .MM:                   `s/ :NM+     +MM-                NMy  :MM`            oMN` .MM.            /M`           `+NMd` oMMy                  
         .MM:                  :s`   .dMy`   `mMh               /MN.  :MM`           .NM/   dM+            sy   .          .NM: oMMy                  
         .MM:          -.    `o/       sMm-   .dMs             .Nd.   :MM`          :mm:    -NN.          .d`   y-          NN` oMMy                  
         -MM/         /h    :y`         :NM+    /md:         `+h/     /MM.       .+hh/       .dN+`      `/+`    dN:       `yd-  /MMNdddddddmho`       
       `-oyyy///////+sy- -:sys:.       .:syys:.   .+o+/:---::/.     `-syys//////+/-            -oyysoo++/`      -+ss/:---/+-     `oyyyyyyyyyo`        
                                                                                                                                                      
                                                                                                                                                      
                                                                                                                                                      
       `+   :-  oyyyy/      .yyyyy. `syyyy-  oyyyy:      .yyyyy. `syyyy-      -yyyys` .yyyyy.      :yyyyo  -yyyys`      +yyyy+  /yyyyo  :yyyys`       
       :M   sh .M-..om      +m...ds /N...yh -M-..sd      od...do /N...hy      hy...N/ sd...mo      mo..-M- hs...M:      M/..+M  N+..:M. ds..-M:       
       :M   sh .M`  +m  :N  +d   hs /N   sh -M`  od  /N  oh   do /m   yy  sh  hs   N/ sh   do  hs  m+  `M- ho   M:  m/  M-  :M  N/  .M. do  `M:       
       -mdsdNh .M`  +m   +  +d   hs /N   sh -M`  od   /  oh   do /m   yy  .:  hs   N/ sh   do  :.  m+  `M- ho   M:  /   M-  :M  N/  .M. do  `M:       
            sh .M`  +m  :m  +d   hs /N   sh -M`  od  :m  oh   do /m   yy  oy  hs   N/ sh   do  yo  m+  `M- ho   M:  d:  M-  :M  N/  .M. do  `M:       
            sh .M`  +m  `.  +d   hs /N   yh -M`  od  `.  od   do /m   yy  `.  hs   N/ sh   do  .`  m+  .M- ho   M:  .`  M-  :M  N/  -M. do  `M:       
            // `ymmmd+      .dmmmd- .hmmmd: `ymmmd+      -dmmmd- .hmmmd:      :dmmmh. -dmmmd-      +dmmmy` /dmmmh`      smmmms  ommmmy  /dmmmy`       
                                                                                                                                                      


EXODUS 2, David Rudnick [2011-2021]
Published in partnership wth Folia (Billy Rennenkamp, Dan Denorch, Everett Williams)
*/

contract EXODUS2 is ERC721Full("EXODUS 2", "X2") {
    using strings for *;
    string[] public stanzas;
    constructor() public {
        for (uint256 i = 1; i < 20; i++) {
            _mint(msg.sender, i);
        }
    }

    function deploy(string memory pangram) public {
        require(stanzas.length < 19, "stanzas populated");
        stanzas.push(pangram);
    }

    function tokenURI(uint _tokenId) external view returns (string memory _infoUrl) {
        string memory base = "https://exodus-ii.folia.app/v1/metadata/";
        string memory id = uint2str(_tokenId);
        return base.toSlice().concat(id.toSlice());
    }
    function uint2str(uint i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0) {
            uint _uint = 48 + i % 10;
            bstr[k--] = toBytes(_uint)[31];
            i /= 10;
        }
        return string(bstr);
    }
    function toBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

}

/*

        oyyyy/  oyyyy/      .yyyyy. `syyyy-  oyyyy:      .yyyyy. `syyyy-      -yyyys` .yyyyy.      :yyyyo  -yyyys`      +yyyy+  /yyyyo  :yyyys`       
       .M-..om .M-..om      +m...ds /N...yh -M-..sd      od...do /N...hy      hy...N/ sd...mo      mo..-M- hs...M:      M/..+M  N+..:M. ds..-M:       
       .M`  +m .M`  +m  :N  +d   hs /N   sh -M`  od  /N  oh   do /m   yy  sh  hs   N/ sh   do  hs  m+  `M- ho   M:  m/  M-  :M  N/  .M. do  `M:       
       .M`  +m .M`  +m   +  +d   hs /N   sh -M`  od   /  oh   do /m   yy  .:  hs   N/ sh   do  :.  m+  `M- ho   M:  /   M-  :M  N/  .M. do  `M:       
       .M`  +m .M`  +m  :m  +d   hs /N   sh -M`  od  :m  oh   do /m   yy  oy  hs   N/ sh   do  yo  m+  `M- ho   M:  d:  M-  :M  N/  .M. do  `M:       
       .M`  +m .M`  +m  `.  +d   hs /N   yh -M`  od  `.  od   do /m   yy  `.  hs   N/ sh   do  .`  m+  .M- ho   M:  .`  M-  :M  N/  -M. do  `M:       
       `ymmmd+ `ymmmd+      .dmmmd- .hmmmd: `ymmmd+      -dmmmd- .hmmmd:      :dmmmh. -dmmmd-      +dmmmy` /dmmmh`      smmmms  ommmmy  /dmmmy`       


                                                                            :d/                  
                                                                            .d/                 
                                                                    `.        .N-                
                                                                    /ymo`      dh                
                                                                    sMm`    -MN                
                                                                    mMM.   +NMy `:+yhs+/.      
                                                            -//:`    yMm  /dMMN/yNMMh/``-:      
                                                            -/+dNy:  `N+:dMMMN+hyo/-`           
                                                                :MMMs  +dNMMMN/-//++/:-.         
                                                                `mMMh +NMMMMmyydMMMNh/:+o        
                                                    `-+syhhyso/-` `/ds/MMMMMy.```:+/.    `        
                                                .odNMMMMMMMMMNmy/``-NMMMNo`.-/oyhddhyo:.        
                                                /mMMMMMMMMMMMMMMNNmhmMMMMo+hmNMMMMMMMMMMNd+.     
                                                /NMNdyshMMMMMmy/-.-:sNMMMMhs++ydNMMMMMMMMMMMNs.   
                                                mNs-`  `odho:`       -mMM+`    `-odMMMMmmmNMMMm:  
                                                M+   `.`              :Mh         `:oo:`..-:odNN. 
                                                m:  -mmd:     `-osso:. mo-ohhhyo/.      ```   :No 
                                                -h- `/hMs    .hMMMMMMNhNmNMMMMMNmNy.   .dmd:   do 
                                                .o++ohy.   `mNdhdmNNNMMMdyhmNm-.:hh   /MMd. `+m` 
                                                    `.`     .m/   `-/dMMMNs-`..    .    /hhssyy.  
                                                            `      dMMMMMMN:             `..`    
                                                                    NMNNMMm:.     `:+o+:`         
                                                                    -:.-yNMy`    +d+-.-+m/        
                                                                        -hMy   -N`  /s/Nm        
                                                                    `so+smh+..N`  /dmh:    ``  
                                                                    +h `+-./yhNd/`    `.:+hMd. 
                                                                    .hshM+    ./shdmmNMMmdyo:` 
                                                                        `
*/