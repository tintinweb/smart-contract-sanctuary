/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract Parallel1155 {
  function safeBatchTransferFrom ( address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data ) virtual external;
  function safeTransferFrom ( address _from, address _to, uint256 _id, uint256 _value, bytes memory _data ) virtual external;
}


contract ParallelNftFaucet {
    Parallel1155 nftContract;

    address public contractOwner;
    address public trustedSigner = 0x862968878152A851fE3e61F59A14bb563697cCe7;
    string ticketPhrase = "parallel faucet v1";
    address public nftContractAddress = 0x1eAfa9A30575320874d0b1655Dcc76E7474663c0;
    address public pullNftsFromAddress = 0x8C4dA1776D27e7C15d7B0AE9a66B233c606D2695;
    uint16 public maxBlockWait = 500;

//    uint16[20] public enabledNfts = [1,2];
    mapping (uint32 => bool) enabledNfts;

    uint16 public maxNftsPerUser = 1;
    uint32 public currentBonusCard = 3;

    // Struct to store user info
//    struct DepositInfo {
//        uint totalNftsReceived;
//    }
    // event PaymentReceived(uint indexed _who, uint _value, uint _timestamp);
    // event Withdrawal(address indexed _withdrawalAddress, uint _value, uint _timestamp);
    // mapping of user info indexed by the user ID
//    mapping (address => DepositInfo) depositInfo;
    mapping (address => uint) addressInfo;

    constructor()  public {
        contractOwner = msg.sender;
        nftContract = Parallel1155(nftContractAddress);
    }
    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    function addressLookup(address _userAddress) public view returns (uint){
//        return (depositInfo[_userAddress].totalNftsReceived);
        return (addressInfo[_userAddress]);
    }

    function getNftEnabled(uint32 _nftId) public returns (bool){
        return enabledNfts[_nftId];
    }
    function setNftEnabled(uint32 _nftId, bool _enabled) public onlyOwner{
        enabledNfts[_nftId]=_enabled;
    }
    function setMaxBlockWait(uint8 _delay) public onlyOwner{
        maxBlockWait=_delay;
    }
    function setNftContractAddress(address _newAddr) public onlyOwner {
        nftContractAddress = _newAddr;
        nftContract = Parallel1155(nftContractAddress);
    }
    function setMaxNftsPerUser(uint16 _max) public onlyOwner {
        maxNftsPerUser = _max;
    }
    function setTrustedSigner(address _signer) public onlyOwner {
        trustedSigner = _signer;
    }
    function setCurrentBonusCard(uint32 _id) public onlyOwner {
        currentBonusCard = _id;
    }
    function setPullNftsFromAddress(address _pullFrom) public onlyOwner {
        pullNftsFromAddress = _pullFrom;
    }
    function setOwner(address _newOwner) public onlyOwner {
        contractOwner = _newOwner;
    }
    function setTicketPhrase(string memory _phrase) public onlyOwner {
        ticketPhrase = _phrase;
    }
//    function getBlockNumber() public {
//        block.number;
//    }

    function requestNft(bytes memory _ticket, uint32 _nftId, uint _ticketBlock) public {
//        require(depositInfo[msg.sender].totalNftsReceived < maxNftsPerUser, "max bonus received");
        //        require(enabledNfts[_nftId] == true, "nft not enabled");
        require(addressInfo[msg.sender] < maxNftsPerUser, "max bonus received");

        require(block.number >= _ticketBlock, "invalid ticket block");
        require(block.number - _ticketBlock < maxBlockWait, "ticket has expired");

        require(verify(trustedSigner, msg.sender, _nftId, 1, ticketPhrase, _ticketBlock, _ticket));

//        depositInfo[msg.sender].totalNftsReceived = depositInfo[msg.sender].totalNftsReceived + 1;
        addressInfo[msg.sender] = addressInfo[msg.sender] + 1;
        nftContract.safeTransferFrom(pullNftsFromAddress, msg.sender, _nftId, 1, bytes(""));
    }

    function getMessageHash(
        address _to, uint32 _nftId, uint16 _amount, string memory _message, uint _ticketBlock
    )
    public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_to, _nftId, _amount, _message, _ticketBlock));
    }

    function getEthSignableMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(
        address _signer,
        address _to, uint32 _nftId, uint16 _amount, string memory _message, uint _ticketBlock,
        bytes memory signature
    )
    public pure returns (bool)
    {
        bytes32 messageHash = getMessageHash(_to, _nftId, _amount, _message, _ticketBlock);
        bytes32 signableMessageHash = getEthSignableMessageHash(messageHash);
        return recoverSigner(signableMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    public pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    public pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}