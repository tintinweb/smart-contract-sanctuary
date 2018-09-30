contract SocialPlasma {

  address admin;
  mapping(address => bool) operators;
  mapping(address => uint256) deposits;

  string name;
  uint256 m;
  uint256 a;
  uint256 b;
  uint256 c;

  // Events
  event Deposit(address depositee, uint amount, uint timestamp);
  event WithdrawalRequest(address withdrawee, uint amount, uint timestamp);
  event Withdrawal(address withdrawee, uint amount, uint timestamp);
  event NewOperator(address addedBy, address newOperator);

 /**
  * @dev Initializes the Social Plasma smart contract
  * @param _name Name of the plasma chain
  * @param _operator Plasma chain operator
  * @param _m Bonding curve slope
  * @param _a Bonding curve parameter
  * @param _b Bonding curve parameter
  * @param _c Bonding curve parameter
  */
  constructor(string _name,
    address _operator,
    uint256 _m,
    uint256 _a,
    uint256 _b,
    uint256 _c
  ) public {
    operators[_operator] = true;
    name = _name;
    m = _m;
    a = _a;
    b = _b;
    c = _c;
  }

 /**
  * @dev Deposit ETH to network
  */
  function deposit () public payable {
    require(msg.value > 0);
    uint256 minted = a * msg.value + b; // mul(m(1 + a))**(log2(msg.value)) + b;
    deposits[msg.sender] += minted;
    emit Deposit(msg.sender, msg.value, block.timestamp);
  }

 /**
  * @dev Request to withdraw tokens from SocialPlasma
  * @param _amount withdrawal amount requested
  */
  function requestWithdraw (uint256 _amount) public {
    require(_amount > 0);
    emit WithdrawalRequest(msg.sender, _amount, block.timestamp);
  }

  /**
   * @dev Make a withdrawal that has been signed by a host
   * @param _confirmedBy operator address
   * @param _confirmation string in the form of address-amount
   * @param _amount amount of tokens being withdrawn
   * @param _signedTx withdrawal amount signed by operator
   */
   function confirmWithdrawal (address _confirmedBy, string _confirmation, uint256 _amount, string _signedTx, address _send) public payable {
     // Validate an operator has confirmed this withdrawal
     require(operators[_confirmedBy]);

     // Validate the sender is the correct withdrawee
     //bytes32 confirmation = keccak256(msg.sender+"-"+_amount);
     //require(confirmation == _confirmation);

     // Send the withdrawal and update the balance
     deposits[msg.sender] -= _amount;
     require(msg.sender.send(_amount));
   }

   /**
    * @dev Add a new plasma operator
    * @param _address Plasma operator address
    */
    function addOperator (address _address) public {
      require(operators[msg.sender]);
      operators[_address] = true;
      emit NewOperator(msg.sender, _address);
    }

   /**
    * @dev Remove a plasma operator
    * @param _address operator being removed
    */
    function removeOperator (address _address) public {
      require(msg.sender == admin);
      operators[_address] = false;
    }
}

// File: contracts/SocialNetwork.sol

contract SocialNetwork {

  uint256 version;

  struct Network {
    address owner;
    uint m;
    uint a;
    uint b;
    uint c;
  }

  mapping (address => Network) networks;

 /**
  * @dev Initializes the Social Network smart contract
  */
  constructor() public {
    version = 1;
  }

  /**
   * @dev Add a network layer with different parameters
   * @param _name - ID/name of the network
   * @param _m - slope of the function
   * @param _a - precentage growth in price per factor-increase
   * @param _b - adjusts the functions as in mx + b
   * @param _c - base of the factor-increase (i.e. 2x for doubling)
   */
   function createNetwork (string _name, uint _m, uint _a, uint _b, uint _c) public payable {
     address plasmaContractAddress = new SocialPlasma(_name, msg.sender, _m, _a, _b, _c);
     networks[plasmaContractAddress] = Network(msg.sender, _m, _a , _b, _c);
   }
}