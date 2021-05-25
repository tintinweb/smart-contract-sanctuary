/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.6.12;

contract Test {
    uint16 private constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
        4 + // function selector
            32 + // word containing start location of abiencoded _report value
            32 + // word containing location start of abiencoded  _rs value
            32 + // word containing start location of abiencoded _ss value
            32 + // _rawVs value
            32 + // word containing length of _report
            32 + // word containing length _rs
            32 + // word containing length of _ss
            0; // placeholder

    // Used to relieve stack pressure in transmit
    struct ReportData {
        HotVars hotVars; // Only read from storage once
        bytes observers; // ith element is the index of the ith observer
        int192[] observations; // ith element is the ith observation
        bytes vs; // jth element is the v component of the jth signature
        bytes32 rawReportContext;
    }

    struct HotVars {
        bytes16 latestConfigDigest;
        // 32 most sig bits for epoch, 8 least sig bits for round
        // Current bound assumed on number of faulty/dishonest oracles participating
        // in the protocol, this value is referred to as f in the design
        uint40 latestEpochAndRound;
        uint8 threshold;
        uint32 latestAggregatorRoundId;
    }

    HotVars public s_hotVars;

    bytes public bytes32v;

    bytes public array192v;

    constructor() public {
        s_hotVars = HotVars({
            latestConfigDigest: bytes16(uint128(0x1234)),
            latestEpochAndRound: 1,
            threshold: 32,
            latestAggregatorRoundId: 100
        });
    }

    function expectedMsgDataLength(
        bytes calldata _report,
        bytes32[] calldata _rs,
        bytes32[] calldata _ss
    ) private pure returns (uint256 length) {
        // calldata will never be big enough to make this overflow
        return
            uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
            _report.length + // one byte pure entry in _report
            _rs.length *
            32 + // 32 bytes per entry in _rs
            _ss.length *
            32 + // 32 bytes per entry in _ss
            0; // placeholder d
    }

    bytes public report;

    function generate(
        bytes32 a,
        bytes32 b,
        int192[] memory c
    ) public {
        report = abi.encode(a, b, c);
    }

    function calSha256(bytes calldata data) public view returns (bytes32) {
        return sha256(data);
    }

    function generateBytes32(bytes32 a) public {
        bytes32v = abi.encode("bytes32", a);
    }

    function decodeBytes32(bytes calldata data) public view returns (bytes32) {
        return abi.decode(data, (bytes32));
    }

    function generateint192(int192[] memory c) public {
        array192v = abi.encode("int192[]", c);
    }

    function decodeReport(bytes calldata _report)
        public
        view
        returns (
            bytes32 a,
            bytes32 b,
            int192[] memory c
        )
    {
        //require(false, "get here");
        (a, b, c) = abi.decode(_report, (bytes32, bytes32, int192[]));
    }

    function decodeReport2(bytes calldata _report)
        public
        view
        returns (
            bytes16 configDigest,
            uint64 roundId,
            uint8 observerCount,
            uint8 validBytesCount,
            bytes32 rawObservers,
            bytes32 observation
        )
    {
        bytes32 rawReportContext;
        (rawReportContext, rawObservers, observation) = abi.decode(
            _report,
            (bytes32, bytes32, bytes32)
        );

        // rawReportContext consists of:
        // 6-byte zero padding
        // 16-byte configDigest
        // 8-byte round id
        // 1-byte observer count
        // 1-byte valid byte count (answer)

        configDigest = bytes16(rawReportContext << 48);
        roundId = uint64(bytes8(rawReportContext << 176));
        observerCount = uint8(bytes1(rawReportContext << 240));
        validBytesCount = uint8(uint256(rawReportContext));
    }

    function decodeReport3(bytes calldata _report)
        public
        view
        returns (
            uint8 dataCount, bytes32[] memory data
        ) {
      
      bytes32 a;
      bytes32 b;
      (a, b, data) = abi.decode(
            _report,
            (bytes32, bytes32, bytes32[])
        );
      dataCount = uint8(uint256(a));
    }

    function decodeReport4(bytes calldata _report)
    public
    view
    returns (
        uint8 _count,
        uint8 _validBytesCount,
        bytes32 _observerCount,
        bytes32 _aggregateData,
        uint8[] memory _observerOrder,
        uint8[] memory _observationsLength,
        bytes32[] memory _observations
    ) {
      
      bytes32 configDigest;
      bytes32 observerIndex;
      bytes32 observerCount;
      bytes32 aggregateData;
      bytes32 observerOrder;
      bytes32 observationsLength;
      bytes32[] memory observations;
      (configDigest, observerIndex, observerCount, aggregateData, observerOrder, observationsLength, observations) = abi.decode(
            _report,
            (bytes32, bytes32, bytes32, bytes32, bytes32, bytes32, bytes32[])
        );
      _observerCount = observerCount;
      _count = uint8(bytes1(configDigest << 240));
      _validBytesCount = uint8(uint256(configDigest));
      _aggregateData = aggregateData;
      _observerOrder = new uint8[](observations.length);
      _observationsLength = new uint8[](observations.length);
      for(uint i = 0; i < observations.length; i ++){
          _observerOrder[i] = uint8(observerOrder[i]);
          _observationsLength[i] = uint8(observationsLength[i]);
      }
      _observations = observations;
    }

    address public publicKey;
    bytes32 public reportHash;

    function verifySign(
        bytes calldata _report,
        bytes32 _rs,
        bytes32 _ss,
        uint8 _rawVs
    ) public {
        string memory prefix = "\x19Ethereum Signed Message:\n";
        string memory length = uint2str(_report.length);
        //bytes32 h = keccak256(_report);
        prefix = concatenate(prefix, length);
        string memory data = string(_report);
        prefix = concatenate(prefix, data);
        bytes32 h = keccak256(bytes(prefix));
        publicKey = ecrecover(h, _rawVs, _rs, _ss);
    }

    function verifySign2(
        bytes calldata _report,
        bytes32 _rs,
        bytes32 _ss,
        uint8 _rawVs
    ) public {
        reportHash = keccak256(_report);
        publicKey = ecrecover(reportHash, _rawVs, _rs, _ss);
    }

    function verifySign3(
        bytes calldata _report,
        bytes32 _rs,
        bytes32 _ss,
        uint8 _rawVs
    ) public {
        reportHash = keccak256(_report);
        reportHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", reportHash)
        );
        publicKey = ecrecover(reportHash, _rawVs, _rs, _ss);
    }

    string public testStr;

    function concCat(uint256 i) public {
        string memory length = uint2str(i);
        string memory prefix = "\x19Ethereum Signed Message:\n";
        testStr = concatenate(prefix, length);
    }

    function concatenate(string memory a, string memory b)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function recoverAddress(
        bytes32 hash,
        bytes1 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(hash, uint8(v) + 27, r, s);
    }

    function getShaHash(bytes calldata _report) public view returns (bytes32) {
        bytes32 h = sha256(_report);
        return h;
    }

    function getKcakHash(bytes calldata _report) public view returns (bytes32) {
        bytes32 h = keccak256(_report);
        return h;
    }

    function getGweiAmount() public view returns (uint256){
      return (1 gwei);
    }

    function getGasPrice() public view returns (uint256) {
      return tx.gasprice;
    }

    function getString(string calldata stringBytes, uint8 validBytes) public view returns(string memory){
        bytes memory validString = substr(bytes(stringBytes), 0, validBytes);
        return string(validString);
    }

    function getStringFromBytes(bytes memory stringbytes) public view returns(string memory){
        string memory bar = string(abi.encodePacked(stringbytes));
        return bar;
    }

    // Size of a word, in bytes.
    uint internal constant WORD_SIZE = 32;

    // Copies 'len' bytes from 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that:
    //  - 'startIndex + len <= self.length'
    // The length of the substring is: 'len'
    function substr(bytes memory self, uint startIndex, uint len) internal pure returns (bytes memory) {
        require(startIndex + len <= self.length);
        if (len == 0) {
            return new bytes(0);
        }
        uint256 addr = dataPtr(self);
        return toBytes(addr + startIndex, len);
    }

    // Returns a memory pointer to the data portion of the provided bytes array.
    function dataPtr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        copy(addr, btsptr, len);
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(uint src, uint dest, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function concatString(string memory a, string memory b, string memory c) public view returns (string memory ret){
        ret = string(abi.encodePacked(a, ";", b));
        ret = string(abi.encodePacked(ret, ";", c));
    }

    function concatString2(bytes32 a, bytes32 b, bytes32 c) public view returns (string memory ret){
        ret = string(abi.encodePacked(a));
        ret = string(abi.encodePacked(ret, ';', b));
        ret = string(abi.encodePacked(ret, ";", c));
    }

    function concatBytes(bytes32 a, bytes32 b, bytes32 c) public view returns (bytes memory ret){
        string memory retStr = string(abi.encodePacked(a));
        retStr = string(abi.encodePacked(retStr, ";", b));
        retStr = string(abi.encodePacked(retStr, ";", c));
        ret = bytes(retStr);
    }

    function getIndexAndTringAnswer(bytes32 a, bytes32 b, bytes32 c) public view returns (uint8[] memory index, string memory ret){
        ret = string(abi.encodePacked(a));
        ret = string(abi.encodePacked(ret, ';', b));
        ret = string(abi.encodePacked(ret, ";", c));
        index = new uint8[](3);
        index[0] = 0;
        index[1] = 1;
        index[2] = 2;
    }
}