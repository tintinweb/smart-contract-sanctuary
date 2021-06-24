//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;

//pragma experimental ABIEncoderV2;
import "Ownable.sol";
import "ccTokenControllerIf.sol";
import "MintFactoryIfView.sol";
import "CanReclaimToken.sol";

/// @title MintFactory
contract MintFactory is Ownable, MintFactoryIfView, CanReclaimToken {
    function getStatusString(RequestStatus status) internal pure returns (string memory) {
        if (status == RequestStatus.PENDING) {
            return "pending";
        } else if (status == RequestStatus.CANCELED) {
            return "canceled";
        } else if (status == RequestStatus.APPROVED) {
            return "approved";
        } else if (status == RequestStatus.REJECTED) {
            return "rejected";
        } else {
            // unreachable.
            return "unknown";
        }
    }

    function getMintRequest(uint seq) override
    external
    view
    returns (
        uint requestSeq,
        address requester,
        uint amount,
        string memory btcAddress,
        string memory btcTxId,
        uint requestBlockNo,
        uint confirmedBlockNo,
        string  memory status,
        bytes32 requestHash
    )
    {
        require(seq > 0, "seq from 1");
        require(seq < mintRequests.length, "invalid seq");
        Request memory request = mintRequests[seq];
        string memory statusString = getStatusString(request.status);

        requestSeq = seq;
        requester = request.requester;
        amount = request.amount;
        btcAddress = request.btcAddress;
        btcTxId = request.btcTxId;
        requestBlockNo = request.requestBlockNo;
        confirmedBlockNo = request.confirmedBlockNo;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getMintRequestsLength() override external view returns (uint length) {
        return mintRequests.length;
    }

    function getBurnRequest(uint seq) override
    external
    view
    returns (
        uint requestSeq,
        address requester,
        uint amount,
        string memory btcAddress,
        string memory btcTxId,
        uint requestBlockNo,
        uint confirmedBlockNo,
        string  memory status,
        bytes32 requestHash
    )
    {
        require(seq > 0, "seq from 1");
        require(seq < burnRequests.length, "invalid seq");
        Request storage request = burnRequests[seq];
        string memory statusString = getStatusString(request.status);

        requestSeq = seq;
        requester = request.requester;
        amount = request.amount;
        btcAddress = request.btcAddress;
        btcTxId = request.btcTxId;
        requestBlockNo = request.requestBlockNo;
        confirmedBlockNo = request.confirmedBlockNo;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getBurnRequestsLength() override external view returns (uint length) {
        return burnRequests.length;
    }

    constructor() {
        controller = (ccTokenControllerIf)(owner);

        Request memory request = Request({
            requester : (address)(0),
            amount : 0,
            btcAddress : "invalid.address",
            btcTxId : "invalid.tx",
            seq : 0,
            requestBlockNo : 0,
            confirmedBlockNo : 0,
            status : RequestStatus.REJECTED
            });

        mintRequests.push(request);
        burnRequests.push(request);
    }

    modifier onlyMerchant() {
        controller.requireMerchant(msg.sender);
        _;
    }

    modifier onlyCustodian() {
        controller.requireCustodian(msg.sender);
        _;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        }
        for (uint i = 0; i < bytes(a).length; i ++) {
            if (bytes(a)[i] != bytes(b)[i]) {
                return false;
            }
        }
        return true;
    }

    function isEmptyString(string memory a) internal pure returns (bool) {
        return (compareStrings(a, ""));
    }

    event CustodianBtcAddressForMerchantSet(address indexed merchant,
        address indexed sender,
        string btcDepositAddress);

    function setCustodianBtcAddressForMerchant(
        address merchant,
        string  memory btcAddress
    )
    external
    onlyCustodian
    returns (bool)
    {
        require((address)(merchant) != address(0), "invalid merchant address");
        controller.requireMerchant(merchant);
        require(!isEmptyString(btcAddress), "invalid btc address");

        custodianBtcAddressForMerchant[merchant] = btcAddress;
        emit CustodianBtcAddressForMerchantSet(merchant, msg.sender, btcAddress);
        return true;
    }

    event BtcDepositAddressOfMerchantSet(address indexed merchant,
        string btcDepositAddress);

    function setMerchantBtcDepositAddress(string  memory btcAddress)
    external
    onlyMerchant
    returns (bool) {
        require(!isEmptyString(btcAddress), "invalid btc address");

        btcDepositAddressOfMerchant[msg.sender] = btcAddress;
        emit BtcDepositAddressOfMerchantSet(msg.sender, btcAddress);
        return true;
    }

    event NewMintRequest(
        uint indexed seq,
        address indexed requester,
        string btcAddress,
        string btcTxId,
        uint blockNo,
        bytes32 requestHash
    );

    function requestMint(
        uint amount,
        string memory btcTxId
    )
    external
    onlyMerchant
    returns (bool)
    {
        require(!isEmptyString(btcTxId), "invalid btcTxId");
        require(!isEmptyString(custodianBtcAddressForMerchant[msg.sender]), "invalid btc deposit address");

        uint seq = mintRequests.length;
        uint blockNo = block.number;

        Request memory request = Request({
            requester : msg.sender,
            amount : amount,
            btcAddress : custodianBtcAddressForMerchant[msg.sender],
            btcTxId : btcTxId,
            seq : seq,
            requestBlockNo : blockNo,
            confirmedBlockNo : 0,
            status : RequestStatus.PENDING
            });

        bytes32 requestHash = calcRequestHash(request);
        mintRequestSeqMap[requestHash] = seq;
        mintRequests.push(request);

        emit NewMintRequest(seq, msg.sender, request.btcAddress, btcTxId, blockNo, requestHash);
        return true;
    }

    function calcRequestHash(Request memory request) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                request.requester,
                request.btcAddress,
                request.btcTxId,
                request.seq,
                request.requestBlockNo
            ));
    }

    event MintRequestCancel(uint indexed seq, address indexed requester, bytes32 requestHash);

    function getPendingMintRequest(bytes32 _requestHash) view private returns (Request memory) {
        uint seq = mintRequestSeqMap[_requestHash];
        require(mintRequests.length > seq, "invalid seq");
        require(seq > 0, "invalid requestHash");
        Request memory request = mintRequests[seq];
        require(request.status == RequestStatus.PENDING, "status not pending.");
        require(_requestHash == calcRequestHash(request), "invalid hash");

        return request;
    }

    function getPendingMintRequestV(bytes32 _requestHash) override view public returns (
        uint requestSeq,
        address requester,
        uint amount,
        string memory btcAddress,
        string memory btcTxId,
        uint requestBlockNo,
        uint confirmedBlockNo,
        string  memory status) {
        Request memory request = getPendingMintRequest(_requestHash);

        requestSeq = request.seq;
        requester = request.requester;
        amount = request.amount;
        btcAddress = request.btcAddress;
        btcTxId = request.btcTxId;
        requestBlockNo = request.requestBlockNo;
        confirmedBlockNo = request.confirmedBlockNo;
        status = getStatusString(request.status);
    }


    function cancelMintRequest(bytes32 requestHash) external onlyMerchant returns (bool) {
        Request memory request = getPendingMintRequest(requestHash);
        uint seq = request.seq;
        require(msg.sender == request.requester, "cancel sender is different than pending request initiator");

        mintRequests[seq].status = RequestStatus.CANCELED;

        emit MintRequestCancel(request.seq, msg.sender, calcRequestHash(request));
        return true;
    }

    event MintConfirmed(
        uint indexed seq,
        address indexed requester,
        uint amount,
        string btcDepositAddress,
        string btcTxid,
        uint blockNo,
        bytes32 requestHash
    );

    function confirmMintRequest(bytes32 requestHash) external onlyCustodian returns (bool) {
        uint blockNo = block.number;
        Request memory request = getPendingMintRequest(requestHash);
        require(blockNo > request.requestBlockNo, "confirmMintRequest failed");

        require(blockNo - 20 >= request.requestBlockNo, "confirmMintRequest failed, wait for 20 blocks");
        uint seq = request.seq;
        mintRequests[seq].status = RequestStatus.APPROVED;
        uint amount = mintRequests[seq].amount;
        mintRequests[seq].confirmedBlockNo = blockNo;

        require(controller.mint(request.requester, amount), "mint failed");
        emit MintConfirmed(
            request.seq,
            request.requester,
            amount,
            request.btcAddress,
            request.btcTxId,
            blockNo,
            calcRequestHash(request)
        );
        return true;
    }

    event MintRejected(
        uint indexed seq,
        address indexed requester,
        uint amount,
        string btcDepositAddress,
        string btcTxid,
        uint blockNo,
        bytes32 requestHash
    );

    function rejectMintRequest(bytes32 requestHash) external onlyCustodian returns (bool) {
        Request memory request = getPendingMintRequest(requestHash);
        uint seq = request.seq;

        mintRequests[seq].status = RequestStatus.REJECTED;
        uint blockNo = block.number;
        mintRequests[seq].confirmedBlockNo = blockNo;

        emit MintRejected(
            request.seq,
            request.requester,
            request.amount,
            request.btcAddress,
            request.btcTxId,
            blockNo,
            calcRequestHash(request)
        );
        return true;
    }

    event Burned(
        uint indexed seq,
        address indexed requester,
        uint amount,
        string btcAddress,
        uint blockNo,
        bytes32 requestHash
    );

    function burn(uint amount) external onlyMerchant returns (bool) {
        string memory btcDepositAddress = btcDepositAddressOfMerchant[msg.sender];
        require(!isEmptyString(btcDepositAddress), "merchant btc deposit address was not set");

        uint seq = burnRequests.length;
        uint blockNo = block.number;

        Request memory request = Request({
            requester : msg.sender,
            amount : amount,
            btcAddress : btcDepositAddress,
            btcTxId : "",
            seq : seq,
            requestBlockNo : blockNo,
            confirmedBlockNo : 0,
            status : RequestStatus.PENDING
            });

        bytes32 requestHash = calcRequestHash(request);
        burnRequestSeqMap[requestHash] = seq;
        burnRequests.push(request);

        require(controller.getToken().transferFrom(msg.sender, (address)(controller), amount), "trasnfer tokens to burn failed");
        require(controller.burn(amount), "burn failed");

        emit Burned(seq, msg.sender, amount, btcDepositAddress, blockNo, requestHash);
        return true;
    }

    event BurnConfirmed(
        uint indexed seq,
        address indexed requester,
        uint amount,
        string btcAddress,
        string btcTxId,
        uint blockNo
    );

    function confirmBurnRequest(bytes32 requestHash, string memory btcTxId) external onlyCustodian returns (bool) {
        uint seq = burnRequestSeqMap[requestHash];
        require(burnRequests.length > seq, "invalid seq");
        require(seq > 0, "invalid requestHash");
        Request memory request = burnRequests[seq];
        require(requestHash == calcRequestHash(request), "invalid requestHash");
        require(request.status == RequestStatus.PENDING, "status not pending.");

        burnRequests[seq].btcTxId = btcTxId;
        burnRequests[seq].status = RequestStatus.APPROVED;
        uint blockNo = block.number;
        burnRequests[seq].confirmedBlockNo = blockNo;
        request.btcTxId = btcTxId;
        burnRequestSeqMap[calcRequestHash(request)] = seq;

        emit BurnConfirmed(
            request.seq,
            request.requester,
            request.amount,
            request.btcAddress,
            btcTxId,
            blockNo
        );
        return true;
    }
}