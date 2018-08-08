pragma solidity ^0.4.24;

// 22.07.18


//*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/
//
//  Ethertote token contract
//
//  (parts of the token contract
//  are based on the &#39;MiniMeToken&#39; - Jordi Baylina)
//
//  Fully ERC20 Compliant token
//
//  Name:            Ethertote
//  Symbol:          TOTE
//  Decimals:        0
//  Total supply:    10000000 (10 million tokens)
//
//*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/


// ----------------------------------------------------------------------------
// TokenController contract is called when `_owner` sends ether to the 
// Ethertote Token contract
// ----------------------------------------------------------------------------
contract TokenController {

    function proxyPayments(address _owner) public payable returns(bool);
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}


// ----------------------------------------------------------------------------
// ApproveAndCallFallBack
// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}


// ----------------------------------------------------------------------------
// The main EthertoteToken contract, the default controller is the msg.sender
// that deploys the contract
// ----------------------------------------------------------------------------
contract EthertoteToken {

    // Variables to ensure contract is conforming to ERC220
    string public name;                
    uint8 public decimals;             
    string public symbol;              
    uint public _totalSupply;
    
    // Addtional variables 
    string public version; 
    address public contractOwner;
    address public thisContractAddress;
    address public EthertoteAdminAddress;
    
    bool public tokenGenerationLock;            // ensure tokens can only be minted once
    
    // the controller takes full control of the contract
    address public controller;
    
    // null address which will be assigned as controller for security purposes
    address public relinquishOwnershipAddress = 0x0000000000000000000000000000000000000000;
    
    
    // Modifier to ensure generateTokens() is only ran once by the constructor
    modifier onlyController { 
        require(
            msg.sender == controller
            ); 
            _; 
    }
    
    
    modifier onlyContract { 
        require(
            address(this) == thisContractAddress
            
        ); 
        _; 
    }
    
    
    modifier EthertoteAdmin { 
        require(
            msg.sender == EthertoteAdminAddress
            
        ); 
        _; 
    }


    // Checkpoint is the struct that attaches a block number to a
    // given value, and the block number attached is the one that last changed the
    // value
    struct  Checkpoint {
        uint128 fromBlock;
        uint128 value;
    }

    // parentToken will be 0x0 for the token unless cloned
    EthertoteToken private parentToken;

    // parentSnapShotBlock is the block number from the Parent Token which will
    // be 0x0 unless cloned
    uint private parentSnapShotBlock;

    // creationBlock is the &#39;genesis&#39; block number when contract is deployed
    uint public creationBlock;

    // balances is the mapping which tracks the balance of each address
    mapping (address => Checkpoint[]) balances;

    // allowed is the mapping which tracks any extra transfer rights 
    // as per ERC20 token standards
    mapping (address => mapping (address => uint256)) allowed;

    // Checkpoint array tracks the history of the totalSupply of the token
    Checkpoint[] totalSupplyHistory;

    // needs to be set to &#39;true&#39; to allow tokens to be transferred
    bool public transfersEnabled;


// ----------------------------------------------------------------------------
// Constructor function initiated automatically when contract is deployed
// ----------------------------------------------------------------------------
    constructor() public {
        
        controller = msg.sender;
        EthertoteAdminAddress = msg.sender;
        tokenGenerationLock = false;
        
    // --------------------------------------------------------------------
    // set the following values prior to deployment
    // --------------------------------------------------------------------
    
        name = "Ethertote";                                   // Set the name
        symbol = "TOTE";                                 // Set the symbol
        decimals = 0;                                       // Set the decimals
        _totalSupply = 10000000 * 10**uint(decimals);       // 10,000,000 tokens
        
        version = "Ethertote Token contract - version 1.0";
    
    //---------------------------------------------------------------------

        // Additional variables set by the constructor
        contractOwner = msg.sender;
        thisContractAddress = address(this);

        transfersEnabled = true;                            // allows tokens to be traded
        
        creationBlock = block.number;                       // sets the genesis block


        // Now call the internal generateTokens function to create the tokens 
        // and send them to owner
        generateTokens(contractOwner, _totalSupply);
        
        // Now that the tokens have been generated, finally reliquish 
        // ownership of the token contract for security purposes
        controller = relinquishOwnershipAddress;
    }


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface Methods for full compliance
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

    // totalSupply //
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }
    
    // balanceOf //
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    // allowance //
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // transfer //
    function transfer(address _to, uint256 _amount
    ) public returns (bool success) {
        
        require(transfersEnabled);
        
        // prevent tokens from ever being sent back to the contract address 
        require(_to != address(this) );
        // prevent tokens from ever accidentally being sent to the nul (0x0) address
        require(_to != 0x0);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

    // approve //
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    // transferFrom
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {
        
        // prevent tokens from ever being sent back to the contract address 
        require(_to != address(this) );
        // prevent tokens from ever accidentally being sent to the nul (0x0) address
        require(_to != 0x0);
        
        if (msg.sender != controller) {
            require(transfersEnabled);

            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }
    
// ----------------------------------------------------------------------------
//  ERC20 compliant events
// ----------------------------------------------------------------------------

    event Transfer(
        address indexed _from, address indexed _to, uint256 _amount
        );
    
    event Approval(
        address indexed _owner, address indexed _spender, uint256 _amount
        );

// ----------------------------------------------------------------------------

    // once constructor assigns control to 0x0 the contract cannot be changed
    function changeController(address _newController) onlyController private {
        controller = _newController;
    }
    
    function doTransfer(address _from, address _to, uint _amount) internal {

           if (_amount == 0) {
               emit Transfer(_from, _to, _amount); 
               return;
           }

           require(parentSnapShotBlock < block.number);

           // Do not allow transfer to 0x0 or the token contract itself
           // require((_to != 0) && (_to != address(this)));
           
           require(_to != address(this));
           
           

           // If the amount being transfered is more than the balance of the
           //  account, the transfer throws
           uint previousBalanceFrom = balanceOfAt(_from, block.number);
           require(previousBalanceFrom >= _amount);

           // Alerts the token controller of the transfer
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

           // First update the balance array with the new value for the address
           //  sending the tokens
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

           // Then update the balance array with the new value for the address
           //  receiving the tokens
           uint previousBalanceTo = balanceOfAt(_to, block.number);
           
           // Check for overflow
           require(previousBalanceTo + _amount >= previousBalanceTo); 
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

           // An event to make the transfer easy to find on the blockchain
           emit Transfer(_from, _to, _amount);

    }


// ----------------------------------------------------------------------------
// approveAndCall allows users to use their tokens to interact with contracts
// in a single function call
// msg.sender approves `_spender` to send an `_amount` of tokens on
// its behalf, and then a function is triggered in the contract that is
// being approved, `_spender`. This allows users to use their tokens to
// interact with contracts in one function call instead of two
    
// _spender is the address of the contract able to transfer the tokens
// _amount is the amount of tokens to be approved for transfer
// return &#39;true&#39; if the function call was successful
// ----------------------------------------------------------------------------    
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );
        return true;
    }




// ----------------------------------------------------------------------------
// Query the balance of an address at a specific block number
// ----------------------------------------------------------------------------
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        } 
        
        else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }


// ----------------------------------------------------------------------------
// Queries the total supply of tokens at a specific block number
// will return 0 if called before the creationBlock value
// ----------------------------------------------------------------------------
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {
        if (
            (totalSupplyHistory.length == 0) ||
            (totalSupplyHistory[0].fromBlock > _blockNumber)
            ) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        } 
        else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }


// ----------------------------------------------------------------------------
// The generateTokens function will generate the initial supply of tokens
// Can only be called once during the constructor as it has the onlyContract
// modifier attached to the function
// ----------------------------------------------------------------------------
    function generateTokens(address _owner, uint _theTotalSupply) 
    private onlyContract returns (bool) {
        require(tokenGenerationLock == false);
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _theTotalSupply >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _totalSupply >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _totalSupply);
        updateValueAtNow(balances[_owner], previousBalanceTo + _totalSupply);
        emit Transfer(0, _owner, _totalSupply);
        tokenGenerationLock = true;
        return true;
    }


// ----------------------------------------------------------------------------
// Enable tokens transfers to allow tokens to be traded
// ----------------------------------------------------------------------------

    function enableTransfers(bool _transfersEnabled) private onlyController {
        transfersEnabled = _transfersEnabled;
    }

// ----------------------------------------------------------------------------
// Internal helper functions
// ----------------------------------------------------------------------------

    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

// ----------------------------------------------------------------------------
// function used to update the `balances` map and the `totalSupplyHistory`
// ----------------------------------------------------------------------------
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

// ----------------------------------------------------------------------------
// function to check if address is a contract
// ----------------------------------------------------------------------------
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

// ----------------------------------------------------------------------------
// Helper function to return a min betwen the two uints
// ----------------------------------------------------------------------------
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

// ----------------------------------------------------------------------------
// fallback function: If the contract&#39;s controller has not been set to 0, 
// then the `proxyPayment` method is called which relays the eth and creates 
// tokens as described in the token controller contract
// ----------------------------------------------------------------------------
    function () public payable {
        require(isContract(controller));
        require(
            TokenController(controller).proxyPayments.value(msg.value)(msg.sender)
            );
    }


    event ClaimedTokens(
        address indexed _token, address indexed _controller, uint _amount
        );

// ----------------------------------------------------------------------------
// This method can be used by the controller to extract other tokens accidentally 
// sent to this contract.
// _token is the address of the token contract to recover
//  can be set to 0 to extract eth
// ----------------------------------------------------------------------------
    function withdrawOtherTokens(address _token) EthertoteAdmin public {
        if (_token == 0x0) {
            controller.transfer(address(this).balance);
            return;
        }
        EthertoteToken token = EthertoteToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

}