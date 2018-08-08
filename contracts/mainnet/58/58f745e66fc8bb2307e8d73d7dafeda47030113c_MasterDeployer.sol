pragma solidity ^0.4.24;

//Swap Deployer functions - descriptions can be found in Deployer.sol
interface Deployer_Interface {
  function newContract(address _party, address user_contract, uint _start_date) external payable returns (address);
}

//Slightly modified SafeMath library - includes a min function
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

//Swap factory functions - descriptions can be found in Factory.sol
interface Factory_Interface {
  function createToken(uint _supply, address _party, uint _start_date) external returns (address,address, uint);
  function payToken(address _party, address _token_add) external;
  function deployContract(uint _start_date) external payable returns (address);
   function getBase() external view returns(address);
  function getVariables() external view returns (address, uint, uint, address,uint);
  function isWhitelisted(address _member) external view returns (bool);
}


/**
*The DRCTLibrary contains the reference code used in the DRCT_Token (an ERC20 compliant token
*representing the payout of the swap contract specified in the Factory contract).
*/
library DRCTLibrary{

    using SafeMath for uint256;

    /*Structs*/
    /**
    *@dev Keeps track of balance amounts in the balances array
    */
    struct Balance {
        address owner;
        uint amount;
        }

    struct TokenStorage{
        //This is the factory contract that the token is standardized at
        address factory_contract;
        //Total supply of outstanding tokens in the contract
        uint total_supply;
        //Mapping from: swap address -> user balance struct (index for a particular user&#39;s balance can be found in swap_balances_index)
        mapping(address => Balance[]) swap_balances;
        //Mapping from: swap address -> user -> swap_balances index
        mapping(address => mapping(address => uint)) swap_balances_index;
        //Mapping from: user -> dynamic array of swap addresses (index for a particular swap can be found in user_swaps_index)
        mapping(address => address[]) user_swaps;
        //Mapping from: user -> swap address -> user_swaps index
        mapping(address => mapping(address => uint)) user_swaps_index;
        //Mapping from: user -> total balance accross all entered swaps
        mapping(address => uint) user_total_balances;
        //Mapping from: owner -> spender -> amount allowed
        mapping(address => mapping(address => uint)) allowed;
    }   

    /*Events*/
    /**
    *@dev events for transfer and approvals
    */
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event CreateToken(address _from, uint _value);
    
    /*Functions*/
    /**
    *@dev Constructor - sets values for token name and token supply, as well as the 
    *factory_contract, the swap.
    *@param _factory 
    */
    function startToken(TokenStorage storage self,address _factory) public {
        self.factory_contract = _factory;
    }

    /**
    *@dev ensures the member is whitelisted
    *@param _member is the member address that is chekced agaist the whitelist
    */
    function isWhitelisted(TokenStorage storage self,address _member) internal view returns(bool){
        Factory_Interface _factory = Factory_Interface(self.factory_contract);
        return _factory.isWhitelisted(_member);
    }

    /**
    *@dev gets the factory address
    */
    function getFactoryAddress(TokenStorage storage self) external view returns(address){
        return self.factory_contract;
    }

    /**
    *@dev Token Creator - This function is called by the factory contract and creates new tokens
    *for the user
    *@param _supply amount of DRCT tokens created by the factory contract for this swap
    *@param _owner address
    *@param _swap address
    */
    function createToken(TokenStorage storage self,uint _supply, address _owner, address _swap) public{
        require(msg.sender == self.factory_contract);
        //Update total supply of DRCT Tokens
        self.total_supply = self.total_supply.add(_supply);
        //Update the total balance of the owner
        self.user_total_balances[_owner] = self.user_total_balances[_owner].add(_supply);
        //If the user has not entered any swaps already, push a zeroed address to their user_swaps mapping to prevent default value conflicts in user_swaps_index
        if (self.user_swaps[_owner].length == 0)
            self.user_swaps[_owner].push(address(0x0));
        //Add a new swap index for the owner
        self.user_swaps_index[_owner][_swap] = self.user_swaps[_owner].length;
        //Push a new swap address to the owner&#39;s swaps
        self.user_swaps[_owner].push(_swap);
        //Push a zeroed Balance struct to the swap balances mapping to prevent default value conflicts in swap_balances_index
        self.swap_balances[_swap].push(Balance({
            owner: 0,
            amount: 0
        }));
        //Add a new owner balance index for the swap
        self.swap_balances_index[_swap][_owner] = 1;
        //Push the owner&#39;s balance to the swap
        self.swap_balances[_swap].push(Balance({
            owner: _owner,
            amount: _supply
        }));
        emit CreateToken(_owner,_supply);
    }

    /**
    *@dev Called by the factory contract, and pays out to a _party
    *@param _party being paid
    *@param _swap address
    */
    function pay(TokenStorage storage self,address _party, address _swap) public{
        require(msg.sender == self.factory_contract);
        uint party_balance_index = self.swap_balances_index[_swap][_party];
        require(party_balance_index > 0);
        uint party_swap_balance = self.swap_balances[_swap][party_balance_index].amount;
        //reduces the users totals balance by the amount in that swap
        self.user_total_balances[_party] = self.user_total_balances[_party].sub(party_swap_balance);
        //reduces the total supply by the amount of that users in that swap
        self.total_supply = self.total_supply.sub(party_swap_balance);
        //sets the partys balance to zero for that specific swaps party balances
        self.swap_balances[_swap][party_balance_index].amount = 0;
    }

    /**
    *@dev Returns the users total balance (sum of tokens in all swaps the user has tokens in)
    *@param _owner user address
    *@return user total balance
    */
    function balanceOf(TokenStorage storage self,address _owner) public constant returns (uint balance) {
       return self.user_total_balances[_owner]; 
     }

    /**
    *@dev Getter for the total_supply of tokens in the contract
    *@return total supply
    */
    function totalSupply(TokenStorage storage self) public constant returns (uint _total_supply) {
       return self.total_supply;
    }

    /**
    *@dev Removes the address from the swap balances for a swap, and moves the last address in the
    *swap into their place
    *@param _remove address of prevous owner
    *@param _swap address used to get last addrss of the swap to replace the removed address
    */
    function removeFromSwapBalances(TokenStorage storage self,address _remove, address _swap) internal {
        uint last_address_index = self.swap_balances[_swap].length.sub(1);
        address last_address = self.swap_balances[_swap][last_address_index].owner;
        //If the address we want to remove is the final address in the swap
        if (last_address != _remove) {
            uint remove_index = self.swap_balances_index[_swap][_remove];
            //Update the swap&#39;s balance index of the last address to that of the removed address index
            self.swap_balances_index[_swap][last_address] = remove_index;
            //Set the swap&#39;s Balance struct at the removed index to the Balance struct of the last address
            self.swap_balances[_swap][remove_index] = self.swap_balances[_swap][last_address_index];
        }
        //Remove the swap_balances index for this address
        delete self.swap_balances_index[_swap][_remove];
        //Finally, decrement the swap balances length
        self.swap_balances[_swap].length = self.swap_balances[_swap].length.sub(1);
    }

    /**
    *@dev This is the main function to update the mappings when a transfer happens
    *@param _from address to send funds from
    *@param _to address to send funds to
    *@param _amount amount of token to send
    */
    function transferHelper(TokenStorage storage self,address _from, address _to, uint _amount) internal {
        //Get memory copies of the swap arrays for the sender and reciever
        address[] memory from_swaps = self.user_swaps[_from];
        //Iterate over sender&#39;s swaps in reverse order until enough tokens have been transferred
        for (uint i = from_swaps.length.sub(1); i > 0; i--) {
            //Get the index of the sender&#39;s balance for the current swap
            uint from_swap_user_index = self.swap_balances_index[from_swaps[i]][_from];
            Balance memory from_user_bal = self.swap_balances[from_swaps[i]][from_swap_user_index];
            //If the current swap will be entirely depleted - we remove all references to it for the sender
            if (_amount >= from_user_bal.amount) {
                _amount -= from_user_bal.amount;
                //If this swap is to be removed, we know it is the (current) last swap in the user&#39;s user_swaps list, so we can simply decrement the length to remove it
                self.user_swaps[_from].length = self.user_swaps[_from].length.sub(1);
                //Remove the user swap index for this swap
                delete self.user_swaps_index[_from][from_swaps[i]];
                //If the _to address already holds tokens from this swap
                if (self.user_swaps_index[_to][from_swaps[i]] != 0) {
                    //Get the index of the _to balance in this swap
                    uint to_balance_index = self.swap_balances_index[from_swaps[i]][_to];
                    assert(to_balance_index != 0);
                    //Add the _from tokens to _to
                    self.swap_balances[from_swaps[i]][to_balance_index].amount = self.swap_balances[from_swaps[i]][to_balance_index].amount.add(from_user_bal.amount);
                    //Remove the _from address from this swap&#39;s balance array
                    removeFromSwapBalances(self,_from, from_swaps[i]);
                } else {
                    //Prepare to add a new swap by assigning the swap an index for _to
                    if (self.user_swaps[_to].length == 0){
                        self.user_swaps[_to].push(address(0x0));
                    }
                self.user_swaps_index[_to][from_swaps[i]] = self.user_swaps[_to].length;
                //Add the new swap to _to
                self.user_swaps[_to].push(from_swaps[i]);
                //Give the reciever the sender&#39;s balance for this swap
                self.swap_balances[from_swaps[i]][from_swap_user_index].owner = _to;
                //Give the reciever the sender&#39;s swap balance index for this swap
                self.swap_balances_index[from_swaps[i]][_to] = self.swap_balances_index[from_swaps[i]][_from];
                //Remove the swap balance index from the sending party
                delete self.swap_balances_index[from_swaps[i]][_from];
            }
            //If there is no more remaining to be removed, we break out of the loop
            if (_amount == 0)
                break;
            } else {
                //The amount in this swap is more than the amount we still need to transfer
                uint to_swap_balance_index = self.swap_balances_index[from_swaps[i]][_to];
                //If the _to address already holds tokens from this swap
                if (self.user_swaps_index[_to][from_swaps[i]] != 0) {
                    //Because both addresses are in this swap, and neither will be removed, we simply update both swap balances
                    self.swap_balances[from_swaps[i]][to_swap_balance_index].amount = self.swap_balances[from_swaps[i]][to_swap_balance_index].amount.add(_amount);
                } else {
                    //Prepare to add a new swap by assigning the swap an index for _to
                    if (self.user_swaps[_to].length == 0){
                        self.user_swaps[_to].push(address(0x0));
                    }
                    self.user_swaps_index[_to][from_swaps[i]] = self.user_swaps[_to].length;
                    //And push the new swap
                    self.user_swaps[_to].push(from_swaps[i]);
                    //_to is not in this swap, so we give this swap a new balance index for _to
                    self.swap_balances_index[from_swaps[i]][_to] = self.swap_balances[from_swaps[i]].length;
                    //And push a new balance for _to
                    self.swap_balances[from_swaps[i]].push(Balance({
                        owner: _to,
                        amount: _amount
                    }));
                }
                //Finally, update the _from user&#39;s swap balance
                self.swap_balances[from_swaps[i]][from_swap_user_index].amount = self.swap_balances[from_swaps[i]][from_swap_user_index].amount.sub(_amount);
                //Because we have transferred the last of the amount to the reciever, we break;
                break;
            }
        }
    }

    /**
    *@dev ERC20 compliant transfer function
    *@param _to Address to send funds to
    *@param _amount Amount of token to send
    *@return true for successful
    */
    function transfer(TokenStorage storage self, address _to, uint _amount) public returns (bool) {
        require(isWhitelisted(self,_to));
        uint balance_owner = self.user_total_balances[msg.sender];
        if (
            _to == msg.sender ||
            _to == address(0) ||
            _amount == 0 ||
            balance_owner < _amount
        ) return false;
        transferHelper(self,msg.sender, _to, _amount);
        self.user_total_balances[msg.sender] = self.user_total_balances[msg.sender].sub(_amount);
        self.user_total_balances[_to] = self.user_total_balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    /**
    *@dev ERC20 compliant transferFrom function
    *@param _from address to send funds from (must be allowed, see approve function)
    *@param _to address to send funds to
    *@param _amount amount of token to send
    *@return true for successful
    */
    function transferFrom(TokenStorage storage self, address _from, address _to, uint _amount) public returns (bool) {
        require(isWhitelisted(self,_to));
        uint balance_owner = self.user_total_balances[_from];
        uint sender_allowed = self.allowed[_from][msg.sender];
        if (
            _to == _from ||
            _to == address(0) ||
            _amount == 0 ||
            balance_owner < _amount ||
            sender_allowed < _amount
        ) return false;
        transferHelper(self,_from, _to, _amount);
        self.user_total_balances[_from] = self.user_total_balances[_from].sub(_amount);
        self.user_total_balances[_to] = self.user_total_balances[_to].add(_amount);
        self.allowed[_from][msg.sender] = self.allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
    *@dev ERC20 compliant approve function
    *@param _spender party that msg.sender approves for transferring funds
    *@param _amount amount of token to approve for sending
    *@return true for successful
    */
    function approve(TokenStorage storage self, address _spender, uint _amount) public returns (bool) {
        self.allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
    *@dev Counts addresses involved in the swap based on the length of balances array for _swap
    *@param _swap address
    *@return the length of the balances array for the swap
    */
    function addressCount(TokenStorage storage self, address _swap) public constant returns (uint) { 
        return self.swap_balances[_swap].length; 
    }

    /**
    *@dev Gets the owner address and amount by specifying the swap address and index
    *@param _ind specified index in the swap
    *@param _swap specified swap address
    *@return the owner address associated with a particular index in a particular swap
    *@return the amount to transfer associated with a particular index in a particular swap
    */
    function getBalanceAndHolderByIndex(TokenStorage storage self, uint _ind, address _swap) public constant returns (uint, address) {
        return (self.swap_balances[_swap][_ind].amount, self.swap_balances[_swap][_ind].owner);
    }

    /**
    *@dev Gets the index by specifying the swap and owner addresses
    *@param _owner specifed address
    *@param _swap  specified swap address
    *@return the index associated with the _owner address in a particular swap
    */
    function getIndexByAddress(TokenStorage storage self, address _owner, address _swap) public constant returns (uint) {
        return self.swap_balances_index[_swap][_owner]; 
    }

    /**
    *@dev Look up how much the spender or contract is allowed to spend?
    *@param _owner 
    *@param _spender party approved for transfering funds 
    *@return the allowed amount _spender can spend of _owner&#39;s balance
    */
    function allowance(TokenStorage storage self, address _owner, address _spender) public constant returns (uint) {
        return self.allowed[_owner][_spender]; 
    }
}

/**
*The DRCT_Token is an ERC20 compliant token representing the payout of the swap contract
*specified in the Factory contract.
*Each Factory contract is specified one DRCT Token and the token address can contain many
*different swap contracts that are standardized at the Factory level.
*The logic for the functions in this contract is housed in the DRCTLibary.sol.
*/
contract DRCT_Token {

    using DRCTLibrary for DRCTLibrary.TokenStorage;

    /*Variables*/
    DRCTLibrary.TokenStorage public drct;

    /*Functions*/
    /**
    *@dev Constructor - sets values for token name and token supply, as well as the 
    *factory_contract, the swap.
    *@param _factory 
    */
    constructor() public {
        drct.startToken(msg.sender);
    }

    /**
    *@dev Token Creator - This function is called by the factory contract and creates new tokens
    *for the user
    *@param _supply amount of DRCT tokens created by the factory contract for this swap
    *@param _owner address
    *@param _swap address
    */
    function createToken(uint _supply, address _owner, address _swap) public{
        drct.createToken(_supply,_owner,_swap);
    }

    /**
    *@dev gets the factory address
    */
    function getFactoryAddress() external view returns(address){
        return drct.getFactoryAddress();
    }

    /**
    *@dev Called by the factory contract, and pays out to a _party
    *@param _party being paid
    *@param _swap address
    */
    function pay(address _party, address _swap) public{
        drct.pay(_party,_swap);
    }

    /**
    *@dev Returns the users total balance (sum of tokens in all swaps the user has tokens in)
    *@param _owner user address
    *@return user total balance
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
       return drct.balanceOf(_owner);
     }

    /**
    *@dev Getter for the total_supply of tokens in the contract
    *@return total supply
    */
    function totalSupply() public constant returns (uint _total_supply) {
       return drct.totalSupply();
    }

    /**
    *ERC20 compliant transfer function
    *@param _to Address to send funds to
    *@param _amount Amount of token to send
    *@return true for successful
    */
    function transfer(address _to, uint _amount) public returns (bool) {
        return drct.transfer(_to,_amount);
    }

    /**
    *@dev ERC20 compliant transferFrom function
    *@param _from address to send funds from (must be allowed, see approve function)
    *@param _to address to send funds to
    *@param _amount amount of token to send
    *@return true for successful transfer
    */
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        return drct.transferFrom(_from,_to,_amount);
    }

    /**
    *@dev ERC20 compliant approve function
    *@param _spender party that msg.sender approves for transferring funds
    *@param _amount amount of token to approve for sending
    *@return true for successful
    */
    function approve(address _spender, uint _amount) public returns (bool) {
        return drct.approve(_spender,_amount);
    }

    /**
    *@dev Counts addresses involved in the swap based on the length of balances array for _swap
    *@param _swap address
    *@return the length of the balances array for the swap
    */
    function addressCount(address _swap) public constant returns (uint) { 
        return drct.addressCount(_swap); 
    }

    /**
    *@dev Gets the owner address and amount by specifying the swap address and index
    *@param _ind specified index in the swap
    *@param _swap specified swap address
    *@return the amount to transfer associated with a particular index in a particular swap
    *@return the owner address associated with a particular index in a particular swap
    */
    function getBalanceAndHolderByIndex(uint _ind, address _swap) public constant returns (uint, address) {
        return drct.getBalanceAndHolderByIndex(_ind,_swap);
    }

    /**
    *@dev Gets the index by specifying the swap and owner addresses
    *@param _owner specifed address
    *@param _swap  specified swap address
    *@return the index associated with the _owner address in a particular swap
    */
    function getIndexByAddress(address _owner, address _swap) public constant returns (uint) {
        return drct.getIndexByAddress(_owner,_swap); 
    }

    /**
    *@dev Look up how much the spender or contract is allowed to spend?
    *@param _owner address
    *@param _spender party approved for transfering funds 
    *@return the allowed amount _spender can spend of _owner&#39;s balance
    */
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return drct.allowance(_owner,_spender); 
    }
}






//ERC20 function interface with create token and withdraw
interface Wrapped_Ether_Interface {
  function totalSupply() external constant returns (uint);
  function balanceOf(address _owner) external constant returns (uint);
  function transfer(address _to, uint _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint _amount) external returns (bool);
  function approve(address _spender, uint _amount) external returns (bool);
  function allowance(address _owner, address _spender) external constant returns (uint);
  function withdraw(uint _value) external;
  function createToken() external;

}

interface Membership_Interface {
    function getMembershipType(address _member) external constant returns(uint);
}



/**
*The Factory contract sets the standardized variables and also deploys new contracts based on
*these variables for the user.  
*/
contract Factory {
    using SafeMath for uint256;
    
    /*Variables*/
    //Addresses of the Factory owner and oracle. For oracle information, 
    //check www.github.com/DecentralizedDerivatives/Oracles
    address public owner;
    address public oracle_address;
    //Address of the user contract
    address public user_contract;
    //Address of the deployer contract
    address internal deployer_address;
    Deployer_Interface internal deployer;
    address public token;
    //A fee for creating a swap in wei.  Plan is for this to be zero, however can be raised to prevent spam
    uint public fee;
    //swap fee
    uint public swapFee;
    //Duration of swap contract in days
    uint public duration;
    //Multiplier of reference rate.  2x refers to a 50% move generating a 100% move in the contract payout values
    uint public multiplier;
    //Token_ratio refers to the number of DRCT Tokens a party will get based on the number of base tokens.  As an example, 1e15 indicates that a party will get 1000 DRCT Tokens based upon 1 ether of wrapped wei. 
    uint public token_ratio;
    //Array of deployed contracts
    address[] public contracts;
    uint[] public startDates;
    address public memberContract;
    mapping(uint => bool) whitelistedTypes;
    mapping(address => uint) public created_contracts;
    mapping(address => uint) public token_dates;
    mapping(uint => address) public long_tokens;
    mapping(uint => address) public short_tokens;
    mapping(address => uint) public token_type; //1=short 2=long

    /*Events*/
    //Emitted when a Swap is created
    event ContractCreation(address _sender, address _created);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*Functions*/
    /**
    *@dev Constructor - Sets owner
    */
     constructor() public {
        owner = msg.sender;
    }

    /**
    *@dev constructor function for cloned factory
    */
    function init(address _owner) public{
        require(owner == address(0));
        owner = _owner;
    }

    /**
    *@dev Sets the Membership contract address
    *@param _memberContract The new membership address
    */
    function setMemberContract(address _memberContract) public onlyOwner() {
        memberContract = _memberContract;
    }

    /**
    *@dev Sets the member types/permissions for those whitelisted
    *@param _memberTypes is the list of member types
    */
    function setWhitelistedMemberTypes(uint[] _memberTypes) public onlyOwner(){
        whitelistedTypes[0] = false;
        for(uint i = 0; i<_memberTypes.length;i++){
            whitelistedTypes[_memberTypes[i]] = true;
        }
    }

    /**
    *@dev Checks the membership type/permissions for whitelisted members
    *@param _member address to get membership type from
    */
    function isWhitelisted(address _member) public view returns (bool){
        Membership_Interface Member = Membership_Interface(memberContract);
        return whitelistedTypes[Member.getMembershipType(_member)];
    }
 
    /**
    *@dev Gets long and short token addresses based on specified date
    *@param _date 
    *@return short and long tokens&#39; addresses
    */
    function getTokens(uint _date) public view returns(address, address){
        return(long_tokens[_date],short_tokens[_date]);
    }

    /**
    *@dev Gets the type of Token (long and short token) for the specifed 
    *token address
    *@param _token address 
    *@return token type short = 1 and long = 2
    */
    function getTokenType(address _token) public view returns(uint){
        return(token_type[_token]);
    }

    /**
    *@dev Updates the fee amount
    *@param _fee is the new fee amount
    */
    function setFee(uint _fee) public onlyOwner() {
        fee = _fee;
    }

    /**
    *@dev Updates the swap fee amount
    *@param _swapFee is the new swap fee amount
    */
    function setSwapFee(uint _swapFee) public onlyOwner() {
        swapFee = _swapFee;
    }   

    /**
    *@dev Sets the deployer address
    *@param _deployer is the new deployer address
    */
    function setDeployer(address _deployer) public onlyOwner() {
        deployer_address = _deployer;
        deployer = Deployer_Interface(_deployer);
    }

    /**
    *@dev Sets the user_contract address
    *@param _userContract is the new userContract address
    */
    function setUserContract(address _userContract) public onlyOwner() {
        user_contract = _userContract;
    }

    /**
    *@dev Sets token ratio, swap duration, and multiplier variables for a swap.
    *@param _token_ratio the ratio of the tokens
    *@param _duration the duration of the swap, in days
    *@param _multiplier the multiplier used for the swap
    *@param _swapFee the swap fee
    */
    function setVariables(uint _token_ratio, uint _duration, uint _multiplier, uint _swapFee) public onlyOwner() {
        require(_swapFee < 10000);
        token_ratio = _token_ratio;
        duration = _duration;
        multiplier = _multiplier;
        swapFee = _swapFee;
    }

    /**
    *@dev Sets the address of the base tokens used for the swap
    *@param _token The address of a token to be used  as collateral
    */
    function setBaseToken(address _token) public onlyOwner() {
        token = _token;
    }

    /**
    *@dev Allows a user to deploy a new swap contract, if they pay the fee
    *@param _start_date the contract start date 
    *@return new_contract address for he newly created swap address and calls 
    *event &#39;ContractCreation&#39;
    */
    function deployContract(uint _start_date) public payable returns (address) {
        require(msg.value >= fee && isWhitelisted(msg.sender));
        require(_start_date % 86400 == 0);
        address new_contract = deployer.newContract(msg.sender, user_contract, _start_date);
        contracts.push(new_contract);
        created_contracts[new_contract] = _start_date;
        emit ContractCreation(msg.sender,new_contract);
        return new_contract;
    }

    /**
    *@dev Deploys DRCT tokens for given start date
    *@param _start_date of contract
    */
    function deployTokenContract(uint _start_date) public{
        address _token;
        require(_start_date % 86400 == 0);
        require(long_tokens[_start_date] == address(0) && short_tokens[_start_date] == address(0));
        _token = new DRCT_Token();
        token_dates[_token] = _start_date;
        long_tokens[_start_date] = _token;
        token_type[_token]=2;
        _token = new DRCT_Token();
        token_type[_token]=1;
        short_tokens[_start_date] = _token;
        token_dates[_token] = _start_date;
        startDates.push(_start_date);

    }

    /**
    *@dev Deploys new tokens on a DRCT_Token contract -- called from within a swap
    *@param _supply The number of tokens to create
    *@param _party the address to send the tokens to
    *@param _start_date the start date of the contract      
    *@returns ltoken the address of the created DRCT long tokens
    *@returns stoken the address of the created DRCT short tokens
    *@returns token_ratio The ratio of the created DRCT token
    */
    function createToken(uint _supply, address _party, uint _start_date) public returns (address, address, uint) {
        require(created_contracts[msg.sender] == _start_date);
        address ltoken = long_tokens[_start_date];
        address stoken = short_tokens[_start_date];
        require(ltoken != address(0) && stoken != address(0));
            DRCT_Token drct_interface = DRCT_Token(ltoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
            drct_interface = DRCT_Token(stoken);
            drct_interface.createToken(_supply.div(token_ratio), _party,msg.sender);
        return (ltoken, stoken, token_ratio);
    }
  
    /**
    *@dev Allows the owner to set a new oracle address
    *@param _new_oracle_address 
    */
    function setOracleAddress(address _new_oracle_address) public onlyOwner() {
        oracle_address = _new_oracle_address; 
    }

    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

    /**
    *@dev Allows the owner to pull contract creation fees
    *@return the withdrawal fee _val and the balance where is the return function?
    */
    function withdrawFees() public onlyOwner(){
        Wrapped_Ether_Interface token_interface = Wrapped_Ether_Interface(token);
        uint _val = token_interface.balanceOf(address(this));
        if(_val > 0){
            token_interface.withdraw(_val);
        }
        owner.transfer(address(this).balance);
     }

    /**
    *@dev fallback function
    */ 
    function() public payable {
    }

    /**
    *@dev Returns a tuple of many private variables.
    *The variables from this function are pass through to the TokenLibrary.getVariables function
    *@returns oracle_adress is the address of the oracle
    *@returns duration is the duration of the swap
    *@returns multiplier is the multiplier for the swap
    *@returns token is the address of token
    *@returns _swapFee is the swap fee 
    */
    function getVariables() public view returns (address, uint, uint, address,uint){
        return (oracle_address,duration, multiplier, token,swapFee);
    }

    /**
    *@dev Pays out to a DRCT token
    *@param _party is the address being paid
    *@param _token_add token to pay out
    */
    function payToken(address _party, address _token_add) public {
        require(created_contracts[msg.sender] > 0);
        DRCT_Token drct_interface = DRCT_Token(_token_add);
        drct_interface.pay(_party, msg.sender);
    }

    /**
    *@dev Counts number of contacts created by this factory
    *@return the number of contracts
    */
    function getCount() public constant returns(uint) {
        return contracts.length;
    }

    /**
    *@dev Counts number of start dates in this factory
    *@return the number of active start dates
    */
    function getDateCount() public constant returns(uint) {
        return startDates.length;
    }
}

/**
*This contracts helps clone factories and swaps through the Deployer.sol and MasterDeployer.sol.
*The address of the targeted contract to clone has to be provided.
*/
contract CloneFactory {

    /*Variables*/
    address internal owner;
    
    /*Events*/
    event CloneCreated(address indexed target, address clone);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /*Functions*/
    constructor() public{
        owner = msg.sender;
    }    
    
    /**
    *@dev Allows the owner to set a new owner address
    *@param _owner the new owner address
    */
    function setOwner(address _owner) public onlyOwner(){
        owner = _owner;
    }

    /**
    *@dev Creates factory clone
    *@param _target is the address being cloned
    *@return address for clone
    */
    function createClone(address target) internal returns (address result) {
        bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
        bytes20 targetBytes = bytes20(target);
        for (uint i = 0; i < 20; i++) {
            clone[26 + i] = targetBytes[i];
        }
        assembly {
            let len := mload(clone)
            let data := add(clone, 0x20)
            result := create(0, data, len)
        }
    }
}


/**
*This contract deploys a factory contract and uses CloneFactory to clone the factory
*specified.
*/

contract MasterDeployer is CloneFactory{
    
    using SafeMath for uint256;

    /*Variables*/
    address[] factory_contracts;
    address private factory;
    mapping(address => uint) public factory_index;

    /*Events*/
    event NewFactory(address _factory);

    /*Functions*/
    /**
    *@dev Initiates the factory_contract array with address(0)
    */
    constructor() public {
        factory_contracts.push(address(0));
    }

    /**
    *@dev Set factory address to clone
    *@param _factory address to clone
    */  
    function setFactory(address _factory) public onlyOwner(){
        factory = _factory;
    }

    /**
    *@dev creates a new factory by cloning the factory specified in setFactory.
    *@return _new_fac which is the new factory address
    */
    function deployFactory() public onlyOwner() returns(address){
        address _new_fac = createClone(factory);
        factory_index[_new_fac] = factory_contracts.length;
        factory_contracts.push(_new_fac);
        Factory(_new_fac).init(msg.sender);
        emit NewFactory(_new_fac);
        return _new_fac;
    }

    /**
    *@dev Removes the factory specified
    *@param _factory address to remove
    */
    function removeFactory(address _factory) public onlyOwner(){
        require(_factory != address(0) && factory_index[_factory] != 0);
        uint256 fIndex = factory_index[_factory];
        uint256 lastFactoryIndex = factory_contracts.length.sub(1);
        address lastFactory = factory_contracts[lastFactoryIndex];
        factory_contracts[fIndex] = lastFactory;
        factory_index[lastFactory] = fIndex;
        factory_contracts.length--;
        factory_index[_factory] = 0;
    }

    /**
    *@dev Counts the number of factories
    *@returns the number of active factories
    */
    function getFactoryCount() public constant returns(uint){
        return factory_contracts.length - 1;
    }

    /**
    *@dev Returns the factory address for the specified index
    *@param _index for factory to look up in the factory_contracts array
    *@return factory address for the index specified
    */
    function getFactorybyIndex(uint _index) public constant returns(address){
        return factory_contracts[_index];
    }
}