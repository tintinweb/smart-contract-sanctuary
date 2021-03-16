// @unsupported: ovm
/**
 *Submitted for verification at Etherscan.io on 2017-10-12
 */

/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016-2017 Oraclize LTD
*/

/*
Oraclize Connector v1.2.0
*/

// 'compressed' alternative, where all modifiers have been changed to FUNCTIONS
// which is cheaper for deployment, potentially cheaper execution

pragma solidity >0.6.0 <0.8.0;

contract Oraclize {
    mapping(address => uint256) reqc;

    mapping(address => bytes1) public cbAddresses;

    mapping(address => bool) public offchainPayment;

    event Log1(
        address sender,
        bytes32 cid,
        uint256 timestamp,
        string datasource,
        string arg,
        uint256 gaslimit,
        bytes1 proofType,
        uint256 gasPrice
    );
    event Log2(
        address sender,
        bytes32 cid,
        uint256 timestamp,
        string datasource,
        string arg1,
        string arg2,
        uint256 gaslimit,
        bytes1 proofType,
        uint256 gasPrice
    );
    event LogN(
        address sender,
        bytes32 cid,
        uint256 timestamp,
        string datasource,
        bytes args,
        uint256 gaslimit,
        bytes1 proofType,
        uint256 gasPrice
    );
    event Log1_fnc(
        address sender,
        bytes32 cid,
        uint256 timestamp,
        string datasource,
        string arg,
        function() external callback,
        uint256 gaslimit,
        bytes1 proofType,
        uint256 gasPrice
    );
    event Log2_fnc(
        address sender,
        bytes32 cid,
        uint256 timestamp,
        string datasource,
        string arg1,
        string arg2,
        function() external callback,
        uint256 gaslimit,
        bytes1 proofType,
        uint256 gasPrice
    );
    event LogN_fnc(
        address sender,
        bytes32 cid,
        uint256 timestamp,
        string datasource,
        bytes args,
        function() external callback,
        uint256 gaslimit,
        bytes1 proofType,
        uint256 gasPrice
    );

    event Emit_OffchainPaymentFlag(
        address indexed idx_sender,
        address sender,
        bool indexed idx_flag,
        bool flag
    );

    address owner;
    address paymentFlagger;

    function changeAdmin(address _newAdmin) external {
        onlyadmin();
        owner = _newAdmin;
    }

    function changePaymentFlagger(address _newFlagger) external {
        onlyadmin();
        paymentFlagger = _newFlagger;
    }

    function addCbAddress(address newCbAddress, bytes1 addressType) external {
        onlyadmin();
        //bytes memory nil = '';
        addCbAddress(newCbAddress, addressType, hex"");
    }

    // proof is currently a placeholder for when associated proof for addressType is added
    function addCbAddress(
        address newCbAddress,
        bytes1 addressType,
        bytes memory proof
    ) public {
        onlyadmin();
        cbAddresses[newCbAddress] = addressType;
    }

    function removeCbAddress(address newCbAddress) external {
        onlyadmin();
        delete cbAddresses[newCbAddress];
    }

    function cbAddress() public view returns (address _cbAddress) {
        if (cbAddresses[tx.origin] != 0x00) return _cbAddress = tx.origin;
    }

    function addDSource(string calldata dsname, uint256 multiplier) external {
        addDSource(dsname, 0x00, multiplier);
    }

    function addDSource(
        string memory dsname,
        bytes1 proofType,
        uint256 multiplier
    ) public {
        onlyadmin();
        bytes32 dsname_hash = keccak256(abi.encodePacked(dsname, proofType));
        dsources.push(dsname_hash);
        price_multiplier[dsname_hash] = multiplier;
    }

    // Utilized by bridge
    function multiAddDSource(
        bytes32[] calldata dsHash,
        uint256[] calldata multiplier
    ) external {
        onlyadmin();
        // dsHash -> keccak256(abi.encodePacked(DATASOURCE_NAME, PROOF_TYPE));
        for (uint256 i = 0; i < dsHash.length; i++) {
            dsources.push(dsHash[i]);
            price_multiplier[dsHash[i]] = multiplier[i];
        }
    }

    function multisetProofType(
        uint256[] calldata _proofType,
        address[] calldata _addr
    ) external {
        onlyadmin();
        for (uint256 i = 0; i < _addr.length; i++)
            addr_proofType[_addr[i]] = bytes1(uint8(_proofType[i]));
    }

    function multisetCustomGasPrice(
        uint256[] calldata _gasPrice,
        address[] calldata _addr
    ) external {
        onlyadmin();
        for (uint256 i = 0; i < _addr.length; i++)
            addr_gasPrice[_addr[i]] = _gasPrice[i];
    }

    uint256 gasprice = 20000000000;

    function setGasPrice(uint256 newgasprice) external {
        onlyadmin();
        gasprice = newgasprice;
    }

    function setBasePrice(uint256 new_baseprice) external {
        //0.001 usd in ether
        onlyadmin();
        baseprice = new_baseprice;
        for (uint256 i = 0; i < dsources.length; i++)
            price[dsources[i]] = new_baseprice * price_multiplier[dsources[i]];
    }

    function setBasePrice(uint256 new_baseprice, bytes calldata proofID)
        external
    {
        //0.001 usd in ether
        onlyadmin();
        baseprice = new_baseprice;
        for (uint256 i = 0; i < dsources.length; i++)
            price[dsources[i]] = new_baseprice * price_multiplier[dsources[i]];
    }

    function setOffchainPayment(address _addr, bool _flag) external {
        if (msg.sender != paymentFlagger) revert();
        offchainPayment[_addr] = _flag;
        emit Emit_OffchainPaymentFlag(_addr, _addr, _flag, _flag);
    }

    function withdrawFunds(address payable _addr) external {
        onlyadmin();
        _addr.send(address(this).balance);
    }

    // unnecessary?
    //function() {}

    constructor() public {
        owner = msg.sender;
    }

    // Pesudo-modifiers

    function onlyadmin() private {
        if (msg.sender != owner) revert();
    }

    function costs(string memory datasource, uint256 gaslimit)
        private
        returns (uint256 price)
    {
        price = getPrice(datasource, gaslimit, msg.sender);

        if (msg.value >= price) {
            uint256 diff = msg.value - price;
            if (diff > 0) {
                // added for correct query cost to be returned
                if (!msg.sender.send(diff)) {
                    revert();
                }
            }
        } else revert();
    }

    mapping(address => bytes1) addr_proofType;
    mapping(address => uint256) addr_gasPrice;
    uint256 public baseprice;
    mapping(bytes32 => uint256) price;
    mapping(bytes32 => uint256) price_multiplier;
    bytes32[] dsources;

    bytes32[] public randomDS_sessionPubKeysHash;

    function randomDS_updateSessionPubKeysHash(
        bytes32[] calldata _newSessionPubKeysHash
    ) external {
        onlyadmin();
        delete randomDS_sessionPubKeysHash;
        for (uint256 i = 0; i < _newSessionPubKeysHash.length; i++)
            randomDS_sessionPubKeysHash.push(_newSessionPubKeysHash[i]);
    }

    function randomDS_getSessionPubKeyHash() external view returns (bytes32) {
        uint256 i =
            uint256(keccak256(abi.encodePacked(reqc[msg.sender]))) %
                randomDS_sessionPubKeysHash.length;
        return randomDS_sessionPubKeysHash[i];
    }

    function setProofType(bytes1 _proofType) external {
        addr_proofType[msg.sender] = _proofType;
    }

    function setCustomGasPrice(uint256 _gasPrice) external {
        addr_gasPrice[msg.sender] = _gasPrice;
    }

    function getPrice(string memory _datasource)
        public
        returns (uint256 _dsprice)
    {
        return getPrice(_datasource, msg.sender);
    }

    function getPrice(string memory _datasource, uint256 _gaslimit)
        public
        returns (uint256 _dsprice)
    {
        return getPrice(_datasource, _gaslimit, msg.sender);
    }

    function getPrice(string memory _datasource, address _addr)
        private
        returns (uint256 _dsprice)
    {
        return getPrice(_datasource, 200000, _addr);
    }

    function getPrice(
        string memory _datasource,
        uint256 _gaslimit,
        address _addr
    ) private returns (uint256 _dsprice) {
        uint256 gasprice_ = addr_gasPrice[_addr];
        if (
            (offchainPayment[_addr]) ||
            ((_gaslimit <= 200000) &&
                (reqc[_addr] == 0) &&
                (gasprice_ <= gasprice) &&
                (tx.origin != cbAddress()))
        ) return 0;

        if (gasprice_ == 0) gasprice_ = gasprice;
        _dsprice = price[
            keccak256(abi.encodePacked(_datasource, addr_proofType[_addr]))
        ];
        _dsprice += _gaslimit * gasprice_;
        return _dsprice;
    }

    function getCodeSize(address _addr) private view returns (uint256 _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function query(string calldata _datasource, string calldata _arg)
        external
        payable
        returns (bytes32 _id)
    {
        return query1(0, _datasource, _arg, 200000);
    }

    function query1(string calldata _datasource, string calldata _arg)
        external
        payable
        returns (bytes32 _id)
    {
        return query1(0, _datasource, _arg, 200000);
    }

    function query2(
        string calldata _datasource,
        string calldata _arg1,
        string calldata _arg2
    ) external payable returns (bytes32 _id) {
        return query2(0, _datasource, _arg1, _arg2, 200000);
    }

    function queryN(string calldata _datasource, bytes calldata _args)
        external
        payable
        returns (bytes32 _id)
    {
        return queryN(0, _datasource, _args, 200000);
    }

    function query(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg
    ) external payable returns (bytes32 _id) {
        return query1(_timestamp, _datasource, _arg, 200000);
    }

    function query1(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg
    ) external payable returns (bytes32 _id) {
        return query1(_timestamp, _datasource, _arg, 200000);
    }

    function query2(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg1,
        string calldata _arg2
    ) external payable returns (bytes32 _id) {
        return query2(_timestamp, _datasource, _arg1, _arg2, 200000);
    }

    function queryN(
        uint256 _timestamp,
        string calldata _datasource,
        bytes calldata _args
    ) external payable returns (bytes32 _id) {
        return queryN(_timestamp, _datasource, _args, 200000);
    }

    /*  Needless?
    function query(uint _timestamp, string _datasource, string _arg, uint _gaslimit)
    payable
    external
    returns (bytes32 _id)
    {
        return query1(_timestamp, _datasource, _arg, _gaslimit);
    }
*/
    function query_withGasLimit(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg,
        uint256 _gaslimit
    ) external payable returns (bytes32 _id) {
        return query1(_timestamp, _datasource, _arg, _gaslimit);
    }

    function query1_withGasLimit(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg,
        uint256 _gaslimit
    ) external payable returns (bytes32 _id) {
        return query1(_timestamp, _datasource, _arg, _gaslimit);
    }

    function query2_withGasLimit(
        uint256 _timestamp,
        string calldata _datasource,
        string calldata _arg1,
        string calldata _arg2,
        uint256 _gaslimit
    ) external payable returns (bytes32 _id) {
        return query2(_timestamp, _datasource, _arg1, _arg2, _gaslimit);
    }

    function queryN_withGasLimit(
        uint256 _timestamp,
        string calldata _datasource,
        bytes calldata _args,
        uint256 _gaslimit
    ) external payable returns (bytes32 _id) {
        return queryN(_timestamp, _datasource, _args, _gaslimit);
    }

    function query1(
        uint256 _timestamp,
        string memory _datasource,
        string memory _arg,
        uint256 _gaslimit
    ) public payable returns (bytes32 _id) {
        costs(_datasource, _gaslimit);
        if (
            (_timestamp > block.timestamp + 3600 * 24 * 60) ||
            (_gaslimit > block.gaslimit)
        ) revert();

        _id = keccak256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender]++;
        emit Log1(
            msg.sender,
            _id,
            _timestamp,
            _datasource,
            _arg,
            _gaslimit,
            addr_proofType[msg.sender],
            addr_gasPrice[msg.sender]
        );
        return _id;
    }

    function query2(
        uint256 _timestamp,
        string memory _datasource,
        string memory _arg1,
        string memory _arg2,
        uint256 _gaslimit
    ) public payable returns (bytes32 _id) {
        costs(_datasource, _gaslimit);
        if (
            (_timestamp > block.timestamp + 3600 * 24 * 60) ||
            (_gaslimit > block.gaslimit)
        ) revert();

        _id = keccak256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender]++;
        emit Log2(
            msg.sender,
            _id,
            _timestamp,
            _datasource,
            _arg1,
            _arg2,
            _gaslimit,
            addr_proofType[msg.sender],
            addr_gasPrice[msg.sender]
        );
        return _id;
    }

    function queryN(
        uint256 _timestamp,
        string memory _datasource,
        bytes memory _args,
        uint256 _gaslimit
    ) public payable returns (bytes32 _id) {
        costs(_datasource, _gaslimit);
        if (
            (_timestamp > block.timestamp + 3600 * 24 * 60) ||
            (_gaslimit > block.gaslimit)
        ) revert();

        _id = keccak256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender]++;
        emit LogN(
            msg.sender,
            _id,
            _timestamp,
            _datasource,
            _args,
            _gaslimit,
            addr_proofType[msg.sender],
            addr_gasPrice[msg.sender]
        );
        return _id;
    }

    function query1_fnc(
        uint256 _timestamp,
        string memory _datasource,
        string memory _arg,
        function() external _fnc,
        uint256 _gaslimit
    ) public payable returns (bytes32 _id) {
        costs(_datasource, _gaslimit);
        if (
            (_timestamp > block.timestamp + 3600 * 24 * 60) ||
            (_gaslimit > block.gaslimit) ||
            _fnc.address != msg.sender
        ) revert();

        _id = keccak256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender]++;
        emit Log1_fnc(
            msg.sender,
            _id,
            _timestamp,
            _datasource,
            _arg,
            _fnc,
            _gaslimit,
            addr_proofType[msg.sender],
            addr_gasPrice[msg.sender]
        );
        return _id;
    }

    function query2_fnc(
        uint256 _timestamp,
        string memory _datasource,
        string memory _arg1,
        string memory _arg2,
        function() external _fnc,
        uint256 _gaslimit
    ) public payable returns (bytes32 _id) {
        costs(_datasource, _gaslimit);
        if (
            (_timestamp > block.timestamp + 3600 * 24 * 60) ||
            (_gaslimit > block.gaslimit) ||
            _fnc.address != msg.sender
        ) revert();

        _id = keccak256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender]++;
        emit Log2_fnc(
            msg.sender,
            _id,
            _timestamp,
            _datasource,
            _arg1,
            _arg2,
            _fnc,
            _gaslimit,
            addr_proofType[msg.sender],
            addr_gasPrice[msg.sender]
        );
        return _id;
    }

    function queryN_fnc(
        uint256 _timestamp,
        string memory _datasource,
        bytes memory _args,
        function() external _fnc,
        uint256 _gaslimit
    ) public payable returns (bytes32 _id) {
        costs(_datasource, _gaslimit);
        if (
            (_timestamp > block.timestamp + 3600 * 24 * 60) ||
            (_gaslimit > block.gaslimit) ||
            _fnc.address != msg.sender
        ) revert();

        _id = keccak256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
        reqc[msg.sender]++;
        emit LogN_fnc(
            msg.sender,
            _id,
            _timestamp,
            _datasource,
            _args,
            _fnc,
            _gaslimit,
            addr_proofType[msg.sender],
            addr_gasPrice[msg.sender]
        );
        return _id;
    }
}