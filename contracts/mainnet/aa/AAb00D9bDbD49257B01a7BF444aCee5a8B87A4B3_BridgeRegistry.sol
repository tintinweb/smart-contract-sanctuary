pragma solidity 0.5.16;


contract BridgeRegistry {
    address public cosmosBridge;
    address public bridgeBank;
    address public oracle;
    address public valset;

    bool private _initialized;

    uint256[100] private ____gap;

    event LogContractsRegistered(
        address _cosmosBridge,
        address _bridgeBank,
        address _oracle,
        address _valset
    );

    function initialize(
        address _cosmosBridge,
        address _bridgeBank
    ) public {
        require(!_initialized, "Initialized");

        cosmosBridge = _cosmosBridge;
        bridgeBank = _bridgeBank;
        _initialized = true;

        emit LogContractsRegistered(cosmosBridge, bridgeBank, oracle, valset);
    }
}