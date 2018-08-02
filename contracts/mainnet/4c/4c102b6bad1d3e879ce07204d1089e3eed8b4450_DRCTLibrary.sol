pragma solidity ^0.4.24;

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