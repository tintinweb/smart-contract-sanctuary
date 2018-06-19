pragma solidity ^0.4.19;


contract AddressProxy {

    struct ContractAddress {
        bytes32 id;
        string name;
        address at;
        uint createdTime;
        uint updatedTime;
    }

    address public owner;
    mapping(bytes32 => ContractAddress) private contractsAddress;
    bytes32[] public availableIds;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event AddressCreated(bytes32 id, string name, address at, uint createdTime, uint updatedTime);
    event AddressUpdated(bytes32 id, string name, address at, uint createdTime, uint updatedTime);

    function AddressProxy() public {
        owner = msg.sender;
    }

    function getAvailableIds() public view returns (bytes32[]) {
        return availableIds;
    }

    //  Adds or updates an address
    //  @params {string} name - the name of the contract Address
    //  @params {address} newAddress
    function addAddress(string name, address newAddress) public onlyOwner {
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

    function getContractNameById(bytes32 id) public view returns(string) {
        return contractsAddress[id].name;
    }

    function getContractAddressById(bytes32 id) public view returns(address) {
        return contractsAddress[id].at;
    }

    function getContractCreatedTimeById(bytes32 id) public view returns(uint) {
        return contractsAddress[id].createdTime;
    }

    function getContractUpdatedTimeById(bytes32 id) public view returns(uint) {
        return contractsAddress[id].updatedTime;
    }

    //  @params {string} source
    //  @return {bytes32}
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