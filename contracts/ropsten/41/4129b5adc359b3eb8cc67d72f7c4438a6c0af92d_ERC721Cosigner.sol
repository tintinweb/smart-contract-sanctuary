pragma solidity ^0.4.19;


/**
    @dev Defines the interface of a standard RCN cosigner.

    The cosigner is an agent that gives an insurance to the lender in the event of a defaulted loan, the confitions
    of the insurance and the cost of the given are defined by the cosigner. 

    The lender will decide what cosigner to use, if any; the address of the cosigner and the valid data provided by the
    agent should be passed as params when the lender calls the &quot;lend&quot; method on the engine.
    
    When the default conditions defined by the cosigner aligns with the status of the loan, the lender of the engine
    should be able to call the &quot;claim&quot; method to receive the benefit; the cosigner can define aditional requirements to
    call this method, like the transfer of the ownership of the loan.
*/
contract Cosigner {
    uint256 public constant VERSION = 2;
    
    /**
        @return the url of the endpoint that exposes the insurance offers.
    */
    function url() public view returns (string);
    
    /**
        @dev Retrieves the cost of a given insurance, this amount should be exact.

        @return the cost of the cosign, in RCN wei
    */
    function cost(address engine, uint256 index, bytes data, bytes oracleData) public view returns (uint256);
    
    /**
        @dev The engine calls this method for confirmation of the conditions, if the cosigner accepts the liability of
        the insurance it must call the method &quot;cosign&quot; of the engine. If the cosigner does not call that method, or
        does not return true to this method, the operation fails.

        @return true if the cosigner accepts the liability
    */
    function requestCosign(Engine engine, uint256 index, bytes data, bytes oracleData) public returns (bool);
    
    /**
        @dev Claims the benefit of the insurance if the loan is defaulted, this method should be only calleable by the
        current lender of the loan.

        @return true if the claim was done correctly.
    */
    function claim(address engine, uint256 index, bytes oracleData) public returns (bool);
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

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract BytesUtils {
    function readBytes32(bytes data, uint256 index) internal pure returns (bytes32 o) {
        require(data.length / 32 > index);
        assembly {
            o := mload(add(data, add(32, mul(32, index))))
        }
    }
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
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
        emit NewSymbol(currency);
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

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable returns(bool);
    function approve(address _approved, uint256 _tokenId) external payable returns(bool);
    function getApproved(uint256 _tokenId) external view returns (address);
}

contract ERC721Cosigner is Cosigner, BytesUtils, Ownable {
    mapping(uint => ERC721Data) loanIdToERC721Data; // loan index on loans array in nano loan engine to ERC721Data
    struct ERC721Data {
        ERC721 addr; // address of ERC721 contract
        uint nft; // non fungible id
    }
    // index of metadata
    uint private constant INDEX_ERC721_ADDR = 0;
    uint private constant INDEX_NFT = 1;
    //this cosign dont have cost
    function cost(address , uint256 , bytes , bytes ) public view returns (uint256) {
        return 0;
    }

    function requestCosign(Engine _engine, uint256 _index, bytes _data, bytes ) public returns (bool) {
        require(msg.sender == address(_engine), &quot;the sender its not the Engine&quot;);

        ERC721 erc721 = ERC721(address(readBytes32(_data, INDEX_ERC721_ADDR)));
        uint nft = uint(readBytes32(_data, INDEX_NFT));
        require(erc721.transferFrom(_engine.getBorrower(_index), address(this), nft), &quot;fail transfer&quot;);
        loanIdToERC721Data[_index] = ERC721Data(erc721, nft);

        require(_engine.cosign(_index, 0), &quot;fail cosing&quot;);

        return true;
    }

    function url() public view returns (string) {
        return &quot;&quot;;
    }

    /**
        @dev Defines a custom logic that determines if a loan is defaulted or not.

        @param _index Index of the loan

        @return true if the loan is considered defaulted
    */
    function isDefaulted(Engine _engine, uint256 _index) public view returns (bool) {
        return _engine.getStatus(_index) == Engine.Status.lent && _engine.getDueTime(_index) <= now;
    }

    function claim(address _engineAddress, uint256 _index, bytes ) public returns (bool) {
      Engine engine = Engine(_engineAddress);
      ERC721Data storage erc721Data = loanIdToERC721Data[_index];
      // for borrower claim
      address borrower = engine.getBorrower(_index);
      if(msg.sender == borrower) {
          require(engine.getStatus(_index) == Engine.Status.paid, &quot;the loan its not paid&quot;);
          require(erc721Data.addr.transferFrom(address(this), borrower, erc721Data.nft), &quot;fail transfer&quot;);
          return true;
      }
      // for lender claim
      address lender = engine.ownerOf(_index);
      require(msg.sender == lender, &quot;bad sender&quot;);
      require(isDefaulted(engine, _index), &quot;the loan its not defaulted&quot;);
      require(erc721Data.addr.transferFrom(address(this), lender, erc721Data.nft), &quot;fail transfer&quot;);
      return true;
    }
}