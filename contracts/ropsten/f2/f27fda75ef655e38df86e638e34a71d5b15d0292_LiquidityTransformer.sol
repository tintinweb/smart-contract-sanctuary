/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity =0.7.2;


interface IWiseToken {

    function currentWiseDay()
        external view
        returns (uint64);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function mintSupply(
        address _investorAddress,
        uint256 _amount
    ) external;

    function giveStatus(
        address _referrer
    ) external;
}

interface UniswapRouterV2 {

    function addLiquidityETH(
        address token,
        uint256 amountTokenMax,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (
        uint256 amountB
    );

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (
        uint256[] memory amounts
    );
}

interface UniswapV2Pair {

    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function token1() external view returns (address);
}

interface RefundSponsorI {
    function addGasRefund(address _a, uint256 _c) external;
}

interface IERC20Token {

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )  external returns (
        bool success
    );

    function approve(
        address _spender,
        uint256 _value
    )  external returns (
        bool success
    );
}

interface ProvableI {

    function cbAddress() external returns (address _cbAddress);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function getPrice(string calldata _datasource) external returns (uint _dsprice);
    function randomDS_getSessionPubKeyHash() external view returns (bytes32 _sessionKeyHash);
    function getPrice(string calldata _datasource, uint _gasLimit)  external returns (uint _dsprice);
    function queryN(uint _timestamp, string calldata _datasource, bytes calldata _argN) external payable returns (bytes32 _id);
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gasLimit) external payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns (bytes32 _id);
}

interface OracleAddrResolverI {
    function getAddress() external returns (address _address);
}

contract usingProvable {

    using CBOR for Buffer.buffer;

    ProvableI provable;
    OracleAddrResolverI OAR;

    uint constant day = 60 * 60 * 24;
    uint constant week = 60 * 60 * 24 * 7;
    uint constant month = 60 * 60 * 24 * 30;

    byte constant proofType_NONE = 0x00;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    byte constant proofType_Android = 0x40;
    byte constant proofType_TLSNotary = 0x10;

    string provable_network_name;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_consensys = 161;

    mapping(bytes32 => bytes32) provable_randomDS_args;
    mapping(bytes32 => bool) provable_randomDS_sessionKeysHashVerified;

    modifier provableAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            provable_setNetwork(networkID_auto);
        }
        if (address(provable) != OAR.getAddress()) {
            provable = ProvableI(OAR.getAddress());
        }
        _;
    }

    modifier provable_randomDS_proofVerify(bytes32 _queryId, string memory _result, bytes memory _proof) {
        // RandomDS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (uint8(_proof[2]) == uint8(1)));
        bool proofVerified = provable_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), provable_getNetworkName());
        require(proofVerified);
        _;
    }

    function provable_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      _networkID; // NOTE: Silence the warning and remain backwards compatible
      return provable_setNetwork();
    }

    function provable_setNetworkName(string memory _network_name) internal {
        provable_network_name = _network_name;
    }

    function provable_getNetworkName() internal view returns (string memory _networkName) {
        return provable_network_name;
    }

    function provable_setNetwork() internal returns (bool _networkSet) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) { //mainnet
            OAR = OracleAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            provable_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) { //ropsten testnet
            OAR = OracleAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            provable_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) { //kovan testnet
            OAR = OracleAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            provable_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) { //rinkeby testnet
            OAR = OracleAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            provable_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41) > 0) { //goerli testnet
            OAR = OracleAddrResolverI(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41);
            provable_setNetworkName("eth_goerli");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) { //ethereum-bridge
            OAR = OracleAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) { //ether.camp ide
            OAR = OracleAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) { //browser-solidity
            OAR = OracleAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }
    /**
     * @dev The following `__callback` functions are just placeholders ideally
     *      meant to be defined in child contract when proofs are used.
     *      The function bodies simply silence compiler warnings.
     */
    function __callback(bytes32 _myid, string memory _result) virtual public {
        __callback(_myid, _result, new bytes(0));
    }

    function __callback(bytes32 _myid, string memory _result, bytes memory _proof) virtual public {
      _myid; _result; _proof;
      provable_randomDS_args[bytes32(0)] = bytes32(0);
    }

    function provable_getPrice(string memory _datasource) provableAPI internal returns (uint _queryPrice) {
        return provable.getPrice(_datasource);
    }

    function provable_getPrice(string memory _datasource, uint _gasLimit) provableAPI internal returns (uint _queryPrice) {
        return provable.getPrice(_datasource, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(0, _datasource, _arg);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query{value: price}(_timestamp, _datasource, _arg);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource,_gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query_withGasLimit{value: price}(_timestamp, _datasource, _arg, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
           return 0; // Unexpectedly high price
        }
        return provable.query_withGasLimit{value: price}(0, _datasource, _arg, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg1, string memory _arg2) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query2{value: price}(0, _datasource, _arg1, _arg2);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        return provable.query2{value: price}(_timestamp, _datasource, _arg1, _arg2);
    }

    function provable_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query2_withGasLimit{value: price}(_timestamp, _datasource, _arg1, _arg2, _gasLimit);
    }

    function provable_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        return provable.query2_withGasLimit{value: price}(0, _datasource, _arg1, _arg2, _gasLimit);
    }

    function provable_query(string memory _datasource, string[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(_timestamp, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, string[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = stra2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(0, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, string[1] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[1] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[2] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[2] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[3] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[3] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[4] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[4] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[5] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[5] memory _args) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, string[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, string[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(0, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[] memory _argN) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN{value: price}(_timestamp, _datasource, args);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(_timestamp, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[] memory _argN, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0; // Unexpectedly high price
        }
        bytes memory args = ba2cbor(_argN);
        return provable.queryN_withGasLimit{value: price}(0, _datasource, args, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[1] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[1] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[1] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[2] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[2] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[2] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[3] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[3] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[3] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[4] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[4] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[4] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[5] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs);
    }

    function provable_query(uint _timestamp, string memory _datasource, bytes[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function provable_query(string memory _datasource, bytes[5] memory _args, uint _gasLimit) provableAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return provable_query(_datasource, dynargs, _gasLimit);
    }

    function provable_setProof(byte _proofP) provableAPI internal {
        return provable.setProofType(_proofP);
    }


    function provable_cbAddress() provableAPI internal returns (address _callbackAddress) {
        return provable.cbAddress();
    }

    function getCodeSize(address _addr) view internal returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function provable_setCustomGasPrice(uint _gasPrice) provableAPI internal {
        return provable.setCustomGasPrice(_gasPrice);
    }

    function provable_randomDS_getSessionPubKeyHash() provableAPI internal returns (bytes32 _sessionKeyHash) {
        return provable.randomDS_getSessionPubKeyHash();
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int _returnCode) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
            return -1;
        } else if (h.length > (2 ** 128 - 1)) {
            return -1;
        } else {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i++) {
                if (h[i] == n[0]) {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {
                        subindex++;
                    }
                    if (subindex == n.length) {
                        return int(i);
                    }
                }
            }
            return -1;
        }
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeString(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function provable_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32 _queryId) {
        require((_nbytes > 0) && (_nbytes <= 32));
        _delay *= 10; // Convert from seconds to ledger timer ticks
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(uint8(_nbytes));
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = provable_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            /*
             The following variables can be relaxed.
             Check the relaxed random contract at https://github.com/oraclize/ethereum-examples
             for an idea on how to override and replace commit hash variables.
            */
            mstore(add(unonce, 0x20), xor(blockhash(sub(number(), 1)), xor(coinbase(), timestamp())))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = provable_query("random", args, _customGasLimit);
        bytes memory delay_bytes8_left = new bytes(8);
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))
        }
        provable_randomDS_setCommitment(queryId, keccak256(abi.encodePacked(delay_bytes8_left, args[1], sha256(args[0]), args[2])));
        return queryId;
    }

    function provable_randomDS_setCommitment(bytes32 _queryId, bytes32 _commitment) internal {
        provable_randomDS_args[_queryId] = _commitment;
    }

    function verifySig(bytes32 _tosignh, bytes memory _dersig, bytes memory _pubkey) internal returns (bool _sigVerified) {
        bool sigok;
        address signer;
        bytes32 sigr;
        bytes32 sigs;
        bytes memory sigr_ = new bytes(32);
        uint offset = 4 + (uint(uint8(_dersig[3])) - 0x20);
        sigr_ = copyBytes(_dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(_dersig, offset + (uint(uint8(_dersig[offset - 1])) - 0x20), 32, sigs_, 0);
        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        (sigok, signer) = safer_ecrecover(_tosignh, 27, sigr, sigs);
        if (address(uint160(uint256(keccak256(_pubkey)))) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(_tosignh, 28, sigr, sigs);
            return (address(uint160(uint256(keccak256(_pubkey)))) == signer);
        }
    }

    function provable_randomDS_proofVerify__sessionKeyValidity(bytes memory _proof, uint _sig2offset) internal returns (bool _proofVerified) {
        bool sigok;
        // Random DS Proof Step 6: Verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(uint8(_proof[_sig2offset + 1])) + 2);
        copyBytes(_proof, _sig2offset, sig2.length, sig2, 0);
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(_proof, 3 + 1, 64, appkey1_pubkey, 0);
        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = byte(uint8(1)); //role
        copyBytes(_proof, _sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        if (!sigok) {
            return false;
        }
        // Random DS Proof Step 7: Verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(_proof, 3, 65, tosign3, 1);
        bytes memory sig3 = new bytes(uint(uint8(_proof[3 + 65 + 1])) + 2);
        copyBytes(_proof, 3 + 65, sig3.length, sig3, 0);
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        return sigok;
    }

    function provable_randomDS_proofVerify__returnCode(bytes32 _queryId, string memory _result, bytes memory _proof) internal returns (uint8 _returnCode) {
        // Random DS Proof Step 1: The prefix has to match 'LP\x01' (Ledger Proof version 1)
        if ((_proof[0] != "L") || (_proof[1] != "P") || (uint8(_proof[2]) != uint8(1))) {
            return 1;
        }
        bool proofVerified = provable_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), provable_getNetworkName());
        if (!proofVerified) {
            return 2;
        }
        return 0;
    }

    function matchBytes32Prefix(bytes32 _content, bytes memory _prefix, uint _nRandomBytes) internal pure returns (bool _matchesPrefix) {
        bool match_ = true;
        require(_prefix.length == _nRandomBytes);
        for (uint256 i = 0; i< _nRandomBytes; i++) {
            if (_content[i] != _prefix[i]) {
                match_ = false;
            }
        }
        return match_;
    }

    function provable_randomDS_proofVerify__main(bytes memory _proof, bytes32 _queryId, bytes memory _result, string memory _contextName) internal returns (bool _proofVerified) {
        // Random DS Proof Step 2: The unique keyhash has to match with the sha256 of (context name + _queryId)
        uint ledgerProofLength = 3 + 65 + (uint(uint8(_proof[3 + 65 + 1])) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(_proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(abi.encodePacked(sha256(abi.encodePacked(_contextName, _queryId)))))) {
            return false;
        }
        bytes memory sig1 = new bytes(uint(uint8(_proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1])) + 2);
        copyBytes(_proof, ledgerProofLength + (32 + 8 + 1 + 32), sig1.length, sig1, 0);
        // Random DS Proof Step 3: We assume sig1 is valid (it will be verified during step 5) and we verify if '_result' is the _prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), _result, uint(uint8(_proof[ledgerProofLength + 32 + 8])))) {
            return false;
        }
        // Random DS Proof Step 4: Commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength + 32, 8 + 1 + 32, commitmentSlice1, 0);
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(_proof, sig2offset - 64, 64, sessionPubkey, 0);
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (provable_randomDS_args[_queryId] == keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))) { //unonce, nbytes and sessionKeyHash match
            delete provable_randomDS_args[_queryId];
        } else return false;
        // Random DS Proof Step 5: Validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) {
            return false;
        }
        // Verify if sessionPubkeyHash was verified already, if not.. let's do it!
        if (!provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash]) {
            provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = provable_randomDS_proofVerify__sessionKeyValidity(_proof, sig2offset);
        }
        return provable_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function copyBytes(bytes memory _from, uint _fromOffset, uint _length, bytes memory _to, uint _toOffset) internal pure returns (bytes memory _copiedBytes) {
        uint minLength = _length + _toOffset;
        require(_to.length >= minLength); // Buffer too small. Should be a better way?
        uint i = 32 + _fromOffset; // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
     Duplicate Solidity's ecrecover, but catching the CALL return value
    */
    function safer_ecrecover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal returns (bool _success, address _recoveredAddress) {
        /*
         We do our own memory management here. Solidity uses memory offset
         0x40 to store the current end of memory. We write past it (as
         writes are memory extensions), but don't update the offset so
         Solidity will reuse it. The memory used here is only needed for
         this context.
         FIXME: inline assembly can't access return values
        */
        bool ret;
        address addr;
        assembly {
            let size := mload(0x40)
            mstore(size, _hash)
            mstore(add(size, 32), _v)
            mstore(add(size, 64), _r)
            mstore(add(size, 96), _s)
            ret := call(3000, 1, 0, size, 128, size, 32) // NOTE: we can reuse the request memory because we deal with the return code.
            addr := mload(size)
        }
        return (ret, addr);
    }
    /*
     The following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    */
    function ecrecovery(bytes32 _hash, bytes memory _sig) internal returns (bool _success, address _recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_sig.length != 65) {
            return (false, address(0));
        }
        /*
         The signature format is a compact form of:
           {bytes32 r}{bytes32 s}{uint8 v}
         Compact means, uint8 is not padded to 32 bytes.
        */
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            /*
             Here we are loading the last 32 bytes. We exploit the fact that
             'mload' will pad with zeroes if we overread.
             There is no 'mload8' to do this, but that would be nicer.
            */
            v := byte(0, mload(add(_sig, 96)))
            /*
              Alternative solution:
              'byte' is not working due to the Solidity parser, so lets
              use the second best option, 'and'
              v := and(mload(add(_sig, 65)), 255)
            */
        }
        /*
         albeit non-transactional signatures are not specified by the YP, one would expect it
         to match the YP range of [27, 28]
         geth uses [0, 1] and some clients have followed. This might change, see:
         https://github.com/ethereum/go-ethereum/issues/2053
        */
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (false, address(0));
        }
        return safer_ecrecover(_hash, v, r, s);
    }
}

contract LiquidityTransformer is usingProvable {

    using SafeMathLT for uint256;
    using SafeMathLT for uint128;

    IWiseToken public WISE_CONTRACT;
    UniswapV2Pair public UNISWAP_PAIR;

    UniswapRouterV2 public constant UNISWAP_ROUTER = UniswapRouterV2(
        0xf164fC0Ec4E93095b804a4795bBe1e041497b92a
    );

    RefundSponsorI public constant REFUND_SPONSOR = RefundSponsorI(
        0x1BFd2F71146C08722e40942aC1418147784fa888
    );

    address payable constant TEAM_ADDRESS = 0x29bB844F56352C6735bBc8989b0e483bcFBB3DCC;
    address public TOKEN_DEFINER = 0x29bB844F56352C6735bBc8989b0e483bcFBB3DCC;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint8 constant INVESTMENT_DAYS = 50;

    uint128 constant THRESHOLD_LIMIT_MIN = 1 ether;
    uint128 constant THRESHOLD_LIMIT_MAX = 50 ether;
    uint128 constant TEAM_ETHER_MAX = 2000 ether;
    uint128 constant MIN_INVEST = 50000000 gwei;
    uint128 constant DAILY_MAX_SUPPLY = 10000000;

    uint256 constant YODAS_PER_WISE = 10 ** uint256(18);
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 7;

    struct Globals {
        uint64 generatedDays;
        uint64 generationDayBuffer;
        uint64 generationTimeout;
        uint64 preparedReferrals;
        uint256 totalTransferTokens;
        uint256 totalWeiContributed;
        uint256 totalReferralTokens;
    }

    Globals public g;

    mapping(uint256 => uint256) dailyMinSupply;
    mapping(uint256 => uint256) public dailyTotalSupply;
    mapping(uint256 => uint256) public dailyTotalInvestment;

    mapping(uint256 => uint256) public investorAccountCount;
    mapping(uint256 => mapping(uint256 => address)) public investorAccounts;
    mapping(address => mapping(uint256 => uint256)) public investorBalances;

    mapping(address => uint256) public referralAmount;
    mapping(address => uint256) public referralTokens;
    mapping(address => uint256) public investorTotalBalance;
    mapping(address => uint256) originalInvestment;

    uint256 public referralAccountCount;
    uint256 public uniqueInvestorCount;

    mapping (uint256 => address) public uniqueInvestors;
    mapping (uint256 => address) public referralAccounts;

    event GeneratingRandomSupply(
        uint256 indexed investmentDay
    );

    event GeneratedRandomSupply(
        uint256 indexed investmentDay,
        uint256 randomSupply
    );

    event GeneratedStaticSupply(
        uint256 indexed investmentDay,
        uint256 staticSupply
    );

    event GenerationStatus(
        uint64 indexed investmentDay,
        bool result
    );

    event LogNewProvableQuery(
        string description
    );

    event ReferralAdded(
        address indexed referral,
        address indexed referee,
        uint256 amount
    );

    event UniSwapResult(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    event WiseReservation(
        address indexed sender,
        uint256 indexed investmentDay,
        uint256 amount
    );

    modifier afterInvestmentPhase() {
        require(
            _currentWiseDay() > INVESTMENT_DAYS,
            'WISE: ongoing investment phase'
        );
        _;
    }

    modifier afterUniswapTransfer() {
        require (
            g.generatedDays > 0 &&
            g.totalWeiContributed == 0,
            'WISE: forward liquidity first'
        );
        _;
    }

    modifier investmentDaysRange(uint256 _investmentDay) {
        require(
            _investmentDay > 0 &&
            _investmentDay <= INVESTMENT_DAYS,
            'WISE: not in initial investment days range'
        );
        _;
    }

    modifier investmentEntryAmount(uint256 _days) {
        require(
            msg.value >= MIN_INVEST * _days,
            'WISE: investment below minimum'
        );
        _;
    }

    modifier onlyFundedDays(uint256 _investmentDay) {
        require(
            dailyTotalInvestment[_investmentDay] > 0,
            'WISE: no investments on that day'
        );
        _;
    }

    modifier refundSponsorDynamic() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = (21000 + gasStart - gasleft()).mul(tx.gasprice);
        gasSpent = msg.value.div(10) > gasSpent ? gasSpent : msg.value.div(10);
        REFUND_SPONSOR.addGasRefund(msg.sender, gasSpent);
    }

    modifier refundSponsorFixed() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = (21000 + gasStart - gasleft()).mul(tx.gasprice);
        gasSpent = gasSpent > 5000000000000000 ? 5000000000000000 : gasSpent;
        REFUND_SPONSOR.addGasRefund(msg.sender, gasSpent);
    }

    modifier onlyTokenDefiner() {
        require(
            msg.sender == TOKEN_DEFINER,
            'WISE: wrong sender'
        );
        _;
    }

    receive() external payable {
        require (
            msg.sender == address(UNISWAP_ROUTER) ||
            msg.sender == TEAM_ADDRESS ||
            msg.sender == TOKEN_DEFINER,
            'WISE: direct deposits disabled'
        );
    }

    function defineToken(
        address _wiseToken,
        address _uniswapPair
    )
        external
        onlyTokenDefiner
    {
        WISE_CONTRACT = IWiseToken(_wiseToken);
        UNISWAP_PAIR = UniswapV2Pair(_uniswapPair);
    }

    function revokeAccess()
        external
        onlyTokenDefiner
    {
        TOKEN_DEFINER = address(0x0);
    }

    constructor(address _wiseToken, address _uniswapPair) {

        WISE_CONTRACT = IWiseToken(_wiseToken);
        UNISWAP_PAIR = UniswapV2Pair(_uniswapPair);

        provable_setProof(proofType_Ledger);
        provable_setCustomGasPrice(100000000000);

        dailyMinSupply[1] = 5000000;
        dailyMinSupply[2] = 5000000;
        dailyMinSupply[3] = 5000000;
        dailyMinSupply[4] = 5000000;
        dailyMinSupply[5] = 5000000;
        dailyMinSupply[6] = 5000000;
        dailyMinSupply[7] = 5000000;

        dailyMinSupply[8] = 4500000;
        dailyMinSupply[9] = 5000000;

        dailyMinSupply[10] = 4500000;
        dailyMinSupply[11] = 5000000;
        dailyMinSupply[12] = 1;
        dailyMinSupply[13] = 5000000;
        dailyMinSupply[14] = 4000000;
        dailyMinSupply[15] = 5000000;
        dailyMinSupply[16] = 4000000;
        dailyMinSupply[17] = 4000000;
        dailyMinSupply[18] = 5000000;
        dailyMinSupply[19] = 1;

        dailyMinSupply[20] = 5000000;
        dailyMinSupply[21] = 3500000;
        dailyMinSupply[22] = 5000000;
        dailyMinSupply[23] = 3500000;
        dailyMinSupply[24] = 5000000;
        dailyMinSupply[25] = 3500000;
        dailyMinSupply[26] = 1;
        dailyMinSupply[27] = 5000000;
        dailyMinSupply[28] = 5000000;
        dailyMinSupply[29] = 3000000;

        dailyMinSupply[30] = 5000000;
        dailyMinSupply[31] = 3000000;
        dailyMinSupply[32] = 5000000;
        dailyMinSupply[33] = 1;
        dailyMinSupply[34] = 5000000;
        dailyMinSupply[35] = 2500000;
        dailyMinSupply[36] = 2500000;
        dailyMinSupply[37] = 5000000;
        dailyMinSupply[38] = 2500000;
        dailyMinSupply[39] = 5000000;

        dailyMinSupply[40] = 1;
        dailyMinSupply[41] = 5000000;
        dailyMinSupply[42] = 1;
        dailyMinSupply[43] = 5000000;
        dailyMinSupply[44] = 1;
        dailyMinSupply[45] = 5000000;
        dailyMinSupply[46] = 1;
        dailyMinSupply[47] = 1;
        dailyMinSupply[48] = 1;
        dailyMinSupply[49] = 5000000;
        dailyMinSupply[50] = 5000000;
    }


    //  WISE RESERVATION (EXTERNAL FUNCTIONS)  //
    //  -------------------------------------  //

    /** @dev Performs reservation of WISE tokens with ETH
      * @param _investmentDays array of reservation days.
      * @param _referralAddress referral address for bonus.
      */
    function reserveWise(
        uint8[] calldata _investmentDays,
        address _referralAddress
    )
        external
        payable
        refundSponsorDynamic
        investmentEntryAmount(_investmentDays.length)
    {
        checkInvestmentDays(
            _investmentDays,
            _currentWiseDay()
        );

        _reserveWise(
            _investmentDays,
            _referralAddress,
            msg.sender,
            msg.value
        );
    }

    /** @notice Allows reservation of WISE tokens with other ERC20 tokens
      * @dev this will require LT contract to be approved as spender
      * @param _tokenAddress address of an ERC20 token to use
      * @param _tokenAmount amount of tokens to use for reservation
      * @param _investmentDays array of reservation days
      * @param _referralAddress referral address for bonus
      */
    function reserveWiseWithToken(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint8[] calldata _investmentDays,
        address _referralAddress
    )
        external
        refundSponsorFixed
    {
        IERC20Token _token = IERC20Token(
            _tokenAddress
        );

        _token.transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        _token.approve(
            address(UNISWAP_ROUTER),
            _tokenAmount
        );

        address[] memory _path = preparePath(
            _tokenAddress
        );

        uint256[] memory amounts =
        UNISWAP_ROUTER.swapExactTokensForETH(
            _tokenAmount,
            0,
            _path,
            address(this),
            block.timestamp.add(2 hours)
        );

        require(
            amounts[1] >= MIN_INVEST * _investmentDays.length,
            'WISE: investment below minimum'
        );

        checkInvestmentDays(
            _investmentDays,
            _currentWiseDay()
        );

        _reserveWise(
            _investmentDays,
            _referralAddress,
            msg.sender,
            amounts[1]
        );
    }

    //  WISE RESERVATION (INTERNAL FUNCTIONS)  //
    //  -------------------------------------  //

    /** @notice Distributes ETH equaly between selected reservation days
      * @dev this will require LT contract to be approved as a spender
      * @param _investmentDays array of selected reservation days
      * @param _referralAddress referral address for bonus
      * @param _senderAddress address of the investor
      * @param _senderValue amount of ETH contributed
      */
    function _reserveWise(
        uint8[] memory _investmentDays,
        address _referralAddress,
        address _senderAddress,
        uint256 _senderValue
    )
        internal
    {
        require(
            _senderAddress != _referralAddress,
            'WISE: must be a different address'
        );

        require(
            notContract(_referralAddress),
            'WISE: invalid referral address'
        );

        uint256 _investmentBalance = _referralAddress == address(0x0)
            ? _senderValue // no referral bonus
            : _senderValue.mul(1100).div(1000);

        uint256 _totalDays = _investmentDays.length;
        uint256 _dailyAmount = _investmentBalance.div(_totalDays);
        uint256 _leftOver = _investmentBalance.mod(_totalDays);

        _addBalance(
            _senderAddress,
            _investmentDays[0],
            _dailyAmount.add(_leftOver)
        );

        for (uint8 _i = 1; _i < _totalDays; _i++) {
            _addBalance(
                _senderAddress,
                _investmentDays[_i],
                _dailyAmount
            );
        }

        _trackInvestors(
            _senderAddress,
            _investmentBalance
        );

        if (_referralAddress != address(0x0)) {

            _trackReferrals(_referralAddress, _senderValue);

            emit ReferralAdded(
                _referralAddress,
                _senderAddress,
                _senderValue
            );
        }

        originalInvestment[_senderAddress] += _senderValue;
        g.totalWeiContributed += _senderValue;
    }

    /** @notice Allocates investors balance to specific day
      * @param _senderAddress investors wallet address
      * @param _investmentDay selected investment day
      * @param _investmentBalance amount invested (with bonus)
      */
    function _addBalance(
        address _senderAddress,
        uint256 _investmentDay,
        uint256 _investmentBalance
    )
        internal
    {
        if (investorBalances[_senderAddress][_investmentDay] == 0) {
            investorAccounts[_investmentDay][investorAccountCount[_investmentDay]] = _senderAddress;
            investorAccountCount[_investmentDay]++;
        }

        investorBalances[_senderAddress][_investmentDay] += _investmentBalance;
        dailyTotalInvestment[_investmentDay] += _investmentBalance;

        emit WiseReservation(
            _senderAddress,
            _investmentDay,
            _investmentBalance
        );
    }

    //  WISE RESERVATION (PRIVATE FUNCTIONS)  //
    //  ------------------------------------  //

    /** @notice Tracks investorTotalBalance and uniqueInvestors
      * @dev used in _reserveWise() internal function
      * @param _investorAddress address of the investor
      * @param _value ETH amount invested (with bonus)
      */
    function _trackInvestors(address _investorAddress, uint256 _value) private {
        // if (investorTotalBalance[_investorAddress] == 0) uniqueInvestors.push(_investorAddress);
        if (investorTotalBalance[_investorAddress] == 0) {
            uniqueInvestors[
            uniqueInvestorCount] = _investorAddress;
            uniqueInvestorCount++;
        }
        investorTotalBalance[_investorAddress] += _value;
    }

    /** @notice Tracks referralAmount and referralAccounts
      * @dev used in _reserveWise() internal function
      * @param _referralAddress address of the referrer
      * @param _value ETH amount referred during reservation
      */
    function _trackReferrals(address _referralAddress, uint256 _value) private {
        if (referralAmount[_referralAddress] == 0) {
            referralAccounts[
            referralAccountCount] = _referralAddress;
            referralAccountCount++;
        }
        referralAmount[_referralAddress] += _value;
    }


    //  SUPPLY GENERATION (EXTERNAL FUNCTION)  //
    //  -------------------------------------  //

    /** @notice Allows to generate supply for past funded days
      * @param _investmentDay investemnt day index (1-50)
      */
    function generateSupply(
        uint64 _investmentDay
    )
        external
        investmentDaysRange(_investmentDay)
        onlyFundedDays(_investmentDay)
    {
        require(
            _investmentDay < _currentWiseDay(),
            'WISE: investment day must be in past'
        );

        require(
            g.generationDayBuffer == 0,
            'WISE: supply generation in progress'
        );

        require(
            dailyTotalSupply[_investmentDay] == 0,
            'WISE: supply already generated'
        );

        g.generationDayBuffer = _investmentDay;
        g.generationTimeout = uint64(block.timestamp.add(2 hours));

        DAILY_MAX_SUPPLY - dailyMinSupply[_investmentDay] == dailyMinSupply[_investmentDay]
            ? _generateStaticSupply(_investmentDay)
            : _generateRandomSupply(_investmentDay);
    }


    //  SUPPLY GENERATION (INTERNAL FUNCTIONS)  //
    //  --------------------------------------  //

    /** @notice Generates supply for days with static supply
      * @param _investmentDay investemnt day index (1-50)
      */
    function _generateStaticSupply(
        uint256 _investmentDay
    )
        internal
    {
        dailyTotalSupply[_investmentDay] = dailyMinSupply[_investmentDay] * YODAS_PER_WISE;
        g.totalTransferTokens += dailyTotalSupply[_investmentDay];

        g.generatedDays++;
        g.generationDayBuffer = 0;
        g.generationTimeout = 0;

        emit GeneratedStaticSupply(
            _investmentDay,
            dailyTotalSupply[_investmentDay]
        );
    }

    /** @notice Generates supply for days with random supply
      * @dev uses provable api to request provable_newRandomDSQuery
      * @param _investmentDay investemnt day index (1-50)
      */
    function _generateRandomSupply(
        uint256 _investmentDay
    )
        internal
    {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;
        provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );

        emit GeneratingRandomSupply(_investmentDay);
        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
    }

    //  SUPPLY GENERATION (ORACLE FUNCTIONS)  //
    //  ------------------------------------  //

    /** @notice Function that generates random supply
      * @dev expected to be called by oracle within 2 hours
      * time-frame, otherwise __timeout() can be performed
      */
    function __callback(
        bytes32 _queryId,
        string memory _result,
        bytes memory _proof
    )
        public
        override
    {
        require(
            msg.sender == provable_cbAddress(),
            'WISE: can only be called by Oracle'
        );

        require(
            g.generationDayBuffer > 0 &&
            g.generationDayBuffer <= INVESTMENT_DAYS,
            'WISE: incorrect generation day'
        );

        if (
            provable_randomDS_proofVerify__returnCode(
                _queryId,
                _result,
                _proof
            ) != 0
        ) {

            g.generationDayBuffer = 0;
            g.generationTimeout = 0;

            emit GenerationStatus(
                g.generationDayBuffer, false
            );

        } else {

            g.generatedDays = g.generatedDays + 1;
            uint256 _investmentDay = g.generationDayBuffer;

            uint256 currentDayMaxSupply = DAILY_MAX_SUPPLY.sub(dailyMinSupply[_investmentDay]);
            uint256 ceilingDayMaxSupply = currentDayMaxSupply.sub(dailyMinSupply[_investmentDay]);

            uint256 randomSupply = uint256(
                keccak256(
                    abi.encodePacked(_result)
                )
            ) % ceilingDayMaxSupply;

            require(
                dailyTotalSupply[_investmentDay] == 0,
                'WISE: supply already generated!'
            );

            dailyTotalSupply[_investmentDay] = dailyMinSupply[_investmentDay]
                .add(randomSupply)
                .mul(YODAS_PER_WISE);

            g.totalTransferTokens = g.totalTransferTokens
                .add(dailyTotalSupply[_investmentDay]);

            emit GeneratedRandomSupply(
                _investmentDay,
                dailyTotalSupply[_investmentDay]
            );

            emit GenerationStatus(
                g.generationDayBuffer, true
            );

            g.generationDayBuffer = 0;
            g.generationTimeout = 0;

        }
    }

    /** @notice Allows to reset expected oracle callback
      * @dev resets generationDayBuffer to retry callback
      * assigns static supply if no callback within a day
      */
    function __timeout()
        external
    {
        require(
            g.generationTimeout > 0 &&
            g.generationTimeout < block.timestamp,
            'WISE: still awaiting!'
        );

        uint64 _investmentDay = g.generationDayBuffer;

        require(
            _investmentDay > 0 &&
            _investmentDay <= INVESTMENT_DAYS,
            'WISE: incorrect generation day'
        );

        require(
            dailyTotalSupply[_investmentDay] == 0,
            'WISE: supply already generated!'
        );

        if (_currentWiseDay() - _investmentDay > 1) {

            dailyTotalSupply[_investmentDay] = dailyMinSupply[1]
                .mul(YODAS_PER_WISE);

            g.totalTransferTokens = g.totalTransferTokens
                .add(dailyTotalSupply[_investmentDay]);

            g.generatedDays = g.generatedDays + 1;

            emit GeneratedStaticSupply(
                _investmentDay,
                dailyTotalSupply[_investmentDay]
            );

            emit GenerationStatus(
                _investmentDay, true
            );

        } else {
            emit GenerationStatus(
                _investmentDay, false
            );
        }
        g.generationDayBuffer = 0;
        g.generationTimeout = 0;
    }


    //  PRE-LIQUIDITY GENERATION FUNCTION  //
    //  ---------------------------------  //

    /** @notice Pre-calculates amount of tokens each referrer will get
      * @dev must run this for all referrer addresses in batches
      * converts _referralAmount to _referralTokens based on dailyRatio
      */
    function prepareReferralBonuses(
        uint256 _referralBatchFrom,
        uint256 _referralBatchTo
    )
        external
        afterInvestmentPhase
    {
        require(
            _referralBatchFrom < _referralBatchTo,
            'WISE: incorrect referral batch'
        );

        require (
            g.preparedReferrals < referralAccountCount,
            'WISE: all referrals already prepared'
        );

        uint256 _totalRatio = g.totalTransferTokens.div(g.totalWeiContributed);

        for (uint256 i = _referralBatchFrom; i < _referralBatchTo; i++) {
            address _referralAddress = referralAccounts[i];
            uint256 _referralAmount = referralAmount[_referralAddress];
            if (referralAmount[_referralAddress] > 0) {
                referralAmount[_referralAddress] = 0;
                if (_referralAmount >= THRESHOLD_LIMIT_MIN) {
                    _referralAmount >= THRESHOLD_LIMIT_MAX
                        ? _fullReferralBonus(_referralAddress, _referralAmount, _totalRatio)
                        : _familyReferralBonus(_referralAddress, _totalRatio);

                    g.totalReferralTokens = g.totalReferralTokens.add(
                        referralTokens[_referralAddress]
                    );
                }
                g.preparedReferrals++;
            }
        }
    }

    /** @notice performs token allocation for 10% of referral amount
      * @dev after liquidity is formed referrer can withdraw this amount
      * additionally this will give CM status to the referrer address
      */
    function _fullReferralBonus(address _referralAddress, uint256 _referralAmount, uint256 _ratio) internal {
        referralTokens[_referralAddress] = _referralAmount.div(10).mul(_ratio);
        WISE_CONTRACT.giveStatus(_referralAddress);
    }

    /** @notice performs token allocation for family bonus referrals
      * @dev after liquidity is formed referrer can withdraw this amount
      */
    function _familyReferralBonus(address _referralAddress, uint256 _ratio) internal {
        referralTokens[_referralAddress] = MIN_INVEST.mul(_ratio);
    }


    //  LIQUIDITY GENERATION FUNCTION  //
    //  -----------------------------  //

    /** @notice Creates initial liquidity on Uniswap by forwarding
      * reserved tokens equivalent to ETH contributed to the contract
      * @dev check addLiquidityETH documentation
      */
    function forwardLiquidity(/*🦄*/)
        external
        afterInvestmentPhase
    {
        require(
            g.generatedDays == fundedDays(),
            'WISE: must generate supply for all days'
        );

        require (
            g.preparedReferrals == referralAccountCount,
            'WISE: must prepare all referrals'
        );

        require (
            g.totalTransferTokens > 0,
            'WISE: must have tokens to transfer'
        );

        uint256 _balance = g.totalWeiContributed;
        uint256 _buffer = g.totalTransferTokens + g.totalReferralTokens;

        _balance = _balance.sub(
            _teamContribution(
                _balance.div(10)
            )
        );

        _buffer = _buffer.mul(_balance).div(
            g.totalWeiContributed
        );

        WISE_CONTRACT.mintSupply(
            address(this), _buffer
        );

        WISE_CONTRACT.approve(
            address(UNISWAP_ROUTER), _buffer
        );

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) =

        UNISWAP_ROUTER.addLiquidityETH{value: _balance}(
            address(WISE_CONTRACT),
            _buffer,
            0,
            0,
            address(0x0),
            block.timestamp.add(2 hours)
        );

        g.totalTransferTokens = 0;
        g.totalReferralTokens = 0;
        g.totalWeiContributed = 0;

        emit UniSwapResult(
            amountToken, amountETH, liquidity
        );
    }


    //  WISE TOKEN PAYOUT FUNCTIONS (INDIVIDUAL)  //
    //  ----------------------------------------  //

    /** @notice Allows to mint all the tokens
      * from investor and referrer perspectives
      * @dev can be called after forwardLiquidity()
      */
    function $getMyTokens(/*💰*/)
        external
        afterUniswapTransfer
    {
        payoutInvestorAddress(msg.sender);
        payoutReferralAddress(msg.sender);
    }

    /** @notice Allows to mint tokens for specific investor address
      * @dev aggregades investors tokens across all investment days
      * and uses WISE_CONTRACT instance to mint all the WISE tokens
      * @param _investorAddress requested investor calculation address
      * @return _payout amount minted to the investors address
      */
    function payoutInvestorAddress(
        address _investorAddress
    )
        public
        afterUniswapTransfer
        returns (uint256 _payout)
    {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {
            if (investorBalances[_investorAddress][i] > 0) {
                _payout += investorBalances[_investorAddress][i].mul(
                    _calculateDailyRatio(i)
                ).div(100E18);
                investorBalances[_investorAddress][i] = 0;
            }
        }
        if (_payout > 0) {
            WISE_CONTRACT.mintSupply(
                _investorAddress,
                _payout
            );
        }
    }

    /** @notice Allows to mint tokens for specific referrer address
      * @dev must be pre-calculated in prepareReferralBonuses()
      * @param _referralAddress referrer payout address
      * @return _referralTokens amount minted to the referrer address
      */
    function payoutReferralAddress(
        address _referralAddress
    ) public
        afterUniswapTransfer
        returns (uint256 _referralTokens)
    {
        _referralTokens = referralTokens[_referralAddress];
        if (referralTokens[_referralAddress] > 0) {
            referralTokens[_referralAddress] = 0;
            WISE_CONTRACT.mintSupply(
                _referralAddress,
                _referralTokens
            );
        }
    }

    //  WISE TOKEN PAYOUT FUNCTIONS (BATCHES)  //
    //  -------------------------------------  //

    /** @notice Allows to mint tokens for specific investment day
      * recommended batch size is up to 50 addresses per call
      * @param _investmentDay processing investment day
      * @param _investorBatchFrom batch starting index
      * @param _investorBatchTo bach finishing index
      */
    function payoutInvestmentDayBatch(
        uint256 _investmentDay,
        uint256 _investorBatchFrom,
        uint256 _investorBatchTo
    )
        external
        afterUniswapTransfer
        onlyFundedDays(_investmentDay)
    {
        require(
            _investorBatchFrom < _investorBatchTo,
            'WISE: incorrect investment batch'
        );

        uint256 _dailyRatio = _calculateDailyRatio(_investmentDay);

        for (uint256 i = _investorBatchFrom; i < _investorBatchTo; i++) {
            address _investor = investorAccounts[_investmentDay][i];
            uint256 _balance = investorBalances[_investor][_investmentDay];
            uint256 _payout = _balance.mul(_dailyRatio).div(100E18);

            if (investorBalances[_investor][_investmentDay] > 0) {
                investorBalances[_investor][_investmentDay] = 0;
                WISE_CONTRACT.mintSupply(
                    _investor,
                    _payout
                );
            }
        }
    }

    /** @notice Allows to mint tokens for referrers in batches
      * @dev can be called right after forwardLiquidity()
      * recommended batch size is up to 50 addresses per call
      * @param _referralBatchFrom batch starting index
      * @param _referralBatchTo bach finishing index
      */
    function payoutReferralBatch(
        uint256 _referralBatchFrom,
        uint256 _referralBatchTo
    )
        external
        afterUniswapTransfer
    {
        require(
            _referralBatchFrom < _referralBatchTo,
            'WISE: incorrect referral batch'
        );

        for (uint256 i = _referralBatchFrom; i < _referralBatchTo; i++) {
            address _referralAddress = referralAccounts[i];
            uint256 _referralTokens = referralTokens[_referralAddress];
            if (referralTokens[_referralAddress] > 0) {
                referralTokens[_referralAddress] = 0;
                WISE_CONTRACT.mintSupply(
                    _referralAddress,
                    _referralTokens
                );
            }
        }
    }

    //  INFO VIEW FUNCTIONS (PERSONAL)  //
    //  ------------------------------  //

    /** @notice checks for callers investment amount on specific day (with bonus)
      * @return total amount invested across all investment days (with bonus)
      */
    function myInvestmentAmount(uint256 _investmentDay) external view returns (uint256) {
        return investorBalances[msg.sender][_investmentDay];
    }

    /** @notice checks for callers investment amount on each day (with bonus)
      * @return _myAllDays total amount invested across all days (with bonus)
      */
    function myInvestmentAmountAllDays() external view returns (uint256[51] memory _myAllDays) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _myAllDays[i] = investorBalances[msg.sender][i];
        }
    }

    /** @notice checks for callers total investment amount (with bonus)
      * @return total amount invested across all investment days (with bonus)
      */
    function myTotalInvestmentAmount() external view returns (uint256) {
        return investorTotalBalance[msg.sender];
    }


    //  INFO VIEW FUNCTIONS (GLOBAL)  //
    //  ----------------------------  //

    /** @notice checks for investors count on specific day
      * @return investors count for specific day
      */
    function investorsOnDay(uint256 _investmentDay) public view returns (uint256) {
        return dailyTotalInvestment[_investmentDay] > 0 ? investorAccountCount[_investmentDay] : 0;
    }

    /** @notice checks for investors count on each day
      * @return _allInvestors array with investors count for each day
      */
    function investorsOnAllDays() external view returns (uint256[51] memory _allInvestors) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestors[i] = investorsOnDay(i);
        }
    }

    /** @notice checks for investment amount on each day
      * @return _allInvestments array with investment amount for each day
      */
    function investmentsOnAllDays() external view returns (uint256[51] memory _allInvestments) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestments[i] = dailyTotalInvestment[i];
        }
    }

    /** @notice checks for supply amount on each day
      * @return _allSupply array with supply amount for each day
      */
    function supplyOnAllDays() external view returns (uint256[51] memory _allSupply) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allSupply[i] = dailyTotalSupply[i];
        }
    }


    //  HELPER FUNCTIONS (PURE)  //
    //  -----------------------  //

    /** @notice checks that provided days are valid for investemnt
      * @dev used in reserveWise() and reserveWiseWithToken()
      */
    function checkInvestmentDays(
        uint8[] memory _investmentDays,
        uint64 _currentWiseDay
    ) internal pure {
        for (uint8 _i = 0; _i < _investmentDays.length; _i++) {
            require(
                _investmentDays[_i] >= _currentWiseDay,
                'WISE: investment day already passed'
            );
            require(
                _investmentDays[_i] > 0 &&
                _investmentDays[_i] <= INVESTMENT_DAYS,
                'WISE: incorrect investment day'
            );
        }
    }

    /** @notice prepares path variable for uniswap to exchange tokens
      * @dev used in reserveWiseWithToken() swapExactTokensForETH call
      * @param _tokenAddress ERC20 token address to be swapped for ETH
      * @return _path that is used to swap tokens for ETH on uniswap
      */
    function preparePath(
        address _tokenAddress
    ) internal pure returns (
        address[] memory _path
    ) {
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = WETH;
    }

    /** @notice keeps team contribution at caped level
      * @dev subtracts amount during forwardLiquidity()
      * @return ETH amount the team is allowed to withdraw
      */
    function _teamContribution(
        uint256 _teamAmount
    ) internal pure returns (uint256) {
        return _teamAmount > TEAM_ETHER_MAX ? TEAM_ETHER_MAX : _teamAmount;
    }

    /** @notice checks for invesments on all days
      * @dev used in forwardLiquidity() requirements
      * @return $fundedDays - amount of funded days 0-50
      */
    function fundedDays() public view returns (
        uint8 $fundedDays
    ) {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {
            if (dailyTotalInvestment[i] > 0) $fundedDays++;
        }
    }

    /** @notice WISE equivalent in ETH price calculation
      * @dev returned value has 100E18 precision - divided later on
      * @return token price for specific day based on total investement
      */
    function _calculateDailyRatio(
        uint256 _investmentDay
    ) internal view returns (uint256) {

        uint256 dailyRatio = dailyTotalSupply[_investmentDay].mul(100E18)
            .div(dailyTotalInvestment[_investmentDay]);

        uint256 remainderCheck = dailyTotalSupply[_investmentDay].mul(100E18)
            .mod(dailyTotalInvestment[_investmentDay]);

        return remainderCheck == 0 ? dailyRatio : dailyRatio.add(1);
    }

    //  TIMING FUNCTIONS  //
    //  ----------------  //

    /** @notice shows current day of WiseToken
      * @dev value is fetched from WISE_CONTRACT
      * @return iteration day since WISE inception
      */
    function _currentWiseDay() public view returns (uint64) {
        return WISE_CONTRACT.currentWiseDay();
    }

    //  EMERGENCY REFUND FUNCTIONS  //
    //  --------------------------  //

    /** @notice allows refunds if funds are stuck
      * @param _investor address to be refunded
      * @return _amount refunded to the investor
      */
    function requestRefund(
        address payable _investor,
        address payable _succesor
    ) external returns (
        uint256 _amount
    ) {
        require(
            g.totalWeiContributed > 0  &&
            originalInvestment[_investor] > 0 &&
            _currentWiseDay() > INVESTMENT_DAYS + 10,
           unicode'WISE: liquidity successfully forwarded to uniswap 🦄'
        );

        // refunds the investor
        _amount = originalInvestment[_investor];
        originalInvestment[_investor] = 0;
        _succesor.transfer(_amount);

        // deny possible comeback
        g.totalTransferTokens = 0;
    }

    /** @notice allows to withdraw team funds for the work
      * strictly only after the uniswap liquidity is formed
      * @param _amount value to withdraw from the contract
      */
    function requestTeamFunds(
        uint256 _amount
    )
        external
        afterUniswapTransfer
    {
        TEAM_ADDRESS.transfer(_amount);
    }

    function notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }

}

library SafeMathLT {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'WISE: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'WISE: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'WISE: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'WISE: division by zero');
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'WISE: modulo by zero');
        return a % b;
    }
}

library Buffer {

    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory _buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity; // Allocate space for the buffer data
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint _a, uint _b) private pure returns (uint _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }
    /**
      * @dev Appends a byte array to the end of the buffer. Resizes if doing so
      *      would exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return _buffer The original buffer.
      *
      */
    function append(buffer memory _buf, bytes memory _data) internal pure returns (buffer memory _buffer) {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint dest;
        uint src;
        uint len = _data.length;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            dest := add(add(bufptr, buflen), 32) // Start address = buffer address + buffer length + sizeof(buffer length)
            mstore(bufptr, add(buflen, mload(_data))) // Update buffer length
            src := add(_data, 32)
        }
        for(; len >= 32; len -= 32) { // Copy word-length chunks while possible
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint mask = 256 ** (32 - len) - 1; // Copy remaining bytes
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return _buf;
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      *
      */
    function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), 32) // Address = buffer address + buffer length + sizeof(buffer length)
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1)) // Update buffer length
        }
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return _buffer The original buffer.
      *
      */
    function appendInt(buffer memory _buf, uint _data, uint _len) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint mask = 256 ** _len - 1;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), _len) // Address = buffer address + buffer length + sizeof(buffer length) + len
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len)) // Update buffer length
        }
        return _buf;
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory _buf, uint8 _major, uint _value) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major) private pure {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}