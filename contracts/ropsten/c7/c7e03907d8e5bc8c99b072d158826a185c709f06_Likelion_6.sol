/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// Seo sangcheol

pragma solidity 0.8.0;

contract Likelion_6 {
    string[] names;
    string[] id;
    string[] pw;
        
        function pushName(string memory _name) public {
         if(keccak256(bytes(_name))!=keccak256(bytes("james"))) {
            names.push(_name);
            }
        }
        
        function getName(uint i) public view returns(string memory) {
        return names[i];

        }

 /*       function joinId(string memory _id, string memory _pw) public {
            id.push(keccak256(bytes(_id)));
            pw.push(keccak256(bytes(_pw)));
            }
 */
 
        function getId(uint i) public view returns(string memory, string memory) {
        return (id[i],pw[i]);

        }
        }