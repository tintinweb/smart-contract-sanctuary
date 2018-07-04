pragma solidity ^0.4.19;


contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract Engine {
    uint256 public VERSION;
    string public VERSION_NAME;

    enum Status { initial, lent, paid, destroyed }
    struct Approbation {
        bool approved;
        bytes data;
        bytes32 checksum;
    }

    function getTotalLoans() public view returns (uint256);
    function getOracle(uint index) public view returns (Oracle);
    function getBorrower(uint index) public view returns (address);
    function getCosigner(uint index) public view returns (address);
    function ownerOf(uint256) public view returns (address owner);
    function getCreator(uint index) public view returns (address);
    function getAmount(uint index) public view returns (uint256);
    function getPaid(uint index) public view returns (uint256);
    function getDueTime(uint index) public view returns (uint256);
    function getApprobation(uint index, address _address) public view returns (bool);
    function getStatus(uint index) public view returns (Status);
    function isApproved(uint index) public view returns (bool);
    function getPendingAmount(uint index) public returns (uint256);
    function getCurrency(uint index) public view returns (bytes32);
    function cosign(uint index, uint256 cost) external returns (bool);
    function approveLoan(uint index) public returns (bool);
    function transfer(address to, uint256 index) public returns (bool);
    function takeOwnership(uint256 index) public returns (bool);
    function withdrawal(uint index, address to, uint256 amount) public returns (bool);
}

contract ERC721 {
   // ERC20 compatible functions
   function name() public view returns (string _name);
   function symbol() public view returns (string _symbol);
   function totalSupply() public view returns (uint256 _totalSupply);
   function balanceOf(address _owner) public view returns (uint _balance);
   // Functions that define ownership
   function ownerOf(uint256) public view returns (address owner);
   function approve(address, uint256) public returns (bool);
   function takeOwnership(uint256) public returns (bool);
   function transfer(address, uint256) public returns (bool);
   function setApprovalForAll(address _operator, bool _approved) public returns (bool);
   function getApproved(uint256 _tokenId) public view returns (address);
   function isApprovedForAll(address _owner, address _operator) public view returns (bool);
   // Token metadata
   function tokenMetadata(uint256 _tokenId) public view returns (string info);
   // Events
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
   event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender; 
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    } 
} 

/**
    @dev Defines the interface of a standard RCN oracle.

    The oracle is an agent in the RCN network that supplies a convertion rate between RCN and any other currency,
    it&#39;s primarily used by the exchange but could be used by any other agent.
*/
contract Oracle is Ownable {
    uint256 public constant VERSION = 4;

    event NewSymbol(bytes32 _currency);

    mapping(bytes32 => bool) public supported;
    bytes32[] public currencies;

    /**
        @dev Returns the url where the oracle exposes a valid &quot;oracleData&quot; if needed
    */
    function url() public view returns (string);

    /**
        @dev Returns a valid convertion rate from the currency given to RCN

        @param symbol Symbol of the currency
        @param data Generic data field, could be used for off-chain signing
    */
    function getRate(bytes32 symbol, bytes data) public returns (uint256 rate, uint256 decimals);

    /**
        @dev Adds a currency to the oracle, once added it cannot be removed

        @param ticker Symbol of the currency

        @return if the creation was done successfully
    */
    function addCurrency(string ticker) public onlyOwner returns (bool) {
        bytes32 currency = encodeCurrency(ticker);
        NewSymbol(currency);
        supported[currency] = true;
        currencies.push(currency);
        return true;
    }

    /**
        @return the currency encoded as a bytes32
    */
    function encodeCurrency(string currency) public pure returns (bytes32 o) {
        require(bytes(currency).length <= 32);
        assembly {
            o := mload(add(currency, 32))
        }
    }
    
    /**
        @return the currency string from a encoded bytes32
    */
    function decodeCurrency(bytes32 b) public pure returns (string o) {
        uint256 ns = 256;
        while (true) { if (ns == 0 || (b<<ns-8) != 0) break; ns -= 8; }
        assembly {
            ns := div(ns, 8)
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(ns, 0x20), 0x1f), not(0x1f))))
            mstore(o, ns)
            mstore(add(o, 32), b)
        }
    }
    
}

contract BytesUtils {
    function readBytes32(bytes data, uint256 index) internal pure returns (bytes32 o) {
        require(data.length / 32 > index);
        assembly {
            o := mload(add(data, add(32, mul(32, index))))
        }
    }
}

contract Pawn is ERC721, BytesUtils, Ownable {
    Engine engine;

    mapping (uint => address) pawnToOwner;
    mapping (uint => address) pawnToApproved;

    mapping (uint => PawnToken) loanIdToPawn;
    struct PawnToken {
        ERC20Data[]  erc20Datas;  // loan index to array of ERC20Data struct
        ERC721Data[] erc721Datas; // loan index to array of ERC721Data struct
    }

    struct ERC20Data {
        Token addr; // address of ERC20 contract
        uint amount;
    }
    struct ERC721Data {
        ERC721 addr; // address of ERC721 contract
        uint[] nfts; // array of non fungible
    }

    function getERC20Pawn(uint _loanId) public view returns(address[] addrs, uint[] amounts){
        ERC20Data[] storage erc20Data = loanIdToPawn[_loanId].erc20Datas;

        for(uint i; i < erc20Data.length; i++){
            addrs[i] = erc20Data[i].addr;
            amounts[i] = erc20Data[i].amount;
        }
    }

    function getERC721AddrPawn(uint _loanId) public view returns(address[] addrs){
        ERC721Data[] storage erc721Data = loanIdToPawn[_loanId].erc721Datas;

        for(uint i; i < erc721Data.length; i++){
            addrs[i] = erc721Data[i].addr;
        }
    }

    function getERC721AddrPawn(uint _loanId, address _addr) public view returns(uint[]){
        ERC721Data[] storage erc721Data = loanIdToPawn[_loanId].erc721Datas;

        for(uint i; i < erc721Data.length; i++){
            if(erc721Data[i].addr == _addr)
                return erc721Data[i].nfts;
        }
    }

    constructor(Engine _engine) public {
        engine = _engine;
    }

    modifier onlyBorrower(uint _loanId) {
        require(engine.getBorrower(_loanId) == msg.sender);
        _;
    }

    function deletePawn(uint _loanId) public onlyBorrower(_loanId) {
        delete loanIdToPawn[_loanId];
    }

    function addERC20ToPawnToken(uint _loanId, Token _erc20, uint _amount) public onlyBorrower(_loanId) {
        if(pawnToOwner[_loanId] == 0)
            pawnToOwner[_loanId] = msg.sender;
        loanIdToPawn[_loanId].erc20Datas.push(ERC20Data(_erc20, _amount));
    }

    function addERC721ToPawnToken(uint _loanId, ERC721 _erc721, uint[] _nfts) public onlyBorrower(_loanId) {
        if(pawnToOwner[_loanId] == 0)
            pawnToOwner[_loanId] = msg.sender;
        loanIdToPawn[_loanId].erc721Datas.push(ERC721Data(_erc721, _nfts));
    }

    function ownerOf(uint _loanId) public view returns (address) { return pawnToOwner[_loanId]; }

    function approve(address _to, uint _loanId) public returns(bool) {
        require(msg.sender == pawnToOwner[_loanId]);
        require(msg.sender != _to);

        pawnToApproved[_loanId] = _to;

        emit Approval(msg.sender, _to, _loanId);

        return true;
    }

    function takeOwnership(uint _loanId) public returns(bool) {
        require(pawnToOwner[_loanId] != 0x0);
        address oldOwner = pawnToOwner[_loanId];

        require(pawnToApproved[_loanId] == msg.sender);
        delete pawnToApproved[_loanId];

        _takeAll(oldOwner, address(this), _loanId);
        pawnToOwner[_loanId] = msg.sender;

        return true;
    }

    function _takeAll(address _from, address _to, uint _loanId) private returns(bool) {
        PawnToken storage pawn = loanIdToPawn[_loanId];
        ERC20Data[] storage erc20Datas = pawn.erc20Datas;

        uint i;
        for(i = 0; i < erc20Datas.length; i++){
            require(erc20Datas[i].addr.transferFrom(_from, _to, erc20Datas[i].amount));
        }

        ERC721Data[] storage erc721Datas = pawn.erc721Datas;
        ERC721 addr;

        for(i = 0; i < erc721Datas.length; i++){
            addr = erc721Datas[i].addr;
            uint[] storage nfts = erc721Datas[i].nfts;
            for(uint j = 0; j < nfts.length; j++){
                require(addr.takeOwnership(nfts[j]));
            }
        }

        return true;
    }

    function checkLoanStatus(address _to, uint256 _loanId) private view returns (bool) {
      return (engine.getBorrower(_loanId) == _to && engine.getStatus(_loanId) == Engine.Status.paid) ||
        (engine.ownerOf(_loanId) == _to && engine.getStatus(_loanId) == Engine.Status.lent && engine.getDueTime(_loanId) <= now);
    }

    function _transferAll(address _to, uint _loanId) private returns(bool) {
        PawnToken storage pawn = loanIdToPawn[_loanId];
        ERC20Data[] storage erc20Datas = pawn.erc20Datas;

        uint i;
        for(i = 0; i < erc20Datas.length; i++){
            require(erc20Datas[i].addr.transfer(_to, erc20Datas[i].amount));
        }

        ERC721Data[] storage erc721Datas = pawn.erc721Datas;
        ERC721 addr;

        for(i = 0; i < erc721Datas.length; i++){
            addr = erc721Datas[i].addr;
            uint[] storage nfts = erc721Datas[i].nfts;
            for(uint j = 0; j < nfts.length; j++){
                require(addr.transfer(_to, nfts[j]));
            }
        }

        return true;
    }

    function transfer(address _to, uint _loanId) public returns(bool) {
        require(pawnToOwner[_loanId] != 0x0);//TODO es necesario????
        require(msg.sender == pawnToOwner[_loanId]);
        require(checkLoanStatus(_to, _loanId));
        require(msg.sender != _to);
        require(_to != address(0));

        _transferAll(_to, _loanId);
        pawnToOwner[_loanId] = _to;

        emit Transfer(msg.sender, _to, _loanId);

        return true;
    }

    function name() public view returns (string){ return &quot;test_erc721&quot;; }
    function symbol() public view returns (string){ return &quot;TEST&quot;; }
    function totalSupply() public view returns (uint256){ return 0; }
    function balanceOf(address ) public view returns (uint) { return 0; }
    function setApprovalForAll(address , bool ) public returns (bool){ return false; }
    function getApproved(uint _loanId) public view returns (address) { return pawnToApproved[_loanId]; }
    function isApprovedForAll(address , address ) public view returns (bool){ return false; }
    // Token metadata
    function tokenMetadata(uint256 ) public view returns (string info){ return &quot;&quot;; }
}