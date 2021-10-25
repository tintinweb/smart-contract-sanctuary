/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract dfloresdevCard {
    
    string private name = "- Name: David Flores";
    string private description = "- Description: #A11Y Advocate | Software engineer | #GoogleCloud | #Web | #Platzi | #Firebase | #React | #dfloresdev | #GDGCloudMx | #Globant | http://bit.ly/3jgBV5i";
    string private github = "- GitHub: https://github.com/dfloresdev";
    string private twitter = "- Twitter: https://twitter.con/dfloresdev";
    string private linkedin = "- LinkedIn: https://www.linkedin.com/in/dfloresdev/";
    string private webpage = "- Web: https://dflores.dev";
    string private opensea = "- OpenSea: https://opensea.io/dfloresdev";
    
    function append(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f, string memory g) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b, c, d, e, f, g));
    
    }

    function getAllData() public view returns (string memory){
        return append(name, description, github, twitter, linkedin, webpage, opensea);
    }
    
    function getGithub() public view returns (string memory){
        return github;
    }
    function getTwitter() public view returns (string memory){
        return twitter;
    }
    function getLinkedin() public view returns (string memory){
        return linkedin;
    }
    function getWebpage() public view returns (string memory){
        return webpage;
    }
    function getOpensea() public view returns (string memory){
        return opensea;
    }
}