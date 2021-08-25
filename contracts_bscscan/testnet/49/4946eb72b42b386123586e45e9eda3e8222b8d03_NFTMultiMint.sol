/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// File: contracts/NFTMultiMint.sol

pragma solidity ^0.5.0;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public{
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) internal onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract NFTULTRASAFE1155 is Ownable{
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    using SafeMath for uint256;
         // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    mapping (uint256 => address) public _creator;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;
    mapping(uint256 => string) private _tokenURIs;
    mapping (uint256 => uint256) public totalQuantity; 

    mapping (uint256 => uint256) public _royal; 
    string public name;
    string public symbol;

     constructor(string memory _name, string memory _symbol) public{
        name = _name;
        symbol = _symbol;
    }
    function _transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        transferOwnership(newOwner);
       
    }
    function safeTransferFrom(address _from, address _to, uint256 _id,uint256  _value) public onlyOwner{
        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_creator[_id]][owner()] == true, "Need operator approval for 3rd party transfers.");

        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        // MUST emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _value);

    }

    function balanceOf(address _owner, uint256 _id) public view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[_id][_owner];
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address from, address _operator, bool _approved) public onlyOwner{
        operatorApproval[from][_operator] = _approved;
        emit ApprovalForAll(from, _operator, _approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApproval[_owner][_operator];
    }
    function mint(address from, uint256 _id, uint256 _supply, string memory _uri) public onlyOwner{
        require(_creator[_id] == address(0x0), "Token is already minted");
        require(_supply != 0, "Supply should be positive");
        require(bytes(_uri).length > 0, "uri should be set");

        _creator[_id] = from;
        balances[_id][from] = _supply;
        _setTokenURI(_id, _uri);
        totalQuantity[_id] = _supply;
        emit TransferSingle(msg.sender, address(0x0), from, _id, _supply);
    }
      function _setTokenURI(uint256 tokenId, string memory uri) internal onlyOwner{
        _tokenURIs[tokenId] = uri;
        emit URI(uri, tokenId);
    }

   function burn(address from, uint256 _id, uint256 _value) public onlyOwner{
        require(balances[_id][from] >= _value, "Only Burn Allowed Token Owner or insuficient Token Balance");
        require(operatorApproval[_creator[_id]][owner()] == true, "Need operator approval for 3rd party burns.");
        balances[_id][from] = balances[_id][from].sub(_value);
        if(totalQuantity[_id] == _value){
             address own = owner(); 
             operatorApproval[_creator[_id]][own] == false;
             delete _creator[_id];
        }
        totalQuantity[_id] = totalQuantity[_id].sub(_value);
        // MUST emit event
        emit TransferSingle(from, from, address(0x0), _id, _value);
    }
}
contract NFTMultiMint is NFTULTRASAFE1155{
    string public name;
    string public symbol;

    mapping (uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol) NFTULTRASAFE1155(name, symbol) public{
        name = _name;
        symbol = _symbol;
    }
}