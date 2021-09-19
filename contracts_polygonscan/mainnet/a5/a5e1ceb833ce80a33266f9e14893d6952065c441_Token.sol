/**
 *Submitted for verification at polygonscan.com on 2021-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


    //    *** ----------------- ERC721 non fungible contract maker -------------------------- *** 
    

interface IMaker {
    function mint(address minter, address newChildToken) external returns (bool);
    function ownerOf(uint256 tokenID) external view returns (address);
    function tokenIdOf(address contractAddress) external view returns (uint256);
}
    //   *** ----------------- ERC20 send interface ------------------------ ***
    
    
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}





    //    *** --------------- ERC20 contract owned by the owner of ERC721 token ID_1 ----------------- *** 




contract Token {

    address private _maker;
    address private _dev;

    uint256 private _addresId;
    uint256 private _uriId;
    uint256 private _price;
    uint256 private _tempMaxA;
    uint256 private _tempMaxU;
   
    string private _currentURI;

    mapping (uint256 => address) private _newAddresses;
    mapping (uint256 => string) private _myUris;
   
    constructor () {
      _dev = msg.sender;
    }
    
    function setContract(address maker_, string memory name_, string memory symbol_, string memory uri_) public {
        require(msg.sender == _dev, "caller not the owner");
        _maker = maker_;
        _name = name_;
        _symbol = symbol_;
        
        _addresId ++;
        _newAddresses[_addresId] = address(this);
        
        _uriId ++;
        _myUris[_uriId] = uri_;
        _currentURI = uri_;
        
        _dev = address(0);
        _price = 10**18;
        _totalSupply = 10**21;
        _balances[msg.sender] = _totalSupply;        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    //    *** ----------------- smart contract basic functions --------------------------------- ***
    
    
    
    
    /**
     *  @dev  Contract can receive ether
     */
    receive() external payable {}
    
    modifier onlyOwner() {
         require(msg.sender == IMaker(_maker).ownerOf(IMaker(_maker).tokenIdOf(address(this))));
        _;
    }
    
    /**
     *  @dev  Contract can send ether
     */
    function zendEth(address payable to, uint256 amount) public payable onlyOwner() {
        to.transfer(amount);
    }

    /**
     *  @dev  Contract can receive and send ERC20 tokens ----------------***
     */
    function zendTokens(address to, address token, uint256 amount) public onlyOwner() {
        IERC20(token).transfer(to, amount);
    }
    
    
    
    //    *** ------------------------ mint new_nfc functions ------------------------------------ ***
    
    
    
    
    
    /**
     *  @dev  Send 'the_token_price_or_more' to 'this_contract_address' and mint a 'new_nft_(ERC721)'.
     *        (Send to any other address is a normal transfer)
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        
        if (recipient == address(this)) {
            require(_addresId <= _tempMaxA, "temporary sold out");
            require(_uriId <= _tempMaxU, "temporary sold out");
            buyNewNfc(amount);
        } else {
            _transfer(msg.sender, recipient, amount);
        }
        return true;
    }
    
    /**
     *  @dev  Tokens sent to this contract address, mint a new ERC721 token (nft) to sender.
     *        Tokens sent to this contract end up on the balance of a new ERC20 contract.
     *        The new ERC721 token is linked to the new ERC20 contract that hodls the URI of the new ERC721 token.
     *        Ownership of this new ERC721 token proofs ownership of this new ERC20 contract.
     */
    function buyNewNfc(uint256 amount) internal {
        if (amount >= _price) { _addresId++;
            IMaker(_maker).mint(msg.sender, _newAddresses[_addresId]);
            _transfer(msg.sender, _newAddresses[_addresId], amount);
        } else {
            emit Transfer(msg.sender, address(this), 0);
        }
    }
    
    /**
     *  @dev  Set a new price for minting new nfcs (add 10**18)
     */
    function setPrice(uint256 price) public onlyOwner() {
        _price = price;
    }
   
    function getPrice() public view returns (uint256) {
        return _price;
    }
    
    function ownerOfThisContract() public view returns (address) {
        return IMaker(_maker).ownerOf(IMaker(_maker).tokenIdOf(address(this)));
    }
    
    
    
    //    *** ------------------------ URI setters and getters ----------------------------- ***
        
        
        
      
 
    /**
     *  @dev  Change the URI of the nft linked to this contract
     */
    function setNewCurrentURI(uint256 myURIindexId) public onlyOwner() {
        _currentURI = _myUris[myURIindexId];
    }
    
    /**
     *  @dev  Enter new URI to this contracts list_of_URIs
     */
    function setURI(string memory uri) public onlyOwner() {
        uint256 prevUriId = _uriId;
        _uriId++;
        _myUris[_uriId] = uri;
        _tempMaxU = _uriId;
        _uriId = prevUriId;
    }
    
    function getURI() public view returns (string memory) {
        return _currentURI;
    }
    
    
    /**
     *   @dev  Enter array of URIS to this contracts list_of_URIs 
     */
    function setURIList(string[] calldata uris) public onlyOwner() {
         uint256 prevUriId = _uriId;
        for (uint256 i = 0; i < uris.length; i++) {
            _uriId++;
            _myUris[_uriId] = uris[i];
        }
        _tempMaxU = _uriId;
        _uriId = prevUriId;
    }
    
    function getUriFromList(uint256 myIndexId) public view onlyOwner() returns (string memory) {
        return _myUris[myIndexId];
    }
    
    /**
     *  @dev  Enter array of addresses to new addresses list 
     */
    function setAddressList(address[] calldata children) public onlyOwner(){
        uint256 prevAddresId =_addresId;
        for (uint256 i = 0; i < children.length; i++) {
            _addresId++;
            _newAddresses[_addresId] = children[i];
        }
        _tempMaxA = _addresId;
        _addresId = prevAddresId;
    }
    
    
    
    
    //   *** ----------------- ERC20 supplies ----------------------- ***
    
    
    
    

    event Transfer(address indexed from, address indexed to, uint256 value);
   
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
   
    string private _name;
   
    string private _symbol;
   
    function name() public view  returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
   
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function mintERC20Tokens(address to, uint256 amount) public onlyOwner() {
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    } 

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

   function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender,msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   
}