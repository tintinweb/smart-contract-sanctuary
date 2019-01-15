pragma solidity ^0.5.2; 
contract newYearDetermination {   
    
string myHeader = "The Blockchain is the best carving stone to imprint new year determinations";
string myTitle = "Here Are My Determination of Year 2019";
string myDetermination = &#39;\r\n [1] Study on Blockchain at least one hour every day \r\n [2] Contribute to enrich the Blockchain community in Korea - especially in Jeju \r\n [3] Increase the number of my SNS followers by 2000 \r\n [4] Post SNS contents every alternative days \r\n [5] Write a book (or journals) on Blockchain \r\n [6] Setup one Bitcoin Lighting Network Node \r\n [7] Build and operate at least five Masternodes of Altcoins \r\n [8] Trip to Scandinavian countries \r\n [9] Play with Sarang at least 30 minutes every day \r\n [10] Love my wife and family as always&#39;; 

    function x_Header () public view returns (string memory) {       
        return myHeader;
    } 
    
    function y_Title () public view returns (string memory) {       
        return myTitle;
    }
    
    function z_Determinations () public view returns (string memory) {       
        return myDetermination;
    }
}