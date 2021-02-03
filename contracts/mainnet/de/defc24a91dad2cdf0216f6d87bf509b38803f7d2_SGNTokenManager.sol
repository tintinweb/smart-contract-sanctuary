/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

pragma solidity 0.4.25;

// File: contracts/saga-genesis/interfaces/ISGNTokenManager.sol

/**
 * @title SGN Token Manager Interface.
 */
interface ISGNTokenManager {
    /**
     * @dev Get the current SGR worth of a given SGN amount.
     * @param _sgnAmount The amount of SGN to convert.
     * @return The equivalent amount of SGR.
     */
    function convertSgnToSga(uint256 _sgnAmount) external view returns (uint256);

    /**
     * @dev Exchange SGN for SGR.
     * @param _sender The address of the sender.
     * @param _sgnAmount The amount of SGN received.
     * @return The amount of SGR that the sender is entitled to.
     */
    function exchangeSgnForSga(address _sender, uint256 _sgnAmount) external returns (uint256);

    /**
     * @dev Handle direct SGN transfer.
     * @param _sender The address of the sender.
     * @param _to The address of the destination account.
     * @param _value The amount of SGN to be transferred.
     */
    function uponTransfer(address _sender, address _to, uint256 _value) external;

    /**
     * @dev Handle custodian SGN transfer.
     * @param _sender The address of the sender.
     * @param _from The address of the source account.
     * @param _to The address of the destination account.
     * @param _value The amount of SGN to be transferred.
     */
    function uponTransferFrom(address _sender, address _from, address _to, uint256 _value) external;

    /** 
     * @dev Upon minting of SGN vested in delay.
     * @param _value The amount of SGN to mint.
     */
    function uponMintSgnVestedInDelay(uint256 _value) external;
}

// File: contracts/saga-genesis/interfaces/ISagaExchanger.sol

/**
 * @title Saga Exchanger Interface.
 * @dev Old exchanger adapting by SagaExchangerSogurAdapter to the new ISogurExchanger.
 */
interface ISagaExchanger {
    /**
     * @param _to The address of the SGN holder.
     * @param _value The amount of SGR to transfer.
     */
    function transferSgaToSgnHolder(address _to, uint256 _value) external;
}

// File: contracts/saga-genesis/SGNTokenManager.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title SGN Token Manager.
 */
contract SGNTokenManager is ISGNTokenManager, ISagaExchanger {
    string public constant VERSION = "2.0.0";


    /**
     * @dev Get the current SGR worth of a given SGN amount.
       function name is convertSgnToSga and not convertSgnToSgr for backward compatibility.
     * @param _sgnAmount The amount of SGN to convert.
     * @return Fixed zero as disabled.
     */
    function convertSgnToSga(uint256 _sgnAmount) external view returns (uint256) {
        require(false, "convert SGN to SGA is disabled");
        _sgnAmount;
        return 0;
    }

    /**
     * @dev Exchange SGN for SGR.
       function name is exchangeSgnForSga and not exchangeSgnForSgr for backward compatibility.
     * @param _sender The address of the sender.
     * @param _sgnAmount The amount of SGN received.
     * @return Fixed zero as exchange is disabled.
     */
    function exchangeSgnForSga(address _sender, uint256 _sgnAmount) external returns (uint256) {
        _sender;
        _sgnAmount;
        return 0;
    }

    /**
     * @dev Handle direct SGN transfer.
     * @param _sender The address of the sender.
     * @param _to The address of the destination account.
     * @param _value The amount of SGN to be transferred.
     */
    function uponTransfer(address _sender, address _to, uint256 _value) external {
        _sender;
        _to;
        _value;
    }

    /**
     * @dev Handle custodian SGN transfer.
     * @param _sender The address of the sender.
     * @param _from The address of the source account.
     * @param _to The address of the destination account.
     * @param _value The amount of SGN to be transferred.
     */
    function uponTransferFrom(address _sender, address _from, address _to, uint256 _value) external {
        _sender;
        _from;
        _to;
        _value;
    }

    /** 
     * @dev Upon minting of SGN vested in delay.
     * @param _value The amount of SGN to mint.
     */
    function uponMintSgnVestedInDelay(uint256 _value) external {
        require(false, "minting sgn is disabled");
        _value;
    }

    /**
     * @dev Transfer SGR to an SGN holder.
     * @param _to The address of the SGN holder.
     * @param _value The amount of SGR to transfer.
     */
    function transferSgaToSgnHolder(address _to, uint256 _value) external {
        _to;
        _value;
    }
}