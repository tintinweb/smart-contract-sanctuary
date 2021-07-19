/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract InstaImplementationM1 {

    event LogCast(
        address indexed origin,
        address indexed sender,
        uint256 value,
        string[] targetsNames
    );

    receive() external payable {}


    /**
     * @dev This is the main function, Where all the different functions are called
     * from Smart Account.
     * @param _targetNames Array of Connector address.
     * @param _datas Array of Calldata.
    */
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    )
    external
    payable 
    returns (bytes32) // Dummy return to fix instaIndex buildWithCast function
    {   
        emit LogCast(
            _origin,
            msg.sender,
            msg.value,
            _targetNames
        );
    }
}