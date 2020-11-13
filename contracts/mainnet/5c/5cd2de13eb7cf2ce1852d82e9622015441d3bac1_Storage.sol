pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string hash = "737936b81de6f6ad998981e7abaec57cc0ae62abededfd79d81b3834fb8973936274cb9a7d5d3dbc4e3539dd4b355b7962e70c4a8ae0e5c9316c2f4a1ce93a0b  PreElectionThoughts.mp3";
    
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getHash() public view returns (string memory){
        return hash;
    }
}