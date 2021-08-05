/**
 *Submitted for verification at Etherscan.io on 2020-12-21
*/

/*                   
███╗   ██╗███████╗████████╗                         
████╗  ██║██╔════╝╚══██╔══╝                         
██╔██╗ ██║█████╗     ██║                            
██║╚██╗██║██╔══╝     ██║                            
██║ ╚████║██║        ██║                            
╚═╝  ╚═══╝╚═╝        ╚═╝                            
███████╗██╗  ██╗ █████╗ ██████╗ ██████╗ ███████╗    
██╔════╝██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝    
███████╗███████║███████║██████╔╝██║  ██║███████╗    
╚════██║██╔══██║██╔══██║██╔══██╗██║  ██║╚════██║    
███████║██║  ██║██║  ██║██║  ██║██████╔╝███████║    
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝
presented by LexDAO LLC
*/
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

interface IERC20Withdrawal { // brief interface for erc20 token withdrawal
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

interface IERC721transferFrom { // brief interface for erc721 token (nft)
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTShards {
    uint8   public decimals; // fixed unit scaling factor - default 18 to match ETH
    uint256 public totalSupply; // tracks outstanding token mint - mint updateable by manager
    uint256 public totalSupplyCap; // maximum of token mintable
    bytes32 public DOMAIN_SEPARATOR; // eip-2612 permit() pattern - hash identifies contract
    bytes32 constant public PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"); // eip-2612 permit() pattern - hash identifies function for signature
    string  public details; // details token offering, redemption, etc. - updateable by manager
    string  public name; // fixed token name
    string  public symbol; // fixed token symbol
    bool    public transferable; // transferability of token - updateable by manager
    
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public nonces;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event UpdateDetails(string details);
    event UpdateTransferability(bool transferable);
    
    constructor(
        address _manager,
        uint8 _decimals, 
        uint256 _managerSupply,  
        uint256 _totalSupplyCap,
        string memory _details, 
        string memory _name, 
        string memory _symbol,  
        bool _transferable
    ) {
        decimals = _decimals; 
        totalSupplyCap = _totalSupplyCap; 
        details = _details; 
        name = _name; 
        symbol = _symbol;  
        transferable = _transferable; 
        if (_managerSupply > 0) {_mint(_manager, _managerSupply);}
        // eip-2612 permit() pattern:
        uint256 chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes("1")),
            chainId,
            address(this)));
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value; 
        emit Approval(owner, spender, value); 
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value; 
        totalSupply = totalSupply - value; 
        emit Transfer(from, address(0), value);
    }
    
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
    
    function burnFrom(address from, uint256 value) external {
        _approve(from, msg.sender, allowance[from][msg.sender] - value);
        _burn(from, value);
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }
    
    // Adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "expired");
        bytes32 hashStruct = keccak256(abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline));
        bytes32 hash = keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "!signer");
        _approve(owner, spender, amount);
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value; 
        balanceOf[to] = balanceOf[to] + value; 
        emit Transfer(from, to, value); 
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        require(transferable, "!transferable"); 
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferBatch(address[] calldata to, uint256[] calldata value) external {
        require(to.length == value.length, "!to/value");
        require(transferable, "!transferable");
        for (uint256 i = 0; i < to.length; i++) {
            _transfer(msg.sender, to[i], value[i]);
        }
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(transferable, "!transferable");
        _approve(from, msg.sender, allowance[from][msg.sender] - value);
        _transfer(from, to, value);
        return true;
    }
    
    /****************
    MANAGER FUNCTIONS
    ****************/
    modifier onlyManager {
        require(balanceOf[msg.sender] > totalSupply / 2, "!manager"); // require simple majority
        _;
    }
    
    function _mint(address to, uint256 value) internal {
        require(totalSupply + value <= totalSupplyCap, "capped"); 
        balanceOf[to] = balanceOf[to] + value; 
        totalSupply = totalSupply + value; 
        emit Transfer(address(0), to, value); 
    }
    
    function mint(address to, uint256 value) external onlyManager {
        _mint(to, value);
    }
    
    function mintBatch(address[] calldata to, uint256[] calldata value) external onlyManager {
        require(to.length == value.length, "!to/value");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], value[i]); 
        }
    }
    
    function updateDetails(string calldata _details) external onlyManager {
        details = _details;
        emit UpdateDetails(_details);
    }
    
    function updateTransferability(bool _transferable) external onlyManager {
        transferable = _transferable;
        emit UpdateTransferability(_transferable);
    }
    
    function withdrawNFT(address[] calldata nft, address[] calldata withrawTo, uint256[] calldata tokenId) external onlyManager { // withdraw NFT sent to contract
        require(nft.length == withrawTo.length && nft.length == tokenId.length, "!nft/withdrawTo/tokenId");
        for (uint256 i = 0; i < nft.length; i++) {
            IERC721transferFrom(nft[i]).transferFrom(address(this), withrawTo[i], tokenId[i]);
        }
    }
    
    function withdrawToken(address[] calldata token, address[] calldata withdrawTo, uint256[] calldata value, bool max) external onlyManager { // withdraw token sent to contract
        require(token.length == withdrawTo.length && token.length == value.length, "!token/withdrawTo/value");
        for (uint256 i = 0; i < token.length; i++) {
            uint256 withdrawalValue = value[i];
            if (max) {withdrawalValue = IERC20Withdrawal(token[i]).balanceOf(address(this));}
            IERC20Withdrawal(token[i]).transfer(withdrawTo[i], withdrawalValue);
        }
    }
}