/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage3 {

    uint256 public number;
    string public text;
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function storeNumber(uint256 num) public {
        number = num;
    }
    
    function storeText(string memory txt) public {
        text = txt;
    }

}