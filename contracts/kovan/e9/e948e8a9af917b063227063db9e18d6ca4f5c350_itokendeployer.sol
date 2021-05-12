pragma solidity ^0.5.0;

import "./token.sol";

contract itoken is ERC20 {

    address public owner;

    address public daaaddress;
    address[] public alladdress;
    mapping(address =>bool) public whitelistedaddress;
    /**
     * @dev Constructor
     * @param _name name of the token
     * @param _symbol symbol of the token, 3-4 chars is recommended
     * @param _daaaddress Pool address for mint and burn permission
     */

         /**
     * @dev Add Chef address so that itoken can be deposited/withdraw from 
     * @param _address Address of Chef contract
     */

    function addChefAddress(address _address) public returns(bool){
        require(!whitelistedaddress[_address],"Already white listed");
        whitelistedaddress[_address] = true;
        alladdress.push(msg.sender);
        return true;
    }

	constructor(string memory _name, string memory _symbol, address _daaaddress) public ERC20(_name, _symbol) {
		daaaddress = _daaaddress;
        addChefAddress(msg.sender);
        addChefAddress(daaaddress);
        _mint(msg.sender, 1000000*10**18);
	}


    /**
     * @dev Mint new itoken for new deposit can only be called by 
     * @param account Account to which tokens will be minted
     * @param amount amount to mint
     */
	function mint(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return true;
    }

    function validateTransaction(address to, address from) public view returns(bool){
        if(whitelistedaddress[to] || whitelistedaddress[from]){
            return true;
        }
        else{
            return false;
        }
    }
    /**
     * @dev Transfer function with additional condition to limit the token transfer.
     * @param recipient Account to which tokens will be transfered
     * @param amount amount to transfer
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
      require(validateTransaction(msg.sender,recipient),"itoken can only be traded with DAA pool/chef");
      _transfer(msg.sender, recipient, amount);
      return true;
    }

    /**
     * @dev Burn itoken during withdraw can only be called by DAA 
     * @param account Account from which tokens will be burned
     * @param amount amount to burn
     */

    function burn(address account, uint256 amount) external returns (bool) {
        _burn(account, amount);
        return true;
    }
}

contract itokendeployer {
    address public owner;
    address public daaaddress;
    address[] public deployeditokens;
    modifier onlyOnwer{
        require(msg.sender == owner, "Only owner call");
        _;
    }

    modifier onlyDaa{
        require(msg.sender == daaaddress, "Only DAA contract can call");
        _;
    }
    /**
     * @dev Constructor.
     */
    constructor() public {
		owner = msg.sender;
	}

    /**
     * @dev Create new itoken when a new pool is created. Mentioned in Public Facing ASTRA TOKENOMICS document  itoken distribution 
       section that itoken need to be given a user for deposit in pool.
     * @param _name name of the token
     * @param _symbol symbol of the token, 3-4 chars is recommended
     */
    function createnewitoken(string calldata _name, string calldata _symbol) external onlyDaa returns(address) {
		itoken _itokenaddr = new itoken(_name,_symbol,msg.sender);  
        deployeditokens.push(address(_itokenaddr));
		return address(_itokenaddr);  
    }

    /**
     * @dev Get the address of the itoken based on the pool Id.
     * @param pid Daa Pool Index id.
     */
    function getcoin(uint256 pid) external view returns(address){
        return deployeditokens[pid];
    }

    /**
     * @dev Add the address DAA pool configurtaion contrac so that only Pool configuration can create the itokens.
     * @param _address Address of the DAA contract.
     */
    function addDaaAdress(address _address) public onlyOnwer { 
        require(daaaddress != _address, "Already set Daa address");
	    daaaddress = _address;
	}
    
}