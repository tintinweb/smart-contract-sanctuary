pragma solidity 0.5.10;

import './LibAddress.sol';
import './LibInteger.sol';

/**
 * @title BlobDefinition 
 * @dev HBD token contract adhering to ERC721 standard
 */
contract BlobDefinition
{
    using LibAddress for address;
    using LibInteger for uint;

    event Transfer(address indexed from, address indexed to, uint indexed id);
    event Approval(address indexed owner, address indexed approved, uint indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev The admin of the contract
     */
    address payable private _admin;

    /**
     * @dev The total minted tokens
     */
    uint private _supply;

    /**
     * @dev The base url of token info page
     */
    string private _base_uri;

    /**
     * @dev Permitted addresses to carry out special functions
     */
    mapping (address => bool) private _permissions;

    /**
     * @dev Number of tokens held by an address
     */
    mapping (address => uint) private _token_balances;

    /**
     * @dev Owners of each token
     */
    mapping (uint => address) private _token_owners;

    /**
     * @dev Approved third party addresses for each token
     */
    mapping (uint => address) private _token_approvals;

    /**
     * @dev Approved third party addresses to manage all tokens belonging to some address
     */
    mapping (address => mapping (address => bool)) private _token_operators;

    /**
     * @dev Interfaces supported by this contract
     */
    mapping(bytes4 => bool) private _supported_interfaces;

    /**
     * @dev The name of token
     */
    string private constant _name = "Hash Blob Definition";

    /**
     * @dev The symbol of token
     */
    string private constant _symbol = "HBD";

    /**
     * Interface id for ERC165
     */
    bytes4 private constant _interface_165 = 0x01ffc9a7;

    /**
     * Interface id for ERC721
     */
    bytes4 private constant _interface_721 = 0x80ac58cd;

    /**
     * Maximum number of tokens to be minted
     */
    uint private constant _max_supply = 16384;

    /**
     * @dev Initialise the contract
     */
    constructor () public
    {
        //The contract creator becomes the admin
        _admin = msg.sender;

        //Register supported interfaces
        _supported_interfaces[_interface_165] = true;
        _supported_interfaces[_interface_721] = true;
    }

    /**
     * @dev Allow access only for the admin of contract
     */
    modifier onlyAdmin()
    {
        require(msg.sender == _admin);
        _;
    }

    /**
     * @dev Allow access only for the permitted addresses
     */
    modifier onlyPermitted()
    {
        require(_permissions[msg.sender]);
        _;
    }

    /**
     * @dev Give or revoke permission of accounts
     * @param account The address to change permission
     * @param permission True if the permission should be granted, false if it should be revoked
     */
    function permit(address account, bool permission) public onlyAdmin
    {
        _permissions[account] = permission;
    }

    /**
     * @dev Withdraw from the balance of this contract
     * @param amount The amount to be withdrawn, if zero is provided the whole balance will be withdrawn
     */
    function clean(uint amount) public onlyAdmin
    {
        if (amount == 0){
            _admin.transfer(address(this).balance);
        } else {
            _admin.transfer(amount);
        }
    }

    /**
     * @dev Set the base uri
     * @param uri The base uri
     */
    function base(string memory uri) public onlyAdmin
    {
        _base_uri = uri;
    }

    /**
     * @dev Move token from one account to another
     * @param from The token sender address
     * @param to The recipient address
     * @param id The token id to transfer
     */
    function transferFrom(address from, address to, uint id) public
    {
        //The token must exist
        require(_isExist(id));

        //Caller must be approved or the owner of token
        require(_isApprovedOrOwner(msg.sender, id));

        //Do the transfer
        _send(from, to, id, "");
    }

    /**
     * @dev Safely move token from one account to another
     * @param from The token sender address
     * @param to The recipient address
     * @param id The token id to transfer
     */
    function safeTransferFrom(address from, address to, uint id) public
    {
        //The token must exist
        require(_isExist(id));

        //Caller must be approved or the owner of token
        require(_isApprovedOrOwner(msg.sender, id));

        //Do the transfer
        _send(from, to, id, "");
    }

    /**
     * @dev Safely move token from one account to another
     * @param from The token sender address
     * @param to The recipient address
     * @param id The token id to transfer
     * @param data Additional extra data
     */
    function safeTransferFrom(address from, address to, uint id, bytes memory data) public
    {
        //The token must exist
        require(_isExist(id));

        //Caller must be approved or the owner of token
        require(_isApprovedOrOwner(msg.sender, id));

        //Do the transfer
        _send(from, to, id, data);
    }

    /**
     * @dev Allow a third party to transfer caller's token
     * @param to The address to allow
     * @param id The token id to allow transfer
     */
    function approve(address to, uint id) public
    {
        //The token must exist
        require(_isExist(id));

        //No need to approve the owner
        address owner = ownerOf(id);
        require(to != owner);

        //Caller must be the owner of token or an approved operator
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        
        //Grant approval
        _token_approvals[id] = to;

        //Emit events
        emit Approval(owner, to, id);
    }

    /**
     * @dev Grant or revoke approval for a third party to transfer all of caller's tokens
     * @param to The address to grant or revoke
     * @param approved Grant or revoke approval
     */
    function setApprovalForAll(address to, bool approved) public
    {
        //Cannot set own settings
        require(to != msg.sender);

        //Grant or revoke approval
        _token_operators[msg.sender][to] = approved;

        //Emit events
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Mint tokens
     * @param to The owner of token
     */
    function mint(address to) public onlyPermitted returns (uint)
    {
        //No point of minting to zero address
        require(!to.isOriginAddress());

        //Must not exceed the maximum available tokens to be minted
        require(_supply < _max_supply);

        //Mint the token
        uint id = _supply.add(1);
        _token_owners[id] = to;
        _token_balances[to] = _token_balances[to].add(1);

        //Increment supply
        _supply = id;

        //Emit events
        emit Transfer(address(0), to, id);

        return id;
    }

    /**
     * @dev Enable tokens
     * @param to The owner of token
     * @param id The token id to enable
     */
    function enable(address to, uint id) public onlyPermitted
    {
        //Must be a valid id
        require(id > 0);

        //No point of minting to zero address
        require(!to.isOriginAddress());

        //Token does not already exists
        require(!_isExist(id));

        //Enable the token
        _token_owners[id] = to;
        _token_balances[to] = _token_balances[to].add(1);

        //Emit events
        emit Transfer(address(0), to, id);
    }

    /**
     * @dev Burn tokens
     * @param owner The owner of token
     * @param id The token id to burn
     */
    function disable(address owner, uint id) public onlyPermitted
    {
        //Token must exist
        require(_isExist(id));

        //Token must be owned by sent in address
        require(ownerOf(id) == owner);

        //Disable the token
        _token_approvals[id] = address(0);
        _token_balances[owner] = _token_balances[owner].sub(1);
        _token_owners[id] = address(0);

        //Emit events
        emit Transfer(owner, address(0), id);
    }

    /**
     * @dev Safely move token from one account to another
     * @param from The token sender address
     * @param to The recipient address
     * @param id The token id to transfer
     */
    function move(address from, address to, uint id) public onlyPermitted
    {
        //The token must exist
        require(_isExist(id));

        //Do the transfer
        _send(from, to, id, "");
    }

    /**
     * @dev Get the approved address for a token
     * @param id The token id
     * @return address The approved address
     */
    function getApproved(uint id) public view returns (address)
    {
        return _token_approvals[id];
    }

    /**
     * @dev Check whether the provided operator is approved to manage owner's tokens
     * @param owner The token owner address
     * @param operator The operator address to check against
     * @return bool True if the operator is approved, otherwise false
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool)
    {
        return _token_operators[owner][operator];
    }

    /**
     * @dev Get number of tokens belonging to an account
     * @param account The address of account to check
     * @return uint The tokens balance
     */
    function balanceOf(address account) public view returns (uint)
    {
        return _token_balances[account];
    }

    /**
     * @dev Get the owner of a token
     * @param id The id of token
     * @return address The owner of token
     */
    function ownerOf(uint id) public view returns (address)
    {
        return _token_owners[id];
    }

    /**
     * @dev Get the url of token info page
     * @param id The id of token
     * @return string The url of token info page
     */
    function tokenURI(uint id) public view returns (string memory)
    {
        if(_isExist(id)) {
            return string(abi.encodePacked(_base_uri, id.toString()));
        } else {
            return "";
        }
    }

    /**
     * @dev Get the url of contract info page
     * @return string The url of contract info page
     */
    function contractURI() public view returns (string memory)
    {
        return _base_uri;
    }

    /**
     * @dev Check whether the given interface is supported by this contract
     * @param id The interface id to check
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 id) external view returns (bool) {
        return _supported_interfaces[id];
    }

    /**
     * @dev Get the total number of tokens in existance
     * @return uint Number of tokens
     */
    function totalSupply() public view returns (uint)
    {
        return _supply;
    }

    /**
     * @dev Get the maximum number of tokens minted
     * @return uint Maximum number of tokens
     */
    function maxSupply() public pure returns (uint)
    {
        return _max_supply;
    }

    /**
     * @dev Get name of token
     * @return string The name
     */
    function name() public pure returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Get symbol of token
     * @return string The symbol
     */
    function symbol() public pure returns (string memory)
    {
        return _symbol;
    }

    /**
     * @dev Check whether the provided address is permitted
     * @param account The address to check
     * @return bool True if the address is permitted, otherwise false
     */
    function isPermitted(address account) public view returns (bool)
    {
        return _permissions[account];
    }

    /**
     * @dev Check whether the token exists
     * @param id The id of token
     * @return bool True if the token exists, otherwise false
     */
    function _isExist(uint id) private view returns (bool)
    {
        return ownerOf(id) != address(0);
    }

    /**
     * @dev Check whether the provided address is the owner of token or a approved address
     * @param spender The address to check
     * @param id The id of token
     * @return bool True if the provided address is the owner of token or a approved address, otherwise false
     */
    function _isApprovedOrOwner(address spender, uint id) private view returns (bool)
    {
        address owner = ownerOf(id);
        return (spender == owner || getApproved(id) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Transfer tokens from one account to another
     * @param from The token owner
     * @param to The token receiver
     * @param id The token id to transfer
     * @param data Additional data to add to the transaction
     */
    function _send(address from, address to, uint id, bytes memory data) private
    {
        //The token must be owned by the provided address
        require(ownerOf(id) == from);

        //No point of transferring to zero address
        require(!to.isOriginAddress());

        //Do nothing with the data
        delete data;

        //Clear approvals
        _token_approvals[id] = address(0);

        //Reduce the balance from owner
        _token_balances[from] = _token_balances[from].sub(1);

        //Increase the balance of receiver
        _token_balances[to] = _token_balances[to].add(1);

        //Set the new owner
        _token_owners[id] = to;

        //Emit events
        emit Transfer(from, to, id);
    }
}