// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


contract WarriorGeneGenerator{

    address public core;
    uint256 public constant genModulus = 10**72;
    uint256 public constant genStartPosition = 1;
    uint256 public constant attributeStartPosition = 4;
    uint256 public constant GEN_PREFIX = 10**75;

    modifier onlyCore() {
        require(
            msg.sender == core,
            "WarriorGeneGenerator: only core functionality"
        );
        _;
    }

    /**
     * @dev constructor to set inital value.
     */
    constructor (address _core) {
        core = _core;
    }

    /**
     * @dev generate warrior gene
     * @param _metadata unique metadata using which the warrior attributes are generated
     */
    function generateGene(uint256 _currentGen, bytes32 _metadata) public onlyCore view returns(uint256 gene){
        gene = uint256(_metadata);
        // gene = {1-digit prefix}{3-digits generation}{72-digits attributes}
        gene = (gene % genModulus)+(_currentGen*genModulus)+GEN_PREFIX;
    }

    /**
     * @dev set new core
     * @param _newCore new core address
     */
    function setCore(address _newCore) public onlyCore{
        require(
            _newCore != address(0),
            "WarriorGeneGenerator: new core cannot be zero"
        );
        core = _newCore;
    }

}

