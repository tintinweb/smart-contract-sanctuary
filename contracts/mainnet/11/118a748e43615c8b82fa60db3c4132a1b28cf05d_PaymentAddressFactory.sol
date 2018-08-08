pragma solidity ^0.4.19;


/// @title Version
contract Version {
    string public semanticVersion;

    /// @notice Constructor saves a public version of the deployed Contract.
    /// @param _version Semantic version of the contract.
    function Version(string _version) internal {
        semanticVersion = _version;
    }
}


/// @title Factory
contract Factory is Version {
    event FactoryAddedContract(address indexed _contract);

    modifier contractHasntDeployed(address _contract) {
        require(contracts[_contract] == false);
        _;
    }

    mapping(address => bool) public contracts;

    function Factory(string _version) internal Version(_version) {}

    function hasBeenDeployed(address _contract) public constant returns (bool) {
        return contracts[_contract];
    }

    function addContract(address _contract)
        internal
        contractHasntDeployed(_contract)
        returns (bool)
    {
        contracts[_contract] = true;
        FactoryAddedContract(_contract);
        return true;
    }
}


contract PaymentAddress {
    event PaymentMade(address indexed _payer, address indexed _collector, uint256 _value);

    address public collector;
    bytes4 public identifier;

    function PaymentAddress(address _collector, bytes4 _identifier) public {
        collector = _collector;
        identifier = _identifier;
    }

    function () public payable {
        collector.transfer(msg.value);
        PaymentMade(msg.sender, collector, msg.value);
    }
}


contract PaymentAddressFactory is Factory {
    // index of created contracts
    mapping (bytes4 => address) public paymentAddresses;

    function PaymentAddressFactory() public Factory("1.0.0") {}

    // deploy a new contract
    function newPaymentAddress(address _collector, bytes4 _identifier)
        public
        returns(address newContract)
    {
        require(paymentAddresses[_identifier] == address(0x0));
        PaymentAddress paymentAddress = new PaymentAddress(_collector, _identifier);
        paymentAddresses[_identifier] = paymentAddress;
        addContract(paymentAddress);
        return paymentAddress;
    }
}