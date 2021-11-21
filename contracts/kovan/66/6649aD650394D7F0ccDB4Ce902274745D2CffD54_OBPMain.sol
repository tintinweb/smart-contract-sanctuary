// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/IRefereeDeployer.sol';
import './interfaces/IBettingOperatorDeployer.sol';



/// @title major contract of entry
/// @author Chris. CK Wong
contract OBPMain {
    address public migrator;
    //important address for being able to confiscate OBP in referee
    address public court;
    address public OBPToken;
    address public IBODeployer;
    address public IRDeployer;
    //registered referees
    address[] public allReferees;
    //registered bettingOperators
    mapping(uint256 => address) public allOperators;
    //supported token to place bet, this list needs to be centralized as fee is collected in this unit, and needs to be swapped back to OBP later 
    address[] public supportedTokens;

    modifier onlyMigrator {
        require(msg.sender == migrator);
        _;
    }

    constructor(address _OBPToken, address _court) {
        migrator = msg.sender;
        OBPToken = _OBPToken;
        court = _court;
    }


    function allRefereesLength() public view returns (uint) {
        return allReferees.length;
    }
    /// @dev address of the deployed operator would be pushed to the map; a 0x0 would be pushed in case create2 fails due to insuffiicent gas
    function deployBettingOperator(uint256 roothash) external returns(address operator){
        address owner = msg.sender;
        address OBPMain = address(this);
        require(allOperators[roothash] == address(0), "deployBettingOperator:: this roothash is occupied, pls render another rootHash");
        address operator = IBettingOperatorDeployer(IBODeployer).createBettingOperator(OBPMain,OBPToken, owner, roothash, court);
        allOperators[roothash] = operator;
        

    }

    /// @dev address of the deployed referee would be pushed to the list; a 0x0 would be pushed in case create2 fails due to insuffiicent gas
    function deployReferee() external returns(address referee) {
        address owner = msg.sender;
        address referee = IRefereeDeployer(IRDeployer).createReferee(court, owner, OBPToken);
        allReferees.push(referee);

    }

    /// @notice Protocol fee collected from BettingOperator in unit of `betToken` would be converted back to OBP. Thus the pre-requisite of supporting a betToken is a Pool betToken/OBP
    function addSupportedToken(address ERC20Token) onlyMigrator external {
        supportedTokens.push(ERC20Token);
    }

    function removeSupportedToken(uint256 index) onlyMigrator external {
        delete supportedTokens[index];
    }

    function setBettingOperatorDeployer(address _bettingOperatorDeployer) external onlyMigrator {
        IBODeployer = _bettingOperatorDeployer;
    }

    function setRefereeOperatorDeployer(address _refereeDeployer) external onlyMigrator {
        IRDeployer = _refereeDeployer;
    }
    
    function setCourt(address _court) external onlyMigrator {
        court = _court;
    }
    function transferMigrator(address _newMigrator) external onlyMigrator {
        migrator = _newMigrator;
    }


}

pragma solidity ^0.8.0;

interface IBettingOperatorDeployer {

    function createBettingOperator(address OBPMain, address OBPToken, address owner, uint256 roothash, address court) external returns(address);
    function setOperatorFee(uint256 _feeToOperator) external;
    function setRefereeFee(uint256 _feeToRefereeFee) external;
}

pragma solidity ^0.8.0;

interface IRefereeDeployer {

    function createReferee(address owner, address court, address OBPToken) external returns(address);
    function setArbitrationWindow(uint256 _arbitrationTime) external;

}