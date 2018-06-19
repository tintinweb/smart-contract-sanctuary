pragma solidity ^0.4.15;

contract Factory{
    
    //Adress of creator
    address private creator;

    // Addresses of owners
    address[] public owners = [0x6CAa636cFFbCbb2043A3322c04dE3f26b1fa6555, 0xbc2d90C2D3A87ba3fC8B23aA951A9936A6D68121, 0x680d821fFE703762E7755c52C2a5E8556519EEDc];

    //List of deployed Forwarders
    address[] public deployed_forwarders;
    
    //Get number of forwarders created
    uint public forwarders_count = 0;
    
    //Last forwarder create
    address public last_forwarder_created;
  
    //Only owners can generate a forwarder
    modifier onlyOwnerOrCreator {
      require(msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2] || msg.sender == creator);
      _;
    }
    
    event ForwarderCreated(address to);
  
    //Constructor
    constructor() public {
        creator = msg.sender;
    }
  
    //Create new Forwarder
    function create_forwarder() public onlyOwnerOrCreator {
        address new_forwarder = new Forwarder();
        deployed_forwarders.push(new_forwarder);
        last_forwarder_created = new_forwarder;
        forwarders_count += 1;
        
        emit ForwarderCreated(new_forwarder);
    }
    
    //Get deployed forwarders
    function get_deployed_forwarders() public view returns (address[]) {
        return deployed_forwarders;
    }

}

contract Forwarder {
    
  // Address to which any funds sent to this contract will be forwarded
  address private parentAddress = 0x7aeCf441966CA8486F4cBAa62fa9eF2D557f9ba7;
  
  // Addresses of people who can flush ethers and tokenContractAddress
  address[] private owners = [0x6CAa636cFFbCbb2043A3322c04dE3f26b1fa6555, 0xbc2d90C2D3A87ba3fC8B23aA951A9936A6D68121, 0x680d821fFE703762E7755c52C2a5E8556519EEDc];
  
  event ForwarderDeposited(address from, uint value, bytes data);

  /**
   * Create the contract.
   */
  constructor() public {

  }

  /**
   * Modifier that will execute internal code block only if the sender is among owners.
   */
  modifier onlyOwner {
    require(msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2]);
    _;
  }

  /**
   * Default function; Gets called when Ether is deposited, and forwards it to the parent address
   */
  function() public payable {
    // throws on failure
    parentAddress.transfer(msg.value);
    // Fire off the deposited event if we can forward it
    emit ForwarderDeposited(msg.sender, msg.value, msg.data);
  }


  /**
   * Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushTokens(address tokenContractAddress) public onlyOwner {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    address forwarderAddress = address(this);
    uint forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, forwarderBalance)) {
      revert();
    }
  }

  /**
   * It is possible that funds were sent to this address before the contract was deployed.
   * We can flush those funds to the parent address.
   */
  function flush() public onlyOwner {
    // throws on failure
    uint my_balance = address(this).balance;
    if (my_balance == 0){
        return;
    } else {
        parentAddress.transfer(address(this).balance);
    }
  }
}

contract ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) public returns (bool success);
  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) public constant returns (uint256 balance);
}