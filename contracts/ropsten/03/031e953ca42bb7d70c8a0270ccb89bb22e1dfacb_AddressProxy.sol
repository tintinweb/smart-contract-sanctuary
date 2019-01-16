pragma solidity ^0.4.24;

interface ErrorThrower {
    event Error(string func, string message);
}


contract Ownable is ErrorThrower {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner(string _funcName) {
        if(msg.sender != owner){
            emit Error(_funcName,"Operation can only be performed by contract owner");
            return;
        }
        _;
    }


    function renounceOwnership() public onlyOwner("renounceOwnership") {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }


    function transferOwnership(address _newOwner) public onlyOwner("transferOwnership") {
        _transferOwnership(_newOwner);
    }

    /**
    *  Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        if(_newOwner == address(0)){
            emit Error("transferOwnership","New owner&#39;s address needs to be different than 0x0");
            return;
        }

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
@title AddressProxy contract
@author App Store Foundation
 This contract works as part of a set of mechanisms in order to maintain tracking of the latest
version&#39;s contracts deployed to the network.
 */

contract AddressProxy is Ownable {

    struct ContractAddress {
        bytes32 id;
        string name;
        address at;
        uint createdTime;
        uint updatedTime;
    }

    mapping(bytes32 => ContractAddress) private contractsAddress;
    bytes32[] public availableIds;

    event AddressCreated(bytes32 id, string name, address at, uint createdTime, uint updatedTime);
    event AddressUpdated(bytes32 id, string name, address at, uint createdTime, uint updatedTime);

    function AddressProxy() public {
    }


    /**
    @notice Get all avaliable ids registered on the contract
     Just shows the list of ids registerd on the contract
    @return { "IdList" : "List of registered ids" }
     */
    function getAvailableIds() public view returns (bytes32[] IdList) {
        return availableIds;
    }

    /**
    @notice  Adds or updates an address
     Used when a new address needs to be updated to a currently registered id or to a new id.
    @param name Name of the contract
    @param newAddress Address of the contract
    */
    function addAddress(string name, address newAddress) public onlyOwner("addAddress") {
        bytes32 contAddId = stringToBytes32(name);

        uint nowInMilliseconds = now * 1000;

        if (contractsAddress[contAddId].id == 0x0) {
            ContractAddress memory newContractAddress;
            newContractAddress.id = contAddId;
            newContractAddress.name = name;
            newContractAddress.at = newAddress;
            newContractAddress.createdTime = nowInMilliseconds;
            newContractAddress.updatedTime = nowInMilliseconds;
            availableIds.push(contAddId);
            contractsAddress[contAddId] = newContractAddress;

            emit AddressCreated(newContractAddress.id, newContractAddress.name, newContractAddress.at, newContractAddress.createdTime, newContractAddress.updatedTime);
        } else {
            ContractAddress storage contAdd = contractsAddress[contAddId];
            contAdd.at = newAddress;
            contAdd.updatedTime = nowInMilliseconds;

            emit AddressUpdated(contAdd.id, contAdd.name, contAdd.at, contAdd.createdTime, contAdd.updatedTime);
        }
    }

    /**
    @notice Get the contract name associated to a certain id
    @param id Id of the registry
    @return { &#39;name&#39; : &#39;Name of the contract associated to the given id&#39; }
     */
    function getContractNameById(bytes32 id) public view returns(string name) {
        return contractsAddress[id].name;
    }


    /**
    @notice Get the contract address associated to a certain id
    @param id Id of the registry
    @return { &#39;contractAddr&#39; : &#39;Address of the contract associated to the given id&#39; }
     */
    function getContractAddressById(bytes32 id) public view returns(address contractAddr) {
        return contractsAddress[id].at;
    }

    /**
    @notice Get the specific date on which the contract address was firstly registered
    to a certain id
    @param id Id of the registry
    @return { &#39;time&#39; : &#39;Time in miliseconds of the first time the given id was registered&#39; }
     */
    function getContractCreatedTimeById(bytes32 id) public view returns(uint time) {
        return contractsAddress[id].createdTime;
    }

    /**
    @notice Get the specific date on which the contract address was lastly updated to a certain id
    @param id Id of the registry
    @return { &#39;time&#39; : &#39;Time in miliseconds of the last time the given id was updated&#39; }
     */
    function getContractUpdatedTimeById(bytes32 id) public view returns(uint time) {
        return contractsAddress[id].updatedTime;
    }

    /**
    @notice Converts a string type variable into a byte32 type variable
     This function is internal and uses inline assembly instructions.
    @param source string to be converted to a byte32 type
    @return { &#39;result&#39; : &#39;Initial string content converted to a byte32 type&#39; }
     */
    function stringToBytes32(string source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}