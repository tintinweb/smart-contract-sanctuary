pragma solidity ^0.8.0;

import './interfaces/IRefereeDeployer.sol';
import './interfaces/IBettingOperatorDeployer.sol';



//This is a modification from sushibar implementation, with an added mapping for storing valid Referees and their current staking totals
contract OBPMain {
    address public migrator;
    //important address for being able to confiscate OBP in referee
    address public court;
    address public OBPToken;
    address public IBODeployer;
    address public IRDeployer;
    //registered referees
    address[] public referees;
    //registered bettingOperators
    address[] public bettingOperators;
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



    function deployBettingOperator(uint256 roothash) external returns(address){
        address owner = msg.sender;
        return IBettingOperatorDeployer(IBODeployer).createBettingOperator(OBPToken, owner, roothash, court);
    }
    function deployReferee() external returns(address referee) {
        address owner = msg.sender;
        address referee = IRefereeDeployer(IRDeployer).createReferee(court, owner, OBPToken);
    }

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

    function createBettingOperator(address OBPToken, address owner, uint256 roothash, address court) external returns(address);
    function setOperatorFee(uint256 _feeToOperator) external;
    function setRefereeFee(uint256 _feeToRefereeFee) external;
}

pragma solidity ^0.8.0;

interface IRefereeDeployer {

    function createReferee(address owner, address court, address OBPToken) external returns(address);
    function setArbitrationWindow(uint256 _arbitrationTime) external;

}