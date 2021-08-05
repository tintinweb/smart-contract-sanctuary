/**
 *Submitted for verification at Etherscan.io on 2021-01-08
*/

// File: contracts/IQLF.sol

/**
 * @author          Yisi Liu
 * @contact         [email protected]
 * @author_time     01/06/2021
**/

pragma solidity >= 0.6.0;

interface IQLF {
    /**
     * @dev Returns if the given address is qualified, implemented on demand.
     */
    function ifQualified (address testee) external view returns (bool);

    /**
     * @dev Logs if the given address is qualified, implemented on demand.
     */
    function logQualified (address testee) external;

    /**
     * @dev Emit when `ifQualified` is called to decide if the given `address`
     * is `qualified` according to the preset rule by the contract creator and 
     * the current block `number` and the current block `timestamp`.
     */
    event Qualification(bool qualified, uint256 number, uint256 timestamp);
}

// File: contracts/qualification.sol

/**
 * @author          Yisi Liu
 * @contact         [email protected]
 * @author_time     01/06/2021
**/

pragma solidity >= 0.6.0;


contract QLF is IQLF {
    string private name;
    uint256 private creation_time;

    constructor (string memory _name) public {
        name = _name;
        creation_time = block.timestamp;
    }

    function get_name() public view returns (string memory) {
        return name;
    }

    function get_creation_time() public view returns (uint256) {
        return creation_time;
    }

    function ifQualified(address testee) public view override returns (bool) {
        bool qualified = true;
        return qualified;
    } 

    function logQualified(address testee) public override {
        bool qualified = true;
        emit Qualification(qualified, block.number, block.timestamp);
    } 
}