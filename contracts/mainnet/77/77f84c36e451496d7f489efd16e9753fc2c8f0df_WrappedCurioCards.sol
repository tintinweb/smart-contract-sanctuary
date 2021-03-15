//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "./ERC1155.sol";

interface CurioCards{
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract WrappedCurioCards is ERC1155 {
    using SafeMath for uint256;
    using Address for address;

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    // id => creators
    mapping (uint256 => address) public creators;
    // id => contracts
    mapping (uint256 => address) public contracts;    

    // A nonce to ensure we have a unique id each time we mint.
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function supportsInterface(bytes4 _interfaceId) override
    public
    pure
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    // Creates a new token type and assings _initialSupply to minter
    function create(uint256 id,address curiocontract, string calldata _uri) external onlyOwner{
        creators[id] = msg.sender;
        contracts[id]= curiocontract;
        balances[id][msg.sender] = 0;

        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, id, 0);

        if (bytes(_uri).length > 0)
            emit URI(_uri, id);
    }

    function mint(uint256 _id, address  _to, uint256  _quantity) internal {


            // Grant the items to the caller
            balances[_id][_to] = _quantity.add(balances[_id][_to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint 
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), _to, _id, _quantity);

            if (_to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _to, _id, _quantity, '');
            }
    }

    function wrap(uint256 id,uint256 amount) public{
        address contractaddress =  contracts[id];
        CurioCards cards=CurioCards(contractaddress);
        require(cards.transferFrom(msg.sender,address(this),amount));
        mint(id,msg.sender,amount);
    }

    function unwrap(uint256 id,uint256 amount) public{
        
        address contractaddress =  contracts[id];
        CurioCards cards=CurioCards(contractaddress);
        require(cards.transferFrom(address(this),msg.sender,amount));
        balances[id][msg.sender] = amount.add(balances[id][msg.sender]);
        emit TransferSingle(address(0x0),msg.sender, msg.sender,id , amount);
    }



    function setURI(string calldata _uri, uint256 _id) external creatorOnly(_id) {
        emit URI(_uri, _id);
    }
}