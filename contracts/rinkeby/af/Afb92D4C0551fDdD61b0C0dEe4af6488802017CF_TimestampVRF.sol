/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// File: base/Context.sol



pragma solidity ^0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  {}

    function _msgSender() internal view returns (address payable) {
        return payable (msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: base/Ownable.sol




pragma solidity ^0.8.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
   */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
   */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: base/IOracle.sol


pragma solidity ^0.8.0;

interface IOracle{
    function getTimestampCountById(bytes32 _queryId)
        external
        view
        returns (uint256);
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);
}
// File: TestContracts/Timestamp.sol


pragma solidity ^0.8.0;



contract TimestampVRF is Ownable{

    IOracle Oracle;

    constructor(address oracleAddress){
        Oracle = IOracle(oracleAddress);
    }

    function setOracle(address oracleAddress) external onlyOwner{
        Oracle = IOracle(oracleAddress);
    }

    function initiateRandomness(uint _tokenId,uint _timestamp) external view returns(uint){
        bytes32 tellorId = 0x0000000000000000000000000000000000000000000000000000000000000001;
        uint result = Oracle.getTimestampCountById(tellorId);
        uint tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,result-1);
        if(tellorTimeStamp<_timestamp){
            return uint(keccak256(abi.encodePacked(_tokenId,block.timestamp)));
        }
        for(uint i=(result-2);i>0;i--){
            if(tellorTimeStamp < _timestamp)
            break;
            tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,i);
        }
        bytes memory tellorValue = Oracle.getValueByTimestamp(tellorId,tellorTimeStamp);
        return uint(keccak256(abi.encodePacked(tellorValue,_tokenId,block.timestamp)));
    }

    function stealRandomness() external view returns(uint){
        bytes32 tellorId = 0x0000000000000000000000000000000000000000000000000000000000000001;
        uint result = Oracle.getTimestampCountById(tellorId);
        uint tellorTimeStamp = Oracle.getReportTimestampByIndex(tellorId,result-1);
        bytes memory tellorValue = Oracle.getValueByTimestamp(tellorId,tellorTimeStamp);
        return uint(keccak256(abi.encodePacked(tellorValue,block.timestamp,block.difficulty)));
    }
}