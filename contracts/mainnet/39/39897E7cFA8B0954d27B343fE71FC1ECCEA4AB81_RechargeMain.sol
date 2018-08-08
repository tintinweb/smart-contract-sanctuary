pragma solidity ^0.4.18;

/*
 * ERC223 interface
 * see https://github.com/ethereum/EIPs/issues/20
 * see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC223 {
    function totalSupply() constant public returns (uint256 outTotalSupply);
    function balanceOf( address _owner) constant public returns (uint256 balance);
    function transfer( address _to, uint256 _value) public returns (bool success);
    function transfer( address _to, uint256 _value, bytes _data) public returns (bool success);
    function transferFrom( address _from, address _to, uint256 _value) public returns (bool success);
    function approve( address _spender, uint256 _value) public returns (bool success);
    function allowance( address _owner, address _spender) constant public returns (uint256 remaining);
    event Transfer( address indexed _from, address indexed _to, uint _value, bytes _data);
    event Approval( address indexed _owner, address indexed _spender, uint256 _value);
}


contract ERC223Receiver { 
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}




/// @title A base contract to control ownership
/// @author cuilichen
contract OwnerBase {

    // The addresses of the accounts that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;
    
    /// constructor
    function OwnerBase() public {
       ceoAddress = msg.sender;
       cfoAddress = msg.sender;
       cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCFO The address of the new COO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCOO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}



/**
 * Standard ERC223 receiver
 */
contract RechargeMain is ERC223Receiver, OwnerBase {

	event EvtCoinSetted(address coinContract);
    
	event EvtRecharge(address customer, uint amount);

	
	ERC223 public coinContract;
	
	
    function RechargeMain(address coin) public {
		// the creator of the contract is the initial CEO
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
		
		coinContract = ERC223(coin);
    }

    /**
     * Owner can update base information here.
     */
    function setCoinInfo(address coin) public {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
		
		coinContract = ERC223(coin);
		
        emit EvtCoinSetted(coinContract);
    }
	
	/// @dev receive token from coinContract
	function tokenFallback(address _from, uint _value, bytes ) public {
		require(msg.sender == address(coinContract));
		emit EvtRecharge(_from, _value);
	}
    
	
    function () public payable {
        //fallback
    }
    
    
    /// transfer dead tokens to contract master
    function withdrawTokens() external {
		address myself = address(this);
        uint256 fundNow = coinContract.balanceOf(myself);
        coinContract.transfer(cfoAddress, fundNow);//token
        
        uint256 balance = myself.balance;
        cfoAddress.transfer(balance);//eth
    }
    

}