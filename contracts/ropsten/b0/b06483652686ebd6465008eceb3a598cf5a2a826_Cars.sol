pragma solidity ^0.4.0;

contract Cars {
    struct Car {
        string vin;
        string make;
        string model;
        uint16 modelYear;
        string ipfsHash;
        address creator;
    }

    event CarAddedEvent(
        string vin,
        string make,
        string model,
        uint16 modelYear,
        string ipfsHash,
        address creator 
    );

    mapping (bytes32 => Car) public cars;

    modifier carExists(string vin) {
        Car storage car = cars[keccak256(abi.encodePacked(vin))];
        require(bytes(car.vin).length != 0);
        _;
    }

    modifier carDoesNotExists(string vin) {
        Car storage car = cars[keccak256(abi.encodePacked(vin))];
        require(bytes(car.vin).length == 0);
        _;
    }

    function getCar(string _vin) public view returns (string vin, string make, string model, uint16 modelYear, string ipfsHash, address creator) {
        Car storage car = cars[keccak256(abi.encodePacked(_vin))];
        return (
            car.vin,
            car.make,
            car.model,
            car.modelYear,
            car.ipfsHash,
            car.creator
        );
    }

    function addCar(string vin, string make, string model, uint16 modelYear, string ipfsHash) public {
        addCar(vin, make, model, modelYear, ipfsHash, msg.sender);
    }
    
    function addCar(string vin, string make, string model, uint16 modelYear, string ipfsHash, address creator) private carDoesNotExists(vin) {
        cars[keccak256(abi.encodePacked(vin))] = Car(vin, make, model, modelYear, ipfsHash, creator);

        emit CarAddedEvent(vin, make, model, modelYear, ipfsHash, creator);
    }
    
    function hashMessage(string vin, string make, string model, uint16 modelYear, string ipfsHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            keccak256(abi.encodePacked(
                "string VIN",
                "string Make",
                "string Model",
                "uint16 Model Year",
                "string IPFS Hash"
            )),
            keccak256(abi.encodePacked(
                vin,
                make,
                model,
                modelYear,
                ipfsHash
            ))
        ));
    }
     
    function recoverSigner(bytes32 hash, bytes32 r, bytes32 s, uint8 v) public pure returns (address) {
        return ecrecover(hash, v, r, s);
    }
    
    function addCarSigned(string vin, string make, string model, uint16 modelYear, string ipfsHash, address signer, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 hash = hashMessage(vin, make, model, modelYear, ipfsHash);
        address recoveredSignerAddress = recoverSigner(hash, r, s, v);
        require(recoveredSignerAddress == signer);

        addCar(vin, make, model, modelYear, ipfsHash, signer);
    }
}